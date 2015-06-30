// $Id: Write.nc,v 1.3 2004/04/14 19:06:21 kristinwright Exp $

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
module Write {
  provides {
    interface FileWrite[uint8_t fd];
    interface IFileCheck as WriteCheck;
  }
  uses {
    interface IFileWrite[uint8_t fd];
    interface IFileWrite2[uint8_t fd];
    interface IFileCoord;
    interface IFileMetaRead;
    interface IFileMetaWrite;
    interface IFileCheck;
    interface IFileFree;
  }
#include "massert.h"
}
implementation {
  char *temp;
  bool flags;
  enum { s_open, s_create, s_created, s_sync, s_close };
  uint8_t state;
  uint8_t writefd;

  void create();
  void nextFile_create(struct fileEntry *file, fileresult_t result);

  bool open(uint8_t fd) {
    return call IFileWrite.firstBlock[fd]() != IFS_EOF_BLOCK;
  }

  command result_t WriteCheck.notOpen(fileblock_t block) {
    uint8_t i;

    for (i = 0; i < FS_NUM_WFDS; i++)
      if (block == call IFileWrite.firstBlock[i]())
	return FALSE;
    return TRUE;
  }

  /**
   * open a file for sequential reads.
   * @param filename Name of file to open. Must not be stack allocated.
   * @param create TRUE if file should be created if it doesn't exist
   * @param truncate TRUE if file should be truncated if it exists
   * @return 
   *   SUCCESS: attempt proceeds, <code>opened</code> will be signaled<br>
   *   FAIL: filesystem is busy or another file is already open for writing
   */
  command result_t FileWrite.open[uint8_t fd](const char *filename, uint8_t pflags) {
    if (!filename[0] || open(fd) || !call IFileCoord.lock())
      return FAIL;

    writefd = fd;
    temp = (char *)filename;
    flags = pflags;
    state = s_open;
    call IFileMetaRead.read();
    call IFileMetaRead.readNext();

    return SUCCESS;
  }

  void openComplete(filesize_t size, fileresult_t result) {
    call IFileCoord.unlock();
    if (result != FS_OK)
      call IFileWrite.close[writefd]();
    signal FileWrite.opened[writefd](size, result);
  }

  void nextFile_open(struct fileEntry *file, fileresult_t result) {
    if (result == FS_OK)
      {
	if (!strcmp(file->name, temp))
	  if (!call IFileCheck.notOpen(file->firstBlock))
	    openComplete(0, FS_ERROR_FILE_OPEN);
	  else 
	    call IFileWrite2.open[writefd](file->firstBlock, FS_CRC_FILES);
	else
	  call IFileMetaRead.readNext();
      }
    else
      {
	if (result == FS_NO_MORE_FILES)
	  if (flags & FS_FCREATE)
	    {
	      create();
	      return;
	    }
	  else
	    result = FS_ERROR_NOT_FOUND;
      
	openComplete(0, result);
      }
  }

  event void IFileMetaRead.nextFile(struct fileEntry *file, fileresult_t result) {
    switch (state)
      {
      case s_open: nextFile_open(file, result); break;
      case s_create: nextFile_create(file, result); break;
      }
  }

  event void IFileWrite2.openDone[uint8_t fd](fileresult_t result) {
    if (result == FS_OK)
      {
	if (flags & FS_FTRUNCATE)
	  call IFileWrite2.truncate[fd]();
	else
	  call IFileWrite2.seekEnd[fd]();
#if 0
	else
	  openComplete(0, result); // open at beginning
#endif
      }
    else
      openComplete(0, result);
  }

  event void IFileWrite2.seekDone[uint8_t fd](filesize_t size, fileresult_t result) {
    openComplete(size, result);
  }

  event void IFileWrite2.truncated[uint8_t fd](fileblock_t freeBlocks, fileresult_t result) {
    if (result == FS_OK && freeBlocks != IFS_EOF_BLOCK)
      call IFileMetaWrite.deleteBlocks(freeBlocks);
    else
      openComplete(0, result);
  }

  event void IFileMetaWrite.blocksDeleted(fileresult_t result) {
    openComplete(0, result);
  }

  void create() {
    // We need at least 3 blocks free beyond those reserved for another
    // copy of the metadata to ensure that we'll have enough space after
    // the create:
    // - 1 block for the new file
    // - 1 extra block for the new metadata if it expands
    // - 1 extra reserved block if the new metadata expanded
    if (call IFileFree.nFreeBlocks() < 3)
      openComplete(0, FS_ERROR_NOSPACE);
    else
      {
	state = s_create;
	call IFileWrite.newv[writefd](FS_CRC_FILES);
      }
  }

  event void IFileWrite.newvDone[uint8_t fd](fileresult_t result) {
    if (fd == IFS_WFD_META)
      return;

    if (result == FS_OK)
      call IFileWrite.sync[fd]();
    else
      openComplete(0, result);
  }

  void nextFile_create(struct fileEntry *file, fileresult_t result) {
    if (result == FS_OK)
      call IFileMetaWrite.writeFile(file->name, file->firstBlock);
    else if (result == FS_NO_MORE_FILES)
      {
	state = s_created;
	call IFileMetaWrite.writeFile(temp, call IFileWrite.firstBlock[writefd]());
      }
    else
      call IFileMetaWrite.writeComplete(result);
  }

  event void IFileMetaWrite.writeReady() {
    switch (state)
      {
      case s_create:
	call IFileMetaRead.readNext();
	return;
      case s_created:
	call IFileMetaWrite.writeComplete(FS_OK);
	return;
      }
  }

  event void IFileMetaWrite.writeCompleted(fileresult_t result) {
    openComplete(0, result);
  }

  /**
   * close file currently open for writing
   * @return
   *   SUCCESS: attempts proceeds, <code>closed</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t FileWrite.close[uint8_t fd]() {
    if (!open(fd) || !call IFileCoord.lock())
      return FAIL;

    state = s_close;
    call IFileWrite.sync[fd]();
    return SUCCESS;
  }

  /**
   * Reserve space for the currently open file to be <code>newSize</code>
   * bytes long. <code>append</code>s that do not make the file take
   * more than <code>newSize</code> bytes will not fail with FS_ERROR_NOSPACE.
   * Note: you can find the reserved size of a file by requesting a reserve
   * with a newSize of 0. The <code>reserved</code> event will indicate the
   * space currently reserved.
   * @param newSize Size file is expected to grow to
   * @return
   *   SUCCESS: attempt proceeds, <code>reserved</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t FileWrite.reserve[uint8_t fd](filesize_t newSize) {
    if (!open(fd) || !call IFileCoord.lock())
      return FAIL;

    call IFileWrite2.reserve[fd](newSize);
    return SUCCESS;
  }

  event void IFileWrite2.reserved[uint8_t fd](filesize_t reservedSize, fileresult_t result) {
    call IFileCoord.unlock();
    signal FileWrite.reserved[fd](reservedSize, result);
  }

  /**
   * Ensure data appended is comitted to stable storage.
   * @return
   *   SUCCESS: attempt proceeds, <code>synced</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t FileWrite.sync[uint8_t fd]() {
    if (!open(fd) || !call IFileCoord.lock())
      return FAIL;

    state = s_sync;
    call IFileWrite.sync[fd]();
    return SUCCESS;
  }

  event void IFileWrite.syncDone[uint8_t fd](fileresult_t result) {
    if (fd == IFS_WFD_META)
      return;

    switch (state)
      {
      case s_close:
	call IFileWrite.close[fd]();
	call IFileCoord.unlock();
	signal FileWrite.closed[fd](result);
	return;
      case s_sync:
	call IFileCoord.unlock();
	signal FileWrite.synced[fd](result);
	return;
      case s_create:
	call IFileMetaWrite.write();
	call IFileMetaRead.read();
	return;
      }
  }

  /**
   * Write bytes sequentially to end of open file.
   * @param buffer Data to write
   * @param n Number of bytes to write
   * @return
   *   SUCCESS: attempt proceeds, <code>appended</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t FileWrite.append[uint8_t fd](void *buffer, filesize_t n) {
    if (!open(fd) || !call IFileCoord.lock())
      return FAIL;

    call IFileWrite.write[fd](buffer, n);
    temp = buffer;
    return SUCCESS;
  }

  event void IFileWrite.writeDone[uint8_t fd](filesize_t nWritten, fileresult_t result) {
    if (fd == IFS_WFD_META)
      return;

    call IFileCoord.unlock();
    signal FileWrite.appended[fd](temp, nWritten, result);
  }

  default event result_t FileWrite.opened[uint8_t fd](filesize_t fileSize, fileresult_t result) {
    return SUCCESS;
  }
  default event result_t FileWrite.closed[uint8_t fd](fileresult_t result) {
    return SUCCESS;
  }
  default event result_t FileWrite.appended[uint8_t fd](void *buffer, filesize_t nWritten,
							fileresult_t result) {
    return SUCCESS;
  }
  default event result_t FileWrite.reserved[uint8_t fd](filesize_t reservedSize, fileresult_t result) {
    return SUCCESS;
  }
  default event result_t FileWrite.synced[uint8_t fd](fileresult_t result) {
    return SUCCESS;
  }
}
