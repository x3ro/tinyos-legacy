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
