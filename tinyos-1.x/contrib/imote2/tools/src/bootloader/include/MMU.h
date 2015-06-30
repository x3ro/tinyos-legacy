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
 * @file MMU.h
 * @author 
 * 
 * Ported By: Junaith Ahemed Shahabdeen
 * 
 * This file is ported from the TinyOS repository. The file
 * contains functions that are required to handle 
 * MMU and Cache (ICache and DCache).
 *  
 */
#ifndef __MMU_H__
#define __MMU_H__

void initSyncFlash();

/**
 * initMMU
 * 
 * The function which is implemented in util.s performs
 * the following tasks.
 *
 * 1. Enable Read/Write permission for Domain 0 in the
 *    CP15 Domain Register 3.
 * 2. Set Translation Table Base Register with the MMU
 *    table address. MMU Table is defined in mmu_table.s
 *    which enables C, B bits for flash partition 1 (where
 *    the boot loader code is located), SRAM and the 
 *    register addresses.
 * 3. Sets MMU enable bit (1st bit) in the Control and
 *    Auxiliary control registers (CP15 register 1) to
 *    enable MMU. 
 */
void initMMU();

/**
 * enableICache
 *
 * The function which is implemented in util.s performs
 * the following
 *
 * 1. Unlocks the ICache and Itlb.
 * 2. Invalidates ICache, BTB, and Itlb.
 * 3. Enable Icache and BTB in the CP15 register1. 
 */
void enableICache();

/**
 * enableDCache
 *
 * The function is implemented in util.s.
 *
 * 1. Unlocks Dtlb and DCache.
 * 2. Invalidata DCache, mini-dcache and DTlb.
 * 3. Enable dcache in the CP15 register1.
 */
void enableDCache();

/**
 * disableDCache
 * 
 * The function cleans the entire data cache to restore the dirty
 * bits and invalidates the cache before disabling it.
 */
void disableDCache();

/**
 * invalidateDCache
 * 
 * The function invalidates the DCache for the given buffer.
 * @param address Virtual address to evict.
 * @param numbytes Size of the buffer.
 */
void invalidateDCache(uint8_t *address, int32_t numbytes); 

/**
 * cleanDCache
 *
 */
void cleanDCache(uint8_t *address, int32_t numbytes); 

/**
 *
 */
void globalCleanAndInvalidateDCache();

#endif
