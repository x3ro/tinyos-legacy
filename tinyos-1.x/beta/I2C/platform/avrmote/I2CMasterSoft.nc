// $Id: I2CMasterSoft.nc,v 1.1 2003/11/01 00:18:22 idgay Exp $

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
 *
 * Authors:		Joe Polastre, Rob Szewczyk
 * Date last modified:  7/18/02
 *
 * @author Joe Polastre
 * @author Rob Szewczyk
 */

/* A software I2C master-only implementation.
 * This implementation turns on the pullups on the SCL and SDA pins, 
 * allowing its use on motes (which do not have pullup resistors on the
 * I2C bus).
 */

module I2CMasterSoft
{
  provides {
    interface StdControl;
    interface I2C;
  }
}
implementation
{
  // global variables
  norace char local_data;	// data to be read/written

  // wait when triggering the clock
  void wait() {
    TOSH_uwait(5);
  }

  // hardware pin functions
  void MAKE_CLOCK_OUTPUT() { TOSH_MAKE_I2C_BUS1_SCL_OUTPUT(); }
  void MAKE_CLOCK_INPUT() { TOSH_MAKE_I2C_BUS1_SCL_INPUT(); }
  char GET_CLOCK() { return TOSH_READ_I2C_BUS1_SCL_PIN(); }
  void SET_CLOCK() { MAKE_CLOCK_INPUT(); TOSH_SET_I2C_BUS1_SCL_PIN(); }
  void CLEAR_CLOCK() { MAKE_CLOCK_OUTPUT(); TOSH_CLR_I2C_BUS1_SCL_PIN(); }

  void MAKE_DATA_OUTPUT() { TOSH_MAKE_I2C_BUS1_SDA_OUTPUT(); }
  void MAKE_DATA_INPUT() { TOSH_MAKE_I2C_BUS1_SDA_INPUT(); }
  char GET_DATA() { return TOSH_READ_I2C_BUS1_SDA_PIN(); }
  void SET_DATA() { MAKE_DATA_INPUT(); TOSH_SET_I2C_BUS1_SDA_PIN();  }
  void CLEAR_DATA() { MAKE_DATA_OUTPUT(); TOSH_CLR_I2C_BUS1_SDA_PIN(); }

  void clock_high() {
    SET_CLOCK();
    while (!GET_CLOCK()) ;
  }

  void pulse_clock() {
    wait();
    clock_high();
    wait();
    CLEAR_CLOCK();
  }

  bool read_bit() {
    uint8_t i;
	
    SET_DATA();
    wait();
    clock_high();
    wait();
    i = GET_DATA();
    CLEAR_CLOCK();
    return i;
  }

  uint8_t i2c_read(){
    uint8_t data = 0;
    uint8_t i;

    for (i = 0; i < 8; i ++)
      {
	data = data << 1;
	if (read_bit())
	  data |= 0x1;
      }
    return data;
  }

  bool i2c_write(char c) { 
    uint8_t i;

    for (i = 0; i < 8; i ++)
      {
	if (c & 0x80)
	  SET_DATA();
	else
	  CLEAR_DATA();
	pulse_clock();
	c = c << 1;
      }
    i = read_bit();	

    return i == 0;
  }

  void i2c_start() {
    SET_DATA();
    clock_high();
    wait();
    CLEAR_DATA();
    wait();
    CLEAR_CLOCK();
  }

  void i2c_ack() {
    CLEAR_DATA();
    pulse_clock();
  }

  void i2c_nack() {
    SET_DATA();
    pulse_clock();
  }

  void i2c_end() {
    CLEAR_DATA();
    wait();
    clock_high();
    wait();
    SET_DATA();
  }

  command result_t StdControl.init() {
    SET_CLOCK();
    SET_DATA();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void sendStart() {
    i2c_start();
    signal I2C.sendStartDone();
  }

  async command result_t I2C.sendStart() {
    post sendStart();
    return SUCCESS;
  }

  task void sendEnd() {
    i2c_end();
    signal I2C.sendEndDone();
  }

  async command result_t I2C.sendEnd() {
    post sendEnd();
    return SUCCESS;
  }

  task void read() {
    uint8_t val = i2c_read();
    if (local_data)
      i2c_ack();
    else
      i2c_nack();
    signal I2C.readDone(val);
  }

  async command result_t I2C.read(bool ack) {
    local_data = ack;
    post read();
    return SUCCESS;
  }

  task void write() {
    signal I2C.writeDone(i2c_write(local_data), FALSE);
  }

  async command result_t I2C.write(char data) {
    local_data = data;
    post write();
    return SUCCESS;
  }
}
