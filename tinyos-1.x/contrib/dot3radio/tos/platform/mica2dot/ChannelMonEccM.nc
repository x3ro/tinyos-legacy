/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 */

module ChannelMonEccM {
  provides interface ChannelMon;
  uses interface Random;
  uses interface Chipcon;
  uses interface SpiByteFifo;
  uses interface RadioEncoding as Code;
  uses interface ADC;
}
implementation {
  enum {
    IDLE_STATE,
    DISABLED_STATE,
    READING_STATE,
    FIND_SYNC_STATE
  };
  enum {
    SYNC_BYTE = 0x33,
    NSYNC_BYTE = 0xcc,
    SYNC_WORD = 0x33cc,
    NSYNC_WORD = 0xcc33
  };
  enum {
    VALID_PRECURSER = 5
  };

  int16_t CM_waiting;
  uint8_t CM_state;
  int txlength;
  int rxlength;
  int preamblelen;
  char pre_tx;
  char spi_byte;
  char *bufptr;
  char *rxbuf;
  int SPI_byte_interval;
  char preamble[20];
  TOS_MsgPtr txbufptr;  // pointer to transmit buffer
  TOS_MsgPtr rxbufptr;  // pointer to receive buffer
  TOS_Msg msg;  // save received messages
  char tunefreq;   // tune frequency for radio
  int timeout;
  char symbolvalid;  //  found a valid preamble
  uint16_t current; // last 2 spibus readings
  char bitflip;  // data inverted
  uint8_t offset;  // bit offset for spibus
  uint8_t pktcnt;  // packet counter
  char rssi_ena;
  uint16_t signal_strength;

  char buf_head;
  char buf_end;
  char encoded_buffer[4];
  char enc_count;

  command result_t ChannelMon.init(uint8_t freq) {
    int i;
    preamblelen = sizeof(preamble);

    // need to make this a constant in flash
    // doing this for now since the compiler ignores the static declaration

    for (i=0;i<preamblelen;i++)
      preamble[i] = 0xaa;

    preamble[preamblelen-2] = SYNC_BYTE;
    preamble[preamblelen-1] = NSYNC_BYTE;

    pre_tx = 1;
    rxbufptr = &msg;
    rxlength = MSG_DATA_SIZE;
    offset = 0;
    bitflip = 0;
    symbolvalid = 0;
    current = 0;
    tunefreq = freq;
    CM_waiting = -1;
    CM_state = IDLE_STATE;
    spi_byte = 0x00;
    call SpiByteFifo.initSlave(); // set spi bus to slave mode
    call Chipcon.rxmode();
    call SpiByteFifo.enableIntr(); // enable spi and spi interrupt
    rssi_ena = 0; // rssi enabled

    return SUCCESS;
  }

  command result_t ChannelMon.tune(uint8_t freq) {
    tunefreq = freq;
    call Chipcon.tune(freq);

    return SUCCESS;
  }

  command result_t ChannelMon.rssi_enable() {
    rssi_ena = 1;

    return SUCCESS;
  }

  command result_t ChannelMon.rssi_disable() {
    rssi_ena = 0;

    return SUCCESS;
  }

  command result_t ChannelMon.sleep() {
    CM_state = DISABLED_STATE;
    call Chipcon.sleep();
    call SpiByteFifo.disableIntr(); // disable spi interrupt

    return SUCCESS;
  }

  command result_t ChannelMon.awake() {
    CM_state  = IDLE_STATE;
    CM_waiting = -1;
    spi_byte = 0x00;
    call Chipcon.awake();
    call SpiByteFifo.enableIntr(); // enable spi interrupt

    return SUCCESS;
  }

  command result_t ChannelMon.stop() {
    CM_state = DISABLED_STATE;
    call Chipcon.rf_pwdn();
    call SpiByteFifo.disableIntr(); // disable spi interrupt

    return SUCCESS;
  }

  command result_t ChannelMon.start() {
    CM_state  = IDLE_STATE;
    CM_waiting = -1;
    spi_byte = 0x00;
    call Chipcon.rf_pwup();
    call SpiByteFifo.enableIntr(); // enable spi interrupt

    return SUCCESS;
  }

  command result_t ChannelMon.mac_delay(TOS_MsgPtr Msg) {
    // msg is pointer to new transmit packet
    txbufptr = Msg;
    txlength = MSG_DATA_SIZE; 
    CM_waiting = ((call Random.rand() & 0x3f) + 100) >> 3;

    return SUCCESS;
  }


/**********************************************************
* make a spibus interrupt handler
* needs to handle interrupts for transmit delay
* and then go into byte transmit mode with
*   timer1 baudrate delay as interrupt handler
* else
* needs to handle interrupts for byte read and detect preamble
*  then handle reading a packet
**********************************************************/

  event result_t SpiByteFifo.dataReady(uint8_t data_in) {
    if (CM_state == DISABLED_STATE)
      return SUCCESS;

    if (CM_state == IDLE_STATE) {
      buf_end = 0;
      buf_head = 0;
      enc_count= 0;

      if(CM_waiting > 0)
        CM_waiting--;

      if(CM_waiting == 1) { // tx timeout go to tx mode
        int i;
        char byte;

	// time to transmit a packet
        cli();

        call Chipcon.txmode();	// radio to tx mode
        
        call SpiByteFifo.txMode(); 	// miso
        for (i=0;i<preamblelen;i++)
        {
          call SpiByteFifo.writeByte(preamble[i]);
        }
        for (i=0;i<txlength;i++)
        {
          byte = ((char*)txbufptr)[i];
          call Code.encode(byte); 
          // call SpiByteFifo.writeByte(byte);
        }
        call Code.encode_flush();
	
	// wait for byte buffer to empty
        while(call SpiByteFifo.isBufEmpty()) ;

        call SpiByteFifo.rxMode(); // miso
        call Chipcon.rxmode();	// radio to rx mode
        CM_state = IDLE_STATE;
	signal ChannelMon.sendDone((TOS_MsgPtr)txbufptr, SUCCESS);	// signal rfcomm
        call SpiByteFifo.enableIntr();  // enable spi interrupts
        sei();  // enable interrupts
        return SUCCESS;
      }
      // go to receive mode and look for incoming packets
      // check for valid preamble
      else
      {
        cli();
        if (data_in==0xaa || data_in==0x55)
          symbolvalid++;
        else
          symbolvalid = 0;
        if (symbolvalid > VALID_PRECURSER)
        {
          symbolvalid = preamblelen;
          CM_state = FIND_SYNC_STATE;
          if (rssi_ena) {
            call ADC.getData();
          }
        }
        sei();
      }
      return SUCCESS;
    }
    if (CM_state == FIND_SYNC_STATE)
    {
      // count the number of precurser bytes and look for a sync byte
      // save the data in an integer with last byte received as msbyte
      //    and current byte received as the lsbyte.
      // use a bit shift compare to find the byte boundary for the sync byte
      // retain the shift value and use it to collect all of the packet data
      // check for data inversion, and restore proper polarity
      // check for end of precurser and bail
      uint8_t i;
      symbolvalid--;
      if (symbolvalid == 0)
      {
        CM_state = IDLE_STATE;
        return SUCCESS;
      }
      // bit shift the data in with previous sample
      for(i=0;i<8;i++)
      {
        current <<= 1;
        if(data_in & 0x80)
          current |=  0x1;
        data_in <<= 1;
        // check for sync byte
        if (current == SYNC_WORD)
        {
          CM_state = READING_STATE;
          offset = 7-i;
          pktcnt = 0;
        }
        if (current == NSYNC_WORD)
        {
          CM_state = READING_STATE;
          offset = 7-i;
          bitflip = 1;
          pktcnt = 0;
        }
      }
      return SUCCESS;
    }
    //  collect the data and shift into double buffer
    //  shift out data by correct offset
    //  invert the data if necessary
    //  stop after the correct packet length is read
    //  return notification to upper levels
    //  go back to idle state

    if (CM_state == READING_STATE)
    {
      uint8_t i;

      for(i=0;i<8;i++)
      {
        current <<= 1;
        if(data_in & 0x80)
          current |=  0x1;
        data_in <<= 1;
      }
      /*
      if (bitflip)
        ((char*)rxbufptr)[(int)pktcnt] = ~current>>offset;
      else
        ((char*)rxbufptr)[(int)pktcnt] = current>>offset;
      pktcnt++;
      if (pktcnt >= rxlength)
      { 
        CM_state = IDLE_STATE;
	rxbufptr = signal ChannelMon.receive((TOS_Msg*)rxbufptr);	// signal rfcomm
      }
      */
      if (bitflip)
        call Code.decode(~current>>offset);
      else
        call Code.decode(current>>offset);
    }
    return SUCCESS;
  }

  event result_t Code.decodeDone(char data, char error) {
    if (CM_state == READING_STATE) {
      ((char*)rxbufptr)[(int)pktcnt] = data;
      pktcnt++;
      if (pktcnt >= rxlength) {
        CM_state = IDLE_STATE;
        msg.strength = 1023;
        if (rssi_ena) {
          msg.strength = signal_strength;
        } 
        rxbufptr = signal ChannelMon.receive((TOS_MsgPtr)rxbufptr);
      }
    }
    return SUCCESS;
  }

  event result_t Code.encodeDone(char data1) {
    if (CM_state == IDLE_STATE) {
      encoded_buffer[(int)buf_end] = data1;
      buf_end++;
      buf_end &= 0x3;
      enc_count += 1;
      
      call SpiByteFifo.writeByte(encoded_buffer[(int)buf_head]);

      buf_head++;
      buf_head &= 0x3;
      enc_count--;
    }
    return SUCCESS;
  }

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

  char delay_null_func()
  {
    return 1;
  }

  char delay(int u_sec)
  {
    int cnt;
    for(cnt=0;cnt<u_sec/8;cnt++)
      delay_null_func();
    return 1;
  }

  event result_t ADC.dataReady(uint16_t data) {
    signal_strength = data;
    return SUCCESS;
  }

}


