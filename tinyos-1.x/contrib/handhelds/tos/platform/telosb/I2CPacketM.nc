// $Id: I2CPacketM.nc,v 1.1 2006/08/03 19:16:50 ayer1 Exp $
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
 * Provides the ability to write or read a series of bytes to/from the
 * I2C bus.  
 **/
module I2CPacketM
{
  provides {
    interface MSP430I2CPacket as I2CPacket;
    interface StdControl;
  }
  uses {
    interface MSP430I2CPacket as LPacket;
    interface StdControl as LControl;
    interface BusArbitration;
  }
}

implementation
{
  command result_t StdControl.init() {
    call LControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t I2CPacket.readPacket(uint16_t _addr, uint8_t _length, uint8_t* _data) {
    // bus arbitration occurs here
    if (call BusArbitration.getBus() == SUCCESS) {
      if (call LControl.start())
	return call LPacket.readPacket(_addr, _length, _data);
    }
    return FAIL;
  }

  event void LPacket.readPacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result) {
    call LControl.stop();
    call BusArbitration.releaseBus();
    signal I2CPacket.readPacketDone(_addr, _length, _data, _result);
  }

  command result_t I2CPacket.writePacket(uint16_t _addr, uint8_t _length, uint8_t* _data) {
    // bus arbitration occurs here
    if (call BusArbitration.getBus() == SUCCESS) {
      if (call LControl.start())
	return call LPacket.writePacket(_addr, _length, _data);
    }
    return FAIL;
  }

  event void LPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result) {
    call LControl.stop();
    call BusArbitration.releaseBus();
    signal I2CPacket.writePacketDone(_addr, _length, _data, _result);
  }

  event result_t BusArbitration.busFree() { return SUCCESS; }
}
