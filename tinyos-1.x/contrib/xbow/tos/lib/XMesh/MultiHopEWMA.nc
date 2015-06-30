// $Id: MultiHopEWMA.nc,v 1.3 2005/01/14 01:25:22 jdprabhu Exp $

/*
 * Copyright (c) 2005 Crossbow Technology, Inc.
 *
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and
 * documentation is granted, provided the following conditions are met:
 * 
 * 1. The above copyright notice and these conditions, along with the
 * following disclaimers, appear in all copies of the software.
 * 
 * 2. When the use, copying, modification or distribution is for COMMERCIAL
 * purposes (i.e., any use other than academic research), then the software
 * (including all modifications of the software) may be used ONLY with
 * hardware manufactured by and purchased from Crossbow Technology, unless
 * you obtain separate written permission from, and pay appropriate fees
 * to, Crossbow. For example, no right to copy and use the software on
 * non-Crossbow hardware, if the use is commercial in nature, is permitted
 * under this license. 
 *
 * 3. When the use, copying, modification or distribution is for
 * NON-COMMERCIAL PURPOSES (i.e., academic research use only), the software
 * may be used, whether or not with Crossbow hardware, without any fee to
 * Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE
 * TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
 * EVEN IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM
 * ALL WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY
 * LICENSOR HAS ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS. 
 * 
 */

includes AM;
includes MultiHop;


#define MULTI_HOP_DEBUG 1

module MultiHopEWMA {

  provides {
    interface StdControl;
    interface RouteSelect;
    interface RouteControl;
    command void set_power_mode(uint8_t mode);
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
#ifndef ROUTE_UPDATE_INTERVAL
#ifdef TEN_X
    ROUTE_UPDATE_INTERVAL      = 36000,
#else
    ROUTE_UPDATE_INTERVAL      = 360000,
#endif
#endif
    SWITCH_THRESHOLD     	    = 192,
    MAX_ALLOWABLE_LINK_COST     = 256*6,
    LIVELINESS              	= 2,
    MAX_DESCENDANT		        = 5

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
    uint16_t id;  
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
  uint8_t power_mode;
  bool gSelfTimer;

  uint8_t descendant_route[128];   

  command void set_power_mode(uint8_t mode){
	power_mode = mode;
  }


   
    uint16_t next_sequence_number(){
    if(power_mode == 0){
    	gCurrentSeqNo++;
    	if(gCurrentSeqNo == 0) gCurrentSeqNo = 1;
    	return gCurrentSeqNo;
    }else{
	return 0;
    }
  }

   
  uint8_t findEntry(uint8_t id) {
    uint8_t i = 0;
    for (i = 0; i < ROUTE_TABLE_SIZE; i++) {
      if ((NeighborTbl[i].flags & NBRFLAG_VALID) && NeighborTbl[i].id == id) {
        return i;
      }
    }
    return ROUTE_INVALID;
  }
  
  
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
    
  }

  
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
    return 0; 
  }

  int sortDebugEstFcn(const void *x, const void *y) {
    struct SortDbgEntry *nx = (struct SortDbgEntry *) x;
    struct SortDbgEntry *ny = (struct SortDbgEntry *) y;
    uint8_t xReceiveEst = nx->sendEst, yReceiveEst = ny->sendEst;
    if (xReceiveEst > yReceiveEst) return -1;
    if (xReceiveEst == yReceiveEst) return 0;
    if (xReceiveEst < yReceiveEst) return 1;
    return 0; 
  }



  uint32_t evaluateCost(uint16_t cost, uint8_t sendEst, uint8_t receiveEst) {
    uint32_t transEst = (uint32_t) sendEst * (uint32_t) receiveEst;
    uint32_t immed = ((uint32_t) 1 << 24);

    if (transEst == 0) return ((uint32_t) 1 << (uint32_t) 16);
    
    immed = immed / transEst;
    immed += ((uint32_t) cost << 6);
    return immed;
  }


  void updateEst(TableEntry *Nbr) {
    uint16_t usExpTotal, usActTotal, newAve;

    if (Nbr->flags & NBRFLAG_NEW)  return;
    
    usExpTotal = ESTIMATE_TO_ROUTE_RATIO >> 1;
    usExpTotal = 1;

    dbg(DBG_ROUTE,"MultiHopEWMA: Updating Nbr %d. ExpTotl = %d, rcvd= %d, missed = %d\n",
        Nbr->id, usExpTotal, Nbr->received, Nbr->missed);

    atomic {
      usActTotal = Nbr->received + Nbr->missed;
      if (usActTotal < usExpTotal) usActTotal = usExpTotal;
      newAve = ((uint16_t) 255 * (uint16_t)Nbr->received) / (uint16_t)usActTotal;
      Nbr->missed = 0;
      Nbr->received = 0;
      if (Nbr->liveliness  == 0) Nbr->sendEst >>= 1;
      else                       Nbr->liveliness --;
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
    bool Result = FALSE;  

    if(seqno == 0) return FALSE;

    iNbr = findPreparedIndex(saddr);
    pNbr = &NeighborTbl[iNbr];

    sDelta = (seqno - NeighborTbl[iNbr].lastSeqno - 1);

    
    
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
      newEntry(iNbr,saddr);
      pNbr->received++;
      pNbr->lastSeqno = seqno;
      pNbr->flags ^= NBRFLAG_NEW;
    }
    else {
      Result = TRUE;
    }

    *NbrIndex = iNbr;
    if(saddr == 0) return FALSE;
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

    if(pNewParent == NULL){
     for (i = 0;i < ROUTE_TABLE_SIZE;i++) {
      pNbr = &NeighborTbl[i];
      if (!(pNbr->flags & NBRFLAG_VALID)) continue;
      if (pNbr->parent == TOS_LOCAL_ADDRESS) continue;
      if (pNbr->parent == ROUTE_INVALID) continue;
      if (pNbr->hop == ROUTE_INVALID) continue;
      if (pNbr->childLiveliness > 0) continue;

      ulNbrLinkCost = evaluateCost(0, pNbr->sendEst,pNbr->receiveEst);
      ulNbrTotalCost = evaluateCost(pNbr->cost, pNbr->sendEst,pNbr->receiveEst);
      if (ulMinTotalCost > ulNbrTotalCost) {
        ulMinTotalCost = ulNbrTotalCost;
        pNewParent = pNbr;
      }
     }
    }
    
    if(pNewParent == NULL) {
	
	
	pNewParent = gpCurrentParent;
        ulMinTotalCost = ROUTE_INVALID;
    } else if((pOldParent != NULL) &&
              (oldParentCost < (SWITCH_THRESHOLD + ulMinTotalCost))){
	
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
	if(gpCurrentParent != NULL) gpCurrentParent->sendEst >>= 1;
	chooseParent();
	return SUCCESS;
  }
  uint8_t last_entry_sent;

  uint8_t error_count; 

  void RESET_NODE(){
	atomic{
		wdt_enable(WDTO_500MS);
		while(1){;}
	}
  }

  

  task void SendRouteTask() {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *) &routeMsg.data[0];
    RoutePacket *pRP = (RoutePacket *)&pMHMsg->data[0];
    uint8_t length = offsetof(TOS_MHopMsg,data) + offsetof(RoutePacket,estList);
    uint8_t maxEstEntries;
    uint8_t i,j;
    uint8_t last_index_added = 0;


    if(error_count > 5){
	RESET_NODE();
    }

    if (gfSendRouteBusy) {
      error_count ++;
      return;
    }

    dbg(DBG_ROUTE,"MultiHopEWMA Sending route update msg.\n");
    dbg(DBG_ROUTE,"Current cost: %d.\n", gbCurrentCost);

    maxEstEntries = TOSH_DATA_LENGTH - length;
    maxEstEntries = maxEstEntries / sizeof(RPEstEntry);


    pRP->parent = (gpCurrentParent) ? gpCurrentParent->id : ROUTE_INVALID;
    pRP->cost = gbCurrentCost; 

    routeMsg.strength = 0xffff;

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
    pMHMsg->seqno = next_sequence_number();

    if (call SendMsg.send(TOS_BCAST_ADDR, length, &routeMsg) == SUCCESS) {
      gfSendRouteBusy = TRUE;
    }else{
      error_count ++;
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

    debugMsg.strength = 0xffff;

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
    chooseParent();
#ifdef MULTI_HOP_DEBUG
    if(TOS_LOCAL_ADDRESS != BASE_STATION_ADDRESS) debugCounter ++;
    if(debugCounter > 1){
	post SendDebugTask();
	debugCounter = 0;
    }else{
#endif 
    	post SendRouteTask();
#ifdef MULTI_HOP_DEBUG
    }
#endif 

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
    gUpdateInterval += ((uint32_t)ROUTE_UPDATE_INTERVAL);
    gfSendRouteBusy = FALSE;
    gSelfTimer = TRUE;
    error_count  = 0;

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
	else NeighborTbl[indes].childLiveliness = MAX_DESCENDANT;
  }


   

   
   void updateDescendantRoute(uint16_t id, uint16_t route){
       descendant_route[id & 0x7f] = route;
   }

   
   command result_t RouteSelect.selectDescendantRoute(TOS_MsgPtr Msg, uint8_t id, uint8_t resend, uint8_t force_monitor) {
     TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
     uint8_t iNbr;
     bool fIsDuplicate;
     result_t Result = SUCCESS;
     if (gbCurrentHopCount < pMHMsg->hopcount && resend == 0) {
       
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

     if (!fIsDuplicate) {
       pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
       pMHMsg->hopcount = gbCurrentHopCount;
       
       Msg->addr =  descendant_route[pMHMsg->originaddr & 0x7f];
       if(Msg->addr == 0) Result = FAIL;
	   else               pMHMsg->seqno = next_sequence_number();  
       Msg->strength = 0;
     }
     else {
       Result = FAIL;
     }
     dbg(DBG_ROUTE,"MultiHopEWMA: Sequence Number: %d\n", pMHMsg->seqno);

     return Result;
   }


  command result_t RouteSelect.selectRoute(TOS_MsgPtr Msg, uint8_t id, uint8_t resend, uint8_t force_monitor) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

    uint8_t iNbr;
    bool fIsDuplicate;
    result_t Result = SUCCESS;

    Msg->strength = 0;

    if (gpCurrentParent == NULL) {
      
      
      if ((pMHMsg->sourceaddr == TOS_LOCAL_ADDRESS) &&
          (pMHMsg->originaddr == TOS_LOCAL_ADDRESS)) {
        pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
        pMHMsg->hopcount = gbCurrentHopCount;
        pMHMsg->seqno = next_sequence_number();
        Msg->addr = TOS_BCAST_ADDR;
    	Msg->strength = 0;
        return SUCCESS;
      }
      else {
        return FAIL;
      }
    }

    if (gbCurrentHopCount >= pMHMsg->hopcount && resend == 0) {
      
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

    
    if(gpCurrentParent->id != 0 && resend == 1) force_monitor = 1;

    if (!fIsDuplicate) {
      uint16_t source = pMHMsg->sourceaddr;
      if(source != TOS_LOCAL_ADDRESS){
        updateDescendantRoute(pMHMsg->originaddr, source);
      }
      pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
      pMHMsg->hopcount = gbCurrentHopCount;
      if (gpCurrentParent->id != TOS_UART_ADDR && force_monitor == 1) {
	    
        pMHMsg->seqno = next_sequence_number();
	    Msg->strength = (uint16_t)0xffff;
	    if(resend) Msg->strength = 0;
      }else if(gpCurrentParent->id == 0){
	
	   pMHMsg->seqno = 0;                
	   Msg->strength = 0x7fff;
      }else {
	
	   pMHMsg->seqno = 0;                
	   Msg->strength = 0xffff;
      }
      Msg->addr = gpCurrentParent->id;
      if(pMHMsg->originaddr != TOS_LOCAL_ADDRESS) updateDescendant(pMHMsg->originaddr);
    }
    else Result = FAIL;
    
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
    gUpdateInterval = (Interval * 1024);  
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
	
	if(Msg->type == 0xef) return Msg;
    saddr = pMHMsg->sourceaddr;

    updateNbrCounters(saddr,pMHMsg->seqno,&iNbr);
    

    NeighborTbl[iNbr].parent = pRP->parent;
    NeighborTbl[iNbr].hop    = pMHMsg->hopcount;
    NeighborTbl[iNbr].cost   = pRP->cost;

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
    if(success) error_count = 0;

    return SUCCESS;
  }
  event result_t DebugSendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

}

