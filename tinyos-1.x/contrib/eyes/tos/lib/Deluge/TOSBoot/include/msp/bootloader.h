// $Id: bootloader.h,v 1.4 2005/01/25 18:11:24 klueska Exp $

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
 * bootloader.h - For msp platform.
 *
 * @author  Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since   0.1
 */

#ifndef __MSP_BOOTLOADER_H__
#define __MSP_BOOTLOADER_H__

#include <sys/inttypes.h>

typedef uint8_t (*programBufPtr_t)(void*, uint32_t, uint16_t);
typedef uint8_t (*programImgPtr_t)(uint32_t);

// changes for eyesIFX
#if defined(PLATFORM_EYESIFX)
#define BL_EXTERNAL_PAGE_SIZE  ((uint32_t)126)
#else
#define BL_EXTERNAL_PAGE_SIZE  ((uint32_t)256)
#endif

#define BL_GOLDEN_IMG_ADDR     ((uint32_t)0)
#define BL_GESTURE_MAX_COUNT   5

#define IS_WDT_RESET()				\
  ((IFG1&WDTIFG) && (!IS_NETPROG_RESET()))
#define IS_POWER_ON_RESET()				\
  (!(IFG1&WDTIFG) && !(IFG1&OFIFG) && !(FCTL3&ACCVIFG) && !(IS_NETPROG_RESET()) && !(IS_PROG_FAIL_RESET()))
#define IS_BROWN_OUT_RESET()			\
  0
#define IS_EXTERNAL_RESET()			\
  0
#define IS_NETPROG_RESET()						\
  (eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR) & BL_EXPLICIT_REBOOT)
#define IS_PROG_FAIL_RESET()						\
  (eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR) & BL_PROGRAM_FAIL_FLAG)

#define CLEAR_WDT_RESET_FLAG()			\
  IFG1 &= ~WDTIFG
#define CLEAR_POWER_ON_RESET_FLAG()		\
  ;
#define CLEAR_BROWN_OUT_RESET_FLAG()		\
  ;
#define CLEAR_EXTERNAL_RESET_FLAG()		\
  ;
#define CLEAR_NETPROG_RESET_FLAG()				\
  {								\
    uint8_t tmp = eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR);	\
    tmp &= ~BL_EXPLICIT_REBOOT;					\
    eeprom_write_byte((uint8_t*)BL_FLAGS_ADDR, tmp);		\
    while(!eeprom_is_ready());					\
  }
#define CLEAR_PROG_FAIL_RESET_FLAG()				\
  {								\
    uint8_t tmp = eeprom_read_byte((uint8_t*)BL_FLAGS_ADDR);	\
    tmp &= ~BL_PROGRAM_FAIL_FLAG;				\
    eeprom_write_byte((uint8_t*)BL_FLAGS_ADDR, tmp);		\
    while(!eeprom_is_ready());					\
  }

#define BL_RESET_LOG_ENTRY_SIZE 3 // in bits
#define BL_RESET_LOG_ENTRY_MASK 7

enum {
  BL_NULL_ENTRY_RESET = 0,
  BL_WDT_RESET = 1, 
  BL_EXTERNAL_RESET = 2,
  BL_POWER_ON_RESET = 3,
  BL_BROWN_OUT_RESET = 4,
  BL_PROGRAM_FAIL = 5,
  BL_NETPROG_RESET = 6,
};

enum {
  BL_GOLDEN_IMG_LOADED = 1,
  BL_EXPLICIT_REBOOT = 2,
  BL_PROGRAM_FAIL_FLAG = 4,
};

// reset counters

#define BL_WDT_RESET_COUNTER          0x60 // 2 bytes
#define BL_EXTERNAL_RESET_COUNTER     0x62 // 2 bytes
#define BL_POWER_ON_RESET_COUNTER     0x64 // 2 bytes
#define BL_BROWN_OUT_RESET_COUNTER    0x66 // 2 bytes
#define BL_PROGRAM_FAIL_COUNTER       0x68 // 2 bytes
#define BL_NETPROG_RESET_COUNTER      0x6A // 2 bytes
#define BL_RESET_HISTORY              0x6C // 2 bytes

// bootloader state

#define BL_LOAD_IMG_ADDR              0x70 // 1 byte
#define BL_GESTURE_COUNT_ADDR         0x71 // 1 byte
#define BL_NEW_IMG_START_PAGE_ADDR    0x72 // 2 bytes
#define BL_CUR_IMG_START_PAGE_ADDR    0x74 // 2 bytes
#define BL_PROGRAM_BUF_ADDR           0x76 // 4 bytes

#define BL_FLAGS_ADDR                 0x7e // 1 byte

#endif
