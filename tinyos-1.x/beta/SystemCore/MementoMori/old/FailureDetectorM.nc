includes DFDTypes;

module FailureDetectorM {
  provides {
    interface StdControl;
    interface FailureDetector;
    
  }
  uses {
    interface HeartBeatHandler;
    interface MonitoringState;
    
    interface NodeTimeout;
  }
}
implementation {

  MonitorRec *earliest = NULL;

  //------------ StdControl -----------------

  command result_t StdControl.init() {

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  //------------ MonitoringState ------------

  event void MonitoringState.added(uint16_t addr) {
    MonitorRec *mr = call MonitoringState.lookup(addr);

    if (mr == NULL)
      return;

    mr->status = FOP_ALIVE;

    call NodeTimeout.add(addr, NT_FAIL_DETECTOR, 
			 call HeartBeatHandler.getPeriod());


  }

  event void MonitoringState.deleted(uint16_t addr) {
    call NodeTimeout.remove(addr, NT_FAIL_DETECTOR);
  }

  //------------ FailureDetector ------------

 /**
   * Queries the status of a node
   *
   * @param addr Address of the node in question
   *
   * @result Returns one of 
   * {FOP_ALIVE, FOP_FAILED, FOP_UNCERTAIN}
   **/
  command FOpinion FailureDetector.getOpinion(uint16_t addr) {
    MonitorRec *mr = call MonitoringState.lookup(addr);

    if (mr == NULL)
      return FOP_UNCERTAIN;
    else
      return (mr->status);
    
  }

  /**
   * Share the opinion of an external node
   * regarding the status of this node.
   *
   * @param src Source of the opinion
   * @param addr Monitoring target whose status is being claimed
   * @param op The failure status opinion
   * 
   * @returns FAIL if we are not responsible for monitoring addr
   **/
  command result_t FailureDetector.imposeOpinion(uint16_t addr, 
						   FOpinion op) {
    MonitorRec *mr = call MonitoringState.lookup(addr);

    if (mr == NULL)
      return FAIL;

    if (mr->status != op) {
      signal FailureDetector.opinionChanged(addr, 
					    mr->status,
					    op);
    }

    mr->status = op;

    return SUCCESS;
  }

  /**
   * Queries the preiod of failure detection
   * for this node (in 1/1024th of a second).
   *
   * @param addr Address of the node
   *
   * @returns 0xFFFFFFFF if we do not watch over this node,
   * the timeout period otherwise
   **/
  command uint32_t FailureDetector.getTimeout(uint16_t addr) {
    MonitorRec *mr = call MonitoringState.lookup(addr);

    if (mr == NULL)
      return 0xFFFFFFFF;
    else
      return call NodeTimeout.getTimeout(addr, NT_FAIL_DETECTOR);
  }

  /**
   * Postpone the timeout of a given node
   * by a given delay
   *
   * @param addr Address of the node
   * @param delay Postpone by this much 1/1024th of a second
   **/
  command result_t FailureDetector.postpone(uint16_t addr, uint32_t delay) {
    MonitorRec *mr = call MonitoringState.lookup(addr);

    if (mr == NULL)
      return FAIL;

    call NodeTimeout.postpone(addr, NT_FAIL_DETECTOR, delay);
  }


  //----------------- HeartBeatHandler --------------------------

  event void HeartBeatHandler.receiveHeartBeat(uint16_t srcAddr,
					       VitalStats *vStats) {
    MonitorRec *mr = call MonitoringState.lookup(srcAddr);

    dbg(DBG_USR1, "GOT HEARTBEAT FROM %u\n", srcAddr);

    if (mr == NULL) {
      dbg(DBG_USR1, "Not my node: %u\n", srcAddr);
 
      return;
    }

    // Copy the core state
    //    call VitalStats.copy(&wSlot[wIndex].stats, vStats);

    call NodeTimeout.update(srcAddr, NT_FAIL_DETECTOR);
    call HeartBeatHandler.getPeriod();

    call FailureDetector.imposeOpinion(srcAddr,
				       FOP_ALIVE);
    

    return;
  }

/*
  event void HeartBeatHandler.receivePacket(uint16_t srcAddr) {
    MonitorRec *mr = call MonitoringState.lookup(addr);

    if (mr == NULL) {
 
      return;
    }    

    call FailureDetector.postpone(srcAddr,
				  call FailureDetector.getTimeout(srcAddr));

    call FailureDetector.imposeOpinion(srcAddr, FOP_ALIVE);

    return;
  }
*/

  // ------- NodeTimeout ------------------------------------

  event void NodeTimeout.timedOut(uint16_t addr, uint8_t type) {
    if (type == NT_FAIL_DETECTOR) {
      MonitorRec *mr = call MonitoringState.lookup(addr);
      uint8_t oldStatus;
      
      if (mr == NULL) {
	dbg(DBG_USR1, "*** ERROR:  NodeTimeout.timedOut could not find %u\n", addr);
	
	return;
      }

      oldStatus = mr->status;
      mr->status = FOP_TENTATIVELY_FAILED;

      signal FailureDetector.opinionChanged(addr, oldStatus, 
					    FOP_TENTATIVELY_FAILED);

    }
  }

  event void NodeTimeout.timeoutReset(uint16_t addr, uint8_t type) {
    if (type == NT_FAIL_DETECTOR) {
      MonitorRec *mr = call MonitoringState.lookup(addr);
      uint8_t oldStatus;
      
      if (mr == NULL) {
	dbg(DBG_USR1, "*** ERROR:  NodeTimeout.timedOut could not find %u\n", addr);
	
	return;
      }

      oldStatus = mr->status;
      mr->status = FOP_ALIVE;

      signal FailureDetector.opinionChanged(addr, oldStatus, 
					    FOP_ALIVE);

    }
  }

}
