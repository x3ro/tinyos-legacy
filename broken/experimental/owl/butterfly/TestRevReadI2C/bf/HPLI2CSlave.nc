// $Id: HPLI2CSlave.nc,v 1.1 2003/10/25 00:29:00 idgay Exp $

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

module HPLI2CSlave
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
  uint8_t address;
  bool start_stop_check;

  enum { S_IDLE, S_ADDRESS, S_WRITE_ACK, S_READ_ACK, S_WRITE_BYTE, S_READ_BYTE,
	 S_WRITE_ACK2 };

  uint8_t trace[200];
  uint8_t tpos = 0;

  void tt(uint8_t n) {
#if 0
    if (tpos < sizeof trace)
      trace[tpos++] = n;
#endif
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

  void wait_for_start() {
    tt(0x80);
    state = S_IDLE;
    MAKE_DATA_INPUT();
    outp(0xf0, USISR);
    outp(1 << USISIE | 2 << USIWM0, USICR);
  }

  void write_ack(uint8_t bit) {
    MAKE_DATA_OUTPUT();
    outp(bit ? 0x80 : 0, USIDR);
    outp(1 << USIOIE | 3 << USIWM0 | 3 << USICS0, USICR);
    outp(0xfe, USISR); // 1 bit only
  }

  void read_byte() {
    MAKE_DATA_INPUT();
    outp(1 << USIOIE | 3 << USIWM0 | 2 << USICS0, USICR);
    start_stop_check = TRUE;
    outp(0xff, USISR);
  }

  TOSH_SIGNAL(SIG_USI_START) {
    // get address
    tt(0x83);
    state = S_ADDRESS;

    // clear start condition, busy wait for clock to drop
    sbi(USISR, USISIF);
    while (GET_CLOCK()) ;

    read_byte();
  }

  TOSH_SIGNAL(SIG_USI_OVERFLOW) {
    uint8_t data = inp(USIDR);

    if (start_stop_check)
      {
	tt(0x84);
	start_stop_check = FALSE;
	// busy wait for stop, start or clock drop
	while (GET_CLOCK())
	  {
	    uint8_t sr = inp(USISR);

	    if (sr & 1 << USIPF)
	      {
		wait_for_start();
		signal I2CSlave.masterWriteDone();
		return;
	      }
	    else if (sr & 1 << USISIF)
	      {
		state = S_ADDRESS;
		read_byte();
		signal I2CSlave.masterWriteDone();
		return;
	      }
	  }
	// Continue counting from 2
	outp(0xf2, USISR);
	return;
      }

    tt(0x85 + state); tt(data);
    switch (state)
      {
      case S_ADDRESS:
	if (data >> 1 == address)
	  {
	    tt(0x8b);
	    if (data & 1) // read
	      {
		data = signal I2CSlave.masterRead();
		//state = S_READ_ACK;
	      }
	    else
	      state = S_WRITE_ACK;
	    write_ack(0);
	  }
	else
	  {
	    tt(0x8c);
	    wait_for_start();
	  }
	break;

      case S_WRITE_ACK:
	state = S_WRITE_BYTE;
	read_byte();
	break;

      case S_WRITE_ACK2:
	wait_for_start();
	signal I2CSlave.masterWriteDone();
	break;

      case S_WRITE_BYTE:
	signal I2CSlave.masterWrite(data);
	state = S_WRITE_ACK2;
	write_ack(0);
	break;
      }
  }
  
  command result_t StdControl.init() {
    SET_CLOCK();
    MAKE_CLOCK_OUTPUT();
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
