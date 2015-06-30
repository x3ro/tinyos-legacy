// $Id: FastI2CSlave.nc,v 1.2 2003/10/27 21:20:28 idgay Exp $

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

module FastI2CSlave
{
  provides {
    interface StdControl;
    interface I2CSlave;
  }
  uses interface Leds;
}
implementation
{
  uint8_t address;

  uint8_t trace[200];
  uint8_t tpos = 0;

  void tt(uint8_t n) {
#if 1
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
    outp(0xf0, USISR);
    outp(1 << USISIE | 2 << USIWM0, USICR);
  }

  void write_ack() {
    MAKE_DATA_OUTPUT();
    outp(0, USIDR);
    outp(3 << USIWM0 | 3 << USICS0, USICR);
    outp(0xfe, USISR); // 1 bit only
    while (bit_is_clear(USISR, USIOIF)) ;
    MAKE_DATA_INPUT();
  }

  uint8_t read_byte() {
    outp(3 << USIWM0 | 2 << USICS0, USICR);
    outp(0xf0, USISR);
    while (bit_is_clear(USISR, USIOIF)) ;

    return inp(USIDR);
  }

  TOSH_SIGNAL(SIG_USI_START) {
    uint8_t sla, data;
    bool read;

  start:
    tt(0x81);
    // clear start condition, busy wait for clock to drop
    while (GET_CLOCK()) ;

    sla = read_byte();
    tt(sla);
    if (sla >> 1 != address)
      {
	// Not for us.
	tt(0x82);
	wait_for_start();
	return;
      }

    if (sla & 1) // read
      {
	data = signal I2CSlave.masterRead();
	read = TRUE;
      }
    else
      read = FALSE;

    write_ack();

    for (;;)
      {
	outp(3 << USIWM0 | 2 << USICS0, USICR);
	outp(0xf0, USISR);
	// wait for something to happen
	while (!(inp(USISR) & (1 << USISIF | 1 << USIPF | 1 << USIOIF))) ;

	if (bit_is_set(USISR, USIPF))
	  {
	    // wait for start, but *don't* clear status (we could miss a start
	    // immediately after stop if we did)
	    outp(1 << USISIE | 2 << USIWM0, USICR);
	    //wait_for_start();
	    signal I2CSlave.masterWriteDone();
	    return;
	  }
	if (bit_is_set(USISR, USISIF))
	  {
	    // repeated start
	    signal I2CSlave.masterWriteDone();
	    goto start;
	  }

	signal I2CSlave.masterWrite(inp(USIDR));
	write_ack();
      }
  }
  
  command result_t StdControl.init() {
    SET_CLOCK();
    SET_DATA();
    MAKE_CLOCK_OUTPUT();
    MAKE_DATA_INPUT();
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
