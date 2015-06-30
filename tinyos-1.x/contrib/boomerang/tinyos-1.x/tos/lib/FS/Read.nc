// $Id: Read.nc,v 1.1.1.1 2007/11/05 19:09:13 jpolastre Exp $

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
module Read {
  provides {
    interface StdControl;
    interface FileRead[uint8_t fd];
    interface IFileCheck as ReadCheck;
  }
  uses {
    interface IFileRead[uint8_t fd];
    interface IFileCoord;
    interface IFileMetaRead;
    interface IFileCheck;
  }
#include "massert.h"
}
implementation {
  char *temp;
  fileblock_t firstBlock[FS_NUM_RFDS];
  uint8_t readfd;

  command result_t StdControl.init() {
    uint8_t i;
    for (i = 0; i < FS_NUM_RFDS; i++)
      firstBlock[i] = IFS_EOF_BLOCK;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t ReadCheck.notOpen(fileblock_t block) {
    uint8_t i;

    for (i = 0; i < FS_NUM_RFDS; i++)
      if (block == firstBlock[i])
	return FALSE;
    return TRUE;
  }

  /**
   * open a file for sequential reads.
   * @param filename Name of file to open. Must not be stack allocated.
   * @return 
   *   SUCCESS: attempt proceeds, <code>opened</code> will be signaled<br>
   *   FAIL: filesystem is busy or another file is open for reading
   */
  command result_t FileRead.open[uint8_t fd](const char *filename) {
    if (firstBlock[fd] != IFS_EOF_BLOCK || !call IFileCoord.lock())
      return FAIL;

    readfd = fd;
    temp = (char *)filename;
    call IFileMetaRead.read();
    call IFileMetaRead.readNext();

    return SUCCESS;
  }

  void openComplete(fileresult_t result) {
    call IFileCoord.unlock();
    signal FileRead.opened[readfd](result);
  }

  event void IFileMetaRead.nextFile(struct fileEntry *file, fileresult_t result) {
    if (result == FS_OK)
      {
	if (!strcmp(file->name, temp))
	  if (!call IFileCheck.notOpen(file->firstBlock))
	    openComplete(FS_ERROR_FILE_OPEN);
	  else
	    {
	      firstBlock[readfd] = file->firstBlock;
	      call IFileRead.open[readfd](file->firstBlock, 0, FS_CRC_FILES);
	      openComplete(FS_OK);
	    }
	else
	  call IFileMetaRead.readNext();
      }
    else
      openComplete(result == FS_NO_MORE_FILES ? FS_ERROR_NOT_FOUND : result);
  }

  /**
   * Close file currently open for reading
   * @return SUCCESS if a file was open, FAIL otherwise
   */
  command result_t FileRead.close[uint8_t fd]() {
    if (firstBlock[fd] == IFS_EOF_BLOCK || !call IFileCoord.lock())
      return FAIL;

    firstBlock[fd] = IFS_EOF_BLOCK;
    call IFileCoord.unlock();
    return SUCCESS;
  }

  /**
   * Read bytes sequentially from open file.
   * @param buffer Target to read into
   * @param n Number of bytes to read
   * @return
   *   SUCCESS: attempt proceeds, <code>readDone</code> will be signaled<br>
   *   FAIL: no file was open for reading, or a read is in progress
   */
  command result_t FileRead.read[uint8_t fd](void *buffer, filesize_t n) {
    if (firstBlock[fd] == IFS_EOF_BLOCK || !call IFileCoord.lock())
      return FAIL;

    call IFileRead.read[fd](buffer, n);
    temp = buffer;
    return SUCCESS;
  }

  event void IFileRead.readDone[uint8_t fd](filesize_t nRead, fileresult_t result) {
    if (fd != IFS_RFD_META)
      {
	call IFileCoord.unlock();
	signal FileRead.readDone[fd](temp, nRead, result);
      }
  }

  /**
   * Return number of bytes remaining in file.
   * @return
   *   SUCCESS: attempt proceeds, <code>remaining</code> will be signaled<br>
   *   FAIL: no file was open for reading, or a read is in progress
   */
  command result_t FileRead.getRemaining[uint8_t fd]() {
    if (firstBlock[fd] == IFS_EOF_BLOCK || !call IFileCoord.lock())
      return FAIL;

    call IFileRead.getRemaining[fd]();

    return SUCCESS;
  }

  event void IFileRead.remaining[uint8_t fd](filesize_t n, fileresult_t result) {
    call IFileCoord.unlock();
    signal FileRead.remaining[fd](n, result);
  }

  default event result_t FileRead.opened[uint8_t fd](fileresult_t result) {
    return SUCCESS;
  }
  default event result_t FileRead.readDone[uint8_t fd](void *buffer, filesize_t nRead,
						       fileresult_t result) {
    return SUCCESS;
  }
  default event result_t FileRead.remaining[uint8_t fd](filesize_t n, fileresult_t result) {
    return SUCCESS;
  }
}
