module MgmtQueryM {
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;

    interface StdControl as SubControl;

    interface MgmtAttrRetrieve;

    interface Receive as Query1Receive;
    interface Drip as Query1Drip;
    interface Receive as Query2Receive;
    interface Drip as Query2Drip;
    interface Receive as Query3Receive;
    interface Drip as Query3Drip;
    interface Receive as Query4Receive;
    interface Drip as Query4Drip;

    interface Send as ResponseSendMH;
    interface Timer;

    interface Random;

    interface SharedMsgBuf;
  }
}
implementation {

#define BIT_GET(x, i) ((x) & (1 << (i)))
#define BIT_SET(x, i) ((x) | (1 << (i)))
#define BIT_CLEAR(x, i) ((x) & ~(1 << (i)))
  
  MgmtQueryDesc query[MAX_QUERIES];
  MgmtQueryDesc *waitingQuery;
  MgmtQueryMsg  *dripQuery;
  TOS_MsgPtr    dripMsg;
  uint8_t       dripQueryID;
  bool          dripRebroadcasting;

  bool msgBufBusy;

  command result_t StdControl.init() {
    call Leds.init();
    call SubControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {

    call SubControl.start();

    call Random.init();
    call Query1Drip.init();
    call Query2Drip.init();
    call Query3Drip.init();
    call Query4Drip.init();
    // HACK!!!
    (void)unique("Drip");
    (void)unique("Drip");
    (void)unique("Drip");
    (void)unique("Drip");

    call Timer.start(TIMER_REPEAT, 1024 / MAX_QUERIES);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  void processQuery(void *pData, uint8_t qid) {

    MgmtQueryMsg *qBuf = (MgmtQueryMsg*) pData;

    query[qid].queryType = qBuf->msgType;
    query[qid].queryActive = FALSE;

    if (qBuf->msgType == QUERY_ACTIVE || 
	qBuf->msgType == QUERY_ONE_SHOT) {
      query[qid].epochLength = qBuf->epochLength;
      query[qid].numAttrs = qBuf->numAttrs;
      memcpy(&query[qid].attrs, qBuf->attrList, 
	     (qBuf->numAttrs <= MAX_QUERY_ATTRS ? 
	      qBuf->numAttrs : MAX_QUERY_ATTRS ) * sizeof(MgmtAttrID));
      query[qid].epochCounter = call Random.rand() % qBuf->epochLength;      
      query[qid].seqno = 0;
      query[qid].ramQuery = qBuf->ramQuery;
    }
  }

  task void rebroadcastTask() {

    dripQuery->msgType = query[dripQueryID].queryType;
    dripQuery->epochLength = query[dripQueryID].epochLength;
    dripQuery->ramQuery = query[dripQueryID].ramQuery;
    dripQuery->numAttrs = query[dripQueryID].numAttrs;
    memcpy(&dripQuery->attrList, &query[dripQueryID].attrs, 
	   (dripQuery->numAttrs <= MAX_QUERY_ATTRS 
	    ? dripQuery->numAttrs : MAX_QUERY_ATTRS ) 	   
	   * sizeof(MgmtAttrID));

    switch(dripQueryID) {
    case 0:
      call Query1Drip.rebroadcast(dripMsg, 
				  (uint8_t *)dripQuery,
				  offsetof(MgmtQueryMsg, attrList) + 
				  (dripQuery->numAttrs <= MAX_QUERY_ATTRS 
				   ? dripQuery->numAttrs : MAX_QUERY_ATTRS ) 
				  * sizeof(MgmtAttrID));
      break;
    case 1:
      call Query2Drip.rebroadcast(dripMsg, 
				  (uint8_t *)dripQuery,
				  offsetof(MgmtQueryMsg, attrList) + 
				  (dripQuery->numAttrs <= MAX_QUERY_ATTRS 
				   ? dripQuery->numAttrs : MAX_QUERY_ATTRS ) 
				  * sizeof(MgmtAttrID));
      break;
    case 2:
      call Query3Drip.rebroadcast(dripMsg, 
				  (uint8_t *)dripQuery,
				  offsetof(MgmtQueryMsg, attrList) + 
				  (dripQuery->numAttrs <= MAX_QUERY_ATTRS 
				   ? dripQuery->numAttrs : MAX_QUERY_ATTRS ) 
				  * sizeof(MgmtAttrID));
      break;
    case 3:
      call Query4Drip.rebroadcast(dripMsg, 
				  (uint8_t *)dripQuery,
				  offsetof(MgmtQueryMsg, attrList) + 
				  (dripQuery->numAttrs <= MAX_QUERY_ATTRS 
				   ? dripQuery->numAttrs : MAX_QUERY_ATTRS ) 
				  * sizeof(MgmtAttrID));
      break;
    }
    dripRebroadcasting = FALSE;
  }

  result_t rebroadcastQuery(TOS_MsgPtr msg, 
			    void *pData, uint8_t qid) {
    if (dripRebroadcasting)
      return FAIL;

    dripMsg = msg;
    dripQuery = (MgmtQueryMsg*) pData;
    dripQueryID = qid;
    if (post rebroadcastTask()) {
      dripRebroadcasting = TRUE;
      return SUCCESS; 
    } else {
      return FAIL;
    }
  }

  event TOS_MsgPtr Query1Receive.receive(TOS_MsgPtr pMsg, void* pData, 
					 uint16_t payloadLen) {
    processQuery(pData, 0);
    query[0].queryActive = TRUE;
    return pMsg;
  }

  event result_t Query1Drip.rebroadcastRequest(TOS_MsgPtr msg,
					       void *pData) {
    return rebroadcastQuery(msg, pData, 0);
  }

  event TOS_MsgPtr Query2Receive.receive(TOS_MsgPtr pMsg, void* pData, 
					 uint16_t payloadLen) {
    processQuery(pData, 1);
    query[1].queryActive = TRUE;
    return pMsg;
  }

  event result_t Query2Drip.rebroadcastRequest(TOS_MsgPtr msg,
					       void *pData) {
    return rebroadcastQuery(msg, pData, 1);
  }

  event TOS_MsgPtr Query3Receive.receive(TOS_MsgPtr pMsg, void* pData, 
					 uint16_t payloadLen) {
    processQuery(pData, 2);
    query[2].queryActive = TRUE;
    return pMsg;
  }

  event result_t Query3Drip.rebroadcastRequest(TOS_MsgPtr msg,
					       void *pData) {
    return rebroadcastQuery(msg, pData, 2);
  }

  event TOS_MsgPtr Query4Receive.receive(TOS_MsgPtr pMsg, void* pData, 
					 uint16_t payloadLen) {
    processQuery(pData, 3);
    query[3].queryActive = TRUE;
    return pMsg;
  }

  event result_t Query4Drip.rebroadcastRequest(TOS_MsgPtr msg,
					       void *pData) {
    return rebroadcastQuery(msg, pData, 3);
  }

  uint8_t currentQuery = 0;

  event result_t Timer.fired() {

    uint8_t qid = currentQuery;

    MgmtQueryDesc *curQuery = &query[qid];

    currentQuery = (currentQuery + 1) % MAX_QUERIES;
    
    if (curQuery->queryActive == FALSE)
      return SUCCESS;
    
    if (curQuery->epochCounter > 0)
      curQuery->epochCounter--;
    
    if ((curQuery->queryType == QUERY_ACTIVE || 
	 curQuery->queryType == QUERY_ONE_SHOT) && 
	curQuery->epochCounter == 0) {

      uint16_t bufLen;
      uint8_t i, bytes;
      TOS_MsgPtr pMsgBuf = call SharedMsgBuf.getMsgBuf();
      MgmtQueryResponseMsg *response = 
	call ResponseSendMH.getBuffer(pMsgBuf, &bufLen);

      if (!call SharedMsgBuf.lock())
	return SUCCESS;
      msgBufBusy = TRUE;

      call Leds.redOn();

      response->qid = qid+1;
      response->seqno = curQuery->seqno;
      
      for (i = 0, bytes = 0; i < curQuery->numAttrs; i++) {
	
	if (!curQuery->ramQuery) {
	  
	  if (bytes + call MgmtAttrRetrieve.getAttrLength(curQuery->attrs[i]) > 
	      bufLen - offsetof(MgmtQueryResponseMsg, data)) {
	    break;
	  }
	  
	  if (call MgmtAttrRetrieve.getAttr(curQuery->attrs[i], 
					    &response->data[bytes]) == FAIL) {
	    // If this returns FAIL, we're going to get a getAttrDone later
	    curQuery->attrLocks = BIT_SET(curQuery->attrLocks, i);
	  };
	  
	  bytes += call MgmtAttrRetrieve.getAttrLength(curQuery->attrs[i]);
	  
	} else {
	  
	  // First 2 bits are length log 2, second 14 are a mem addr
	  
	  uint8_t len = 1 << (curQuery->attrs[i] >> 14 & 0x3);
	  void *addr = (void*) (curQuery->attrs[i] & 0x3FFF);
	  
	  if ((bytes + len) > bufLen - offsetof(MgmtQueryResponseMsg, data)) {
	    break;
	  }
	  
	  memcpy(&response->data[bytes], addr, len);
	  bytes += len;
	}
      }
      
      if (curQuery->attrLocks != 0) {
	waitingQuery = curQuery;
	return SUCCESS;
      }
      
      curQuery->epochCounter = curQuery->epochLength;
      
      if (call ResponseSendMH.send(pMsgBuf, sizeof(MgmtQueryResponseMsg) + bytes)) {
	curQuery->seqno++;
	if (curQuery->queryType == QUERY_ONE_SHOT)
	  curQuery->queryType = QUERY_INACTIVE;
	return SUCCESS;
      } else {
	call SharedMsgBuf.unlock();
	msgBufBusy = FALSE;
      }
    }
    
    return SUCCESS;
  }

  event result_t MgmtAttrRetrieve.getAttrDone(uint16_t id,
					      uint8_t *resultBuf) {
    /*
      This is where I should figure out which query is currently
      active, unset the lock bit for the attribute, see if they are
      all cleared, and then send it.

      Fill the buffer quickly, please. Other queries may be waiting.
    */
    uint16_t bufLen;
    uint8_t i, bytes;
    TOS_MsgPtr pMsgBuf = call SharedMsgBuf.getMsgBuf();
    MgmtQueryResponseMsg *response = 
      call ResponseSendMH.getBuffer(pMsgBuf, &bufLen);
    
    if (waitingQuery == NULL || !msgBufBusy)
      return FAIL;
    
    for (i = 0, bytes = 0; i < waitingQuery->numAttrs; i++) {
      if (bytes + call MgmtAttrRetrieve.getAttrLength(waitingQuery->attrs[i]) > 
	  bufLen - offsetof(MgmtQueryResponseMsg, data)) {
	break;
      }
      
      if (&response->data[bytes] == resultBuf) {
	waitingQuery->attrLocks = BIT_CLEAR(waitingQuery->attrLocks, i);
      }

      bytes += call MgmtAttrRetrieve.getAttrLength(waitingQuery->attrs[i]);
    }

    if (waitingQuery->attrLocks == 0) {
      if (call ResponseSendMH.send(pMsgBuf, sizeof(MgmtQueryResponseMsg) + bytes)) {
	waitingQuery->seqno++;
	if (waitingQuery->queryType == QUERY_ONE_SHOT)
	  waitingQuery->queryType = QUERY_INACTIVE;
	else
	  waitingQuery->epochCounter = waitingQuery->epochLength;
	
	waitingQuery = NULL;
      } else {
	call SharedMsgBuf.unlock();
	msgBufBusy = FALSE;
      }
    }
    
    return SUCCESS;
  }

  event result_t ResponseSendMH.sendDone(TOS_MsgPtr pMsg, result_t success) {
    if (pMsg == call SharedMsgBuf.getMsgBuf() &&
	msgBufBusy == TRUE) {
      call SharedMsgBuf.unlock();
      msgBufBusy = FALSE;
      call Leds.redOff();
    }
    return SUCCESS;
  }

}
