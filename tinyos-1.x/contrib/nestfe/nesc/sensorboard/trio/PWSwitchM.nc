//$Id: PWSwitchM.nc,v 1.3 2005/07/06 17:25:04 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * Implementation file for the Trio ADC switch <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

module PWSwitchM
{
  provides {
    interface StdControl;
    interface BytePort;
  }
  uses {
    interface StdControl as I2CControl;
    interface MSP430I2CPacket as I2CPacket;
    interface Timer as InitTimer;
  }
}

implementation
{
  enum {
    I2C_ADDR = 0x48,  // ADG715 address 
  };
  enum {
    SET_DATA_LEN = 1,
    SET_DATA_0 = 0x00,  // data byte:
  };

  enum {
    READ_DATA_LEN = 1,
    READ_DATA_0 = 0x00, // data bytes;
  };

  enum {
    STATE_IDLE = 0,
    STATE_INIT,
    STATE_SET ,
    STATE_READ ,
  };

  //// Input terminals
  //enum {
  //  // D1: not used 
  //  // D2: not used 
  //  V_CAP = 0x04, // D3
  //  ADC_EXP2 = 0x08, // D4
  //  // D5: not used
  //  // D6: not used
  //  V_BAT = 0x40, // D7 
  //  ADC_EXP1 = 0x80, // D8
  //};

  // Output terminals
  // S1 thru S4 wired to ADC_MUX0
  // S5 thru S8 wired to ADC_MUX1

  /** 
     Initialize the switches to read V_BAT and V_CAP

     S8 open  : 0
     S7 => D7 : 1
     S6 open  : 0
     S5 open  : 0
     S4 open  : 0
     S3 => D3 : 1
     S2 open  : 0
     S1 open  : 0
   **/
  uint8_t sw_bits = 0x88;
  uint8_t state = STATE_IDLE;
  bool bInit = FALSE;
  int8_t usercount;

  uint8_t data_set[SET_DATA_LEN];
  uint8_t data_read[READ_DATA_LEN];

  task void port_init_task();
  task void port_set_task();
  task void port_read_task();

  command result_t StdControl.init() {

    atomic usercount = 0;
    
    data_set[0] = SET_DATA_0;
    data_read[0] = READ_DATA_0;

    return call I2CControl.init();
  }
    
  command result_t StdControl.start() {
    int8_t _localcount;
    atomic {
      if (usercount <= 0) {
        usercount = 0;
      }
      _localcount = usercount;
      usercount++;
    }
    if (_localcount == 0) {
      call I2CControl.start();
      call InitTimer.start(TIMER_ONE_SHOT, 80);
    }
    return SUCCESS;
  }

  task void port_init_task() {
    call I2CPacket.writePacket(I2C_ADDR, SET_DATA_LEN, data_set);
  }

  event result_t InitTimer.fired() {
    uint8_t _state;
    bool _bInit;

    atomic {
      _state = state;
      _bInit = bInit;
    }
    if (_state == STATE_IDLE && _bInit == FALSE) {
      atomic state = STATE_INIT;
      data_set[0] = sw_bits;
      post port_init_task();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    int8_t _localcount;
    atomic {
      usercount--;
      if (usercount <= 0) {
        usercount = 0;
      }
      _localcount = usercount;
    }
    if (_localcount == 0) {
      return call I2CControl.stop();
    }
    else {
      return SUCCESS;
    }
  }

  task void port_set_task() {
    call I2CPacket.writePacket(I2C_ADDR, SET_DATA_LEN, data_set);
  }

  task void port_read_task() {
    call I2CPacket.readPacket(I2C_ADDR, READ_DATA_LEN, data_read);
  }

  command result_t BytePort.setPort(uint8_t bits) {
    uint8_t _state;
    atomic _state = state;
    data_set[0] = bits;
    if (_state == STATE_IDLE) {
      atomic state = STATE_SET;   
      post port_set_task();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t BytePort.getPort() {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ;
      post port_read_task();
      return SUCCESS;
    }
    return FAIL;
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) {

    uint8_t _state;
    atomic _state = state;

    if (_success == FAIL) {
      if (_state == STATE_INIT) {
        post port_init_task();
      }
      else if (_state == STATE_SET) {
        post port_set_task();
      }
    }
    else {
      if (_state == STATE_INIT) {
        atomic {
          state = STATE_IDLE;
          bInit = TRUE;
        }
      }
      else if (_state == STATE_SET) {
        atomic state = STATE_IDLE;
        signal BytePort.setPortDone(_success);
      }
    }
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) {

    uint8_t _state;
    atomic _state = state;

    if (_success == FAIL) {
      if (_state == STATE_READ) {
        post port_read_task();
      }
    }
    else {
      if (_state == STATE_READ) {
        atomic state = STATE_IDLE;
        signal BytePort.getPortDone(_data[0], _success);
      }
    }
  }



}
