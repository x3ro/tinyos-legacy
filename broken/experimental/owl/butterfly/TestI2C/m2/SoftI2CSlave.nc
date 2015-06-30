// $Id: SoftI2CSlave.nc,v 1.1 2003/10/23 19:00:49 uid70149 Exp $

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

/* This code is a hack, for debugging purposes. Consider it broken, buggy, etc.
 */

module SoftI2CSlave
{
  provides {
    interface StdControl;
    interface I2CSlave;
  }
  uses interface Leds;
}
implementation
{
  // global variables
  uint8_t state;           	// maintain the state of the current process
  uint8_t local_data;		// data to be read/written
  uint8_t count;
  uint8_t address;
  bool stop_possible, start_possible;

  // define constants for state
  enum {READ_DATA=1, WRITE_DATA, SEND_START, SEND_END};

  enum { S_IDLE, S_ADDRESS, S_WRITE_ACK, S_READ_ACK, S_WRITE_BYTE, S_READ_BYTE };

  // wait when triggering the clock
  void wait() {
    TOSH_uwait(20);
    //asm volatile  ("nop" ::);
  }

  // hardware pin functions
  void SET_CLOCK() { TOSH_SET_I2C_BUS1_SCL_PIN(); }
  void CLEAR_CLOCK() { TOSH_CLR_I2C_BUS1_SCL_PIN(); }
  void MAKE_CLOCK_OUTPUT() { TOSH_MAKE_I2C_BUS1_SCL_OUTPUT(); }
  void MAKE_CLOCK_INPUT() { TOSH_MAKE_I2C_BUS1_SCL_INPUT(); }
  int GET_CLOCK() { return TOSH_READ_I2C_BUS1_SCL_PIN(); }

  void SET_DATA() { TOSH_SET_I2C_BUS1_SDA_PIN(); }
  void CLEAR_DATA() { TOSH_CLR_I2C_BUS1_SDA_PIN(); }
  void MAKE_DATA_OUTPUT() { TOSH_MAKE_I2C_BUS1_SDA_OUTPUT(); }
  void MAKE_DATA_INPUT() { TOSH_MAKE_I2C_BUS1_SDA_INPUT(); }
  int GET_DATA() { return TOSH_READ_I2C_BUS1_SDA_PIN(); }

  // sda = pd1 = int1, scl = pd0 = int0

  void enable_start_intr() {
    // falling edge on sda
    MAKE_DATA_INPUT();
    EICRA |= 0x8;
    sbi(EIFR, 1);
    sbi(EIMSK, 1);
  }

  void enable_stop_intr() {
    // rising edge on sda
    MAKE_DATA_INPUT();
    EICRA |= 0xa;
    sbi(EIFR, 1);
    sbi(EIMSK, 1);
  }

  void disable_data_intr() {
    cbi(EIMSK, 1);
  }

  void enable_clock_intr() {
    // rising edge on scl
    MAKE_CLOCK_INPUT();
    EICRA |= 0x3;
    sbi(EIFR, 0);
    sbi(EIMSK, 0);
  }

  void disable_clock_intr() {
    cbi(EIMSK, 0);
  }

  void wait_for_start() {
    state = S_IDLE;
    start_possible = TRUE;
    disable_clock_intr();
    enable_start_intr();
  }

  void check_for_start() {
    start_possible = TRUE;
    enable_start_intr();
  }

  void check_for_stop() {
    stop_possible = TRUE;
    enable_stop_intr();
  }

  void write_bit(uint8_t bit) {
    if (!bit)
      {
	CLEAR_DATA();
	MAKE_DATA_OUTPUT();
      }
  }

  void read_byte() {
    count = 8;
    local_data = 0;
  }

  uint8_t trace[100];
  uint8_t tpos = 0;

  TOSH_SIGNAL(SIG_INTERRUPT0) {
    uint8_t bit = GET_DATA();

    if (tpos < sizeof trace)
      trace[tpos++] = bit ? 0x44 : 0x11;

    local_data = local_data << 1 | bit;

    if (count == 8)
      {
	if (!GET_DATA())
	  check_for_stop();
	else
	  check_for_start();
      }
    else
      disable_data_intr();

    if (!--count)
      {
	switch (state)
	  {
	  case S_ADDRESS:
	    if (local_data >> 1 == address)
	      {
		if (local_data & 1) // read
		  {
		    local_data = signal I2CSlave.masterRead();
		    //state = S_READ_ACK;
		  }
		else
		  state = S_WRITE_ACK;
		count = 1;
		write_bit(0);
	      }
	    else
	      wait_for_start();
	    break;
	  case S_WRITE_ACK:
	    state = S_WRITE_BYTE;
	    MAKE_DATA_INPUT();
	    read_byte();
	    break;
	  case S_WRITE_BYTE:
	    signal I2CSlave.masterWrite(local_data);
	    state = S_WRITE_ACK;
	    count = 1;
	    write_bit(0);
	    break;
	  }
      }
  }

  TOSH_SIGNAL(SIG_INTERRUPT1) {
    if (GET_CLOCK())
      {
	disable_data_intr();
	switch (state)
	  {
	  case S_WRITE_BYTE:
	    signal I2CSlave.masterWriteDone();
	    break;
	  }
	if (start_possible)
	  {
	    enable_clock_intr();
	    state = S_ADDRESS;
	    read_byte();
	  }
	else if (stop_possible)
	  {
	    state = S_IDLE;
	    wait_for_start();
	  }
      }
  }

  command result_t StdControl.init() {
    MAKE_CLOCK_INPUT();
    MAKE_DATA_INPUT();
    SET_CLOCK();
    SET_DATA();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    wait_for_start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t I2CSlave.setAddress(uint8_t value) {
    atomic address = value;
    return SUCCESS;
  }

  command uint8_t I2CSlave.getAddress() {
    return address;
  }

}
