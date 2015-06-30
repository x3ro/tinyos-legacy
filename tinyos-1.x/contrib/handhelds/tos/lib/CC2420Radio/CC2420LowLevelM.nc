/*
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
 * Authors: Joe Polastre
 * Date last modified:  $Revision: 1.1 $
 *
 */

/**
 * @author Joe Polastre
 */

/**
 * Adapted by Andrew Christian to use Message interface
 * and to fix bugs.
 * 
 * @author Andrew Christian
 * 6 December 2004
 *
 * Notes:
 *
 *   --  All of these functions are designed to run in interrupt context.  You
 *       should wrap them with appropriate 'atomic' statements if you call them from
 *       task context, or be very careful of what you are doing.
 *
 * Updated June 2005 to support faster operation (Andrew Christian)
 */

module CC2420LowLevelM {
  provides {
    interface StdControl;
    interface CC2420LowLevel;
    interface CC2420Interrupt as CC2420InterruptFIFO;
    interface CC2420Interrupt as CC2420InterruptFIFOP;
  }
  uses {
    interface HPLUSARTControl as USARTControl;
    interface MSP430Interrupt as FIFOInterrupt;
    interface MSP430Interrupt as FIFOPInterrupt;
  }
}
implementation
{
#define WAIT_FOR_TX_COMPLETION() ({while (call USARTControl.isTxEmpty() == FAIL);})

  /********************************************
   *  StdControl interfaces
   ********************************************/
  
  command result_t StdControl.init() {
    TOSH_SET_RADIO_CSN_PIN();
    TOSH_MAKE_RADIO_CSN_OUTPUT();
    call USARTControl.setModeSPI();
    call USARTControl.setClockSource(SSEL_SMCLK);
    call USARTControl.setClockRate(2, 0);   // As fast as possible => SMCLK / 2
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    return SUCCESS;
  } 

  command result_t StdControl.start() {
    call USARTControl.enableSPI();
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
    call USARTControl.disableSPI();
    return SUCCESS;
  }


  /********************************************
   *  CC2420InterruptFIFO interfaces
   ********************************************/

  async command void CC2420InterruptFIFO.enable() {
    call FIFOInterrupt.disable();
    call FIFOInterrupt.clear();
    call FIFOInterrupt.edge(TRUE);
    call FIFOInterrupt.enable();

    if ( (call FIFOInterrupt.getValue()) && 
	 !(call FIFOInterrupt.getPending())) {
      call FIFOInterrupt.setPending();
    }
  }

  async command void CC2420InterruptFIFO.disable() {
    call FIFOInterrupt.disable();
    call FIFOInterrupt.clear();
  }

  async command bool CC2420InterruptFIFO.getEnabled() {
    return call FIFOInterrupt.getEnabled();
  }

  async event void FIFOInterrupt.fired() {
    call FIFOInterrupt.disable();
    call FIFOInterrupt.clear();  // Must clear this before we reenable interrupts

    if ( signal CC2420InterruptFIFO.fired() ) {
      call FIFOInterrupt.enable();
      call FIFOInterrupt.clear();

      if ( (call FIFOInterrupt.getValue()) && 
	   !(call FIFOInterrupt.getPending())) {
	call FIFOInterrupt.setPending();
      }
    }
  }

  /********************************************
   *  CC2420InterruptFIFOP interfaces
   ********************************************/

  async command void CC2420InterruptFIFOP.enable() {
    call FIFOPInterrupt.disable();
    call FIFOPInterrupt.clear();
    call FIFOPInterrupt.edge(TRUE);
    call FIFOPInterrupt.enable();

    if ( (call FIFOPInterrupt.getValue()) && 
	 !(call FIFOPInterrupt.getPending())) {
      call FIFOPInterrupt.setPending();
    }
  }

  async command void CC2420InterruptFIFOP.disable() {
    call FIFOPInterrupt.disable();
    call FIFOPInterrupt.clear();
  }

  async command bool CC2420InterruptFIFOP.getEnabled() {
    return call FIFOPInterrupt.getEnabled();
  }

  async event void FIFOPInterrupt.fired() {
    if ( !signal CC2420InterruptFIFOP.fired())
      call FIFOPInterrupt.disable();
    call FIFOPInterrupt.clear();
  }

  /********************************************
   * Read and write to CC2420 configuration registers
   ********************************************/

  inline uint8_t spi_rx()
  {
    return call USARTControl.rx();
  }

  inline void spi_tx_byte( uint8_t x )
  {
    call USARTControl.tx(x);
    while ( call USARTControl.isTxEmpty() == FAIL )
      ;
  }

  inline uint8_t spi_rx_byte()
  {
    call USARTControl.tx(0);
    while (call USARTControl.isRxIntrPending() == FAIL)
      ;
    return call USARTControl.rx();
  }

  
  /**
   * Send a command strobe
   * 
   * @return status byte from the chipcon
   */ 

  async command uint8_t CC2420LowLevel.cmd(uint8_t addr) {
    uint8_t status;
    TOSH_CLR_RADIO_CSN_PIN();
    spi_tx_byte( addr ); // call USARTControl.tx(addr);
    status = spi_rx();  // status = call USARTControl.rx();
    TOSH_SET_RADIO_CSN_PIN();
    return status;
  }

  /**
   * Transmit 16-bit data
   *
   * @return status byte from the chipcon.  0xff is return of command failed.
   */

  async command uint8_t CC2420LowLevel.write(uint8_t addr, uint16_t data) {
    uint8_t status;

    TOSH_CLR_RADIO_CSN_PIN();
    spi_tx_byte( addr );     // call USARTControl.tx(addr);
    status = spi_rx();
    spi_tx_byte((data>>8) & 0xff); // call USARTControl.tx((data >> 8) & 0x0FF);
    spi_tx_byte(data & 0xff);  // call USARTControl.tx(data & 0x0FF);
    TOSH_SET_RADIO_CSN_PIN();

    return status;
  }

  /**
   * Read 16-bit data
   *
   * @return 16-bit register value
   */

  async command uint16_t CC2420LowLevel.read(uint8_t addr) {
    uint16_t data = 0;

    TOSH_CLR_RADIO_CSN_PIN();
    spi_tx_byte( addr | 0x40 ); // call USARTControl.tx(addr | 0x40);
    spi_rx();   // status byte
    data = (spi_rx_byte() << 8);
    data |= spi_rx_byte();
    TOSH_SET_RADIO_CSN_PIN();

    return data;
  }

  /********************************************
   * Read and write to CC2420 RAM
   ********************************************/

  async command result_t CC2420LowLevel.readRAM(uint16_t addr, uint8_t length, uint8_t* buffer) 
  {
    int i;

    TOSH_CLR_RADIO_CSN_PIN();

    spi_tx_byte((addr & 0x7F) | 0x80);
    spi_tx_byte(((addr >> 1) & 0xC0) | 0x20);
    spi_rx();

    for (i = 0; i < length; i++) 
      *buffer++ = spi_rx_byte();

    TOSH_SET_RADIO_CSN_PIN();    

    return SUCCESS;
  }

  async command result_t CC2420LowLevel.writeRAM(uint16_t addr, uint8_t length, uint8_t* buffer) {
    int i;

    TOSH_CLR_RADIO_CSN_PIN();
    spi_tx_byte((addr & 0x7F) | 0x80);
    spi_tx_byte((addr >> 1) & 0xC0);

    for (i = 0; i < length; i++) 
      spi_tx_byte(*buffer++);

    TOSH_SET_RADIO_CSN_PIN();

    return SUCCESS;
  }


  /********************************************
   *  Running in interrupt context, read a 
   *  complete incoming message.  If the message
   *  requires an ACK, check with our higher level
   *  and send a SACK or SACKPEND as appropriate.
   ********************************************/
  
  async command void CC2420LowLevel.openRXFIFO()
  {
    TOSH_CLR_RADIO_CSN_PIN();
    spi_tx_byte(CC2420_RXFIFO | 0x40);
    spi_rx();
  }

  async command void CC2420LowLevel.closeRXFIFO()
  {
    TOSH_SET_RADIO_CSN_PIN();
  }

  /*
   * This version runs in interrupt context and spins while waiting for FIFO
   * to go high.
   */

  async command result_t CC2420LowLevel.readRXFIFO( uint8_t *data, int len )
  {
    for ( ; len > 0 ; len-- ) {
      while ( !TOSH_READ_RADIO_FIFO_PIN()) {
	// Yes, you MUST check FIFO a second time in this loop
	if (TOSH_READ_RADIO_FIFOP_PIN() && !TOSH_READ_RADIO_FIFO_PIN())
	  return FAIL;
      }
      *data++ = spi_rx_byte();
    }

    return SUCCESS;
  }

  /*
   * This version runs in interrupt context and assumes that all of the bytes
   * are already available.  Note that 'data' may be a NULL pointer.
   */

  async command void CC2420LowLevel.readRXFIFOsafe( uint8_t *data, int len )
  {
    uint8_t v;

    for ( ; len > 0 ; len-- ) {
      v = spi_rx_byte();
      if (data) *data++ = v;
    }
  }

  /********************************************
   *  Write to the CC2420 FIFO.  We assume that
   *  the CRC will be appended.
   ********************************************/

  async command result_t CC2420LowLevel.writeTXFIFO( struct Message *msg ) {
    int i;

    TOSH_CLR_RADIO_CSN_PIN();
    spi_tx_byte(CC2420_TXFIFO);
    spi_tx_byte( msg_get_length(msg) + 2 );  // Add on CRC bytes

    for (i = 0; i < msg_get_length(msg); i++) 
      spi_tx_byte( msg_get_uint8( msg, i ));
    
    TOSH_SET_RADIO_CSN_PIN();
    return SUCCESS;
  }
}
  
