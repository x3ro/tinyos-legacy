includes CompressedSet;
includes PowerArbiter;
includes TimeSync;
includes ResultPacket;

module RollCallIncrM {
  provides {
    interface StdControl;
  }
  uses {
    interface RouteControl;

    interface SendMsg as SendReport;
    interface ReceiveMsg as ReceiveReport;

    interface AggressiveSendControl;

    interface EpochScheduler;
    interface PowerArbiter;

    interface Timer;
    interface Time;

    interface Random;

    interface HeartBeatHandler;

    interface Leds;
  }
}
implementation {

  // Nodes awaken every ROLLCALL_PERIOD...
#define ROLLCALL_PERIOD 10240
  
  // and wait for at most his long
#define MAX_ROUND_WAIT 3096

  // but, actually, for MAX_ROUND_WAIT - WAIT_PER_LEVEL * treeLevel...
#define WAIT_PER_LEVEL 205

  // before sending their reports, spread out randomly
  // over this interval
#define STAGGER_INTERVAL (WAIT_PER_LEVEL / 2)

  // The buffer which stores the bitmap is at most this long
  // max nodes = (MAX_LIVE_BITMAP_BYTES - 1) * 8
#define MAX_LIVE_BITMAP_BYTES 21

  // The length of the history (for suppressing stray packets)
#define MAX_LIVE_SET_HISTORY 1

#define MAX_SEND_RETRIES 2

#define MAX_NODES ((MAX_LIVE_BITMAP_BYTES - sizeof(Set)) << 3)

  // Forward decls ----------------------------

  // Clean up after sending your report
  void finishRound();

  enum {
    // Sending the full bitmap of live and dead nodes
    UPDATE_FULL = 0,
    // Sending the bitmap of just the newly discovered nodes
    UPDATE_DISC,
    // Sending the bitmap of just the failed nodes
    UPDATE_FAIL,
    // Sending the bitmap of just the failed nodes,
    // need a node to disprove that these nodes have failed
    UPDATE_QUERY
  };

  typedef struct {
    // Round of this communication
    uint16_t round:14;

    // Type of the roster message
    uint16_t type:2;

    // Set of nodes that we consider alive
    Set alive;
  } RosterMsg;

  uint32_t rollCallRound = 0;

  // A circular buffer of sets maintaining 
  // history
  uint8_t liveSetHistory[MAX_LIVE_SET_HISTORY][MAX_LIVE_BITMAP_BYTES];
  int8_t curLiveSet = 0;

  // Buffer for the liveness bitmap
  // To be recast into Set
  uint8_t lastLiveSet[MAX_LIVE_BITMAP_BYTES];
  bool lastLSValid = FALSE;

  void initLiveSets() {
    for (curLiveSet = 0; 
	 curLiveSet < MAX_LIVE_SET_HISTORY; 
	 curLiveSet++) {
      initSet(&liveSetHistory[curLiveSet][0], 
	      MAX_LIVE_BITMAP_BYTES);
    }

    initSet(lastLiveSet, MAX_LIVE_BITMAP_BYTES);

    curLiveSet = 0;
  }

  // Get the pointer to the current live Set
  Set *getLiveSet() {
    return (Set *)&liveSetHistory[curLiveSet][0];
  }
  
  // Fast forward the live set to the next one
  void switchLiveSet() {
    int8_t oldLiveSet = curLiveSet;

    if (++curLiveSet == MAX_LIVE_SET_HISTORY) {
      curLiveSet = 0;
    }

    // Invalidate the last live set
    lastLSValid = FALSE;

    // Carry over to the next round
    copySet((Set *)&liveSetHistory[curLiveSet][0], 
	    (Set *)&liveSetHistory[oldLiveSet][0]);
  }

  void aggregateHistory() {
    int8_t temp;
    uint8_t idx;

    // If the cached set value is invalid, need to recompute
    if (!lastLSValid) {
      initSet(lastLiveSet, MAX_LIVE_BITMAP_BYTES);
      
      for (temp = curLiveSet - MAX_LIVE_SET_HISTORY,
	     idx = curLiveSet - MAX_LIVE_SET_HISTORY; 
	   temp < curLiveSet;
	   temp++, idx++) {
	unionSets((Set *)lastLiveSet, 
		  (Set *)&liveSetHistory[idx %  MAX_LIVE_SET_HISTORY][0]);
      }

      lastLSValid = TRUE;
    }
  }

  bool liveSetChanged() {
    aggregateHistory();

    return !setsEqual((Set *)lastLiveSet,
		      (Set *)&liveSetHistory[curLiveSet][0]);
  }

  bool collectDiscoveredNodes(Set *newNodeSet) {
    aggregateHistory();

    copySet(newNodeSet, 
	    (Set *)&liveSetHistory[curLiveSet][0]);

    subtractSets((Set *)newNodeSet,
		 (Set *)lastLiveSet);

    return (newNodeSet->len == 0);
  }

  bool collectFailedNodes(Set *failedNodeSet) {
    aggregateHistory();

    copySet(failedNodeSet, 
	    (Set *)lastLiveSet);

    subtractSets((Set *)failedNodeSet,
		 (Set *)lastLiveSet);

    return (failedNodeSet->len == 0);
  }

  // Remember my old tree level so if that
  // changes, will need to adjust the epoch
  // scheduling and initial full update
  uint8_t treeLevel = 0xFF;

  TOS_Msg rollCallMsg;
  // Try to send again if busy
  uint8_t sendRetries = 0;

  command result_t StdControl.init() {

    call Leds.init();

    initLiveSets();

    return SUCCESS;
  }
  command result_t StdControl.start() {

    // Init the round timing
    call EpochScheduler.addSchedule(ROLLCALL_PERIOD,
				    MAX_ROUND_WAIT);

    // Prime the bitmap
    {
      Set *aliveBitmap = getLiveSet();

      // Note that I am alive :)
      setBit(aliveBitmap, TOS_LOCAL_ADDRESS);

      dbg(DBG_USR3, "^^ Alive bitmap is now\n");
      printSet(aliveBitmap);
    }

    call EpochScheduler.start();

    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveReport.receive(TOS_MsgPtr msg) {
    RosterMsg *aMsg = (RosterMsg *)msg->data;
    uint8_t buf2[MAX_LIVE_BITMAP_BYTES];
    Set *aliveSet = getLiveSet();
    Set *newSet = initSet(buf2, MAX_LIVE_BITMAP_BYTES);

    /*
     * Uncomment to reject packets to others

     if (msg->addr == TOS_LOCAL_ADDRESS)
     return msg;

     *
     */

    // Add -1 here to allow aggregates of two rounds
    if (aMsg->round != rollCallRound) {
      // Stale

      return msg;
    }

    dbg(DBG_USR3, "^^ Node %u reports set:\n", 
	call RouteControl.getSender(msg));
    printSetBits(&aMsg->alive);

    decompressSet(&aMsg->alive, newSet);

    if (aMsg->type == UPDATE_FULL ||
	aMsg->type == UPDATE_DISC) {

      dbg(DBG_USR3, "^^ A node reports these are alive (type=%s):\n",
	  aMsg->type == UPDATE_FULL ? "FULL" : "DISC");
      printSet(newSet);

      // This node is alive
      unionSets(aliveSet, newSet);
    } else {

      dbg(DBG_USR3, "^^ A node reports these have failed:\n");
      printSet(newSet);
      printSetBits(newSet);

      // Update type is "failure"
      subtractSets(aliveSet, newSet);
    }

    dbg(DBG_USR3, "^^ After union my set is:\n");
    printSet(aliveSet);
    printSetBits(aliveSet);

    return msg;
  }

  event void EpochScheduler.beginEpoch() {
    TimeStamp ts;

    //    call PowerArbiter.useResource(PWR_RADIO);

    tos2timeStamp(call Time.get(), ts);

    rollCallRound = timeStampDiv32(ts, ROLLCALL_PERIOD);

  }


  event void EpochScheduler.epochOver() {
    uint8_t curTreeLevel = call RouteControl.getDepth();

    // Check if our attachments have changed, change our schedule
    // if so
    if (curTreeLevel != treeLevel) {
      uint32_t waitingTime = curTreeLevel * WAIT_PER_LEVEL;

      dbg(DBG_USR1, "^^^^ Tree level change: from %u to %u!!!\n", 
	  treeLevel, curTreeLevel);

      if (waitingTime > MAX_ROUND_WAIT) {
	waitingTime = MAX_ROUND_WAIT;      
      }

      dbg(DBG_USR1, "^^^^ Tree level sets wait to %u\n", waitingTime);;

      treeLevel = curTreeLevel;

      call EpochScheduler.stop();

      call EpochScheduler.addSchedule(ROLLCALL_PERIOD,
				      MAX_ROUND_WAIT - 
				      waitingTime);

      call EpochScheduler.start();
    }

    call Timer.start(TIMER_ONE_SHOT,
		     (TOS_LOCAL_ADDRESS * (uint32_t)STAGGER_INTERVAL) / 
		     (uint32_t)MAX_NODES);
  }

  event result_t Timer.fired() {
    uint16_t maxLen;
    RosterMsg *aliveMsg = 
      (RosterMsg *)rollCallMsg.data;
    Set *aliveSet = (Set *)getLiveSet();
    // Variables for compression of the bitmap
    uint8_t projLen, idxLen;

    bool isGateway = (call RouteControl.getDepth() == 0);

    dbg(DBG_USR3, "^^ Round %u over, reporting these as alive to %u\n", 
	rollCallRound,
	call RouteControl.getParent());
    printSet(aliveSet);

    if (!liveSetChanged()) {
      // Not doing anything, absolutely
      dbg(DBG_USR3, "^^ UPDATE DECISION:  Idle this round\n");

      finishRound();

    } else {
      // Determine what has changed
      uint8_t buf2[MAX_LIVE_BITMAP_BYTES];
      
      if (collectFailedNodes((Set *)buf2)) {
	// Some nodes have failed
	dbg(DBG_USR3, "^^ UPDATE DECISION:  These nodes have failed\n");
	printSet((Set *)buf2);

	// Engage in local reconciliation

      } else {

      }
      
    }

    // Submit the report
    aliveMsg->round = rollCallRound;

    // XXX: Projected length might exceed
    // the size of the packet
    if (!isGateway &&
	preprocessSet(aliveSet, &projLen, &idxLen)) {
      
      // Compress the set
      compressSet(aliveSet, &aliveMsg->alive, idxLen);
    } else {
      // Copy the set
      copySet(&aliveMsg->alive, aliveSet);
    }
    

    dbg(DBG_USR3, "neighbor message SIZE OF ALIVE SET = %u, maxLen is %u\n", 
	sizeOfSet(aliveSet),
	maxLen);

    {
      uint16_t tgtAddr = TOS_BCAST_ADDR;
      
      dbg(DBG_USR3, "^^ level %d READY TO SHIP %d bytes to parent: %u%s", 
	  call RouteControl.getDepth(),
	  sizeof(RosterMsg) - sizeof(Set) +
	  sizeOfSet(&aliveMsg->alive),
	  call RouteControl.getParent(),
	  (call RouteControl.getDepth() == 0 ? "-------\n" : "\n"));
      printSet(&aliveMsg->alive);
      
      if (!isGateway) {
	tgtAddr = call RouteControl.getParent();
      } else {
	tgtAddr = TOS_UART_ADDR;
      }

      dbg(DBG_USR3, "^^ SHIPPING!!!\n");
      fflush(stdout);
      
      if (call SendReport.send(tgtAddr,
			       sizeof(RosterMsg) - sizeof(Set) +
			       sizeOfSet(&aliveMsg->alive),
			       &rollCallMsg) == FAIL) {

	call Leds.greenToggle();

	dbg(DBG_USR3, "^^ send FAILED to SHIP!\n");
	fflush(stdout);
	
	if (sendRetries > MAX_SEND_RETRIES) {
	  sendRetries = 0;

	  finishRound();
	} else {
	  sendRetries++;

	  call Timer.start(TIMER_ONE_SHOT,
			   WAIT_PER_LEVEL >> 1);
	}
      } else {
	dbg(DBG_USR3, "^^ send SHIPPED successfully!\n");	
	fflush(stdout);
      }
      
    }

    return SUCCESS;
  }

  event result_t SendReport.sendDone(TOS_MsgPtr msg,
				     result_t status) {

    dbg(DBG_USR3, "^^ sendDone\n");    

    finishRound();

    return SUCCESS;
  }

  void finishRound() {
    Set *aliveBitmap;

    switchLiveSet();

    // Note:  this function clears the live set
    aliveBitmap = getLiveSet();

    //    call PowerArbiter.releaseResource(PWR_RADIO);

    // Note that I am alive :)
    setBit(aliveBitmap, TOS_LOCAL_ADDRESS);

    dbg(DBG_USR3, "^^ After finishround, my alive set is\n");
    printSet(aliveBitmap);
  }

  event void HeartBeatHandler.receiveHeartBeat(uint16_t srcAddr,
					       VitalStats *vStats) {
    Set *aliveBitmap = getLiveSet();

    dbg(DBG_USR1, "Overheard heartbeat from %u as alive\n\n", srcAddr);

    setBit(aliveBitmap, srcAddr);

  }


}
