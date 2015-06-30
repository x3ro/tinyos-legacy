includes IFS;
module FreeList {
  provides {
    interface StdControl;
    interface IFileFree;
  }
#include "massert.h"
}
implementation {
  fileblock_t nFreeBlocks, freePtr, reserved;
  uint8_t usedBlocks[IFS_NUM_PAGES / 8];

  command result_t StdControl.init() {
    call IFileFree.freeall();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void IFileFree.freeall() {
    nFreeBlocks = IFS_NUM_PAGES;
    reserved = 0;
    memset(usedBlocks, 0, sizeof usedBlocks);
  }

  command fileblock_t IFileFree.nFreeBlocks() {
    return nFreeBlocks - reserved;
  }

  command void IFileFree.setReserved(fileblock_t n) {
    assert(n <= nFreeBlocks);
    reserved = n;
  }

  uint8_t inuse(fileblock_t n) {
    return usedBlocks[n >> 3] & (1 << (n & 7));
  }

  command fileblock_t IFileFree.allocate() {
    fileblock_t i = freePtr;

    assert(nFreeBlocks > 0);
    assert(freePtr < IFS_NUM_PAGES);
    /* Return 1st free page after freePtr */
    for (;;)
      {
	if (++i >= IFS_NUM_PAGES)
	  i = 0;

	if (!inuse(i))
	  {
	    call IFileFree.reserve(i);
	    freePtr = i;
	    return i;
	  }
      }
  }

  command void IFileFree.free(fileblock_t n) {
    assert(inuse(n));
    nFreeBlocks++;
    usedBlocks[n >> 3] &= ~(1 << (n & 7));
  }

  command void IFileFree.setFreePtr(fileblock_t n) {
    assert(n < IFS_NUM_PAGES);
    freePtr = n;
  }

  command void IFileFree.reserve(fileblock_t n) {
    assert(!inuse(n));
    usedBlocks[n >> 3] |= (1 << (n & 7));
    nFreeBlocks--;
  }

  command bool IFileFree.inuse(fileblock_t n) {
    return n >= IFS_NUM_PAGES || inuse(n) != 0;
  }
}
