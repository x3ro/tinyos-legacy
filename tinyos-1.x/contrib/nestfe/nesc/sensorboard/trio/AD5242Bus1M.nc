// $Id: AD5242Bus1M.nc,v 1.1 2005/06/02 00:42:43 jaein Exp $
/*
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
 */

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1 $
 *
 */

module AD5242Bus1M
{
  provides {
    interface StdControl;
    interface AD5242;
  }
  uses {
    interface StdControl as LowerControl;
    interface MSP430I2CPacket as I2CPacket;
  }
}

implementation
{
  enum {
    AD524X_RDAC = 1 << 7,
    AD524X_RS   = 1 << 6,
    AD524X_SD   = 1 << 5,
    AD524X_O1   = 1 << 4,
    AD524X_O2   = 1 << 3
  };

  enum {
    IDLE = 0,

    AD5242_START,
    AD5242_STOP,
    AD5242_WRITE,
    AD5242_READ,
    AD5242_OUTPUT1,
    AD5242_OUTPUT2,
    AD5242_POT1,
    AD5242_POT2,
    AD5242_RPOT1,
    AD5242_RPOT2,
  };
    
  uint8_t data[2];
  uint8_t device[4];
  uint8_t state;
  int8_t usercount;

  result_t startWriteCommand(uint8_t _addr, uint8_t _length, uint16_t _data, uint8_t _newstate) {
    uint8_t _state = 0;

    atomic {
      _state = state;
      if (_state == IDLE)
	state = _newstate;
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

  result_t startReadCommand(uint8_t _addr, uint8_t _length, uint8_t _newstate) {
    uint8_t _state = 0;

    atomic {
      _state = state;
      if (_state == IDLE)
	state = _newstate;
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
	      //TOSH_MAKE_AD524X_SD_OUTPUT();
	      //TOSH_SET_AD524X_SD_PIN();
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
	      //TOSH_CLR_AD524X_SD_PIN();
	      //TOSH_MAKE_AD524X_SD_INPUT();
	      usercount = 0;
      }
      _localcount = usercount;
    }
    if (_localcount == 0)
      return call LowerControl.stop();
    else
      return SUCCESS;
  }

  /** START commands **/
  command result_t AD5242.start(uint8_t addr) {
    atomic device[(int)(addr & 0x03)] &= ~AD524X_SD;
    return startWriteCommand(addr, 1, device[(int)(addr & 0x03)], AD5242_START);
  }

  /** STOP commands **/
  command result_t AD5242.stop(uint8_t addr) {
    atomic device[(int)(addr & 0x03)] |= AD524X_SD;
    return startWriteCommand(addr, 1, device[(int)(addr & 0x03)], AD5242_STOP);
  }

  /** OUTPUT 1 **/
  command result_t AD5242.setOutput1(uint8_t addr, bool high) {
    atomic {
      if (high)
	device[(int)(addr & 0x03)] |= AD524X_O1;
      else
	device[(int)(addr & 0x03)] &= ~AD524X_O1;
    }
    return startWriteCommand(addr, 1, device[(int)addr & 0x03], AD5242_OUTPUT1);
  }

  command result_t AD5242.getOutput1(uint8_t addr) {
    bool _high;
    atomic _high = (device[(int)(addr & 0x03)] & AD524X_O1) >> AD524X_O1;
    return _high;
  }

  /** OUTPUT 2 **/
  command result_t AD5242.setOutput2(uint8_t addr, bool high) {
    atomic {
      if (high)
	device[(int)(addr & 0x03)] |= AD524X_O2;
      else
	device[(int)(addr & 0x03)] &= ~AD524X_O2;
    }
    return startWriteCommand(addr, 1, device[(int)addr & 0x03], AD5242_OUTPUT2);
  }

  command result_t AD5242.getOutput2(uint8_t addr) {
    bool _high;
    atomic _high = (device[(int)(addr & 0x03)] & AD524X_O2) >> AD524X_O2;
    return _high;
  }

  /** POT 1 - set commands**/
  command result_t AD5242.setPot1(uint8_t addr, uint8_t value) {
    uint16_t _temp;
    atomic _temp = (device[(int)addr & 0x03] & ~AD524X_RDAC) | (value << 8);
    return startWriteCommand(addr, 2, _temp, AD5242_POT1);
  }

  /** POT 2 - set commands**/
  command result_t AD5242.setPot2(uint8_t addr, uint8_t value) {
    uint16_t _temp;
    atomic _temp = (device[(int)addr & 0x03] | AD524X_RDAC) | (value << 8);
    return startWriteCommand(addr, 2, _temp, AD5242_POT2);
  }

  /** POT 1 - get commands**/
  command result_t AD5242.getPot1(uint8_t addr) {
    uint8_t _temp;
    atomic _temp = (device[(int)addr & 0x03] & ~AD524X_RDAC);
    return startWriteCommand(addr, 1, _temp, AD5242_RPOT1);
  }

  /** POT 2 - get commands**/
  command result_t AD5242.getPot2(uint8_t addr) {
    uint8_t _temp;
    atomic _temp = (device[(int)addr & 0x03] | AD524X_RDAC);
    return startWriteCommand(addr, 1, _temp, AD5242_RPOT2);
  }

  event void I2CPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    uint8_t _state;
    atomic _state = state;

    // check if the buffer is ours
    if (data != _data)
      return;

    switch (_state) {
    case AD5242_RPOT1:
      state = IDLE;
      signal AD5242.getPot1Done(_addr & 0x03, data[0], _success);
      break;
    case AD5242_RPOT2:
      state = IDLE;
      signal AD5242.getPot2Done(_addr & 0x03, data[0], _success);
      break;
    }
  }

  event void I2CPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _success) { 
    uint8_t _state;
    atomic _state = state;

    // check if the buffer is ours
    if (data != _data)
      return;

    switch (_state) {
    // AD5242 events
    case AD5242_START:
      state = IDLE;
      signal AD5242.startDone(_addr & 0x03, _success);
      break;
    case AD5242_STOP:
      state = IDLE;
      signal AD5242.stopDone(_addr & 0x03, _success);
      break;
    case AD5242_OUTPUT1:
      state = IDLE;
      signal AD5242.setOutput1Done(_addr & 0x03, _success);
      break;
    case AD5242_OUTPUT2:
      state = IDLE;
      signal AD5242.setOutput2Done(_addr & 0x03, _success);
      break;
    case AD5242_POT1:
      state = IDLE;
      signal AD5242.setPot1Done(_addr & 0x03, _success);
      break;
    case AD5242_POT2:
      state = IDLE;
      signal AD5242.setPot2Done(_addr & 0x03, _success);
      break;
    case AD5242_RPOT1:
      state = IDLE;
      startReadCommand(_addr, 1, AD5242_RPOT1);
      break;
    case AD5242_RPOT2:
      state = IDLE;
      startReadCommand(_addr, 1, AD5242_RPOT2);
      break;
    }
  }

  default event void AD5242.startDone(uint8_t addr, result_t result) { }
  default event void AD5242.stopDone(uint8_t addr, result_t result) { }
  default event void AD5242.setOutput1Done(uint8_t addr, result_t result) { }
  default event void AD5242.setOutput2Done(uint8_t addr, result_t result) { }
  default event void AD5242.setPot1Done(uint8_t addr, result_t result) { }
  default event void AD5242.getPot1Done(uint8_t addr, uint8_t value, result_t result) { }
  default event void AD5242.setPot2Done(uint8_t addr, result_t result) { }
  default event void AD5242.getPot2Done(uint8_t addr, uint8_t value, result_t result) { }


}

