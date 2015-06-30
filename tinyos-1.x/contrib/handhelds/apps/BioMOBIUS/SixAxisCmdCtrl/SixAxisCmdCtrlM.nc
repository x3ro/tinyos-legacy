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
 *         November, 2007
 */

 /***********************************************************************************

   This app is an example that shows how the SerialCommandParser interface can 
   be used to control and configure SHIMMER from a BioMOBIUS PC application.

   Default Sample Frequency: 100 hz
   
   Packet Format:
         BOF| Sensor ID | Data Type | Seq No. | TimeStamp | Len | Acc | Acc  | Acc  | Gyro  | Gyro | Gyro |  CRC | EOF
   Byte:  1 |    2      |     3     |    4    |     5-6   |  7  | 8-9 | 10-11| 12-13| 14-15 | 16-17| 18-19| 20-21| 22

 ***********************************************************************************/

includes crc;
includes SixAxisCmdCtrl;
includes DMA;
includes MMA_Accel;
includes Message;
includes RovingNetworks;


module SixAxisCmdCtrlM {
  provides{
    interface StdControl;
    interface SensorControl;
  }
  uses {
    interface DMA as DMA0;

    interface StdControl as AccelStdControl;
    interface StdControl as SerialCommandStdControl;
    interface MMA_Accel as Accel;

    interface StdControl as GyroStdControl;
    interface GyroBoard;

    interface StdControl as BTStdControl;
    interface Bluetooth;

    interface Leds;
    interface Timer as ActivityTimer;
    interface Timer as SampleTimer;
    interface LocalTime;
    interface SerialCommandParser;
  }
}

implementation {
 
#define USE_8MHZ_CRYSTAL
#define USE_AVCC_REF /* approx 0.5 milliamps saving when using AVCC compared to 2.5V or 1.5V internal ref */

#ifdef LOW_BATTERY_INDICATION
  //#define DEBUG_LOW_BATTERY_INDICATION
  /* during testing of the the (AVcc-AVss)/2 value from the ADC on various SHIMMERS, to get a reliable cut off point 
     to recharge the battery it is important to find the baseline (AVcc-AVss)/2 value coming from the ADC as it varies 
     from SHIMMER to SHIMMER, however the range of fluctuation is pretty constant and (AVcc-AVss)/2 provides an accurate 
     battery low indication that prevents getting any voltage skewed data from the accelerometer or add-on board sensors */
  #define TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD 1000
  #define BATTERY_LOW_INDICATION_OFFSET 20 /* (AVcc - AVss)/2 = Approx 3V-0V/2 = 1.5V, 12 bit ADC with 2.5V REF,
                                              4096/2500 = 1mV=1.6384 units */ 
  bool need_baseline_voltage, linkDisconnecting, battPacketPending;
  uint16_t num_baseline_voltage_samples, baseline_voltage;
  uint32_t sum_batt_volt_samples;

#ifdef DEBUG_LOW_BATTERY_INDICATION
  uint16_t debug_counter;
#endif /* DEBUG_LOW_BATTERY_INDICATION */

#endif /* LOW_BATTERY_INDICATION */


  task void startSensing();
  task void stopSensing();

  #define FIXED_PACKET_SIZE 22
  #define FIXED_PAYLOAD_SIZE 12
  uint8_t tx_packet[(FIXED_PACKET_SIZE*2)+1]; /* (*2)twice size because of byte stuffing */
                                              /* (+1)MSP430 CPU can only read/write 16-bit values at even addresses, 
                                              /* so use an empty byte to even up the memory locations for 16-bit values */
  #define MAX_CMD_PACKET_SIZE 50
  uint8_t tx_cmd_packet[MAX_CMD_PACKET_SIZE*2]; /* (*2)twice size because of byte stuffing */

  const uint8_t personality[17] = {
    0,1,2,3,4,5,0xFF,0xFF,
    SAMPLING_50HZ,SAMPLING_50HZ,SAMPLING_50HZ,SAMPLING_50HZ,
    SAMPLING_50HZ,SAMPLING_50HZ,SAMPLING_0HZ_OFF,SAMPLING_0HZ_OFF,FRAMING_EOF
  };

  norace uint8_t current_buffer = 0, dma_blocks = 0, g_data;
  uint16_t sbuf0[36], sbuf1[36], timestamp0, timestamp1, 
           sample_freq = SAMPLING_100HZ, new_sample_freq = SAMPLING_0HZ_OFF;

  bool enable_sending, command_mode_complete, activity_led_on, sensor_sampling=FALSE, cmdPacketPending;
  
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
    call DMA0.setBlockSize(7);

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

    SET_FLAG(ADC12MCTL0, INCH_5);  // accel x 
    SET_FLAG(ADC12MCTL1, INCH_4);  // accel y 
    SET_FLAG(ADC12MCTL2, INCH_3);  // accel z 
    SET_FLAG(ADC12MCTL3, INCH_1);  // x gyro
    SET_FLAG(ADC12MCTL4, INCH_6);  // y gyro
    SET_FLAG(ADC12MCTL5, INCH_2);  // z gyro
    SET_FLAG(ADC12MCTL6, INCH_11); // (AVcc-AVss)/2 to monitor battery voltage
    SET_FLAG(ADC12MCTL6, EOS);     //sez "this is the last reg" 

#ifdef USE_AVCC_REF
    // set reference to analog voltage AVcc
    CLR_FLAG(ADC12CTL0, REFON);
    CLR_FLAG(ADC12MCTL0, SREF_7);
    CLR_FLAG(ADC12MCTL1, SREF_7);
    CLR_FLAG(ADC12MCTL2, SREF_7);
    CLR_FLAG(ADC12MCTL3, SREF_7);
    CLR_FLAG(ADC12MCTL4, SREF_7);
    CLR_FLAG(ADC12MCTL5, SREF_7);
    CLR_FLAG(ADC12MCTL6, SREF_7);    
#else
    SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL2, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL3, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL4, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL5, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL6, SREF_1);             // Vref = Vref+ and Vr-    
#endif /* USE_AVCC_REF */
    
    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
    
    setupDMA();

    call DMA0.beginTransfer();
  }

  /*****************************************
   * StdControl interface
   *****************************************/
  
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
      SET_FLAG(BCSCTL2, DIVS_3);  // divide it by 8, 8MHZ/8=1MHZ
    }
    /* 
     * end clock set up 
     */
#endif /* USE_8MHZ_CRYSTAL */

    call AccelStdControl.init();

    // pins for gyro, gyro enable
    TOSH_MAKE_ADC_1_INPUT();   // x
    TOSH_MAKE_ADC_2_INPUT();   // z
    TOSH_MAKE_ADC_6_INPUT();   // y

    TOSH_SEL_ADC_1_MODFUNC();
    TOSH_SEL_ADC_2_MODFUNC();
    TOSH_SEL_ADC_6_MODFUNC();
    
    atomic {
      memset(tx_packet, 0, (FIXED_PACKET_SIZE*2));
      memset(tx_cmd_packet, 0, (MAX_CMD_PACKET_SIZE*2));
      enable_sending = FALSE;
      cmdPacketPending = FALSE;
      command_mode_complete = FALSE;
      activity_led_on = FALSE;
    }

    call BTStdControl.init();
    call Bluetooth.disableRemoteConfig(TRUE);
    /* if CPU=8Mhz then customise roving networks baudrate to suit 8Mhz/9 baud */
    /* call Bluetooth.setBaudrate("452"); */

    call SerialCommandStdControl.init();
    dma_blocks = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call BTStdControl.start();
    call SerialCommandStdControl.start();

#ifdef LOW_BATTERY_INDICATION
    /* initialise baseline voltage measurement stuff */ 
    need_baseline_voltage = TRUE;
    linkDisconnecting = FALSE;
    battPacketPending = FALSE;
    num_baseline_voltage_samples = baseline_voltage = sum_batt_volt_samples = 0;
    call Leds.redOn();
#ifdef DEBUG_LOW_BATTERY_INDICATION
    debug_counter = 0;
#endif /* DEBUG_LOW_BATTERY_INDICATION */
#endif /* LOW_BATTERY_INDICATION */

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Leds.redOff();
    call BTStdControl.stop();
    call SerialCommandStdControl.stop();
    return SUCCESS;
  }
  
  task void setSampleFrequency() {
    result_t result;

    sample_freq = new_sample_freq;
    if(sensor_sampling) {
      call SampleTimer.stop();
      call SampleTimer.start(TIMER_REPEAT, sample_freq);
    }
    signal SensorControl.sampleFrequencyChanged(SUCCESS);
  }

  /*****************************************
   * SensorControl interface
   *****************************************/

  command result_t SensorControl.startStreaming(){
    if(command_mode_complete) {
      post startSensing();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t SensorControl.stopStreaming(){
    post stopSensing();
    return SUCCESS;
  }

  command result_t SensorControl.startLogging(){
  }

  command result_t SensorControl.stopLogging(){
  }

  command result_t SensorControl.getCardData(){
  }

  command uint8_t SensorControl.getActiveRadio(){
    return 'B'; /* Bluetooth */
  }
  
  command result_t SensorControl.changeSampleFrequency(uint16_t new_freq){

    switch ( new_freq ) {
      case 1000:
        new_freq = SAMPLING_1000HZ;
      break;
      case 500:
        new_freq = SAMPLING_500HZ;
      break;
      case 250:
        new_freq = SAMPLING_250HZ;
      break;
      case 200:
        new_freq = SAMPLING_200HZ;
      break;
      case 166:
        new_freq = SAMPLING_166HZ;
      break;
      case 125:
        new_freq = SAMPLING_125HZ;
      break;
      case 100:
        new_freq = SAMPLING_100HZ;
      break;
      case 50:
        new_freq = SAMPLING_50HZ;
      break;
      case 10:
        new_freq = SAMPLING_10HZ;
      break;
    }

    if(new_freq == sample_freq) {
      signal SensorControl.sampleFrequencyChanged(SUCCESS);
      return SUCCESS;
    }
    new_sample_freq = new_freq;
    post setSampleFrequency();
  }

  command uint16_t SensorControl.getSampleFrequency(){
    switch ( sample_freq ) {
      case SAMPLING_1000HZ:
        return 1000;
      case SAMPLING_500HZ:
        return 500;
      case SAMPLING_250HZ:
        return 250;
      case SAMPLING_200HZ:
        return 200;
      case SAMPLING_166HZ:
        return 166;
      case SAMPLING_125HZ:
        return 125;
      case SAMPLING_100HZ:
        return 100;
      case SAMPLING_50HZ:
        return 50;
      case SAMPLING_10HZ:
        return 10;
      default:
        return 0;
    }
  }

  task void sendCmdPacket() {
    atomic if(enable_sending) {
      call Bluetooth.write(tx_cmd_packet, (tx_cmd_packet[6]+10));
      atomic enable_sending = FALSE;
      cmdPacketPending = FALSE;
    } 
    else
      cmdPacketPending = TRUE;
  }

  event result_t SerialCommandParser.responseReady(const uint8_t *buf, uint16_t len) {
    uint16_t crc;
    tx_cmd_packet[0] = FRAMING_BOF;
    tx_cmd_packet[1] = SHIMMER_REV1;
    tx_cmd_packet[2] = COMMAND_DATA_TYPE;
    tx_cmd_packet[3]++; /* increment sequence number */ 
    tx_cmd_packet[4] = tx_cmd_packet[5] = 0; /* no use for time stamp */
    tx_cmd_packet[6] = len;
    memcpy(&tx_cmd_packet[7], buf, len);
    crc = calc_crc(&tx_cmd_packet[1], ((10+len)-FRAMING_SIZE));
    tx_cmd_packet[len+7] = crc & 0xff;
    tx_cmd_packet[len+8] = (crc >> 8) & 0xff;
    tx_cmd_packet[len+9] = FRAMING_EOF;
    post sendCmdPacket();
    return SUCCESS;
  }

#ifdef LOW_BATTERY_INDICATION
  
  task void sendBattMessage() {
    atomic if(enable_sending) {
      call Bluetooth.write(&tx_packet[1], FIXED_PACKET_SIZE);
      atomic enable_sending = FALSE;
      battPacketPending = FALSE;
    }
    else
      battPacketPending = TRUE;
  }

  task void sendBatteryLowIndication() {
    uint16_t crc;
    char batt_low_str[] = "BATTERY LOW!";

    /* stop all sensing - battery is below the threshold */
    call SampleTimer.stop();
    call ActivityTimer.stop();
    call DMA0.ADCstopConversion();
    call AccelStdControl.stop();
    call Leds.yellowOff();

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

    /* re-initialise baseline voltage measurement stuff */
    need_baseline_voltage = TRUE;
    num_baseline_voltage_samples = baseline_voltage = sum_batt_volt_samples = 0;
    call Leds.redOn();

    post sendBattMessage();
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
      battery_voltage = sbuf0[6];
    }
    else {
      battery_voltage = sbuf1[6];
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
        call Leds.redOff();
      }
    }
    else {
      checkBattVoltageLevel(battery_voltage);
    }
  }
#endif /* LOW_BATTERY_INDICATION */


  /* The MSP430 CPU is byte addressed and little endian */
  /* packets are sent little endian so the word 0xABCD will be sent as bytes 0xCD 0xAB */
  void preparePacket() {
    uint16_t *p_packet, *p_ADCsamples, crc;
    
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
    *p_packet++ = *p_ADCsamples++; //tx_packet[8]
    *p_packet++ = *p_ADCsamples++; //tx_packet[10]
    *p_packet++ = *p_ADCsamples++; //tx_packet[12]
    *p_packet++ = *p_ADCsamples++; //tx_packet[14]
    *p_packet++ = *p_ADCsamples++; //tx_packet[16]
    *p_packet = *p_ADCsamples; //tx_packet[18]

/* debug stuff - capture battery voltage to monitor discharge */
#ifdef DEBUG_LOW_BATTERY_INDICATION
    if(current_buffer == 1) {
      tx_packet[18] = (sbuf0[6]) & 0xff;
      tx_packet[19] = ((sbuf0[6]) >> 8) & 0xff;
    }
    else {
      tx_packet[18] = (sbuf1[6]) & 0xff;
      tx_packet[19] = ((sbuf1[6]) >> 8) & 0xff;
    }
#endif /* LOW_BATTERY_INDICATION */

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
    register uint16_t i;
    signal SensorControl.streamingStarted(SUCCESS);
    for(i = 0; i < 400 ; i++) // give the receiver a chance to receive the command response
      TOSH_uwait(5000);

    call ActivityTimer.start(TIMER_ONE_SHOT, 1000);
    call AccelStdControl.start();
    call Accel.setSensitivity(RANGE_4_0G);

    call SampleTimer.start(TIMER_REPEAT, sample_freq);

    call GyroStdControl.init();
    call GyroStdControl.start();
    sampleADC();
    sensor_sampling = TRUE;
  }

  task void sendPersonality() {
    atomic if(enable_sending) {
      /* send data over the air */
      call Bluetooth.write(&personality[0], 17);
      atomic enable_sending = FALSE;
    }
  }

  task void stopSensing() {
    call SampleTimer.stop();
    call ActivityTimer.stop();
    call DMA0.ADCstopConversion();
    call AccelStdControl.stop();
    call GyroStdControl.stop();
    call Leds.yellowOff();
    signal SensorControl.streamingStopped(SUCCESS);
    sensor_sampling = FALSE;
  }

  async event void Bluetooth.connectionMade(uint8_t status) { 
    atomic enable_sending = TRUE;
    call Leds.greenOn();
  }

  async event void Bluetooth.commandModeEnded() { 
    atomic command_mode_complete = TRUE;
  }
    
  async event void Bluetooth.connectionClosed(uint8_t reason){
    atomic enable_sending = FALSE;    
    call Leds.greenOff();

    post stopSensing();
  }

  async event void Bluetooth.dataAvailable(uint8_t data){
    call SerialCommandParser.handleByte(data);
  }

  async event void GyroBoard.buttonPressed() { }

  event void Bluetooth.writeDone(){
    atomic enable_sending = TRUE;

#ifdef LOW_BATTERY_INDICATION
    if(linkDisconnecting) {
      linkDisconnecting = FALSE;
      /* signal battery low to master and let the master disconnect the link */
      post sendBatteryLowIndication();
      return;
    }
    atomic if(battPacketPending) {
      post sendBattMessage();
    }

#endif /* LOW_BATTERY_INDICATION */
    atomic if(cmdPacketPending) {
      post sendCmdPacket();
    }
  }

  event result_t ActivityTimer.fired() {
      atomic {
        /* toggle activity led every second */
        if(activity_led_on) {
          call Leds.yellowOn();
          activity_led_on = FALSE;
	  call ActivityTimer.start(TIMER_ONE_SHOT, 125);
        }
        else {
          call Leds.yellowOff();
          activity_led_on = TRUE;
	  call ActivityTimer.start(TIMER_ONE_SHOT, 3000);
        }
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

