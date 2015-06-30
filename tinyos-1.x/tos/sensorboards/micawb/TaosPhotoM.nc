/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: TaosPhotoM.nc,v 1.8 2003/12/13 01:50:57 whong Exp $
 */

includes sensorboard;
module TaosPhotoM {
  provides {
    interface ADC[uint8_t id];
    interface StdControl;
  }
  uses {
    interface StdControl as SwitchControl;
    interface StdControl as I2CPacketControl;
    interface Switch;
    interface Timer;
    interface I2CPacket;
  }
}
implementation {

  enum {IDLE, BUSY, BUSY_0, BUSY_1, GET_SAMPLE_0, GET_SAMPLE_1,
        MAIN_SWITCH, WAIT_SWITCH};

  char state;
  char tempvalue;
  bool power;

  command result_t StdControl.init() {
    state = IDLE;
    power = FALSE;
    call I2CPacketControl.init();
    return call SwitchControl.init();
  }

  command result_t StdControl.start() {
    state = MAIN_SWITCH;
    // turn the sensor on
    call I2CPacketControl.start();
    call SwitchControl.start();
    if (call Switch.set(MICAWB_LIGHT_POWER,1) != SUCCESS) {
      state = WAIT_SWITCH;
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    power = FALSE;
    // turn the sensor off
    return call Switch.set(MICAWB_LIGHT_POWER,0);
  }

  event result_t Switch.getDone(char value) {
    return SUCCESS;
  }

  event result_t Switch.setDone(bool result) {
    if (state == MAIN_SWITCH) {
      state = IDLE;
    }
    else if (state == WAIT_SWITCH) {
      if (call Switch.set(MICAWB_LIGHT_POWER,1) != SUCCESS) {
	state = WAIT_SWITCH;
      }
      else {
	state = MAIN_SWITCH;
      }
    }
    return SUCCESS;
  }

  event result_t Switch.setAllDone(bool result) {
    return SUCCESS;
  }

  // no such thing
  async command result_t ADC.getContinuousData[uint8_t id]() {
    return FAIL;
  }

  async command result_t ADC.getData[uint8_t id]() {
    if (state == IDLE)
    {
      state = BUSY;
      if (id == 0)
      {
	tempvalue = 0x43;
	state = BUSY_0;
	return call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
      }
      else if (id == 1)
      {
	tempvalue = 0x83;
	state = BUSY_1;
	return call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
      }
    }
    state = IDLE;
    return FAIL;
  }

  event result_t I2CPacket.writePacketDone(bool result) {
    if ((state == BUSY_0) || (state == BUSY_1))
    {
      // if this is the first time after power is turned on
      // sensor must wait 800ms for first conversion
      if (power == FALSE) {
	power = TRUE;
	return call Timer.start(TIMER_ONE_SHOT, 850);
      }
      // if the power is already on, we don't need to wait for
      // the first conversion to occur
      else
      {
	if (state == BUSY_0) {
	  state = GET_SAMPLE_0;
	  return call I2CPacket.readPacket(1,0x01);
	}
	else if (state == BUSY_1)
	{
	  state = GET_SAMPLE_1;
	  return call I2CPacket.readPacket(1,0x01);
	}
      }
    }
    return SUCCESS;
  }

  event result_t Timer.fired() {
    // sensor is now warmed up, go get samples
    if (state == BUSY_0)
    {
      state = GET_SAMPLE_0;
      return call I2CPacket.readPacket(1,0x01);
    }
    else if (state == BUSY_1)
    {
      state = GET_SAMPLE_1;
      return call I2CPacket.readPacket(1,0x01);
    }
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char length, char* data) {
    if (state == GET_SAMPLE_0) {
      state = IDLE;
      //      if ((data[0] >> 7) == 1)
	// conversion is successful
	signal ADC.dataReady[0](data[0]);
	//      else
	//	signal ADC.dataReady[0](0x00);
    }
    else if (state == GET_SAMPLE_1) {
      state = IDLE;
      //      if ((data[0] >> 7) == 1)
	// conversion is successful
	signal ADC.dataReady[1](data[0]);
	//      else
	//	signal ADC.dataReady[1](0x00);
    }
    return SUCCESS;
  }

  default async event result_t ADC.dataReady[uint8_t id](uint16_t data)
  {
    return SUCCESS;
  }

}

