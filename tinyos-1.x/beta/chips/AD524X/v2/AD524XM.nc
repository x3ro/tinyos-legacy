// $Id: AD524XM.nc,v 1.1 2005/08/03 23:43:05 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 * @author Joe Polastre <info@moteiv.com>
 * Revision:  $Revision: 1.1 $
 *
 */
includes AD524X;

module AD524XM
{
  provides {
    interface StdControl;
    interface AD524X;
  }
  uses {
    interface StdControl as LowerControl;
    interface MSP430I2CPacket as I2CPacket;
  }
}

implementation
{
  enum {
    AD524X_RDAC   = 1 << 7,
    AD524X_RS     = 1 << 6,
    AD524X_SD     = 1 << 5,
    AD524X_3_8_SD = 1 << 6, /* the AD5243 and AD5248 use a different bit */
    AD524X_O1     = 1 << 4,
    AD524X_O2     = 1 << 3
  };

  enum {
    IDLE = 0,
    AD524X_START,
    AD524X_STOP,
    AD524X_OUTPUT ,
    AD524X_RPOT,
    AD524X_WPOT,
  };
    
  uint8_t data[2];
  uint8_t device[4];
  uint8_t state;
  uint8_t type;
  bool rdac;
  int8_t usercount;

  result_t startWriteCommand(uint8_t _addr, uint8_t _length, uint16_t _data, uint8_t _newstate, bool _rdac, ad524x_type_t _type) {
    uint8_t _state = 0;

    atomic {
      _state = state;
      if (_state == IDLE) {
	state = _newstate;
	type = _type;
	rdac = _rdac;
      }
    }

    if (_state == IDLE) {
      data[0] = _data & 0xFF;
      data[1] = (_data >> 8) & 0xFF;
      if (!call I2CPacket.writePacket((_addr & 0x03) | 0x2C, _length, data)) {
	state = IDLE;
	return FAIL;
      }
      return SUCCESS;
    }
    return FAIL;
  }

  result_t startReadCommand(uint8_t _addr, uint8_t _length, uint8_t _newstate, bool _rdac, ad524x_type_t _type) {
    uint8_t _state = 0;

    atomic {
      _state = state;
      if (_state == IDLE) {
	state = _newstate;
	type = _type;
	rdac = _rdac;
      }
    }

    if (_state == IDLE) {
      if (!call I2CPacket.readPacket((_addr & 0x03) | 0x2C, _length, data)) {
	state = IDLE;
	return FAIL;
      }
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t StdControl.init() {
    atomic {
      usercount = 0;
      state = 0;
    }
    return call LowerControl.init();
  }

  command result_t StdControl.start() {
    int8_t _localcount;
    atomic {
      if (usercount <= 0) {
	TOSH_MAKE_AD524X_SD_OUTPUT();
	TOSH_SET_AD524X_SD_PIN();
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
	TOSH_CLR_AD524X_SD_PIN();
	TOSH_MAKE_AD524X_SD_INPUT();
	usercount = 0;
      }
      _localcount = usercount;
    }
    if (_localcount == 0)
      return call LowerControl.stop();
    else
      return SUCCESS;
  }

  command result_t AD524X.start(uint8_t addr, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242) || (_type == TYPE_AD5245)) {
      atomic device[(int)(addr & 0x03)] &= ~AD524X_SD;
      return startWriteCommand(addr, 1, device[(int)(addr & 0x03)], AD524X_START, 0, _type);
    }
    else if ((_type == TYPE_AD5243) || (_type == TYPE_AD5248)) {
      atomic device[(int)(addr & 0x03)] &= ~AD524X_3_8_SD;
      return startWriteCommand(addr, 1, device[(int)(addr & 0x03)], AD524X_START, 0, _type);
    }
    return FAIL;
  }

  command result_t AD524X.stop(uint8_t addr, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242) || (_type == TYPE_AD5245)) {
      atomic device[(int)(addr & 0x03)] |= AD524X_SD;
      return startWriteCommand(addr, 1, device[(int)(addr & 0x03)], AD524X_STOP, 0, _type);
    }
    else if ((_type == TYPE_AD5243) || (_type == TYPE_AD5248)) {
      atomic device[(int)(addr & 0x03)] |= AD524X_3_8_SD;
      return startWriteCommand(addr, 1, device[(int)(addr & 0x03)], AD524X_STOP, 0, _type);
    }
    return FAIL;
  }

  command result_t AD524X.setOutput(uint8_t addr, bool output, bool high, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242)) {
      atomic {
	if (!output)
	  if (high)
	    device[(int)(addr & 0x03)] |= AD524X_O1;
	  else
	    device[(int)(addr & 0x03)] &= ~AD524X_O1;
	else
	  if (high)
	    device[(int)(addr & 0x03)] |= AD524X_O2;
	  else
	    device[(int)(addr & 0x03)] &= ~AD524X_O2;
      }
      return startWriteCommand(addr, 1, device[(int)addr & 0x03], AD524X_OUTPUT, output, _type);
    }
    return FAIL;
  }

  command bool AD524X.getOutput(uint8_t addr, bool output, ad524x_type_t _type) {
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242)) {
      bool _high;
      if (!output)
	atomic _high = (device[(int)(addr & 0x03)] & AD524X_O1) >> AD524X_O1;
      else
	atomic _high = (device[(int)(addr & 0x03)] & AD524X_O2) >> AD524X_O2;
      return _high;
    }
    return FALSE;
  }
  
  command result_t AD524X.setPot(uint8_t addr, bool _rdac, 
				 uint8_t value, ad524x_type_t _type) {
    uint16_t _temp;
    if ((_type == TYPE_AD5241) || (_type == TYPE_AD5242)) {
      atomic _temp = (device[(int)addr & 0x03] & ~AD524X_RDAC) | (value << 8);
      if ((_type == TYPE_AD5242) && (_rdac)) {
	_temp |= AD524X_RDAC;
      }
      return startWriteCommand(addr, 2, _temp, AD524X_WPOT, _rdac, _type);
    }
    else {
      value = value >> 1; // turn 256-pos value to 128-pos value
      return startWriteCommand(addr, 1, value, AD524X_WPOT, 0, _type);
    } 
  }

  command result_t AD524X.getPot(uint8_t addr, bool _rdac, 
				 ad524x_type_t _type) {
    uint8_t _temp;
    if (_type == TYPE_AD5242) {
      atomic _temp = (device[(int)addr & 0x03] & ~AD524X_RDAC);
      return startWriteCommand(addr, 1, _temp, AD524X_RPOT, _rdac, _type);
    }
    else {
      return startReadCommand(addr, 1, AD524X_RPOT, 0, _type);
    }
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    uint8_t _state;
    bool _rdac;
    uint8_t _type;

    atomic {
      _state = state;
      _rdac = rdac;
      _type = type;
    }

    // check if the buffer is ours
    if (data != _data)
      return;

    switch (_state) {
    case AD524X_RPOT:
      state = IDLE;
      signal AD524X.getPotDone(_addr & 0x03, _rdac, data[0], _success, _type);
      break;
    }
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    uint8_t _state;
    uint8_t _type;
    bool _rdac;

    atomic {
      _state = state;
      _type = type;
      _rdac = rdac;
    }

    // check if the buffer is ours
    if (data != _data)
      return;

    switch (_state) {
    case AD524X_START:
      state = IDLE;
      signal AD524X.startDone(_addr & 0x03, _success, _type);
      break;
    case AD524X_STOP:
      state = IDLE;
      signal AD524X.stopDone(_addr & 0x03, _success, _type);
      break;
    case AD524X_OUTPUT:
      state = IDLE;
      signal AD524X.setOutputDone(_addr & 0x03, _rdac, _success, _type);
      break;
    case AD524X_WPOT:
      state = IDLE;
      if (_length == 1)
	signal AD524X.setPotDone(_addr & 0x03, 0, _success, _type);
      else
	signal AD524X.setPotDone(_addr & 0x03, _rdac, _success, _type);
      break;
    case AD524X_RPOT:
      state = IDLE;
      startReadCommand(_addr, 1, AD524X_RPOT, rdac, type);
      break;
    }
  }

}

