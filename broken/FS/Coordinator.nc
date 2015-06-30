module Coordinator {
  provides {
    interface StdControl;
    interface IFileCoord;
    interface IFileCheck;
  }
  uses {
    interface IFileCheck as ReadCheck;
    interface IFileCheck as WriteCheck;
  }
#include "massert.h"
}
implementation {
  bool busy;

  command result_t StdControl.init() {
    busy = TRUE; // until file system ready
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Debug.init();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t IFileCoord.lock() {
    if (busy)
      return FAIL;
    busy = TRUE;
    return SUCCESS;
  }

  command result_t IFileCoord.unlock() {
    assert(busy);
    busy = FALSE;
    return SUCCESS;
  }

  command result_t IFileCheck.notOpen(fileblock_t firstBlock) {
    return rcombine(call ReadCheck.notOpen(firstBlock),
		    call WriteCheck.notOpen(firstBlock));
  }

  default command result_t WriteCheck.notOpen(fileblock_t firstBlock) {
    return SUCCESS;
  }
}
