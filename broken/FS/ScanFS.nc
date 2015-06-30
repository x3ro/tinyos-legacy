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
