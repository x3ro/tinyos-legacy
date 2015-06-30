// $Id: PWSwitchM.nc,v 1.1 2005/08/19 03:59:06 jwhui Exp $

/*									tab:2
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

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module PWSwitchM {
  provides {
    interface StdControl;
  }
  uses {
    interface MSP430I2CPacket as I2CPacket;
    interface StdControl as I2CControl;
    interface Timer;
  }
}

implementation {

  enum {
    I2C_ADDR = 0x48,
    I2C_DATA = 0x44,
  };

  uint8_t data_set;

  command result_t StdControl.init() {
    data_set = 0x44;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start( TIMER_ONE_SHOT, 4095 );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call I2CPacket.writePacket( I2C_ADDR, sizeof( data_set ), &data_set );
    return SUCCESS;
  }

  event void I2CPacket.writePacketDone( uint16_t addr, uint8_t len,
					uint8_t* data, result_t success ) {}

  event void I2CPacket.readPacketDone( uint16_t addr, uint8_t len,
				       uint8_t* data, result_t success ) {}

}
