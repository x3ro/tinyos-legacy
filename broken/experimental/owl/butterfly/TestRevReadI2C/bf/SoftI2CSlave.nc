// $Id: SoftI2CSlave.nc,v 1.1 2003/10/25 00:29:00 idgay Exp $

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

  enum { S_IDLE, S_ADDRESS, S_WRITE_ACK, S_READ_ACK, S_WRITE_BYTE, S_READ_BYTE,
	 S_WRITE_ACK_DONE };

  uint8_t trace[200];
  uint8_t tpos = 0;

  void tt(uint8_t n) {
    if (tpos < sizeof trace)
      trace[tpos++] = n;
  }

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

  void enable_data_intr() {
    // sda edge
    MAKE_DATA_INPUT();
    sbi(PCMSK0, 5);
    sbi(EIMSK, PCIE0);
  }

  void disable_data_intr() {
    cbi(PCMSK0, 5);
    if (inp(PCMSK0) == 0)
      cbi(EIMSK, PCIE0);
  }

  void enable_clock_intr() {
    MAKE_CLOCK_INPUT();
    sbi(PCMSK0, 4);
    sbi(EIMSK, PCIE0);
  }

  void disable_clock_intr() {
    tt(0x87);
    cbi(PCMSK0, 4);
    if (inp(PCMSK0) == 0)
      cbi(EIMSK, PCIE0);
  }

  void wait_for_start() {
    state = S_IDLE;
    start_possible = TRUE;
    disable_clock_intr();
    enable_data_intr();
  }

  void check_for_start() {
    start_possible = TRUE;
    enable_data_intr();
  }

  void check_for_stop() {
    stop_possible = TRUE;
    enable_data_intr();
  }

  void write_bit(uint8_t bit) {
    if (!bit)
      {
	CLEAR_DATA();
	MAKE_DATA_OUTPUT();
      }
  }

  void read_byte() {
    MAKE_DATA_INPUT();
    count = 8;
    local_data = 0;
  }

  void clock_rise(uint8_t data) {
    local_data = local_data << 1 | data;

    if (count == 8)
      {
	tt(0x82);
	// start/stop detection until clock drops
	if (!data)
	  check_for_stop();
	else
	  check_for_start();
      }

    if (!--count)
      {
	switch (state)
	  {
	  case S_ADDRESS:
	    if (local_data >> 1 == address)
	      {
		tt(0x84); tt(local_data);
		if (local_data & 1) // read
		  {
		    local_data = signal I2CSlave.masterRead();
		    //state = S_READ_ACK;
		  }
		else
		  state = S_WRITE_ACK;
	      }
	    else
	      {
		tt(0x85); tt(local_data);
		wait_for_start();
	      }
	    break;
	  case S_WRITE_BYTE:
	    tt(0x8a); tt(local_data);
	    signal I2CSlave.masterWrite(local_data);
	    state = S_WRITE_ACK;
	    break;
	  }
      }
  }

  void clock_fall(uint8_t data) {
    tt(0x83);
    disable_data_intr();
    start_possible = stop_possible = FALSE;

    if (state == S_WRITE_ACK)
      {
	tt(0x86);
	write_bit(0);
	state = S_WRITE_ACK_DONE;
      }
    else if (state == S_WRITE_ACK_DONE)
      {
	tt(0x8b);
	state = S_WRITE_BYTE;
	read_byte();
      }
  }

  void data_fall(uint8_t clk) {
    if (start_possible && clk)
      {
	tt(0x80);
	disable_data_intr();
	enable_clock_intr();
	state = S_ADDRESS;
	read_byte();
      }
  }

  void data_rise(uint8_t clk) {
    if (stop_possible && clk)
      {
	tt(0x81);
	state = S_IDLE;
	wait_for_start();
	signal I2CSlave.masterWriteDone();
      }
  }

  uint8_t lastE;

  TOSH_SIGNAL(SIG_PIN_CHANGE0) {
    uint8_t E = inp(PINE);

    if (tpos < sizeof trace)
      tt((E & (1 << 4 | 1 << 5)) | (start_possible ? 1 : 0) | (stop_possible ? 2 : 0));


    if (start_possible || stop_possible)
      {
	// check for data change with clock high
	if ((E & 1 << 5) != (lastE & 1 << 5) && (E & 1 << 4))
	  {
	    if (E & 1 << 5)
	      data_rise((E & 1 << 4) != 0);
	    else
	      data_fall((E & 1 << 4) != 0);
	    lastE = E;
	    return;
	  }
      }
    if (state != S_IDLE)
      {
	// check for clock change
	if ((E & 1 << 4) != (lastE & 1 << 4))
	  {
	    if (E & 1 << 4)
	      clock_rise((E & 1 << 5) != 0);
	    else
	      clock_fall((E & 1 << 5) != 0);
	  }
      }
    lastE = E;
  }
  
  command result_t StdControl.init() {
    MAKE_CLOCK_INPUT();
    MAKE_DATA_INPUT();
    SET_CLOCK();
    SET_DATA();
    lastE = inp(PINE);
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
