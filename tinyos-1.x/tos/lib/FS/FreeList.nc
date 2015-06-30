// $Id: FreeList.nc,v 1.2 2003/10/07 21:46:18 idgay Exp $

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
includes IFS;
module FreeList {
  provides {
    interface StdControl;
    interface IFileFree;
  }
#include "massert.h"
}
implementation {
  fileblock_t nFreeBlocks, freePtr, reserved;
  uint8_t usedBlocks[IFS_NUM_PAGES / 8];

  command result_t StdControl.init() {
    call IFileFree.freeall();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void IFileFree.freeall() {
    nFreeBlocks = IFS_NUM_PAGES;
    reserved = 0;
    memset(usedBlocks, 0, sizeof usedBlocks);
  }

  command fileblock_t IFileFree.nFreeBlocks() {
    return nFreeBlocks - reserved;
  }

  command void IFileFree.setReserved(fileblock_t n) {
    assert(n <= nFreeBlocks);
    reserved = n;
  }

  uint8_t inuse(fileblock_t n) {
    return usedBlocks[n >> 3] & (1 << (n & 7));
  }

  command fileblock_t IFileFree.allocate() {
    fileblock_t i = freePtr;

    assert(nFreeBlocks > 0);
    assert(freePtr < IFS_NUM_PAGES);
    /* Return 1st free page after freePtr */
    for (;;)
      {
	if (++i >= IFS_NUM_PAGES)
	  i = 0;

	if (!inuse(i))
	  {
	    call IFileFree.reserve(i);
	    freePtr = i;
	    return i;
	  }
      }
  }

  command void IFileFree.free(fileblock_t n) {
    assert(inuse(n));
    nFreeBlocks++;
    usedBlocks[n >> 3] &= ~(1 << (n & 7));
  }

  command void IFileFree.setFreePtr(fileblock_t n) {
    assert(n < IFS_NUM_PAGES);
    freePtr = n;
  }

  command void IFileFree.reserve(fileblock_t n) {
    assert(!inuse(n));
    usedBlocks[n >> 3] |= (1 << (n & 7));
    nFreeBlocks--;
  }

  command bool IFileFree.inuse(fileblock_t n) {
    return n >= IFS_NUM_PAGES || inuse(n) != 0;
  }
}
