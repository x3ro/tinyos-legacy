// $Id: HPLSpiM.nc,v 1.3 2004/06/08 22:41:40 jdprabhu Exp $

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
 * Authors: Jaein Jeong, Philip buonadonna
 * Date last modified: $Revision: 1.3 $
 *
 */

/**
 * @author Jaein Jeong
 * @author Philip buonadonna
 */


module HPLSpiM
{
  provides interface SpiByteFifo;
  uses interface PowerManagement;
}
implementation
{
  norace uint8_t OutgoingByte; // Define norace to prevent nesC 1.1 warnings

  TOSH_SIGNAL(SIG_SPI) {
    register uint8_t temp = inp(SPDR);
    outp(OutgoingByte,SPDR);
    signal SpiByteFifo.dataReady(temp);
  }

  async command result_t SpiByteFifo.writeByte(uint8_t data) {
    while(bit_is_clear(SPSR,SPIF));
    outp(data, SPDR);
  //  atomic OutgoingByte = data;
    return SUCCESS;
  }

  async command result_t SpiByteFifo.isBufBusy() {
    return bit_is_clear(SPSR,SPIF);
  }

  async command uint8_t SpiByteFifo.readByte() {
    return inp(SPDR);
  }

  async command result_t SpiByteFifo.enableIntr() {
    //sbi(SPCR,SPIE);
    outp(0xC0, SPCR);
    cbi(DDRB, 0);
    call PowerManagement.adjustPower();
    return SUCCESS;
  }

  async command result_t SpiByteFifo.disableIntr() {
    cbi(SPCR, SPIE);
    sbi(DDRB, 0);
    cbi(PORTB, 0);
    call PowerManagement.adjustPower();
    return SUCCESS;
  }

  async command result_t SpiByteFifo.initMaster() {
	// Bit 7: SPIE = 1; enable SPI int
	// Bit 6: SPE  = 1; enable SPI 
	// Bit 5: DORD = 0; msb of data xmitted first
	// Bit 4: MSTR = 1; spi is master
	// Bit 3: CPOL = 0; spi clk is low when idle
	// Bit 2: CPHA = 0; sample data on positive edge of sclk
	// Bit 1,0: SPR1,SPR0; clock rate, 0 => fosc/4 (~550ns/bit, 4.4usec/byte)

    atomic {
      TOSH_MAKE_SPI_SCK_OUTPUT();
      TOSH_MAKE_MISO_INPUT();	   // miso
      TOSH_MAKE_MOSI_OUTPUT();	   // mosi
	  sbi (SPSR, SPI2X);           // Double speed spi clock
	  sbi(SPCR, MSTR);             // Set master mode
      cbi(SPCR, CPOL);		       // Set proper polarity...
      cbi(SPCR, CPHA);		       // ...and phase
	  cbi(SPCR, SPR1);             // set clock, fosc/2 (~3.6 Mhz)
      cbi(SPCR, SPR0);
  //    sbi(SPCR, SPIE);	           // enable spi port interrupt
      sbi(SPCR, SPE);              // enable spie port
 } 
    return SUCCESS;
  }
	
  async command result_t SpiByteFifo.txMode() {
    TOSH_MAKE_MISO_OUTPUT();
    TOSH_MAKE_MOSI_OUTPUT();
    return SUCCESS;
  }

  async command result_t SpiByteFifo.rxMode() {
    TOSH_MAKE_MISO_INPUT();
    TOSH_MAKE_MOSI_INPUT();
    return SUCCESS;
  }
}
