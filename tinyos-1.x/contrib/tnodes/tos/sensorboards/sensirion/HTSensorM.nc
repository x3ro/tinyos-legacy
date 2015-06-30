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
 * $Id: HTSensorM.nc,v 1.1 2006/03/06 10:07:40 palfrey Exp $
 */

// #define error_code(code) { call Leds.set(code); for(;;); }

module HTSensorM {
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
    interface PowerManagement;
    // interface StdControl as TimerControl;
  }

}
implementation {


  //sensirionStates
  enum { INIT, READY, TEMP_MEASUREMENT, HUM_MEASUREMENT } sensirionState = INIT;

  uint8_t errornum;

  bool humerror,temperror;

  static inline void delay() {
    TOSH_wait_250ns();
    TOSH_wait_250ns();
    TOSH_wait_250ns();
    TOSH_wait_250ns();
    // asm volatile  ("nop" ::);
  }

  static inline void set_sda_low() {
    HTSENS_MAKE_DATA_OUTPUT();
    HTSENS_CLEAR_DATA();
  }

  static inline void set_sda_high() {
    HTSENS_MAKE_DATA_INPUT();
    HTSENS_SET_DATA();
  }

  static inline void set_sck_low() {
    HTSENS_CLEAR_CLOCK();
  }

  static inline void set_sck_high() {
    HTSENS_SET_CLOCK();
  }

  static inline int get_sda() {
    int sda;

    delay();

    set_sck_high();
    sda = HTSENS_GET_DATA();
#ifdef PLATFORM_PC
    sda = 0;
#endif
    delay();

    set_sck_low();
    delay();

    return sda;
  }

  static inline void clock_sda(bool sda) {
    if (sda) {
      set_sda_high();
    }
    else {
      set_sda_low();
    }
    
    delay();
    set_sck_high();
    delay();
    set_sck_low();
    set_sda_high();
    delay();
  }
    
  static inline void acknowledge() {
    dbg(DBG_USR1, "acknowledge()\n");

    clock_sda(FALSE);
  }

  static inline void start_transmission() { 
    dbg(DBG_USR1, "start_transmission()\n");

    set_sck_high(); delay();
    set_sda_low();  delay();
    set_sck_low();  delay();
    set_sck_high(); delay();
    set_sda_high(); delay();
    set_sck_low();  delay();
  }

  static inline result_t send_address(int addr) {
    int i;

    dbg(DBG_USR1, "send_address(%d)\n", addr);

    // send start of transmission sequence
    start_transmission();

    // send 8 bytes
    for (i=0x80; i>0; i>>=1) {
      clock_sda(i & addr);
    }

    // check acknowledgement
    return get_sda() == 0 ? SUCCESS : FAIL;
  }

  static inline uint8_t receive_data(bool ack) {
    int i;
    uint8_t byte = 0;

    // read 8 bits to form a byte
    for (i=0; i<8; i++) {
      byte <<= 1;
      byte |= get_sda() & 0x01;
    }

    // if necessary acknowledge
    clock_sda(!ack);

    return byte;
  }

  static inline result_t soft_reset() {

    dbg(DBG_USR1, "soft_reset()\n");

    // stop the timer if it's running
    call Timer.stop();

    // reset the sensirionState
    atomic sensirionState = READY;

    // send the reset command
    return send_address(TOSH_HTSENS_RESET_ADDR);
  }

  static inline result_t hard_reset() {
    int i;

    dbg(DBG_USR1, "hard_reset()\n");

    // at least 9 clock pulses with sda high
    for (i=0; i<10; i++) clock_sda(TRUE);

    // perform a soft reset
    return soft_reset();
  }

task void timerStart() {
	call Timer.start(TIMER_ONE_SHOT, HTSENS_TIMEOUT_MS);
}
  
  static inline result_t process_command(int cmd) {

    dbg(DBG_USR1, "process_command()\n");

    if ( send_address(cmd & 0x1f) == FAIL ) {
      // error_code(1);
      dbg(DBG_USR1, "process_command() FAILED\n");
      return FAIL;
    }

    // enable interrupt
    HTSENS_INT_ENABLE();
    call PowerManagement.adjustPower();

    // start timeout timer with task; should be no problem
    // worst case: timeout takes longer
    post timerStart();
    return SUCCESS;
  }

  command result_t StdControl.init() {
    humerror = FALSE;
    temperror = FALSE;
    atomic sensirionState = INIT;
    errornum = 0;

    // disable interrupt
    HTSENS_INT_DISABLE();
    call PowerManagement.adjustPower();
    // call Leds.init();
    
    HTSENS_MAKE_CLOCK_OUTPUT();
    set_sda_high();
    set_sck_low();

    return hard_reset();
  }

  command result_t StdControl.start() {
    atomic sensirionState = READY;

    // call TempSensor.getData();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return hard_reset();
  }

  
  task void read_sensor() {
	  int tempsensirionState;
    uint16_t data = 0;
    char crc = 0;

    // disable timer
    call Timer.stop();

    // receive 3 bytes with acknowledgements except for crc
    data |= receive_data(TRUE) << 8;
    data |= receive_data(TRUE);
    crc = receive_data(FALSE);

    // signal data ready
    atomic tempsensirionState = sensirionState;
    switch(tempsensirionState) {
    case TEMP_MEASUREMENT: signal TempSensor.dataReady(data); break;
    case HUM_MEASUREMENT:  signal HumSensor.dataReady(data);  break;
    default: // do nothing
    }
    
    atomic sensirionState = READY;
  }

#ifndef PLATFORM_PC
  TOSH_SIGNAL(HTSENS_INTERRUPT)
  {
    // disable interrupt
    HTSENS_INT_DISABLE();
    call PowerManagement.adjustPower();

    // post task
    post read_sensor();

    return;
  }
#endif

  async command result_t TempSensor.getData() {
	  int tempsensirionState;
    dbg(DBG_USR1, "TempSensor.getData()\n");

    // failure if sensor not ready
    atomic tempsensirionState = sensirionState;
    if ( tempsensirionState != READY ) {
      return FAIL;
    }
        
    atomic sensirionState = TEMP_MEASUREMENT;

    return process_command(TOSH_HTSENS_TEMPERATURE_ADDR);
  }

  async command result_t HumSensor.getData() {
	  int tempsensirionState;
    
    // failure if sensor not ready
    atomic tempsensirionState = sensirionState;
    if( tempsensirionState != READY ){
      return FAIL;
    }

    atomic sensirionState = HUM_MEASUREMENT;

    return process_command(TOSH_HTSENS_HUMIDITY_ADDR);
  }

  command result_t HumError.enable() {
    if (humerror == FALSE) {
      humerror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.enable() {
    if (temperror == FALSE) {
      temperror = TRUE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t HumError.disable() {
    if (humerror == TRUE) {
      humerror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TempError.disable() {
    if (temperror == TRUE) {
      temperror = FALSE;
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t Timer.fired() {
	  int tempsensirionState;

	  // disable interrupt
	  HTSENS_INT_DISABLE();
	  call PowerManagement.adjustPower();

	  // signal error
	  atomic tempsensirionState = sensirionState;
	  switch(tempsensirionState) {
		  case TEMP_MEASUREMENT: temperror && signal TempError.error(++errornum); break;
		  case HUM_MEASUREMENT:  humerror && signal HumError.error(++errornum); break;
		  default: // do nothing
	  }

	  // something went wrong, so reset communication
	  hard_reset();

	  atomic sensirionState = READY;

	  // error_code(2);

	  return SUCCESS;
  }

  // no such thing
  async command result_t TempSensor.getContinuousData() { return FAIL; }
  async command result_t HumSensor.getContinuousData() { return FAIL; }

  // default actions
  default async event result_t TempSensor.dataReady(uint16_t tempData) { return SUCCESS; }
  default async event result_t HumSensor.dataReady(uint16_t humData) { return SUCCESS; }
  default event result_t HumError.error(uint8_t token) { return SUCCESS; }
  default event result_t TempError.error(uint8_t token) { return SUCCESS; }

}
