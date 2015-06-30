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
 * $Id: TaosPhotoM.nc,v 1.1.1.1 2007/11/05 19:10:41 jpolastre Exp $
 */

includes sensorboard;
module TaosPhotoM {
  provides {
    interface ADC[uint8_t id];
    interface ADCError[uint8_t id];
    interface SplitControl;
  }
  uses {
    interface StdControl as I2CPacketControl;
    interface StdControl as TimerControl;
    interface StdControl as BusControl;
    interface Timer;
    interface I2CPacket;
    interface Leds;
    interface BusArbitration;
  }
}
implementation {

  enum {POWER_OFF=0, IDLE, WARM_UP, BUSY, BUSY_0, BUSY_1, GET_SAMPLE_0, GET_SAMPLE_1, BUSY_0_BUS, BUSY_1_BUS, WARM_UP_BUS};


  char state;
  char tempvalue;

  uint8_t counter;

  bool error0,error1;

  task void initDone() {
    signal SplitControl.initDone();
  }

  task void startDone() {
    signal SplitControl.startDone();
  }

  task void stopDone() {
    signal SplitControl.stopDone();
  }

  command result_t SplitControl.init() {
    state = POWER_OFF;
    error0 = error1 = FALSE;
    counter = 0;
    call I2CPacketControl.init();
    call TimerControl.init();
    post initDone();
    return SUCCESS;
  }

  command result_t SplitControl.start() {
	state = WARM_UP;
	TAOS_POWER_ON();
        call BusControl.start();	
	tempvalue = 0x03;
        if (call BusArbitration.getBus()) {
          call I2CPacketControl.start();
	  TOSH_uwait(3);
          call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
        }
        else {
          state = WARM_UP_BUS;
        }
	return SUCCESS;
  }

  command result_t SplitControl.stop() {
        state = POWER_OFF;
        TAOS_POWER_OFF();
        call I2CPacketControl.stop();
        post stopDone();
	return SUCCESS;
  }

  event result_t BusArbitration.busFree() {
    if (state == WARM_UP_BUS) {
        if (call BusArbitration.getBus()) {
          state = WARM_UP;
          call I2CPacketControl.start();
	  TOSH_uwait(3);
          call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
        }
    }
    else if (state == BUSY_0_BUS) {
      if (call BusArbitration.getBus()) {
        state = BUSY_0;
        call I2CPacketControl.start();
        return call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
      }
    }
    else if (state == BUSY_1_BUS) {
      if (call BusArbitration.getBus()) {
        state = BUSY_1;
        call I2CPacketControl.start();
        return call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
      }
    }
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
        if (call BusArbitration.getBus()) {
          call I2CPacketControl.start();
          return call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
        }
        else {
          state = BUSY_0_BUS;
        }
      }
      else if (id == 1)
      {
	tempvalue = 0x83;
	state = BUSY_1;
        if (call BusArbitration.getBus()) {
          call I2CPacketControl.start();
          return call I2CPacket.writePacket(1,(char*)&tempvalue,0x01);
        }
        else {
          state = BUSY_1_BUS;
        }
      }
    }
    //state = IDLE;
    return FAIL;
  }

  event result_t I2CPacket.writePacketDone(bool result) {
    if (state == WARM_UP) {
        call I2CPacketControl.stop();
        call BusArbitration.releaseBus();
	return call Timer.start(TIMER_ONE_SHOT, 900);
    }
    if ((state == BUSY_0) || (state == BUSY_1))
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
    return SUCCESS;
  }

  event result_t Timer.fired() {
    if (state == WARM_UP) {
      state = IDLE;
      post startDone();
    }
    else if (state == GET_SAMPLE_0) {
      state = IDLE;
      call ADC.getData[0]();
    }
    else if (state == GET_SAMPLE_1) {
      state = IDLE;
      call ADC.getData[1]();
    }
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char length, short* data) {
    if (state == GET_SAMPLE_0) {
      call I2CPacketControl.stop();
      call BusArbitration.releaseBus();
      if (((data[0] & 0x0FF) == 0) || ((data[0] & 0xFF00) == 0)) 
        if (error0) {
          counter++;
          if (counter > TAOS_TIMEOUT_TRIES) {
            counter = 0;
            state = IDLE;
            // tell the app there was an error
            signal ADCError.error[0](1);
            // then signal the app with the data we have which may be wrong
            return signal ADC.dataReady[0](data[0]);
          }
          else
            call Timer.start(TIMER_ONE_SHOT, TAOS_TIMEOUT_MS);
          return SUCCESS;
        }          
      counter = 0;
      state = IDLE;
      signal ADC.dataReady[0](data[0]);
    }
    else if (state == GET_SAMPLE_1) {
      call I2CPacketControl.stop();
      call BusArbitration.releaseBus();
      if (((data[0] & 0xFF) == 0) || ((data[0] & 0xFF00) == 0)) 
        if (error1) {
          counter++;
          if (counter > TAOS_TIMEOUT_TRIES) {
            counter = 0;
            state = IDLE;            
            // tell the app there was an error
            signal ADCError.error[1](1);
            // then signal the app with the data we have which may be wrong
            return signal ADC.dataReady[1](data[0]);
          }
          else
            call Timer.start(TIMER_ONE_SHOT, TAOS_TIMEOUT_MS);
          return SUCCESS;
        }          
      counter = 0;
      state = IDLE;
      signal ADC.dataReady[1](data[0]);
    }
    return SUCCESS;
  }

  command result_t ADCError.enable[uint8_t id]() {
    if ((id == 0) && (error0 == FALSE)) {
      error0 = TRUE;
      return SUCCESS;
    }
    else if ((id == 1) && (error1 == FALSE)) {
      error1 = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t ADCError.disable[uint8_t id]() {
    if ((id == 0) && (error0 == TRUE)) {
      error0 = FALSE;
      return SUCCESS;
    }
    else if ((id == 1) && (error1 == TRUE)) {
      error1 = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  default event result_t ADCError.error[uint8_t id](uint8_t token) {
    return SUCCESS;
  }

  async default event result_t ADC.dataReady[uint8_t id](uint16_t data)
  {
    return SUCCESS;
  }

}

