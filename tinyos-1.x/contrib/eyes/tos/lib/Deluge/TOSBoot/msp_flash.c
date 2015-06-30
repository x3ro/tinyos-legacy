// $Id: msp_flash.c,v 1.2 2005/01/19 13:08:12 klueska Exp $

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
 * msp_flash.c
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

#include <stdint.h>
#include <io.h>
#include <bl_flash.h>

enum {
  IFLASH_BOUND_LOW  = 0x00,
  IFLASH_BOUND_HIGH = 0x7e,
  IFLASH_OFFSET     = 0x1000,
  IFLASH_SIZE       = 128,
  IFLASH_SEG0_VNUM_ADDR = 0x107f,
  IFLASH_SEG1_VNUM_ADDR = 0x10ff,
};

uint8_t chooseSegment() {
  uint8_t vnum0 = *(uint8_t*)IFLASH_SEG0_VNUM_ADDR;
  uint8_t vnum1 = *(uint8_t*)IFLASH_SEG1_VNUM_ADDR;
  if (vnum0 != 0xff && vnum1 != 0xff)
    return (vnum0 >= vnum1) ? 0 : 1;
  else if (vnum0 == 0 && vnum1 == 0xff)
    return 0;
  else if (vnum0 == 0xff && vnum1 == 0)
    return 1;
  return 0;
}

void eeprom_write_byte(volatile uint8_t *p, uint8_t value) {

  volatile uint8_t* addrPtr;
  uint8_t secToUpd = 0;
  uint16_t i;
  
  if ((uint16_t)p < IFLASH_BOUND_LOW || IFLASH_BOUND_HIGH < (uint16_t)p)
    return;

  if (chooseSegment() == 0) {
    p = (void*)((uint16_t)p + IFLASH_SIZE);
    secToUpd = 1;
  }
  p = (void*)((uint16_t)p + IFLASH_OFFSET);

  addrPtr = (uint8_t*)((uint16_t)p & ~0x7f);
  
  FCTL2 = FWKEY + FSSEL1 + FN2;
  FCTL3 = FWKEY;
  FCTL1 = FWKEY + ERASE;
  *addrPtr = 0;
  FCTL1 = FWKEY + WRT;
  for (i = 0; i < IFLASH_SIZE-1; i++) {
    if ((uint16_t)addrPtr != (uint16_t)p)
      *addrPtr = (secToUpd == 0) ? *(uint8_t*)((uint16_t)addrPtr + IFLASH_SIZE) 
	: *(uint8_t*)((uint16_t)addrPtr - IFLASH_SIZE);
    else
      *addrPtr = value;
    addrPtr++;
  }
  *addrPtr = (secToUpd == 0) ? (*(uint8_t*)IFLASH_SEG1_VNUM_ADDR)+1 : (*(uint8_t*)IFLASH_SEG0_VNUM_ADDR)+1;
  FCTL1 = FWKEY;
  FCTL3 = FWKEY + LOCK;

}

uint8_t eeprom_read_byte(uint8_t *p) {
  if (chooseSegment() == 1)
    p = (uint8_t*)((uint16_t)p + IFLASH_SIZE);
  p = (void*)((uint16_t)p + IFLASH_OFFSET);
  return *p;
}

uint16_t eeprom_read_word(uint16_t *p) {
  if (chooseSegment() == 1)
    p = (uint16_t*)((uint16_t)p + IFLASH_SIZE);
  p = (void*)((uint16_t)p + IFLASH_OFFSET);
  return *p;
}

void eeprom_write_page(void *buf, uint16_t pageBaseByteAddr, uint16_t length) {
  volatile uint16_t *flashAddr = (uint16_t*)pageBaseByteAddr;
  uint16_t *wordBuf = (uint16_t*)buf;
  uint16_t i = 0;
  
  FCTL2 = FWKEY + FSSEL1 + FN2;
  FCTL3 = FWKEY;
  FCTL1 = FWKEY + ERASE;
  *flashAddr = 0;
  FCTL1 = FWKEY + WRT;
  if (pageBaseByteAddr == (BL_MSP_RESET_ADDR/BL_INTERNAL_PAGE_SIZE)*BL_INTERNAL_PAGE_SIZE)
    *(uint16_t*)BL_MSP_RESET_ADDR = BOOTLOADER_START;
  for (i = 0; i < length / sizeof(uint16_t); i++) {
    if ((uint16_t)flashAddr != BL_MSP_RESET_ADDR)
      *flashAddr++ = wordBuf[i];
  }
  FCTL1 = FWKEY;
  FCTL3 = FWKEY + LOCK;
}
