/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
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
 * Author: Steve Ayer/Adrian Burns, March, 2007
 *         Michael Fogarty (Mail Author), July 2007
 *         Portions from Jason Waterman's ThreeAxisRecorder shimmer code
 *         with thanks to Stephen Linder whose FAT_ logging code provided guidance.
 *
 * $Author: ayer1 $ $Date: 2010/02/10 18:51:06 $ $Revision: 1.3 $
 *
 */

/***********************************************************************************

   This app has multiple uses.
   1. It uses Bluetooth to stream various combinations of data to BioMOBIUS. 
   Eg. Accelerometer only, Accel + Gyro data, Accel + ECG data etc.
   It allows the SHIMMER device to be configured and controlled from the BioMOBIUS V2 
   SHIMMER block.
   
   2. It can also save data to the micro SD card (NOTE:SD logging code is still under 
   development and is not validated).

   IMPORTANT: For this firmware to function properly it needs to communicate to the 
   BioMOBIUS V2 SHIMMER Block.
   
   It allows the SHIMMER device to be configured and controlled from the BioMOBIUS 2.0
   SHIMMER block. This firmware is the firmware that has all of these controls implemented.
   Other legacy firmware that may report personality data differently or that doesn't accept 
   channel sequence changes should still basically work with the new BioMOBIUS 2.0 shimmer block.
   This is because the REV1 packet format is consistent across all shimmer firmware 
   implementations. This firmware implements a REC2 packet format in additiion to Rev1.
   
   LOW_BATTERY_INDICATION if defined stops the app streaming data just after the 
   battery voltage drops below the regulator value of 3V.

   Default Sample Frequency: 50 hz

   Rev 1 Packet Format
   The historical packet format, kind of large and very good for detecting byte or 
   packet losses because it is checksummed and sequenced

   Rev 1 packets have a lot of overhead to make it easy for EyesWeb to detect when
         it has missed something.  This format is suitable when streaming data across
         the BT radio.
   Rev 2 packets are useful in situations where small comms dropouts aren't an issue.
         They're much smaller and so better for higher frequencies.  They're automatically
         used if the shimmer is recording to SD.
   
   Rev 1 Packet Format:
      BOF|Sensor ID|Data Type|Seq No.|TimeStamp|Len| SampleData        | CRC | EOF
   Byte1 |    2    |    3    |   4   |    5-6  | 7 |8 - sample_count*2 | +1-2| +3

   Rev 2 Packet Format:   
   A small, tight packet format that is isochronous in spirit. That is, it is designed 
   to recover quickly if bytes are lost and lost data is unimportant relative to getting 
   the latest data through. This is the mode the shimmer slip into when SD recording is enabled.
   
   
      Function      b7 b6 b5 b4 b3 b2 b1 b0
      -------------------------------------
      SYNC byte     1  0  x  x  x  x  x  x    
      sample0       0  0  lower 6 bits of sample data
      sample0       0  1  upper 6 bits of sample data
      sample1       0  0  lower 6 bits of sample data
      sample1       0  1  upper 6 bits of sample data
      ...
      SYNC byte  ...

   b6 is a toggle bit, reset by reception of SYNC byte

***********************************************************************************/

includes crc;
includes Shimmer;
includes DMA;
includes MMA7260_Accel;
includes RovingNetworks;

module ReconfigurableM {
  provides{
    interface StdControl;
  }
  uses {
    interface DMA as DMA0;

    interface StdControl as AccelStdControl;
    interface MMA7260_Accel as Accel;
    interface SD;
    interface StdControl as BTStdControl;
    interface Bluetooth;

    interface Leds;
    interface Timer as SetupTimer;
    interface Timer as ActivityTimer;
    interface TimerJiffyAsync as AsyncSampleTimer;
    interface StdControl as AsyncSampleTimerControl;
    interface LocalTime;
  }
} 

implementation {

  /* comment out USE_8MHZ_CRYSTAL and load this code once so that the
     baudrate of the RovingNetworks Bluetooth module is setup(once
     only), then uncomment it and load for 8MHZ operation */
#define USE_8MHZ_CRYSTAL
  //#define LOW_BATTERY_INDICATION

  // SD related defs
#define START_SECTOR 2000
#define TIMESTAMP_DATA_OFFSET 0
#define TIMESTAMP_DATA_LENGTH 2 // 2 words
#define SAMPLE_DATA_OFFSET 2    // starts right after

  // bluetooth comms buffer macros
    //#define BT_TX_BUFF_SIZE 600 
#define BT_TX_BUFF_SIZE 1030 // 1024B sample buffer w/ ^q command during debug
#define NEXT_BUFFER(ent) (((ent) >= ((BT_TX_BUFF_SIZE) - 1)) ? 0 : ((ent) + 1))

#ifdef LOW_BATTERY_INDICATION
  /* during testing of the the (AVcc-AVss)/2 value from the ADC on
     various SHIMMERS, to get a reliable cut off point to recharge the
     battery it is important to find the baseline (AVcc-AVss)/2 value
     coming from the ADC as it varies from SHIMMER to SHIMMER, however
     the range of fluctuation is pretty constant and (AVcc-AVss)/2
     provides an accurate battery low indication that prevents getting
     any voltage skewed data from the accelerometer or add-on board
     sensors */
#define TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD 1000
#define BATTERY_LOW_INDICATION_OFFSET 20 /* (AVcc - AVss)/2 = Approx 3V-0V/2 = 1.5V, 
                                            12 bit ADC with 2.5V REF,
                                            4096/2500 = 1mV=1.6384 units */ 
 bool need_baseline_voltage, linkDisconnecting;
 uint16_t num_baseline_voltage_samples, baseline_voltage;
 uint32_t sum_batt_volt_samples;
#endif /* LOW_BATTERY_INDICATION */

    // REV1 packet definitions
    //   sample data is sent with the 
    //   payload size == sample_count*2
#define STANDARD_PACKET_SIZE 22
#define STANDARD_PAYLOAD_SIZE 12
#define STANDARD_PACKET_OVERHEAD 10    // 10+12=22

#define TINYOS_CLOCK_TICS_SEC 0x8000

 void resetBatteryBaseline();
 void composeStringPacket(char *, const char *);

 const char Hex_Lookup[] = "0123456789ABCDEF";

//#define TEST_PATTERN
#ifdef TEST_PATTERN
 uint16_t test_value;
#endif

 uint8_t tx_packet[(STANDARD_PACKET_SIZE*2)+1]; 
 /* (*2)twice size because of byte stuffing */
 /* (+1)MSP430 CPU can only read/write 16-bit values at even addresses, 
 /* so use an empty byte to even up the memory locations for 16-bit values */

 uint8_t sequence;   // rev1 packet sequence

 norace long double jiffy_period;
 uint32_t timestamp;           // captured each sample block for rev1 packet transmission

#define SD_BLOCK_SIZE 512      // in bytes (NOTE! SD_M is hard coded to 512 at writeblock()
#define SAMPLE_BUFF_SIZE (SD_BLOCK_SIZE/2)  // block size in words
 // [double buffered][256 16 bit entries] for accumulating samples and writing them to SD
 uint16_t sbuf[2][SAMPLE_BUFF_SIZE];        // ping-pong sample buffer
 uint8_t sbuf_in, sbuf_out, in_buffer, out_buffer; // various sbuf indices
 norace uint8_t sbuf_last;

 norace uint8_t sample_count; // only written by host when not sampling (locked out in host logic)
 uint8_t  inch_index;
 norace uint16_t sample_period;

 uint16_t battery_voltage;

 // bluetooth transmit buffer vars
 // 16 bit value on a 16 bit micro, increment should be atomic
 uint16_t Head;       // Next entry in the buffer to fill
 uint16_t Tail;     // Oldest entry in the buffer.
 uint8_t Buffer[BT_TX_BUFF_SIZE]; // Circular buffer of bytes

 uint32_t sectors_written; // number of sectors written to the SD card
 norace uint8_t file_marker[SD_BLOCK_SIZE]; // used to mark the start and end of files on SD card
 norace uint16_t marker_idx;      // 
 uint32_t send_sector_num; // sector to send to the host


 // possible values for rx_state
 enum {
   SAMPLE_CONFIGURATION = 0,
   WRITE_MARKER,
 };
 uint8_t rx_state = SAMPLE_CONFIGURATION;

 // mux_ controls are for the PRIMMER board with analog switch
 norace bool sampling, connected, command_mode_complete, activity_led_on, 
   mux_sel = FALSE, mux_active = FALSE, recording = FALSE, new_sector = TRUE;

 // Send one byte across the serial line
 task void SendNextByte() {
   bool empty;
   result_t res;
   uint8_t *src;

   atomic empty = (Head == Tail);
   if (empty) return; // buffer is empty

   atomic src = &Buffer[Tail];
   res = call Bluetooth.write(src, 1);
   if (res != FAIL) atomic Tail = NEXT_BUFFER(Tail);
 }

  
 // Send data across the serial line
 result_t SendBluetooth(uint8_t* data, uint16_t length) {
   uint16_t i;
   uint16_t in_use;

   // see if there's enough room for this packet
   atomic {
     in_use = (Head < Tail) ? Head + BT_TX_BUFF_SIZE - Tail : Head - Tail;
   }

   if (in_use + length >= BT_TX_BUFF_SIZE)
     return FAIL; // not enough room

   // copy incoming bytes to the buffer
   for (i = 0; i < length; i++) {
     atomic {
       Buffer[Head] = data[i];
       Head = NEXT_BUFFER(Head);
     }
   }

   post SendNextByte();

   return SUCCESS;
 }

 task void write_sector() {
   uint8_t err;
   uint16_t *write_buffer;
   uint8_t *ptr;      // points to data buffer
   uint16_t i;        // counter
   uint16_t crc_fsc;  // crc checksum

   crc_fsc = 0;

   atomic write_buffer = &sbuf[in_buffer^1][0];

   // Calc CRC16 of data
   ptr = (uint8_t *)write_buffer;
   for (i = 0; i < (SD_BLOCK_SIZE - 2); i++) {  // -2 for crc bytes themselves
     crc_fsc = crcByte(crc_fsc, *(ptr + i));
   }
   write_buffer[SAMPLE_BUFF_SIZE-1] = crc_fsc;  // last entry

   // START_SECTOR holds recording metadata.  +1 is where sample data begins.
   err = call SD.writeBlock(START_SECTOR + 1 + sectors_written, ptr);

   if(err == 0) sectors_written++;
   else sampling = FALSE; // set in motion the process to stop sampling!
 }


 task void test_read_sector() {
   uint8_t err;
   uint8_t sd_test_buffer[SD_BLOCK_SIZE]; // stores data read from the SD card
   char packet[STANDARD_PACKET_SIZE];
   
   call SD.init();

   // SD.readSector returns non-zero for error
   err = call SD.readBlock(START_SECTOR, sd_test_buffer);

   if (err == 0)
     composeStringPacket(packet, "SD READ OK");
   else 
     composeStringPacket(packet, "SD FAILURE");

   SendBluetooth(packet, STANDARD_PACKET_SIZE); 
 }

 task void send_sector() {
   uint8_t err;
   uint32_t sector;
   uint8_t sd_send_buffer[512]; // stores data read from the SD card

   call SD.init();

   atomic sector = send_sector_num;

   // SD.readSector returns non-zero for error
   err = call SD.readBlock((START_SECTOR + sector), sd_send_buffer);

   if (err == 0) {
     SendBluetooth((uint8_t *)&sector, 4);
     SendBluetooth(sd_send_buffer, SD_BLOCK_SIZE);
     atomic send_sector_num++;
   } else {
     char packet[STANDARD_PACKET_SIZE];
     composeStringPacket(packet, "SD FAILURE");
     SendBluetooth(packet, STANDARD_PACKET_SIZE);
   }
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
   // set up trigger source:  ADC12IFGx
   call DMA0.init();

#ifdef TEST_PATTERN
   call DMA0.setSourceAddress((uint16_t)&test_value);
#else
   call DMA0.setSourceAddress((uint16_t)ADC12MEM0_);
#endif
   atomic {  // doesn't need to be atomic. shouldn't be sampling now.
     in_buffer = 0;
     out_buffer = in_buffer;
     sbuf_in = SAMPLE_DATA_OFFSET;
     sbuf_out = sbuf_in;
     call DMA0.setDestinationAddress((uint16_t)&sbuf[in_buffer][sbuf_in]);
   }

   // calculate index of last sample set in buffer
   // i.e., the last DMA transfer destination.
   // decrease available buffer size by 1 for the crc at the end of the sector
   // and by 2 for the timestamp at the beginning, then offset by same amount
   sbuf_last = ((SAMPLE_BUFF_SIZE - 1 - 2) / sample_count) - 1;
   sbuf_last *= sample_count;
   sbuf_last += 2;  // TIMESTAMP_DATA_LENGTH, for timestamp in front 

   /* we'll transfer from six sequential adcmem registers to six
    * sequential addresses in a buffer +1 for the battery value that
    * is the last in the sequence and is not written to SD */
   call DMA0.setBlockSize(sample_count+1);

#ifdef TEST_PATTERN
   // non-repeated block transfer, source addr not incremented, dest incremented
   DMA0CTL = DMADT_1 + DMADSTINCR_3 + DMASRCINCR_0;
#else
   // non-repeated block transfer, source and dest addrs incremented
   DMA0CTL = DMADT_1 + DMADSTINCR_3 + DMASRCINCR_3;
#endif

   // enables DMA transfers (set DMAEN+DMAIE, clr DMAIFG)
   // doesn't begin the transfer in our case, because we're configured for adc triggering
   // latches the src, dest, and sz registers in non-repeating mode
   call DMA0.beginTransfer();
 }


 void configureDefaultShimmerADC() {
   // sets ADC regs to a typical config, some of which 
   // we'll just change below
   call DMA0.ADCinit(); 

   atomic{
     CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
     SET_FLAG(ADC12CTL1, ADC12SSEL_3);         // clk from aclk

     /* with a 125khz clock (_7) it's 136usec per conversion, 136*6=816usec in total */
     SET_FLAG(ADC12CTL1, ADC12DIV_7);
     // sample and hold time four adc12clk cycles
     SET_FLAG(ADC12CTL0, SHT0_0);   

     // set reference voltage to 2.5v
     SET_FLAG(ADC12CTL0, REF2_5V);   
      
     // conversion start address
     SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity

     SET_FLAG(ADC12MCTL0, INCH_5);  // accel x 
     SET_FLAG(ADC12MCTL1, INCH_4);  // accel y 
     SET_FLAG(ADC12MCTL2, INCH_3);  // accel z 
     SET_FLAG(ADC12MCTL3, INCH_0);  // Anex
     SET_FLAG(ADC12MCTL4, INCH_7);  // Anex
     SET_FLAG(ADC12MCTL5, INCH_11); // (AVcc-AVss)/2 to monitor battery voltage
     SET_FLAG(ADC12MCTL5, EOS);     //sez "this is the last reg" 

     sample_count = 5;

     SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL2, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL3, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL4, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL5, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL6, SREF_1);             // Vref = Vref+ and Vr-
     SET_FLAG(ADC12MCTL7, SREF_1);             // Vref = Vref+ and Vr-
    
     /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
     /* clear init defaults first */
     CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel
     SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
   }
 }
  
 command result_t StdControl.init() {

#ifdef USE_8MHZ_CRYSTAL
   /* 
    * set up 8mhz clock to max out 
    * msp430 throughput 
    */
   register uint8_t i;

   atomic CLR_FLAG(BCSCTL1, XT2OFF); // basic clock system control reg, turn off XT2 osc

   call Leds.init();

   call Leds.redOn(); // indicate red if we get stuck here
   atomic do {
     CLR_FLAG(IFG1, OFIFG);
     for(i = 0; i < 0xff; i++);
   } while(READ_FLAG(IFG1, OFIFG));
   call Leds.redOff();

   call Leds.yellowOn();  // indicate yellow if we seem to linger here
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

   call AccelStdControl.init();
   // set default sensitivity to 4g for historical reasons
   call Accel.setSensitivity(RANGE_4_0G);

   // pins for internal expansion connector
   TOSH_MAKE_ADC_1_INPUT();   // x
   TOSH_MAKE_ADC_2_INPUT();   // z
   TOSH_MAKE_ADC_6_INPUT();   // y

   TOSH_SEL_ADC_1_MODFUNC();
   TOSH_SEL_ADC_2_MODFUNC();
   TOSH_SEL_ADC_6_MODFUNC();
    
   // inits:
   atomic {
     sampling = FALSE;
     connected = FALSE;
     command_mode_complete = FALSE;
     activity_led_on = FALSE;
     inch_index = 0;
     sample_period = SAMPLING_50HZ;
     recording = FALSE;
     Head = 0;
     Tail = 0;
     marker_idx = 0;
   }

   call BTStdControl.init();
   call Bluetooth.disableRemoteConfig(TRUE);

   /* if CPU=8Mhz then customise roving networks baudrate to suit 8Mhz/9 baud */
   //call Bluetooth.setBaudrate("452");

   call SD.init();

   configureDefaultShimmerADC();

   return SUCCESS;
 }

 command result_t StdControl.start() {
   call BTStdControl.start();

#ifdef LOW_BATTERY_INDICATION 
   resetBatteryBaseline();
#endif
   /* so that the clinicians know the sensor is on */
   call Leds.redOn();
   return SUCCESS;
 }

 command result_t StdControl.stop() {
   call BTStdControl.stop();
   return SUCCESS;
 }

 void composeStringPacket(char *pkt, const char *str) {
   uint16_t crc;
   char *start;

   start = pkt;

   *pkt++ = FRAMING_BOF;
   *pkt++ = SHIMMER_REV1;
   *pkt++ = STRING_DATA_TYPE;
   pkt++; // sequence number.  ignored by host.
   pkt++; // timestamp
   pkt++; // timestamp
   *pkt++ = STANDARD_PAYLOAD_SIZE;
   memcpy(pkt, str, STANDARD_PAYLOAD_SIZE);

   // calc crc from SHIMMER_REV to last byte of payload
   crc = calc_crc(start+1, (STANDARD_PACKET_SIZE-FRAMING_SIZE));
   pkt += STANDARD_PAYLOAD_SIZE;
   *pkt++ = crc & 0xff;
   *pkt++ = (crc >> 8) & 0xff;
   *pkt++ = FRAMING_EOF;
 }

#ifdef LOW_BATTERY_INDICATION
  
 task void handleBatteryLowIndication() {
   char packet[STANDARD_PACKET_SIZE];

   /* stop all sensing - battery is below the threshold */
   call SetupTimer.stop();
   while ( call AsyncSampleTimer.isSet() )
     call AsyncSampleTimerControl.stop();
   call ActivityTimer.stop();
   call DMA0.ADCstopConversion();
   call AccelStdControl.stop();
   call Leds.yellowOff();

   /* send the battery low indication packet to MOBIUS */
   composeStringPacket(packet, "BATTERY LOW!");
   SendBluetooth(packet, STANDARD_PACKET_SIZE);

   /* initialise baseline voltage measurement stuff */
   need_baseline_voltage = TRUE;
   num_baseline_voltage_samples = baseline_voltage = sum_batt_volt_samples = 0;
   call Leds.orangeOn();
 }

 void resetBatteryBaseline(){
   /* initialise baseline voltage measurement stuff */ 
   atomic{
     need_baseline_voltage = TRUE;
     num_baseline_voltage_samples = baseline_voltage = sum_batt_volt_samples = 0;
   }
   call Leds.orangeOn();
 }

 /* all samples are got so set the baseline voltage for this SHIMMER hardware */
 void setBattVoltageBaseline(){
   atomic baseline_voltage = (sum_batt_volt_samples / TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD);
 }

 /* check voltage level and if it is low then stop sampling, send message and disconnect */
 void checkBattVoltageLevel(uint16_t voltage){
   atomic{
     if(voltage < (baseline_voltage-BATTERY_LOW_INDICATION_OFFSET))
       linkDisconnecting = TRUE;
   }
 }

 /* keep checking the voltage level of the battery until it drops below the offset */
 task void monitorBattery(){
   uint16_t bv;
   atomic bv = battery_voltage;

   if(need_baseline_voltage) {
     num_baseline_voltage_samples++;      
     if(num_baseline_voltage_samples <= TOTAL_BASELINE_BATT_VOLT_SAMPLES_TO_RECORD) {
       /* add this sample to the total so that an average baseline can be obtained */
       sum_batt_volt_samples += bv;
     }
     else {
       setBattVoltageBaseline();
       need_baseline_voltage = FALSE;
       call Leds.orangeOff();
     }
   }
   else {
     checkBattVoltageLevel(bv);
   }
 }
#endif /* LOW_BATTERY_INDICATION */


 /* The MSP430 CPU is byte addressed and little endian packets are
    sent little endian so the word 0xABCD will be sent as bytes 0xCD 0xAB 

    returns TRUE if there was data in the sbuf to send 
 */
 bool preparePacket() {
   uint16_t *pi_packet, *p_ADCsamples, crc, ts;
   uint8_t i, *pb_packet;
   bool inSameBuffer, dmaDone;

   atomic {
     inSameBuffer = (in_buffer == out_buffer);
     dmaDone = (sbuf_out < (sbuf_in - sample_count));
   }

   // if sbuf_in and sbuf_out indices are operating from different buffers then we
   // we can send data at sbuf_out.  they are operating from the same buffer, then
   // ensure that sbuf_out must be using the previous sample's data, rather than
   // the one that's in progress 
   if (inSameBuffer && !dmaDone)
     return 0;

   // if here we're drawing characters from different buffers (sbuf[0 or 1][])
   // OR _out and _in are in the same buffer but are different values, so there
   // must be something to drain.

   // start from index 1, because when we copy the 16 bit sample data
   // into the packet below, the micro wants them aligned on even addrs
   tx_packet[1] = FRAMING_BOF;
   tx_packet[2] = SHIMMER_REV1;
   if (mux_active) {
     if (mux_sel == 0) tx_packet[3] = PROPRIETARY_DATA_TYPE_ALT_MUX;
     else tx_packet[3] = PROPRIETARY_DATA_TYPE;
   } else tx_packet[3] = PROPRIETARY_DATA_TYPE;

   tx_packet[4] = sequence++;     // pkt seq num
   atomic ts = timestamp;
   tx_packet[5] = ts & 0xFF;
   tx_packet[6] = ts >> 8;
   tx_packet[7] = sample_count*2; // byte count of payload space: 2 bytes per sample

   pi_packet = (uint16_t *)&tx_packet[8];
   p_ADCsamples = &sbuf[out_buffer][sbuf_out];

   /* copy all the data samples into the outgoing packet */
   for (i = 0; i < sample_count; i++)
     *pi_packet++ = *p_ADCsamples++; 

   atomic{
     sbuf_out += sample_count;
     if (sbuf_out > sbuf_last){
       out_buffer ^= 1;   // switch to other buffer
       sbuf_out = SAMPLE_DATA_OFFSET;
     }
   }

   crc = calc_crc(&tx_packet[2], (sample_count*2 + STANDARD_PACKET_OVERHEAD - FRAMING_SIZE));

   pb_packet = (uint8_t *)pi_packet;
   *pb_packet++ = crc & 0xff;
   *pb_packet++ = (crc >> 8) & 0xff;
   *pb_packet   = FRAMING_EOF;

   return sample_count*2 + STANDARD_PACKET_OVERHEAD;
 }


 // attempt to form a packet if one is available.  return length of packet formed.
 // 0 indicates unformed.
 uint8_t prepareRev2Packet() {
   uint16_t *p_ADCsamples;
   uint8_t data_msb, data_lsb, i;
   bool inSameBuffer, dmaDone;

   atomic {
     inSameBuffer = (in_buffer == out_buffer);
     dmaDone = (sbuf_out < (sbuf_in - sample_count));
   }

   // if sbuf_in and sbuf_out indices are operating from different buffers then we
   // we can send data at sbuf_out.  they are operating from the same buffer, then
   // ensure that sbuf_out must be using the previous sample's data, rather than
   // the one that's in progress 
   if (inSameBuffer && !dmaDone)
     return 0;

   tx_packet[1] = CMD;   // packet sync byte

#if 0  // try to keep up with sampling
   atomic{
     p_ADCsamples = &sbuf[out_buffer][sbuf_out];
     sbuf_out += sample_count;
     if (sbuf_out > sbuf_last){
       out_buffer ^= 1;
       sbuf_out = SAMPLE_DATA_OFFSET;
     }

     if (mux_active) {
       if ((sbuf_out / sample_count) & 1)  // odd groups will contain alt channel data
         tx_packet[1] += MUXED; // indicate this holds alt input data
     }
   }
#else  // don't try to keep up, always just send latest
   atomic{
     if (sbuf_in == SAMPLE_DATA_OFFSET) {  // at start of buffer?
       sbuf_out = sbuf_last;               //   set readout index to end of other buffer
       out_buffer = in_buffer ^1;
     } else {
       sbuf_out = sbuf_in - sample_count;  // not at start of buffer, so readout index
       out_buffer = in_buffer;             // is just set to the last sample block in this buffer
     }
     p_ADCsamples = &sbuf[out_buffer][sbuf_out];

     if (mux_active) {
       if ((sbuf_out / sample_count) & 1)  // odd groups will contain alt channel data
         tx_packet[1] += MUXED; // indicate this holds alt input data
     }
   }
#endif

   // samples are 12 bits.  divide them into two 6 bit entries.
   // form up first data element using lower 6 bits of sample lsB
   for (i = 2; i < (sample_count*2 + 2); i+=2) {
     data_lsb = *p_ADCsamples & 0xff;
     data_msb = *p_ADCsamples >> 6;

     data_msb &= 0x3C;
     data_msb |= (data_lsb & 0xC0) >> 6; 
     data_lsb &= DATA_MASK;
	
     tx_packet[i] = data_lsb + DATA0;
     tx_packet[i+1] = data_msb + DATA1;
     p_ADCsamples++;
   }

   return sample_count*2 + 1;  // two bytes per sample, one CMD header byte
 }


 task void sendSensorData(){
   uint8_t packetLen;

   if(connected){
     // prepare packet at tx_packet[1]
     if (recording)
       packetLen = prepareRev2Packet();
     else 
       packetLen = preparePacket();
     
     if (packetLen) SendBluetooth(&tx_packet[1], packetLen); 
   }
 }
 


 /* if channel sequence includes 0 or 7, then turn on the external
    boost regulator that lives on the AnEx expansion board.   */
 void Configure_SER0_PIN(){
   int i;
   for (i = 0; i < 16; i++){
     if (((*((&ADC12MCTL0) + i) & 0x0F ) == 0x00) ||
         ((*((&ADC12MCTL0) + i) & 0x0F ) == 0x07)) 
       {
         TOSH_SET_SER0_RTS_PIN();  // turn on AnEx board charge pump      
	 return;
       }
     if ( *((&ADC12MCTL0) + i) & EOS ) return;
   }
   // default to off
   TOSH_CLR_SER0_RTS_PIN();  // turn on AnEx board charge pump      
 }


 // put personality packet at pointer, return number of bytes placed there
 uint8_t populatePersonality(uint8_t *dest){
   uint8_t *ptr;
   uint16_t crc;

   ptr = dest;
   *ptr++ = FRAMING_BOF;
   *ptr++ = SHIMMER_REV1;
   *ptr++ = PERSONALITY_DATA_TYPE;
   *ptr++ = 0;  // sequence number ignored by block parser
   *ptr++ = 0;  // timestamps ignored
   *ptr++ = 0;
   *ptr++ = STANDARD_PAYLOAD_SIZE;

   *ptr = (mux_active) ? PERS_MUX_BIT : 0;
   *ptr |= (recording) ? PERS_REC_BIT : 0;
   *ptr++ |= (sample_count & PERS_SAMPLE_MASK);
   atomic *ptr++ = sample_period;
   *ptr++ = ADC12MCTL0;
   *ptr++ = ADC12MCTL1;  
   *ptr++ = ADC12MCTL2;  // 4
   *ptr++ = ADC12MCTL3;  // 5
   *ptr++ = ADC12MCTL4;
   *ptr++ = ADC12MCTL5;
   *ptr++ = ADC12MCTL6;
   *ptr++ = ADC12MCTL7;
   *ptr++ = ADC12MCTL8;
   *ptr++ = ADC12MCTL9;   // 11

   //   crc = calc_crc(&tx_packet[1], (STANDARD_PACKET_SIZE-FRAMING_SIZE));
   crc = calc_crc(dest+1, (STANDARD_PACKET_SIZE-FRAMING_SIZE));
   *ptr++ = crc & 0xff;
   *ptr++ = (crc >> 8) & 0xff;
   *ptr = FRAMING_EOF;

   return STANDARD_PACKET_SIZE;
 }

 task void startSensing(){
   uint16_t period;

   TOSH_CLR_PROG_OUT_PIN();   // gyro enable low

   if (recording){
     new_sector = TRUE;
     sectors_written = 0;
     call SD.init();
   }

   // reset mux control
   if (mux_active) {
     mux_sel = 0;
     TOSH_CLR_SER0_RTS_PIN();
   }

   sequence = 0;
   Configure_SER0_PIN();
   call ActivityTimer.start(TIMER_REPEAT, 1000);
   call AccelStdControl.start();

   atomic period = sample_period;

   setupDMA();

   sampling = TRUE;
   jiffy_period = ((double) sample_period  * (double)TINYOS_CLOCK_TICS_SEC) / 1000.0;
   call AsyncSampleTimer.setOneShot((uint32_t) jiffy_period);
 }

 task void sendPersonality(){
   populatePersonality(&tx_packet[0]);
   SendBluetooth(&tx_packet[0], STANDARD_PACKET_SIZE);
 }

 /* this task is posted when the async sample timer sees that the
    'sampling' flag has been reset.  this is because it's important
    that the dma transfer sample buffer logic not be running while we
    do what we need to do below. */
 task void stopSensing(){
   uint8_t *ptr8;
   uint16_t crc_fsc, i;
    
   TOSH_CLR_SER0_RTS_PIN();  // turn off AnEx board charge pump
   TOSH_SET_PROG_OUT_PIN();  // turn off gyro (aka bsl_tx)

   call SetupTimer.stop();

   // one-shot async timer function needs to stop before we can
   // go on safely with SD writes
   //   sampling = FALSE;
   call AsyncSampleTimerControl.stop();
   call ActivityTimer.stop();
   call DMA0.ADCstopConversion();
   call AccelStdControl.stop();
   call Leds.yellowOff();

   if (recording){
     uint8_t in;   // sample buffer input index
     uint32_t sectors;

     sectors = sectors_written;
     atomic in = sbuf_in;

     // remove offset for calcs
     in -= SAMPLE_DATA_OFFSET;

     // calculate index of last good block, and if we have to write a remainder sector.
     if (in != 0){           // at start of buffer?  then no remainder
       in -= sample_count;   // point to last transfer completed
       sectors++;            // for remainder block
       atomic in_buffer ^= 1;// write_sector() writes out the non current in- buffer.
       post write_sector();  // but, for the last, partial sector that's what we want
     }

     // did recording start w/o host first setting up tag and personality?
     if (marker_idx == 0){
       file_marker[marker_idx++] = 0;  // place tag string length of 0
       file_marker[marker_idx++] = 0;  // place personality data length of 0
     }
     ptr8 = &file_marker[marker_idx];
     *ptr8++ = sectors & 0xff;
     *ptr8++ = (sectors >> 8) & 0xff;
     *ptr8++ = (sectors >> 16) & 0xff;
     *ptr8++ = (sectors >> 24) & 0xff;
     *ptr8++ = in;      

     // calc CRC16 of data
     crc_fsc = 0;
     for (i = 0; i < (SD_BLOCK_SIZE-2); i++) {
       crc_fsc = crcByte(crc_fsc, *(file_marker + i));
     }
     *(uint16_t *)(file_marker + (SD_BLOCK_SIZE-2)) = crc_fsc;
     call SD.writeBlock(START_SECTOR, file_marker);
     marker_idx = 0;
   }
 }

 async event void Bluetooth.connectionMade(uint8_t status) { 
   atomic connected = TRUE;
   call Leds.greenOn();
 }

 async event void Bluetooth.commandModeEnded() { 
   atomic command_mode_complete = TRUE;
 }
    
 async event void Bluetooth.connectionClosed(uint8_t reason){
   atomic connected = FALSE;    
   call Leds.greenOff();
   if (!recording)
     sampling = FALSE; // will cause sampling shut down if sampling
 }

 async event void Bluetooth.dataAvailable(uint8_t data){
   static unsigned char tagLenth, personalityLen;

   switch (rx_state){
     case WRITE_MARKER:
       // host can write an arbitrary string 'tag' at the start of the first sector
       if (marker_idx == 0) tagLenth = data;
       else tagLenth--;

       file_marker[marker_idx++] = data;
       if ((data == 0) || (tagLenth == 0)){
         rx_state = SAMPLE_CONFIGURATION;
         // write the personality length in the next entry
         // and append the personality data to that

         // if sender sent a stop string message then replace length at
         // head with correct value
         if (data == 0)
           file_marker[0] = marker_idx-1;

         personalityLen = populatePersonality(&file_marker[marker_idx + 1]);
         file_marker[marker_idx++] = personalityLen;
         marker_idx += personalityLen;
       }
       return;
     
     case SAMPLE_CONFIGURATION:
     default:
       break;
   }
   
   if (rx_state != SAMPLE_CONFIGURATION) return;

   switch (data){
     case SHIMMER_WRITE_MARKER:      // ^w
       rx_state = WRITE_MARKER; 
       marker_idx = 0;
       atomic send_sector_num = 0;
       break;
     case SHIMMER_ACCEL_RANGE_1_5G:
       call Accel.setSensitivity(RANGE_1_5G);
       break;
     case SHIMMER_ACCEL_RANGE_2_0G:
       call Accel.setSensitivity(RANGE_2_0G);
       break;
     case SHIMMER_ACCEL_RANGE_4_0G:
       call Accel.setSensitivity(RANGE_4_0G);
       break;
     case SHIMMER_ACCEL_RANGE_6_0G:
       call Accel.setSensitivity(RANGE_6_0G);
       break;

     case SHIMMER_GET_BATTERY:      // get ^battery voltage
     {
       char packet[STANDARD_PACKET_SIZE];
       char string[STANDARD_PAYLOAD_SIZE];

       memcpy(string, "Battery xxxx", STANDARD_PAYLOAD_SIZE);
       string[8]  = Hex_Lookup[(battery_voltage >> 12)];
       string[9]  = Hex_Lookup[((battery_voltage >> 8) & 0x0F)];
       string[10] = Hex_Lookup[((battery_voltage >> 4) & 0x0F)];
       string[11] = Hex_Lookup[(battery_voltage & 0x0F)];

       composeStringPacket(packet, string);
       SendBluetooth(packet, STANDARD_PACKET_SIZE);
     }
     break;
     case SHIMMER_SD_TEST:
       post test_read_sector();
       break;
     case SHIMMER_FETCH:      // ^f - fetch
       post send_sector();
       break;
     case SHIMMER_RESET_SECTOR:      // ^r - reset sector num
       send_sector_num = 0;
       break;
     case SHIMMER_DECREMENT_SECTOR: //'-'
       atomic { 
         if (send_sector_num != 0) send_sector_num--;
       }
       break;
     case SHIMMER_INCREMENT_SECTOR: //'+'
       send_sector_num++;
       break;
     case SHIMMER_START:      // start capturing on ^G
       atomic if(command_mode_complete) {
         post startSensing();
       } else {  /* give config a chance, wait 5 secs */
         call SetupTimer.start(TIMER_REPEAT, 5000);
       }
       break;
     case SHIMMER_STOP:  // stop on space bar
       sampling = FALSE;
       break;
     case SHIMMER_PERSONALITY:  
       post sendPersonality();   
       break;
     case SHIMMER_LATCH_SEQUENCE:
       *((&ADC12MCTL0) + inch_index) = INCH_11 + SREF_1 + EOS;
       sample_count = inch_index;
       inch_index = 0;
#ifdef LOW_BATTERY_INDICATION 
       resetBatteryBaseline();
#endif
       break;
     case SHIMMER_MULTIPLEXER_ON:
       atomic {
         mux_sel = 0;
         TOSH_CLR_SER0_RTS_PIN();
         mux_active = TRUE;
       }
       break; 
     case SHIMMER_MULTIPLEXER_OFF:
       atomic {
         mux_active = FALSE;
         mux_sel = 0;
         TOSH_CLR_SER0_RTS_PIN();
       }
       break;
     case SHIMMER_LOGSD_ON:
       recording = TRUE;
       break;
     case SHIMMER_LOGSD_OFF:
       recording = FALSE;
       break;

     default:
       if ((data >= '@') && (data <= 'Z')){ // 0x40..0x5A
         atomic sample_period = 10 * (data - '@');
         break;
       }
       if (data >= 'a' && data <= 'i'){  // 0x61..0x69
         atomic sample_period += data - 0x60;
         break;
       }
       if (data >= '0' && data <= 0x3F){
         *((&ADC12MCTL0) + inch_index++) = SREF_1 + (data & 0x0f);
         if (inch_index == 0x10) inch_index = 0;
         break;
       }
       break;
   }
 }


 event void Bluetooth.writeDone(){
   register uint16_t h, t;

   // move this test somewhere else
#ifdef LOW_BATTERY_INDICATION
   if(linkDisconnecting) {
     linkDisconnecting = FALSE;
     /* signal battery low to master and let the master disconnect the link */
     post handleBatteryLowIndication();
   }
#endif /* LOW_BATTERY_INDICATION */

   atomic { h = Head; t = Tail; }
   if (h != t) post SendNextByte();
 }


 event result_t SetupTimer.fired() {
   atomic if(command_mode_complete){
     call ActivityTimer.stop();
     post startSensing();
   }
   return SUCCESS;
 }

 event result_t ActivityTimer.fired() {
   atomic {
     /* toggle activity led every second */
     if(activity_led_on) {
       call Leds.yellowOn();
       activity_led_on = FALSE;
     }
     else {
       call Leds.yellowOff();
       activity_led_on = TRUE;
     }
   }
   return SUCCESS;
 }

 async event result_t AsyncSampleTimer.fired() {
   if (sampling)
     call AsyncSampleTimer.setOneShot((uint32_t) jiffy_period);
   else {
     post stopSensing();
     return SUCCESS;
   }

   // next stop: dma transferComplete
   call DMA0.ADCbeginConversion();

#if 0  // wiggle pin when sampling
   mux_sel ^= 1;
   if (mux_sel) 
     TOSH_SET_SER0_CTS_PIN(); 
   else 
     TOSH_CLR_SER0_CTS_PIN();
#endif

   return SUCCESS;
 }

 
 async event void DMA0.transferComplete(){
   uint32_t ts;

   ts = call LocalTime.read();
   atomic timestamp = ts;

   // PRIMMER board mux needs switching now that a/d operation is done
   if (mux_active) {
     mux_sel ^= 1;
     if (mux_sel) 
       TOSH_SET_SER0_RTS_PIN(); 
     else
       TOSH_CLR_SER0_RTS_PIN();
   }

   // if we're now at the beginning of a sector, put the timestamp
   // in the first two word entries
   if (recording & new_sector){
     atomic {
       sbuf[in_buffer][TIMESTAMP_DATA_OFFSET] = (uint16_t)(timestamp & 0xffff);
       sbuf[in_buffer][TIMESTAMP_DATA_OFFSET+1] = (uint16_t)(timestamp >> 16);
     }
     new_sector = FALSE;
   }
   
   // new samples have just been placed into &sbuf[sbuf_in]
   // there are sample_count biometric samples, and 1 battery sample
   // grab battery sample from just dma'd block (last of samples)
   atomic battery_voltage = sbuf[in_buffer][sbuf_in+sample_count]; 

#ifdef TEST_PATTERN
   atomic { test_value++; test_value &= 4095;}
#endif

   atomic {
     sbuf_in += sample_count;

     // sbuf-last = idx of last available transfer block space within buffer.  there are
     // probably leftover bytes in the SAMPLE_BUFF_SIZE buffer, but dma requires we do it in blocks
     if (sbuf_in > sbuf_last){
       // this buffer is full.  flip to new buffer, reset index
       in_buffer ^= 1;
       sbuf_in = SAMPLE_DATA_OFFSET;

       // if we're recording, now's the time to write that last buffer.
       // this should be done /after/ the buffer^1 (flip) above.  write-sector assumes
       // you want the buffer that isn't currently being filled with samples to be written
       //   post the write request the next time through this, after the next transfer has completed.
       if (recording){
	 post write_sector();
	 new_sector = TRUE;
       }
     }
     //  set new destination address
     DMA0DA = (uint16_t)&sbuf[in_buffer][sbuf_in];
   }
   // if we're not in repeated block transfer mode, then we
   // need to re-arm this.  doing this latches the 
   // DMA0DA write, above.
   call DMA0.beginTransfer();
   // now we wait for the async timer to fire

   post sendSensorData(); 

#ifdef LOW_BATTERY_INDICATION
   post monitorBattery();
#endif /* LOW_BATTERY_INDICATION */
 }


 async event void SD.available(){
   //   call Leds.set(0x00);
 }

 async event void SD.unavailable(){
   //   call Leds.set(0x0F);
 }

 async event void DMA0.ADCInterrupt(uint8_t regnum) {
   // we should *not* see this, as the adc interrupts are eaten by the dma controller!
   /* Turn on all LEDs */
   call Leds.set(0x0F);
 } 

}


