includes Timer;
includes NeighborList;

module NeighborHistoryM {
   provides {
      interface ByteValue as NodeHistory; // allow access and notify 
                                              // of updates
      interface StdControl;
      interface NeighborQuality;  // for external use
      interface Pick as PickLowestQuality;
      interface Settings;
   }
   uses {
      interface Timer;
      interface SequenceNumber;  // input from single hop layer
      interface NeighborMgmt;
      interface ByteValue as NodeAge;
      interface Leds;
   }
}

implementation
{
   typedef struct {
      uint8_t lastSeqNum;
      uint8_t lastSeqNumAssumed;
      HistoryBits_t historyBits;
   } NodeHistory_t;

   NodeHistory_t history[NEIGHBOR_LIST_LEN];

   uint8_t neighborTimeout;
   uint8_t timeoutPenalty;
   uint8_t updateInterval;
   uint16_t timerCounter;

   uint8_t countBitsSet(HistoryBits_t data) {
      uint8_t i;
      uint8_t ret=0;

//    dbg(DBG_TEMP, ("nbrlist_get_bits_set %02x\n", data));

      if(data == 0L){
         return 0;
      }
      for(i = 0; i < NUM_HISTORY_BITS; i++){
         if(data & 0x01L){
            ret++;
         }
         data >>= 1;
      }

//    dbg(DBG_TEMP, ("Ldans_get_bits_set:  %x ==> %x bits set\n", data, ret));

      return ret;
   }

   command result_t StdControl.init() {
      timerCounter = 0;
      neighborTimeout = NEIGHBOR_LIST_NBR_TIMEOUT;
      updateInterval = NEIGHBOR_LIST_UPDATE_INTERVAL;
      timeoutPenalty = NEIGHBOR_HISTORY_PENALTY;
      return SUCCESS;
   }

   command result_t StdControl.start() {
      return call Timer.start(TIMER_REPEAT, CLOCK_SCALE);
   }

   command result_t StdControl.stop() {
      return call Timer.stop();
   }

   command uint8_t NodeHistory.getValue(uint8_t indx) {
      return countBitsSet(history[indx].historyBits);
   }

   default event result_t NodeHistory.valueChanged(uint8_t indx) {
      return SUCCESS;
   }

   event void NeighborMgmt.initializeIndex(uint8_t indx) {
      // We don't really want to get here except by going through 
      // updateSeqNum.  But, in case we do, do something reasonable.

      history[indx].historyBits = NEIGHBOR_HISTORY_INITIAL_VALUE;
      history[indx].lastSeqNum = 0;
      history[indx].lastSeqNumAssumed = 0;
   }

   command uint8_t PickLowestQuality.pick() {
      uint8_t i;
      uint8_t bestIndex = INVALID_INDEX;
      uint8_t bestVal = 255;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if ((call NeighborMgmt.getAddrForIndex(i)!=INVALID_NODE_ID) &&
             (countBitsSet(history[i].historyBits) <= bestVal)) {
            bestIndex = i;
         }
      }
      return bestIndex;
   }

   task void assessPenalties() {
      uint8_t i;
      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         // Node age is measured in multiples of updateInterval
         if ((call NeighborMgmt.getAddrForIndex(i) != INVALID_NODE_ID) &&
             (call NodeAge.getValue(i) > neighborTimeout)) {
               history[i].historyBits <<= timeoutPenalty;
               history[i].lastSeqNumAssumed += timeoutPenalty;
         }
      }
   }

   event result_t Timer.fired() {
      if (timerCounter > updateInterval) {
         if (post assessPenalties()) {
            timerCounter = 0;
         }
      }
      timerCounter++;
      return SUCCESS;
   }

   event void SequenceNumber.updateSeqNum(wsnAddr addr, uint8_t seqNum) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);

      if (indx == INVALID_INDEX) {  // no history at the moment
         indx = call NeighborMgmt.addNode(addr);
         history[indx].historyBits = NEIGHBOR_HISTORY_INITIAL_VALUE;
         history[indx].lastSeqNum = seqNum;
         history[indx].lastSeqNumAssumed = seqNum;

      } else {
         NodeHistory_t *nbrPtr = &(history[indx]);
         bool setLastBit = TRUE;

         // wraparound should work due to unsigned math
         uint8_t bitShifts = seqNum - nbrPtr->lastSeqNum;

         //The following is to avoid giving a double penalty after a timeout:
         //  once during bitshifting after timeout, followed by second when a
         //  packet is received indicating missed sequence numbers
         if (nbrPtr->lastSeqNum == nbrPtr->lastSeqNumAssumed) {
             // we have not assumed packet loss during since the last packet
             // was received
            nbrPtr->lastSeqNumAssumed = seqNum;
         } else {
            uint8_t bitLocation = (nbrPtr->lastSeqNumAssumed - seqNum);
            if (bitLocation < 32) {
               // We received a packet after we already assumed it was lost
               //   Don't do more bitshifting, and instead of setting the
               //   last bit, set the bit corresponding to this sequence number
               HistoryBits_t maskbits = 1;

               bitShifts = 0;
               setLastBit = FALSE;

               maskbits <<= bitLocation;
               nbrPtr->historyBits |= maskbits;
            } else {
               // Only shift relative to the last assumed packet rather than
               // the last received packet
               bitShifts = seqNum - nbrPtr->lastSeqNumAssumed;
               nbrPtr->lastSeqNumAssumed = seqNum;
            }
         }

         nbrPtr->lastSeqNum = seqNum;
         nbrPtr->historyBits <<= bitShifts;

         nbrPtr->historyBits |= (setLastBit ? 1 : 0);

      }

      dbg(DBG_USR1,"NeighborHistory got seq %d from node %d, history = %x\n", seqNum, addr, history[indx].historyBits);

      signal NodeHistory.valueChanged(indx);

   }

   command uint16_t NeighborQuality.getNeighborQuality(wsnAddr addr) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);

      if (indx == INVALID_INDEX) {
         return (uint16_t)countBitsSet(NEIGHBOR_HISTORY_INITIAL_VALUE);
      } else {
         return (uint16_t)(call NodeHistory.getValue(indx));
      }
   }

   event result_t NodeAge.valueChanged(uint8_t indx) {
      return SUCCESS;
   }

   command result_t Settings.updateSetting(uint8_t *buf, uint8_t *len) {
      if (*len < 2) {
         return FAIL;
      }

      neighborTimeout = buf[0];
      timeoutPenalty = buf[1];

      *len = 2;

      return SUCCESS;
   }

   command result_t Settings.fillSetting(uint8_t *buf, uint8_t *len) {
      if (*len < 2) {
         return FAIL;
      }

      buf[0] = neighborTimeout;
      buf[1] = timeoutPenalty;

      *len = 2;

      return SUCCESS;
   }

   event void NeighborMgmt.setUpdateInterval(uint8_t interval) {
      updateInterval = interval;
   }

}
