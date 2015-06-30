// $Id: Writer.nc,v 1.3 2004/04/14 19:06:21 kristinwright Exp $

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
module Writer {
  provides {
    interface StdControl;
    interface IFileWrite[uint8_t fd];
    interface IFileWrite2[uint8_t fd];
  }
  uses {
    interface IFileBlock;
    interface IFileBlockErase;
    interface IFileBlockMeta;
    interface IFileFree;
  }
#include "massert.h"
}
implementation {
  struct fileState {
    fileblock_t first, block, nextBlock, blockPosition;
    fileblockoffset_t lastOffset, offset;
    bool check;
  } fds[FS_NUM_WFDS];

  fileblock_t newBlock, lastNewBlock, newCount;
  fileblock_t lastBlock;
  fileblockoffset_t lastBlockOffset;
  uint8_t writefd;
  char *writefrom;
  filesize_t writeSize, requestedSize;
  enum { s_creating, s_opening, s_seeking, s_truncating,
	 s_reserving, s_reserving2,
	 s_allocating, s_allocating2, s_syncing, s_writing,
	 s_meta_sync, s_meta_sync_first };
  uint8_t state;

  command result_t StdControl.init() {
    fds[0].first = fds[1].first = IFS_EOF_BLOCK;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void writeComplete(fileresult_t result) {
    signal IFileWrite.writeDone[writefd](requestedSize - writeSize, result);
  }

  void syncComplete(fileresult_t result) {
    signal IFileWrite.syncDone[writefd](result);
  }

  void seekComplete(fileresult_t result) {
    signal IFileWrite2.seekDone[writefd](writeSize, result);
  }

  void reserveComplete(fileresult_t result) {
    signal IFileWrite2.reserved[writefd](writeSize, result);
  }

  void allocateAbort(fileresult_t result) {
    switch (state)
      {
      case s_creating: signal IFileWrite.newvDone[writefd](result); break;
      case s_reserving: reserveComplete(result); break;
      default: writeComplete(result); break;
      }
  }

  task void nospace() {
    allocateAbort(FS_ERROR_NOSPACE);
  }

  void allocateNextNewBlock() {
    lastNewBlock = newBlock;
    newBlock = call IFileFree.allocate();
    call IFileBlockErase.erase(newBlock);
  }

  void flushAndAllocateNextNewBlock() {
    call IFileBlock.flush(newBlock);
  }

  void allocateNewBlocks(fileblock_t n) {
    if (call IFileFree.nFreeBlocks() >= n)
      {
	newCount = n;
	newBlock = IFS_EOF_BLOCK;
	allocateNextNewBlock();
      }
    else
      post nospace();
  }

  void allocateFail(fileresult_t result) {
    call IFileFree.free(newBlock);
    allocateAbort(result);
  }

  void readNextBlock() {
    call IFileBlockMeta.read(fds[writefd].nextBlock, fds[writefd].check);
  }

  bool updateMeta() {
    bool update = fds[writefd].check;

    if (fds[writefd].offset > fds[writefd].lastOffset)
      {
	fds[writefd].lastOffset = fds[writefd].offset;
	update = TRUE;
      }

    if (update)
      call IFileBlockMeta.write(fds[writefd].block, fds[writefd].check, FALSE,
				fds[writefd].nextBlock, fds[writefd].lastOffset);

    return update;
  }

  event void IFileBlockErase.eraseDone(fileresult_t result) {
    if (result == FS_OK)
      call IFileBlockMeta.write(newBlock, fds[writefd].check,
				FALSE, lastNewBlock, 0);
    else
      allocateFail(result);
  }

  command void IFileWrite.newv[uint8_t fd](bool check) {
    state = s_creating; 
    writefd = fd;
    fds[fd].offset = 0;
    fds[fd].lastOffset = 0;
    fds[fd].check = check;
    fds[fd].blockPosition = 0;

    allocateNewBlocks(1);
  }

  command void IFileWrite2.open[uint8_t fd](fileblock_t first, bool check) {
    state = s_opening;
    writefd = fd;
    fds[fd].first = fds[fd].block = first;
    fds[fd].offset = 0;
    fds[fd].blockPosition = 0;
    fds[fd].check = check;
    call IFileBlockMeta.read(first, check);
  }

  command fileblock_t IFileWrite.firstBlock[uint8_t fd]() {
    return fds[fd].first;
  }

  command void IFileWrite.close[uint8_t fd]() {
    fds[fd].first = IFS_EOF_BLOCK;
  }

  void continueWrite() {
    fileblock_t block;
    fileblockoffset_t count, offset;

    // check if done
    if (writeSize == 0)
      {
	writeComplete(FS_OK);
	return;
      }

    block = fds[writefd].block;
    offset = fds[writefd].offset;
    if (writeSize >= IFS_PAGE_SIZE || writeSize + offset > IFS_PAGE_SIZE)
      count = IFS_PAGE_SIZE - offset;
    else
      count = writeSize;

    if (count > 0)
      {
	call IFileBlock.write(block, offset, writefrom, count);
	fds[writefd].offset += count;
	writefrom += count;
	writeSize -= count;
      }
    else if (fds[writefd].nextBlock != IFS_EOF_BLOCK) // writing through a file
      {
	state = s_writing;
	if (!updateMeta())
	  readNextBlock();
      }
    else // need new block
      {
	state = s_allocating;
	allocateNewBlocks(1);
      }
  }

  void seekToEnd(fileblock_t nextBlock, fileblockoffset_t lastOffset);
  void reserve(fileblock_t nextBlock, fileblockoffset_t lastOffset);

  event void IFileBlockMeta.readDone(fileblock_t nextBlock,
				     fileblockoffset_t lastByte,
				     fileresult_t result) {
    if (result == FS_OK)
      switch (state)
	{
	case s_meta_sync_first:
	  // setting root flag, we're not the only block or we wouldn't be
	  // here (see metaSync)
	  call IFileBlockMeta.write(fds[writefd].first, fds[writefd].check,
				    TRUE, nextBlock, lastByte);
	  break;
	case s_opening:
	  fds[writefd].nextBlock = nextBlock;
	  fds[writefd].lastOffset = lastByte;
	  signal IFileWrite2.openDone[writefd](result);
	  break;
	case s_seeking:
	  seekToEnd(nextBlock, lastByte);
	  break;
	case s_reserving:
	  reserve(nextBlock, lastByte);
	  break;
	case s_writing:
	  call IFileBlock.flush(fds[writefd].block);
	  fds[writefd].block = fds[writefd].nextBlock;
	  fds[writefd].blockPosition++;
	  fds[writefd].offset = 0;

	  fds[writefd].nextBlock = nextBlock;
	  fds[writefd].lastOffset = lastByte;
	  break;
	}
    else
      switch (state)
	{
	case s_opening: signal IFileWrite2.openDone[writefd](result); break;
	case s_seeking: seekComplete(result); break;
	case s_reserving: reserveComplete(result); break;
	case s_meta_sync_first: syncComplete(result); break;
	case s_writing: writeComplete(result); break;
	}
  }

  event void IFileBlock.writeDone(fileresult_t result) {
    if (result == FS_OK)
      continueWrite();
    else
      writeComplete(result);
  }

  event void IFileBlockMeta.writeDone(fileresult_t result) {
    if (result == FS_OK)
      switch (state)
	{
	case s_truncating: {
	  fileblock_t nowFree = fds[writefd].nextBlock;

	  fds[writefd].nextBlock = IFS_EOF_BLOCK;
	  fds[writefd].offset = fds[writefd].lastOffset = 0;
	  signal IFileWrite2.truncated[writefd](nowFree, FS_OK);
	  return;
	}
	case s_writing:
	  readNextBlock();
	  return;
	case s_allocating: case s_reserving:
	  if (--newCount)
	    flushAndAllocateNextNewBlock();
	  else
	    call IFileBlock.sync(newBlock);
	  return;
	case s_creating:
	  if (--newCount)
	    flushAndAllocateNextNewBlock();
	  else
	    {
	      fds[writefd].block = fds[writefd].first = newBlock;
	      fds[writefd].nextBlock = lastNewBlock;
	      signal IFileWrite.newvDone[writefd](FS_OK);
	    }
	  return;
	case s_allocating2:
	  /* We've finished writing the old block */
	  call IFileBlock.flush(fds[writefd].block);
	  fds[writefd].block = newBlock;
	  fds[writefd].blockPosition++;
	  fds[writefd].nextBlock = lastNewBlock;
	  fds[writefd].offset = fds[writefd].lastOffset = 0;
	  break;
	case s_reserving2:
	  call IFileBlock.flush(lastBlock);
	  if (lastBlock == fds[writefd].block)
	    fds[writefd].nextBlock = newBlock;
	  break;
	case s_meta_sync:
	  /* If metadata is more than 1 block we will need to set the root flag
	     on the first block, so we just flush. */
	  if (fds[writefd].block != fds[writefd].first)
	    {
	      state = s_meta_sync_first;
	      call IFileBlock.flush(fds[writefd].block);
	      fds[writefd].block = fds[writefd].first;
	      return;
	    }
	  /* fall through */
	case s_syncing: case s_meta_sync_first:
	  call IFileBlock.sync(fds[writefd].block);
	  return;
	}
    else
      switch (state)
	{
	  // I'm not using allocateFail for failure in the s_allocating2
	  // case as it's not clear whether the flash chip does or does not
	  // contain the ptr to the new block. Better to leak until reboot.
	case s_writing: case s_allocating2:
	  writeComplete(result);
	  return;
	case s_creating: case s_allocating: case s_reserving:
	  allocateFail(result);
	  return;
	case s_meta_sync: case s_syncing: case s_meta_sync_first:
	  syncComplete(result);
	  return;
	case s_truncating:
	  signal IFileWrite2.truncated[writefd](0, result);
	  return;
	}
  }

  task void writeCompleteTask() {
    writeComplete(FS_OK);
  }

  command void IFileWrite.write[uint8_t fd](void *buffer, filesize_t n) {
    writefd = fd;
    writefrom = buffer;
    requestedSize = writeSize = n;
    if (n == 0)
      post writeCompleteTask();
    else
      continueWrite();
  }

  command void IFileWrite.sync[uint8_t fd]() {
    state = s_syncing;
    writefd = fd;
    if (!updateMeta())
      call IFileBlock.sync(fds[fd].block);
  }

  command void IFileWrite.metaSync[uint8_t fd]() {
    /* This assumes the MetaData component never rewinds and synchronises
       once only, at the end. */
    state = s_meta_sync;
    writefd = fd;
    call IFileBlockMeta.write(fds[fd].block, fds[fd].check, 
			      fds[fd].block == fds[fd].first,
			      IFS_EOF_BLOCK, fds[fd].offset);
  }

  event void IFileBlock.syncDone(fileresult_t result) {
    switch (state)
      {
      case s_allocating:
	/* We've synced the new block, now we can point to it from the
	   old block */
	if (result == FS_OK)
	  {
	    state = s_allocating2;
	    call IFileBlockMeta.write(fds[writefd].block, fds[writefd].check,
				      FALSE, newBlock, IFS_PAGE_SIZE);
	  }
	else
	  allocateFail(result);
	return;
      case s_reserving:
	if (result == FS_OK)
	  {
	    state = s_reserving2;
	    call IFileBlockMeta.write(lastBlock, fds[writefd].check,
				      FALSE, newBlock, lastBlockOffset);
	  }
	else
	  allocateFail(result);
	return;
      case s_syncing: case s_meta_sync: case s_meta_sync_first:
	signal IFileWrite.syncDone[writefd](result);
	return;
      }
  }

  event void IFileBlock.flushDone(fileresult_t result) {
    switch (state)
      {
      case s_meta_sync_first:
	if (result == FS_OK)
	  call IFileBlockMeta.read(fds[writefd].first, fds[writefd].check);
	else
	  syncComplete(result);
	break;
      case s_allocating: case s_reserving: case s_creating:
	if (result == FS_OK)
	  allocateNextNewBlock();
	else
	  allocateFail(result);
	break;
      case s_reserving2:
	reserveComplete(result);
	break;
      default:
	if (result == FS_OK)
	  continueWrite();
	else
	  writeComplete(result);
	break;
      }
  }

  void seekToEnd(fileblock_t nextBlock, fileblockoffset_t lastOffset) {
    writeSize += lastOffset;
    if (nextBlock == IFS_EOF_BLOCK || lastOffset < IFS_PAGE_SIZE)
      {
	fds[writefd].nextBlock = nextBlock;
	fds[writefd].offset = fds[writefd].lastOffset = lastOffset;
	seekComplete(FS_OK);
      }
    else
      {
	fds[writefd].block = nextBlock;
	fds[writefd].blockPosition++;
	call IFileBlockMeta.read(nextBlock, fds[writefd].check);
      }
  }

  command void IFileWrite2.seekEnd[uint8_t fd]() {
    state = s_seeking;
    writefd = fd;
    writeSize = 0;
    seekToEnd(fds[fd].nextBlock, fds[fd].lastOffset);
  }

  command void IFileWrite2.truncate[uint8_t fd]() {
    state = s_truncating;
    writefd = fd;
    call IFileBlockMeta.write(fds[fd].first, fds[fd].check, FALSE,
			      IFS_EOF_BLOCK, 0);
  }


  task void reserveDoneTask() {
    reserveComplete(FS_OK);
  }

  void reserve(fileblock_t nextBlock, fileblockoffset_t lastOffset) {
    writeSize += IFS_PAGE_SIZE;

    lastBlockOffset = lastOffset;
    if (nextBlock == IFS_EOF_BLOCK)
      {
	if (writeSize > requestedSize)
	  post reserveDoneTask();
	else
	  {
	    fileblock_t nNewBlocks =
	      (requestedSize - writeSize + IFS_PAGE_SIZE - 1) >> IFS_LOG2_PAGE_SIZE;
	    writeSize += (filesize_t)nNewBlocks << IFS_LOG2_PAGE_SIZE;
	    allocateNewBlocks(nNewBlocks);
	  }
      }
    else
      {
	lastBlock = nextBlock;
	call IFileBlockMeta.read(nextBlock, fds[writefd].check);
      }
  }

  command void IFileWrite2.reserve[uint8_t fd](filesize_t newSize) {
    state = s_reserving;
    writefd = fd;
    requestedSize = newSize;
    writeSize = (filesize_t)fds[fd].blockPosition << IFS_LOG2_PAGE_SIZE;
    lastBlock = fds[fd].block;
    reserve(fds[fd].nextBlock, fds[fd].lastOffset);
  }

  default event void IFileWrite.newvDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileWrite.writeDone[uint8_t id](filesize_t nWritten, fileresult_t result) {
    assert(0);
  }
  default event void IFileWrite.syncDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileWrite2.openDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileWrite2.seekDone[uint8_t id](filesize_t size, fileresult_t result) {
    assert(0);
  }
  default event void IFileWrite2.reserved[uint8_t id](filesize_t size, fileresult_t result) {
    assert(0);
  }
  default event void IFileWrite2.truncated[uint8_t id](fileblock_t nowFree, fileresult_t result) {
    assert(0);
  }
  event void IFileBlock.readDone(fileresult_t result) {
    assert(0);
  }
}
