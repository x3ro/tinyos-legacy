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

/* I2C for the ATmega169. This does both master & slave, but doesn't do
   multi-master arbitration (collisions will just create a mess). See
   comments in wClockBits about collision detection. */

module HPLI2CM
{
  provides {
    interface StdControl;
    interface I2C;
    interface I2CSlave;
  }
}
implementation
{
  norace uint8_t temp;
  uint8_t state;
  uint8_t address;

  enum { S_IDLE, S_SENDING, S_READING };

  // hardware pin functions
  void SET_CLOCK() { TOSH_SET_I2C_BUS1_SCL_PIN(); }
  void CLEAR_CLOCK() { TOSH_CLR_I2C_BUS1_SCL_PIN(); }
  void MAKE_CLOCK_OUTPUT() { TOSH_MAKE_I2C_BUS1_SCL_OUTPUT(); }
  void MAKE_CLOCK_INPUT() { TOSH_MAKE_I2C_BUS1_SCL_INPUT(); }
  char GET_CLOCK() { return TOSH_READ_I2C_BUS1_SCL_PIN(); }

  // We don't touch PE5 directly, we only use USIDR
  void SET_DATA() { sbi(USIDR, 7); }
  void CLEAR_DATA() { cbi(USIDR, 7); }
  void SHIFT_DATA() { sbi(USICR, USICLK); }
  void MAKE_DATA_OUTPUT() { TOSH_MAKE_I2C_BUS1_SDA_OUTPUT(); }
  void MAKE_DATA_INPUT() { TOSH_MAKE_I2C_BUS1_SDA_INPUT(); }

  void wait_for_start() {
    outp(1 << USISIE | 2 << USIWM0, USICR);
    outp(1 << USIOIF, USISR);
    state = S_IDLE;
    MAKE_DATA_INPUT();
  }

  void write_ack(bool ack) {
    MAKE_DATA_OUTPUT();
    outp(ack ? 0 : 0x80, USIDR);
    outp(3 << USIWM0 | 3 << USICS0, USICR);
    outp(1 << USIOIF | 0xe, USISR); // 1 bit only
    while (bit_is_clear(USISR, USIOIF)) ;
    MAKE_DATA_INPUT();
  }

  // Switch hardware to sending vs receiving mode
  void start_sending() {
    // 2-wire mode, with software clock strobe
    // (UCICS mode 3) is broken for master work - data changes on
    // the positive clock edge (the previous bit was latched until
    // then), which is incorrect (too late) and doesn't work
    outp(2 << USIWM0, USICR);
    state = S_SENDING;

    // Configure SDA as output
    MAKE_DATA_OUTPUT();
    SET_DATA(); 
  }

  // wait when triggering the clock
  void wait() {
    TOSH_uwait(5);
  }

  bool wclockBits(uint8_t n) {
    uint8_t i;

    for (i = 0; i < n; i++)
      {
	wait();
	SET_CLOCK();
	while (!GET_CLOCK()) ;
#if 0
	// Doing collision detection is tricky, because we also need
	// to prevent the clock from going faster than we want. To do this,
	// we would need to use USIWM mode 3 (hold clock low on counter
	// overflow), and clock the counter from an external source
	// (USICS modes 2 or 3). But using those modes doesn't seem to
	// work (the data pin changes at the wrong time, leading to 
	// false start or stop conditions). A hack with 0xff in USIDR
	// and modifying SDA directly might work.
	if (bit_is_set(USISR, USIDC)) // collision
	  return FALSE;
#endif
	wait();
	CLEAR_CLOCK();
	SHIFT_DATA(); // shift data after clock drop for writes
      }
    return TRUE;
  }

  void rclockBits(uint8_t n) {
    uint8_t i;

    for (i = 0; i < n; i++)
      {
	wait();
	SET_CLOCK();
	while (!GET_CLOCK()) ;
	wait();
	SHIFT_DATA(); // shift data before clock drop for reads
	CLEAR_CLOCK();
      }
  }

  command result_t StdControl.init() {
    atomic 
      {
	address = 0;
	state = S_IDLE;
      }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // Setup chip to listen for I2C start conditions
    atomic
      {
	outp(0xf0, USISR); // clear pending conditions
	wait_for_start();
	// we assume the bus is free at this point (no real way of
	// checking), we mark this by pretending that we're at the
	// end of a previous send, and are doing a repeated start
	state = S_SENDING; 

	// Clock is always an output (we can sample its state as long
	// as we're not driving it low)
	MAKE_CLOCK_OUTPUT();
	SET_CLOCK();

	// Data is input or output depending on our action. But we always
	// modify its state via USIDR (data input connects pin to USIDR,
	// data output connects USIDR to pin)
	TOSH_SET_I2C_BUS1_SDA_PIN(); // Just leave PORTE5 high forever
      }

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    outb(USICR, 0);		// Restore normal port behaviour
    return SUCCESS;
  }

  task void sendStart() {
    bool oops = FALSE;

    atomic
      {
	// if not a repeated start, bus must be free (stop condition
	// detected - stop conditions are cleared when a start is 
	// detected or sent)
	if (state != S_SENDING && bit_is_clear(USISR, USIPF))
	  {
	    // bus busy, we have to busy wait :-(
	    // Note: in the case that we're currently receiving, we
	    // could stop busy waiting (and let the receive logic
	    // restart us), but this doesn't seem worth the bother.
	    post sendStart();
	    oops = TRUE;
	  }
	else
	  start_sending();
      }
    if (oops)
      return;

    // We ensure data and clock are high
    // (If somebody else does a start at this time this will do no harm)
    SET_DATA(); 
    wait();
    SET_CLOCK();
    while (!GET_CLOCK()) ;
    wait();

    // The start condition
    CLEAR_DATA();
    wait();
    CLEAR_CLOCK();
    outb(USISR, 1 << USISIF | 1 << USIPF); // clear start condition we just caused, and any old stop condition
    signal I2C.sendStartDone(); 
  }

  async command result_t I2C.sendStart() {
    post sendStart();
    return SUCCESS;
  }

  bool sending() {
    uint8_t s;
    atomic s = state;
    return s == S_SENDING;
  }

  task void sendEnd() {
    CLEAR_DATA();
    wait();
    SET_CLOCK();
    while (!GET_CLOCK()) ;
    wait();
    atomic
      {
	state = S_IDLE;
	SET_DATA();
      }
    signal I2C.sendEndDone();
    atomic
      {
	if (state == S_IDLE)
	  wait_for_start();
      }
  }

  async command result_t I2C.sendEnd() {
    if (!sending())
      return FAIL;

    post sendEnd();
    return SUCCESS;
  }

  task void i2cRead() {
    uint8_t n;

    MAKE_DATA_INPUT();
    rclockBits(8);
    n = inp(USIDR);
    MAKE_DATA_OUTPUT();
    outp(temp ? 0 : 0x80, USIDR);
    wclockBits(1);
    signal I2C.readDone(n);
  }

  async command result_t I2C.read(bool ack) {
    if (!sending())
      return FAIL;

    temp = ack;
    post i2cRead();
    return SUCCESS;
  }

  task void i2cWrite() {
    bool ack;

    outp(temp, USIDR);
    if (!wclockBits(8))
      {
	signal I2C.writeDone(FALSE, TRUE);
	atomic wait_for_start();
	return;
      }
    MAKE_DATA_INPUT();
    rclockBits(1);
    ack = !(inp(USIDR) & 1);
    MAKE_DATA_OUTPUT();
    signal I2C.writeDone(ack, FALSE);
  }

  async command result_t I2C.write(char data) {
    if (!sending())
      return FAIL;

    temp = data;
    post i2cWrite();
    return SUCCESS;
  }

  async command result_t I2CSlave.setAddress(uint8_t value) {
    atomic address = value;
    return SUCCESS;
  }

  async command uint8_t I2CSlave.getAddress() {
    return address;
  }

  // The I2C slave stuff is done using busy waits - the I2C clock rate
  // is potentially high enough (100kHz - i.e., 10 processor cycles)
  // that an interrupt driven solution makes little sense.
  // (the lack of interrupt for the stop condition makes an interrupt-driven
  // solution tricky too)

  uint8_t wait_for_event() {
    uint8_t sr;

    while (!((sr = inp(USISR)) & (1 << USISIF | 1 << USIPF | 1 << USIOIF))) ;

    return sr;
  }

  TOSH_SIGNAL(SIG_USI_START) {
    uint8_t sla, adr, sr;

    state = S_READING;
    // busy wait for clock to drop
    while (GET_CLOCK()) ;

    // Read address byte
    outp(3 << USIWM0 | 2 << USICS0, USICR);
    outp(1 << USISIF | 1 << USIOIF | 1 << USIPF, USISR);
    // We can enable interrupts now that we've setup the registers and
    // cleared the start condition
    __nesc_enable_interrupt();
    sr = wait_for_event();
    if (sr & (1 << USISIF | 1 << USIPF))
      {
	// we got an unexpected start or stop. abort.
	atomic wait_for_start();
	return;
      }

    sla = inp(USIDR);
    adr = sla >> 1;

    if (!(adr == 0 && address & I2CSLAVE_GENERAL_CALL ||
	  adr != 0 && adr == address & 0x7f))
      {
	// Not for us.
	atomic wait_for_start();
	return;
      }

    write_ack(TRUE);

    if (sla & 1) // read
      signal I2CSlave.masterReadStart();
    else
      signal I2CSlave.masterWriteStart(FALSE);
  }

  task void masterWrite() {
    bool ack = temp;

    for (;;)
      {
	uint8_t val, sr;

	outp(3 << USIWM0 | 2 << USICS0, USICR);
	outp(1 << USIOIF, USISR);
	// wait for something to happen
	sr = wait_for_event();
	if (sr & (1 << USISIF | 1 << USIPF))
	  {
	    // we want to get the completion event before the next transaction
	    atomic state = S_IDLE;
	    signal I2CSlave.masterWriteDone();
	    atomic wait_for_start();
	    return;
	  }

	val = inp(USIDR);

	write_ack(ack);

	ack = signal I2CSlave.masterWrite(val);
      }
  }

  async command result_t I2CSlave.masterWriteReady(bool ackFirst) {
    temp = ackFirst;
    post masterWrite();
    return SUCCESS;
  }

  task void masterRead() {
    for (;;)
      {
	uint16_t data;
	bool ack;

	MAKE_DATA_OUTPUT();
	data = signal I2CSlave.masterRead();
	outp(data, USIDR);

	// write the byte
	outp(3 << USIWM0 | 2 << USICS0, USICR);
	outp(1 << USIOIF, USISR);
	// we can't really detect start or stop conditions, as we might
	// be driving data low. So don't try.
	while (bit_is_clear(USISR, USIOIF)) ;

	// read the ack bit
	MAKE_DATA_INPUT();
	outp(3 << USIWM0 | 2 << USICS0, USICR);
	outp(1 << USIOIF | 0xe, USISR);
	while (bit_is_clear(USISR, USIOIF));
	ack = inp(USIDR) & 1;
	if (ack || data & I2CSLAVE_LAST)
	  {
	    // nack or last byte - we exit
	    atomic state = S_IDLE;
	    signal I2CSlave.masterReadDone(ack);
	    atomic wait_for_start();
	    return;
	  }
      }
  }

  async command result_t I2CSlave.masterReadReady() {
    post masterRead();
    return SUCCESS;
  }

  default async event result_t I2CSlave.masterWrite(uint8_t n) {
    return SUCCESS;
  }

  default async event result_t I2CSlave.masterWriteDone() {
    return SUCCESS;
  }

  default async event uint16_t I2CSlave.masterRead() {
    return I2CSLAVE_LAST;
  }

  default async event result_t I2CSlave.masterReadDone(bool lastByteAcked) {
    return SUCCESS;
  }

  default async event result_t I2CSlave.masterReadStart() {
    return SUCCESS;
  }

  default async event result_t I2CSlave.masterWriteStart(bool general) {
    return SUCCESS;
  }
}
