//$Id: MgmtQueryM.nc,v 1.21 2005/08/19 18:31:19 gtolle Exp $

includes Drain;
includes Events;
#include <nucleusSignal.h>

module MgmtQueryM {
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as SubControl;

    interface Leds;

    interface Timer;

    interface Random;

    interface AttrClient[AttrID id];

    interface ReceiveMsg as QueryReceiveLocal;
    interface SendMsg as ResponseSend;

    interface Send as ResponseSendMH;
    interface SendMsg as ResponseSendMsgMH;
    interface Receive as QueryReceive;
    interface Drip as QueryDrip;

    interface Receive as QueryReceiveDrain;

    interface Dest;
  }
}
implementation {

#define BIT_GET(x, i) ((x) & (1 << (i)))
#define BIT_SET(x, i) ((x) | (1 << (i)))
#define BIT_CLEAR(x, i) ((x) & ~(1 << (i)))

  DestMsg       queryDest[MGMTQUERY_MAX_QUERIES];
  MgmtQueryDesc query[MGMTQUERY_MAX_QUERIES];

  bool timerRunning;

  TOS_Msg responseBuf;
  bool    responseBufBusy;
  bool querySending;

  MgmtQueryDesc *waitingQuery;
  MgmtQueryMsg  *dripQuery;

  uint8_t currentQuery;

  uint16_t responseAttempts;
  uint16_t responseBusyDrops;
  uint16_t responseDrops;

  void saveDripIncoming(void* pData, uint8_t arrayID);
  void saveLocalIncoming(void *pData, uint8_t arrayID);
  void saveIncoming(MgmtQueryMsg* queryMsg, uint8_t arrayID);

  void initTimedQuery(MgmtQueryDesc *qDesc);
  void startTimer();
  result_t processQuery(DestMsg* curDest, MgmtQueryDesc *curQuery);
  result_t processSendDone(TOS_MsgPtr pMsg);

  result_t sendQuery(MgmtQueryDesc *curQuery, 
		     TOS_MsgPtr pMsgBuf,
		     uint8_t len);

  result_t sendResponse(TOS_MsgPtr pMsgBuf, uint16_t destAddr, uint8_t len);

  command result_t StdControl.init() {
    call SubControl.init();
    timerRunning = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    call QueryDrip.init();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event TOS_MsgPtr QueryReceive.receive(TOS_MsgPtr pMsg, void* pData, 
					uint16_t payloadLen) {
    saveDripIncoming(pData, 0);
    return pMsg;
  }

  event TOS_MsgPtr QueryReceiveDrain.receive(TOS_MsgPtr pMsg, 
					     void* pData, 
					     uint16_t payloadLen) {
    saveLocalIncoming(pData, 0);
    return pMsg;
  }

  event TOS_MsgPtr QueryReceiveLocal.receive(TOS_MsgPtr pMsg) {

    saveLocalIncoming(pMsg->data, 0);
    return pMsg;
  }

  void saveDripIncoming(void* pData, uint8_t arrayID) {

    DestMsg* destMsg = (DestMsg*) pData;
    memcpy(&queryDest[arrayID], destMsg, sizeof(DestMsg));    

    saveIncoming((MgmtQueryMsg*) destMsg->data, arrayID);
  }

  void saveLocalIncoming(void *pData, uint8_t arrayID) {

    queryDest[arrayID].addr = TOS_LOCAL_ADDRESS;
    queryDest[arrayID].ttl = 1;

    saveIncoming((MgmtQueryMsg*) pData, arrayID);
  }
  
  void saveIncoming(MgmtQueryMsg *queryMsg, uint8_t arrayID) {

    memcpy(&query[arrayID], queryMsg, sizeof(MgmtQueryMsg));

    memcpy(&(query[arrayID].attrList), queryMsg->attrList, 
	   (queryMsg->numAttrs <= MGMTQUERY_MAX_QUERY_ATTRS ? 
	    queryMsg->numAttrs : MGMTQUERY_MAX_QUERY_ATTRS ) * MGMTQUERY_ATTR_SIZE);

    if (query[arrayID].queryMessage.active) {
      query[arrayID].queryPending = TRUE;
      query[arrayID].seqno = 0;      
      query[arrayID].countdown = call Random.rand() % (MGMTQUERY_MIN_DELAY * query[arrayID].queryMessage.delay);
    } else {
      query[arrayID].countdown = 0;
    }
    
    if (!timerRunning) {
      startTimer();
    }
  }

  void startTimer() {
    uint8_t i;
    uint16_t minCountdown = 0xFFFF;
    DestMsg *curDest;
    MgmtQueryDesc *curQuery;
    
    for (i = 0; i < MGMTQUERY_MAX_QUERIES; i++) {
      curDest = &queryDest[i];
      curQuery = &query[i];
      if (curQuery->queryMessage.active && 
	  curQuery->queryPending &&
	  call Dest.isEndpoint(curDest) &&
	  curQuery->countdown < minCountdown)
	minCountdown = curQuery->countdown;
    }

    if (minCountdown < 0xFFFF) {

      timerRunning = TRUE;
      for (i = 0; i < MGMTQUERY_MAX_QUERIES; i++) {
	curQuery = &query[i];
	if (curQuery->queryMessage.active && 
	    curQuery->queryPending &&
	    call Dest.isEndpoint(curDest)) {
	  curQuery->countdown -= minCountdown;
	}
      }
      
      if (minCountdown == 0)
	minCountdown = 5; // don't want to start a 0 length timer
      
      call Timer.start(TIMER_ONE_SHOT, minCountdown);

    } else {

      timerRunning = FALSE;
    }
  }

  event result_t QueryDrip.rebroadcastRequest(TOS_MsgPtr msg,
					      void *pData) {
    uint8_t arrayID = 0;
    uint8_t attrLen;

    DestMsg* destMsg = (DestMsg*) pData;
    MgmtQueryMsg *queryMsg = (MgmtQueryMsg*) destMsg->data;

    memcpy(destMsg, &queryDest[arrayID], sizeof(DestMsg));
    memcpy(queryMsg, &query[arrayID], sizeof(MgmtQueryMsg));
    
    attrLen = (query[arrayID].queryMessage.numAttrs <= 
	       MGMTQUERY_MAX_QUERY_ATTRS ? 
	       query[arrayID].queryMessage.numAttrs : 
	       MGMTQUERY_MAX_QUERY_ATTRS ) * MGMTQUERY_ATTR_SIZE;
    
    memcpy(queryMsg->attrList, &(query[arrayID].attrList), attrLen);

    call QueryDrip.rebroadcast(msg, pData, 
			       sizeof(DestMsg) + 
			       sizeof(MgmtQueryMsg) + 
			       attrLen);
    return SUCCESS;
  }

  event result_t Timer.fired() {

    DestMsg *curDest;
    MgmtQueryDesc *curQuery;
    uint8_t i;

    for (i = 0; i < MGMTQUERY_MAX_QUERIES; i++) {
      curDest = &queryDest[i];
      curQuery = &query[i];
      if (curQuery->queryMessage.active && 
	  curQuery->queryPending &&
	  call Dest.isEndpoint(curDest) && 
	  curQuery->countdown == 0) {
	if (processQuery(curDest, curQuery) == SUCCESS)
	  break;
      }
    }

    startTimer();

    return SUCCESS;
  }

  result_t processQuery(DestMsg* curDest, MgmtQueryDesc *curQuery) {
    
    uint16_t bufLen = 0;
    uint8_t i, bytes;

    TOS_MsgPtr pMsgBuf = &responseBuf;

    MgmtQueryResponseMsg *response;

    if (responseBufBusy) {
      return FAIL;
    }
    
    response = (MgmtQueryResponseMsg*) 
      call ResponseSendMH.getBuffer(pMsgBuf, &bufLen);

    if (response == NULL)
      return FAIL;

    responseBufBusy = TRUE;

    response->queryID = curQuery->queryMessage.queryID;
    response->seqno = curQuery->seqno;
    response->attrsPresent = 0;

    waitingQuery = curQuery;

    for (i = 0; i < curQuery->queryMessage.numAttrs; i++) {
      curQuery->attrLocks = BIT_SET(curQuery->attrLocks, i);
    }
    
    for (i = 0, bytes = 0; i < curQuery->queryMessage.numAttrs; i++) {

      MgmtQueryAttr attr;
      memcpy(&attr, ((uint8_t*)(&curQuery->attrList[0])) + 
	     (i * MGMTQUERY_ATTR_SIZE), MGMTQUERY_ATTR_SIZE);
      
      if (BIT_GET(curQuery->queryMessage.ramAttrs, i)) {
	
	void *addr = (void*) (attr.id);
	uint8_t len = attr.pos;
	
	if ((bytes + len) <= bufLen - MGMTQUERY_RESPONSE_HEADER_SIZE) {
	  memcpy(&response->data[bytes], addr, len);
	  response->attrsPresent = BIT_SET(response->attrsPresent, i);
	  bytes += len;
	}
	
	curQuery->attrLocks = BIT_CLEAR(curQuery->attrLocks, i);

      } else {

	if ((bytes + call AttrClient.getAttrLength[attr.id]() > 
	     bufLen - MGMTQUERY_RESPONSE_HEADER_SIZE) ||
	    
	    (call AttrClient.getAttr[attr.id](&response->data[bytes], 
					      attr.pos) == FAIL)) {

	  curQuery->attrLocks = BIT_CLEAR(curQuery->attrLocks, i);

	} else {
	  bytes += call AttrClient.getAttrLength[attr.id]();
	}
      }
    }
    
    if (waitingQuery->attrLocks == 0) {
      // We might have already sent it after the last attribute's 
      // getDone. If so, this call will fail.
      sendQuery(waitingQuery, pMsgBuf, bytes);
    }

    return SUCCESS; 
  }

  event result_t AttrClient.getAttrDone[AttrID id](void *attrBuf) {

    /*
      This is where I should figure out which query is currently
      active, unset the lock bit for the attribute, see if they are
      all cleared, and then send it.

      Fill the buffer quickly, please. Other queries may be waiting.
    */

    uint16_t bufLen;
    uint8_t i, bytes;
    TOS_MsgPtr pMsgBuf = &responseBuf;

    MgmtQueryResponseMsg *response;
    
    if (waitingQuery == NULL || !responseBufBusy)
      return FAIL;

    response = (MgmtQueryResponseMsg*) 
      call ResponseSendMH.getBuffer(pMsgBuf, &bufLen);

    if (response == NULL)
      return FAIL;
    
    for (i = 0, bytes = 0; i < waitingQuery->queryMessage.numAttrs; i++) {

      MgmtQueryAttr attr;
      memcpy(&attr, ((uint8_t*)(&waitingQuery->attrList[0])) + 
	     (i * MGMTQUERY_ATTR_SIZE), MGMTQUERY_ATTR_SIZE);

      if (BIT_GET(waitingQuery->queryMessage.ramAttrs, i)) {
	
	uint8_t len = attr.pos;
	
	if ((bytes + len) > bufLen - MGMTQUERY_RESPONSE_HEADER_SIZE) {
	  break;
	}

	bytes += len;

      } else {

	if (bytes + call AttrClient.getAttrLength[attr.id]() > 
	    bufLen - MGMTQUERY_RESPONSE_HEADER_SIZE) {
	  break;
	}
	
	if (&response->data[bytes] == attrBuf && 
	    BIT_GET(waitingQuery->attrLocks, i)) {

	  waitingQuery->attrLocks = BIT_CLEAR(waitingQuery->attrLocks, i);
	  response->attrsPresent = BIT_SET(response->attrsPresent, i);
	}

	if (BIT_GET(waitingQuery->attrLocks, i) || 
	    BIT_GET(response->attrsPresent, i)) {
	  bytes += call AttrClient.getAttrLength[attr.id]();
	}
      }
    }
    
    if (waitingQuery->attrLocks == 0) {
      sendQuery(waitingQuery, pMsgBuf, bytes);
    }
    return SUCCESS;
  }
  
  result_t sendQuery(MgmtQueryDesc *curQuery, TOS_MsgPtr pMsgBuf,
		     uint8_t len) {

    result_t result;

    if (querySending) {
      responseBusyDrops++;
      return FAIL;
    }

    responseAttempts++;

    querySending = TRUE;

    result = sendResponse(pMsgBuf, curQuery->queryMessage.destination, len);

    if (result == SUCCESS) {

      call Leds.redOn();
    
      curQuery->seqno++;
      
      if (curQuery->queryMessage.repeat) {
	curQuery->countdown = curQuery->queryMessage.delay; 
      } else {
	curQuery->queryPending = FALSE;
      }
      
    } else {
      responseDrops++;
      querySending = FALSE;
      responseBufBusy = FALSE;
      return FAIL;
    }
    
    return SUCCESS;
  }

  result_t sendResponse(TOS_MsgPtr pMsgBuf, uint16_t destAddr, uint8_t len) {
    result_t result = FAIL;
    
    result = call ResponseSendMsgMH.send(destAddr,
					 MGMTQUERY_RESPONSE_HEADER_SIZE + len,
					 pMsgBuf);    
    return result;
  }

  event result_t ResponseSend.sendDone(TOS_MsgPtr pMsg, result_t success) {

    return processSendDone(pMsg);
  }

  event result_t ResponseSendMsgMH.sendDone(TOS_MsgPtr pMsg, result_t success) {
    return processSendDone(pMsg);
  }

  event result_t ResponseSendMH.sendDone(TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

  result_t processSendDone(TOS_MsgPtr pMsg) {

//    if (pMsg == &responseBuf && responseBufBusy == TRUE) {
    if (responseBufBusy == TRUE) {
      querySending = FALSE;
      responseBufBusy = FALSE;
      call Leds.redOff();
    }

    return SUCCESS;
  }
  
  event result_t AttrClient.attrChanged[AttrID key](void *attrBuf) {
    return SUCCESS;
  }
}
