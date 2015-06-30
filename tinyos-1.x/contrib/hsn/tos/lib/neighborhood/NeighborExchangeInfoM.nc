/*
 * WARNING: This module packs addresses into bytes for piggyback transmission.
 *          If using this module with 16-bit addresses, make sure you don't
 *          have addresses that are higher than 254.
 */

includes NeighborList;

module NeighborExchangeInfoM {
   provides {
      interface StdControl;
      interface ByteValue as OutboundQuality;
      interface NeighborQuality as NeighborOutboundQuality; // for external use
      interface NeighborQuality as NeighborBiDirQuality;    // for external use
      interface Pick as PickLowestQuality;
      interface Piggyback;
      interface Settings;
   }
   uses {
      interface NeighborMgmt;
      interface ByteValue as NodeHistory;
   }
}

implementation
{
   uint8_t outboundQuality[NEIGHBOR_LIST_LEN];

   uint8_t q_tholds[NUM_QUALITY_THOLDS];

   uint8_t computeQualityLevel(uint8_t packetsReceived) {
      uint8_t th;

      for (th = 0; th <= NUM_QUALITY_THOLDS; th++) {
         if ( ((th == 0) || (packetsReceived < q_tholds[th-1])) &&
              ((th == NUM_QUALITY_THOLDS) || (packetsReceived >= q_tholds[th]))
            ) {
            return NUM_QUALITY_THOLDS - th;
         }
      }
      return -1;  // this shouldn't happen!
   }

   command result_t StdControl.init() {
      q_tholds[0] = NEIGHBOR_QUALITY_THOLD0;
      q_tholds[1] = NEIGHBOR_QUALITY_THOLD1;
      q_tholds[2] = NEIGHBOR_QUALITY_THOLD2;
      return SUCCESS;
   }

   command result_t StdControl.start() {
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      return SUCCESS;
   }

   event void NeighborMgmt.initializeIndex(uint8_t indx) {
      outboundQuality[indx] = 1;
   }

   command uint8_t OutboundQuality.getValue(uint8_t indx) {
      if ((indx == INVALID_INDEX) || 
          (call NeighborMgmt.getAddrForIndex(indx) == INVALID_NODE_ID)) {
         return 1;  // no info known
      } else {
         return outboundQuality[indx];
      }
   }

   default event result_t OutboundQuality.valueChanged(uint8_t indx) {
      return SUCCESS;
   }

   command uint16_t NeighborOutboundQuality.getNeighborQuality(wsnAddr addr) {
      return (uint16_t)(call OutboundQuality.getValue(
                         call NeighborMgmt.getIndexForNode(addr)));
   }

   command uint16_t NeighborBiDirQuality.getNeighborQuality(wsnAddr addr) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);
      if ((indx == INVALID_INDEX) ||
          (call NeighborMgmt.getAddrForIndex(indx) == INVALID_NODE_ID)) {
         return 1;  // no info known
      } else {
         uint8_t inbound = computeQualityLevel(call NodeHistory.getValue(indx));
         return (uint16_t)(inbound < outboundQuality[indx] ?
                           inbound : outboundQuality[indx]);
      }
   }

   // The resulting buffer will contain a list of NUM_QUALITY_THOLDS+1 list 
   // lengths followed by that many lists of node ids.
   //  (e.g. TH3_cnt TH2_cnt TH1_cnt TH0_cnt N1 N2 N3 N4...)
   command uint8_t Piggyback.fillPiggyback(wsnAddr addr, uint8_t* buf,
                                                                uint8_t len) {
      uint8_t *counts = buf;
      uint8_t th;
      uint8_t i;
      uint8_t pos;
      wsnAddr nbr[NEIGHBOR_LIST_LEN];
      uint8_t quality[NEIGHBOR_LIST_LEN];

      // if I can't even fit the group counts, give up
      if (len < NUM_QUALITY_THOLDS+1) {
         return 0;  // TODO: handle this more gracefully
      }

      // zero out the portion of the packet we're using
      for (i=0; i < len; i++) {
         buf[i] = 0;
      }

      pos = NUM_QUALITY_THOLDS + 1;

      // count up the bits once, ahead of time
      for (i = 0; i < NEIGHBOR_LIST_LEN; i++) {
         nbr[i] = call NeighborMgmt.getAddrForIndex(i);
         quality[i] = call NodeHistory.getValue(i);
      }

      // find the nodes for each threshold group
      for (th = 0; th <= NUM_QUALITY_THOLDS; th++) {
         uint8_t max_th = (th == 0 ? 255 : q_tholds[th-1]);
         uint8_t min_th = (th == NUM_QUALITY_THOLDS ? 0 : q_tholds[th]);
         counts[th] = 0;

         for (i = 0; i < NEIGHBOR_LIST_LEN; i++) {
            if ((nbr[i] != INVALID_NODE_ID) && 
                (quality[i] < max_th) && (quality[i] >= min_th)) {
               // WARNING: packing an address into a 8-bit field!!!
               buf[pos++] = (uint8_t) nbr[i];
               counts[th]++;

               if (pos >= len) {  // shouldn't ever be greater than
                  return len;
               }
            }
         }
      }

      return pos;
   }

   // The buffer should contain a list of NUM_QUALITY_THOLDS+1 list lengths
   // followed by that many lists of node ids.
   command result_t Piggyback.receivePiggyback(wsnAddr addr, uint8_t* buf,
                                               uint8_t len) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);
      uint8_t th;
      uint8_t pos;
      uint8_t i;

      if (indx == INVALID_INDEX) {
         return FAIL;
      }

      pos = NUM_QUALITY_THOLDS + 1;

      for (th=0; th <= NUM_QUALITY_THOLDS; th++) {
         for (i=0; i<buf[th]; i++) {
            if (buf[pos] == (uint8_t) TOS_LOCAL_ADDRESS) {    // found myself
               outboundQuality[indx] = NUM_QUALITY_THOLDS - th;

               return SUCCESS;
            }
            pos++;
            if (pos >= len) {  // shouldn't ever be greater than
               outboundQuality[indx] = 0;
               return FAIL;
            }
         }
      }
      // I wasn't listed, so you haven't heard from me
      outboundQuality[indx] = 0;

      return FAIL;

   }

   event result_t NodeHistory.valueChanged(uint8_t indx) {
      return SUCCESS;
   }

   command uint8_t PickLowestQuality.pick() {
      uint8_t i;
      uint8_t worstIndex = INVALID_INDEX;
      uint8_t worstQuality = 255;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if (call NeighborMgmt.getAddrForIndex(i) != INVALID_NODE_ID) {
            uint8_t quality = call OutboundQuality.getValue(i);
            if (quality <= worstQuality) {
               worstIndex = i;
               worstQuality = quality;
            }
         }
      }
      return worstIndex;
   }


   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < NUM_QUALITY_THOLDS) {
         return FAIL;
      }

      for (i=0; i < NUM_QUALITY_THOLDS; i++) {
         q_tholds[i] = buf[i];
      }

      *len = NUM_QUALITY_THOLDS;

      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      uint8_t i;

      if (*len < NUM_QUALITY_THOLDS) {
         return FAIL;
      }

      for (i=0; i < NUM_QUALITY_THOLDS; i++) {
         buf[i] = q_tholds[i];
      }

      *len = NUM_QUALITY_THOLDS;

      return SUCCESS;
   }

   event void NeighborMgmt.setUpdateInterval(uint8_t interval) {
   }

}
