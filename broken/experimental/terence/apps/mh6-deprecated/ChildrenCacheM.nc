#include "fatal.h"
#include "BitArraySize.h"
module ChildrenCacheM {
  provides {
    interface StdControl;
    interface Children;
  }
  uses {
    interface BitArray;
  }


}

implementation {
#define MAX_NUMBER_NODE 256
  uint8_t childrenData[BITARRAY_SIZE(MAX_NUMBER_NODE)];
  BitArrayPtr children;

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Children.clear();
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command void Children.clear() {
    children = call BitArray.initBitArray(childrenData, BITARRAY_SIZE(MAX_NUMBER_NODE));
  }
  command uint8_t Children.isChild(uint8_t id) {
    if (id >= 256) {
      FATAL("id excess number of node");
      return 0;
    }
    return call BitArray.readBitInArray(id, children);
  }
  command void Children.receivePacket(uint8_t source) {
    if (source >= 256) {
      FATAL("id excess number of node");
    }
    call BitArray.saveBitInArray(source, 1, children);
		
  }
	

}
