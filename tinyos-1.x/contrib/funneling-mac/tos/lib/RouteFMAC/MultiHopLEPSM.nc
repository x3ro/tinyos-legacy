// $Id: MultiHopLEPSM.nc,v 1.1.1.1 2007/07/06 03:44:07 ahngang Exp $

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

module MultiHopLEPSM {

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
    interface RouteManagement;
    interface Leds;
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
    DATA_FREQ                   = 10000,
    MAX_ALLOWABLE_LINK_COST     = 1536,
    MIN_LIVELINESS              = 2

  };

  enum {
    ROUTE_INVALID    = 0xff
  };

  struct SortEntry {
    uint16_t id;
    uint8_t  receiveEst;
  };

  typedef struct RPEstEntry {
    uint16_t id;
    uint8_t receiveEst;
  } __attribute__ ((packed)) RPEstEntry;

  typedef struct RoutePacket {
    uint16_t sourceaddr;  // fmac
    uint16_t originaddr;  // fmac
    int16_t seqno;        // fmac
    uint8_t hopcount;     // fmac
    uint16_t parent;
    //    uint16_t cost; // XXX This has NO real use.
    //    uint8_t hop;  // XXX Is this already in the MH header??
    uint8_t estEntries;
    RPEstEntry estList[1];
  } __attribute__ ((packed)) RoutePacket;

  typedef struct TableEntry {
    uint16_t id;  // Node Address
    uint16_t parent;
    uint16_t missed;
    uint16_t received;
    int16_t lastSeqno;
    uint8_t flags;
    uint8_t liveliness;
    uint8_t hop;
    uint8_t receiveEst;
    uint8_t sendEst;
  } TableEntry;

  TOS_Msg routeMsg; 
  bool gfSendRouteBusy;

  TableEntry BaseStation;
  TableEntry NeighborTbl[ROUTE_TABLE_SIZE];
  TableEntry *gpCurrentParent;
  uint8_t gbCurrentHopCount;
  int16_t gCurrentSeqNo;
  uint16_t gwEstTicks;
  uint32_t gUpdateInterval;
  bool waitforinterrupt;   //fmac


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

  uint32_t evaluateCost(uint8_t sendEst, uint8_t receiveEst) {
    uint32_t transEst = (uint32_t) sendEst * (uint32_t) receiveEst;
    uint32_t immed = ((uint32_t) 1 << 24);

    if (transEst == 0) return ((uint32_t) 1 << (uint32_t) 16);
    // DO NOT change this LINE! mica compiler is WEIRD!
    immed = immed / transEst;
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
    dbg(DBG_ROUTE,"MultiHopLEPSM: Updating Nbr %d. ExpTotl = %d, rcvd= %d, missed = %d\n",
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
      if (Nbr->liveliness < MIN_LIVELINESS) {
        Nbr->sendEst <<= 1;
      }
      Nbr->liveliness = 0;
    
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

    dbg(DBG_TEMP, "GET IN updateNbrCounters\n");
    iNbr = findPreparedIndex(saddr);
    pNbr = &NeighborTbl[iNbr];
    sDelta = (seqno - NeighborTbl[iNbr].lastSeqno - 1);

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
    uint32_t ulMinLinkCost = (uint32_t) -1;
    TableEntry* pNewParent = NULL;
    uint8_t bNewHopCount = ROUTE_INVALID;
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
      if (pNbr->sendEst < 25) continue;
      if ((pNbr->hop != 0) && (pNbr->receiveEst < 25)) continue;

      ulNbrLinkCost = evaluateCost(pNbr->sendEst,pNbr->receiveEst);

      if ((pNbr->hop != 0) && (ulNbrLinkCost > MAX_ALLOWABLE_LINK_COST)) continue;
      
      if ((pNbr->hop < bNewHopCount) || 
          ((pNbr->hop == bNewHopCount) && ulMinLinkCost > ulNbrLinkCost)) {
        ulMinLinkCost = ulNbrLinkCost;
        pNewParent = pNbr;
        bNewHopCount = pNbr->hop;
      }

    }

    if (pNewParent) {
      atomic {
        gpCurrentParent = pNewParent;
        gbCurrentHopCount = bNewHopCount + 1;
      }
    }
  }

  task void SendRouteTask() {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *) &routeMsg.data[0];
    //RoutePacket *pRP = (RoutePacket *)&pMHMsg->data[0];
    RoutePacket *pRP = (RoutePacket *) &routeMsg.data[0];  // fmac
    struct SortEntry sortTbl[ROUTE_TABLE_SIZE];
    //uint8_t length = offsetof(TOS_MHopMsg,data) + offsetof(RoutePacket,estList);
    uint8_t length = offsetof(RoutePacket,estList);  // fmac
    uint8_t maxEstEntries;
    uint8_t i,j;

    if (gfSendRouteBusy) {
      return;
    }

    dbg(DBG_ROUTE,"MultiHopLEPSM Sending route update msg.\n");

    maxEstEntries = TOSH_DATA_LENGTH - length;
    maxEstEntries = maxEstEntries / sizeof(RPEstEntry);

    for (i = 0,j = 0;i < ROUTE_TABLE_SIZE; i++) {
      if (NeighborTbl[i].flags & NBRFLAG_VALID) {
        sortTbl[j].id = NeighborTbl[i].id;
        sortTbl[j].receiveEst = NeighborTbl[i].receiveEst;
        j++;
      }
    }
    qsort (sortTbl,j,sizeof(struct SortEntry),sortByReceiveEstFcn);

    pRP->parent = (gpCurrentParent) ? gpCurrentParent->id : ROUTE_INVALID;
    //pRP->hop = gbCurrentHopCount;
    //pRP->cost = cost; 
    pRP->estEntries = (j > maxEstEntries) ? maxEstEntries : j;
    for (i = 0; i < pRP->estEntries; i++) {
      pRP->estList[i].id = sortTbl[i].id;
      pRP->estList[i].receiveEst = sortTbl[i].receiveEst;
      length += sizeof(RPEstEntry);
    }

    pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
    pMHMsg->hopcount = gbCurrentHopCount;
    pMHMsg->seqno = gCurrentSeqNo++;

    if (call SendMsg.send(TOS_BCAST_ADDR, length, &routeMsg) == SUCCESS) {
      gfSendRouteBusy = TRUE;
    }

  }

  task void TimerTask() {
    
    dbg(DBG_ROUTE,"MultiHopLEPSM timer task.\n");
    updateTable();

#ifndef NDEBUG
    {
      int i;
      dbg(DBG_ROUTE,"\taddr\tprnt\tmisd\trcvd\tlstS\thop\trEst\tsEst\n");
      for (i = 0;i < ROUTE_TABLE_SIZE;i++) {
        if (NeighborTbl[i].flags) {
          dbg(DBG_ROUTE,"\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n",
              NeighborTbl[i].id,
              NeighborTbl[i].parent,
              NeighborTbl[i].missed,
              NeighborTbl[i].received,
              NeighborTbl[i].lastSeqno,
              NeighborTbl[i].hop,
              NeighborTbl[i].receiveEst,
              NeighborTbl[i].sendEst);
        }
      }
      if (gpCurrentParent) {
        dbg(DBG_ROUTE,"MultiHopLEPSM: Parent = %d\n",gpCurrentParent->id);
      }
    }
#endif
    chooseParent();

    post SendRouteTask();

  }


  command result_t StdControl.init() {

    memset((void *)NeighborTbl,0,(sizeof(TableEntry) * ROUTE_TABLE_SIZE));
    BaseStation.id = TOS_UART_ADDR;
    BaseStation.parent = TOS_UART_ADDR;
    BaseStation.flags = NBRFLAG_VALID;
    BaseStation.hop = 0;
    gpCurrentParent = NULL;
    gbCurrentHopCount = ROUTE_INVALID;
    gCurrentSeqNo = 0;
    gwEstTicks = 0;
    gUpdateInterval = DATA_TO_ROUTE_RATIO * DATA_FREQ;
    gfSendRouteBusy = FALSE;
    atomic waitforinterrupt = FALSE;  //fmac  

    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDRESS) {

      gpCurrentParent = &BaseStation;
      gbCurrentHopCount = 0;

    }

    return SUCCESS;
  }

  command result_t StdControl.start() {
    post TimerTask();
    call Timer.start(TIMER_REPEAT,gUpdateInterval);
#ifdef USE_WATCHDOG
	call PoochHandler.start();
	call WDT.start(gUpdateInterval * 5);
#endif
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

  command result_t RouteSelect.selectRoute(TOS_MsgPtr Msg, uint8_t id) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

    uint8_t iNbr;
    bool fIsDuplicate;
    result_t Result = SUCCESS;


    if (gpCurrentParent == NULL) {
      // If the msg is locally generated, then send it to the broadcast address
      // This is necessary to seed the network.
      if ((pMHMsg->sourceaddr == TOS_LOCAL_ADDRESS) &&
          (pMHMsg->originaddr == TOS_LOCAL_ADDRESS)) {
        pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
        pMHMsg->hopcount = gbCurrentHopCount;
        pMHMsg->seqno = gCurrentSeqNo++;
        Msg->addr = TOS_BCAST_ADDR;
        return SUCCESS;
      }
      else {
        return FAIL;
      }
    }

    if (gbCurrentHopCount >= pMHMsg->hopcount) {
      // Possible cycle??
      return FAIL;
    }
    
    if ((pMHMsg->sourceaddr == TOS_LOCAL_ADDRESS) &&
        (pMHMsg->originaddr == TOS_LOCAL_ADDRESS)) {
      fIsDuplicate = FALSE;
    }
    else {
      fIsDuplicate = updateNbrCounters(pMHMsg->sourceaddr,pMHMsg->seqno,&iNbr);
    }

    if (!fIsDuplicate) {
      pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
      pMHMsg->hopcount = gbCurrentHopCount;
      if (gpCurrentParent->id != TOS_UART_ADDR) {
        pMHMsg->seqno = gCurrentSeqNo++;
      }
         Msg->addr = gpCurrentParent->id;
    }
    else {
      Result = FAIL;
    }

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

    Result = post TimerTask();
    return Result;
  }

  //->fmac

  task void callStartTx() {
    call RouteManagement.StartTx();
  }

  async event result_t RouteManagement.StartCSMA() {
    bool wait_interrupt;
    atomic wait_interrupt = waitforinterrupt;
    if (wait_interrupt) {
      post TimerTask();
      if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDRESS) 
        atomic waitforinterrupt = FALSE;
    } else {
      if (TOS_LOCAL_ADDRESS != BASE_STATION_ADDRESS)
        post callStartTx();
    }
    return SUCCESS;
  }
  //<-fmac

  event result_t Timer.fired() {
    if (call RouteManagement.isCSMAperiod() == SUCCESS) { //fmac
        post TimerTask();
    }
    else {                                //fmac
        atomic waitforinterrupt = TRUE;          //fmac
    }                                     //fmac
    return SUCCESS;
  }  

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
    //RoutePacket *pRP = (RoutePacket *)&pMHMsg->data[0];
    RoutePacket *pRP = (RoutePacket *)&Msg->data[0];  // fmac
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
    //    NeighborTbl[iNbr].cost = pRP->cost;

    // find out my address, extract the estimation
    for (i = 0; i < pRP->estEntries; i++) {
      if (pRP->estList[i].id == TOS_LOCAL_ADDRESS) {
        NeighborTbl[iNbr].sendEst = pRP->estList[i].receiveEst;
        NeighborTbl[iNbr].liveliness++;
      }
    }

    return Msg;
  }

  event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr Msg, void *Payload, uint16_t Len) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
    uint8_t iNbr;

    dbg(DBG_TEMP, "updateNbrCounters called HERE-3\n");
    updateNbrCounters(pMHMsg->sourceaddr,pMHMsg->seqno,&iNbr);

    return SUCCESS;
  }


  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    gfSendRouteBusy = FALSE;
    
    if (TOS_LOCAL_ADDRESS != BASE_STATION_ADDRESS) {  // fmac
        atomic waitforinterrupt = FALSE;              // fmac
        call RouteManagement.StartTx();               // fmac
    }                                                 // fmac

    return SUCCESS;
  }

}

