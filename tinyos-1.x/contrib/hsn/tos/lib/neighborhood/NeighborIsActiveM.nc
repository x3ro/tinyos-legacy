includes NeighborList;

module NeighborIsActiveM {
   provides {
      interface ByteValue as NodeActivity;
      interface StdControl;
      interface NeighborIsActive; // for external use
   }
   uses {
      interface ByteValue as NodeHistory;
      interface NeighborMgmt;
   }
}

implementation
{
   uint8_t activity[NEIGHBOR_LIST_LEN];

   command result_t StdControl.init() {
      return SUCCESS;
   }

   command result_t StdControl.start() {
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      return SUCCESS;
   }

   command uint8_t NodeActivity.getValue(uint8_t indx) {
      return activity[indx];
   }

   default event result_t NodeActivity.valueChanged(uint8_t indx) {
      return SUCCESS;
   }

   event void NeighborMgmt.initializeIndex(uint8_t indx) {
      activity[indx] = 0;
   }

   command uint8_t NeighborIsActive.numActiveNeighbors() {
      uint8_t i;
      uint8_t count = 0;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if ((call NeighborMgmt.getAddrForIndex(i) != INVALID_NODE_ID) && 
             (activity[i] > 0)) {
            count++;
         }
      }
      return count;
   }

   command bool NeighborIsActive.isActive(wsnAddr addr) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);

      if ((indx == INVALID_INDEX) || (activity[indx] == 0)) {
         return FALSE;
      } else {
         return TRUE;
      }
   }

   event result_t NodeHistory.valueChanged(uint8_t indx) {
      if (activity[indx] > 0) {
         if (call NodeHistory.getValue(indx) 
                  < NEIGHBOR_ACTIVITY_REMOVE_THRESH) {
            activity[indx] = 0;
         }
      } else {
         if (call NodeHistory.getValue(indx) 
                   >= NEIGHBOR_ACTIVITY_JOIN_THRESH) {
            activity[indx] = 1;
         }
      }
   }

   event void NeighborMgmt.setUpdateInterval(uint8_t interval) {
   }
}
