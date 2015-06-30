// $Id: HPLCC2420M.nc,v 1.10 2005/05/19 18:00:21 jdprabhu Exp $

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
 * Authors: Alan Broad, Crossbow
 * Date last modified:  $Revision: 1.10 $
 *
 */

/**
 * Low level hardware access to the CC2420
 * @author Alan Broad
 */

module HPLCC2420M {
  provides {
    interface StdControl;
    interface HPLCC2420;
    interface HPLCC2420RAM;
  }
   uses {
     interface StdControl as TimerControl;  //For TimerC initialization
   }
}
implementation
{
 norace bool bSpiAvail;                    //true if Spi bus available
 norace uint8_t* rambuf;
  norace uint8_t ramlen;
  norace uint16_t ramaddr;

/*********************************************************
 * function: init
 *  set Atmega pin directions for cc2420
 *  enable SPI master bus
 ********************************************************/
    command result_t StdControl.init() {
    
    bSpiAvail = TRUE;
    TOSH_MAKE_MISO_INPUT();
    TOSH_MAKE_MOSI_OUTPUT();
    TOSH_MAKE_SPI_SCK_OUTPUT();
    TOSH_MAKE_CC_RSTN_OUTPUT();    
    TOSH_MAKE_CC_VREN_OUTPUT();
    TOSH_MAKE_CC_CS_OUTPUT(); 
    TOSH_MAKE_CC_FIFOP1_INPUT();    
    TOSH_MAKE_CC_CCA_INPUT();
    TOSH_MAKE_CC_SFD_INPUT();
    TOSH_MAKE_CC_FIFO_INPUT(); 
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
      call TimerControl.init(); // Explicitly initialize the TOS Timer
    return SUCCESS;
  }
  
  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }
  

   /*********************************************************
   * function: cmd
   *  send a command strobe
   ********************************************************/
   async command uint8_t HPLCC2420.cmd(uint8_t addr){
     uint8_t status;

	atomic {
      TOSH_CLR_CC_CS_PIN();                   //enable chip select
	  outp(addr,SPDR);
	  while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
	  status = inp(SPDR);
    }
	TOSH_SET_CC_CS_PIN();                       //disable chip select
    return status;
   }

   /**************************************************************************
   * function: write                                       
   *   - accepts a 6 bit address and 16 bit data, 
   *   - write addr byte to SPI while reading status
   *   - if cmd strobe then just write addr, read status and exit
   *   - else write 16 bit data
   *   - SPI bus runs at ~ 3.6Mhz clock (2.2 usec/byte xfr) 
   *      
   *  NEED TO CHK IS SPI BUS IN USE?????????????????????????????
   *  THIS ROUTINE IS POLLING SPI CHANGE ????????????????????????
   * 
   ********************************************************/
  async command result_t HPLCC2420.write(uint8_t addr, uint16_t data) {
     uint8_t status;
 
 //   while (!bSpiAvail){};                      //wait for spi bus 

	atomic {
	  bSpiAvail = FALSE;
      TOSH_CLR_CC_CS_PIN();                   //enable chip select
	  outp(addr,SPDR);
	  while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
	  status = inp(SPDR);
      if (addr > CC2420_SAES ){ 
	    outp(data >> 8,SPDR);
	    while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
	    outp(data & 0xff,SPDR);
	    while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
      }
	  bSpiAvail = TRUE;
    }
	TOSH_SET_CC_CS_PIN();                       //disable chip select
    return status;
  }
  
  /****************************************************************************
   * function: read                                        
   *   description: accepts a 6 bit address, 
   *   write addr byte to SPI while reading status 
   *   read status, followed by 2 data bytes
   * Input:  6 bit address                                 
   * Output: 16 bit data                                   
   ****************************************************************************/
  async command uint16_t HPLCC2420.read(uint8_t addr) {
  
    uint16_t data = 0;
    uint8_t status;

//    while (bSpiAvail){};                 //wait for spi bus
   atomic{
      bSpiAvail = FALSE;
      TOSH_CLR_CC_CS_PIN();                   //enable chip select
      outp(addr | 0x40,SPDR);
      while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
      status = inp(SPDR); 
      outp(0,SPDR);
      while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
      data = inp(SPDR);
      outp(0,SPDR);
      while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
      data = (data << 8) | inp(SPDR);
      TOSH_SET_CC_CS_PIN();                       //disable chip select
	  bSpiAvail = TRUE;
    }
    return data;
  }

  task void signalRAMRd() {
    signal HPLCC2420RAM.readDone(ramaddr, ramlen, rambuf);
  }
  /**
   * Read data from CC2420 RAM
   *
   * @return SUCCESS if the request was accepted
   */

  async command result_t HPLCC2420RAM.read(uint16_t addr, uint8_t length, uint8_t* buffer) {
    // not yet implemented
    return FAIL;
  }

  task void signalRAMWr() {
    signal HPLCC2420RAM.writeDone(ramaddr, ramlen, rambuf);
  }
  /**
   * Write databuffer to CC2420 RAM.
   * @param addr RAM Address (9 bits)
   * @param length Nof bytes to write
   * @param buffer Pointer to data buffer
   * @return SUCCESS if the request was accepted
   */

  async command result_t HPLCC2420RAM.write(uint16_t addr, uint8_t length, uint8_t* buffer) {
    uint8_t i = 0;
    uint8_t status;

	if( !bSpiAvail )
		return FALSE;

	atomic {
		bSpiAvail = FALSE;
		ramaddr = addr;
		ramlen = length;
		rambuf = buffer;
		TOSH_CLR_CC_CS_PIN();                   //enable chip select
		outp( ((ramaddr & 0x7F) | 0x80),SPDR);	  //ls address	and set RAM/Reg flagbit
		while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
		status = inp(SPDR);
		outp( ((ramaddr >> 1) & 0xC0),SPDR);	  //ms address
		while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
		status = inp(SPDR);

		for (i = 0; i < ramlen; i++) {				  //buffer write
       	outp( rambuf[i] ,SPDR);
//        call USARTControl.tx(rambuf[i]);
	  	while (!(inp(SPSR) & 0x80)){};          //wait for spi xfr to complete
      }
	}//atomic
	bSpiAvail = TRUE;
	return post signalRAMWr();
  }	//RAM.write

}//HPLCC2420M.nc
  
