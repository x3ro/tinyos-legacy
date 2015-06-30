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

/**
 * @file Flash.h 
 * @Author Josh Herbach
 * Revision:	1.0
 * Date	 09/02/2005
 *
 * This code is ported from the TinyOS repository.
 * ported by; Junaith Ahemed Shahabdeen.
 */
#ifndef __FLASH_H__
#define __FLASH_H__

#define DEBUG 0
#define ASSERT 0

#define FLASH_PARTITION_COUNT 16
#define FLASH_PARTITION_SIZE 0x200000

#define FLASH_STATE_READ_INACTIVE 0
#define FLASH_STATE_PROGRAM 1
#define FLASH_STATE_ERASE 2
#define FLASH_STATE_READ_ACTIVE 3


#define FLASH_BLOCK_COUNT 256
#define FLASH_BLOCK_SIZE 0x20000

#define FLASH_PARAM_BLOCK_SIZE 0x8000

#define FLASH_BLOCK_CLEAN 0
#define FLASH_BLOCK_USED 1


#define FLASH_PROGRAM_BUFFER_SIZE 32
#define FLASH_NOT_SUPPORTED 0x100

#define FLASH_NORMAL 0
#define FLASH_OVERWRITE 1

//anything below FLASH_PROTECTED_REGION will not be written/erased by FlashC
//#define FLASH_PROTECTED_REGION 0x00200000
#define FLASH_PROTECTED_REGION 0x20000

/**
 * FIXME
 * Temporary start address for copying the primary image
 */ 
//#define PRIMARY_IMAGE_ADDRESS 0x1C00000
//#define BOOT_IMAGE_ADDRESS 0x20000
//#define PRIMARY_IMAGE_ADDRESS 0x1800000


#endif
