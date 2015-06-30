includes IFS;
module Rename {
  provides interface FileRename;
  uses {
    interface IFileMetaRead;
    interface IFileMetaWrite;
    interface IFileCoord;
    interface IFileCheck;
  }
#include "massert.h"
}
implementation {
  const char *from, *to;
  fileblock_t deletedFile;
  bool renamed;

  /**
   * Rename a file. If a file called <code>newName</code> exists, it is
   * deleted.
   * @param oldName Name of file to rename. Must not be stack allocated.
   * @param newName New name of file. Must not be stack allocated.
   * @return 
   *   SUCCESS: attempt proceeds, <code>renamed</code> will be signaled<br>
   *   FAIL: filesystem is busy
   */
  command result_t FileRename.rename(const char *oldName, const char *newName) {
    // Refuse empty-string filenames
    if (!newName[0])
      return FAIL;

    if (!call IFileCoord.lock())
      return FAIL;

    from = oldName;
    to = newName;
    deletedFile = IFS_EOF_BLOCK;
    renamed = FALSE;

    call IFileMetaWrite.write();
    call IFileMetaRead.read();

    return SUCCESS;
  }

  event void IFileMetaWrite.writeReady() {
    call IFileMetaRead.readNext();
  }

  default event result_t FileRename.renamed(fileresult_t result) {
    return SUCCESS;
  }

  void renameComplete(fileresult_t result) {
    call IFileCoord.unlock();
    signal FileRename.renamed(result);
  }

  event void IFileMetaRead.nextFile(struct fileEntry *file, fileresult_t result) {
    if (result == FS_OK)
      {
	if (!strcmp(file->name, from))
	  if (!call IFileCheck.notOpen(file->firstBlock))
	    result = FS_ERROR_FILE_OPEN;
	  else
	    {
	      call IFileMetaWrite.writeFile(to, file->firstBlock);
	      renamed = TRUE;
	      return;
	    }
	else if (strcmp(file->name, to))
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
      if (renamed)
	result = FS_OK;
      else
	result = FS_ERROR_NOT_FOUND;

    call IFileMetaWrite.writeComplete(result);
  }

  event void IFileMetaWrite.writeCompleted(fileresult_t result) {
    /* Free the blocks. We do this at the end to avoid problems if
       we don't successfully write the new meta data */
    if (result == FS_OK && deletedFile != IFS_EOF_BLOCK)
      call IFileMetaWrite.deleteBlocks(deletedFile);
    else
      renameComplete(result);
  }

  event void IFileMetaWrite.blocksDeleted(fileresult_t result) {
    // We always return FS_OK because we've actually updated the
    // metadata (if an error occurs here, we'll just lose track
    // of some blocks until the next reboot)
    renameComplete(FS_OK);
  }
}
