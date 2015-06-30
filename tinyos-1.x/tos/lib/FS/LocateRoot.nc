// $Id: LocateRoot.nc,v 1.2 2003/10/07 21:46:18 idgay Exp $

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
module LocateRoot {
  provides interface IFileRoot;
  uses {
    interface IFileBlock;
    interface IFileBlock as ReadRoot;
    interface IFileBlockMeta as CheckRoot;
  }
#include "massert.h"
}
implementation {
  filemeta_t mV;
  fileblock_t block;
  uint8_t rootMarker;

  void locateRoot() { 
    call ReadRoot.read(block, IFS_OFFSET_METADATA,
		       &rootMarker, sizeof rootMarker);
  }

  void rootLocated() {
    if (signal IFileRoot.currentVersion() == 0) /* No matches in matchbox */
      signal IFileRoot.emptyMatchbox();
    else
      signal IFileRoot.located();
  }

  void locateNextBlock() {
    if (++block == IFS_NUM_PAGES)
      rootLocated();
    else
      locateRoot();
  }

  command void IFileRoot.locateRoot() {
    /* Read all blocks and locate the FS root */
    block = 0;
    signal IFileRoot.possibleRoot(0, 0); // Illegal version
    locateRoot();
  }

  event void ReadRoot.readDone(fileresult_t result) {
    if (result == FS_OK &&
	(rootMarker & ((1 << IFS_ROOT_MARKER_BITS) - 1)) == IFS_ROOT_MARKER)
      call IFileBlock.read(block, 0, &mV, sizeof mV);
    else
      locateNextBlock();
  }

  event void IFileBlock.readDone(fileresult_t result) {
    if (result == FS_OK && mV > signal IFileRoot.currentVersion())
      call CheckRoot.read(block, TRUE);
    else
      locateNextBlock();
  }

  event void CheckRoot.readDone(fileblock_t nextBlock,
				fileblockoffset_t lastByte,
				fileresult_t result) {
    if (result == FS_OK)
      signal IFileRoot.possibleRoot(block, mV);

    locateNextBlock();
  }

  event void IFileBlock.writeDone(fileresult_t result) {
    assert(0);
  }
  event void IFileBlock.syncDone(fileresult_t result) {
    assert(0);
  }
  event void IFileBlock.flushDone(fileresult_t result) {
    assert(0);
  }
  event void ReadRoot.writeDone(fileresult_t result) {
    assert(0);
  }
  event void ReadRoot.syncDone(fileresult_t result) {
    assert(0);
  }
  event void ReadRoot.flushDone(fileresult_t result) {
    assert(0);
  }
  event void CheckRoot.writeDone(fileresult_t result) {
    assert(0);
  }
}
