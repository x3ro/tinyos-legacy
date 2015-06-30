// $Id: HPLFlashM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

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
 */


// XXX XXX we need to proide  readdata and writedata here  
module HPLFlashM {
  provides {
    interface StdControl as FlashControl;
    interface BusArbitration as FlashSelect;
    interface FastSPI as FlashSPI;
    interface ReadData;
    interface WriteData;
    
  }
  uses {
    interface HPLUSARTControl as USARTControl;
    interface BusArbitration;
  }
}

implementation {

  command result_t FlashControl.init() {
    // reset the chip
    TOSH_CLR_FLASH_RST_PIN();
    TOSH_uwait(100);
    TOSH_SET_FLASH_RST_PIN();
    // put us in business
    TOSH_SET_FLASH_CS_PIN();
    TOSH_MAKE_FLASH_CS_OUTPUT();
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();    
    return SUCCESS;
  }

  command result_t FlashControl.start() {
    TOSH_SET_FLASH_CS_PIN();
    TOSH_MAKE_FLASH_CS_OUTPUT();
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    
    return SUCCESS;
  }

  command result_t FlashControl.stop() {
    return SUCCESS;
  }

  async command result_t FlashSelect.getBus() {
    if (call BusArbitration.getBus() == FAIL)
      return FAIL;
    TOSH_CLR_FLASH_CS_PIN();
    return SUCCESS;
  }

  async command result_t FlashSelect.releaseBus() {
    TOSH_SET_FLASH_CS_PIN();
    return call BusArbitration.releaseBus();
  }

  event result_t BusArbitration.busFree() {
    return signal FlashSelect.busFree();
  }

  // must use spi mode 0/3 for read buffer and read page but not for get status
#define FLASH_PAGE_READ_CMD 0xD2
#define FLASH_STATUS_READ_CMD 0x57
#define FLASH_PAGE_WRITE_ERASE_CMD 0x82
#define FLASH_PAGE_WRITE_CMD 0x88
#define FLASH_BUFFER_WRITE_CMD 0x84
#define FLASH_BUFFER_READ_CMD 0xD4

  uint8_t getStatus() {
    uint8_t spiIn = 0;
    atomic {
      call USARTControl.isTxIntrPending();
      call USARTControl.rx();
      call USARTControl.tx(FLASH_STATUS_READ_CMD);
      TOSH_uwait(20);
      // we need to tx a byte to twiddle the clock to do a read.
      TOSH_SEL_UCLK1_IOFUNC();
      TOSH_MAKE_UCLK1_OUTPUT();
      TOSH_SET_UCLK1_PIN();
      TOSH_uwait(1);
      TOSH_CLR_UCLK1_PIN();
      TOSH_SEL_UCLK1_MODFUNC();
      //call USARTControl.tx(0x24);
      call USARTControl.tx(0x00);
      spiIn = call USARTControl.rx();

    }
    return spiIn;
  }

  uint8_t getSPIByte() {
    uint8_t spiIn = 0;
    atomic {
      call USARTControl.isTxIntrPending();
      call USARTControl.rx();
      //call USARTControl.tx(0x99);
      call USARTControl.tx(0x00);
      TOSH_uwait(20);
      spiIn = call USARTControl.rx();
    }                              
    return spiIn;
  }

  
  async command uint8_t FlashSPI.txByte(uint8_t spiOut) {
    uint8_t spiIn = 0;
    atomic {
      call USARTControl.isTxIntrPending();
      call USARTControl.rx();
      call USARTControl.tx(spiOut);
      TOSH_uwait(20);
    }
    return spiIn;
  }

  // XXX we should worry about the status here ? or in the read write layer?
  command uint8_t ReadData.read(uint32_t offset, uint8_t* buffer, uint32_t numBytesRead) {
    int i;
    uint8_t res = 0x00;
    
    TOSH_CLR_FLASH_CS_PIN();
    

#if 1
    call FlashSPI.txByte(FLASH_PAGE_READ_CMD);
    for (i=0; i < 7; i++)
      call FlashSPI.txByte(0x00);

    for (i=0; i < numBytesRead; i++)
      buffer[i] = getSPIByte();
#else
    //try the buffer read/write
    call FlashSPI.txByte(FLASH_BUFFER_READ_CMD);
    for (i=0; i < 4; i++)
      call FlashSPI.txByte(0x00);

    for (i=0; i < numBytesRead; i++)
      buffer[i] = getSPIByte();
    
    
#endif
	
    TOSH_SET_FLASH_CS_PIN();
    
    return res;
    
  }


#define FLASH_RDY_BIT 0x80  
  command uint8_t WriteData.write(uint32_t offset, uint8_t* buffer, uint32_t numBytes) {
    int i;
    uint8_t res = 0x00;
    
    TOSH_CLR_FLASH_CS_PIN();
    

#if 1
    call FlashSPI.txByte(FLASH_PAGE_WRITE_ERASE_CMD);
    for (i=0; i < 3; i++)
      call FlashSPI.txByte(0x00);
    for (i=0; i< numBytes; i++)
      call FlashSPI.txByte(buffer[i]);
#else
    // try buffer read/write thingie
    call FlashSPI.txByte(FLASH_BUFFER_WRITE_CMD);
    for (i=0; i < 3; i++)
      call FlashSPI.txByte(0x00);
    for (i=0; i< numBytes; i++)
      call FlashSPI.txByte(buffer[i]);
    
#endif
    
    TOSH_SET_FLASH_CS_PIN();


#if 0
    while (!(res & FLASH_RDY_BIT))
      {
	TOSH_CLR_FLASH_CS_PIN();

	// now return the status
	res = getStatus();
	TOSH_SET_FLASH_CS_PIN();
      }
#endif
    
    return res;

    
  }
  

  default event result_t FlashSelect.busFree() {
    return SUCCESS;
  }



}
