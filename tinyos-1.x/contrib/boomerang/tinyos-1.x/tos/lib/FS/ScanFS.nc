// $Id: ScanFS.nc,v 1.1.1.1 2007/11/05 19:09:14 jpolastre Exp $

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
module ScanFS {
  provides {
    interface IFileScan;
    event void newBlockRead(fileblock_t block);
  }
  uses {
    interface IFileFree;
    interface IFileMetaRead;
    interface IFileBlockMeta;
  }
#include "massert.h"
}
implementation {
  fileblock_t fileBlock;

  void scanned(fileresult_t result) {
    fileBlock = IFS_EOF_BLOCK;
    signal IFileScan.scanned(result);
  }

  command void IFileScan.scanFS(fileblock_t root) {
    call IFileFree.setFreePtr(root);
    call IFileFree.reserve(root);
    call IFileMetaRead.read();
    call IFileMetaRead.readNext();
  }

  event void newBlockRead(fileblock_t block) {
    if (fileBlock != IFS_EOF_BLOCK && block != IFS_EOF_BLOCK)
      {
	// This is a metadata block. Reserve it
	if (call IFileFree.inuse(block))
	  // Yuck. Let nextFile know we have a problem.
	  fileBlock = IFS_EOF_BLOCK;
	else
	  call IFileFree.reserve(block);
      }
  }

  void scanFile(fileblock_t value) {
    fileBlock = value;
    if (call IFileFree.inuse(fileBlock))
      scanned(FS_ERROR_BAD_DATA);
    else
      {
	call IFileFree.reserve(fileBlock);
	call IFileBlockMeta.read(fileBlock, FALSE);
      }
  }

  event void IFileMetaRead.nextFile(struct fileEntry *file, fileresult_t result) {
    if (fileBlock == IFS_EOF_BLOCK)
      // Yuck. newBlockRead discovered a problem
      signal IFileScan.scanned(FS_ERROR_BAD_DATA);
    else if (result == FS_OK)
      {
	signal IFileScan.anotherFile();
	scanFile(file->firstBlock);
      }
    else
      {
	if (result == FS_NO_MORE_FILES)
	  result = FS_OK;
	scanned(result);
      }
  }

  event void IFileBlockMeta.readDone(fileblock_t nextBlock, 
				     fileblockoffset_t lastByte,
				     fileresult_t result) {
    /* gives up on bad file, but continue scanning other files */
    if (result == FS_OK && nextBlock != IFS_EOF_BLOCK)
      scanFile(nextBlock);
    else
      call IFileMetaRead.readNext();
  }

  event void IFileBlockMeta.writeDone(fileresult_t result) { 
    assert(0);
  }
}
