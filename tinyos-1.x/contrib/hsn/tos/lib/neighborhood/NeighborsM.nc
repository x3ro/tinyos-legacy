includes NeighborList;
includes WSN;

module NeighborsM {
   provides {
      interface StdControl;
      interface NeighborMgmt;
      interface Neighbors;  // for external use
   }
   uses {
      interface StdControl as ModuleControl;
      interface Pick as PickForDeletion; // if we run out of space, who do
                                         // we ask what index to delete?
   }
}

implementation
{
   wsnAddr neighborList[NEIGHBOR_LIST_LEN];

   command result_t StdControl.init()
   {
      uint8_t i;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         neighborList[i]=INVALID_NODE_ID;
      }
      call ModuleControl.init();
      return SUCCESS;
   }

   command result_t StdControl.start()
   {
      call ModuleControl.start();
      return SUCCESS;
   }

   command result_t StdControl.stop()
   {
      call ModuleControl.stop();
      return SUCCESS;
   }

   command uint8_t NeighborMgmt.getIndexForNode(wsnAddr addr)
   {
      uint8_t i;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if (neighborList[i]==addr) {
            return i;
         }
      }
      return INVALID_INDEX;
   }

   command wsnAddr NeighborMgmt.getAddrForIndex(uint8_t indx)
   {
      return neighborList[indx];
   }

   command void NeighborMgmt.removeNode(uint8_t indx) {
      neighborList[indx] = INVALID_NODE_ID;
      signal NeighborMgmt.initializeIndex(indx);
   }

   command uint8_t NeighborMgmt.addNode(wsnAddr addr)
   {
      uint8_t i;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if (neighborList[i]==INVALID_NODE_ID) {
            neighborList[i] = addr;
            signal NeighborMgmt.initializeIndex(i);
            return i;
         }
      }

      // No space available, so remove someone
      i = call PickForDeletion.pick();
      neighborList[i] = addr;
      signal NeighborMgmt.initializeIndex(i);

      return i;
   }

   command uint8_t NeighborMgmt.countNeighbors() {
      uint8_t i;
      uint8_t count = 0;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if (neighborList[i]!=INVALID_NODE_ID) {
            count++;
         }
      }
      return count;
   }

   command bool Neighbors.isNeighbor(wsnAddr addr) {
      uint8_t i;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if (neighborList[i] == addr) {
            return TRUE;
         }
      }
      return FALSE;
   }

   /* len is in number of addresses, not bytes */
   command uint8_t Neighbors.getNeighbors(wsnAddr *buf, uint8_t len) {
      uint8_t pos = 0;
      uint8_t i;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if (pos == len) {
            return pos;
         }
         if (neighborList[i]!=INVALID_NODE_ID) {
            buf[pos++] = neighborList[i];
         }
      }
      return pos;
   }

   command uint8_t Neighbors.numNeighbors() {
      return call NeighborMgmt.countNeighbors();
   }

   command void Neighbors.addNeighbor(wsnAddr addr) {
      call NeighborMgmt.addNode(addr);
   }

   command void Neighbors.setUpdateInterval(uint8_t interval) {
      signal NeighborMgmt.setUpdateInterval(interval);
   }
}
