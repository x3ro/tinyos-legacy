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
module RFCommM {
  provides {
    interface RFComm;
    interface RSSI;
  }
  uses interface ChannelMon;
  uses interface Chipcon;
}
implementation
{
  enum {
    IDLE_STATE,
    RX_STATE = 2
  };
  enum {
    FREQ_DEFAULT = 0,
    MODE_DEFAULT = 1
  };
  enum {
    RF_IDLE,
    RF_RXMODE = 2,
    RF_TXMODE
  };

  enum {
    BUF_IDLE,
    BUF_BUSY,
    BUF_FULL
  };

  enum {
    PWDOWN,
    PWUP,
    SLEEP,
    AWAKE
  };

  char state;	// rfcomm mode RF_IDLE, RF_TXMODE, RF_RXMODE
  char send_state;	
  char rxbuf_state;	// RX buffer state BUF_IDLE, BUF_BUSY, BUF_FULL
  char txbuf_state;	// TX buffer state BUF_IDLE, BUF_BUSY, BUF_FULL
  char tx_count;
  short crc_local;
  char rec_count;
  TOS_Msg buffer;
  TOS_MsgPtr rec_ptr;
  TOS_MsgPtr send_ptr;
  unsigned char rx_count;
  char msg_length;
  char tunefreq;

  short calc_crc();
  char check_crc(TOS_MsgPtr msg);

  command result_t RFComm.init() {	
    tunefreq = FREQ_DEFAULT;
    rec_ptr = &buffer;
    txbuf_state = BUF_IDLE;
    rxbuf_state = BUF_IDLE;
    call Chipcon.init(FREQ_DEFAULT);
    call ChannelMon.init(FREQ_DEFAULT);

    return SUCCESS; 
  }

  command result_t RFComm.rf_power(uint8_t rfpower) {
    return call Chipcon.rf_power(rfpower);
  }

  command result_t RFComm.rf_pwup() {
    // return call Chipcon.rf_pwup();
    return call ChannelMon.start();
  }

  command result_t RFComm.rf_pwdn() {
    // return call Chipcon.rf_pwdn();
    return call ChannelMon.stop();
  }

  command result_t RFComm.tune(uint8_t freq) {
    if (txbuf_state == BUF_IDLE)
    {
      tunefreq = freq;
      rxbuf_state = BUF_IDLE;
      call Chipcon.tune(freq);
      call ChannelMon.tune(freq);

      return SUCCESS;
    }
    return FAIL; 
  }

  command result_t RFComm.send(TOS_MsgPtr msg) {
    TOS_MsgPtr tmp = msg;
    if (txbuf_state == BUF_IDLE)
    {
      send_ptr = tmp;
      txbuf_state = BUF_FULL;
      calc_crc();	// calculate crc and add to message
      call ChannelMon.mac_delay(tmp);

      return SUCCESS;
    }
    return FAIL;
  }

  command result_t RFComm.rssi_enable() {
    call ChannelMon.rssi_enable();
    return SUCCESS;
  }

  command result_t RFComm.rssi_disable() {
    call ChannelMon.rssi_disable();
    return SUCCESS;
  }

  command result_t RSSI.rssi_enable() {
    call ChannelMon.rssi_enable();
    return SUCCESS;
  }

  command result_t RSSI.rssi_disable() {
    call ChannelMon.rssi_disable();
    return SUCCESS;
  }

  command result_t RFComm.power(uint8_t mode) {
    if (txbuf_state == BUF_IDLE)
    {
      if (mode == PWDOWN)
        call ChannelMon.stop();
      if (mode == PWUP)
        call ChannelMon.start();
      if (mode == SLEEP)
        call ChannelMon.sleep();
      if (mode == AWAKE)
        call ChannelMon.awake();
    }
    return SUCCESS;
  }

  event result_t ChannelMon.sendDone(TOS_MsgPtr msg, result_t success) {
    TOS_MsgPtr tmp = msg;
    txbuf_state = BUF_IDLE;
    signal RFComm.sendDone((TOS_MsgPtr) tmp, SUCCESS);
    return SUCCESS;
  }

  event TOS_MsgPtr ChannelMon.receive(TOS_MsgPtr msg) {
    TOS_MsgPtr tmp = msg;
    TOS_MsgPtr atmp = msg;
 
    char crc_ok = 1;
    crc_ok = check_crc(msg);	// check for valid checksum
    if (!crc_ok)		// checksum invalid
    {
      return tmp;
    }
    // if the app layer doesn't take the packet pointer,
    // keep the pointer and overwrite the buffer
    // check for valid local address

    if ((msg->group) == (TOS_AM_GROUP & 0xff))
    {
      atmp = signal RFComm.receive((TOS_MsgPtr) msg);
      // signal event packet received
      if (atmp != 0)
        tmp = atmp;
    }

    return tmp;
  }

/*********************************************************
*  local function definitions
*********************************************************/

  short calc_crc()
  {
    short crc, i;
    int temp;
    int length = MSG_DATA_SIZE;
    char *ptr = (char*)send_ptr;
    int count = length - 2;

    crc = 0;
    while (--count >= 0)
    {
      temp = (int) *ptr++;
      crc = crc ^ temp << 8;
      for (i = 0; i < 8; i++)
      {
        if (crc & 0x8000)
          crc = ((crc << 1) & 0xfffe) ^ 0x1021;
        else
          crc = crc << 1;
      }
    }

    ((char*)send_ptr)[length-2] = (crc & 0xff);
    ((char*)send_ptr)[length-1] = ((crc >> 8) & 0xff);

    return crc;
  }

/*
  char check_crc(TOS_MsgPtr msg)
  {
    return 1;
  }
*/

  char check_crc(TOS_MsgPtr msg)
  {
    short crc, i;
    int temp;
    char test = 0;
    int length = MSG_DATA_SIZE;
    char *ptr = (char*)msg;
    int count = length - 2;

    crc = 0;
    while (--count >= 0)
    {
      temp = (int) *ptr++;
      crc = crc ^ temp << 8;
      for (i = 0; i < 8; i++)
      {
        if (crc & 0x8000)
          crc = ((crc << 1) & 0xfffe) ^ 0x1021;
        else
          crc = crc << 1;
      }
    }
    if ((msg->crc) == crc)
      test = 1;

    return test;
  }

 
}
