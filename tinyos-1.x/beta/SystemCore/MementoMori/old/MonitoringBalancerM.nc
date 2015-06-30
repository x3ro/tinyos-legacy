component MonitoringBalancerM {
  provides {
    interface StdControl;
    interface MonitoringBalancer;
    interface HeartBeatHandler as HeartBeatHandlerExt;
  }
  uses {
    interface HeartBeatHandler;
    interface FailureDetector;
    interface MonitoringState;

    interface Time;
  }
}
implementation {

  // We are monitoring this many nodes
  uint8_t numMonitored = 0;

  // ...of them, this many are under evaluation
  // to replace our monitoring targets
  uint8_t numCandidates = 0;

  uint16_t monitorsBuf[MAX_MONITOR_BUF];
  uint8_t numMonEst = 0;

  //------------ StdControl -----------------

  command result_t StdControl.init() {

    NodeList *ml = (NodeList *)monitorsBuf;

    clearNList(ml);

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  //------------ MonitoringBalancer ---------
  

  command void MonitoringBalancer.resetMonitors() {
  }

  command void MonitoringBalancer.monitoredBy(uint16_t addr) {
    NodeList *ml = (NodeList *)monitorsBuf;

    addNList(ml, addr, MAX_MONITOR_BUF - 1);

    call NodeTimeout.add(addr, NT_MONITORED, 5 * ROLLCALL_PERIOD);
    call NodeTimeout.update(addr, NT_MONITORED);
  }

  event void NodeTimout.timedOut(uint16_t addr, uint8_t type) {
    if (type == NT_MONITORED) {
      // The node that we think monitors
      // us has excluded us from the list of nodes
      // it monitors for a very long time

      // Remove it from the list of our monitors
      call NodeTimeout.remove(addr, NT_MONITORED);
      delNList(ml, addr);

    } else if (type == NT_MONITORING) {
      // The node that we are monitoring
      // cannot hear from us and thus overestimates

      // Remove it from our list of nodes that
      // we monitor
      call NodeTimeout.remove(addr, NT_MONITORING);
      call MonitoringState.del(addr);
    }
  }

  event void NodeTimeout.timeoutReset(uint16_t addr, uint8_t type) {
  }

  command void MonitoringBalancer.exportMonitorList(uint8_t *numMonEstimate,
						    NodeList *ml,
						    uint8_t maxLen) {
    NodeList *_ml = (NodeList *)monitorsBuf;

    *numMonEstimate = ml->len;

    copyNList(ml, _ml, maxLen);
  }

  command void MonitoringBalancer.processMonitorList(uint16_t srcAddr,
						     uint8_t numMonEstimate,
						     NodeList *nl) {
    MonitorRec *mr = call MonitoringState.lookup(srcAddr);

    if (mr != NULL && !mr->candidate) {

      call NodeTimeout.add(srcAddr, NT_MONITORING, 5 * ROLLCALL_PERIOD);

      {
	// We are watching this node, but does it know
	// that?
	uint8_t i, myHash = addrHash(TOS_LOCAL_ADDRESS);
	
	for (i = 0; i < nl->len; i++) {
	  if (nl->addrHash[i] == myHash) {
	    break;
	  }
	}

	if (i != nl->len) {
	  // This node knows we are monitoring it!
	  call NodeTimeout.update(srcAddr, NT_MONITORING);
	}
	
      }

      mr->coverage = numMonEstimate;

    }
  }

  //------------ MonitoringState ------------

  event void MonitoringState.added(uint16_t addr) {
    MonitoringRec *mr;
    
    if ((mr = call MonitoringState.lookup(addr)) == NULL)
      return;

    // XXX:  Should it be this?
    mr->coverage = 0xFF;
  }

  event void MonitoringState.deleted(uint16_t addr) {
  }

  //----------------- HeartBeatHandler --------------------------

  bool ripe(uint8_t i) {
    return timeStampDiff(now, candiCache[i].startTime) > 
      CANDIDATE_PROBATION;
  }

  bool qualifies(uint8_t i) {
    return candiCache[i].numHeartBeats > CANDIDATE_QUALIFY;
  }

  bool better(MonitorRec *mr1,
	      MonitorRec *mr2) {

    return (call FailureDetector.getTimeout(mr1->srcAddr) <
	    call FailureDetector.getTimeout(mr2->srcAddr) &&
	    mr2->coverage != 0xFF && // Uninitialized
	    mr1->coverage <= m2->coverage);
  }

  // This part determines whether a new node should replace
  // an old node in the watcher cache

  event void HeartBeatHandler.receiveHeartBeat(uint16_t srcAddr,
					       VitalStats *vStats) {

    MonitorRec *mr = call MonitoringState.lookup(srcAddr);

    if (mr == NULL) {
      // We are not currently tracking this node

      // Should we add it to the cache of candidates?
      
      if (numCandidates < MAX_CANDIDATES) {
	// Add to the candidate cache
	uint8_t i;

	for (i = 0; i < MAX_CANDIDATES; i++) {
	  if (candiCache[i].mr == NULL &&
	      ((candiCache[i].mr = mr = 
		call MonitoringState.add(srcAddr)) != NULL)) {
	  
	    candiCache[i].numHeartBeats = 1;
	    curTimeStamp(candiCache[i].startTime);
	  
	    mr->candidate = TRUE;
	  
	    numCandidates++;
	    break;
	  }
	}
      } 

    } else if (mr->candidate) {
      // We are tracking this node but it's a candidate
      uint8_t i;
      TimeStamp now;

      for (i = 0; i < MAX_CANDIDATES; i++) {
	if (candiCache[i].mr == mr) {
	  break;
	}
      }

      if (i == MAX_CANDIDATES) {
	dbg(DBG_USR1, "*** ERROR:  Candidate not found in cache!!!\n");
	return;
      }

      curTimeStamp(now);

      // See if the candidate has graduated
      if (ripe(i)) {
	// Timed out, time to evaluate
	if (qualifies(i)) {
	  // This candidate has qualified, add it to the
	  // system

	  if (numMonitored + numCandidates < MAX_WATCHED) {
	    // Just add, we have space

	    mr->candidate = FALSE;
	    numMonitored++;

	    candiCache[i].mr = NULL;
	    numCandidates--;

	  } else {
	    // Need to replace another in the cache
	    MonitorIterator mi;
	    MonitorRec *cur = NULL, *worst = NULL;
	    
	    call MonitoringState.iterate(&mi);
	    while ((cur = call MonitoringState.next(&mi)) != NULL) {
	      if (!cur->candidate &&
		  (worst == NULL ||
		   better(worst, cur))) 
		worst = cur;
	    }

	    if (worst == NULL) {
	      dbg(DBG_USR1, "*** ERROR:  Worst is NULL\n");

	      return;
	    }
	    
	    if (better(mr, worst)) {
	      call MonitoringState.del(worst->srcAddr);
	      // numMonitored stays the same

	      candiCache[i].mr = NULL;
	      mr->candidate = FALSE;
	      numCandidates--;

	    }
	  }

	} else {
	  // This candidate does not pass muster
	  call MonitoringState.del(candiCache[i].mr->srcAddr);

	  candiCache[i].mr = NULL;
	  numCandidates--;
	}

      }

    }

    // Pass-through to the failure detector
    call HeartBeatHandlerExt.receiveHeartBeat(srcAddr,
					      vStats);

  }

  event void HeartBeatHandler.receivePacket(uint16_t srcAddr) {
    call HeartBeatHandlerExt.receivePacket(srcAddr);

  }

  //----------------- FailureDetector ---------------------------

  event void FailureDetector.opinionChanged(uint16_t addr, 
					    FOpinion oldOp,
					    FOpionion newOp) {
  }
}
