// $Id: MultiHopEWMA.nc,v 1.1 2004/04/22 23:22:01 jdprabhu Exp $

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


includes AM;
includes MultiHop;


#define MULTI_HOP_DEBUG 1

module MultiHopEWMA {

  provides {
    interface StdControl;
    interface RouteSelect;
    interface RouteControl;
  }

  uses {
    interface Timer;
    interface ReceiveMsg;
    interface Intercept as Snoop[uint8_t id];
    interface SendMsg;
    interface Send as DebugSendMsg;
#ifdef USE_WATCHDOG
	interface StdControl as PoochHandler;
	interface WDT;
#endif
  }
}

implementation {

  enum {
    NBRFLAG_VALID    = 0x01,
    NBRFLAG_NEW      = 0x02,
    NBRFLAG_EST_INIT = 0x04
  };

  enum {
    BASE_STATION_ADDRESS        = 0,
    ROUTE_TABLE_SIZE            = 16,
    ESTIMATE_TO_ROUTE_RATIO     = 5,
    ACCEPTABLE_MISSED           = -20,
    DATA_TO_ROUTE_RATIO         = 2,
    DATA_FREQ                   = 180000,
    SWITCH_THRESHOLD     	= 192,
    MAX_ALLOWABLE_LINK_COST     = 256*6,
    LIVELINESS              	= 2,
    MAX_DESCENDANT		= 5

  };

  enum {
    ROUTE_INVALID    = 0xff
  };

  struct SortEntry {
    uint16_t id;
    uint8_t  receiveEst;
  };

  struct SortDbgEntry {
    uint16_t id;
    uint8_t  sendEst;
    uint8_t  hopcount; 
  };

  typedef struct RPEstEntry {
    uint16_t id;
    uint8_t receiveEst;
  } __attribute__ ((packed)) RPEstEntry;

  typedef struct RoutePacket {
    uint16_t parent;
    uint16_t cost;
    uint8_t estEntries;
    RPEstEntry estList[1];
  } __attribute__ ((packed)) RoutePacket;

  typedef struct TableEntry {
    uint16_t id;  // Node Address
    uint16_t parent;
    uint16_t cost;
    uint8_t childLiveliness;
    uint16_t missed;
    uint16_t received;
    int16_t lastSeqno;
    uint8_t flags;
    uint8_t liveliness;
    uint8_t hop;
    uint8_t receiveEst;
    uint8_t sendEst;
  } TableEntry;

  TOS_Msg debugMsg; 
  TOS_Msg routeMsg; 
  bool gfSendRouteBusy;

  TableEntry BaseStation;
  TableEntry NeighborTbl[ROUTE_TABLE_SIZE];
  TableEntry *gpCurrentParent;
  uint8_t gbCurrentHopCount;
  uint16_t gbCurrentCost;
  int16_t gCurrentSeqNo;
  uint16_t gwEstTicks;
  uint32_t gUpdateInterval;
  bool gSelfTimer;


  /*////////////////////////////////////////////////////////*/
  /**
   * Return index into neighbor table of the given node addr
   * @author terence
   * @param id
   * @return index, if not found return ROUTE_INVALID
   */

  uint8_t findEntry(uint8_t id) {
    uint8_t i = 0;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if ((NeighborTbl[i].flags & NBRFLAG_VALID) && NeighborTbl[i].id == id) {
        return i;
      }
    }
    return ROUTE_INVALID;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This function determines which entry should be replace
   * in this case, we find the one with the lease send estimate
   * @author terence
   * @param void
   * @return index of the table
   */

  uint8_t findEntryToBeReplaced() {
    uint8_t i = 0;
    uint8_t minSendEst = -1;
    uint8_t minSendEstIndex = ROUTE_INVALID;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if ((NeighborTbl[i].flags & NBRFLAG_VALID) == 0) {
        return i;
      }
      if (minSendEst >= NeighborTbl[i].sendEst) {
        minSendEst = NeighborTbl[i].sendEst;
        minSendEstIndex = i;
      }
    }
    return minSendEstIndex;
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to make a new entry give an index and a id
   * @author terence
   * @param index, the index of the table
   * @param id, the node id 
   * @return void
   */

  void newEntry(uint8_t indes, uint16_t id) {
    NeighborTbl[indes].id = id;
    NeighborTbl[indes].flags = (NBRFLAG_VALID | NBRFLAG_NEW);
    NeighborTbl[indes].liveliness = 0;
    NeighborTbl[indes].parent = ROUTE_INVALID;
    NeighborTbl[indes].cost = ROUTE_INVALID;
    NeighborTbl[indes].childLiveliness = 0;
    NeighborTbl[indes].hop = ROUTE_INVALID;
    NeighborTbl[indes].missed = 0;
    NeighborTbl[indes].received = 0;
    NeighborTbl[indes].receiveEst = 0;
    NeighborTbl[indes].sendEst = 0;
    //call Estimator.clearTrackInfo(NeighborTbl[indes].trackInfo);
  }


  /*////////////////////////////////////////////////////////*/
  /**
   * Get neighbor table entry corresponding to the given address.
   * If current entry doesn't exist, then create one, possibly
   * evicting a previous entry. 
   * XXX - what if it evicts the parent???
   *
   * @author terence
   * @param id, node id
   * @return index
   */

  uint8_t findPreparedIndex(uint16_t id) {
    uint8_t indes = findEntry(id);
    if (indes == (uint8_t) ROUTE_INVALID) {
      indes = findEntryToBeReplaced();
      newEntry(indes, id);
    }
    return indes;
  }


  int sortByReceiveEstFcn(const void *x, const void *y) {
    struct SortEntry *nx = (struct SortEntry *) x;
    struct SortEntry *ny = (struct SortEntry *) y;
    uint8_t xReceiveEst = nx->receiveEst, yReceiveEst = ny->receiveEst;
    if (xReceiveEst > yReceiveEst) return -1;
    if (xReceiveEst == yReceiveEst) return 0;
    if (xReceiveEst < yReceiveEst) return 1;
    return 0; // shouldn't reach here becasue it covers all the cases
  }

  int sortDebugEstFcn(const void *x, const void *y) {
    struct SortDbgEntry *nx = (struct SortDbgEntry *) x;
    struct SortDbgEntry *ny = (struct SortDbgEntry *) y;
    uint8_t xReceiveEst = nx->sendEst, yReceiveEst = ny->sendEst;
    if (xReceiveEst > yReceiveEst) return -1;
    if (xReceiveEst == yReceiveEst) return 0;
    if (xReceiveEst < yReceiveEst) return 1;
    return 0; // shouldn't reach here becasue it covers all the cases
  }

  uint32_t evaluateCost(uint16_t cost, uint8_t sendEst, uint8_t receiveEst) {
    uint32_t transEst = (uint32_t) sendEst * (uint32_t) receiveEst;
    uint32_t immed = ((uint32_t) 1 << 24);

    if (transEst == 0) return ((uint32_t) 1 << (uint32_t) 16);
    // DO NOT change this LINE! mica compiler is WEIRD!
    immed = immed / transEst;
    immed += ((uint32_t) cost << 6);
    return immed;
  }


  void updateEst(TableEntry *Nbr) {
    uint16_t usExpTotal, usActTotal, newAve;

    if (Nbr->flags & NBRFLAG_NEW)
      return;
    
    usExpTotal = ESTIMATE_TO_ROUTE_RATIO;
    //if (pNbr->hop != 0) {
    //  usExpTotal *= (1 + DATA_TO_ROUTE_RATIO);
    //}
    dbg(DBG_ROUTE,"MultiHopEWMA: Updating Nbr %d. ExpTotl = %d, rcvd= %d, missed = %d\n",
        Nbr->id, usExpTotal, Nbr->received, Nbr->missed);

    atomic {
      usActTotal = Nbr->received + Nbr->missed;
      
      if (usActTotal < usExpTotal) {
        usActTotal = usExpTotal;
      }
      
      newAve = ((uint16_t) 255 * (uint16_t)Nbr->received) / (uint16_t)usActTotal;
      Nbr->missed = 0;
      Nbr->received = 0;

      // If we haven't seen a recieveEst for us from our neighbor, decay our sendEst
      // exponentially
      if (Nbr->liveliness  == 0) {
        Nbr->sendEst >>= 1;
      }else{
      	Nbr->liveliness --;
      }
    
    }
 

    if (Nbr->flags & NBRFLAG_EST_INIT) {
      uint16_t tmp;
      tmp = ((2 * ((uint16_t)Nbr->receiveEst) + (uint16_t)newAve * 6) / 8);
      Nbr->receiveEst = (uint8_t)tmp;
    }
    else {
      Nbr->receiveEst = (uint8_t) newAve;
      Nbr->flags ^= NBRFLAG_EST_INIT;
    }

     if(Nbr->childLiveliness > 0) Nbr->childLiveliness --;
  }

  void updateTable() {
    TableEntry *pNbr;
    uint8_t i = 0;

    gwEstTicks++;
    gwEstTicks %= ESTIMATE_TO_ROUTE_RATIO;

    for(i = 0; i < ROUTE_TABLE_SIZE; i++) {
      pNbr = &NeighborTbl[i];
      if (pNbr->flags & NBRFLAG_VALID) {
        if (gwEstTicks == 0) 
          updateEst(pNbr);
      }
    }
  }

  bool updateNbrCounters(uint16_t saddr, int16_t seqno, uint8_t *NbrIndex) {
    TableEntry *pNbr;
    int16_t sDelta;
    uint8_t iNbr;
    bool Result = FALSE;  // Result is TRUE if message is a duplicate

    if(seqno == 0) return FALSE;

    iNbr = findPreparedIndex(saddr);
    pNbr = &NeighborTbl[iNbr];

    sDelta = (seqno - NeighborTbl[iNbr].lastSeqno - 1);

    //because 0 isn't a valid sequence number, we have to subtract 1 if 
    //we get 1.  This only fixes part of the problem but oh well.
    if(seqno == 1) sDelta --;

    if (pNbr->flags & NBRFLAG_NEW) {
      pNbr->received++;
      pNbr->lastSeqno = seqno;
      pNbr->flags ^= NBRFLAG_NEW;
    }
    else if (sDelta >= 0) {
      pNbr->missed += sDelta;
      pNbr->received++;
      pNbr->lastSeqno = seqno;
    }
    else if (sDelta < ACCEPTABLE_MISSED) {
      // Something happend to this node.  Reinitialize it's state
      newEntry(iNbr,saddr);
      pNbr->received++;
      pNbr->lastSeqno = seqno;
      pNbr->flags ^= NBRFLAG_NEW;
    }
    else {
      Result = TRUE;
    }

    *NbrIndex = iNbr;
    return Result;

  }


  void chooseParent() {
    TableEntry *pNbr;
    uint32_t ulNbrLinkCost = (uint32_t) -1;
    uint32_t ulNbrTotalCost = (uint32_t) -1;
    uint32_t oldParentCost = (uint32_t) -1;
    uint32_t oldParentLinkCost = (uint32_t) -1;
    uint32_t ulMinTotalCost = (uint32_t) -1;
    TableEntry* pNewParent = NULL;
    TableEntry* pOldParent = NULL;
    uint8_t i;

    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDRESS) return;

    // Choose the parent based on minimal hopcount and cost.  
    // There is a special case for choosing a base-station as it's 
    // receiveEst may be zero (it's not sending any packets)

    for (i = 0;i < ROUTE_TABLE_SIZE;i++) {
      pNbr = &NeighborTbl[i];


      if (!(pNbr->flags & NBRFLAG_VALID)) continue;
      if (pNbr->parent == TOS_LOCAL_ADDRESS) continue;
      if (pNbr->parent == ROUTE_INVALID) continue;
      if (pNbr->hop == ROUTE_INVALID) continue;
      if (pNbr->cost == (uint16_t) ROUTE_INVALID) continue;
      if (pNbr->sendEst < 25 || pNbr->receiveEst < 25) continue;
      if (pNbr->childLiveliness > 0) continue;

      ulNbrLinkCost = evaluateCost(0, pNbr->sendEst,pNbr->receiveEst);
      ulNbrTotalCost = evaluateCost(pNbr->cost, pNbr->sendEst,pNbr->receiveEst);


      if (ulNbrLinkCost > MAX_ALLOWABLE_LINK_COST) continue;
      dbg(DBG_ROUTE,"MultiHopEWMA node: %d, Cost %d, link Cost, %d\n", pNbr->id, ulNbrTotalCost, ulNbrLinkCost);
      if (pNbr == gpCurrentParent) {
	pOldParent = pNbr;
  	oldParentCost = ulNbrTotalCost;
  	oldParentLinkCost = ulNbrLinkCost;
  	continue;
      }
      
      if (ulMinTotalCost > ulNbrTotalCost) {
        ulMinTotalCost = ulNbrTotalCost;
        pNewParent = pNbr;
      }

    }

    //now pick between old and new.
    if(pNewParent == NULL) {
	//use the old parent unless it is null;
	pNewParent = pOldParent;
        ulMinTotalCost = oldParentCost;
    } else if((pOldParent != NULL) &&
              (oldParentCost < (SWITCH_THRESHOLD + ulMinTotalCost))){
	//both valid, but use the old parent 
	pNewParent = pOldParent;
        ulMinTotalCost = oldParentCost;
    }

    if (pNewParent) {
      atomic {
        gpCurrentParent = pNewParent;
        gbCurrentHopCount = pNewParent->hop + 1;
        gbCurrentCost = ulMinTotalCost >> 6;
      }
    } else {
      atomic {
        gpCurrentParent = NULL;
        gbCurrentHopCount = ROUTE_INVALID;
        gbCurrentCost = ROUTE_INVALID;
      }

    }
  }

   command result_t RouteSelect.forwardFailed(){
	gpCurrentParent->sendEst >>= 1;
	chooseParent();
  }
  uint8_t last_entry_sent;

  task void SendRouteTask() {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *) &routeMsg.data[0];
    RoutePacket *pRP = (RoutePacket *)&pMHMsg->data[0];
    uint8_t length = offsetof(TOS_MHopMsg,data) + offsetof(RoutePacket,estList);
    uint8_t maxEstEntries;
    uint8_t i,j;
    uint8_t last_index_added = 0;

    if (gfSendRouteBusy) {
      return;
    }

    dbg(DBG_ROUTE,"MultiHopEWMA Sending route update msg.\n");
    dbg(DBG_ROUTE,"Current cost: %d.\n", gbCurrentCost);

    maxEstEntries = TOSH_DATA_LENGTH - length;
    maxEstEntries = maxEstEntries / sizeof(RPEstEntry);


    pRP->parent = (gpCurrentParent) ? gpCurrentParent->id : ROUTE_INVALID;
    pRP->cost = gbCurrentCost; 

    for (i = 0,j = 0;i < ROUTE_TABLE_SIZE && j < maxEstEntries; i++) {
      uint8_t table_index = i + last_entry_sent + 1;
      if(table_index >= ROUTE_TABLE_SIZE) table_index -=ROUTE_TABLE_SIZE;
      if (NeighborTbl[table_index].flags & NBRFLAG_VALID && NeighborTbl[table_index].receiveEst > 100) {
        pRP->estList[j].id = NeighborTbl[table_index].id;
        pRP->estList[j].receiveEst = NeighborTbl[table_index].receiveEst;
	j ++;
        length += sizeof(RPEstEntry);
	last_index_added = table_index;
        dbg(DBG_ROUTE,"Adding %d to route msg.\n", pRP->estList[j].id);
      }
    }
    last_entry_sent = last_index_added;
    dbg(DBG_ROUTE,"Added total of %d entries to route msg.\n", j);
    pRP->estEntries = j;
    pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->hopcount = gbCurrentHopCount;
    pMHMsg->seqno = gCurrentSeqNo++;
    if(gCurrentSeqNo == 0) gCurrentSeqNo = 1;

    if (call SendMsg.send(TOS_BCAST_ADDR, length, &routeMsg) == SUCCESS) {
      gfSendRouteBusy = TRUE;
    }

  }


  task void SendDebugTask() {
    struct SortDbgEntry sortTbl[ROUTE_TABLE_SIZE];
    uint16_t max_length;
    uint8_t length = offsetof(DebugPacket,estList);
    DebugPacket *pRP = (DebugPacket *)call DebugSendMsg.getBuffer(&debugMsg,&max_length);
    uint8_t maxEstEntries;
    uint16_t parent;
    uint8_t i,j;

    dbg(DBG_ROUTE,"MultiHopEWMA Sending route debug msg.\n");

    maxEstEntries = max_length / sizeof(DBGEstEntry);
    maxEstEntries --;
    parent = (gpCurrentParent) ? gpCurrentParent->id : ROUTE_INVALID;

    for (i = 0,j = 0;i < ROUTE_TABLE_SIZE; i++) {
      if (NeighborTbl[i].flags & NBRFLAG_VALID && NeighborTbl[i].id != parent) {
        sortTbl[j].id = NeighborTbl[i].id;
        sortTbl[j].sendEst = NeighborTbl[i].sendEst;
        sortTbl[j].hopcount = NeighborTbl[i].hop;
        j++;
      }
    }
    qsort (sortTbl,j,sizeof(struct SortDbgEntry),sortDebugEstFcn);

    pRP->estEntries = (j > maxEstEntries) ? maxEstEntries : j;
    pRP->estList[0].id = parent;
    if(gpCurrentParent){
	pRP->estList[0].sendEst = gpCurrentParent->sendEst;
	pRP->estList[0].hopcount = gpCurrentParent->hop;
    }
    length += sizeof(DBGEstEntry);

    for (i = 0; i < pRP->estEntries; i++) {
      pRP->estList[i+1].id = sortTbl[i].id;
      pRP->estList[i+1].sendEst = sortTbl[i].sendEst;
      pRP->estList[i+1].hopcount = sortTbl[i].hopcount;
      length += sizeof(DBGEstEntry);
    }
    pRP->estEntries ++;
    call DebugSendMsg.send(&debugMsg, length);

  }

  int debugCounter;

  task void TimerTask() {
    
    dbg(DBG_ROUTE,"MultiHopEWMA timer task.\n");
    updateTable();

#ifndef NDEBUG
    {
      int i;
      dbg(DBG_ROUTE,"\taddr\tprnt\tcost\tmisd\trcvd\tlstS\thop\trEst\tsEst\tDesc\n");
      for (i = 0;i < ROUTE_TABLE_SIZE;i++) {
        if (NeighborTbl[i].flags) {
          dbg(DBG_ROUTE,"\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
              NeighborTbl[i].id,
              NeighborTbl[i].parent,
              NeighborTbl[i].cost,
              NeighborTbl[i].missed,
              NeighborTbl[i].received,
              NeighborTbl[i].lastSeqno,
              NeighborTbl[i].hop,
              NeighborTbl[i].receiveEst,
              NeighborTbl[i].sendEst,
              NeighborTbl[i].childLiveliness);
        }
      }
      if (gpCurrentParent) {
        dbg(DBG_ROUTE,"MultiHopEWMA: Parent = %d\n",gpCurrentParent->id);
      }
    }
#endif
    chooseParent();
#ifdef MULTI_HOP_DEBUG
    if(TOS_LOCAL_ADDRESS != BASE_STATION_ADDRESS) debugCounter ++;
    if(debugCounter > 1){
	post SendDebugTask();
	debugCounter = 0;
    }else{
#endif //MULTI_HOP_DEBUG
    	post SendRouteTask();
#ifdef MULTI_HOP_DEBUG
    }
#endif //MULTI_HOP_DEBUG

  }


  command result_t StdControl.init() {

    memset((void *)NeighborTbl,0,(sizeof(TableEntry) * ROUTE_TABLE_SIZE));
    BaseStation.id = TOS_UART_ADDR;
    BaseStation.parent = TOS_UART_ADDR;
    BaseStation.flags = NBRFLAG_VALID;
    BaseStation.hop = 0;
    gpCurrentParent = NULL;
    gbCurrentHopCount = ROUTE_INVALID;
    gCurrentSeqNo = 1;
    gwEstTicks = 0;
    gUpdateInterval = TOS_LOCAL_ADDRESS;
    gUpdateInterval <<= 10;
    gUpdateInterval += DATA_TO_ROUTE_RATIO * DATA_FREQ;
    gfSendRouteBusy = FALSE;
	gSelfTimer = TRUE;

    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDRESS) {

      gpCurrentParent = &BaseStation;
      gbCurrentHopCount = 0;
      gbCurrentCost = 0;

    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
	if (gSelfTimer) {
		post TimerTask();
		call Timer.start(TIMER_REPEAT,gUpdateInterval);
#ifdef USE_WATCHDOG
		call PoochHandler.start();
		call WDT.start(gUpdateInterval * 5);
#endif
	}
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  command bool RouteSelect.isActive() {
#if 0
    bool Result = FALSE;

    if (gpCurrentParent != NULL) {
      Result = TRUE;
    }

    return Result;
#endif

    return TRUE;
  }


  void updateDescendant(uint16_t id){
	uint8_t indes = findEntry(id);
	if (indes == (uint8_t) ROUTE_INVALID) { return;}
	else{
		NeighborTbl[indes].childLiveliness = MAX_DESCENDANT;
	}
  }

  command result_t RouteSelect.selectRoute(TOS_MsgPtr Msg, uint8_t id, uint8_t resend, uint8_t force_monitor) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

    uint8_t iNbr;
    bool fIsDuplicate;
    result_t Result = SUCCESS;

    Msg->strength = 0;

    if (gpCurrentParent == NULL) {
      // If the msg is locally generated, then send it to the broadcast address
      // This is necessary to seed the network.
      if ((pMHMsg->sourceaddr == TOS_LOCAL_ADDRESS) &&
          (pMHMsg->originaddr == TOS_LOCAL_ADDRESS)) {
        pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
        pMHMsg->hopcount = gbCurrentHopCount;
        pMHMsg->seqno = gCurrentSeqNo++;
        if(gCurrentSeqNo == 0) gCurrentSeqNo = 1;
        Msg->addr = TOS_BCAST_ADDR;
        return SUCCESS;
      }
      else {
        return FAIL;
      }
    }

    if (gbCurrentHopCount >= pMHMsg->hopcount && resend == 0) {
      // Possible cycle??
      return FAIL;
    }
    
    if ((pMHMsg->sourceaddr == TOS_LOCAL_ADDRESS) &&
        (pMHMsg->originaddr == TOS_LOCAL_ADDRESS)) {
      fIsDuplicate = FALSE;
    } else if(resend == 1){
      fIsDuplicate = FALSE;
    }else {
      fIsDuplicate = updateNbrCounters(pMHMsg->sourceaddr,pMHMsg->seqno,&iNbr);
    }

    //only packets to the base station don't get monitored.
    if(gpCurrentParent->id != 0) force_monitor = 1;

    if (!fIsDuplicate) {
      pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
      pMHMsg->hopcount = gbCurrentHopCount;
      if (gpCurrentParent->id != TOS_UART_ADDR && force_monitor == 1) {
        pMHMsg->seqno = gCurrentSeqNo++;
      }else{
	pMHMsg->seqno = 0;
	Msg->strength = 0xffff;
      }
      if(gCurrentSeqNo == 0) gCurrentSeqNo = 1;
      Msg->addr = gpCurrentParent->id;
      if(pMHMsg->originaddr != TOS_LOCAL_ADDRESS){
	  updateDescendant(pMHMsg->originaddr);
      }
    }
    else {
      Result = FAIL;
    }
    dbg(DBG_ROUTE,"MultiHopEWMA: Sequence Number: %d\n", pMHMsg->seqno);

    return Result;

  }

  command result_t RouteSelect.initializeFields(TOS_MsgPtr Msg, uint8_t id) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

    pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->hopcount = ROUTE_INVALID;

    return SUCCESS;
  }

  command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr Msg, uint16_t* Len) {

  }

  command uint16_t RouteControl.getParent() {

    uint16_t addr;

    addr = (gpCurrentParent != NULL) ? gpCurrentParent->id : 0xffff;

    return addr;
  }

  command uint8_t RouteControl.getQuality() {
    uint8_t val;

    val = (gpCurrentParent != NULL) ? gpCurrentParent->sendEst : 0x00;

    return val;
  }

  command uint8_t RouteControl.getDepth() {
    return gbCurrentHopCount;
  }

  command uint8_t RouteControl.getOccupancy() {
    return 0;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {
    result_t Result;

    call Timer.stop();
    gUpdateInterval = (Interval * 1024);  // * 1024 to make the math simpler
	gSelfTimer = TRUE;
    Result = call Timer.start(TIMER_REPEAT,gUpdateInterval);
#ifdef USE_WATCHDOG
	call PoochHandler.stop();
	call PoochHandler.start();
	call WDT.start(gUpdateInterval * 5);
#endif

    return Result;
  }

  command result_t RouteControl.manualUpdate() {
    result_t Result;

	gSelfTimer = FALSE;
	call Timer.stop();
    Result = post TimerTask();
    return Result;
  }



  event result_t Timer.fired() {
    post TimerTask();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
    RoutePacket *pRP = (RoutePacket *)&pMHMsg->data[0];
    uint16_t saddr;
    uint8_t i, iNbr;

#ifdef USE_WATCHDOG
	call WDT.reset();
#endif

    saddr = pMHMsg->sourceaddr;

    updateNbrCounters(saddr,pMHMsg->seqno,&iNbr);
    //    iNbr = findPreparedIndex(saddr);

    NeighborTbl[iNbr].parent = pRP->parent;
    NeighborTbl[iNbr].hop = pMHMsg->hopcount;
    NeighborTbl[iNbr].cost = pRP->cost;

    // find out my address, extract the estimation
    for (i = 0; i < pRP->estEntries; i++) {
      if (pRP->estList[i].id == TOS_LOCAL_ADDRESS) {
        NeighborTbl[iNbr].sendEst = pRP->estList[i].receiveEst;
        NeighborTbl[iNbr].liveliness = LIVELINESS;
      }
    }

    return Msg;
  }

  event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr Msg, void *Payload, uint16_t Len) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
    uint8_t iNbr;

    updateNbrCounters(pMHMsg->sourceaddr,pMHMsg->seqno,&iNbr);

    return SUCCESS;
  }


  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    gfSendRouteBusy = FALSE;

    return SUCCESS;
  }
  event result_t DebugSendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

}

