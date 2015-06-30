// $Id: RFreeList.nc,v 1.1.1.1 2007/11/05 19:09:14 jpolastre Exp $

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
// A free list for read-only filing systems
includes IFS;
module RFreeList {
  provides {
    interface StdControl;
    interface IFileFree;
  }
#include "massert.h"
}
implementation {
  fileblock_t nFreeBlocks, freePtr, reserved;

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
  }

  command fileblock_t IFileFree.nFreeBlocks() {
    return nFreeBlocks - reserved;
  }

  command void IFileFree.setReserved(fileblock_t n) {
    assert(n <= nFreeBlocks);
    reserved = n;
  }

  command fileblock_t IFileFree.allocate() {
    return 0;
  }

  command void IFileFree.free(fileblock_t n) {
    // Should never be called
  }

  command void IFileFree.setFreePtr(fileblock_t n) {
    assert(n < IFS_NUM_PAGES);
    freePtr = n;
  }

  command void IFileFree.reserve(fileblock_t n) {
    nFreeBlocks--;
  }

  command bool IFileFree.inuse(fileblock_t n) {
    // We say everything is free to keep ScanFS happy
    return n >= IFS_NUM_PAGES;
  }
}