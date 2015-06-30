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
