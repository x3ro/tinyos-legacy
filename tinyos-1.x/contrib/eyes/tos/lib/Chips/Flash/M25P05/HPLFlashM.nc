// $Id: HPLFlashM.nc,v 1.3 2005/09/20 08:32:41 andreaskoepke Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/**
 * HPLFlashM.nc - Driver for M25P05 flash on eyes. 
 * 
 * This driver is intended to force as little change as possible to
 * the existing PageEEPROM implementation for Micas.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Jan-Hinrich Hauer (modifications for eyes-platform)
 */

module HPLFlashM {
  provides {
    interface StdControl as FlashControl;
    interface BusArbitration as FlashSelect;
    interface FlashCommand;
  }
  uses {
    interface HPLUSARTControl as USARTControl;
    interface BusArbitration;
  }
}

implementation {

  command result_t FlashControl.init() {
    TOSH_SEL_FLASH_CS_IOFUNC();
    TOSH_SET_FLASH_CS_PIN();
    TOSH_MAKE_FLASH_CS_OUTPUT();
    //TOSH_uwait(15500); // initial startup time
    return SUCCESS;
  }

  command result_t FlashControl.start() {
    return SUCCESS;
  }

  command result_t FlashControl.stop() {
    return SUCCESS;
  }

  async command result_t FlashSelect.getBus() {
    if (call BusArbitration.getBus() == FAIL)
      return FAIL;
    call USARTControl.setModeUART_TX();   
    call USARTControl.setModeSPI();      
    call USARTControl.setClockSource(SSEL_SMCLK);
    call USARTControl.setClockRate(2, 0);   
    return SUCCESS;
  }

  async command result_t FlashSelect.releaseBus() {
    return call BusArbitration.releaseBus();
  }

  async command void FlashCommand.beginCommand(){    
    TOSH_CLR_FLASH_CS_PIN();
  }
    
  async command void FlashCommand.endCommand(){
    while (call USARTControl.isTxEmpty() == FAIL) // wait for data to be output
      ;
    TOSH_SET_FLASH_CS_PIN();
  }  
    
  event result_t BusArbitration.busReleased() {
    return signal FlashSelect.busReleased();
  }
  
  event result_t BusArbitration.busRequested(){
    return signal FlashSelect.busRequested();
  }
  
  async command uint8_t FlashCommand.rxByte(uint8_t spiOut) {
    uint8_t value;
    call USARTControl.tx(spiOut);
    while (call USARTControl.isTxEmpty() == FAIL) // wait for U0RXBUF to become full
      ;
    value = call USARTControl.rx(); // get data from the buffer
    return value;
  }

  async command void FlashCommand.txByte(uint8_t spiOut) {
    call USARTControl.tx(spiOut);
    while (call USARTControl.isTxIntrPending() == FAIL)  // wait for U0TXBUF become empty
      ;
    return;
  }

  default event result_t FlashSelect.busReleased() {
    return SUCCESS;
  }

}
