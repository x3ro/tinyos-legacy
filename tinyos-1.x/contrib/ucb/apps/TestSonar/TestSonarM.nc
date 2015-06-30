/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *

 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Shawn Schaffert <sms@eecs.berkeley.edu>

module TestSonarM {
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer;

    //interface BusArbitration;
    //interface StdControl as I2CControl;
    //interface MSP430I2CPacket as I2CPacket;
    //interface MSP430I2CEvents as I2CEvents;
    //interface MSP430I2C as I2C;

    interface MSP430I2CPacket as I2CPacket;
  }
}


implementation {




  //bool bus_locked;
  bool activated;
  bool read_requested;
  uint8_t sonar_begin[] = {0x00,0x51};
  uint8_t sonar_read[] = {0x02};
  uint8_t i2c_msg[2];
  uint8_t myData[34];
  enum { SONAR_ADDR = 0xE0 };




  command result_t StdControl.init() {
    //bus_locked = FALSE;
    activated = FALSE;
    read_requested = FALSE;

    call Leds.yellowOff();
    call Leds.greenOff();
    call Leds.redOff();

    //call I2CControl.init();

    return SUCCESS;
  }




  command result_t StdControl.start() {
    call Timer.start( TIMER_REPEAT, 2000 );
    return SUCCESS;
  }




  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }



  event result_t Timer.fired() {
    call Leds.yellowToggle();

    //if (( !bus_locked ) && ( call BusArbitration.getBus() == SUCCESS )) {
    //  bus_locked = TRUE;
    //  call Leds.redToggle();
    //} else if (( bus_locked ) && ( call BusArbitration.releaseBus() == SUCCESS )) {
    //  bus_locked = FALSE;
    //  call Leds.greenToggle();
    //}
    return SUCCESS;

      /*if ( call I2CControl.start() ) {
	if (( !activated ) && ( call I2CPacket.writePacket( SONAR_ADDR , 2 , sonar_begin ) )) {
	  activated = TRUE;
	  call Leds.greenOn();
	} else if (( activated ) && ( !read_requested ) && ( call I2CPacket.writePacket( SONAR_ADDR , 1 , sonar_read ) )) {
	  read_requested = TRUE;
	  call Leds.redOn();
	} else if (( activated ) && ( read_requested ) && ( call I2CPacket.readPacket( SONAR_ADDR , 17 , myData ) )) {
	  activated = FALSE;
	  read_requested = FALSE;
	} else {
	  atomic {
	    call I2CControl.stop();
	    call BusArbitration.releaseBus();
	    bus_locked = FALSE;
	  }
	}
	} */

    //}
  }




      
  //event result_t BusArbitration.busFree() {
  //  return SUCCESS;
  //}




  event void I2CPacket.readPacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success) {
    atomic {
      //call I2CControl.stop();
      //call BusArbitration.releaseBus();
      //bus_locked = FALSE;
      call Leds.redOff();
    }
  }




  event void I2CPacket.writePacketDone(uint16_t addr, uint8_t length, uint8_t* data, result_t success) {
    atomic {
      //call I2CControl.stop();
      //call BusArbitration.releaseBus();
      //bus_locked = FALSE;
      call Leds.greenOff();
    }
  }




  //async event void I2CEvents.arbitrationLost() {}
  //async event void I2CEvents.noAck() {}
  //async event void I2CEvents.ownAddr() {}
  //async event void I2CEvents.readyRegAccess() {}
  //async event void I2CEvents.readyRxData() {}
  //async event void I2CEvents.readyTxData() {}
  //async event void I2CEvents.generalCall() {}
  //async event void I2CEvents.startRecv() {}



}
