// $Id: ThreeAxisRecorderM.nc,v 1.5 2009/07/28 19:05:43 ayer1 Exp $
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
 *   Author:  Jason Waterman
 *            July, 2007
 */

includes DMA;
includes crc;

module ThreeAxisRecorderM {
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer as sampleTimer;
    interface Timer as recordTimer;
    interface HPLUART;
    interface LocalTime;
    interface MSP430Event as Button;
    interface SD;
    interface StdControl as SDStdControl;
    interface StdControl as AccelStdControl;
    interface MMA7260_Accel as Accel;
    interface DMA as DMA0;
  }
}

implementation {
  
  // Our Output Buffers
#define BUFFER_SIZE 600
#define NEXT_BUFFER(ent) (((ent) >= ((BUFFER_SIZE) - 1)) ? 0 : ((ent) + 1))

  // Where to start writing on the SD card
#define START_SECTOR 2000

  // Number of ADC channels used
#define NUM_ADC_CHAN 3

  // Command state
  enum {
    S_IDLE = 0,        // Not processing any commands     
    S_OFFSET_RECV = 1, // Currently receiving time offset from host
    S_MARKER_RECV = 2, // Currently receiving file marker from host
    S_SECTOR_RECV = 3, // Currently receiving a sector number from host
  };

  uint8_t recording; // are we currently recording
  uint8_t state;  // current command when in command state
  uint16_t Head;       // Next entry in the buffer to fill
  uint16_t Tail;       // Oldest entry in the buffer
  uint8_t Buffer[BUFFER_SIZE]; // Circular buffer of bytes
  uint32_t localtime0, localtime1; // SHIMMER Clock time
  bool BytePending;    // TRUE if we have put without a putDone
  uint8_t file_marker[512]; // used to mark the start and end of files on SD card
  uint8_t sd_send_buffer[512]; // stores data read from the DS card
  uint8_t current_buffer; // toggles between the sd_data banks
  uint32_t sectors_written; // number of sectors written to the SD card
  uint32_t send_sector_num; // sector to send to the host
  uint8_t dma_blocks; // how many blocks (one group sample of NUM_ADC_CHANs) gotten
  uint16_t sbuf0[256], sbuf1[256]; // storage for DMA'd accelerometer data

  // Send one byte across the serial line
  result_t SendNextByte() {
    bool busy;
  
    atomic {
      busy = (BytePending == TRUE);
    }
    if (busy) {
      return FAIL;
    }

    if (Head == Tail) {
      return SUCCESS; // buffer is empty
    }
     
    atomic {
      BytePending = TRUE;
    }
     
    call HPLUART.put(Buffer[Tail]);
    return SUCCESS;
  }
  
  // Send data across the serial line
  result_t SendBuffer(uint8_t* data, uint16_t length) {
    uint16_t i;
    uint16_t size;
    bool not_busy;

    // see if there's enough room for this packet
    size = (Head < Tail) ? Head + BUFFER_SIZE - Tail : Head - Tail;
    if (size + length >= BUFFER_SIZE) { 
      return FAIL; // not enough room
    }

    // copy incoming bytes to the buffer
    for (i = 0; i < length; i++) {
      Buffer[Head] = data[i];
      Head = NEXT_BUFFER(Head);
    }

    atomic {
      not_busy = (BytePending == FALSE);
    }

    if (not_busy) SendNextByte();

    return SUCCESS;
  }

  // Sets up the ADC correctly
  void startADC() {
    call DMA0.ADCinit();
    atomic{
      
      SET_FLAG(ADC12CTL1, ADC12DIV_7);
      // sample and hold time 4 adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   
      
      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }

    SET_FLAG(ADC12MCTL0, INCH_5);  // accel x 
    SET_FLAG(ADC12MCTL1, INCH_4);  // accel y 
    SET_FLAG(ADC12MCTL2, INCH_3);  // accel z 
    SET_FLAG(ADC12MCTL2, EOS);     // sez "this is the last reg" 

    SET_FLAG(ADC12MCTL0, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL1, SREF_1);             // Vref = Vref+ and Vr-
    SET_FLAG(ADC12MCTL2, SREF_1);             // Vref = Vref+ and Vr-
    

    /* set up for three adc channels -> three adcmem regs -> three dma
       channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel
    SET_FLAG(ADC12CTL1, CONSEQ_1);      // single sequence of channels
    
    call DMA0.init();

    call DMA0.setSourceAddress((uint16_t)ADC12MEM0_);
    call DMA0.setBlockSize(NUM_ADC_CHAN);

    // we want block transfer, repeated
    DMA0CTL = DMADT_1 + DMADSTINCR_3 + DMASRCINCR_3;
    call DMA0.beginTransfer();
  }
    
  task void start_recording() {
    sectors_written = 0;
    recording = 1;
    // write start marker
    call SDStdControl.init();
    //    call SD.writeSector(START_SECTOR, file_marker);
    call SD.writeBlock(START_SECTOR, file_marker);
    sectors_written++;

    // Set up memory
    atomic {
      current_buffer = 0;
      dma_blocks = 0;
      // DMA Destination address
      // First 4 bytes reserved for a timestamp      
      DMA0DA = (uint16_t)&sbuf0[2];
    }

    // Set up accelrometer
    call AccelStdControl.start();
    call Accel.setSensitivity(RANGE_4_0G);

    // Set up ADC
    startADC();

    // Ready to go
    call sampleTimer.start(TIMER_REPEAT, 20);   // 51.2 Hz
    call recordTimer.start(TIMER_REPEAT, 1024); // 1 Hz
    call Leds.yellowOff();
  }

  task void stop_recording() {
    uint32_t *ptr;
    uint16_t crc_fsc, i;
    
    crc_fsc = 0;

    if (recording == 1) {
      call sampleTimer.stop();
      call recordTimer.stop();
      call Leds.greenOff();
      call Leds.yellowOff();
      call Leds.yellowOn();
      // update file marker with sectors written
      ptr = (uint32_t *)&file_marker[10];
      *ptr = sectors_written;

      // calc CRC16 of data
      for (i = 0; i < 510; i++) {
        crc_fsc = crcByte(crc_fsc, *(file_marker + i));
      }
      *(uint16_t *)(file_marker + 510) = crc_fsc;
      //      call SD.writeSector(START_SECTOR, file_marker);
      call SD.writeBlock(START_SECTOR, file_marker);
      call HPLUART.init();
      CLR_FLAG(ADC12CTL0, REF2_5V);   // turn off voltage ref
      recording = 0;
    }
  }

  task void write_sector() {
    uint16_t *write_buffer;
    uint8_t *time_ptr; // points to localtime
    uint8_t *ptr;      // points to data buffer
    uint8_t my_buffer; // which is our buffer
    uint16_t i;        // counter
    uint16_t crc_fsc;  // crc checksum

    crc_fsc = 0;

    atomic {
      if (current_buffer == 0) {
        my_buffer = 1;
      }
      else {
        my_buffer = 0;
      }
    } // end atomic 

    if (my_buffer == 0) {
      write_buffer = sbuf0;
      time_ptr = (uint8_t *) &localtime0;
    }
    else {
      write_buffer = sbuf1;
      time_ptr = (uint8_t *) &localtime1;
    }

    // Insert the time stamp we saved earlier
    ptr = (uint8_t *)write_buffer;
    *ptr = time_ptr[0]; ptr++;
    *ptr = time_ptr[1]; ptr++;
    *ptr = time_ptr[2]; ptr++;
    *ptr = time_ptr[3]; ptr++;

    // Insert padding for sector
    write_buffer[254] = 0xaaaa;

    // Calc CRC16 of data
    ptr = (uint8_t *)write_buffer;
    for (i = 0; i < 510; i++) {
      crc_fsc = crcByte(crc_fsc, *(ptr + i));
    }
    write_buffer[255] = crc_fsc;

    // call SD.init(); 
    //    call SD.writeSector(START_SECTOR + sectors_written, ptr);
    call SD.writeBlock(START_SECTOR + sectors_written, ptr);
    sectors_written++;
  }

  task void send_sector() {
    uint8_t err;
    uint32_t sector;
    uint32_t marker = 0xaaaaaaaa;

    atomic {
      sector = send_sector_num;
    }
    // Sends a sector to the host
    call Leds.yellowToggle();
    call SDStdControl.init();
    //    err = call SD.readSector((START_SECTOR + sector), sd_send_buffer);
    err = call SD.readBlock((START_SECTOR + sector), sd_send_buffer);
    call HPLUART.init();
    atomic {
      SendBuffer((uint8_t *)&marker, 4);
      SendBuffer(sd_send_buffer, 512);
    }
  }

  command result_t StdControl.init() {

    call Leds.init();
    call AccelStdControl.init();
    call HPLUART.init();

    atomic {
      Head = 0;
      Tail = 0;
      BytePending = FALSE;
      state = S_IDLE;
      sectors_written = 0;
      send_sector_num = 0;
      recording = 0;
    }

    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Leds.greenOn();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /* Gets called when we have input from the host PC.  To keep things
     simple we're just allowing one byte commands to be received.
     Also note that the the offset is stored at a double (8 bytes) and
     on TinyOS a double is 4 bytes, so we keep it around as an array
     of bytes. */

  event async result_t HPLUART.get(uint8_t data) {
    static uint16_t Index = 0; // how many bytes of data received
    static uint8_t offset[8]; // holds our constructed offset
    static uint8_t sector[4]; // holds our constructed sector number

    if (state == S_MARKER_RECV) {    
      // receive offset mode
      file_marker[Index] = data;
      if (Index == 511) { 
        // got all our data
        Index = 0;
        state = S_IDLE;
      }
      else {
        Index++;
      }
    }
    else if (state == S_SECTOR_RECV) {    
      // receive sector mode
      sector[Index] = data;
      if (Index == 3) { 
        // got all our data
        Index = 0;
        state = S_IDLE;
        atomic {
          send_sector_num = *((uint32_t *)sector);
        }
        post send_sector();
      }
      else {
        Index++;
      }
    }
    else if (state == S_OFFSET_RECV) {    
      // receive offset mode
      offset[Index] = data;
      if (Index == 7) { 
        // got all our data
        Index = 0;
        state = S_IDLE;
      }
      else {
        Index++;
      }
    }
    else {               
      // command mode
      if (data == 'a') { 
        // start recording
        post start_recording();
      }
      else if (data == 'd') {
        // toggle on the red led
        call Leds.redToggle();
      }
      else if (data == 'e') {
        // send current file marker
        SendBuffer(file_marker, 512);
      }
      else if (data == 'f') {
        // Send a sector (512 bytes) of data.  The sector to send is
        // sent as next 4 bytes and is 1 based (i.e. 1 is the first
        // block that was written to the SD card.
        state = S_SECTOR_RECV;
      }
      else if (data == 'g') {
        // turns off the orange led
        call Leds.yellowOff();
      }
      else if (data == 'h') {
        // turns on the green led
        call Leds.greenOn();
      }
      else if (data == 'm') { 
        // receive marker
        state = S_MARKER_RECV;
      }
      else if (data == 'o') {
        // send offset (used to determine offset was received correctly)
        SendBuffer(offset, 8);
      }
      if (data == 'r') { 
        // receive offset
        state = S_OFFSET_RECV;
      }
      else if (data == 's') { 
        // send localtime (used for timing calculations)
        localtime0 = call LocalTime.read();
        SendBuffer((uint8_t *)&localtime0, 4);
      }      
    }
    return SUCCESS;
  }

  // Called when the UART is ready to send another byte
  event async result_t HPLUART.putDone() {
    atomic {
      BytePending = FALSE;
    }
    if (Head == Tail) {
      return SUCCESS; // buffer is empty
    }

    Tail = NEXT_BUFFER(Tail);
    SendNextByte();

    return SUCCESS;
  }

  // This gets called when the button is pressed. 
  // Stop recording
  async event void Button.fired() 
  {
    post stop_recording();
  }

  // This is for our blinking record led
  event result_t recordTimer.fired() {
    call Leds.greenToggle();
    return SUCCESS;
  }


  // time to take another sample...
  event result_t sampleTimer.fired() {
    call DMA0.beginTransfer();
    call DMA0.ADCbeginConversion();
    return SUCCESS;
  }
  
  // Called when the data from the ADC has been written to memory.
  async event void DMA0.transferComplete() {
    dma_blocks++;
    
    //call Leds.yellowToggle();

    // check for start of a new sector
    if (dma_blocks == 1) { 
      if (current_buffer == 0) {
	atomic localtime0 = call LocalTime.read();
      }
      else {
	atomic localtime1 = call LocalTime.read();
      }
    }
    // check for end of sector
    else if (dma_blocks == 84) { 
      // Magic number warning:
      // 84 (x,y,x) accelerometer samples fit in one 512 sector.
      // You'll need to change this if NUM_ADC_CHAN is not 3.
      
      // What were doing here is changing buffers.  We have two
      // buffers so we can write out one buffer to the SD card while
      // the ADC is writing data to the other buffer.  First we pad
      // out our data so we get exactly 512 bytes to write to the SD
      // card.  Then we move our DMA address ot the other buffer,
      // skipping the first four bytes for the time stamp (which gets
      // filled in later).
      atomic {
        if (current_buffer == 0) {
          DMA0DA = (uint16_t)&sbuf1[2];
          current_buffer = 1;
        }
        else {
          DMA0DA = (uint16_t)&sbuf0[2];
          current_buffer = 0;
        }
        dma_blocks = 0;
      } // end atomic 
      post write_sector();
      return;
    }
    // Move ADC memory pointer to the next location
    atomic DMA0DA += (NUM_ADC_CHAN * 2); 
  }

  // We should *not* see this, as the adc interrupts are eaten by
  // the dma controller!
  async event void DMA0.ADCInterrupt(uint8_t regnum) {
    call Leds.redOn();    
  } 

  async event void SD.available() {
  } 

  async event void SD.unavailable() {
  } 

}
