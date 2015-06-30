// $Id: IOSwitchM.nc,v 1.9 2005/08/24 17:57:39 gtolle Exp $

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

module IOSwitchM {
  provides {
    interface StdControl;
    interface StdControl as Battery;
    interface StdControl as Charge;
    interface StdControl as PIR;
    interface StdControl as Sounder;
    interface PowerSourceStatus;
  }
  uses {
    interface MSP430I2CPacket as I2CPacket;
    interface Timer;
  }
}

implementation {

  enum {
    I2C_ADDR = 0x20,
    DATA_CONFIG_LEN = 3,
    DATA_CONFIG_0 = 0x06,
    DATA_CONFIG_1 = 0xcc,
    DATA_CONFIG_2 = 0xff,
    DATA_SET_LEN = 3,
    DATA_SET_0 = 0x02,
    DATA_SET_1 = 0x3e,
    DATA_SET_2 = 0x00,
  };

  enum {
    S_DATA_CONFIG,
    S_DATA_SET,
  };

  uint8_t data_config[3];
  uint8_t data_set[3];
  uint8_t state;

  uint8_t battery;
  uint8_t curBattery;

  command result_t StdControl.init() {
    state = S_DATA_CONFIG;
    data_config[0] = DATA_CONFIG_0;
    data_config[1] = DATA_CONFIG_1;
    data_config[2] = DATA_CONFIG_2;
    data_set[0] = DATA_SET_0;
    data_set[1] = DATA_SET_1;
    data_set[2] = DATA_SET_2;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Timer.start( TIMER_REPEAT, 4096 );
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command bool PowerSourceStatus.isOnBattery() {
    return battery;
  }

  command result_t Battery.init() { return SUCCESS; }

  command result_t Battery.start() {
    battery = TRUE;
    data_set[1] |= 0x01;
    return SUCCESS;
  }

  command result_t Battery.stop() {
    battery = FALSE;
    data_set[1] &= ~0x01;
    return SUCCESS;
  }

  command result_t Charge.init() { return SUCCESS; }
  
  command result_t Charge.start() {
    data_set[1] &= ~0x02;
    return SUCCESS;
  }

  command result_t Charge.stop() {
    data_set[1] |= 0x02;
    return SUCCESS;
  }

  command result_t PIR.init() { return SUCCESS; }
  
  command result_t PIR.start() {
    data_set[1] &= ~0x10;
    return SUCCESS;
  }

  command result_t PIR.stop() {
    data_set[1] |= 0x10;
    return SUCCESS;
  }

  command result_t Sounder.init() { return SUCCESS; }

  command result_t Sounder.start() {
    data_set[1] &= ~0x20;
    call Timer.stop();
    call Timer.start( TIMER_REPEAT, 4096 );
    state = S_DATA_SET;
    return call I2CPacket.writePacket( I2C_ADDR, DATA_SET_LEN, data_set );
  }
  
  command result_t Sounder.stop() {
    data_set[1] |= 0x20;
    call Timer.stop();
    call Timer.start( TIMER_REPEAT, 4096 );
    state = S_DATA_SET;
    return call I2CPacket.writePacket( I2C_ADDR, DATA_SET_LEN, data_set );
  }

  event result_t Timer.fired() {

    call I2CPacket.writePacket( I2C_ADDR, DATA_CONFIG_LEN, data_config );
    return SUCCESS;

  }

  event void I2CPacket.writePacketDone( uint16_t addr, uint8_t len,
					uint8_t* data, result_t success ) {

    switch( state ) {
    case S_DATA_CONFIG:
      state = S_DATA_SET;
      call I2CPacket.writePacket( I2C_ADDR, DATA_SET_LEN, data_set );
      break;
    case S_DATA_SET:
      curBattery = ( data_set[ 1 ] & 0x1 ) ? TRUE : FALSE;
      state = S_DATA_CONFIG;
      break;
    }
    
  }

  event void I2CPacket.readPacketDone( uint16_t addr, uint8_t len,
				       uint8_t* data, result_t success ) {}

}

