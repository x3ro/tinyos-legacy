 // $Id: HPLFlashM.nc,v 1.1 2005/07/29 18:29:31 adchristian Exp $

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
    interface Timer as TimerWrite;
    
  }
}

implementation {

  bool writeActive;
  uint16_t bytesWritten;
  
  
  
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
    //local state vars
    writeActive = FALSE;
    bytesWritten=0;    
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


#define BUFFER1 1
#define BUFFER2 2

#define PAGE_ADDR_BYTE1_MASK 0x0700
#define PAGE_ADDR_BYTE2_MASK 0x00fe

#define PAGE_ADDR_BYTE1(addr) (((( ((addr/PAGE_SIZE)<<1)  & PAGE_ADDR_BYTE1_MASK)) >> 8) & 0xff )
#define PAGE_ADDR_BYTE2(addr) ((( ((addr/PAGE_SIZE)<<1)  & PAGE_ADDR_BYTE2_MASK)) & 0xff )

#define BUFFER_ADDR_BYTE1_MASK 0x0100
#define BUFFER_ADDR_BYTE2_MASK 0x00ff
  
#define BUFFER_ADDR_BYTE1(addr) ((( (addr%PAGE_SIZE)  & BUFFER_ADDR_BYTE1_MASK) >> 8) & 0xff)
#define BUFFER_ADDR_BYTE2(addr) ((( (addr%PAGE_SIZE)  & BUFFER_ADDR_BYTE2_MASK) >> 0) & 0xff)
  
  // must use spi mode 0/3 for read buffer and read page but not for get status
  enum FlashCommands 
    {
      FLASH_STATUS_READ_CMD = 0x57,
      FLASH_CONTINUOUS_READ_CMD = 0xE8, // crosses page boundaries
      FLASH_PAGE_READ_CMD = 0xD2,
      FLASH_PAGE_WRITE_BUFFER1_ERASE_CMD = 0x82,
      FLASH_PAGE_WRITE_BUFFER2_ERASE_CMD = 0x85,
      FLASH_BUFFER1_WRITE_CMD = 0x84,
      FLASH_BUFFER1_READ_CMD = 0xD4,
      FLASH_BUFFER2_WRITE_CMD = 0x87,
      FLASH_BUFFER2_READ_CMD = 0xD6,
      FLASH_BUFFER1_READ_TRANSFER_CMD = 0x53,
      FLASH_BUFFER2_READ_TRANSFER_CMD = 0x55,
      FLASH_BUFFER1_WRITE_TRANSFER_CMD = 0x83,
      FLASH_BUFFER2_WRITE_TRANSFER_CMD = 0x86,
    };
  
  
      
      

  

  // our flash atmel 2 megabit AT45DB021B
#define PAGE_SIZE 264
#define NUM_PAGES 1024


  
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

  void loadPageIntoBuffer(int bufferNo,uint32_t addr)
    {
      uint8_t byte;
      
      //XXX need bus grab stuff here
      

      
	
      TOSH_CLR_FLASH_CS_PIN();

      if (bufferNo == BUFFER1)
	call FlashSPI.txByte(FLASH_BUFFER1_READ_TRANSFER_CMD);
      else 
	call FlashSPI.txByte(FLASH_BUFFER2_READ_TRANSFER_CMD);


      // mem to buffer transfer takes 5 0 bits,P10-P8
      // then P7-P0 + 1 0bit
      // then 1 0 byte
      byte = PAGE_ADDR_BYTE1(addr);
      call FlashSPI.txByte(byte);


      byte = PAGE_ADDR_BYTE2(addr);
      call FlashSPI.txByte(byte);

      byte = 0x00;
      call FlashSPI.txByte(byte);

      TOSH_SET_FLASH_CS_PIN();
      TOSH_uwait(400);
      
    }
  
  
  // XXX we should worry about the status here ? or in the read write layer?
  command uint16_t ReadData.read(uint32_t addr, uint8_t* buffer, uint32_t numBytesToRead) {
    int i;
    uint8_t res = 0x00;
    uint8_t byte;

    
    //XXX need bus grab stuff here
    
    TOSH_CLR_FLASH_CS_PIN();
    


    // this one needs
    // page address byte 1 & 2 followed by buffer address byte 1 & 2
    // followed by 4 bytes of nothing
    call FlashSPI.txByte(FLASH_CONTINUOUS_READ_CMD);

    byte = PAGE_ADDR_BYTE1(addr);    
    call FlashSPI.txByte(byte);

    byte = PAGE_ADDR_BYTE2(addr);    
    byte |= BUFFER_ADDR_BYTE1(addr);
    call FlashSPI.txByte(byte);

    byte = BUFFER_ADDR_BYTE2(addr);
    call FlashSPI.txByte(byte);
    // initiates the reads.
    for (i=0; i < 4; i++)
      call FlashSPI.txByte(0x00);

    for (i=0; i < numBytesToRead; i++)
      buffer[i] = getSPIByte();

    TOSH_SET_FLASH_CS_PIN();
    
    return res;
    
  }


#define FLASH_RDY_BIT 0x80  
  command uint16_t WriteData.write(uint32_t offset, uint8_t* buffer, uint32_t numBytes) {
    int i;
    uint32_t start_addr,end_addr;
    bool quickWrite=FALSE; // can we do a write w/out reading the values into the biffer first
    uint8_t byte;
    
    
    if (writeActive)
      return FAIL;    
    // XXX need this code to work with the radio try to grab the bus first



    /* ok coupla cases:
     * 1) start addr > page bdry and end addr < page+1 bdry --> suck page into buf, copy our part in, start write cycle and return set bytesWritten to numBytes
     * 2) start addr > page bdry and end addr >= page+1 bdry --> suck page into buf, copy our part in, start write cycle and return set bytesWritten to page+1bdry-start_addr
     * 3) start addr = page bdry and end addr < page+1 bdry --> suck page into buf, copy our part in, start write cycle and return set bytesWritten to numBytes
     * 4) start addr = page bdry and end addr >= page+1 bdry --> copy our part into buf, start write cycle and return set bytesWritten to PAGE_SIZE !! no suck in
     * ideally, the first write of a big chunk will self align and then go quickly after that
     */

    writeActive = TRUE;
    start_addr = offset;
    end_addr = start_addr + numBytes;

    
    
    if (!(start_addr%PAGE_SIZE)){
      // we are starting page aligned
      if (end_addr >= (start_addr+PAGE_SIZE))
	quickWrite = TRUE;
    }

    if (end_addr > ((start_addr/PAGE_SIZE)*PAGE_SIZE + PAGE_SIZE)){
      end_addr = (start_addr/PAGE_SIZE)*PAGE_SIZE + PAGE_SIZE; // i.e. the end of the current page
    }
    
    bytesWritten = end_addr - start_addr;

      
    // we need to read in from the buffer
    if (!quickWrite){
      loadPageIntoBuffer(BUFFER1,start_addr);
    }
    
    TOSH_CLR_FLASH_CS_PIN();
    // now write our data into the buffer
    call FlashSPI.txByte(FLASH_BUFFER1_WRITE_CMD);

    // the buffer write command needs 1 byte 0x00
    // 1 byte 7 0's and 1 buffer addr byte
    // 1 byte buffer addr
    byte = 0x00;
    call FlashSPI.txByte(byte);
    byte = BUFFER_ADDR_BYTE1(start_addr);    
    call FlashSPI.txByte(byte);
    byte = BUFFER_ADDR_BYTE2(start_addr);
    call FlashSPI.txByte(byte);

    for (i=0; i< bytesWritten; i++)
      call FlashSPI.txByte(buffer[i]);

    TOSH_SET_FLASH_CS_PIN();

    TOSH_uwait(20);

    // now we need to force the buffer into the flash
    TOSH_CLR_FLASH_CS_PIN();
    call FlashSPI.txByte(FLASH_BUFFER1_WRITE_TRANSFER_CMD);

    byte = PAGE_ADDR_BYTE1(start_addr);
    call FlashSPI.txByte(byte);

    byte = PAGE_ADDR_BYTE2(start_addr);
    call FlashSPI.txByte(byte);

    byte = 0x00;
    call FlashSPI.txByte(byte);

    TOSH_SET_FLASH_CS_PIN();
    call TimerWrite.start(TIMER_ONE_SHOT, 25);
    
    return bytesWritten;

    
  }
  

  default event result_t FlashSelect.busFree() {
    return SUCCESS;
  }


  task void checkWriteComplete()
    {
      uint8_t res = 0x00;

      // XXX grab the bus

      TOSH_CLR_FLASH_CS_PIN();

      // now return the status
      res = getStatus();
      TOSH_SET_FLASH_CS_PIN();

      if (res & FLASH_RDY_BIT){
	// our flash write is done
	writeActive = FALSE;
	// no data needed right now
	signal WriteData.writeDone(NULL,0,SUCCESS);
      }
      else{
	// flash write still pending
	call TimerWrite.start(TIMER_ONE_SHOT, 10);
      }
    }
  

  /**
   * when write timer fires, sched a task to check the state of the spi write and signal if done or restart the timer if not done
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t TimerWrite.fired()
  {
    post checkWriteComplete();
    
    return SUCCESS;
  }


}
