/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * Wrapper for the M25P05 ST Microelectronics.
 * The chip has no accessible buffers, so pages are always
 * synchronized/flushed. Only sectors can be erased. Each (of the two) sectors
 * holds 256 pages, i.e. single pages cannot be erased.
 */
/* - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/03/21 15:24:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */  
includes crc;
includes PageEEPROM;
module PageEEPROMM {
  provides {
    interface StdControl;
    interface PageEEPROM;
    interface FlashM25P05;
  }
  uses {
    interface StdControl as FlashControl;
    interface BusArbitration as SPIBus;
    interface FlashCommand;
    interface Leds;
  }
}
implementation
{  
  #define CHECKARGS 1
  enum { // Instruction Set for External Flash (M25P05)
    WREN = 0x06,  /* write enable */
    WRDI = 0x04,  /* write disable */
    RDSR = 0x05,  /* read SR */
    WRSR = 0x01,  /* write SR */
    READ = 0x03,  /* read data bytes */
    PP   = 0x02,  /* page program */
    SE   = 0xD8,  /* sector erase */
    BE   = 0xC7,  /* bulk erase */
    DP   = 0xB9,  /* deep power down */
    RES  = 0xAB   /* release from deep power down */
  };
  
  enum {
    CMD_IDLE,
    CMD_WRITE_EXTERNAL,
    CMD_READ_EXTERNAL,
    CMD_ERASE_EXTERNAL_ALL,
    CMD_ERASE_EXTERNAL_SECTOR0,
    CMD_ERASE_EXTERNAL_SECTOR1,
    CMD_READCRC_EXTERNAL,
  };
  
  enum {  // M25P05 status register flags
    SR_WIP = 0x01,
    SR_WEL = 0x02,
    SR_BP0 = 0x04,
    SR_BP1 = 0x08,
    SR_SRWD = 0x10
  };

  struct {
    uint8_t addressMSB;
    uint8_t addressLSB;
    void *data;
    eeprompageoffset_t n;
    uint8_t cmd;
    bool pending;           
  } flashCmd;
  
  uint16_t computedCrc;
  bool wip;
    
  enum { // requests
    R_READ,
    R_READCRC,
    R_WRITE,
    R_ERASE,
    R_ERASE_ALL,
    R_ERASE_SECTOR0,
    R_ERASE_SECTOR1,
  };
  
  void requestDone();
  task void executeFlashCommand();

  command result_t StdControl.init() {
    wip = FALSE;
    flashCmd.pending = FALSE;
    flashCmd.cmd = CMD_IDLE;
    return call FlashControl.init();
  }
  
  command result_t StdControl.start() {
    return call FlashControl.start();
  }

  command result_t StdControl.stop() {
    return call FlashControl.stop();
  }
       
  task void executeFlashCommand() 
  {
    uint16_t i;
    uint16_t crc = 0;
    uint8_t data;
    uint8_t status;
                 
    if (call SPIBus.getBus() == FAIL)
      return; // SPIBus.busReleased() will re-post this task
    
    // check for write in progress
    if (wip) {
      call FlashCommand.beginCommand();
      call FlashCommand.txByte(RDSR);
      status = call FlashCommand.rxByte(0x00);
      call FlashCommand.endCommand();
      if (status & SR_WIP){ // flash is busy, retry later
        call SPIBus.releaseBus();
        return;
      }
    }
  
    flashCmd.pending = FALSE;
    wip = TRUE;
     
    // write enable sequence for write/erase commands
    if (flashCmd.cmd != CMD_READ_EXTERNAL || flashCmd.cmd != CMD_READCRC_EXTERNAL){
      call FlashCommand.beginCommand();
      call FlashCommand.txByte(WREN);
      call FlashCommand.endCommand();
    }
    
    // send actual command to flash
    call FlashCommand.beginCommand();
    switch (flashCmd.cmd)
    {
      case CMD_WRITE_EXTERNAL: call FlashCommand.txByte(PP); break;
      case CMD_READ_EXTERNAL: call FlashCommand.txByte(READ); break;
      case CMD_READCRC_EXTERNAL: call FlashCommand.txByte(READ); break;
      case CMD_ERASE_EXTERNAL_ALL: call FlashCommand.txByte(BE); break;
      case CMD_ERASE_EXTERNAL_SECTOR0: call FlashCommand.txByte(SE); break;
      case CMD_ERASE_EXTERNAL_SECTOR1: call FlashCommand.txByte(SE); break;
    }
    
    if (flashCmd.cmd != CMD_ERASE_EXTERNAL_ALL){
      call FlashCommand.txByte(0x00);
      call FlashCommand.txByte(flashCmd.addressMSB);
      call FlashCommand.txByte(flashCmd.addressLSB);
    }
    
    switch (flashCmd.cmd)
    {
      case CMD_WRITE_EXTERNAL:
        for (i=0; i<flashCmd.n; i++)
          call FlashCommand.txByte(*((uint8_t*) flashCmd.data + i));
        break;
      case CMD_READ_EXTERNAL:
        for (i=0; i<flashCmd.n; i++)
          *((uint8_t*) flashCmd.data + i) = call FlashCommand.rxByte(0);
        break;
      case CMD_READCRC_EXTERNAL:
        for (i=0; i<flashCmd.n; i++){
          data = call FlashCommand.rxByte(0);
          crc = crcByte(crc, data);
        }
        computedCrc = crc;
        break;
      default:
        break;
    }
    call FlashCommand.endCommand();
    call SPIBus.releaseBus();
  }
  
  event result_t SPIBus.busReleased() 
  {
    if (flashCmd.pending == TRUE)
      post executeFlashCommand();
    else if(flashCmd.cmd != CMD_IDLE)
      requestDone();
    return SUCCESS;
  }
  
  event result_t SPIBus.busRequested()
  {
    return SUCCESS;
  }
  
  result_t newRequest(uint8_t req, eeprompage_t page, eeprompageoffset_t offset,
                      void *reqdata, eeprompageoffset_t n) 
  {
    #if CHECKARGS
    if (page >= TOS_EEPROM_MAX_PAGES || offset >= TOS_EEPROM_PAGE_SIZE ||
        (req == R_WRITE && offset + n > TOS_EEPROM_PAGE_SIZE))
      return FAIL;
    #endif
    
    if (flashCmd.cmd == CMD_IDLE){
      flashCmd.pending = TRUE;
      flashCmd.addressMSB = (uint8_t) (page >> 1);
      flashCmd.addressLSB = offset;
      if (page & 1)
        flashCmd.addressLSB |= 0x80;
      flashCmd.data = reqdata;
      flashCmd.n = n;
      switch (req)
      {
        case R_READ:    flashCmd.cmd = CMD_READ_EXTERNAL; break;
        case R_READCRC: flashCmd.cmd = CMD_READCRC_EXTERNAL; break; 
        case R_WRITE:   flashCmd.cmd = CMD_WRITE_EXTERNAL; break;
        case R_ERASE_ALL: flashCmd.cmd = CMD_ERASE_EXTERNAL_ALL; break;
        case R_ERASE_SECTOR0: flashCmd.cmd = CMD_ERASE_EXTERNAL_SECTOR0; break;
        case R_ERASE_SECTOR1: flashCmd.cmd = CMD_ERASE_EXTERNAL_SECTOR1; break;
      }
      post executeFlashCommand();
      return SUCCESS;
    }
    return FAIL;
  }
        
  
  command result_t PageEEPROM.write(eeprompage_t page, eeprompageoffset_t offset,
                                    void *data, eeprompageoffset_t n)
  {
    return newRequest(R_WRITE, page, offset, data, n);
  }
  
  command result_t PageEEPROM.erase(eeprompage_t page, uint8_t eraseKind)
  {  
    return FAIL;
  }

  command result_t PageEEPROM.read(eeprompage_t page, eeprompageoffset_t offset,
                        void *data, eeprompageoffset_t n)
  {
    return newRequest(R_READ, page, offset, data, n);
  }

  command result_t PageEEPROM.computeCrc(eeprompage_t page, eeprompageoffset_t offset,
                              eeprompageoffset_t n)
  {
    return newRequest(R_READCRC, page, offset, NULL, n);
  }
  
  command result_t FlashM25P05.eraseAll()
  {
    return newRequest(R_ERASE_ALL, 0, 0, NULL, 0);
  }
    
  command result_t FlashM25P05.eraseSector(uint8_t sector)
  {
    if (sector == 0)
      return newRequest(R_ERASE_SECTOR0, 0, 0x00, NULL, 0);
    else if (sector == 1)
      return newRequest(R_ERASE_SECTOR1, TOS_EEPROM_MAX_PAGES-1, 0x00, NULL, 0);
    return FAIL;
  }
  
  void requestDone() {
    volatile uint8_t oldCmd = flashCmd.cmd ;

    flashCmd.cmd = CMD_IDLE;
    switch (oldCmd)
    {
      case CMD_READ_EXTERNAL:
        wip = FALSE;
        signal PageEEPROM.readDone(SUCCESS); 
        break;
      case CMD_READCRC_EXTERNAL: 
        wip = FALSE;
        signal PageEEPROM.computeCrcDone(SUCCESS, computedCrc); 
        break;
      case CMD_WRITE_EXTERNAL:
        signal PageEEPROM.writeDone(SUCCESS); 
        break;
      case CMD_ERASE_EXTERNAL_ALL: 
        signal FlashM25P05.eraseAllDone(); break;
      case CMD_ERASE_EXTERNAL_SECTOR0: 
        signal FlashM25P05.eraseSectorDone(0); break;
      case CMD_ERASE_EXTERNAL_SECTOR1:
        signal FlashM25P05.eraseSectorDone(1); break;
      default: break;
    }
  } 
    
  command result_t PageEEPROM.sync(eeprompage_t page) { signal PageEEPROM.syncDone(SUCCESS); return SUCCESS; }
  command result_t PageEEPROM.syncAll() { signal PageEEPROM.syncDone(SUCCESS); return SUCCESS; }
  command result_t PageEEPROM.flushAll() { signal PageEEPROM.flushDone(SUCCESS); return SUCCESS; }
  command result_t PageEEPROM.flush(eeprompage_t page) { signal PageEEPROM.flushDone(SUCCESS); return SUCCESS; }

  default event result_t FlashM25P05.eraseSectorDone(uint8_t sector){ return SUCCESS; }
  default event result_t FlashM25P05.eraseAllDone(){ return SUCCESS; }
}
