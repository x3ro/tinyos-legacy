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
 * Authors:		Mohammad Rahmim, Joe Polastre
 *
 * $Id: IntTempHumM.nc,v 1.1 2004/07/16 21:54:39 ammbot Exp $
 */

module IntTempHumM
{
  provides {
    interface StdControl;
    interface ADC as TempSensor;
    interface ADC as HumSensor;
    interface ADCError as HumError;
    interface ADCError as TempError;
  }
  uses {
    interface Leds;
    interface Timer;
    interface StdControl as TimerControl;
  }
}

implementation
{
  //states
  enum {READY=0, TEMP_MEASUREMENT=1, HUM_MEASUREMENT=2, POWER_OFF};

  char state;
  uint8_t timeout;
  uint8_t errornum;
  int16_t data;

  bool humerror,temperror;

  task void signalHumError() {
    signal HumError.error(errornum);
  }

  task void signalTempError() {
    signal TempError.error(errornum);
  }

  static inline void  ack()
  {
    INTHUMIDITY_MAKE_DATA_OUTPUT();
    INTHUMIDITY_CLEAR_DATA();
    TOSH_wait_250ns();
    INTHUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    INTHUMIDITY_CLEAR_CLOCK();
    INTHUMIDITY_MAKE_DATA_INPUT();
    INTHUMIDITY_SET_DATA();
  }

  static inline void initseq()
  { 
    HUMIDITY_MAKE_DATA_OUTPUT();
    INTHUMIDITY_SET_DATA();
    INTHUMIDITY_CLEAR_CLOCK();   
    TOSH_wait_250ns();         
    INTHUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    INTHUMIDITY_CLEAR_DATA();
    TOSH_wait_250ns();
    INTHUMIDITY_CLEAR_CLOCK();
    TOSH_wait_250ns();
    INTHUMIDITY_SET_CLOCK();
    TOSH_wait_250ns(); 
    INTHUMIDITY_SET_DATA();
    TOSH_wait_250ns(); 
    INTHUMIDITY_CLEAR_CLOCK();
  }

  static inline void reset()
  {
    int i;
    INTHUMIDITY_MAKE_DATA_OUTPUT();
    INTHUMIDITY_SET_DATA();
    INTHUMIDITY_CLEAR_CLOCK();
    for (i=0;i<9;i++) {
      INTHUMIDITY_SET_CLOCK();
      TOSH_wait_250ns();
      INTHUMIDITY_CLEAR_CLOCK();
    }
  }

  static inline char processCommand(int cmd)
  {
    int i;
    int CMD = cmd;
    cmd &= 0x1f;
    INTHUMIDITY_INT_DISABLE();
    reset();           
    initseq();        //sending the init sequence
    for(i=0;i<8;i++){
      if(cmd & 0x80) INTHUMIDITY_SET_DATA();
      else INTHUMIDITY_CLEAR_DATA();
      cmd = cmd << 1 ;
      INTHUMIDITY_SET_CLOCK();
      TOSH_wait_250ns();              
      TOSH_wait_250ns();              
      INTHUMIDITY_CLEAR_CLOCK();        
    }
    INTHUMIDITY_MAKE_DATA_INPUT();
    INTHUMIDITY_SET_DATA();
    TOSH_wait_250ns();
    INTHUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    if(INTHUMIDITY_GET_DATA()) 
    { 
      reset(); 
      errornum = 2;
      if ((CMD == TOSH_INTHUMIDITY_ADDR) && (humerror == TRUE))
        post signalHumError();
      else if ((CMD == TOSH_INTHUMIDTEMP_ADDR) && (temperror == TRUE))
        post signalTempError();
      return 0; 
    }
    TOSH_wait_250ns();
    INTHUMIDITY_CLEAR_CLOCK();
    if((CMD == TOSH_INTHUMIDITY_ADDR) || (CMD == TOSH_INTHUMIDTEMP_ADDR) ){
      if ((CMD == TOSH_INTHUMIDITY_ADDR) && (humerror == TRUE)) {
        timeout = 0;
	call Timer.start(TIMER_REPEAT, HUMIDITY_TIMEOUT_MS);
      }
      else if ((CMD == TOSH_INTHUMIDTEMP_ADDR) && (temperror == TRUE)) {
        timeout = 0;
	call Timer.start(TIMER_REPEAT, HUMIDITY_TIMEOUT_MS);
      }
      INTHUMIDITY_INT_ENABLE();
    }
    return 1;
  }

  command result_t StdControl.init() {
    humerror = FALSE;
    temperror = FALSE;
    state = POWER_OFF;
    return call TimerControl.init();
  }

  command result_t StdControl.start() {
    state=READY;
    INTHUMIDITY_CLEAR_CLOCK();
    INTHUMIDITY_MAKE_CLOCK_OUTPUT();
    INTHUMIDITY_SET_DATA();
    INTHUMIDITY_MAKE_DATA_INPUT();
    INTHUMIDITY_INT_DISABLE();
    reset();
    processCommand(TOSH_INTHUMIDITY_RESET);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    state = POWER_OFF;
    INTHUMIDITY_CLEAR_CLOCK();
    INTHUMIDITY_MAKE_CLOCK_INPUT();
    INTHUMIDITY_MAKE_DATA_INPUT();
    INTHUMIDITY_CLEAR_DATA();
    return SUCCESS;
  }

  default async event result_t TempSensor.dataReady(uint16_t tempData) 
  {
    return SUCCESS;
  }

  default async event result_t HumSensor.dataReady(uint16_t humData) 
  {
    return SUCCESS;
  }

  task void readSensor()
  {
    char i;
    char CRC=0;  
    data=0; 

    call Timer.stop();

    for(i=0;i<8;i++){
      INTHUMIDITY_SET_CLOCK();   
      TOSH_wait_250ns();
      data |= INTHUMIDITY_GET_DATA();
      data = data << 1;
      INTHUMIDITY_CLEAR_CLOCK();
    }
    ack();
    for(i=0;i<8;i++){
      INTHUMIDITY_SET_CLOCK();   
      TOSH_wait_250ns();
      data |= INTHUMIDITY_GET_DATA();
      //the last byte of data should not be shifted
      if(i!=7) data = data << 1;  
      INTHUMIDITY_CLEAR_CLOCK();
    }
    ack();
    for(i=0;i<8;i++){
      INTHUMIDITY_SET_CLOCK();   
      TOSH_wait_250ns();
      CRC |= INTHUMIDITY_GET_DATA();
      if(i!=7)CRC = CRC << 1;
      INTHUMIDITY_CLEAR_CLOCK();
    }
    // nack with high as it should be for the CRC ack
    INTHUMIDITY_MAKE_DATA_OUTPUT();
    INTHUMIDITY_SET_DATA();          
    TOSH_wait_250ns();
    INTHUMIDITY_SET_CLOCK();
    TOSH_wait_250ns();
    INTHUMIDITY_CLEAR_CLOCK();

    // some code that calculated crcs used to be here but
    // it was commented out and some related dead code was
    // causing a 256 byte crctable to be linked in.

    if(state==TEMP_MEASUREMENT) {
      signal TempSensor.dataReady(data);
    } else if(state==HUM_MEASUREMENT) {
      signal HumSensor.dataReady(data);
    }
    state=READY;
  }

#ifndef PLATFORM_PC
  TOSH_SIGNAL(INTHUMIDITY_INTERRUPT)
  {
    INTHUMIDITY_INT_DISABLE();
    post readSensor();
    return;
  }
#endif

  // no such thing
  async command result_t TempSensor.getContinuousData() {
    return FAIL;
  }

  // no such thing
  async command result_t HumSensor.getContinuousData() {
    return FAIL;
  }

  async command result_t TempSensor.getData()
  {
    if(state!= READY ){
      reset();
    }
    state=TEMP_MEASUREMENT;
    processCommand(TOSH_INTHUMIDTEMP_ADDR);
    return SUCCESS;
  }

  async command result_t HumSensor.getData()
  {
    if(state!= READY ){
      reset();
    }
    state=HUM_MEASUREMENT;
    processCommand(TOSH_INTHUMIDITY_ADDR);
    return SUCCESS;
  }

  command result_t HumError.enable() {
    if (humerror == FALSE) {
      atomic humerror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.enable() {
    if (temperror == FALSE) {
      atomic temperror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t HumError.disable() {
    if (humerror == TRUE) {
      atomic humerror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.disable() {
    if (temperror == TRUE) {
      atomic temperror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t Timer.fired() {
    timeout++;
    if (timeout > HUMIDITY_TIMEOUT_TRIES) {
      if ((state == HUM_MEASUREMENT) && (humerror == TRUE)) {
        call Timer.stop();
        INTHUMIDITY_INT_DISABLE();
        state = READY;
        errornum = 1;
        post signalHumError();
      }
      else if ((state == TEMP_MEASUREMENT) && (temperror == TRUE)) {
        call Timer.stop();
        INTHUMIDITY_INT_DISABLE();
        state = READY;
        errornum = 1;
        post signalTempError();
      }
    }
    return SUCCESS;
  }

  default event result_t HumError.error(uint8_t token) { return SUCCESS; }

  default event result_t TempError.error(uint8_t token) { return SUCCESS; }

}
