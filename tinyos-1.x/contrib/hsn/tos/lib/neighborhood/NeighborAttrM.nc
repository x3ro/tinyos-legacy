includes NeighborList;

module NeighborAttrM {
   provides {
      interface StdControl;
      interface NeighborAttr;  // for external use
   }
   uses {
      interface NeighborMgmt;
   }
}

implementation
{
   uint8_t attributes[NEIGHBOR_LIST_LEN];

   command result_t StdControl.init() {
      uint8_t i;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         attributes[i]=0;
      }
      return SUCCESS;
   }

   command result_t StdControl.start() {
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      return SUCCESS;
   }

   event void NeighborMgmt.initializeIndex(uint8_t indx) {
      attributes[indx] = 0;
   }

   command void NeighborAttr.setAttr(wsnAddr addr, uint8_t attr) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);
      if (indx == INVALID_INDEX) {
         indx = call NeighborMgmt.addNode(addr);
      }
      attributes[indx] = attr;
   }

   command result_t NeighborAttr.getAttr(wsnAddr addr, uint8_t *attr) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);
      if (indx == INVALID_INDEX) {
         return FAIL;
      } else {
         *attr = attributes[indx];
         return SUCCESS;
      }
   }

   event void NeighborMgmt.setUpdateInterval(uint8_t interval) {
   }
}
