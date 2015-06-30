includes CompressedSet;
includes PowerArbiter;
includes TimeSync;
includes ResultPacket;
includes TimeStamp;
includes PacketTypes;

includes CommonParams;

module RollCallM {
  provides {
    interface StdControl;
  }
  uses {
    interface RouteControl;

    interface SendMsg as SendReport;
    interface ReceiveMsg as ReceiveReport;

    interface AggressiveSendControl as AggSendCtl;

    interface EpochScheduler;
    interface PowerArbiter;

    interface Timer;
    interface Time;

    interface Random;

    interface HeartBeatHandler;

    interface Leds;

    // For sending the stats to the UART
    interface SendMsg as SendStats;

    interface Roster;

    interface TimeSetListener; 
  }
}
implementation {

  // Forward decls ----------------------------

  // Clean up after sending your report
  void finishRound();
  void sendReport();

  uint32_t rollCallRound = 0;

  // Buffer for the liveness bitmap
  // To be recast into Set
  uint8_t lastLiveSet[MAX_LIVE_BITMAP_BYTES];
  bool lastLSValid = FALSE;

  uint8_t liveSetHistory[MAX_LIVE_SET_HISTORY][MAX_LIVE_BITMAP_BYTES];
  int8_t curLiveSet = 0;

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
    if (++curLiveSet == MAX_LIVE_SET_HISTORY) {
      curLiveSet = 0;
    }

    // Invalidate the last live set
    lastLSValid = FALSE;

    initSet(&liveSetHistory[curLiveSet][0], 
	    MAX_LIVE_BITMAP_BYTES);
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

  // Remember my old tree level so if that
  // changes, will need to adjust the epoch
  // scheduling
  uint8_t treeLevel = 0xFF;
  
  // Has the round come to completion?
  bool roundOver = TRUE;

  TOS_Msg rollCallMsg;

  TOS_Msg statsMsg;
  ResultPkt *statsPkt = NULL;

  command result_t StdControl.init() {

    call Leds.init();

    initLiveSets();
    
    {
      statsPkt = (ResultPkt *)statsMsg.data;

      memset(statsPkt, 0, sizeof(ResultPkt));
    }

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

    // Add -1 here to allow aggregates of two rounds
    if (aMsg->round != rollCallRound ||
	roundOver) {
      if (msg->addr == TOS_LOCAL_ADDRESS) {
	  statsPkt->numLate++;
      } 
      return msg;
    }
  
    dbg(DBG_USR3, "^^ Node reports set:\n", 
	call RouteControl.getSender(msg));
    printSetBits(&aMsg->alive);
    
    decompressSet(&aMsg->alive, newSet);
    
    dbg(DBG_USR3, "^^ A node reports these are alive:\n");
    printSet(newSet);
    printSetBits(newSet);
    
    unionSets(aliveSet, newSet);
    
    dbg(DBG_USR3, "^^ After union my set is:\n");
    printSet(aliveSet);
    printSetBits(aliveSet);
    
    return msg;
  }

  void updateRollCallRound() {
    tos_time_t t;
    TimeStamp ts;

    //    call PowerArbiter.useResource(PWR_RADIO);
    t = call Time.get();
    tos2timeStamp(t, ts);

    rollCallRound = timeStampDiv32(ts, ROLLCALL_PERIOD);

    dbg(DBG_USR1, 
	"Round  = (%u,%u) divided by %u\n",
	t.low32, t.high32, ROLLCALL_PERIOD);
	
  }

  event void EpochScheduler.beginEpoch() {

    roundOver = FALSE;

    updateRollCallRound();

    call Leds.yellowOn();

  }


  event void EpochScheduler.epochOver() {

    uint8_t curTreeLevel = call RouteControl.getDepth();

    call Leds.yellowOff();

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
    Set *aliveSet = (Set *)getLiveSet();
    bool isGateway = (call RouteControl.getDepth() == 0) &&
      (call RouteControl.getParent() != TOS_BCAST_ADDR);
    RosterMsg *aliveMsg = 
      (RosterMsg *)rollCallMsg.data;
    
    // Variables for the compression of the bitmap
    uint16_t projLen, idxLen;

    tos_time_t ts;

    ts = call Time.get();

    dbg(DBG_USR3, 
	"^^ Round %u over (time=%u,%u), reporting these as alive to %u\n", 
	rollCallRound,ts.low32, ts.high32,
	call RouteControl.getParent());
    printSet(aliveSet);
 
    // Submit the report
    aliveMsg->round = rollCallRound;
    
    // XXX: Projected length might exceed
    // the size of the packet
    if (!isGateway) {

      if (preprocessSet(aliveSet, &projLen, &idxLen)) {

	//	call Leds.redToggle();
	
	// Compress the set
	compressSet(aliveSet, &aliveMsg->alive, idxLen);
      } else {

	//	call Leds.greenToggle();

	// Copy the set
	copySet(&aliveMsg->alive, aliveSet);
      }
    } else {
      // Report just the dead nodes
      
      copySet(&aliveMsg->alive, call Roster.getRoster());
      subtractSets(&aliveMsg->alive, aliveSet);

      dbg(DBG_USR3, "~~ Gateway node reports these have died\n");
      printSet(&aliveMsg->alive);

      statsPkt->numFailedNodes += setLength(&aliveMsg->alive);
    }
    
    dbg(DBG_USR3, "neighbor message SIZE OF ALIVE SET = %u\n", 
	projLen);
    
    {
      uint16_t tgtAddr = TOS_BCAST_ADDR;
      uint16_t pktSize;
      uint8_t saveBcastRetries;
      
      if (isGateway) {
	tgtAddr = TOS_UART_ADDR;

	// The padding is to fix the weird issue with how 
	// mig-generated handlers process empty, zero-size
	// packets
	pktSize = sizeof(RosterMsg) - sizeof(Set) +
	  sizeOfSet(&aliveMsg->alive) + (aliveMsg->alive.len == 0 ? 1 : 0);

      } else {
	tgtAddr = call RouteControl.getParent();
	pktSize = sizeof(RosterMsg) - sizeof(Set) +
	  projLen;
      }

      if (tgtAddr == TOS_BCAST_ADDR) {
	saveBcastRetries = call AggSendCtl.getBcastRetries();

	call AggSendCtl.setBcastRetries(call AggSendCtl.getRetries());
      }

      dbg(DBG_USR3, 
	  "^^ level %d READY TO SHIP %d bytes (%d - %d + %d) (%s) to parent: %u%s", 
	  call RouteControl.getDepth(),
	  pktSize,
	  sizeof(RosterMsg),
	  sizeof(Set),
	  sizeOfSet(&aliveMsg->alive),
	  (aliveMsg->alive.compressed ? "COMPRESSED" : "UNCOMPRESSED"),
	  call RouteControl.getParent(),
	  (call RouteControl.getDepth() == 0 ? "-------\n" : "\n"));
      printSetBits(&aliveMsg->alive);

      dbg(DBG_USR3, "^^ SHIPPING!!!\n");

      
      if (call SendReport.send(tgtAddr,
			       pktSize,
			       &rollCallMsg) == FAIL) {
	dbg(DBG_USR3, "^^ send FAILED to SHIP!\n");

      } else {
	call Leds.greenToggle();

	dbg(DBG_USR3, "^^ send SHIPPED successfully!\n");	
      }

      if (tgtAddr == TOS_BCAST_ADDR) {
	call AggSendCtl.setBcastRetries(saveBcastRetries);
      }
      
    }
    
    return SUCCESS;
  }

  event result_t SendReport.sendDone(TOS_MsgPtr msg,
				     result_t status) {

    dbg(DBG_USR3, "^^ sendDone\n");    

    if (status == SUCCESS) { 

      //      call Leds.greenToggle();
 
    } else {

      //      call Leds.redToggle();

    }

    finishRound();

    return SUCCESS;
  }

  void finishRound() {
    Set *aliveBitmap;

    sendReport();

    // Increment the round number to prevent contamination
    // (Will be reset next round)
    roundOver = TRUE;

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


  void sendReport() {
    // Form and send a report
    
    // bytesSent, numFailedNodes and numFillUpd are already set
    
    statsPkt->numRounds = rollCallRound;

    statsPkt->parentAddr = call RouteControl.getParent();
    statsPkt->treeLevel = call RouteControl.getDepth();

    dbg(DBG_USR1, 
	"REPORT #failed: %u bytes: %u rounds: %u parent: %u fullUpd: %u\n",
	statsPkt->numFailedNodes,
	statsPkt->bytesSent,
	statsPkt->numRounds,
	statsPkt->parentAddr,
	statsPkt->numFullUpd);

    call SendStats.send(TOS_UART_ADDR,
			sizeof(ResultPkt),
			&statsMsg);

  }

  event result_t SendStats.sendDone(TOS_MsgPtr msg,
				    result_t status) {

    // Zero the stats
    if (status == SUCCESS)
      memset(statsPkt, 0, sizeof(ResultPkt));

    return SUCCESS;
  }

  event void AggSendCtl.transmitted(TOS_MsgPtr msg) {
    if (msg->type == ROLLCALL_AM) {
      statsPkt->numFullUpd += 1;
      statsPkt->bytesSent += msg->length;
    }
  }

  event void TimeSetListener.timeAdjusted(int64_t msTicks) {
    updateRollCallRound();
  }

}
