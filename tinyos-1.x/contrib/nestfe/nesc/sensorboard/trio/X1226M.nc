//$Id: X1226M.nc,v 1.2 2005/07/06 17:25:14 cssharp Exp $
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
 * Implementation for X1226 Real Timer Clock/Calendar chip. <p>
 *
 * @modified 5/17/05
 *
 * @author Jaein Jeong
 */

module X1226M
{
  provides {
    interface StdControl;
    interface X1226;
  }
  uses {
    interface StdControl as LowerControl;
    interface MSP430I2CPacket as I2CPacket;
  }
}

implementation
{
  enum {
    I2C_ADDR = 0x6f,
  };

  enum {
    SET_DATA_LEN = 3,
    READ_START_LEN = 2,
    READ_DATA_LEN = 1,
    SET_PAGE_LEN = 10,
    READ_PAGE_LEN = 8,
  };

  enum {
    STATE_IDLE = 0,
    STATE_WRITE_BYTE,
    STATE_READ_BYTE_START,
    STATE_READ_BYTE,
    STATE_WRITE_PAGE,
    STATE_READ_PAGE_START,
    STATE_READ_PAGE,
  }; 

  uint8_t set_page_len;
  uint8_t read_page_len;

  uint8_t data_set[SET_PAGE_LEN];
  uint8_t data_read[READ_PAGE_LEN];

  uint8_t state;
  int8_t usercount;
  uint8_t m_length_read;

  task void set_reg_byte_task();
  task void read_reg_byte_task();
  task void read_start_reg_byte_task();
  task void set_reg_page_task();
  task void read_start_reg_page_task();
  task void read_reg_page_task();

  uint8_t min(uint8_t a, uint8_t b) {
    if (a > b) 
      return b;
    else 
      return a;
  }

  command result_t StdControl.init() {
    int i;
    atomic {
      usercount = 0;
      state = 0;
    }

    for (i = 0; i < SET_PAGE_LEN; i++) {
      data_set[i] = 0;
    }
    for (i = 0; i < READ_PAGE_LEN; i++) {
      data_set[i] = 0;
    }

    return call LowerControl.init();
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
    if (_localcount == 0)
      return call LowerControl.start();
    else
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
    if (_localcount == 0)
      return call LowerControl.stop();
    else
      return SUCCESS;
  }

  command result_t X1226.setRegByte(uint16_t wordaddr, uint8_t bits) {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_WRITE_BYTE;
      data_set[0] = (wordaddr >> 8) & 0x01;   // word address 1
      data_set[1] = wordaddr & 0xff;          // word address 0
      data_set[2] = bits;                     // data bits 
      post set_reg_byte_task();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t X1226.getRegByte(uint16_t wordaddr) {
    uint8_t _state;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_BYTE_START;
      data_set[0] = (wordaddr >> 8) & 0x01;   // word address 1
      data_set[1] = wordaddr & 0xff;          // word address 0
      post read_start_reg_byte_task();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t X1226.setRegPage(uint16_t wordaddr, uint8_t datalen, 
                              uint8_t *bits_array) {
    int i;
    uint8_t _state;
    uint8_t _set_page_len;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_WRITE_PAGE;
      data_set[0] = (wordaddr >> 8) & 0x01;   // word address 1
      data_set[1] = wordaddr & 0xff;          // word address 0

      _set_page_len = min(datalen, SET_PAGE_LEN-2);
      atomic set_page_len = _set_page_len;

      // data bits
      for (i = 0; i < _set_page_len; i++) {
        data_set[i+2] = bits_array[i];
      } 
      post set_reg_page_task();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t X1226.getRegPage(uint16_t wordaddr, uint8_t datalen) {
    uint8_t _state;
    uint8_t _read_page_len;
    atomic _state = state;
    if (_state == STATE_IDLE) {
      atomic state = STATE_READ_PAGE_START;
      data_set[0] = (wordaddr >> 8) & 0x01;   // word address 1
      data_set[1] = wordaddr & 0xff;          // word address 0

      _read_page_len = min(datalen, READ_PAGE_LEN);
      atomic read_page_len = _read_page_len; 

      post read_start_reg_page_task();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length,
                                      uint8_t* _data, result_t _success) {
    uint8_t _state;
    atomic _state = state;
  
    if (_success == FAIL) {
      if (_state == STATE_READ_BYTE) {
        post read_reg_byte_task();
      }
      if (_state == STATE_READ_PAGE) {
        post read_reg_page_task();
      }
    }
    else {
      if (_state == STATE_READ_BYTE) {
        atomic state = STATE_IDLE;
        signal X1226.getRegByteDone(data_read[0], SUCCESS);
      }
      if (_state == STATE_READ_PAGE) {
        atomic state = STATE_IDLE;
        signal X1226.getRegPageDone(_length, data_read, SUCCESS);
      }
    }
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length,
                                       uint8_t* _data, result_t _success) {
    uint8_t _state;
    atomic _state = state;

    if (_success == FAIL) {
      if (_state == STATE_WRITE_BYTE) {
        post set_reg_byte_task();
      }
      else if (_state == STATE_READ_BYTE_START) {
        post read_start_reg_byte_task();
      }
      else if (_state == STATE_WRITE_PAGE) {
        post set_reg_page_task();  
      }
      else if (_state == STATE_READ_PAGE_START) {
        post read_start_reg_page_task();
      }
    }
    else {
      if (_state == STATE_WRITE_BYTE) {
        atomic state = STATE_IDLE;
        signal X1226.setRegByteDone(_success);
      }
      else if (_state == STATE_READ_BYTE_START) {
        atomic state = STATE_READ_BYTE;
        post read_reg_byte_task();
      } 
      else if (_state == STATE_WRITE_PAGE) {
        atomic state = STATE_IDLE;
        signal X1226.setRegPageDone(_success);
      }
      else if (_state == STATE_READ_PAGE_START) {
        atomic state = STATE_READ_PAGE;
        post read_reg_page_task();
      } 
    }
  }
  
  task void set_reg_byte_task() {
    call I2CPacket.writePacket(I2C_ADDR, SET_DATA_LEN, data_set);
  } 

  task void read_reg_byte_task() {
    call I2CPacket.readPacket(I2C_ADDR, READ_DATA_LEN, data_read);
  }

  task void read_start_reg_byte_task() {
    call I2CPacket.writePacket(I2C_ADDR, READ_START_LEN, data_set);
  } 

  task void set_reg_page_task() {
    call I2CPacket.writePacket(I2C_ADDR, set_page_len, data_set);
  }

  task void read_start_reg_page_task() {
    call I2CPacket.writePacket(I2C_ADDR, READ_START_LEN, data_set);
  } 

  task void read_reg_page_task() {
    call I2CPacket.readPacket(I2C_ADDR, read_page_len, data_read);
  }

  default event void X1226.setRegByteDone(result_t result) { }
  default event void X1226.setRegPageDone(result_t result) { }
  default event void X1226.getRegByteDone(uint8_t databyte, result_t result) { }
  default event void X1226.getRegPageDone(uint8_t datalen, uint8_t* databytes, result_t result) { }

}



