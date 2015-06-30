/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2004 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * History:   Jun 21, 2004         Inception.
 *
 * This component exports the magnetometer sensor as provided by the
 * mica sensor board (micasb). If there is contention for the sensor,
 * it maintains two FIFO request queues (X and Y) and alternates between
 * them.
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


includes Mate;

module MateTHumidityM {
  
  provides {
    interface StdControl;
    interface MateBytecode as Humidity;
    interface MateBytecode as Temperature; 
  }
  
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
    interface MateQueue as Queue;
    interface MateError as Error;
    interface MateContextSynch as Synch;
    interface SplitControl as SensorControl;
    interface MateEngineStatus as EngineStatus;
    interface Leds;
    
    interface ADC as HumADC;
    interface ADC as TempADC;
    interface ADCError as HumError;
    interface ADCError as TempError;
  }
}

implementation {

  enum {
    STATE_UNINIT   =   0,
    STATE_INIT     =   1,
    STATE_OFF      =   2,
    STATE_STARTING =   3,
    STATE_HUM      =   4,
    STATE_TEMP     =   5,
    STATE_STOPPING =   6,
    STATE_BITMASK  = 0x7,
    STATE_BITS     =   3,
  } THumidityState;

  enum {
    STATUS_IDLE          = 0,
    STATUS_START_PENDING = 1 << STATE_BITS,
    STATUS_STOP_PENDING  = 2 << STATE_BITS,
  } THumidityStateStatus;
  
  MateQueue senseHumidityWaitQueue;
  MateQueue senseTemperatureWaitQueue;
  MateContext* sensingContext;

  uint8_t thState = STATE_UNINIT | STATUS_IDLE;
  uint16_t reading;

  uint8_t getState() {
    uint8_t rval;
    atomic {
      rval = thState & STATE_BITMASK;
    }
    return rval;
  }
  uint8_t getStatus() {
    uint8_t rval;
    atomic {
      rval = thState & ~STATE_BITMASK;
    }
    return rval;
  }
  
  void setState(uint8_t newState) {
    atomic {thState = getStatus() | newState;}
  }
  void setStatus(uint8_t newStatus) {
    atomic {thState = getState() | newStatus;}
  }

  void startSensor();
  void stopSensor();
  void serviceSensors();
  
  command result_t StdControl.init() {
    call Queue.init(&senseHumidityWaitQueue);
    call Queue.init(&senseTemperatureWaitQueue);
    atomic {
      sensingContext = NULL;
    }
    if (getState() == STATE_UNINIT) {
      setState(STATE_INIT);
      call HumError.enable();
      call TempError.enable();
      return call SensorControl.init();
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t SensorControl.initDone() {
    dbg(DBG_USR1, "VM: Humidity sensor intialization complete.\n");
    setStatus(STATUS_IDLE);
    setState(STATE_OFF);
    return SUCCESS;
  }

  event result_t SensorControl.startDone() {
    dbg(DBG_USR1, "VM: Humidity sensor started... ");
    if (getStatus() == STATUS_STOP_PENDING) {
      dbg_clear(DBG_USR1, "stop pending, stop sensor.\n");
      stopSensor();
    }
    else {
      dbg_clear(DBG_USR1, "servicing sensors.\n");
      serviceSensors();
    }
    setStatus(STATUS_IDLE);
    call Leds.yellowOn();
    return SUCCESS;
  }

  event result_t SensorControl.stopDone() {
    setState(STATE_OFF);
    if (getStatus() == STATUS_START_PENDING) {
      startSensor();
    }
    setStatus(STATUS_IDLE);
    call Leds.yellowOff();
    return SUCCESS;
  }
  
  void startSensor() {
    uint8_t state = getState();
    call Leds.redToggle();
    if (state == STATE_OFF) {
      call SensorControl.start();
      setState(STATE_STARTING);
    }
    else if (state == STATE_STOPPING) {
      setStatus(STATUS_START_PENDING);
    }
  }
  
  void stopSensor() {
    uint8_t state = getState();
    if (state == STATE_OFF) {
      return;
    }
    else if (state == STATE_STARTING) {
      setStatus(STATUS_STOP_PENDING);
    }
    else {
      call SensorControl.stop();
      setState(STATE_STOPPING);
    }
  }

  inline result_t execSenseHumidity(MateContext* context) {
    bool yield = FALSE;
    dbg(DBG_USR1, "VM (%i): Sensing Humidity.\n", (int)context->which);

    atomic {
      if (call HumADC.getData() == SUCCESS) {
	sensingContext = context;
	context->state = MATE_STATE_BLOCKED;
	setState(STATE_HUM);
	yield = TRUE;
	call Leds.greenOn();
      }
    }
    if (yield) {
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else { // re-issue the instruction
      call Error.error(context, MATE_ERROR_INVALID_SENSOR);
      dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
      context->pc--;
      return FAIL;
    }
  }
  
  inline result_t execSenseTemperature(MateContext* context) {
    bool yield = FALSE;
    dbg(DBG_USR1, "VM (%i): Sensing Temperature.\n", (int)context->which);

    atomic {
      if (call TempADC.getData() == SUCCESS) {
	sensingContext = context;
	context->state = MATE_STATE_BLOCKED;
	setState(STATE_TEMP);
	yield = TRUE;
      }
    }
    if (yield) {
      call Synch.yieldContext(context);
      return SUCCESS;
    }
    else { // re-issue the instruction
      call Error.error(context, MATE_ERROR_INVALID_SENSOR);
      dbg(DBG_ERROR, "VM (%i): Sensor busy, reissue.\n", (int)context->which);
      context->pc--;
      return FAIL;
    }
  }
  
  task void senseHumidityDoneTask();
  task void senseTemperatureDoneTask();

  command result_t Humidity.execute(uint8_t instr,
				    MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Executing humidity function, starting sensor, queuing request.\n", (int)context->which);
    startSensor();
    call Queue.enqueue(context, &senseHumidityWaitQueue, context);
    context->state = MATE_STATE_WAITING;
    call Synch.yieldContext(context);
    return SUCCESS;
  }
  
  command result_t Temperature.execute(uint8_t instr,
				       MateContext* context) {
    dbg(DBG_USR1, "VM (%i): Executing temperature function, starting sensor, queuing request.\n", (int)context->which);
    startSensor();
    call Queue.enqueue(context, &senseTemperatureWaitQueue, context);
    context->state = MATE_STATE_WAITING;
    call Synch.yieldContext(context);
    return SUCCESS;
  }

  command uint8_t Humidity.byteLength() {return 1;}
  command uint8_t Temperature.byteLength() {return 1;}

  async event result_t HumADC.dataReady(uint16_t datum) {
    bool isMine;
    call Leds.greenOff();
    atomic {
      isMine = (getState() == STATE_HUM);
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post senseHumidityDoneTask();
    }
    return SUCCESS;
  }

  async event result_t TempADC.dataReady(uint16_t datum) {
    bool isMine;
    atomic {
      isMine = (getState() == STATE_TEMP);
    }
    if (isMine) {
      atomic {
	reading = datum;
      }
      post senseTemperatureDoneTask();
    }
    return SUCCESS;
  }

  void serviceSensors() {
    // prefer humidity, for no reason -- the event handlers will alternate
    // calls after the first one
    if (!call Queue.empty(&senseHumidityWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseHumidityWaitQueue);
      execSenseHumidity(senser);
    }
    else if (!call Queue.empty(&senseTemperatureWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseTemperatureWaitQueue);
      execSenseTemperature(senser);
    }
    else {
      stopSensor();
    }
  }
  
  task void senseHumidityDoneTask() {
    uint16_t datum;

    if (getState() != STATE_HUM) {
      return;
    }
    atomic {
      datum = reading;
    }

    dbg(DBG_USR1, "VM: Humidity reading: %i\n", (int)datum);

    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: MateHamamatsuM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_THUM, datum);
      sensingContext = NULL;
    }
    // Here is the queue alternation: after an Humidity reading, schedule
    // a Temperature reading first
    if (!call Queue.empty(&senseTemperatureWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseTemperatureWaitQueue);
      execSenseTemperature(senser);
    }
    else if (!call Queue.empty(&senseHumidityWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseHumidityWaitQueue);
      execSenseHumidity(senser);
    }
    else {
      stopSensor();
    }
    return;
  }
  
  task void senseTemperatureDoneTask() {
    uint16_t datum;
    if (getState() != STATE_TEMP) {
      return;
    }
    atomic {
      datum = reading;
    }
    dbg(DBG_USR1, "VM: Temperature reading: %i\n", (int)datum);

    if (sensingContext == NULL) {
      dbg(DBG_USR1, "VM: MateTemperatureM: received sensor reading, but no sending context: VM rebooted?\n");
      return;
    }
    else {
      // Resume the sensing context
      call Synch.resumeContext(sensingContext, sensingContext);
      call Stacks.pushReading(sensingContext, MATE_TYPE_TTEMP, datum);
      sensingContext = NULL;
    }

    // Here is the queue alternation: after an Temperature reading, schedule
    // an Humidity reading first
    if (!call Queue.empty(&senseHumidityWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseHumidityWaitQueue);
      execSenseHumidity(senser);
    }
    else if (!call Queue.empty(&senseTemperatureWaitQueue)) {
      MateContext* senser = call Queue.dequeue(NULL, &senseTemperatureWaitQueue);
      execSenseTemperature(senser);
    }
    else {
      stopSensor();
    }
    return;
  }

  event result_t HumError.error(uint8_t token) {
    if (getState() == STATE_HUM) {
      call Error.error(sensingContext, MATE_ERROR_SENSOR_FAIL);
    }
    return SUCCESS;
  }

  event result_t TempError.error(uint8_t token) {
    if (getState() == STATE_TEMP) {
      call Error.error(sensingContext, MATE_ERROR_SENSOR_FAIL);
    }
    return SUCCESS;
  }
  
  event void EngineStatus.rebooted() {
    sensingContext = NULL;
    call Queue.init(&senseHumidityWaitQueue);
    call Queue.init(&senseTemperatureWaitQueue);
    if (getState() > STATE_OFF &&
	getState() != STATE_STOPPING) {
      stopSensor();
    }
    setStatus(STATUS_IDLE);
  }
}
