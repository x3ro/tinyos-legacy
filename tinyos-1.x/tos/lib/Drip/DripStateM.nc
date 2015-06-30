//$Id: DripStateM.nc,v 1.1 2005/10/27 21:29:43 gtolle Exp $

/*								       
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

includes Drip;

/**
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

module DripStateM {
  provides {
    interface StdControl;
    interface DripState[uint8_t local];
    interface DripStateMgr;
  }
  uses {
    interface Random;
  }
}

implementation {

  DripCacheEntry dripCache[DRIP_CACHE_ENTRIES];

  void printCacheEntry(DripCacheEntry *entry);
  void printCache();
  void trickleReset(DripCacheEntry *dripEntry);
  void trickleSet(DripCacheEntry *dripEntry);
  void incrementSeqno(DripCacheEntry *dripEntry);

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t DripState.init[uint8_t localKey](uint8_t globalKey) {
    DripCacheEntry *dripEntry = &dripCache[localKey];
    
    dripEntry->metadata.id = globalKey;
    dripEntry->metadata.seqno = DRIP_SEQNO_FIRST;

    trickleReset(dripEntry);
    dbg(DBG_USR1, "INIT: ");
    printCacheEntry(dripEntry);

    return SUCCESS;
  }

  command uint16_t DripState.getSeqno[uint8_t localKey]() {
    DripCacheEntry *dripEntry = &dripCache[localKey];
    
    return dripEntry->metadata.seqno;
  }

  command result_t DripState.setSeqno[uint8_t localKey](uint16_t seqno) {
    DripCacheEntry *dripEntry = &dripCache[localKey];

    uint16_t trueSeqno = seqno & ~DRIP_WAKEUP_BIT;

    if (trueSeqno != DRIP_SEQNO_OLDEST && trueSeqno != DRIP_SEQNO_NEWEST) {
      dripEntry->metadata.seqno = seqno;
      return SUCCESS;
    }

    return FAIL;
  }

  command result_t DripState.incrementSeqno[uint8_t localKey]() {
    DripCacheEntry *dripEntry = &dripCache[localKey];

    incrementSeqno(dripEntry);

    trickleReset(dripEntry);

    return SUCCESS;
  }

  void incrementSeqno(DripCacheEntry *dripEntry) {
    dripEntry->metadata.seqno++;
    dripEntry->metadata.seqno++;
    
    // Seqno 0 means that the seqno is unknown, and should only be seen
    // in a message coming in from the UART.
    while (((dripEntry->metadata.seqno & ~DRIP_WAKEUP_BIT) == 
	    DRIP_SEQNO_OLDEST)
	   ||
	   ((dripEntry->metadata.seqno & ~DRIP_WAKEUP_BIT) == 
	    DRIP_SEQNO_NEWEST) 
	   ||
	   ((dripEntry->metadata.seqno & ~DRIP_WAKEUP_BIT) == 
	    DRIP_SEQNO_UNKNOWN))
    {
      dripEntry->metadata.seqno++;
      dripEntry->metadata.seqno++;
    }
  }

  command result_t DripState.entrySent[uint8_t localKey]() {
    DripCacheEntry *dripEntry = &dripCache[localKey];
    dripEntry->trickleState = DRIP_POST_SEND;

    return SUCCESS;
  }

  command bool DripState.newMsg[uint8_t localKey](DripMetadata incomingMetadata) {
    DripCacheEntry *dripEntry = &dripCache[localKey];

    uint16_t incomingSeqno = incomingMetadata.seqno & ~DRIP_WAKEUP_BIT;
    uint16_t currentSeqno = dripEntry->metadata.seqno & ~DRIP_WAKEUP_BIT;
 
    dbg(DBG_USR1,"DripState received: currentSeqNo=%d, incomingSeqNo=%d\n",currentSeqno, incomingSeqno);

    if ((currentSeqno == DRIP_SEQNO_UNKNOWN &&
	 incomingSeqno != DRIP_SEQNO_UNKNOWN &&
	 incomingSeqno != DRIP_SEQNO_OLDEST) ||
	(currentSeqno != DRIP_SEQNO_UNKNOWN &&
	 incomingSeqno != DRIP_SEQNO_UNKNOWN &&
	 incomingSeqno != DRIP_SEQNO_OLDEST &&
	 ((int16_t)(incomingSeqno - currentSeqno) > 0 ||
	  incomingSeqno == DRIP_SEQNO_NEWEST))) {

      /* my entry is older. save new data. */

      if (incomingSeqno == DRIP_SEQNO_NEWEST) {
	/* It's coming in from outside, and does not know the seqno. 
	   Give it an incremented seqno. */

	incrementSeqno(dripEntry);

	// if the new seqno and the current seqno are different in
	// their wakeup status, increment the current seqno once more
	// to make them match.

	if ((dripEntry->metadata.seqno & DRIP_WAKEUP_BIT) != 
	    (incomingMetadata.seqno & DRIP_WAKEUP_BIT)) {
	  dripEntry->metadata.seqno++;
	}
	
      } else {
	
	dripEntry->metadata.seqno = incomingMetadata.seqno;
      }

      trickleReset(dripEntry);

      return TRUE;
      
    } else if (((int16_t)(incomingSeqno - currentSeqno) == 0) && 
	       incomingSeqno != DRIP_SEQNO_OLDEST) {
      
      /* my entry is equal. suppress. */
      
      dripEntry->trickleSuppress = TRUE;

    } else {
      
      /* my entry is newer. rebroadcast. */

      trickleReset(dripEntry);
    }

    return FALSE;
  }

  command result_t DripState.fillMetadata[uint8_t localKey](DripMetadata* metadata) {
    DripCacheEntry *dripEntry = &dripCache[localKey];
    
    *metadata = dripEntry->metadata;
    return SUCCESS;
  }

  command result_t DripStateMgr.updateCounters() {

    /*
      For each entry in the cache:
        Decrement the countdown timer.
	If the countdown timer goes below the send time and we haven't
	sent yet:
	  If we have been suppressed, prevent sending.
  	If the countdown timer goes to 0, double the trickle timer.
    */
	
    uint8_t i;

    for(i = 0; i < DRIP_CACHE_ENTRIES; i++) {

      /*      
	      dbg(DBG_USR1, "COUNT:");
	      printCacheEntry(&dripCache[i]);
      */

      if (dripCache[i].trickleCountdown > 0)
	dripCache[i].trickleCountdown--;
      
      if (dripCache[i].trickleCountdown <= dripCache[i].trickleAnnounce &&
	  dripCache[i].trickleState == DRIP_PRE_SEND) {
	
	if (dripCache[i].trickleSuppress) {
	  dripCache[i].trickleState = DRIP_POST_SEND;
	}

      } else if (dripCache[i].trickleCountdown == 0) {
	
	if (dripCache[i].trickleStage < DRIP_MAX_SEND_INTERVAL)
	  dripCache[i].trickleStage++;
	
	trickleSet(&dripCache[i]);
      }
    }

    return SUCCESS;
  }

  command uint8_t DripStateMgr.findReadyEntry() {
    uint8_t i;

    for(i = 0; i < DRIP_CACHE_ENTRIES; i++) {
      if (dripCache[i].trickleCountdown <= dripCache[i].trickleAnnounce &&
	  dripCache[i].trickleState == DRIP_PRE_SEND) {      
//	dbg(DBG_USR1, "READY: ");
//	printCacheEntry(&dripCache[i]);
	return dripCache[i].metadata.id;
      }
    }
    
    return DRIP_INVALID_KEY;
  }

  void trickleReset(DripCacheEntry *dripEntry) {

    dripEntry->trickleStage = DRIP_MIN_SEND_INTERVAL;
    trickleSet(dripEntry);
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
    dripEntry->trickleState = DRIP_PRE_SEND;
  }
    
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

  
}
