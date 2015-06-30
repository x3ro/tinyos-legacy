includes DFDTypes;

module MonitoringStateM {
  provides {
    interface StdControl;
    interface MonitoringState;
  }

  /*
  uses {
    interface VitalStats;
  }
  */
}
implementation {

  // Watcher slots
  // Total #=MAX_WATCHED slots
  MonitorRec wSlot[MAX_WATCHED];

  void printTable() {
    uint8_t i;

    dbg(DBG_USR1, "MonitoringState ------------------\n");
    dbg(DBG_USR1, "==================================\n");

    for (i = 0; i < MAX_WATCHED; i++) {
      if (!wSlot[i].free) {
	dbg(DBG_USR1, 
	    "%u\tCov: %u\t%s\t%s\n",
	    wSlot[i].srcAddr,
	    wSlot[i].coverage,
	    (wSlot[i].free == TRUE ? "FREE" : "OCCD"),
	    (wSlot[i].candidate ? "CAND" : "FULL"),
	    (wSlot[i].status == FOP_UNCERTAIN ? "UNCR" :
	     (wSlot[i].status == FOP_ALIVE ? "ALIV" :
	      (wSlot[i].status == FOP_TENTATIVELY_FAILED ? "TFAIL" :
	       (wSlot[i].status == FOP_FAILED ? "FAIL" : "UNKN"))))
	    );
      }
    }
    dbg(DBG_USR1, "\n");
  }
  
  //------------- StdControl ------------------------

  command result_t StdControl.init() {
    uint8_t i;

    for (i = 0; i < MAX_WATCHED; i++) {
      wSlot[i].free = TRUE;
    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  //------------- MonitoringState -------------------

    /**
   * Looks up a monitoring record for the node 
   * addr.
   * 
   * @param addr The address of the node
   * 
   * @return NULL if we are not monitoring this node,
   * pointer to the record if we are.
   **/
  command MonitorRec *MonitoringState.lookup(uint16_t addr) {
    uint8_t i;
    
    for (i = 0; i < MAX_WATCHED; i++) {
      if (wSlot[i].srcAddr == addr &&
	  !wSlot[i].free) {
	return &wSlot[i];
      }
    }
    
    return NULL;
  }



  // Initialize a free, new spot
  void fillMonitorSlot(uint8_t idx, uint16_t addr) {
    wSlot[idx].srcAddr = addr;

    //    call VitalStats.init(&wSlot[idx].stats);

    wSlot[idx].free = FALSE;

    wSlot[idx].status = FOP_ALIVE;
    wSlot[idx].candidate = FALSE;

    wSlot[idx].coverage = 0xFF;

    dbg(DBG_USR2, "Initialized %d\n");
    
  }


  /**
   *
   * Adds a monitoring record for this node,
   * sets up the data structures properly
   * 
   * @param addr Address of the node to add
   * 
   * @return NULL if there is no more space,
   * pointer to the record if we added successfully
   *
   **/
  command MonitorRec *MonitoringState.add(uint16_t addr) {
    uint8_t i, 
      firstFree = MAX_WATCHED;

     dbg(DBG_USR2, "*** ADDTOWATCH\n");
     
     // Find a free slot, ideally one whose hash matches src
     for (i = 0; i < MAX_WATCHED; i++) {
       if (firstFree == MAX_WATCHED &&
	   wSlot[i].free) {
	 firstFree = i;
       }
     }

     if (firstFree == MAX_WATCHED)
       return NULL;
     else {
       fillMonitorSlot(firstFree, addr);

       printTable();

       signal MonitoringState.added(addr);

       return &wSlot[firstFree];
     }
  }

  /**
   * Delete a given node from list of monitored
   *
   * @param addr Address of the node
   *
   * @return SUCCESS if the node was located and deleted.
   **/
  command result_t MonitoringState.del(uint16_t addr) {
    MonitorRec *result = call MonitoringState.lookup(addr);

    if (result == NULL)
      return FAIL;

    result->free = TRUE;

    signal MonitoringState.deleted(addr);

    printTable();

    return SUCCESS;
  }

  command bool MonitoringState.amMonitoring(uint16_t addr) {
    return !(call MonitoringState.lookup(addr) == NULL);
  }

  /**
   * Export the records and liveness opinions
   * about the nodes which we monitor.
   *
   * @param wl Pointer to the list of watched nodes
   * @param mask A bitmap where (bit at i == 1) => (node wl[i] is alive)
   **/
  command void MonitoringState.exportWatched(NodeList *wl, 
					     uint32_t *mask) {
    uint8_t i, _numWatched = 0;

    for (i = 0; i < MAX_WATCHED; i++) {
      if (!wSlot[i].free &&
	  !wSlot[i].candidate) {
	wl->addrHash[_numWatched] = addrHash(wSlot[i].srcAddr);
	
	if (wSlot[i].status == FOP_ALIVE)
	  (*mask) |= (1 << (_numWatched));

	_numWatched++;
      }
    }

    wl->len = _numWatched;
  }

  /**
   * Begins the iteration over the list of actively monitored
   * nodes
   *
   * @param mi Pointer to the iterator
   **/
  command void MonitoringState.iterate(MonitorIterator *mi) {
    mi->idx = 0;
  }

  /**
   * Iterates to the next actively monitored
   * node.  All iteration must happen within
   * the context of a single task to ensure
   * correctness of the semantics of this call.
   *
   * @param mi Pointer to the iterator
   *
   * @return Returns NULL when no more records
   * are available, or pointer to the next
   * monitoring record
   **/
  command MonitorRec *MonitoringState.next(MonitorIterator *mi) {
    uint8_t i;

    for (i = mi->idx; i < MAX_WATCHED; i++) {
      if (!wSlot[i].free) {
	mi->idx = i + 1;

	return &wSlot[i];
      }
    }

    return NULL;
  }

  //--------------- Helper funcs ------------------------


}
