// $Id: I2CPacketM.nc,v 1.1.1.1 2007/11/05 19:11:35 jpolastre Exp $
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
 * Provides the ability to write or read a series of bytes to/from the
 * I2C bus.  
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
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

    interface ResourceValidate as I2CValidate;
  }
}

implementation
{
  command result_t StdControl.init() {
    call LControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call LControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t I2CPacket.readPacket( uint8_t rh, uint16_t _addr, uint8_t _length, uint8_t* _data ) {
    if( call I2CValidate.validateUser(rh) ) {
      if( call LPacket.readPacket( rh, _addr, _length, _data ) == SUCCESS )
        return SUCCESS;
    }
    return FAIL;
  }

  event void LPacket.readPacketDone( uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result ) {
    signal I2CPacket.readPacketDone( _addr, _length, _data, _result );
  }

  command result_t I2CPacket.writePacket( uint8_t rh, uint16_t _addr, uint8_t _length, uint8_t* _data ) {
    if( call I2CValidate.validateUser(rh) ) {
      if( call LPacket.writePacket( rh, _addr, _length, _data ) == SUCCESS )
        return SUCCESS;
    }
    return FAIL;
  }

  event void LPacket.writePacketDone(uint16_t _addr, uint8_t _length, uint8_t* _data, result_t _result) {
    signal I2CPacket.writePacketDone( _addr, _length, _data, _result );
  }
}

