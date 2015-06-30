// $Id: HPLFlashM.nc,v 1.2 2005/09/20 08:32:41 andreaskoepke Exp $

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
 * HPLFlashM.nc - Driver for AT45DB041 flash on telos. 
 * 
 * This driver is intended to force as little change as possible to
 * the existing PageEEPROM implementation for Micas.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Kevin Klues <klues@tkn.tu-berlin.de> Changes to work on the eyesIFX platform
 */

module HPLFlashM {
  provides {
    interface StdControl as FlashControl;
    interface BusArbitration as FlashSelect;
    interface FastSPI as FlashSPI;
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
    return SUCCESS;
  }

  command result_t FlashControl.start() {
    return SUCCESS;
  }

  command result_t FlashControl.stop() {
    return SUCCESS;
  }

  async command result_t FlashSelect.getBus() {
    if(call BusArbitration.getBus() == FAIL)
      return FAIL;
    call USARTControl.enableUARTTx();   
    call USARTControl.setModeSPI();   
    call USARTControl.setClockSource(SSEL_SMCLK);
    call USARTControl.setClockRate(2, 0);        
    TOSH_CLR_FLASH_CS_PIN();
    return SUCCESS;
  }

  async command result_t FlashSelect.releaseBus() {
    return call BusArbitration.releaseBus();
  }

  event result_t BusArbitration.busReleased() {
    TOSH_SET_FLASH_CS_PIN();
    return signal FlashSelect.busReleased();
  }
  
  event result_t BusArbitration.busRequested() {
    return signal FlashSelect.busRequested();
  }  

  async command uint8_t FlashSPI.txByte(uint8_t spiOut) {
    uint8_t spiIn = 0;
    atomic {
      call USARTControl.tx(spiOut);
      while(call USARTControl.isTxEmpty() == FAIL);
      spiIn = call USARTControl.rx();
    }
    return spiIn;
  }

  default event result_t FlashSelect.busReleased() {
    return SUCCESS;
  }

}
