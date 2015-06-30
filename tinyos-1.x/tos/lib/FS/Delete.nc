// $Id: Delete.nc,v 1.2 2003/10/07 21:46:18 idgay Exp $

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
module Delete {
  provides interface FileDelete;
  uses {
    interface IFileCoord;
    interface IFileMetaRead;
    interface IFileMetaWrite;
    interface IFileCheck;
  }
#include "massert.h"
}
implementation {
  const char *deleting;
  fileblock_t deletedFile;

  /**
   * Delete a file
   * @param filename Name of file to delete. Must not be stack allocated.
   * @return 
   *   SUCCESS: attempt proceeds, <code>deleted</code> will be signaled<br>
   *   FAIL: filesystem is busy
   */
  command result_t FileDelete.delete(const char *filename) {
    if (!call IFileCoord.lock())
      return FAIL;

    deleting = filename;
    deletedFile = IFS_EOF_BLOCK;

    call IFileMetaWrite.write();
    call IFileMetaRead.read();

    return SUCCESS;
  }

  event void IFileMetaWrite.writeReady() {
    call IFileMetaRead.readNext();
  }

  default event result_t FileDelete.deleted(fileresult_t result) {
    return SUCCESS;
  }

  event void IFileMetaRead.nextFile(struct fileEntry *file, fileresult_t result) {
    if (result == FS_OK)
      {
	if (strcmp(file->name, deleting))
	  {
	    call IFileMetaWrite.writeFile(file->name, file->firstBlock);
	    return;
	  }
	else if (!call IFileCheck.notOpen(file->firstBlock))
	  result = FS_ERROR_FILE_OPEN;
	else
	  {
	    assert(deletedFile == IFS_EOF_BLOCK);
	    deletedFile = file->firstBlock;
	    call IFileMetaRead.readNext();
	    return;
	  }
      }
    else if (result == FS_NO_MORE_FILES)
      if (deletedFile == IFS_EOF_BLOCK)
	result = FS_ERROR_NOT_FOUND;
      else
	result = FS_OK;
    call IFileMetaWrite.writeComplete(result);
  }

  void deleteComplete(fileresult_t result) {
    call IFileCoord.unlock();
    signal FileDelete.deleted(result);
  }

  event void IFileMetaWrite.writeCompleted(fileresult_t result) {
    /* Free the blocks. We do this at the end to avoid problems if
       we don't successfully write the new meta data */
    if (result == FS_OK)
      call IFileMetaWrite.deleteBlocks(deletedFile);
    else
      deleteComplete(result);
  }

  event void IFileMetaWrite.blocksDeleted(fileresult_t result) {
    // We always return FS_OK because we've actually updated the
    // metadata (if an error occurs here, we'll just lose track
    // of some blocks until the next reboot)
    deleteComplete(FS_OK);
  }
}
