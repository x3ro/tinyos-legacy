includes Timer;
includes NeighborList;

// TODO: we should probably increment the individual ages rather than
//       a clock.  This will allow us to detect timestamp overflow.

module NeighborAgeM {
   provides {
      interface ByteValue as NodeAge; // allow access to age data
      interface StdControl;
      interface Pick as PickOldest;
      interface Pick as PickYoungest;
      interface NeighborAge; // for external use
   }
   uses {
      interface Timer;
      interface ByteValue as Trigger; // when should I update?
      interface NeighborMgmt;
      interface Leds;
   }
}

implementation
{
   uint8_t timestamp[NEIGHBOR_LIST_LEN];
   uint8_t currentTime;
   uint8_t updateInterval;

   command result_t StdControl.init() {
      currentTime = 0;
      updateInterval = NEIGHBOR_LIST_UPDATE_INTERVAL;
      return SUCCESS;
   }

   result_t setTimer() {
      call Timer.stop();
      return call Timer.start(TIMER_REPEAT, updateInterval*CLOCK_SCALE);
   }

   command result_t StdControl.start() {
      currentTime = 0;
      return setTimer();
   }

   command result_t StdControl.stop() {
      return call Timer.stop();
   }

   command uint8_t NodeAge.getValue(uint8_t indx) {
      return (currentTime - timestamp[indx]);
   }

   default event result_t NodeAge.valueChanged(uint8_t indx) {
      return SUCCESS;
   }

   event result_t Trigger.valueChanged(uint8_t indx) {
      timestamp[indx] = currentTime;
      return signal NodeAge.valueChanged(indx);
   }

   event void NeighborMgmt.initializeIndex(uint8_t indx) {
      timestamp[indx] = currentTime;
   }

#ifdef NEIGHBOR_AGE_CACHE_TIMEOUT
   task void removeStaleNeighbors() {
      uint8_t i;
      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if ((call NeighborMgmt.getAddrForIndex(i)!=INVALID_NODE_ID) && 
             ((currentTime - timestamp[i]) > NEIGHBOR_AGE_CACHE_TIMEOUT)) {
            call NeighborMgmt.removeNode(i);
         }
      }
   }
#endif

   event result_t Timer.fired() {
      currentTime++;
#ifdef NEIGHBOR_AGE_CACHE_TIMEOUT
      post removeStaleNeighbors();
#endif
      return SUCCESS;
   }

   command uint8_t PickOldest.pick() {
      uint8_t i;
      uint8_t bestVal = 0;
      uint8_t bestIndex = INVALID_INDEX;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if ((call NeighborMgmt.getAddrForIndex(i)!=INVALID_NODE_ID) && 
             ((currentTime - timestamp[i])>= bestVal)) {
            bestVal = (currentTime - timestamp[i]);
            bestIndex = i;
         }
      }
      return bestIndex;
   }

   command uint8_t PickYoungest.pick() {
      uint8_t i;
      uint8_t bestVal = 255;
      uint8_t bestIndex = INVALID_INDEX;

      for (i=0; i<NEIGHBOR_LIST_LEN; i++) {
         if ((call NeighborMgmt.getAddrForIndex(i)!=INVALID_NODE_ID) && 
             ((currentTime - timestamp[i])<= bestVal)) {
            bestVal = (currentTime - timestamp[i]);
            bestIndex = i;
         }
      }
      return bestIndex;
   }

   command result_t NeighborAge.neighborAge(wsnAddr addr, uint8_t *age) {
      uint8_t indx = call NeighborMgmt.getIndexForNode(addr);
      if (indx == INVALID_INDEX) {
         return FAIL;
      } else {
         *age = timestamp[indx];
         return SUCCESS;
      }
   }

   event void NeighborMgmt.setUpdateInterval(uint8_t interval) {
      updateInterval = interval;
      setTimer();
   }  
}
