/* 
 * AODV_core.c - Core AODV module
 * Author:	
 * 		Intel Corporation
 * Date:	$Date: 2004/12/31 20:08:27 $
 *
 * Copyright (c) 2003 Intel Corporation
 */


#define AODV_RTABLE_SIZE   7
#define AODV_RQCACHE_SIZE  7
#define AODV_RPCACHE_SIZE  7

#define AODVR_NUM_TRIES  4

#define AODV_MAX_RAND    4

// this will bethe max number of hops
#define AODV_MAX_METRIC  10  

#if PLATFORM_PC
#define AODV_CORE_DEBUG  1
#endif

#define RREQ_RANDOMIZE 1

module AODV_Core {
    provides {
	interface StdControl as Control;
	interface RouteLookup;
	interface ReactiveRouter;
	interface RouteError;
    }
    uses {
	interface Random;
	// Route Request interfaces
	interface SendMsg as SendRreq;
	interface Payload as RreqPayload;
	interface ReceiveMsg as ReceiveRreq;
	// Route Reply interfaces
	interface SendMsg as SendRreply;
	interface Payload as RreplyPayload;
	interface ReceiveMsg as ReceiveRreply;
	// Route repair interfaces
	interface SendMsg as SendRerr;
	interface Payload as RerrPayload;
	interface ReceiveMsg as ReceiveRerr;
    
	interface Timer;
	interface SingleHopMsg; // to decode single hop headers
	//interface StdControl as MetricControl;
	interface StdControl as ForwardingControl;
	interface StdControl as RadioControl;
	interface Leds;
    }
}

implementation {
    
    // Local allocated message buffers
    TOS_Msg msgBuf1, msgBuf2, msgBuf3;
    TOS_MsgPtr rreqMsg;
    TOS_MsgPtr rReplyMsg;
    TOS_MsgPtr rErrMsg;
    //    bool taskPending;
    uint8_t rreqTaskPending;
    uint8_t rreplyTaskPending;
    uint8_t rerrTaskPending;
#if RREQ_RANDOMIZE
    uint16_t rreqRandomize;
#endif
    bool sendPending;
    int rreqNumTries;
    int rreplyNumTries;
    int rerrNumTries;

    wsnAddr rreqDest;
    wsnAddr rReplyDest;
    wsnAddr rReplySrc;
    wsnAddr rErrDest;
    wsnAddr rErrSrc;
    uint16_t seq;
    uint16_t rreqID;
    AODV_Rreq_Msg fwdRreq;
    AODV_Rreply_Msg fwdRreply;
    

    //Route table entry. Note: move route table processing into a separate component in next release
    AODV_Route_Table routeTable[AODV_RTABLE_SIZE];
    //Reverse route cache. Note: move cache processing into a separate component in next release
    AODV_Route_Cache rreqCache[AODV_RQCACHE_SIZE];
    // Forward route cache. 
    //  AODV_Route_Table rReplyCache[AODV_RPCACHE_SIZE];
    //
    //  Purpose: Initilaize the AODV module
    //  Returns: Always 1 on success
    
    command result_t Control.init() {
	int i;
	dbg(DBG_BOOT, "AODV_Core initializing\n");

      
	rreqMsg = &msgBuf1;
	rReplyMsg = &msgBuf2;
	rErrMsg = &msgBuf3;
#if RREQ_RANDOMIZE
	rreqRandomize = 0;
#endif
	rreqTaskPending = TASK_DONE;
	rreplyTaskPending = TASK_DONE;
	rerrTaskPending = TASK_DONE;
	sendPending = FALSE;

	rreqNumTries = 0;
	rreplyNumTries = 0;
	rerrNumTries = 0;

	rreqDest  =  INVALID_NODE_ID;

	rReplyDest  =  INVALID_NODE_ID;
	rReplySrc  = INVALID_NODE_ID;

	rErrDest = INVALID_NODE_ID;
	rErrSrc  = INVALID_NODE_ID;

	seq = 0;
	rreqID = 0;

	for(i = 0; i< AODV_RTABLE_SIZE; i++){
	    routeTable[i].dest    = INVALID_NODE_ID;
	    routeTable[i].nextHop = INVALID_NODE_ID;
	    routeTable[i].destSeq = 0;
	    routeTable[i].numHops = 0;
	}


	for(i = 0; i< AODV_RQCACHE_SIZE; i++){
	    rreqCache[i].dest    = INVALID_NODE_ID;
	    rreqCache[i].nextHop = INVALID_NODE_ID;
	    rreqCache[i].destSeq = 0;
	    rreqCache[i].numHops = 0;
	}


	call RadioControl.init();
	call ForwardingControl.init();
	call Random.init();
	return SUCCESS;
    }
    

    //
    // Purpose: Start the AODV module
    // Returns: Always 1
    command result_t Control.start() {
	call RadioControl.start();
	call ForwardingControl.start();
	
	return call Timer.start(TIMER_REPEAT, (CLOCK_SCALE/4));
	
    }
    
    command result_t Control.stop() {
      
	call ForwardingControl.stop();
	call RadioControl.stop();
	return call Timer.stop();
    }


    uint8_t getCacheIndex(wsnAddr src, wsnAddr dest){
	int i;
	for(i=0; i< AODV_RQCACHE_SIZE; i++){
	    if(rreqCache[i].src == src && rreqCache[i].dest == dest){
		return i;
	    }
	    return INVALID_INDEX;
	}
    }

    result_t removeRTable(int indx){
      int i;

      for(i = indx; i< AODV_RTABLE_SIZE-1; i++) {
	if(routeTable[i+1].dest == INVALID_NODE_ID){
	  break;
	}
	routeTable[i] = routeTable[i+1];
      }

      routeTable[i].dest    = INVALID_NODE_ID;
      routeTable[i].nextHop = INVALID_NODE_ID;
      routeTable[i].destSeq = 0;
      routeTable[i].numHops = 0;
      return SUCCESS;
    }

    uint8_t getRTableIndex(wsnAddr dest){
      int i;
      for(i=0; i< AODV_RTABLE_SIZE; i++){
	if(routeTable[i].dest == dest){
	  return i;
	}
      }
      return INVALID_INDEX;
      
    }
    
#if AODV_CORE_DEBUG
    void printRTableEntry(int i){
       dbg(DBG_USR3, 
	   "AODV_Core: indx=%d: dest=%d nextHop=%d destSeq=%d numHops=%d \n", 
	   i, routeTable[i].dest, routeTable[i].nextHop, 
	   routeTable[i].destSeq, routeTable[i].numHops );
    }
    void printRTable(){
      int i;
      dbg(DBG_USR3, "Printing RTable entries \n");
      for(i = 0; i<AODV_RTABLE_SIZE; i++){
	if(routeTable[i].dest !=INVALID_NODE_ID){
	  printRTableEntry(i);
	}
      }
      dbg(DBG_USR3, "Printing RTable entries DONE \n");
    }

#endif
    result_t addRtableEntry(AODV_Rreply_MsgPtr msg){
	int i;
	if(msg->dest == TOS_LOCAL_ADDRESS){
	    return SUCCESS; 
	}
	for(i = 0; i<AODV_RTABLE_SIZE; i++){
	    if(routeTable[i].dest == INVALID_NODE_ID){
		break;
	    }
	    if(routeTable[i].dest == msg->dest){
		break;
	    }
	}
	if(i < AODV_RTABLE_SIZE){
	    if(routeTable[i].dest == INVALID_NODE_ID 
	       || routeTable[i].destSeq < msg->destSeq 
	       || (routeTable[i].destSeq == msg->destSeq 
		   && routeTable[i].numHops < msg->metric[0])) {
		routeTable[i].dest = msg->dest;
		routeTable[i].destSeq = msg->destSeq;
		routeTable[i].nextHop = rReplySrc;
		routeTable[i].numHops = msg->metric[0];
		return SUCCESS;     
	    }
	    if(routeTable[i].destSeq == msg->destSeq 
	       && routeTable[i].numHops == msg->metric[0]){
		// entry already exists
		return SUCCESS;
	    }
	}
	dbg(DBG_TEMP, ("ADDRTABLE failed\n"));	
	return FAIL;

    }

    task void sendRerr(){
      AODV_Rerr_MsgPtr msg;
      int i;
      dbg(DBG_ROUTE, ("AODV_Core task sendRerr\n"));	
      call RerrPayload.linkPayload(rErrMsg, (uint8_t **) &msg);
#if AODV_CORE_DEBUG      
      printRTable();
#endif
      msg->dest      = rErrDest;
      i = getRTableIndex(msg->dest);
      if(i == INVALID_NODE_ID){
	rerrTaskPending = TASK_DONE;
	return;
      }
      msg->destSeq   = routeTable[i].destSeq;  
      removeRTable(i); 

      if (!sendPending && call SendRerr.send(TOS_BCAST_ADDR, 
			     AODV_RERR_HEADER_LEN, 
			     rErrMsg)) {
	sendPending = TRUE;
	rerrTaskPending = TASK_DONE;
	
      }
	else{
	  rerrNumTries = AODVR_NUM_TRIES;
	  rerrTaskPending = TASK_REPOSTREQ;
	  return;
	}
#if AODV_CORE_DEBUG      
      dbg(DBG_ROUTE, "AODV_Core task sendRerr taskPending = %d \n",rerrTaskPending);	
      printRTable();
#endif
      

    }


    task void fwdRerr() {
      AODV_Rerr_MsgPtr msg;
      int i;
      dbg(DBG_ROUTE, ("AODV_Core task fwdRerr\n"));	
     
#if AODV_CORE_DEBUG      
      printRTable();
#endif
      call RerrPayload.linkPayload(rErrMsg, (uint8_t **) &msg);
      i = getRTableIndex(rErrDest);

      if(i != INVALID_INDEX && 
	 routeTable[i].nextHop == rErrSrc){
	msg->dest = rErrDest;
	msg->destSeq = routeTable[i].destSeq;
	removeRTable(i);

	if (!sendPending && call SendRerr.send(TOS_BCAST_ADDR, 
			       AODV_RERR_HEADER_LEN, 
			       rErrMsg)) {
	  sendPending = TRUE;
	  rerrTaskPending = TASK_DONE;
	}
	else{
	  rerrNumTries = AODVR_NUM_TRIES;
	  rerrTaskPending = TASK_REPOSTREQ;
	  return;
	}
      }
      else{
	rerrTaskPending = TASK_DONE;
      }
#if AODV_CORE_DEBUG      
      dbg(DBG_ROUTE, "AODV_Core task fwdRerr taskPending = %d \n",rerrTaskPending);	
      printRTable();
#endif
    }

    task void resendRerr(){
      if(rerrNumTries <= 0){
	rerrTaskPending = TASK_DONE;
	return;
      }
      if (!sendPending && call SendRerr.send(TOS_BCAST_ADDR, 
			     AODV_RERR_HEADER_LEN, 
			     rErrMsg)) {
	sendPending = TRUE;
	rerrTaskPending = TASK_DONE;
	}
      else{
	rerrNumTries--;
	rerrTaskPending = TASK_REPOSTREQ;
      }
    }

    
    task void sendRreq() {
	AODV_Rreq_MsgPtr msg;
      
	call RreqPayload.linkPayload(rreqMsg, (uint8_t **) &msg);
	seq++;
	rreqID++;
      
	msg->dest      = rreqDest;
	msg->src       = TOS_LOCAL_ADDRESS;
	msg->rreqID    = rreqID;
	msg->srcSeq    = seq;
	msg->destSeq   = 0;   // this function only sends rreq's if no route exists
	msg->metric[0] = 0;

	if (!sendPending && call SendRreq.send(TOS_BCAST_ADDR, 
			       AODV_RREQ_HEADER_LEN, 
			       rreqMsg)) {
	    sendPending = TRUE;
	    rreqTaskPending = TASK_DONE;
	}
	else{
	  rreqNumTries = AODVR_NUM_TRIES;
	  rreqTaskPending = TASK_REPOSTREQ;
	}
      
    }

    task void forwardRreq() {
	AODV_Rreq_MsgPtr msg;
      
	call RreqPayload.linkPayload(rreqMsg, (uint8_t **) &msg);
      
	*msg = fwdRreq;
	msg->metric[0]++;  // simple hop metric for now
#if RREQ_RANDOMIZE      
	if(rreqRandomize = ((call Random.rand() & 0xff) % AODV_MAX_RAND)){
	    rreqNumTries = AODVR_NUM_TRIES;
	    rreqTaskPending = TASK_REPOSTREQ;
	    return;
	}
#endif
	if (!sendPending && call SendRreq.send(TOS_BCAST_ADDR, 
			       AODV_RREQ_HEADER_LEN, 
			       rreqMsg)) {
	    sendPending = TRUE;
	    rreqTaskPending = TASK_DONE;
	}  
	else{
	  rreqNumTries = AODVR_NUM_TRIES;
	  rreqTaskPending = TASK_REPOSTREQ;
	}
      
    }


    task void resendRreq(){
      if(rreqNumTries <= 0){
	rreqTaskPending = TASK_DONE;
	return;
      }
#if RREQ_RANDOMIZE
      if(rreqRandomize >0){
	  dbg(DBG_USR3, "Calling resendRreq Randomizetries = %d\n", rreqRandomize); 
	  rreqTaskPending = TASK_REPOSTREQ;
	  rreqRandomize--;
	  return;
      }
#endif
      dbg(DBG_ROUTE, "Calling resendRreq tries = %d\n", rreqNumTries);	      
      if (!sendPending && call SendRreq.send(TOS_BCAST_ADDR, 
					     AODV_RREQ_HEADER_LEN, 
					     rreqMsg)) {
	sendPending = TRUE;
	rreqTaskPending = TASK_DONE;
      }
      else{
	rreqNumTries--;
	rreqTaskPending = TASK_REPOSTREQ;
      }
    }



    task void forwardRreply(){
	AODV_Rreply_MsgPtr msg;
      
	call RreqPayload.linkPayload(rReplyMsg, (uint8_t **) &msg);
	dbg(DBG_ROUTE, ("Calling fwdRreply \n"));	
	*msg = fwdRreply;
#if AODV_CORE_DEBUG
	printRTable();
#endif      	
	if(!addRtableEntry(msg)){
	  rreplyTaskPending = TASK_DONE;
	  return;
	}
	if (!sendPending && 
	    call SendRreply.send(rReplyDest, 
			       AODV_RREPLY_HEADER_LEN, 
			       rReplyMsg)) {
	    dbg(DBG_ROUTE, ("Calling SendRreply successful\n"));	
	    sendPending = TRUE;
	    rreplyTaskPending = TASK_DONE;
		    
	}
	else{
	  rreplyTaskPending = TASK_REPOSTREQ;
	  rreplyNumTries = AODVR_NUM_TRIES;
	}
#if AODV_CORE_DEBUG
	printRTable();
#endif      
      
    }

    task void resendRreply(){
      if(rreplyNumTries <= 0){
	rreplyTaskPending = TASK_DONE;
	return;
      }
      if (!sendPending && call SendRreply.send(TOS_BCAST_ADDR, 
					     AODV_RREPLY_HEADER_LEN, 
					     rReplyMsg)) {
	sendPending = TRUE;
	rreplyTaskPending = TASK_DONE;
      }
      else{
	rreplyNumTries--;
	rreplyTaskPending = TASK_REPOSTREQ;
      }
    }


    // success means that the possible new entry is usable
    result_t checkCache(AODV_Rreq_Msg* msg){
  
	int i;
#if  AODV_CORE_DEBUG  
	dbg(DBG_ROUTE, ("AODV_Core: Printing RREQ Cache\n"));
	for(i=0; i< AODV_RQCACHE_SIZE; i++){
	  if(rreqCache[i].dest == INVALID_NODE_ID){
	    break;
	  }
	  dbg(DBG_ROUTE, "AODV_Core:RREQ Cache i = %d, src = %d, rreqID = %d, numhops = %d \n", i, rreqCache[i].src, rreqCache[i].rreqID, rreqCache[i].numHops);
	}
	dbg(DBG_ROUTE, ("AODV_Core: Printing RREQ Cache DONE\n"));
#endif

	for(i=0; i< AODV_RQCACHE_SIZE; i++){
	    if(rreqCache[i].dest == INVALID_NODE_ID){
		return SUCCESS;
	    }

	    if(rreqCache[i].src == msg->src){ 
	      if(rreqCache[i].rreqID < msg->rreqID || 
		 (rreqCache[i].rreqID == msg->rreqID && 
		  rreqCache[i].numHops > msg->metric[0])){
		// this is a newer rreq
		return SUCCESS;
	      }
	      else{
		return FAIL;
	      }
	    }
	}

	return SUCCESS;
    }
    
    result_t updateCache(AODV_Rreq_Msg* msg, wsnAddr nextHop){
	int i;
	int endIndex = -1;
	int replaceIndex=-1;
	for(i=0; i< AODV_RQCACHE_SIZE; i++){
	    if(rreqCache[i].dest == INVALID_NODE_ID){
		endIndex = i;
		break;
	    }

	    if(rreqCache[i].src == msg->src){
		replaceIndex = i;
		break;
	    }
	}
       
	if(replaceIndex != -1){
	  for(i=replaceIndex; i< AODV_RQCACHE_SIZE-1; i++){
		if(rreqCache[i+1].dest != INVALID_NODE_ID){
		  rreqCache[i] = rreqCache[i+1];
		}
		else{
		  break;
		}
	  }
	}
	else{
	  if(endIndex == -1){
	    // no empty entries make room
	    for(i=0; i< AODV_RQCACHE_SIZE-1; i++){
	      rreqCache[i] = rreqCache[i+1];
	  }
	    
	  }
	}
	  
	// i should be at the right place now
	rreqCache[i].dest = msg->dest;
	rreqCache[i].src = msg->src;
	rreqCache[i].nextHop = nextHop;
	rreqCache[i].rreqID = msg->rreqID;
	rreqCache[i].destSeq = msg->destSeq;
	rreqCache[i].numHops = msg->metric[0]; // +1 ??
	
#if  AODV_CORE_DEBUG  
	dbg(DBG_ROUTE, ("AODV_Core: Update Printing RREQ Cache\n"));
	for(i=0; i< AODV_RQCACHE_SIZE; i++){
	  if(rreqCache[i].dest == INVALID_NODE_ID){
	    break;
	  }
	  dbg(DBG_ROUTE, "AODV_Core:RREQ Cache i = %d, src = %d, rreqID = %d, numHops = %d \n", i, rreqCache[i].src, rreqCache[i].rreqID, rreqCache[i].numHops);
	}
	dbg(DBG_ROUTE, ("AODV_Core: Update Printing RREQ Cache DONE\n"));
#endif
	
	return SUCCESS;  // always success for now
    }

    wsnAddr getReverseRoute(AODV_Rreply_MsgPtr msg){
	int i;
	for(i=0; i< AODV_RQCACHE_SIZE; i++){
	    if(rreqCache[i].dest == INVALID_NODE_ID){
		return INVALID_NODE_ID;
	    }
	    if(rreqCache[i].src == msg->src){
		return rreqCache[i].nextHop;
	    }
	}
	return INVALID_NODE_ID;
    }


    event result_t SendRreq.sendDone(TOS_MsgPtr sentBuffer, 
				     bool success) {

	if ((sendPending == TRUE) && (sentBuffer == rreqMsg)) {
	    sendPending = FALSE;
	    return SUCCESS;
	}
	else{
	    return FAIL;
	}
    }
    
    event result_t SendRreply.sendDone(TOS_MsgPtr sentBuffer, 
				       bool success) {
      dbg(DBG_USR3, "Sendrreply done and send->ack is %d \n",sentBuffer->ack);

	if ((sendPending == TRUE) && (sentBuffer == rReplyMsg)) {
	    sendPending = FALSE;
	    return SUCCESS;
	}
	else{
	    return FAIL;
	}

    }
    
    event result_t SendRerr.sendDone(TOS_MsgPtr sentBuffer, 
				     bool success) {
	if ((sendPending == TRUE) && (sentBuffer == rErrMsg)) {
	    sendPending = FALSE;
	    return SUCCESS;
	}
	else{
	    return FAIL;
	}
    }


    //
    // Handle a AODV Rreq message
    //
    event TOS_MsgPtr ReceiveRreq.receive(TOS_MsgPtr receivedMsg) {
	
	AODV_Rreq_MsgPtr msg;
	wsnAddr prevHop;
	
	call RreqPayload.linkPayload(receivedMsg, (uint8_t **) &msg);
	
	dbg(DBG_ROUTE, "AODV_Core ReceiveRreq.receive src:%d dest: %d rreqID %d, metric %d\n"
	    , msg->src, msg->dest, msg->rreqID, msg->metric[0]);
	if(msg->metric[0] > AODV_MAX_METRIC){
	  return receivedMsg;
	}
	if(!checkCache(msg)){
	    // message stale
	  dbg(DBG_ROUTE, ("AODV_Core: checkcache fail\n"));
	    return receivedMsg;
	}
	if(msg->dest == TOS_LOCAL_ADDRESS){ 
	    //simplified AODV -- only destinations send route reply
	    if(msg->destSeq > seq) {
		// not going to happen -- just a sanity check
		dbg(DBG_ROUTE, ("ERROR:AODV_Core msg->destSeq > seq\n"));
		return receivedMsg;
	    }
#if 0
	    indx = getCacheIndex(msg);
	  
	    if(indx != INVALID_INDEX && msg->metric[0] >= rreqCache[indx].numHops){
		// no need t update
		return receivedMsg;
	    }
#endif		
	    dbg(DBG_TEMP, ("ERROR:AODV_Core rreqReceive 1\n"));
	    if(rreplyTaskPending == TASK_DONE){
		dbg(DBG_TEMP, ("ERROR:AODV_Core rreqReceive 2\n"));
		seq++;    
		fwdRreply.dest = msg->dest;
		fwdRreply.src = msg->src;
		fwdRreply.destSeq = msg->destSeq;
		fwdRreply.metric[0] = 0; //destination is 0 hops away
		rReplyDest = call SingleHopMsg.getSrcAddress(receivedMsg);
		rReplySrc = TOS_LOCAL_ADDRESS;
		if(updateCache(msg,rReplyDest)) {
		    rreplyTaskPending = TASK_PENDING;
		    post forwardRreply();      
		}
	    }
	    // send rreply
	}
	else{
	    dbg(DBG_TEMP, ("ERROR:AODV_Core rreqReceive 3\n"));
	    if(rreqTaskPending == TASK_DONE){
		dbg(DBG_TEMP, ("ERROR:AODV_Core rreqReceive 4\n"));
		prevHop = call SingleHopMsg.getSrcAddress(receivedMsg);
		if(msg->src != TOS_LOCAL_ADDRESS && updateCache(msg,prevHop)) {
		    dbg(DBG_TEMP, ("ERROR:AODV_Core rreqReceive 5\n"));
		    rreqTaskPending = TASK_PENDING;
		    fwdRreq = *msg;
		    post forwardRreq(); 
		}
	    }
	}
	dbg(DBG_TEMP, "ERROR:AODV_Core rreqReceive 6 task state = %d \n",
	    rreqTaskPending);
	return receivedMsg;
    }

    event TOS_MsgPtr ReceiveRreply.receive(TOS_MsgPtr receivedMsg) {

	AODV_Rreply_MsgPtr msg;

      
	call RreqPayload.linkPayload(receivedMsg, (uint8_t **) &msg);
      
	dbg(DBG_ROUTE, "AODV_Core Rreply.receive src: %d dest: %d \n", msg->src, msg->dest);
	if(msg->src == TOS_LOCAL_ADDRESS){
	    // notify components that need to be notified
#if AODV_CORE_DEBUG
	  printRTable();
#endif
	  rReplySrc = call SingleHopMsg.getSrcAddress(receivedMsg);
	  addRtableEntry(msg);
#if AODV_CORE_DEBUG
	  printRTable();
#endif
	}
	else{
	    if((rReplyDest = getReverseRoute(msg)) != INVALID_NODE_ID && rreplyTaskPending == TASK_DONE){
		dbg(DBG_ROUTE, "AODV_Core GOING to call fwdRrreply\n");
		rreplyTaskPending = TASK_PENDING;
		fwdRreply = *msg;
		fwdRreply.metric[0]++; 
		rReplySrc = call SingleHopMsg.getSrcAddress(receivedMsg);
		// routing entry added in the forward reply
		post forwardRreply();      
	  
	    }
	}

      
	return receivedMsg;
    }

    event TOS_MsgPtr ReceiveRerr.receive(TOS_MsgPtr receivedMsg) {

      AODV_Rerr_MsgPtr msg;



      call RerrPayload.linkPayload(receivedMsg, (uint8_t **) &msg);
      
      dbg(DBG_ROUTE, ("AODV_Core Rerr.receive\n"));
      rErrDest = msg->dest;
      rErrSrc = call SingleHopMsg.getSrcAddress(receivedMsg);
      if(rerrTaskPending == TASK_DONE){
	rerrTaskPending = TASK_PENDING;
	post fwdRerr();
      }
      
      return receivedMsg;
    }

    event result_t Timer.fired() {
      dbg(DBG_TEMP, ("AODV_Core Timer.fired()\n"));
      if(rreqTaskPending == TASK_REPOSTREQ){
	rreqTaskPending = TASK_PENDING;
	post resendRreq();
      }

      if(rreplyTaskPending == TASK_REPOSTREQ){
	rreplyTaskPending = TASK_PENDING;
	post resendRreply();
      }

      if(rerrTaskPending == TASK_REPOSTREQ){
	rerrTaskPending = TASK_PENDING;
	post resendRerr();
      }


      return SUCCESS;
    }    
    

    command wsnAddr RouteLookup.getNextHop(TOS_MsgPtr m, wsnAddr dest){
	int i;
	for(i =0; i <AODV_RTABLE_SIZE; i++){
	    if(routeTable[i].dest == dest){
		return routeTable[i].nextHop;
	    }
	}
	return INVALID_NODE_ID;
    }


    command wsnAddr RouteLookup.getRoot(){
	return AODV_ROOT_NODE;
    }
    command wsnAddr ReactiveRouter.getNextHop(wsnAddr dest){
	int i;
	for(i =0; i <AODV_RTABLE_SIZE; i++){
	    if(routeTable[i].dest == dest){
		return routeTable[i].nextHop;
	    }
	}
	return INVALID_NODE_ID;
    }	


    command result_t ReactiveRouter.generateRoute(wsnAddr dest){
	dbg(DBG_ROUTE, ("AODV_Core Received a request to generate route\n"));
	if(dest == TOS_LOCAL_ADDRESS){
	  return FAIL;
	}
	if(rreqTaskPending == TASK_DONE){
	    rreqTaskPending = TASK_PENDING;
	    rreqDest = dest;
	    post sendRreq();
	    return SUCCESS;
	}
	else {
	    return FAIL;
	}
    }
    
    command result_t RouteError.SendRouteErr(wsnAddr dest){
      dbg(DBG_ROUTE, ("AODV_Core Received a request to Send Route Error\n"));
      if(rerrTaskPending == TASK_DONE){
	rerrTaskPending = TASK_PENDING;
	rErrDest = dest;
	post sendRerr();
	return SUCCESS;
      }
      return FAIL;
    }
    
    
}
