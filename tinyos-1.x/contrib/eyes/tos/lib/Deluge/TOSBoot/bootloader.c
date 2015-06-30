// $Id: bootloader.c,v 1.4 2005/01/19 13:08:12 klueska Exp $

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
 * bootloader.c - Bootloader is now a self-contained executable. A
 * mica2 and mica2dot can be set to always boot into the bootloader
 * first, before invoking the application. This allows the user to
 * input a special gesture (i.e. reset the node 3 times quickly) to
 * load a golden image stored in flash onto the node.
 *
 * @author  Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since   0.1
 */

#include <bootloader.h>
#include <bl_functions.h>

#define SUCCESS 1
#define FAIL    0

void int2leds(uint8_t value) {
  if (value & 0x1) TOSH_SET_LED0_PIN();
  else TOSH_CLR_LED0_PIN();
  if (value & 0x2) TOSH_SET_LED1_PIN();
  else TOSH_CLR_LED1_PIN();
  if (value & 0x4) TOSH_SET_LED2_PIN();
  else TOSH_CLR_LED2_PIN();
  if (value & 0x8) TOSH_SET_LED3_PIN();
  else TOSH_CLR_LED3_PIN();  
}

void onDelaySequence() {
  uint8_t  output = 0xF;
  uint8_t  i;
  uint16_t j;

  int2leds(output);
  for (i = 0; i < 4; i++ ) {
    for (j = 1024; j > 0; j -= 4) {
      int2leds(output);
      TOSH_uwait(j);
      int2leds(output >> 0x1);
      TOSH_uwait(1024-j);
    }
    output >>= 0x1;
  }
}

void gestureNotify() {
  uint8_t output = 0xF;
  uint8_t i, j;
  
  for ( i = 0; i < 3; i++ ) {
    int2leds(output);
    for ( j = 0; j < 4; j++ )
      TOSH_uwait(0x7fff);
    int2leds(0x0);
    for ( j = 0; j < 4; j++ )
      TOSH_uwait(0x7fff);
  }
}

uint8_t SPIOutput(uint8_t spiOut) {
  if (spiOut & 0x80)
    TOSH_SET_FLASH_OUT_PIN();
  else
    TOSH_CLR_FLASH_OUT_PIN();	
  spiOut <<=1;
  return spiOut;
}

uint8_t SPIInput(uint8_t spiIn) {
  spiIn <<= 1;			
  if (TOSH_READ_FLASH_IN_PIN())
    spiIn |= 1;		
  return spiIn;
}

uint8_t SPIByte(uint8_t spiOut) {
  uint8_t spiIn = 0;
  uint8_t i;
  for (i = 0; i < 8; i++) {
    spiOut = SPIOutput(spiOut);
    TOSH_SET_FLASH_CLK_PIN();
    spiIn = SPIInput(spiIn);
    TOSH_CLR_FLASH_CLK_PIN();
  }
  return spiIn;
}

#if defined(PLATFORM_EYESIFX)
void eepromStartRead(uint16_t pageAddr) {
  uint8_t  cmdBuf[4];
  uint8_t  i;

  /* changes for eyesIFX platform  */
  cmdBuf[0] = 0x03;              // Flash read opcode
  cmdBuf[1] = 0x00;              // bits 16-23 always zero
  cmdBuf[2] = pageAddr >> 1;   
  if (pageAddr & 0x01)
    cmdBuf[3] = 0x80;
  else
    cmdBuf[3] = 0x00;

  TOSH_CLR_FLASH_CLK_PIN();
  TOSH_CLR_FLASH_SELECT_PIN();

  for(i = 0; i < 4; i++)
    SPIByte(cmdBuf[i]); // writeout the command
}
#else
void eepromStartRead(uint16_t pageAddr) {

  uint16_t byteAddr = 0;
  uint8_t  cmdBuf[4];
  uint8_t  i;

  cmdBuf[0] = 0x68;	                         // EE Flash opcode
  cmdBuf[1] = (pageAddr >> 7) & 0x0F;	         // pageAddr[10:7] in lower nibble
  cmdBuf[2] = (pageAddr << 1) + (byteAddr >> 8); // pageAddr[6:0]+ byteAddr[8]
  cmdBuf[3] = (uint8_t)byteAddr;		 // byteAddr[7:0]

  // select the flash
  TOSH_CLR_FLASH_CLK_PIN();
  TOSH_CLR_FLASH_SELECT_PIN();

  for(i = 0; i < 4; i++)
    SPIByte(cmdBuf[i]); // writeout the command
  for(i = 0; i < 4; i++)
    SPIByte(0x0);	// write out 4 fill bytes

  // Flash requires 1 additional (65th) clock to setup data on SOut pin
  TOSH_SET_FLASH_CLK_PIN();
  TOSH_CLR_FLASH_CLK_PIN();
}
#endif

void eepromStopRead() {
  TOSH_SET_FLASH_SELECT_PIN();
}

uint8_t eepromReadByte(uint32_t* externalAddr) {
  uint32_t tmpExternalAddr = *externalAddr;
  if (tmpExternalAddr % BL_EXTERNAL_PAGE_SIZE == 0) {
    eepromStopRead();
    eepromStartRead(tmpExternalAddr / BL_EXTERNAL_PAGE_SIZE);
  }
  *externalAddr = tmpExternalAddr + 1;
  return SPIByte(0);
}

void reboot() {
  ENABLE_WDT();
  while(1);
}

uint8_t programBuf(void *buf, uint32_t pageBaseByteAddr, uint16_t length) {

  uint16_t newImgAddr, oldImgAddr;

  if (((uint32_t)BOOTLOADER_START <= pageBaseByteAddr
       && pageBaseByteAddr <= (uint32_t)BOOTLOADER_END)
      || (pageBaseByteAddr < BL_ADDRESS_LOW)
      || (pageBaseByteAddr >= BL_ADDRESS_HIGH)){
    // trying to write into bootloader section, load golden image
    return FAIL;
  }

  newImgAddr = eeprom_read_word((uint16_t*)BL_NEW_IMG_START_PAGE_ADDR);
  oldImgAddr = eeprom_read_word((uint16_t*)BL_CUR_IMG_START_PAGE_ADDR);

  if (newImgAddr != oldImgAddr
      && oldImgAddr != 0xffff) {
    // invalidate current image address
    eeprom_write_byte((uint8_t*)(BL_CUR_IMG_START_PAGE_ADDR+0), 0xff);
    eeprom_write_byte((uint8_t*)(BL_CUR_IMG_START_PAGE_ADDR+1), 0xff);
    while(!eeprom_is_ready());
  }

  eeprom_write_page(buf, pageBaseByteAddr, length);

  return SUCCESS;

}

uint8_t programImg(uint32_t startPage) {

  uint8_t  buf[BL_INTERNAL_PAGE_SIZE];
  uint32_t pageAddr;
  uint32_t sectionLength;
  uint32_t internalAddr;
  uint32_t externalAddr;
  uint32_t i;

  externalAddr = startPage * BL_EXTERNAL_PAGE_SIZE;

  internalAddr = 0;
  for ( i = 0; i < 4; i++ )
    internalAddr |= ((uint32_t)eepromReadByte(&externalAddr) & 0xff) << (i*8);

  sectionLength = 0;
  for ( i = 0; i < 4; i++ )
    sectionLength |= ((uint32_t)eepromReadByte(&externalAddr) & 0xff) << (i*8);    

  while (sectionLength > 0) {
    for (i = 0; i < sectionLength; i++, internalAddr++) {
      if (i != 0 && internalAddr % BL_INTERNAL_PAGE_SIZE == 0) {
	pageAddr = (internalAddr / BL_INTERNAL_PAGE_SIZE) - ((uint32_t) 1);
	int2leds(pageAddr);
	if (programBuf(buf, pageAddr * BL_INTERNAL_PAGE_SIZE, BL_INTERNAL_PAGE_SIZE) == FAIL)
	  return FAIL;
      }

      buf[internalAddr % BL_INTERNAL_PAGE_SIZE] = eepromReadByte(&externalAddr);
    }

    pageAddr = internalAddr / BL_INTERNAL_PAGE_SIZE;
    if (internalAddr % BL_INTERNAL_PAGE_SIZE == 0)
      pageAddr--;

    if (programBuf(buf, pageAddr * BL_INTERNAL_PAGE_SIZE, BL_INTERNAL_PAGE_SIZE) == FAIL)
      return FAIL;

    internalAddr = 0;
    for ( i = 0; i < 4; i++ )
      internalAddr |= ((uint32_t)eepromReadByte(&externalAddr) & 0xff) << (i*8);

    sectionLength = 0;
    for ( i = 0; i < 4; i++ )
      sectionLength |= ((uint32_t)eepromReadByte(&externalAddr) & 0xff) << (i*8);
  }

  eepromStopRead();  

  return SUCCESS;

}

void incrementFlashWord(uint16_t* flashPtr) {
  uint16_t tmpCounter = eeprom_read_word(flashPtr);
  if (tmpCounter++ < 0xfffe) { 
    eeprom_write_byte((uint8_t*)((uint16_t)flashPtr+0), (tmpCounter>>0)&0xff);
    eeprom_write_byte((uint8_t*)((uint16_t)flashPtr+1), (tmpCounter>>8)&0xff);
    while(!eeprom_is_ready());
  }
}

void logResetEvent(uint8_t eventType) {
  uint16_t log = eeprom_read_word((uint16_t*)BL_RESET_HISTORY);
  log <<= BL_RESET_LOG_ENTRY_SIZE;
  log |= eventType & BL_RESET_LOG_ENTRY_MASK;
  eeprom_write_byte((uint8_t*)(BL_RESET_HISTORY+0), (log>>0)&0xff);
  eeprom_write_byte((uint8_t*)(BL_RESET_HISTORY+1), (log>>8)&0xff);
  while(!eeprom_is_ready());
}

void setProgFailFlag() {
  uint8_t tmp8 = eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR);
  tmp8 |= BL_PROGRAM_FAIL_FLAG;
  eeprom_write_byte((uint8_t*)BL_FLAGS_ADDR, tmp8);
  while(!eeprom_is_ready());
}

void startupSequence() {

  uint32_t newImgAddr, curImgAddr;
  uint8_t  loadImg;
  uint8_t  gestureCount;

  // get current value of counter
  gestureCount = eeprom_read_byte((uint8_t*)BL_GESTURE_COUNT_ADDR);
  gestureCount = (gestureCount==0xff) ? 0x1 : gestureCount+1;
  loadImg = eeprom_read_byte((uint8_t*)BL_LOAD_IMG_ADDR);

  if (gestureCount >= BL_GESTURE_MAX_COUNT) {
    if (loadImg != 0xff) {
      // reprogram attempt has failed, give up
      eeprom_write_byte((uint8_t*)BL_LOAD_IMG_ADDR, 0xff);
      while(!eeprom_is_ready());
      curImgAddr = eeprom_read_word((uint16_t*)BL_CUR_IMG_START_PAGE_ADDR);
      if (curImgAddr == 0xffff) {
	if (!(eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR) & BL_GOLDEN_IMG_LOADED)) {
	  // don't know what to do, flash LEDs continuously
	  for(;;) gestureNotify();
	}

	// current image has been compromised, load golden image
	eeprom_write_byte((uint8_t*)BL_GESTURE_COUNT_ADDR, BL_GESTURE_MAX_COUNT);    
	while(!eeprom_is_ready());
	reboot();
      }
      eeprom_write_byte((uint8_t*)BL_GESTURE_COUNT_ADDR, 0xff);
      while(!eeprom_is_ready());
    }
    else if (!(eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR) & BL_GOLDEN_IMG_LOADED)) {
      // gesture has been detected, display receipt of gesture on LEDs
      gestureNotify();
      // update new image start address
      eeprom_write_byte((uint8_t*)(BL_NEW_IMG_START_PAGE_ADDR+0), BL_GOLDEN_IMG_ADDR);
      eeprom_write_byte((uint8_t*)(BL_NEW_IMG_START_PAGE_ADDR+1), BL_GOLDEN_IMG_ADDR >> 8);
      while(!eeprom_is_ready());
      // load golden image from flash
      if (programImg(BL_GOLDEN_IMG_ADDR) == FAIL) {
	setProgFailFlag();
	reboot();
      }
      // update current image start address
      eeprom_write_byte((uint8_t*)(BL_CUR_IMG_START_PAGE_ADDR+0), BL_GOLDEN_IMG_ADDR);
      eeprom_write_byte((uint8_t*)(BL_CUR_IMG_START_PAGE_ADDR+1), BL_GOLDEN_IMG_ADDR >> 8);
      // clear gesture counter
      gestureCount = 0xff;
    }
  }

  // increment counter
  eeprom_write_byte((uint8_t*)BL_GESTURE_COUNT_ADDR, gestureCount);
  while(!eeprom_is_ready());

  if (loadImg != 0xff) {
    // get address of new program
    newImgAddr = eeprom_read_word((uint16_t*)BL_NEW_IMG_START_PAGE_ADDR);
    if (programImg(newImgAddr) == FAIL) {
      setProgFailFlag();
      reboot();
    }
    // update current image start address
    eeprom_write_byte((uint8_t*)(BL_CUR_IMG_START_PAGE_ADDR+0), newImgAddr);
    eeprom_write_byte((uint8_t*)(BL_CUR_IMG_START_PAGE_ADDR+1), newImgAddr >> 8);
    eeprom_write_byte((uint8_t*)BL_LOAD_IMG_ADDR, 0xff);
    // clear gesture counter
    eeprom_write_byte((uint8_t*)BL_GESTURE_COUNT_ADDR, 0xff);
    while(!eeprom_is_ready());
  }

  // give user some time and count down LEDs
  onDelaySequence();

  // no gesture detected, reset counter
  eeprom_write_byte((uint8_t*)BL_GESTURE_COUNT_ADDR, 0xff);
  while(!eeprom_is_ready());

  runApp();

}

inline void readResets() {

  uint16_t tmpCounter = 0x0;

  if (eeprom_read_word((uint16_t*)BL_RESET_HISTORY) == 0xffff) {
    eeprom_write_byte((uint8_t*)(BL_WDT_RESET_COUNTER+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_WDT_RESET_COUNTER+1), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_POWER_ON_RESET_COUNTER+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_POWER_ON_RESET_COUNTER+1), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_BROWN_OUT_RESET_COUNTER+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_BROWN_OUT_RESET_COUNTER+1), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_EXTERNAL_RESET_COUNTER+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_EXTERNAL_RESET_COUNTER+1), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_PROGRAM_FAIL_COUNTER+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_PROGRAM_FAIL_COUNTER+1), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_NETPROG_RESET_COUNTER+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_NETPROG_RESET_COUNTER+1), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_RESET_HISTORY+0), tmpCounter);
    eeprom_write_byte((uint8_t*)(BL_RESET_HISTORY+1), tmpCounter);
    while(!eeprom_is_ready());
  }

  // watchdog timer reset
  if (IS_WDT_RESET()) {
    incrementFlashWord((uint16_t*)BL_WDT_RESET_COUNTER);
    logResetEvent(BL_WDT_RESET);
  }
  // power on reset
  if (IS_POWER_ON_RESET()) {
    incrementFlashWord((uint16_t*)BL_POWER_ON_RESET_COUNTER);
    logResetEvent(BL_POWER_ON_RESET);
  }
  // brown out reset
  if (IS_BROWN_OUT_RESET()) {
    incrementFlashWord((uint16_t*)BL_BROWN_OUT_RESET_COUNTER);
    logResetEvent(BL_BROWN_OUT_RESET);
  }
  // external reset
  if (IS_EXTERNAL_RESET()) {
    incrementFlashWord((uint16_t*)BL_EXTERNAL_RESET_COUNTER);
    logResetEvent(BL_EXTERNAL_RESET);
  }
  // netprog reset
  if (IS_NETPROG_RESET()) {
    incrementFlashWord((uint16_t*)BL_NETPROG_RESET_COUNTER);
    logResetEvent(BL_NETPROG_RESET);
  }
  // program fail reset
  if (IS_PROG_FAIL_RESET()) {
    incrementFlashWord((uint16_t*)BL_PROGRAM_FAIL_COUNTER);
    logResetEvent(BL_PROGRAM_FAIL);
  }
  // program failure reset is handled at the site of the failure

  CLEAR_WDT_RESET_FLAG();
  CLEAR_POWER_ON_RESET_FLAG();
  CLEAR_BROWN_OUT_RESET_FLAG();
  CLEAR_EXTERNAL_RESET_FLAG();
  CLEAR_NETPROG_RESET_FLAG();
  CLEAR_PROG_FAIL_RESET_FLAG();

}

int main() {

  programBufPtr_t programBufPtr;
  uint32_t programBufAddr;
  uint16_t i;

  DISABLE_INTERRUPTS();
  DISABLE_WDT();
  TOSH_SET_PIN_DIRECTIONS();
  EXTRA_INIT();

  readResets();

  programBufPtr = programBuf;
  programBufAddr = (uint32_t)((uint16_t)programBufPtr);

  for ( i = 0; i < 4; i++ ) {
    uint8_t tmp;
    tmp = (programBufAddr >> (i*8)) & 0xff;
    if (tmp != eeprom_read_byte((uint8_t*)(BL_PROGRAM_BUF_ADDR+i)))
      eeprom_write_byte((uint8_t*)(BL_PROGRAM_BUF_ADDR+i), tmp);
  }

  startupSequence();

  return 0;

}
