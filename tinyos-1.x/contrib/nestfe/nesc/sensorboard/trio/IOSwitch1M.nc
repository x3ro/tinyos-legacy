//$Id: IOSwitch1M.nc,v 1.4 2005/07/29 00:31:28 jaein Exp $
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
 * Implementation file for the first PCA9555 IOSwitch. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

module IOSwitch1M
{
  provides {
    interface StdControl;
    interface IOSwitch;
    interface IOSwitchInterrupt;
  }
  uses {
    interface StdControl as I2CControl;
    interface MSP430I2CPacket as I2CPacket;
    interface Timer as InitTimer;
    interface Timer as DebounceTimer;

    interface MSP430Interrupt;
    interface MSP430GeneralIO;
  }
}

implementation
{
  enum {
    I2C_ADDR = 0x20,   // PCA9555 address for testing
  };

  /** 
     Initialize the port directions.
     Output bit is set as 0 and
     input bit is set as 1.
  
     io0/0: Output, PWR_SW
     io0/1: Output, CHARGE_SW
     io0/2: Output, PW_ACOUSTIC
     io0/3: Output, PW_MAG
     io0/4: Output, PW_PIR
     io0/5: Output, PW_SOUNDER
     io0/6: Output, PWM_SOUNDER
     io0/7: Output, MSG_SR
  
     io1/0: Input, INT_ACOUSTIC
     io1/1: Input, INT_PIR
     io1/2: Input, INT_PIR0
     io1/3: Input, INT_PIR1
     io1/4: Input, INT_PIR2
     io1/5: Input, INT_PIR3
     io1/6: Not used
     io1/7: Not used
   **/

  enum {
    CONFIG_DATA_LEN = 3,
    CONFIG_DATA_0 = 0x06, // command byte: configuration register
    CONFIG_DATA_1 = 0x00, // data byte 0: port 0 direction
    //CONFIG_DATA_2 = 0x3f, // data byte 1: port 1 direction
    // We are not using input pins, so drive them low.
    CONFIG_DATA_2 = 0x00, // data byte 1: port 1 direction
  };

  enum {
    SET_DATA_LEN = 3,
    SET_DATA_0 = 0x02, // command byte: output port register
    SET_DATA_1 = 0x00, // data byte 0:
    SET_DATA_2 = 0x00, // data byte 1:
  };

  enum {
    READ_START_LEN = 1,
    READ_START_0 = 0x00,
    READ_DATA_LEN = 2,
  };

  enum {
    STATE_IDLE = 0,
    STATE_INIT1,
    STATE_INIT2,
    STATE_SET,
    STATE_READ,
    STATE_READ_INTERNAL,
  };

  enum {  
    IOSWITCH1_INIT = 0x3e,
  };

  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;
  uint8_t data[8];
  uint8_t state = STATE_IDLE;
  uint8_t subcmd = 0;
  int8_t usercount;

  bool bInit = FALSE;

  uint8_t data_config[CONFIG_DATA_LEN];
  uint8_t data_set[SET_DATA_LEN];
  uint8_t data_start[READ_START_LEN];
  uint8_t data_read[READ_DATA_LEN];

  void port_init1_task();
  void port_init2_task();
  void port_set_task();
  void port_read_task();
  void port_read_start_task();
  void data_send_task();
  void data_report_task();
  void interrupt_report_task();

  command result_t StdControl.init() {

    usercount = 0;

    call I2CControl.init();

    atomic {
      call MSP430Interrupt.disable();
      call MSP430GeneralIO.makeInput();
      call MSP430GeneralIO.selectIOFunc();
      call MSP430Interrupt.edge(TRUE);
      call MSP430Interrupt.clear();
      call MSP430Interrupt.enable();
    }

    data_config[0] = CONFIG_DATA_0;
    data_config[1] = CONFIG_DATA_1;
    data_config[2] = CONFIG_DATA_2;

    data_set[0] = SET_DATA_0;
    data_set[1] = SET_DATA_1;
    data_set[2] = SET_DATA_2;

    data_start[0] = READ_START_0;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    int8_t _localcount;

    if (usercount <= 0) {
      usercount = 0;
    }
    _localcount = usercount;
    usercount++;

    if (_localcount == 0) {
      call I2CControl.start();
      call InitTimer.start(TIMER_ONE_SHOT, 100);
      call MSP430Interrupt.clear();
      call MSP430Interrupt.enable();
    }
    return SUCCESS;
  }

  event result_t InitTimer.fired() {
    if (state == STATE_IDLE && bInit == FALSE) {
      state = STATE_INIT1;
      port_init1_task();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    int8_t _localcount;

    usercount--;
    if (usercount <= 0) {
      usercount = 0;
    }
    _localcount = usercount;

    if (_localcount == 0) {
      call I2CControl.stop();
      call MSP430Interrupt.disable();
    }
    return SUCCESS;
  }

  void port_init1_task() {
    call I2CPacket.writePacket(I2C_ADDR, CONFIG_DATA_LEN, data_config);
  }

  void port_init2_task() {
    data_set[1] = IOSWITCH1_INIT & 0xff;          // port 0
    data_set[2] = (IOSWITCH1_INIT >> 8) & 0xff;   // port 1
    call I2CPacket.writePacket(I2C_ADDR, SET_DATA_LEN, data_set);
  }

  void port_set_task() {
    call I2CPacket.writePacket(I2C_ADDR, SET_DATA_LEN, data_set);
  }

  void port_read_start_task() {
    call I2CPacket.writePacket(I2C_ADDR, READ_START_LEN, data_start);
  }

  void port_read_task() {
    call I2CPacket.readPacket(I2C_ADDR, READ_DATA_LEN, data_read);
  }

  void data_report_task() {
    uint16_t _bits;
    _bits = data_read[0] & 0xff;
    _bits |= (data_read[1] & 0xff) << 8;
    signal IOSwitch.getPortDone(_bits, SUCCESS);
  }

  void interrupt_report_task() {
    uint8_t _mask = 0x0;

    if ( (data_read[1] & IOSWITCH1_INT_ACOUSTIC) == 0 ) {
      _mask |= IOSWITCH1_INT_ACOUSTIC;
    }
    if ( (data_read[1] & IOSWITCH1_INT_PIR) == 0 ) {
      _mask |= IOSWITCH1_INT_PIR;
    }
    if ( (data_read[1] & IOSWITCH1_INT_PIR0) != 0 ) {
      _mask |= IOSWITCH1_INT_PIR;
    }
    if ( (data_read[1] & IOSWITCH1_INT_PIR1) != 0 ) {
      _mask |= IOSWITCH1_INT_PIR;
    }
    if ( (data_read[1] & IOSWITCH1_INT_PIR2) != 0 ) {
      _mask |= IOSWITCH1_INT_PIR;
    }
    if ( (data_read[1] & IOSWITCH1_INT_PIR3) != 0 ) {
      _mask |= IOSWITCH1_INT_PIR;
    }

    signal IOSwitchInterrupt.fired(_mask);
  }

  command result_t IOSwitch.setPort(uint16_t bits) {

    data_set[1] = bits & 0xff;          // port 0
    data_set[2] = (bits >> 8) & 0xff;   // port 1

    if (state == STATE_IDLE) {
      state = STATE_SET;
      port_set_task();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t IOSwitch.setPort0Pin(uint8_t mask, bool high) {

    if (high) 
      data_set[1] |= mask;
    else 
      data_set[1] &= ~mask;
    
    if (state == STATE_IDLE) {
      state = STATE_SET;
      port_set_task();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t IOSwitch.setPort1Pin(uint8_t mask, bool high) {

    if (high) 
      data_set[2] |= mask;
    else 
      data_set[2] &= ~mask;
    
    if (state == STATE_IDLE) {
      state = STATE_SET;
      port_set_task();
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t IOSwitch.getPort() {

    if (state == STATE_IDLE) {
      state = STATE_READ;
      port_read_start_task();
      return SUCCESS;
    }
    return FAIL;
  }

  void port_setdone_task() {
    state = STATE_IDLE;
    signal IOSwitch.setPortDone(SUCCESS);
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length,
                                       uint8_t* _data, result_t _success) {
    // retry if I2C write is not successful.
    if (_success == FAIL) {
      if (state == STATE_INIT1) {
        port_init1_task();
      }
      else if (state == STATE_INIT2) {
        port_init2_task();
      }
      else if (state == STATE_SET) {
        port_set_task();
      }
      else if (state == STATE_READ) {
        state = STATE_IDLE;
      }
      else if (state == STATE_READ_INTERNAL) {
        state = STATE_IDLE;
      }
    }
    // proceed to the next state.
    else {
      if (state == STATE_INIT1) {
        state = STATE_INIT2;
        port_init2_task();
      }
      else if (state == STATE_INIT2) {
        state = STATE_IDLE;
        bInit = TRUE;
      }
      else if (state == STATE_SET) {
        port_setdone_task();
      }
      else if (state == STATE_READ) {
        port_read_task();
      } 
      else if (state == STATE_READ_INTERNAL) {
        port_read_task();
      } 
    }
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, 
                                      uint8_t* _data, result_t _success) {
    // retry if I2C write is not successful.
    if (_success == FAIL) {
      if (state == STATE_READ) {
        state = STATE_IDLE;
      }
      else if (state == STATE_READ_INTERNAL) {
        state = STATE_IDLE;
      }
    }
    // report the read I2C data.
    else {
      if (state == STATE_READ) {
        state = STATE_IDLE;
        data_report_task();
      }
      else if (state == STATE_READ_INTERNAL) {
        state = STATE_IDLE;
        interrupt_report_task();
      }
    }
  }

  event result_t DebounceTimer.fired() {
    call MSP430Interrupt.clear();
    call MSP430Interrupt.enable();
    return SUCCESS;
  }

  void debounce() {
    call DebounceTimer.start( TIMER_ONE_SHOT, 50 );
  }


  task void interrupt_fired() {
    debounce();
    if (state == STATE_IDLE) {
      state = STATE_READ_INTERNAL;
      port_read_start_task();
    }
    //signal IOSwitchInterrupt.fired(0);
  }

  async event void MSP430Interrupt.fired() {
    call MSP430Interrupt.disable();
    post interrupt_fired();
  }

  default event void IOSwitch.setPortDone(result_t result) { }
  default event void IOSwitch.getPortDone(uint16_t bits, result_t result){}
  default async event void IOSwitchInterrupt.fired(uint8_t mask) { }
}

