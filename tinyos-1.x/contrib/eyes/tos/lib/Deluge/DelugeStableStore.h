// $Id: DelugeStableStore.h,v 1.3 2005/01/25 18:08:53 klueska Exp $

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
 * Provides stable storage services to Deluge.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __DELUGE_STABLE_STORE_H__
#define __DELGUE_STABLE_STORE_H__

enum {
  DELUGE_GOLDEN_IMAGE_NUM = DELUGE_INVALID_IMGNUM-1,
};

#if defined(PLATFORM_EYESIFX)
#define DELUGE_FLASH_PAGE_SIZE        ((uint32_t)(0x1 << (TOS_EEPROM_PAGE_SIZE_LOG2))-2)
#define DELUGE_GOLDEN_IMAGE_SIZE      ((uint32_t)32*(uint32_t)1024)
#define DELUGE_GOLDEN_IMAGE_PAGE      ((uint32_t)0)
#define DELUGE_FLASH_METADATA_PAGE    ((uint32_t)((DELUGE_GOLDEN_IMAGE_PAGE+DELUGE_GOLDEN_IMAGE_SIZE)/(DELUGE_FLASH_PAGE_SIZE))+1)

#else
#define DELUGE_FLASH_PAGE_SIZE        ((uint32_t)(0x1 << TOS_EEPROM_PAGE_SIZE_LOG2))
#define DELUGE_GOLDEN_IMAGE_SIZE      ((uint32_t)64*(uint32_t)1024)
#define DELUGE_GOLDEN_IMAGE_PAGE      ((uint32_t)0)
#define DELUGE_FLASH_METADATA_PAGE    ((DELUGE_GOLDEN_IMAGE_PAGE+DELUGE_GOLDEN_IMAGE_SIZE)/DELUGE_FLASH_PAGE_SIZE)

#endif
#endif
