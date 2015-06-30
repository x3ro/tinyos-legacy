/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Adrian Burns
 *         September, 2009
 */

 /***********************************************************************************

 /* NOTE: This app samples the SHIMMER SEDA Rev.1.1 add-on board
    
    This app uses transmits GSR data over Bluetooth to BioMOBIUS 
    The GSR data is in resistance from 10k to 4.7Mohm.
   
   LOW_BATTERY_INDICATION if defined stops the app streaming data just after the 
   battery voltage drops below the regulator value of 3V.

   Default Sample Frequency: 32 hz
   
   Packet Format:
         BOF| Sensor ID | Data Type | Seq No. | TimeStamp | Len | GSR | GSR  | CRC  | EOF
   Byte:  1 |    2      |     3     |    4    |     5-6   |  7  | 8-9 | 10-11| 12-13| 14

   if DEBUG_GSR_MODE is defined
   Packet Format:
         BOF| Sensor ID | Data Type | Seq No. | TimeStamp | Len | RawADC | Internal resistor number | CRC  | EOF
   Byte:  1 |    2      |     3     |    4    |     5-6   |  7  | 8-9    | 10-11                    | 12-13| 14

 ***********************************************************************************/

includes crc;
includes GSR;
includes DMA;
includes Message;
includes RovingNetworks;

module GSRM {
  provides{
    interface StdControl;
  }
  uses {
    interface DMA as DMA0;

    interface StdControl as BTStdControl;
    interface Bluetooth;

    interface Leds;
    interface Timer as SetupTimer;
    interface Timer as SampleTimer;
    interface LocalTime;
  }
} 

implementation {
  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

#define USE_8MHZ_CRYSTAL
#define LOW_BATTERY_INDICATION
#define USE_AVCC_REF /* approx 0.5 milliamps saving when using AVCC compared to 2.5V or 1.5V internal ref */
/* Debug Data Format - | AccelX | AccelY | RawADC | InternalResistor | SkinResistance | SkinResistance | */
//#define DEBUG_GSR_MODE //enable this and you will see the ADC value and the internal resistor being used

/* when we switch resistors with the ADG658 it takes a few samples for the 
   ADC to start to see the new sampled voltage correctly, the catch below is 
   to eliminate any glitches in the dats */
#define ONE_HUNDRED_OHM_STEP 100
#define MAX_RESISTANCE_STEP 5000
/* instead of having a large step when resistors change - have a smoother step */
#define NUM_SMOOTHING_SAMPLES 64
/* ignore these samples after a resistor switch - instead send special code */
#define NUM_SAMPLES_TO_IGNORE 6

#define HW_RES_40K_MAX_ADC_VAL    3400 //10k to 56k
#define HW_RES_40K_MIN_ADC_VAL    1140 //10k to 56k..1159->1140
#define HW_RES_280K_MAX_ADC_VAL   3800 //56k to 220k was 4000 but was 3948 on shimer so changed to 3800
#define HW_RES_280K_MIN_ADC_VAL   1490 //56k to 220k..1510->1490
#define HW_RES_1M_MAX_ADC_VAL     3700 //220k to 680k
#define HW_RES_1M_MIN_ADC_VAL     1630 //220k to 680k..1650->1630
#define HW_RES_3M3_MAX_ADC_VAL    3930 //680k to 4M7
#define HW_RES_3M3_MIN_ADC_VAL    1125 //680k to 4M7


#define HW_RES_40K_CONSTANT_1      0.0000000065995
#define HW_RES_40K_CONSTANT_2      (-0.000068950)
#define HW_RES_40K_CONSTANT_3      0.2699
#define HW_RES_40K_CONSTANT_4      (-476.9835)
#define HW_RES_40K_CONSTANT_5      340351.3341

#define HW_RES_280K_CONSTANT_1     0.000000013569627
#define HW_RES_280K_CONSTANT_2     (-0.0001650399)
#define HW_RES_280K_CONSTANT_3     0.7541990
#define HW_RES_280K_CONSTANT_4     (-1572.6287856)
#define HW_RES_280K_CONSTANT_5     1367507.9270

#define HW_RES_1M_CONSTANT_1       0.00000002550036498
#define HW_RES_1M_CONSTANT_2       (-0.00033136)
#define HW_RES_1M_CONSTANT_3       1.6509426597
#define HW_RES_1M_CONSTANT_4       (-3833.348044)
#define HW_RES_1M_CONSTANT_5       3806317.6947

#define HW_RES_3M3_CONSTANT_1      0.00000037153627
#define HW_RES_3M3_CONSTANT_2      (-0.004239437)
#define HW_RES_3M3_CONSTANT_3      17.905709
#define HW_RES_3M3_CONSTANT_4      (-33723.8657)
#define HW_RES_3M3_CONSTANT_5      25368044.6279

#define STARTING_RESISTANCE 10000000
#define QUICK_RESISTANCE_CALCULATION

#ifdef LOW_BATTERY_INDICATION
  //#define DEBUG_LOW_BATTERY_INDICATION
  /* during testing of the the (AVcc-AVss)/2 value from the ADC on various SHIMMERS, to get a reliable cut off point 
     to recharge the battery it is important to find the baseline (AVcc-AVss)/2 value coming from the ADC as it varies 
     from SHIMMER to SHIMMER, however the range of fluctuation is pretty constant and (AVcc-AVss)/2 provides an accurate 
     battery low indication that prevents getting any voltage skewed data from the accelerometer or add-on board sensors */
  #define TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD 1000
  #define BATTERY_LOW_INDICATION_OFFSET 20 /* (AVcc - AVss)/2 = Approx 3V-0V/2 = 1.5V, 12 bit ADC with 2.5V REF,
                                              4096/2500 = 1mV=1.6384 units */ 
  bool need_baseline_voltage, linkDisconnecting, got_first_sample;
  uint16_t num_baseline_voltage_samples, baseline_voltage, gsr_hw_state, transient_sample, transient_smoothing_samples, max_resistance_step;
  uint32_t sum_batt_volt_samples;

#ifdef DEBUG_LOW_BATTERY_INDICATION
  #error "were going for debug mode yea?, comment me out then"
  uint16_t debug_counter;
#endif /* DEBUG_LOW_BATTERY_INDICATION */

#endif /* LOW_BATTERY_INDICATION */

  #define FIXED_PACKET_SIZE 14
  #define FIXED_PAYLOAD_SIZE 4
  uint8_t tx_packet[(FIXED_PACKET_SIZE*2)+1]; /* (*2)twice size because of byte stuffing */
                                              /* (+1)MSP430 CPU can only read/write 16-bit values at even addresses, 
                                              /* so use an empty byte to even up the memory locations for 16-bit values */
  const uint8_t personality[17] = {
    0,1,2,3,4,5,0xFF,0xFF,
    SAMPLING_50HZ,SAMPLING_50HZ,SAMPLING_50HZ,SAMPLING_50HZ,
    SAMPLING_50HZ,SAMPLING_50HZ,SAMPLING_0HZ_OFF,SAMPLING_0HZ_OFF,FRAMING_EOF
  };

  norace uint8_t current_buffer = 0, dma_blocks = 0;
  uint16_t sbuf0[6], sbuf1[6], timestamp0, timestamp1;

  uint16_t stuff[15360];
  /* default sample frequency every time the sensor boots up */
  uint16_t sample_freq = SAMPLING_32HZ;
  /* keeping glabal so that i can start resistances at a reasonable level of 100k */
  uint32_t last_resistance;
  
  bool enable_sending, command_mode_complete;

  uint64_t multiply(uint64_t no1, uint64_t no2){
    if (no1 == 0 || no2 == 0) return 0;
    if (no1 == 1) return no2;
    if (no2 == 1) return no1;
    return no1*no2;
  }

  /* Internal function to calculate 16 bit CRC */
  uint16_t calc_crc(uint8_t *ptr, uint8_t count) {
    uint16_t crc;
      crc = 0;
    while (count-- > 0)
      crc = crcByte(crc, *ptr++);

    return crc;
  }

  void setupDMA() {
    call DMA0.init();

    call DMA0.setSourceAddress((uint16_t)ADC12MEM0_);

    call DMA0.setDestinationAddress((uint16_t)&sbuf0[0]);

    /*
     *  we'll transfer from six sequential adcmem registers 
     * to six sequential addresses in a buffer
     */
    call DMA0.setBlockSize(2);

    // we want block transfer, single
    DMA0CTL = DMADT_1 + DMADSTINCR_3 + DMASRCINCR_3;
  }

  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_3);         // clk from aclk

      /* with a 125khz clock (_7) its 136usec per conversion, 136*6=816usec in total */
      SET_FLAG(ADC12CTL1, ADC12DIV_7);
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   
      
      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }

    SET_FLAG(ADC12MCTL0, INCH_6);  // VSENSE_GSR
    SET_FLAG(ADC12MCTL1, INCH_11); // (AVcc-AVss)/2 to monitor battery voltage
    SET_FLAG(ADC12MCTL1, EOS);     //sez "this is the last reg" 

#ifdef USE_AVCC_REF
    // set reference to analog voltage AVcc
    CLR_FLAG(ADC12CTL0, REFON);
    CLR_FLAG(ADC12MCTL0, SREF_7);
    CLR_FLAG(ADC12MCTL1, SREF_7);
#else
    SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
#endif /* USE_AVCC_REF */
    
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
    
    setupDMA();

    call DMA0.beginTransfer();
  }
  
  command result_t StdControl.init() {
    register uint8_t i;
    call Leds.init();
    
#ifdef USE_8MHZ_CRYSTAL
    /* 
     * set up 8mhz clock to max out 
     * msp430 throughput 
     */

    atomic CLR_FLAG(BCSCTL1, XT2OFF); // basic clock system control reg, turn off XT2 osc

    call Leds.redOn();
    do{
      CLR_FLAG(IFG1, OFIFG);
      for(i = 0; i < 0xff; i++);
    }
    while(READ_FLAG(IFG1, OFIFG));

    call Leds.redOff();

    call Leds.yellowOn();
    TOSH_uwait(50000UL);

    atomic{ 
      BCSCTL2 = 0; 
      SET_FLAG(BCSCTL2, SELM_2); /* select master clock source, XT2CLK when XT2 oscillator present */
    }                            /*on-chip. LFXT1CLK when XT2 oscillator not present on-chip. */

    call Leds.yellowOff();

    atomic{
      SET_FLAG(BCSCTL2, SELS);  // smclk from xt2
      SET_FLAG(BCSCTL2, DIVS_3);  // divide it by 8
    }
    /* 
     * end clock set up 
     */
#endif /* USE_8MHZ_CRYSTAL */

    TOSH_MAKE_ADC_6_INPUT();   // VSENSE_GSR
    TOSH_SEL_ADC_6_MODFUNC();
    
    atomic {
      memset(tx_packet, 0, (FIXED_PACKET_SIZE*2));
      enable_sending = FALSE;
      command_mode_complete = FALSE;      
    }

    call BTStdControl.init();
    call Bluetooth.disableRemoteConfig(TRUE);
    /* if CPU=8Mhz then customise roving networks baudrate to suit 8Mhz/9 baud */
    /* call Bluetooth.setBaudrate("452"); */

    dma_blocks = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    //call Bluetooth.resetDefaults();
    call BTStdControl.start();
    /* so that user knows the sensor is on and needs battery calibration or else battery has run out */
#ifndef DEBUG_GSR_MODE
   call Leds.redOn();
#endif

#ifdef LOW_BATTERY_INDICATION
    /* initialise baseline voltage measurement stuff */ 
    need_baseline_voltage = TRUE;
    num_baseline_voltage_samples = baseline_voltage = sum_batt_volt_samples = 0;
#ifdef DEBUG_LOW_BATTERY_INDICATION
    debug_counter = 0;
#endif /* DEBUG_LOW_BATTERY_INDICATION */
#endif /* LOW_BATTERY_INDICATION */

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call BTStdControl.stop();
    return SUCCESS;
  }

#ifdef LOW_BATTERY_INDICATION
  
  task void sendBatteryLowIndication() {
    uint16_t crc;
    char batt_low_str[] = "BATTERY LOW!";

    /* stop all sensing - battery is below the threshold */
    call SetupTimer.stop();
    call SampleTimer.stop();
    call DMA0.ADCstopConversion();

    /* send the battery low indication packet to BioMOBIUS */
    tx_packet[1] = FRAMING_BOF;
    tx_packet[2] = SHIMMER_REV1;
    tx_packet[3] = STRING_DATA_TYPE;
    tx_packet[4]++; /* increment sequence number */ 
    tx_packet[5] = timestamp0 & 0xff;
    tx_packet[6] = (timestamp0 >> 8) & 0xff;
    tx_packet[7] = FIXED_PAYLOAD_SIZE;
    memcpy(&tx_packet[8], &batt_low_str[0], 12);

#ifdef DEBUG_LOW_BATTERY_INDICATION
    tx_packet[8] = (baseline_voltage) & 0xff;
    tx_packet[9] = ((baseline_voltage) >> 8) & 0xff;
#endif /* DEBUG_LOW_BATTERY_INDICATION */
    
    crc = calc_crc(&tx_packet[2], (FIXED_PACKET_SIZE-FRAMING_SIZE));
    tx_packet[FIXED_PACKET_SIZE - 2] = crc & 0xff;
    tx_packet[FIXED_PACKET_SIZE - 1] = (crc >> 8) & 0xff;
    tx_packet[FIXED_PACKET_SIZE] = FRAMING_EOF;

    call Bluetooth.write(&tx_packet[1], FIXED_PACKET_SIZE);
    atomic enable_sending = FALSE;

    /* initialise baseline voltage measurement stuff */
    need_baseline_voltage = TRUE;
    num_baseline_voltage_samples = baseline_voltage = sum_batt_volt_samples = 0;
#ifndef DEBUG_GSR_MODE
   call Leds.yellowOn();
#endif
  }

  /* all samples are got so set the baseline voltage for this SHIMMER hardware */
  void setBattVoltageBaseline() {
    baseline_voltage = (sum_batt_volt_samples / TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD);
  }

  /* check voltage level and if it is low then stop sampling, send message and disconnect */
  void checkBattVoltageLevel(uint16_t battery_voltage) {
#ifndef DEBUG_LOW_BATTERY_INDICATION
    if(battery_voltage < (baseline_voltage-BATTERY_LOW_INDICATION_OFFSET)) {
#else
    if(debug_counter++ == 2500) {
#endif /* DEBUG_LOW_BATTERY_INDICATION */
      linkDisconnecting = TRUE;
    }
  }

  /* keep checking the voltage level of the battery until it drops below the offset */
  void monitorBattery() {
    uint16_t battery_voltage;
    if(current_buffer == 1) {
      battery_voltage = sbuf0[1];
    }
    else {
      battery_voltage = sbuf1[1];
    }
    if(need_baseline_voltage) {
      num_baseline_voltage_samples++;      
      if(num_baseline_voltage_samples <= TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD) {
        /* add this sample to the total so that an average baseline can be obtained */
        sum_batt_volt_samples += battery_voltage;
      }
      else {
        setBattVoltageBaseline();
        need_baseline_voltage = FALSE;
#ifndef DEBUG_GSR_MODE
        call Leds.yellowOff();
#endif
      }
    }
    else {
      checkBattVoltageLevel(battery_voltage);
    }
  }
#endif /* LOW_BATTERY_INDICATION */


  /* when looking at DEBUG_GSR_MODE - be careful because when you see a switch */
  /* the switch value in debug will switch but the last sample will be from the */
  /* previous internal resistor and not the new one */
  /* Debug yellow=40k, yellow=280k, red=1M */
  void switchInternalResistor(uint8_t internal_resistor) {
    atomic {
      gsr_hw_state = internal_resistor;
      transient_sample = NUM_SAMPLES_TO_IGNORE;
      max_resistance_step = ONE_HUNDRED_OHM_STEP;
      transient_smoothing_samples = NUM_SMOOTHING_SAMPLES;
      
      /* clear pins first incase */
      TOSH_CLR_PROG_OUT_PIN(); // A0 on ADG658
      TOSH_CLR_SER0_CTS_PIN(); // A1 on ADG658
      
      switch ( internal_resistor ) {
        case HW_RES_40K:
#ifdef DEBUG_GSR_MODE
            call Leds.set(0x00);
            call Leds.yellowOn();
#endif
            TOSH_CLR_PROG_OUT_PIN(); // A0 on ADG658
            TOSH_CLR_SER0_CTS_PIN(); // A1 on ADG658
          break;
        case HW_RES_280K:
#ifdef DEBUG_GSR_MODE
            call Leds.set(0x00);
            call Leds.greenOn();
#endif
            TOSH_SET_PROG_OUT_PIN(); // A0 on ADG658
            TOSH_CLR_SER0_CTS_PIN(); // A1 on ADG658
          break;
        case HW_RES_1M:
#ifdef DEBUG_GSR_MODE
            call Leds.set(0x00);
            call Leds.redOn();
#endif
            TOSH_CLR_PROG_OUT_PIN(); // A0 on ADG658
            TOSH_SET_SER0_CTS_PIN(); // A1 on ADG658
          break;
        case HW_RES_3M3:
#ifdef DEBUG_GSR_MODE
            call Leds.set(0x00);
            call Leds.greenOn();
            call Leds.redOn();
#endif
            TOSH_SET_PROG_OUT_PIN(); // A0 on ADG658
            TOSH_SET_SER0_CTS_PIN(); // A1 on ADG658
          break;

        default:
      }
    }
  }

#ifdef QUICK_RESISTANCE_CALCULATION
  
  /* calculates a resistance from a raw ADC value */
  uint32_t calcResistance(uint16_t ADC_val) {
    uint32_t resistance=0;
    uint64_t adc_pow1, adc_pow2, adc_pow3, adc_pow4;
    switch ( gsr_hw_state ) {
      case HW_RES_40K:
        /**/
        adc_pow1 = ADC_val;
        adc_pow2 = multiply(adc_pow1, ADC_val);
        adc_pow3 = multiply(adc_pow2, ADC_val);
        adc_pow4 = multiply(adc_pow3, ADC_val);

        resistance = (
                 ( (HW_RES_40K_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
                 ( (HW_RES_40K_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
                 ( (HW_RES_40K_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
                 ( (HW_RES_40K_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
                 (HW_RES_40K_CONSTANT_5) );
                 /**/
                 
        if (ADC_val < HW_RES_40K_MIN_ADC_VAL) {
          switchInternalResistor(HW_RES_280K);
        }
      break;
      case HW_RES_280K:

        adc_pow1 = ADC_val;
        adc_pow2 = multiply(adc_pow1, ADC_val);
        adc_pow3 = multiply(adc_pow2, ADC_val);
        adc_pow4 = multiply(adc_pow3, ADC_val);

        resistance = (
                 ( (HW_RES_280K_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
                 ( (HW_RES_280K_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
                 ( (HW_RES_280K_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
                 ( (HW_RES_280K_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
                 (HW_RES_280K_CONSTANT_5) );

        if( (ADC_val <= HW_RES_280K_MAX_ADC_VAL) && (ADC_val >= HW_RES_280K_MIN_ADC_VAL) ) {
          ;//stay here
        } else if (ADC_val < HW_RES_280K_MIN_ADC_VAL) {
          switchInternalResistor(HW_RES_1M);
        } else {
          switchInternalResistor(HW_RES_40K);
        }
        break;
      case HW_RES_1M:
        adc_pow1 = ADC_val;
        adc_pow2 = multiply(adc_pow1, ADC_val);
        adc_pow3 = multiply(adc_pow2, ADC_val);
        adc_pow4 = multiply(adc_pow3, ADC_val);

        resistance = (
                 ( (HW_RES_1M_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
                 ( (HW_RES_1M_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
                 ( (HW_RES_1M_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
                 ( (HW_RES_1M_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
                 (HW_RES_1M_CONSTANT_5) );

        if( (ADC_val <= HW_RES_1M_MAX_ADC_VAL) && (ADC_val >= HW_RES_1M_MIN_ADC_VAL) ) {
          ;//stay here
        } else if (ADC_val < HW_RES_1M_MIN_ADC_VAL) {
          switchInternalResistor(HW_RES_3M3);
        } else {
          switchInternalResistor(HW_RES_280K);
        }
        break;
      case HW_RES_3M3:
        adc_pow1 = ADC_val;
        adc_pow2 = multiply(adc_pow1, ADC_val);
        adc_pow3 = multiply(adc_pow2, ADC_val);
        adc_pow4 = multiply(adc_pow3, ADC_val);

        resistance = (
                 ( (HW_RES_3M3_CONSTANT_1)* adc_pow4) + //(powf(ADC_val,4)) ) + 
                 ( (HW_RES_3M3_CONSTANT_2)* adc_pow3) + //(powf(ADC_val,3)) ) + 
                 ( (HW_RES_3M3_CONSTANT_3)* adc_pow2) + //(powf(ADC_val,2)) ) + 
                 ( (HW_RES_3M3_CONSTANT_4)* adc_pow1) + //(powf(ADC_val,1)) ) + 
         (HW_RES_3M3_CONSTANT_5) );

        if( (ADC_val <= HW_RES_3M3_MAX_ADC_VAL) && (ADC_val >= HW_RES_3M3_MIN_ADC_VAL) ) {
          ;//stay here
        } else if (ADC_val > HW_RES_3M3_MAX_ADC_VAL) {
          switchInternalResistor(HW_RES_1M);
        } else {
          /* MIN so cant go any higher*/
        }
        break;
      default:
    }
    return resistance;
  }
  
#else /* using powf - does a log then and exponential */

  /* calculates a resistance from a raw ADC value */
  uint32_t calcResistance(uint16_t ADC_val) {
    uint32_t resistance=0;
    switch ( gsr_hw_state ) {
      case HW_RES_40K:
        resistance = (
                 ( (HW_RES_40K_CONSTANT_1)*(powf(ADC_val,4)) ) + 
                 ( (HW_RES_40K_CONSTANT_2)*(powf(ADC_val,3)) ) + 
                 ( (HW_RES_40K_CONSTANT_3)*(powf(ADC_val,2)) ) + 
                 ( (HW_RES_40K_CONSTANT_4)*(powf(ADC_val,1)) ) + HW_RES_40K_CONSTANT_5 );

        if (ADC_val < HW_RES_40K_MIN_ADC_VAL) {
          switchInternalResistor(HW_RES_280K);
        }
      break;
      case HW_RES_280K:
        resistance = (
                 ( (HW_RES_280K_CONSTANT_1)*(powf(ADC_val,4)) ) + 
                 ( (HW_RES_280K_CONSTANT_2)*(powf(ADC_val,3)) ) + 
                 ( (HW_RES_280K_CONSTANT_3)*(powf(ADC_val,2)) ) + 
                 ( (HW_RES_280K_CONSTANT_4)*(powf(ADC_val,1)) ) + HW_RES_280K_CONSTANT_5 );

        if( (ADC_val <= HW_RES_280K_MAX_ADC_VAL) && (ADC_val >= HW_RES_280K_MIN_ADC_VAL) ) {
          ;//stay here
        } else if (ADC_val < HW_RES_280K_MIN_ADC_VAL) {
          switchInternalResistor(HW_RES_1M);
        } else {
          switchInternalResistor(HW_RES_40K);
        }
        break;
      case HW_RES_1M:
        resistance = (
                 ( (HW_RES_1M_CONSTANT_1)*(powf(ADC_val,4)) ) + 
                 ( (HW_RES_1M_CONSTANT_2)*(powf(ADC_val,3)) ) + 
                 ( (HW_RES_1M_CONSTANT_3)*(powf(ADC_val,2)) ) + 
                 ( (HW_RES_1M_CONSTANT_4)*(powf(ADC_val,1)) ) + HW_RES_1M_CONSTANT_5 );

        if( (ADC_val <= HW_RES_1M_MAX_ADC_VAL) && (ADC_val >= HW_RES_1M_MIN_ADC_VAL) ) {
          ;//stay here
        } else if (ADC_val < HW_RES_1M_MIN_ADC_VAL) {
          switchInternalResistor(HW_RES_3M3);
        } else {
          switchInternalResistor(HW_RES_280K);
        }
        break;
      case HW_RES_3M3:
        resistance = (
                 ( (HW_RES_3M3_CONSTANT_1)*(powf(ADC_val,4)) ) + 
                 ( (HW_RES_3M3_CONSTANT_2)*(powf(ADC_val,3)) ) + 
                 ( (HW_RES_3M3_CONSTANT_3)*(powf(ADC_val,2)) ) + 
                 ( (HW_RES_3M3_CONSTANT_4)*(powf(ADC_val,1)) ) + HW_RES_3M3_CONSTANT_5 );

        if( (ADC_val <= HW_RES_3M3_MAX_ADC_VAL) && (ADC_val >= HW_RES_3M3_MIN_ADC_VAL) ) {
          ;//stay here
        } else if (ADC_val > HW_RES_3M3_MAX_ADC_VAL) {
          switchInternalResistor(HW_RES_1M);
        } else {
          /* MIN so cant go any higher*/
        }
        break;
      default:
    }
    return resistance;
  }

#endif /* QUICK_RESISTANCE_CALCULATION */
  
  /* The MSP430 CPU is byte addressed and little endian */
  /* packets are sent little endian so the word 0xABCD will be sent as bytes 0xCD 0xAB */
  void preparePacket() {
    uint16_t *p_packet, *p_ADCsamples, crc;
    uint32_t resistance;
    
    tx_packet[1] = FRAMING_BOF;
    tx_packet[2] = SHIMMER_REV1;
    tx_packet[3] = PROPRIETARY_DATA_TYPE;
    tx_packet[4]++; /* increment sequence number */ 

    tx_packet[7] = FIXED_PAYLOAD_SIZE;

    p_packet = (uint16_t *)&tx_packet[8];
      
    if(current_buffer == 1) {
      p_ADCsamples = &sbuf0[0];
      tx_packet[5] = timestamp0 & 0xff;
      tx_packet[6] = (timestamp0 >> 8) & 0xff;
    }
    else {
      p_ADCsamples = &sbuf1[0];
      tx_packet[5] = timestamp1 & 0xff;
      tx_packet[6] = (timestamp1 >> 8) & 0xff;
    }
    /* copy all the data samples into the outgoing packet */
    *p_packet = *p_ADCsamples; //tx_packet[8]
    

/* debug stuff - capture battery voltage to monitor discharge */
#ifdef DEBUG_LOW_BATTERY_INDICATION
    if(current_buffer == 1) {
      tx_packet[8] = (sbuf0[1]) & 0xff;
      tx_packet[9] = ((sbuf0[1]) >> 8) & 0xff;
    }
    else {
      tx_packet[8] = (sbuf1[1]) & 0xff;
      tx_packet[9] = ((sbuf1[1]) >> 8) & 0xff;
    }
#endif /* LOW_BATTERY_INDICATION */

    /* if we are after a transition then max_resistance_step will be small to ensure smooth transition */
    if (transient_smoothing_samples) {
      transient_smoothing_samples--;
      /* if we are finished smoothing then go back to a larger resistance step */
      if (!transient_smoothing_samples)
        max_resistance_step = MAX_RESISTANCE_STEP;
    }
    /* only prevent a large step from last resistance if we actually have a last resistance */
    if ((got_first_sample) && (last_resistance > max_resistance_step)) {
      resistance = calcResistance(*p_ADCsamples);
      if( resistance > (last_resistance+max_resistance_step) )
        resistance = (last_resistance+max_resistance_step);
      else if ( resistance < (last_resistance-max_resistance_step) )
        resistance = (last_resistance-max_resistance_step);
      else
        ;
    } else {
      /* get the first sample in this run of sampling */
      resistance = calcResistance(*p_ADCsamples);
      atomic got_first_sample = TRUE;
    }

    last_resistance = resistance;
    
    /* if this sample is near a resistor transition then dont send a special code for data analysis */
    if(transient_sample) {
      transient_sample--;
      resistance = 0xFFFFFFFF;
    }

    tx_packet[8] = (resistance & 0xff);
    tx_packet[9] = (resistance >> 8) & 0xff;
    tx_packet[10] = (resistance >> 16) & 0xff;
    tx_packet[11] = (resistance >> 24) & 0xff;

#ifdef DEBUG_GSR_MODE
    /* Debug Data Format - | RawADC | InternalResistor number | */
    tx_packet[8] = ((*p_ADCsamples) & 0xff);
    tx_packet[9] = (((*p_ADCsamples) >> 8) & 0xff);

//#if 0
    switch ( gsr_hw_state ) {
      case HW_RES_40K:
        tx_packet[10] = 1;
        tx_packet[11] = 0;
        break;
      case HW_RES_280K:
        tx_packet[10] = 2;
        tx_packet[11] = 0;        
        break;        
      case HW_RES_1M:
        tx_packet[10] = 3;
        tx_packet[11] = 0;
        break;
      case HW_RES_3M3:
        tx_packet[10] = 4;
        tx_packet[11] = 0;
        break;
      default:
    }
//#endif
#endif
    crc = calc_crc(&tx_packet[2], (FIXED_PACKET_SIZE-FRAMING_SIZE));
    tx_packet[FIXED_PACKET_SIZE - 2] = crc & 0xff;
    tx_packet[FIXED_PACKET_SIZE - 1] = (crc >> 8) & 0xff;
    tx_packet[FIXED_PACKET_SIZE] = FRAMING_EOF;
  }

  task void sendSensorData() {
#ifdef LOW_BATTERY_INDICATION
    monitorBattery();
#endif /* LOW_BATTERY_INDICATION */

    atomic if(enable_sending) {
      preparePacket();

      /* send data over the air */
      call Bluetooth.write(&tx_packet[1], FIXED_PACKET_SIZE);
      atomic enable_sending = FALSE;
    }
  }

  task void startSensing() {
    call SampleTimer.start(TIMER_REPEAT, sample_freq);

    /* Setup GSR, always start with S1, the 40K internal resistor on GSR board*/ 
    atomic {
      gsr_hw_state = HW_RES_40K;
      transient_sample = NUM_SAMPLES_TO_IGNORE;
      max_resistance_step = MAX_RESISTANCE_STEP;
      transient_smoothing_samples = 0;
      got_first_sample=FALSE;
      last_resistance = STARTING_RESISTANCE;
    }

#ifdef DEBUG_GSR_MODE
    call Leds.set(0x00);
    call Leds.yellowOn();
#endif
    
    /* setup address lines to the ADG658 switch */
    TOSH_MAKE_PROG_OUT_OUTPUT(); //A0
    TOSH_SEL_PROG_OUT_IOFUNC();

    TOSH_MAKE_SER0_CTS_OUTPUT(); //A1
    TOSH_SEL_SER0_CTS_IOFUNC();

    TOSH_CLR_PROG_OUT_PIN();
    TOSH_CLR_SER0_CTS_PIN();
           
    sampleADC();
  }

  task void sendPersonality() {
    atomic if(enable_sending) {
      /* send data over the air */
      call Bluetooth.write(&personality[0], 17);
      atomic enable_sending = FALSE;
    }
  }

  task void stopSensing() {
    call SetupTimer.stop();
    call SampleTimer.stop();
    call DMA0.ADCstopConversion();

#ifdef DEBUG_GSR_MODE
    call Leds.set(0x00);
#endif

    TOSH_CLR_PROG_OUT_PIN();
    TOSH_CLR_SER0_CTS_PIN();
  }

  async event void Bluetooth.connectionMade(uint8_t status) { 
    atomic enable_sending = TRUE;
#ifndef DEBUG_GSR_MODE
    call Leds.greenOn();
#endif
  }

  async event void Bluetooth.commandModeEnded() { 
    atomic command_mode_complete = TRUE;
  }
    
  async event void Bluetooth.connectionClosed(uint8_t reason){
    atomic enable_sending = FALSE;    
#ifndef DEBUG_GSR_MODE
    call Leds.greenOff();
#endif

    post stopSensing();
  }

  async event void Bluetooth.dataAvailable(uint8_t data){
    /* start capturing on ^G */
    if(7 == data) {
      atomic if(command_mode_complete) {
        post startSensing();
      }
      else {
        /* give config a chance, wait 5 secs */
        call SetupTimer.start(TIMER_REPEAT, 5000);
      }
    }
    /* see ADG658 truth table for details on values for each switch inputs */
    else if (data == 0x6E) { //'n'
      atomic gsr_hw_state = HW_RES_40K;
      TOSH_CLR_PROG_OUT_PIN(); //40.2k
      TOSH_CLR_SER0_CTS_PIN();
      call Leds.set(0x00);
      call Leds.redOn();
    }
    else if (data == 0x6F) {
      atomic gsr_hw_state = HW_RES_280K;
      TOSH_SET_PROG_OUT_PIN(); //274k
      TOSH_CLR_SER0_CTS_PIN();
      call Leds.set(0x00);
      call Leds.yellowOn();
    }
    else if (data == 0x70) {
      atomic gsr_hw_state = HW_RES_1M;
      TOSH_CLR_PROG_OUT_PIN(); //1M
      TOSH_SET_SER0_CTS_PIN();
      call Leds.set(0x00);
      call Leds.greenOn();
    }
    else if (data == 0x71) {
      atomic gsr_hw_state = HW_RES_3M3;
      TOSH_SET_PROG_OUT_PIN(); //3.3M
      TOSH_SET_SER0_CTS_PIN();
      call Leds.set(0x00);
      call Leds.redOn();
    }
    /* stop capturing on spacebar */
    else if (data == 32) {
      post stopSensing();
    }
    else { /* were done */ }
  }

  event void Bluetooth.writeDone(){
    atomic enable_sending = TRUE;

#ifdef LOW_BATTERY_INDICATION
    if(linkDisconnecting) {
      linkDisconnecting = FALSE;
      /* signal battery low to master and let the master disconnect the link */
      post sendBatteryLowIndication();
    }
#endif /* LOW_BATTERY_INDICATION */

  }

  event result_t SetupTimer.fired() {
    atomic if(command_mode_complete){
      post startSensing();
    }
    return SUCCESS;
  }

  event result_t SampleTimer.fired() {
    call DMA0.beginTransfer();
    call DMA0.ADCbeginConversion();
    return SUCCESS;
  }

  async event void DMA0.transferComplete() {
    dma_blocks++;
    //atomic DMA0DA += 12;
    if(dma_blocks == 1){ //this should be about 6 but for this test its 1
      dma_blocks = 0;

      if(current_buffer == 0){
        atomic DMA0DA = (uint16_t)&sbuf1[0];
        atomic timestamp1 = call LocalTime.read();
        current_buffer = 1;
      }
      else { 
        atomic DMA0DA = (uint16_t)&sbuf0[0];
        atomic timestamp0 = call LocalTime.read();
        current_buffer = 0;
      }
      post sendSensorData();      
    }
  }

  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    // we should *not* see this, as the adc interrupts are eaten by the dma controller!
    /* Turn on all LEDs */
    call Leds.set(0x0F);
  } 
}

