includes IFS;
module Dir {
  provides interface FileDir;
  uses {
    interface IFileMetaRead;
    interface IFileCoord;
    interface IFileFree;
  }
#include "massert.h"
}
implementation {
  bool busy;

  /**
   * List names of all files in filing system
   * @return 
   *   SUCCESS: attempt proceeds, <code>nextFile</code> will be signaled<br>
   *   FAIL: filesystem is busy
   */
  command result_t FileDir.start() {
    if (!call IFileCoord.lock())
      return FAIL;
    busy = TRUE;

    call IFileMetaRead.read();

    return SUCCESS;
  }

  command result_t FileDir.readNext() {
    if (!busy)
      return FAIL;
    call IFileMetaRead.readNext();
    return SUCCESS;
  }

  default event result_t FileDir.nextFile(const char *filename, fileresult_t result) {
    return FAIL;
  }

  event void IFileMetaRead.nextFile(struct fileEntry *file, fileresult_t result) {
    if (signal FileDir.nextFile(file->name, result) != SUCCESS ||
	result != FS_OK)
      {
	call IFileCoord.unlock();
	busy = FALSE;
      }
  }

  /**
   * @return Number of bytes available in filing system.
   */
  command uint32_t FileDir.freeBytes() {
    return (uint32_t)call IFileFree.nFreeBlocks() << IFS_LOG2_PAGE_SIZE;
  }
}
