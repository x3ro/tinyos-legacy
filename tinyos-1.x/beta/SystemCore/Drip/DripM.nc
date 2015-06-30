/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Authors:	Gilman Tolle
 *
 */

includes AM;
includes Drip;

#ifdef DBG_DRIP
includes EventLoggerPerl;
#endif

module DripM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Drip[uint8_t id];
  }
  uses {
    interface StdControl as SubControl;
    interface ReceiveMsg;
    interface SendMsg;
    interface Timer as SendTimer;
    interface Random;
    interface Leds;
    interface SharedMsgBuf;
#ifdef DBG_DRIP
    interface EventLogger;
#endif
  }
}

implementation {

/*
  struct TOS_Msg buf;
*/
  bool msgBufBusy = FALSE;
  bool dripStarted = FALSE;

  uint8_t sendEntry;
  uint8_t sendLength;

  enum {
    PRE_SEND = 0,
    POST_SEND = 1,
  };

  typedef struct DripCacheEntry {
    DripMetadata     metadata;
    uint8_t          trickleStage;
    uint16_t         trickleAnnounce;
    uint16_t         trickleCountdown;
    uint8_t          trickleSuppress:1;
    uint8_t          sendToUART:1;
    uint8_t          trickleState:6;
  } DripCacheEntry;

  enum {
    DRIP_CACHE_ENTRIES = uniqueCount("Drip"),
    TIMER_PERIOD = 100,
    MIN_SEND_INTERVAL = 0,
    MAX_SEND_INTERVAL = 10,
  };

  DripCacheEntry dripCache[DRIP_CACHE_ENTRIES];
  DripCacheEntry *signalEntry;

  bool accessingCache = FALSE;

  void printCacheEntry(DripCacheEntry *entry) {
#ifdef PLATFORM_PC
    dbg(DBG_USR1, "@%lld (key=0x%x, seqno=%d), tstage=%d, tcount=%d, tannounce=%d, ts=%d\n", tos_state.tos_time, entry->metadata.id, entry->metadata.seqno, entry->trickleStage, entry->trickleCountdown, entry->trickleAnnounce, entry->trickleState);
#endif
  }

  void printCache() {
    uint8_t i;
    for (i = 0; i < DRIP_CACHE_ENTRIES; i++) {
      printCacheEntry(&dripCache[i]);
    }
  }

  void initDripCache() {
    memset(dripCache, 0, sizeof(DripCacheEntry) * DRIP_CACHE_ENTRIES);
  }

  void trickleSet(DripCacheEntry *dripEntry) {
    dripEntry->trickleCountdown = 1 << dripEntry->trickleStage;

    if (dripEntry->trickleCountdown < 4) {
      dripEntry->trickleAnnounce = 0;
    } else {
      dripEntry->trickleAnnounce = 
	call Random.rand() % (dripEntry->trickleCountdown / 2);
    }

    dripEntry->trickleSuppress = FALSE;    
    dripEntry->trickleState = PRE_SEND;
  }

  void trickleReset(DripCacheEntry *dripEntry) {
    dripEntry->trickleStage = MIN_SEND_INTERVAL;
    trickleSet(dripEntry);
  }

  DripCacheEntry* findFreeEntry() {
    uint8_t i;
    
    for(i = 0; i < DRIP_CACHE_ENTRIES; i++) {
      if (dripCache[i].metadata.id == 0)
	return &dripCache[i];
    }
    return NULL;
  }

  DripCacheEntry *findEntry(uint8_t key) {
    uint8_t i;
    
    for(i = 0; i < DRIP_CACHE_ENTRIES; i++) {
      if (dripCache[i].metadata.id == key)
	return &dripCache[i];
    }
    return NULL;
  }

  command result_t StdControl.init() {
#ifdef PLATFORM_PC
    initDripCache();
#endif
    return call SubControl.init();
  }
  
  command result_t StdControl.start() {
    dripStarted = TRUE;
    call SendTimer.start(TIMER_ONE_SHOT, call Random.rand() % TIMER_PERIOD);
    return call SubControl.start();
  }
  
  command result_t StdControl.stop() {
    dripStarted = FALSE;
    call SendTimer.stop();
    return SUCCESS;
  }

  command result_t Drip.init[uint8_t id]() {

    DripCacheEntry *dripEntry = findEntry(id);
    if (dripEntry != NULL) {
      return SUCCESS;
    }

    dripEntry = findFreeEntry();

//    dbg(DBG_USR1, "Initting %d\n", id);

    if (dripEntry == NULL)
      return FAIL;
    
    dripEntry->metadata.id = id;
    dripEntry->metadata.seqno = 1;

    trickleReset(dripEntry);
    dbg(DBG_USR1, "INIT: ");
    printCacheEntry(dripEntry);

    return SUCCESS;
  }

  command result_t Drip.change[uint8_t id]() {
    /*
      Look up source and paramID in the cache.
      Increment the seqno.
      Reset the trickle timer.
    */

    DripCacheEntry *dripEntry = findEntry(id);
    
    if (dripEntry == NULL)
      return FAIL;
    
    dripEntry->metadata.seqno++;

    // Seqno 0 means that the seqno is unknown, and should only be seen
    // in a message coming in from the UART.
    if (dripEntry->metadata.seqno == 0)
      dripEntry->metadata.seqno++;

    trickleReset(dripEntry);
    
    return SUCCESS;
  }

  command result_t Drip.setSeqno[uint8_t id](uint8_t seqno) {
    DripCacheEntry *dripEntry = findEntry(id);
    
    if (dripEntry == NULL)
      return FAIL;

    if (seqno != 0) {
      dripEntry->metadata.seqno = seqno;
    }

    return SUCCESS;
  }

  event result_t SendTimer.fired() {

    /*
      For each non-null entry in the cache:
        Decrement the countdown timer.
	If the countdown timer goes below the send time and we haven't
	sent yet:
	  If we are not suppressed, send.
	  Wait until the next timer interval to examine the next entry.
	If the countdown timer goes to 0, double the trickle timer.
    */
	
    uint8_t i;
    TOS_MsgPtr pMsgBuf = call SharedMsgBuf.getMsgBuf();
    DripMsg *dripMsg = (DripMsg*) pMsgBuf->data;

    for(i = 0; i < DRIP_CACHE_ENTRIES; i++) {

      if (dripCache[i].metadata.id == 0)
	continue;

      dbg(DBG_USR1, "Testing:");
      printCacheEntry(&dripCache[i]);

      // Decrement the counter
      if (dripCache[i].trickleCountdown > 0)
	dripCache[i].trickleCountdown--;

      if (dripCache[i].trickleCountdown <= dripCache[i].trickleAnnounce &&
	  dripCache[i].trickleState == PRE_SEND) {
	
	// If it crosses below the announcement time and we haven't announced
	// yet, announce unless suppressed.

	if (dripCache[i].trickleSuppress) {
	    dripCache[i].trickleState = POST_SEND;

	} else {
	  
	  // Tell the component to fill up the buffer with some data.
	  // If the component returns TRUE, then they are going to fill
	  // it, and command us when it is ready.
	  if (!call SharedMsgBuf.lock())
	    continue;

	  msgBufBusy = TRUE;

	  dbg(DBG_USR1, "Sending:");
	  if (signal Drip.rebroadcastRequest[dripCache[i].metadata.id]
	      (pMsgBuf, dripMsg->data)) {
	    break;
	  } else {
	    call SharedMsgBuf.unlock();
	    msgBufBusy = FALSE;
	  }
	}
      } else if (dripCache[i].trickleCountdown == 0) {
	if (dripCache[i].trickleStage < MAX_SEND_INTERVAL)
	  dripCache[i].trickleStage++;
	
	trickleSet(&dripCache[i]);
      }
    }

    call SendTimer.start(TIMER_ONE_SHOT, TIMER_PERIOD);

    return SUCCESS;
  }

  command result_t Drip.rebroadcast[uint8_t id](TOS_MsgPtr msg,
						void *pData,
						uint8_t len) {
    
    /* pData does not matter right now, because there's only one buf
       they might have been filling. It will matter if we 
       acquire the buf from a lower layer, or if we have a pool. */

    TOS_MsgPtr pMsgBuf = call SharedMsgBuf.getMsgBuf();
    DripMsg *dripMsg = (DripMsg*) pMsgBuf->data;
    
    DripCacheEntry *dripEntry = findEntry(id);
    result_t result;

    if (!call SharedMsgBuf.isLocked())
      return FAIL;
    
    dripMsg->metadata = dripEntry->metadata;
    /* dripMsg->data has been filled already */

    result = call SendMsg.send(TOS_BCAST_ADDR, 
			       offsetof(DripMsg,data) + len,
			       pMsgBuf);
    if (result == SUCCESS) {
      dripEntry->trickleState = POST_SEND;
      printCacheEntry(dripEntry);
//      call Leds.greenToggle();
    } else {
      /* Unlock the buffer if we can't send the msg. The application will
	 not get to broadcast (this turn). */
      call SharedMsgBuf.unlock();
      msgBufBusy = FALSE;
    }
    
    return result;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pMsg) {
    /*
      If it's an DripMsg:
        Look up source and paramID in the cache.
	If the seqno is newer than what we have:
	  Update the seqno.
	  If the ptr is non-null:
	    Copy the new value to the data holder.
	  Reset the Trickle timer
	  signal Drip.changeHandler()
	If the seqno is the same, set the suppression flag
	If the seqno is older:
	  Reset the Trickle timer to update that node quickly
    */
    
    TOS_MsgPtr retMsg = pMsg;
    DripMsg *dripMsg = (DripMsg*) pMsg->data;

    DripCacheEntry *dripEntry = 
      findEntry(dripMsg->metadata.id);
    
    dbg(DBG_USR1, "Received msg(id=%d, seqno=%d)\n",
	dripMsg->metadata.id, dripMsg->metadata.seqno);

    //    call Leds.yellowToggle();
    
    if (dripStarted == FALSE && dripMsg->metadata.id != DRIP_WAKEUPID)
      return pMsg;

    if (dripEntry == NULL)
      return pMsg;

    dbg(DBG_USR1, "BEFORE: (myseqno=%d, diff=%d)\n",
	dripEntry->metadata.seqno, 
	(int8_t) (dripMsg->metadata.seqno - dripEntry->metadata.seqno));

    if ((int8_t)(dripMsg->metadata.seqno - dripEntry->metadata.seqno) == -128 &&
	dripEntry->metadata.seqno > 0) {
      /* Avoid the situation in which the sequence numbers both think their
	 neighbor is less. */
      dripEntry->metadata.seqno++;
    }

    if ((int8_t)(dripMsg->metadata.seqno - dripEntry->metadata.seqno) > 0 ||
	dripMsg->metadata.seqno == 0) {
      
      /* my entry is older. update and rebroadcast. */
      
      if (dripMsg->metadata.seqno == 0) {
	/* It's coming in from outside, and does not know the seqno. 
	   Give it an incremented seqno. */
	dripEntry->metadata.seqno++;
	if (dripEntry->metadata.seqno == 0)
	  dripEntry->metadata.seqno++;
	
	dripMsg->metadata.seqno = dripEntry->metadata.seqno;
      } else {
	/* It has a seqno. Copy it. */
	dripEntry->metadata.seqno = dripMsg->metadata.seqno;
      }

#ifdef DBG_DRIP
      <snms>
        logEvent("DRIP: Received(key=%1d, seqno=%1d)\n", 
		 dripMsg->metadata.id, dripMsg->metadata.seqno);
      </snms>
#endif

      dbg(DBG_USR1, "AFTER: (myseqno=%d, diff=%d)\n",
	  dripEntry->metadata.seqno, 
	  (int8_t) (dripMsg->metadata.seqno - dripEntry->metadata.seqno));

      retMsg = signal Receive.receive[dripMsg->metadata.id]
	(pMsg, dripMsg->data,
	 pMsg->length - 
	 offsetof(DripMsg,data));
      
      trickleReset(dripEntry);

    } else if ((dripMsg->metadata.seqno - dripEntry->metadata.seqno) == 0) {
      
      /* my entry is equal. suppress. */

#ifdef DRIP_NO_SUPPRESS_WAKEUP
      if (dripMsg->metadata.id != DRIP_WAKEUPID)
#endif
	dripEntry->trickleSuppress = TRUE;

    } else {

      /* my entry is newer. rebroadcast. */

      trickleReset(dripEntry);
    }
 
    return retMsg;
  }

  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, 
						       void* payload, 
						       uint16_t payloadLen) {
    return msg;
  }

  default event result_t Drip.rebroadcastRequest[uint8_t id](TOS_MsgPtr msg, 
							     void *payload) {
    return FAIL;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, 
				  result_t success) {
    if (pMsg == call SharedMsgBuf.getMsgBuf() &&
	msgBufBusy == TRUE) {
      call SharedMsgBuf.unlock();
      msgBufBusy = FALSE;
//      call Leds.yellowToggle();
    }
    return SUCCESS;
  }
}









