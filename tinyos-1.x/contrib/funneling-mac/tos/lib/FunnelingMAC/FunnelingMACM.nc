/* Copyright (c) 2007 Dartmouth SensorLab.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * paragraph and the author appear in all copies of this software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/* The funneling-MAC code.
 *
 * Authors: Gahng-Seop Ahn   <ahngang@ee.columbia.edu>,
 *          Emiliano Miluzzo <miluzzo@cs.dartmouth.edu>.
 */

includes AM;
includes FunnelingMAC;

module FunnelingMACM {
  provides {
    interface StdControl;
    interface SendMsg[uint8_t id];
    interface RouteManagement;
    interface SnoopFmac;
    interface Query;
  }
  uses {
    interface ReceiveMsg[uint8_t id];
    interface SendMsg as SendMsgD[uint8_t id];
    interface SendMsg as SendMsgB;
    interface SendMsg as SendMsgS;
    interface SendMsg as SendMsgQ;
    interface StdControl as SubControl;
    interface StdControl as CommStdControl;
    interface CommControl;
    interface CC1000Control;
    interface Leds;
    interface Timer as TimerBeacon;
    interface Timer as BeaconTimeOut;
    interface Timer as ScheduleTimeOut;
    interface Timer as TimerCSMA;
    interface Timer as TimerCSMAduration;
    interface Timer as TimerCSMArepetitions;
    interface Timer as TimerCSMAsnooped;
    interface Timer as TimerTDMA;
    interface Timer as TimerTDMAduration;
    interface Timer as TimerTDMAremaining;
    interface Timer as VirtualSuperframeRemaining;
    interface Timer as TimerSuperframe;
    interface Timer as TimerWaitForCSMA;
    interface Timer as TimerPattern;
    interface Timer as TimerMargin;
    interface Timer as TimerRandomM;
  }
}

implementation {

  enum {
    FWD_QUEUE_SIZE = 25, // Should be bigger than the router queue size
    EMPTY = 0xff,
    BASE_STATION_ADDR = 0,
    POWER_LEVEL_NODE = 15,
    POWER_LEVEL_SINK = 15,
    NO_POWER_LEVEL = 16,
    PACKET_TIME = 30,
    SUPERFRAME_DURATION = 9200,
    SUPERFRAME_MARGIN = 10,
    CONSTANT = 2,
    CONSTANT1 = 30,
    BEACON_TIMEOUT = 350,
    SCHEDULE_TIMEOUT = 150
  };

  TOS_Msg gMsgBuffer; // Packet buffer for beacon & schedule

  /* Internal storage and scheduling state */
  TOS_Msg *FwdBufList[FWD_QUEUE_SIZE];
  uint8_t FwdBufId[FWD_QUEUE_SIZE];
  uint8_t FwdBufLength[FWD_QUEUE_SIZE];
  uint8_t iFwdBufHead, iFwdBufTail, occupancy;

  int timer_rate, timer_ticks;

  /* Funneling-MAC state */

  bool enableFunnelingMAC; // if FALSE, it's equivalent to BMAC
  bool gfSendBusy;
  bool gGetPacketBusy;
  bool isCSMA, isTDMA;
  bool dontsendschedule, scheduleTosend;
  bool notschedule;
  bool needScheduleAgain;
  bool decrement_power;
  bool ImInsideFarea;
  bool scheduleGot;
  bool ImFirstofSchedule;
  bool txforbidden;
  bool snooped;
  bool missedSchedule;
  bool newSchedule;
  bool ImHead;
  bool ImSource;
  bool alreadyscheduled;
  bool IwasFirstofSchedule;
  bool alreadyfirst;
  bool isIncomingBroadcast;
  bool scheduleNotgood;
  bool dataToforward;
  bool dataTosend;
  bool gfShowSchedule;
  bool queryTosend;

  uint8_t pointer;
  uint8_t slotsTotdmaend;
  uint8_t cntpatternsink;
  uint8_t cntpattern;
  uint8_t cntcsmarep;
  uint8_t TimeSlot;
  uint8_t overalltdmaslots;
  uint8_t totalbranches;
  uint8_t positNodeArray;
  uint8_t position;
  uint8_t branchesscheduled;
  uint8_t beacon_power_level;
  uint8_t RegNodeTab_Head, RegNodeTab_Tail;
  uint8_t rept;
  uint8_t branchesIhave;
  uint8_t internaltableindex;
  uint8_t Qseqno;
  uint8_t queryRepeat;

  uint16_t prevparentaddr;
  uint16_t timer_margin, beaconcnt, singleTDMAslotdur, slotcounter_new;
  uint16_t superframedur, CSMAdur, TDMARate, csmadur, noTDMASlot, slotsrem;
  uint16_t csmad, csmar, tdmar, tdmaduration, slotcounter, slotcounter_new;
  uint16_t minCSMAdur, maxTDMArate, data_interval;


  uint8_t array_sched[NO_BRANCHES_SCH];
  uint8_t beacon_power[NO_POWER_LEVEL];

  RegisteredNodes Reg_Nodes;
  NodeTable Internal_Table;
  
  /***********************************************************************
   * Initialization 
   ***********************************************************************/

  static void initialize() {
    uint8_t cnt1;

    iFwdBufHead = iFwdBufTail = 0;

    enableFunnelingMAC = TRUE;
    gfSendBusy = FALSE;
    gGetPacketBusy = FALSE;
    isCSMA = TRUE;
    isTDMA = FALSE;
    dontsendschedule = FALSE;
    scheduleTosend = FALSE;
    notschedule = FALSE;
    needScheduleAgain = FALSE;
    decrement_power = FALSE;
    ImInsideFarea = FALSE;
    scheduleGot = FALSE;
    ImFirstofSchedule = FALSE;
    txforbidden = FALSE;
    snooped = FALSE;
    missedSchedule= FALSE;
    newSchedule=FALSE;
    ImHead=FALSE;
    ImSource=FALSE;
    alreadyscheduled=FALSE;
    IwasFirstofSchedule=FALSE;
    alreadyfirst = FALSE;
    isIncomingBroadcast = FALSE;
    scheduleNotgood = FALSE;
    dataToforward = FALSE;
    dataTosend = FALSE;
    gfShowSchedule = FALSE;
    queryTosend = TRUE;

    pointer = 0;
    slotsTotdmaend = 0;
    cntpatternsink = 0;
    cntpattern = 0;
    cntcsmarep = 1;
    TimeSlot = PACKET_TIME;
    overalltdmaslots = 0;
    totalbranches = 0;
    positNodeArray = 0;
    position = 0;
    branchesscheduled = 0;
    beacon_power_level = 0;
    RegNodeTab_Head = 0;
    RegNodeTab_Tail = 0;
    rept = 0;
    branchesIhave = 0;
    internaltableindex = 0;
    Qseqno = 0;

    prevparentaddr = 0xffff;
    timer_margin = 1.5 * SUPERFRAME_MARGIN;
    beaconcnt = 0;
    singleTDMAslotdur = 0;
    slotcounter_new = 0;
    superframedur = 0;
    CSMAdur = 0;
    TDMARate = 1;
    csmadur = 0;
    noTDMASlot = 0;
    slotsrem = 0;
    csmad = 0;
    csmar = 0;
    tdmar = 0;
    tdmaduration = 0;
    slotcounter = 0;
    slotcounter_new = 0;
    minCSMAdur = 300;
    maxTDMArate = 1120;
    data_interval = 1000;

    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDR) {
      for (cnt1=0; cnt1<NO_BRANCHES_SCH; cnt1++) {
        Reg_Nodes.ActiveBranches[cnt1] = 0;
        Reg_Nodes.traffic_src[cnt1] = 0;
        Reg_Nodes.branches[cnt1].branch = 0;
      }
      beacon_power[0] = 2;
      beacon_power[1] = 4;
      beacon_power[2] = 6;
      beacon_power[3] = 9;
      beacon_power[4] = 12;
      beacon_power[5] = 15;
      beacon_power[6] = 64;
      beacon_power[7] = 80;
      beacon_power[8] = 96;
      beacon_power[9] = 112;
      beacon_power[10] = 128;
      beacon_power[11] = 144;
      beacon_power[12] = 176;
      beacon_power[13] = 192;
      beacon_power[14] = 240;
      beacon_power[15] = 255;
      for (cnt1=0; cnt1<NO_POWER_LEVEL; cnt1++) {
        if (beacon_power[beacon_power_level] < POWER_LEVEL_NODE) {
          beacon_power_level++;
        }
      }
    } else {
      timer_rate = 0;
      for (cnt1=0; cnt1<NO_BRANCHES_SCH; cnt1++) {
        Internal_Table.mybranch[cnt1].Headaddr = 0;
        Internal_Table.mybranch[cnt1].hops = 0;
        Internal_Table.mybranch[cnt1].OriginAddr = 0;
        Internal_Table.mybranch[cnt1].isScheduled = FALSE;
        Internal_Table.mybranch[cnt1].isBranchHead = FALSE;
        Internal_Table.NoSlot[cnt1].slots = 0;
        Internal_Table.NoSlot[cnt1].ifSrc = FALSE;
      }
      Internal_Table.ImEnode = FALSE;
    }

  }

  command result_t StdControl.init() {
    initialize();
    call CommStdControl.init();
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    call CommStdControl.start();
    call SubControl.start();
    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDR) {
      call CC1000Control.SetRFPower(POWER_LEVEL_SINK);
      if (enableFunnelingMAC) 
        call TimerBeacon.start(TIMER_REPEAT, SUPERFRAME_DURATION);
    }
    else call CC1000Control.SetRFPower(POWER_LEVEL_NODE);
    return call CommControl.setPromiscuous(TRUE);
  }

  command result_t StdControl.stop() {
    call TimerBeacon.stop();
    call SubControl.stop();
    return call CommStdControl.stop();
  }

  /***********************************************************************
   * Static functions
   ***********************************************************************/

  static result_t Store(TOS_MsgPtr pMsg, uint8_t id, uint8_t length) {
    if (((iFwdBufHead + 1) % FWD_QUEUE_SIZE) == iFwdBufTail) {
      // the buffer is full
      return FAIL;
    }
    FwdBufList[iFwdBufHead] = pMsg;
    FwdBufId[iFwdBufHead] = id;
    FwdBufLength[iFwdBufHead] = length;
    iFwdBufHead++;
    iFwdBufHead %= FWD_QUEUE_SIZE;
    occupancy++;      
    return SUCCESS;
  }

  static uint8_t noAllocatedSlots() {
    uint8_t no_slots = 0;
    if (scheduleGot && TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
      if (ImFirstofSchedule || IwasFirstofSchedule) no_slots = pointer + 1;
      else no_slots = pointer;
    }
    return no_slots;
  }

  static uint8_t ReturnSlots() {
    if (slotsTotdmaend < 100)
      return (uint8_t)slotsTotdmaend;
    else return 0;
  }

  static uint8_t ReturnCSMArep() {
    uint8_t var = 0;
    if (noTDMASlot != 0) {
      if ((superframedur/noTDMASlot) > 1) {
        var = (uint8_t) (superframedur/noTDMASlot);
        return (var - cntpattern + 1);
      } else return 0;
    } else return 0;
  }

  static result_t getIfBranchHead() {
    uint8_t z, cnt = 0;
    for (z=0;z<NO_BRANCHES_SCH;z++) {
      if (Internal_Table.mybranch[z].isBranchHead == TRUE) cnt++;
    }
    if (cnt > 0) return SUCCESS;
    else return FAIL;
  }

  /***********************************************************************
   * Tasks
   ***********************************************************************/

  task void SendBeacon() {
    BeaconMsg *pBeacon;
    cntpatternsink = 0;
    beaconcnt++;

    if ((needScheduleAgain == TRUE && scheduleTosend == FALSE) || !dontsendschedule) atomic scheduleTosend = TRUE;
    if (scheduleTosend) {
      singleTDMAslotdur = (PACKET_TIME*slotcounter_new);
    }

    pBeacon = (BeaconMsg *)gMsgBuffer.data;

    if (pBeacon) {
      if (TDMARate < (SUPERFRAME_DURATION - 60))
        superframedur = SUPERFRAME_DURATION - 60;
      else {
        superframedur = singleTDMAslotdur;
        call TimerBeacon.stop();
        call TimerBeacon.start(TIMER_REPEAT, superframedur + 60);
      }
      pBeacon->superframe_dur = superframedur;
      if (dontsendschedule) {
        pBeacon->csma_dur = superframedur;
        pBeacon->morebroadcast_pck = 1; // no Schedule && no TDMA
      }
      else {
        pBeacon->csma_dur = CSMAdur;
        pBeacon->tdma_dur = singleTDMAslotdur;
        pBeacon->tdmarate = TDMARate;
        pBeacon->notdmaslots = slotcounter_new;
        if (scheduleTosend) 
          pBeacon->morebroadcast_pck = 3; // Schedule will be followed
        else pBeacon->morebroadcast_pck = 0; // no Schedule will be followed
      }
      if ((call SendMsgB.send(TOS_BCAST_ADDR,sizeof(BeaconMsg),&gMsgBuffer)) != SUCCESS) atomic gfSendBusy = FALSE;
    }
    else atomic gfSendBusy = FALSE; 
  }

  task void SendSchedule() {
    ScheduleMsg *pSchedule;
    uint8_t i, schedpos;

    if (!notschedule) {
      pSchedule = (ScheduleMsg *)gMsgBuffer.data;
      if (pSchedule) {
        if (!decrement_power) {
          for (i=0; i<NO_BRANCHES_SCH; i++) {
            (uint8_t)pSchedule->schedule[i].headbranch_addr = (uint8_t)Reg_Nodes.branches[i].branch;
            pSchedule->schedule[i].no_slots = array_sched[i];
          }
        } 
        else {
          schedpos = 0;
          for (i=0; i<NO_BRANCHES_SCH; i++) {
            pSchedule->schedule[schedpos].headbranch_addr = (uint8_t)Reg_Nodes.branches[i].branch;
            pSchedule->schedule[schedpos].no_slots = Reg_Nodes.branches[i].hoptraveled;
            if (schedpos < (NO_BRANCHES_SCH - 1)) schedpos++;
          }
        }
        if (call SendMsgS.send(TOS_BCAST_ADDR,sizeof(ScheduleMsg),&gMsgBuffer) != SUCCESS) atomic gfSendBusy = FALSE;
      }
      else atomic gfSendBusy = FALSE;
    }
    else atomic gfSendBusy = FALSE;
  }

  task void GetPacket() {
    TOS_MsgPtr      pMsg = (TOS_MsgPtr)FwdBufList[iFwdBufTail];
    TOS_MHopMsg     *pMHMsg = (TOS_MHopMsg *)pMsg->data;
    uint8_t         id = FwdBufId[iFwdBufTail];
    uint8_t         length = FwdBufLength[iFwdBufTail];
    uint8_t         i;

    gGetPacketBusy = TRUE;

    if (occupancy > 0 && txforbidden == FALSE) {
      // put meta-schedule to the packets that is scheduled.

      if (TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
        if (scheduleGot && isTDMA) {
          dbg(DBG_USR3, "GetPacket: src=%i dst=%i hop=%i occu=%i slot=%i ctrl=%i reg=%i TDMA\n", pMHMsg->originaddr, pMsg->addr, pMHMsg->hoptraveled, occupancy, noAllocatedSlots(), pMHMsg->control, pMHMsg->path_head);
        } else {
          dbg(DBG_USR3, "GetPacket: src=%i dst=%i hop=%i occu=%i slot=%i ctrl=%i reg=%i CSMA\n", pMHMsg->originaddr, pMsg->addr, pMHMsg->hoptraveled, occupancy, noAllocatedSlots(), pMHMsg->control, pMHMsg->path_head);
        }
      }

      if (TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
        if (getIfBranchHead() || (pMHMsg->originaddr == TOS_LOCAL_ADDRESS)) {
          if (prevparentaddr == pMsg->addr && scheduleGot && isTDMA) {
            pMHMsg->control = pMHMsg->control | 128;
            pMHMsg->meta_schedule[0] = ReturnSlots();
            pMHMsg->meta_schedule[1] = (uint8_t)noTDMASlot/CONSTANT1;
            pMHMsg->meta_schedule[2] = (uint8_t)csmadur/CONSTANT;
            pMHMsg->meta_schedule[3] = ReturnCSMArep();
          }
          else {
            pMHMsg->control = pMHMsg->control & 4;
            pMHMsg->hoptraveled = 1;
            for (i=0; i<4; i++) {
              pMHMsg->meta_schedule[i] = 0;
            }
          }
        }
        else if ((pMHMsg->control & 128) == 128) {
          if (scheduleGot && isTDMA) {
            pMHMsg->meta_schedule[0] = ReturnSlots();
            pMHMsg->meta_schedule[1] = (uint8_t)noTDMASlot/CONSTANT1;
            pMHMsg->meta_schedule[2] = (uint8_t)csmadur/CONSTANT;
            pMHMsg->meta_schedule[3] = ReturnCSMArep();
          }
          else {
            for (i=0; i<4; i++) {
              pMHMsg->meta_schedule[i] = 0;
            }
          }
        }
      }

      dbg(DBG_USR3, "GetPacket2: ctrl=%i head:%i meta:%i %i %i %i\n", pMHMsg->control, pMHMsg->path_head, pMHMsg->meta_schedule[0], pMHMsg->meta_schedule[1], pMHMsg->meta_schedule[2], pMHMsg->meta_schedule[3]);

      if (call SendMsgD.send[id](pMsg->addr, length, pMsg) == FAIL) {
        gGetPacketBusy = FALSE;
      }
    }
    else gGetPacketBusy = FALSE;
    //gGetPacketBusy = FALSE;  // testing
  }

  task void StartTransmission() {
    dbg(DBG_USR3, "StartTx: occu=%i slot=%i busy=%x TDMA%x CSMA%x\n", occupancy, noAllocatedSlots(), gGetPacketBusy, isTDMA, isCSMA);
    if (occupancy > 0 && !gGetPacketBusy) {
      if (isTDMA) {
        post GetPacket();
      }
      else if (isCSMA) {
        if (ImInsideFarea && scheduleGot) {
          if (occupancy > noAllocatedSlots())
            post GetPacket();
        }
        else post GetPacket();
      }
    }
  }

  static void RegisterNode(TOS_MsgPtr msg) {
    TOS_MHopMsg         *pMHMsg = (TOS_MHopMsg *)msg->data;
    uint8_t j,m;
    uint8_t no_active_branches = 0;
    uint8_t no_diff = 0;
    bool isSame_path = FALSE;
    bool replace = FALSE;
    uint8_t r_index = 0;

    dbg(DBG_USR3, "Register: ori=%i hop=%i ctrl=%i head=%i meta=%i %i %i %i\n", pMHMsg->originaddr, pMHMsg->hoptraveled, pMHMsg->control, pMHMsg->path_head, pMHMsg->meta_schedule[0], pMHMsg->meta_schedule[1], pMHMsg->meta_schedule[2], pMHMsg->meta_schedule[3]);

    if (pMHMsg->path_head == 0) return;

    if (no_active_branches <= NO_BRANCHES_SCH) {
      if (pMHMsg->hoptraveled != 0) {
        for (j=0; j<NO_BRANCHES_SCH; j++) {
          if (Reg_Nodes.ActiveBranches[j] != 0) no_active_branches++;
        }
        if (no_active_branches == 0) {
          Reg_Nodes.ActiveBranches[0] = 1;
          Reg_Nodes.traffic_src[0] = pMHMsg->originaddr;
          Reg_Nodes.branches[0].branch = pMHMsg->path_head;
          Reg_Nodes.branches[0].hoptraveled = pMHMsg->hoptraveled;
          no_active_branches++;
          RegNodeTab_Head++;
        } else {
          for (m=0; m<no_active_branches; m++) {
            if (pMHMsg-> originaddr == Reg_Nodes.traffic_src[m]
                && pMHMsg->path_head == Reg_Nodes.branches[m].branch 
                && pMHMsg->hoptraveled == Reg_Nodes.branches[m].hoptraveled) {
              isSame_path = TRUE;
              dbg(DBG_USR3, "Register: same path\n");
            } else {
              no_diff++;
              dbg(DBG_USR3, "Register: diff ori=%i reg_src=%i hop=%i reg_hop=%i\n", pMHMsg->originaddr, Reg_Nodes.branches[m].branch, pMHMsg->hoptraveled, Reg_Nodes.branches[m].hoptraveled);
              if (pMHMsg->originaddr == Reg_Nodes.traffic_src[m]) {
                replace = TRUE;
                r_index = m;
              }
            } 
          }
          if (no_diff != 0 && isSame_path == FALSE) {
            if (replace) {
              Reg_Nodes.branches[r_index].branch = pMHMsg->path_head;
              Reg_Nodes.branches[r_index].hoptraveled = pMHMsg->hoptraveled;
              needScheduleAgain = TRUE; 
            } else {
              if (((RegNodeTab_Head + 1) % (NO_BRANCHES_SCH+1)) == RegNodeTab_Tail) {
                RegNodeTab_Head = RegNodeTab_Tail;
                RegNodeTab_Tail++;
                RegNodeTab_Tail %= NO_BRANCHES_SCH;
              }
              Reg_Nodes.ActiveBranches[RegNodeTab_Head] = 1;
              Reg_Nodes.traffic_src[RegNodeTab_Head] = pMHMsg->originaddr;
              Reg_Nodes.branches[RegNodeTab_Head].branch = pMHMsg->path_head;
              Reg_Nodes.branches[RegNodeTab_Head].hoptraveled = pMHMsg->hoptraveled;
              needScheduleAgain = TRUE;
              RegNodeTab_Head++;
              RegNodeTab_Head %= NO_BRANCHES_SCH;
            }
          }
        }
      }
    }
  }

  task void DecideSchedule() {
    uint8_t a,b,c,cnt,trace = 0;
    uint8_t power = 0;
    uint8_t maxslotsno = 0;
    uint8_t array[NO_BRANCHES_SCH];

    decrement_power = FALSE;
    slotcounter = 0;
    slotcounter_new = 0;
    rept = 0;

    for (a=0; a<NO_BRANCHES_SCH; a++) {
      array[a] = 0;
      array_sched[a] = 0;
      cnt = 0;
      slotcounter = Reg_Nodes.branches[a].hoptraveled;
      cnt = slotcounter;
      array[a] = cnt;
      if (cnt > maxslotsno) {
        maxslotsno = cnt;
        trace = a;
      }
    }
    for (c=0; c<NO_BRANCHES_SCH-1; c++) {
      if ((array[c] > 3) || (array[c+1] > 3)) {
        if ((array[c] - array[c+1]) < 2) {
          if ((array[c] - array[c+1]) == 1) array_sched[c] = 4;
          else if ((array[c] - array[c+1]) == -2) array_sched[c] = 1;
          else if ((array[c] - array[c+1]) == -1) array_sched[c] = 2;
          else if ((array[c] - array[c+1]) == 0) array_sched[c] = 3;
          else if ((array[c] - array[c+1]) < -2) array_sched[c] = 1;
        } else {
          if ((array[c] - array[c+1]) == 2) {
            if (array[c] == 4) array_sched[c] = 4;
            else array_sched[c] = 5;
          } else array_sched[c] = 1;
        }
      } else array_sched[c] = array[c];
    }
    array_sched[NO_BRANCHES_SCH-1] = array[NO_BRANCHES_SCH-1];
    for (b=0; b<NO_BRANCHES_SCH; b++) {
      slotcounter_new = slotcounter_new + array_sched[b];
    }
    if (slotcounter_new == 0) dontsendschedule = TRUE;
    else dontsendschedule = FALSE;
    if (!dontsendschedule) {
      if (((slotcounter_new * PACKET_TIME) + minCSMAdur) < maxTDMArate) {
        rept = (maxTDMArate-minCSMAdur) / (slotcounter_new * PACKET_TIME);
        if (rept > 5) rept = 5;
        TDMARate = maxTDMArate / rept;
        CSMAdur = TDMARate - (slotcounter_new * PACKET_TIME);
      } else {
        TDMARate = (slotcounter_new * PACKET_TIME) + minCSMAdur;
        a = (TDMARate / maxTDMArate) + 1; 
        TDMARate = a * maxTDMArate;
        CSMAdur = TDMARate - (slotcounter_new * PACKET_TIME);
      }
      if ((slotcounter_new * PACKET_TIME) < data_interval) {
        if (beacon_power_level < NO_POWER_LEVEL - 1) beacon_power_level++;
      } else {
        if (beacon_power[beacon_power_level] > POWER_LEVEL_NODE) beacon_power_level--;
      }
      power = beacon_power[beacon_power_level];
      call CC1000Control.SetRFPower(power);
    } else CSMAdur = SUPERFRAME_DURATION;
  }

  task void TDMAPhase() {
    uint16_t waitbeforetx = 0;

    if (position < positNodeArray) {
      slotsTotdmaend = 0;
      if (ImFirstofSchedule) { //I send or forward immediately
        slotsTotdmaend = overalltdmaslots - 1;
        post StartTransmission();
        if (branchesscheduled > 0) {
          waitbeforetx = TimeSlot * (Internal_Table.NoSlot[0].slots + 1);
          call TimerTDMA.start(TIMER_ONE_SHOT,waitbeforetx);
          ImFirstofSchedule = FALSE;
          IwasFirstofSchedule = TRUE;
        }
        dbg(DBG_USR3, "TDMAPhase ImFirst position=%i array=%i waitTX=%i br_sched=%i\n", position, positNodeArray, waitbeforetx, branchesscheduled);
      }
      else {
        if (IwasFirstofSchedule) {
          slotsTotdmaend = Internal_Table.NoSlot[position].slotsTotdmaExpires;
          post StartTransmission();
          position++;
          if (Internal_Table.NoSlot[position].slots != 0) {
            waitbeforetx = TimeSlot * (Internal_Table.NoSlot[position].slots + 1);
            call TimerTDMA.start(TIMER_ONE_SHOT,waitbeforetx);
          } else {
            position = 0;
            ImFirstofSchedule = TRUE;
            IwasFirstofSchedule = FALSE;
          }
          dbg(DBG_USR3, "TDMAPhase IwasFirst position=%i array=%i waitTX=%i slots=%i\n", position, positNodeArray, waitbeforetx, Internal_Table.NoSlot[position].slots);
        }
        else {
          slotsTotdmaend = Internal_Table.NoSlot[position].slotsTotdmaExpires;
          if (Internal_Table.mybranch[position].isBranchHead) {
            dataToforward = TRUE;
          }
          if (Internal_Table.NoSlot[position].ifSrc) {
            dataTosend = TRUE;
          }
          if (!Internal_Table.mybranch[position].isBranchHead && !Internal_Table.NoSlot[position].ifSrc) {
            dataToforward = TRUE;
          }
          if (position == 0) {
            waitbeforetx = TimeSlot * (Internal_Table.NoSlot[position].slots);
          } else {
            waitbeforetx = TimeSlot * (Internal_Table.NoSlot[position].slots + 1);
          }
          call TimerTDMA.start(TIMER_ONE_SHOT,waitbeforetx);
          dbg(DBG_USR3, "TDMAPhase else position=%i waitTX=%i\n", position, waitbeforetx);
          position++;
        }
      }
    } else {
      dbg(DBG_USR3, "TDMAPhase position > array position=%i waitTX=%i\n", position, waitbeforetx);
      position = 0;
    }
  }

  /***********************************************************************
   * Commands
   ***********************************************************************/

  command result_t SendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)msg->data;
    uint8_t i, j, matches, matching;
    bool result;

    if (!enableFunnelingMAC) { // FunnelingMAC is disabled.
      if (TOS_LOCAL_ADDRESS == 0) {
      }
      return call SendMsgD.send[id](address, length, msg);
    }

    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDR) { // sink
      if (pMHMsg->control == 5 || pMHMsg->control == 6 ||
          pMHMsg->control == 133 || pMHMsg->control == 134) {
        atomic needScheduleAgain = TRUE;
      }
      RegisterNode(msg);
      result = Store(msg, id, length);
      if (gGetPacketBusy == FALSE) post GetPacket(); // send to UART
      return result;
    }

    if (pMHMsg->originaddr == TOS_LOCAL_ADDRESS) pMHMsg->hoptraveled = 0;
    pMHMsg->hoptraveled++;

    if (pMHMsg->originaddr == TOS_LOCAL_ADDRESS) {
      pMHMsg->hoptraveled = 1;
      pMHMsg->path_head = 0;
      for (i=0;i<4;i++) {
        pMHMsg->meta_schedule[i] = 0;
      }
      pMHMsg->control = 0;
      if (ImInsideFarea) {
        if (missedSchedule) pMHMsg->control = 1;
        if (newSchedule) pMHMsg->control = pMHMsg->control | 2;
        pMHMsg->control = pMHMsg->control | 4;
        pMHMsg->path_head = TOS_LOCAL_ADDRESS;
        if (prevparentaddr != msg->addr) {
          pMHMsg->control = pMHMsg->control & 4;
        }
      }
    } else if (ImInsideFarea) {
      matches = 0;
      if ((pMHMsg->control & 4) != 4) Internal_Table.ImEnode = TRUE;
      if ((pMHMsg->control & 128) == 0) {
        if (branchesIhave == 0) {
          Internal_Table.mybranch[internaltableindex].OriginAddr = pMHMsg->originaddr;
          if (pMHMsg->path_head == 0) {
            Internal_Table.mybranch[internaltableindex].Headaddr = TOS_LOCAL_ADDRESS;
          } else {
              Internal_Table.mybranch[internaltableindex].Headaddr = pMHMsg->path_head;
              Internal_Table.mybranch[internaltableindex].hops = pMHMsg->hoptraveled;
          }
          branchesIhave++;
          internaltableindex++;
        } else {
          if ((pMHMsg->control & 8) != 8) {
            for (j=0; j<NO_BRANCHES_SCH; j++) {
              if (Internal_Table.mybranch[j].Headaddr != 0) {
                if (Internal_Table.mybranch[j].Headaddr == pMHMsg->path_head || Internal_Table.mybranch[j].Headaddr == TOS_LOCAL_ADDRESS) {
                  if (Internal_Table.mybranch[j].OriginAddr == pMHMsg->originaddr) {
                    matches++;
                  }
                }
              }
            }
          } else {
            matching = 0;
            for (j=0; j<NO_BRANCHES_SCH; j++)
              if (Internal_Table.mybranch[j].OriginAddr == pMHMsg->originaddr)
                matching++;
            if (matching == 0) matches = 0;
            else matches++;
          }
          if (matches == 0) {
            if (pMHMsg->path_head == 0) {
              Internal_Table.mybranch[internaltableindex].Headaddr = TOS_LOCAL_ADDRESS;
            } else {
              Internal_Table.mybranch[internaltableindex].Headaddr = pMHMsg->path_head;
              Internal_Table.mybranch[internaltableindex].hops = pMHMsg->hoptraveled;
            }
            Internal_Table.mybranch[internaltableindex].OriginAddr = pMHMsg->originaddr;
            if ((branchesIhave + 1) < NO_BRANCHES_SCH) {
              branchesIhave++;
            }
            if ((internaltableindex + 1) < NO_BRANCHES_SCH) {
              internaltableindex++;
            } else internaltableindex = 0;
          }
        }
        totalbranches = branchesIhave;
      }
      if ((pMHMsg->control & 128) == 0) {
        dbg(DBG_USR3, "SendMsg: ctrl=%i flag4=%i\n", pMHMsg->control, (pMHMsg->control & 4));
        if ((pMHMsg->control & 4) == 0) {
          for (i=0; i<4; i++) {
            pMHMsg->meta_schedule[i] = 0;
          }
          pMHMsg->control = pMHMsg->control | 4;
          pMHMsg->hoptraveled = 1;
          pMHMsg->path_head = TOS_LOCAL_ADDRESS;
        }
      }
    }
    
    prevparentaddr = msg->addr;
    result = Store(msg, id, length);
    if (isCSMA && !isTDMA) post StartTransmission();
    return result;
  } 

  command void SnoopFmac.snoop(TOS_MsgPtr msg) {
    TOS_MHopMsg         *pMHMsg = (TOS_MHopMsg *)msg->data;

    if (!enableFunnelingMAC) return;

    if (!ImInsideFarea && TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
      if (!snooped && ((pMHMsg->control & 128) == 128) && (pMHMsg->meta_schedule[1] != 0) && (pMHMsg->meta_schedule[2] != 0)) {
        call VirtualSuperframeRemaining.stop();
        cntcsmarep = 1;
        slotsrem = (pMHMsg->meta_schedule[0]) * TimeSlot;
        if (pMHMsg->meta_schedule[1] > 0)
          tdmar = pMHMsg->meta_schedule[1] * CONSTANT1;
        else
          tdmar = 80;
        if (pMHMsg->meta_schedule[2] > 0)
          csmad = (pMHMsg->meta_schedule[2]) * CONSTANT;
        else
          csmad = 60;
        csmar = (pMHMsg->meta_schedule[3]);
        if (csmar > 0 && slotsrem < 7500) {
          atomic snooped = TRUE;
          atomic isCSMA = FALSE;
          call TimerTDMAremaining.start(TIMER_ONE_SHOT,(slotsrem + 0.5*TimeSlot));
        }
        if (csmar == 0 && tdmar > 9000) {
          atomic snooped = TRUE;
          atomic isCSMA = FALSE;
          call TimerTDMAremaining.start(TIMER_ONE_SHOT,(slotsrem + 0.5*TimeSlot));
        }
      }
    }
    return;
  }

  command result_t RouteManagement.isCSMAperiod() {
    if (isCSMA) return SUCCESS;
    else return FAIL;
  }

  command result_t RouteManagement.StartTx() {
    dbg(DBG_USR3, "fmac: RouteManagement.StartTx\n");
    if (isCSMA) post StartTransmission();
    return SUCCESS;
  }

  command result_t Query.StartSendQuery(bool sendQuery, uint16_t rate) {
    QueryMsg *pQuery;
    queryTosend = sendQuery;
    if (sendQuery && !gfSendBusy) {
      data_interval = rate;
      pQuery = (QueryMsg *)gMsgBuffer.data;
      if (pQuery) {
        Qseqno++;
        pQuery->rate = rate;
        pQuery->seqno = Qseqno;
        queryRepeat = 0;
        call CC1000Control.SetRFPower(255);
        dbg(DBG_USR3, "fmac: StartSendQuery\n");
        if ((call SendMsgQ.send(TOS_BCAST_ADDR,sizeof(QueryMsg),&gMsgBuffer)) == SUCCESS) atomic gfSendBusy = TRUE;
      }
    }
    return SUCCESS;
  }

  /***********************************************************************
   * Timer events
   ***********************************************************************/

  event result_t TimerBeacon.fired() {
    atomic notschedule = FALSE;
    post DecideSchedule();

    atomic {
      if (!gfSendBusy && !queryTosend) {
        gfSendBusy = TRUE;
        post SendBeacon();
      }
    }
    return SUCCESS;
  }

  event result_t BeaconTimeOut.fired() {
    isCSMA = TRUE;
    signal RouteManagement.StartCSMA();
    txforbidden = FALSE;
    return SUCCESS;
  }

  event result_t ScheduleTimeOut.fired() {
    missedSchedule = TRUE;
    newSchedule = FALSE;
    scheduleGot = FALSE;
    isCSMA = TRUE;
    signal RouteManagement.StartCSMA();
    return SUCCESS;
  }

  event result_t TimerCSMA.fired() {
    isCSMA = FALSE;
    return SUCCESS;
  }

  event result_t TimerCSMAduration.fired() {
    isCSMA = FALSE;
    cntpatternsink++;
    if (cntpatternsink <= ((superframedur-5*PACKET_TIME)/TDMARate))
      call TimerWaitForCSMA.start(TIMER_ONE_SHOT,(timer_margin + 10 + singleTDMAslotdur));
    return SUCCESS;
  }

  event result_t TimerCSMArepetitions.fired() {
    if (cntcsmarep < (csmar-1)) {    
      isCSMA = TRUE;
      txforbidden = FALSE;
      cntcsmarep++;
      call TimerCSMAsnooped.start(TIMER_ONE_SHOT,csmad);
      signal RouteManagement.StartCSMA();
    } else {
      isCSMA = FALSE;
      snooped = FALSE;   
      call VirtualSuperframeRemaining.stop(); 
      call VirtualSuperframeRemaining.start(TIMER_ONE_SHOT,(csmad+BEACON_TIMEOUT+100));
      call TimerCSMArepetitions.stop();
      }
          return SUCCESS;
  }

  event result_t TimerCSMAsnooped.fired() {
    isCSMA = FALSE;
    snooped = FALSE;
    if (tdmar > 9000) {
      call VirtualSuperframeRemaining.stop();
      call VirtualSuperframeRemaining.start(TIMER_ONE_SHOT,(3100+BEACON_TIMEOUT));
    }
    return SUCCESS;
  }

  event result_t TimerTDMA.fired() {
    dbg(DBG_USR3, "TimerTDMA.fired: IwasFirst=%x dataTosend=%x dataToforward=%x isTDMA=%x\n", IwasFirstofSchedule, dataTosend, dataToforward, isTDMA);
    if (IwasFirstofSchedule) {
      post TDMAPhase();
    } else {
      if (dataTosend) {
        post StartTransmission();
        dataTosend = FALSE;
      }
      if (dataToforward) {
        post StartTransmission();
        atomic dataToforward = FALSE;
      }
      if (isTDMA) post TDMAPhase();
    }
    return SUCCESS;
  }

  event result_t TimerTDMAduration.fired() {
    if (noTDMASlot!=0) {
      if ((superframedur/noTDMASlot) == 1 && cntpattern == 2) {
        isTDMA = FALSE;
        isCSMA = FALSE;
        dbg(DBG_USR3, "TimerTDMAduration.fired sfr=%i slot=%i pat=%i\n", superframedur, noTDMASlot, cntpattern);
        call TimerPattern.stop();
      } else {
        isTDMA = FALSE;
        isCSMA = TRUE;
        call TimerCSMA.start(TIMER_ONE_SHOT,csmadur);
        signal RouteManagement.StartCSMA();
      }
    } else {
      isTDMA = FALSE;
      isCSMA = TRUE;
      signal RouteManagement.StartCSMA();
    }
//    if (TOS_LOCAL_ADDRESS == 1)
      dbg(DBG_USR3, "TimerTDMAduration.fired csmadur=%i TDMA%x CSMA%x\n", csmadur, isTDMA, isCSMA);
    return SUCCESS;
  }

  event result_t TimerTDMAremaining.fired() {
    txforbidden = FALSE;
    if (tdmar < 9000) {
      call TimerCSMArepetitions.start(TIMER_REPEAT,tdmar-10);
      call TimerCSMAsnooped.start(TIMER_ONE_SHOT,csmad);
    } else {
      call TimerCSMAsnooped.start(TIMER_ONE_SHOT,csmad);
    }
    isCSMA = TRUE;
    signal RouteManagement.StartCSMA();
    return SUCCESS;
  }

  event result_t VirtualSuperframeRemaining.fired() {
    isCSMA = TRUE;
    signal RouteManagement.StartCSMA();
    txforbidden = FALSE;
    dbg(DBG_USR3, "VirtualSR.fired TDMA%x CSMA%x\n", isTDMA, isCSMA);
    return SUCCESS;
  }

  event result_t TimerSuperframe.fired() {
    ImInsideFarea = FALSE;
    isCSMA = FALSE;
    isTDMA = FALSE;
    call BeaconTimeOut.start(TIMER_ONE_SHOT,BEACON_TIMEOUT);
    if (TOS_LOCAL_ADDRESS == 1)
      dbg(DBG_USR3, "TimerSuperframe.fired TDMA%x CSMA%x\n", isTDMA, isCSMA);
    return SUCCESS;
  }

  event result_t TimerWaitForCSMA.fired() {
    isCSMA = TRUE;    //new route
    signal RouteManagement.StartCSMA();
    call TimerCSMAduration.start(TIMER_ONE_SHOT,(CSMAdur - PACKET_TIME));
    return SUCCESS;
  }

  event result_t TimerPattern.fired() {
    if (noTDMASlot != 0) {
      if ((superframedur/noTDMASlot) == 1) {   
        //case of 1 superframe between 2 beacons
        isTDMA = TRUE;
        isCSMA = FALSE;
        call TimerMargin.start(TIMER_ONE_SHOT,timer_margin);
        cntpattern++;
      } else if (cntpattern < (superframedur/noTDMASlot)) {       
        isTDMA = TRUE;
        isCSMA = FALSE;
        cntpattern++;
        call TimerMargin.start(TIMER_ONE_SHOT,timer_margin);
      } else {
        isTDMA = FALSE;
        call TimerPattern.stop();
      }
      if (TOS_LOCAL_ADDRESS == 1)
        dbg(DBG_USR3, "TimerPattern.fired TDMA%x CSMA%x\n", isTDMA, isCSMA);
      return SUCCESS;
    } else {
      dbg(DBG_USR3, "TimerPattern.fired(fail) TDMA%x CSMA%x\n", isTDMA, isCSMA);
      return FAIL;
    }
  }

  event result_t TimerMargin.fired() {
//    call TimerTDMAduration.start(TIMER_ONE_SHOT,(tdmaduration-TimeSlot));
    call TimerTDMAduration.start(TIMER_ONE_SHOT, tdmaduration);
    if (TOS_LOCAL_ADDRESS == 1) dbg(DBG_USR3, "TimerTDMAduration.start tdmaduration=%i\n", tdmaduration);
      if (scheduleGot)
        post TDMAPhase();
    return SUCCESS;
  }

  event result_t TimerRandomM.fired() {
    if (isCSMA) post StartTransmission();
    return SUCCESS;
  }

  /***********************************************************************
   * Events
   ***********************************************************************/

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
    if (pMsg->type == AM_QUERY) {
      QueryMsg *pQMsg = (QueryMsg *)pMsg->data;
      dbg(DBG_USR3, "fmac: Query received\n");
      if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDR) return pMsg;
      if (Qseqno < pQMsg->seqno) {
        Qseqno = pQMsg->seqno;
        dbg(DBG_USR3, "fmac: signal Query.StartSendData\n");
        signal Query.StartSendData(pQMsg->rate);
      }
      return pMsg;
    }

    if (pMsg->type == AM_BEACON && TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
      BeaconMsg *pBMsg = (BeaconMsg *)pMsg->data;
      cntpattern = 0;
      ImInsideFarea = TRUE;
      snooped = TRUE;
      txforbidden = FALSE;
      isCSMA = FALSE;
      isTDMA = FALSE;

      call VirtualSuperframeRemaining.stop();
      call BeaconTimeOut.stop();
      call TimerPattern.stop();
      call TimerMargin.stop();
      call TimerTDMAduration.stop();
      call TimerTDMA.stop();
      call TimerCSMA.stop();
      call TimerTDMAremaining.stop();
      call TimerCSMArepetitions.stop();
      call TimerCSMAsnooped.stop();

      superframedur = pBMsg->superframe_dur - 3*SUPERFRAME_MARGIN;

      if (pBMsg->csma_dur > 150) csmadur = pBMsg->csma_dur - 1.5*TimeSlot;
      else csmadur = pBMsg->csma_dur;
      if (pBMsg->morebroadcast_pck == 1) {
        // it means the beacon is followed by a query 
        // and csma_durat=superfr_durat
        atomic scheduleGot = FALSE;
        tdmaduration = 0;
        noTDMASlot = 0;
        overalltdmaslots = 0;
        call TimerSuperframe.start(TIMER_ONE_SHOT,superframedur);
        call TimerCSMA.start(TIMER_ONE_SHOT,csmadur);
        signal RouteManagement.StartCSMA();
        atomic isCSMA = TRUE;
      } else {
        tdmaduration = pBMsg->tdma_dur;
        noTDMASlot = pBMsg->tdmarate;
        overalltdmaslots = pBMsg->notdmaslots;
        call TimerSuperframe.start(TIMER_ONE_SHOT,superframedur);
      }
      if (pBMsg->morebroadcast_pck == 0) {
        if (!scheduleNotgood) {                 
          atomic isTDMA = TRUE;
          atomic isCSMA = FALSE;
          cntpattern++;
          call TimerPattern.start(TIMER_REPEAT,noTDMASlot);
          call TimerMargin.start(TIMER_ONE_SHOT,timer_margin);
        } else {                             
          atomic isTDMA = FALSE;              
          atomic isCSMA = TRUE;                
          signal RouteManagement.StartCSMA();
        }                                  
      }
      if (pBMsg->morebroadcast_pck == 1) {
        isIncomingBroadcast = TRUE;
      }
      if (pBMsg->morebroadcast_pck == 3) {
        call ScheduleTimeOut.start(TIMER_ONE_SHOT,SCHEDULE_TIMEOUT);
        isIncomingBroadcast = TRUE;
      }
//      if (TOS_LOCAL_ADDRESS == 1)
        dbg(DBG_USR3, "Receive Beacon csmadur=%i tdmadur=%i slots=%i\n", pBMsg->csma_dur, pBMsg->tdma_dur, pBMsg->notdmaslots);
    }
    else if (id == AM_SCHEDULE && TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
      ScheduleMsg *pSMsg = (ScheduleMsg *)pMsg->data;
      uint8_t i, j, matches, slotpassed = 0;
      uint16_t slotcnt = 0;
      uint16_t slotcntforward = 0;

      alreadyfirst = FALSE;
      branchesscheduled = 0;
      cntpattern = 0;

      call ScheduleTimeOut.stop();

      if (!ImInsideFarea) {
        call VirtualSuperframeRemaining.stop();
        call TimerPattern.stop();
        call TimerMargin.stop();
        call TimerTDMAduration.stop();
        call TimerTDMA.stop();
        call TimerCSMA.stop();
        call TimerTDMAremaining.stop();
        call TimerCSMArepetitions.stop();
        call TimerCSMAsnooped.stop();
      }

      for (i=0; i<NO_BRANCHES_SCH; i++) {
        Internal_Table.NoSlot[i].slots = 0;
        Internal_Table.NoSlot[i].ifSrc = FALSE;
        Internal_Table.NoSlot[i].slotsTotdmaExpires = 0;
        Internal_Table.mybranch[i].isScheduled = FALSE;
        Internal_Table.mybranch[i].isBranchHead = FALSE;
      }
      ImFirstofSchedule = FALSE;
      position = 0;
      pointer = 0;
      positNodeArray = 0;
      IwasFirstofSchedule = FALSE;

      if (TOS_LOCAL_ADDRESS == 1) {
        for (i=0; i<NO_BRANCHES_SCH; i++) {
          dbg(DBG_USR3, "Schedule: head=%i slots=%i\n", pSMsg->schedule[i].headbranch_addr, pSMsg->schedule[i].no_slots);
        }
      }
      for (j=0; j<totalbranches; j++) {
        dbg(DBG_USR3, "Table: branch%i head=%i hops=%i\n", j, Internal_Table.mybranch[j].Headaddr, Internal_Table.mybranch[j].hops);
      }

      for (i=0; i<NO_BRANCHES_SCH; i++) {
        alreadyscheduled = FALSE;
        if (i == 0) {
          if (pSMsg->schedule[i].headbranch_addr == TOS_LOCAL_ADDRESS) {//I'm branch head and I'm the very first
            ImFirstofSchedule = TRUE;
            alreadyfirst = TRUE;
            slotcntforward = pSMsg->schedule[i].no_slots - 1;
            slotpassed = pSMsg->schedule[i].no_slots;
          } else {
            matches = 0;
            for (j=0; j<totalbranches; j++) {
              if (pSMsg->schedule[i].headbranch_addr == Internal_Table.mybranch[j].Headaddr && !alreadyscheduled) {
                alreadyscheduled = TRUE;
                matches++;
                Internal_Table.mybranch[j].isScheduled = TRUE;
                Internal_Table.NoSlot[i].slots = Internal_Table.mybranch[j].hops;
                Internal_Table.NoSlot[i].slotsTotdmaExpires = overalltdmaslots - Internal_Table.NoSlot[i].slots - 1;
                slotcntforward = pSMsg->schedule[i].no_slots - Internal_Table.mybranch[j].hops - 1;
                pointer++;
              }
            }
            if (matches == 0) {
              slotcnt = slotcnt + pSMsg->schedule[i].no_slots;
              pointer = i;
            }
            slotpassed = pSMsg->schedule[i].no_slots;
          }
        } else {
          if (pSMsg->schedule[i].headbranch_addr == TOS_LOCAL_ADDRESS) {
            if (ImSource && !alreadyfirst) {
              Internal_Table.NoSlot[pointer].ifSrc = TRUE;
              Internal_Table.mybranch[pointer].isScheduled = TRUE;
            }
            else {
              Internal_Table.mybranch[pointer].isBranchHead = TRUE;
              ImHead = TRUE;
              Internal_Table.mybranch[pointer].isScheduled = TRUE;
            }
           Internal_Table.NoSlot[pointer].slots = slotcntforward + slotcnt;
            Internal_Table.NoSlot[pointer].slotsTotdmaExpires = overalltdmaslots - slotpassed - 1;
            slotcntforward = pSMsg->schedule[i].no_slots - 1;
            slotcnt = 0;
            pointer++;
            slotpassed = slotpassed + pSMsg->schedule[i].no_slots;
          } else {
            matches = 0;
            alreadyscheduled = FALSE;
            for (j=0; j<totalbranches; j++) {
              if (pSMsg->schedule[i].headbranch_addr == Internal_Table.mybranch[j].Headaddr &&
                  pSMsg->schedule[i].headbranch_addr != 0 && Internal_Table.mybranch[j].Headaddr != 0 &&
                  Internal_Table.mybranch[j].isScheduled == FALSE && !alreadyscheduled) {
                matches++;
                alreadyscheduled = TRUE;
                Internal_Table.mybranch[pointer].isScheduled = TRUE;
                Internal_Table.NoSlot[pointer].slots = Internal_Table.mybranch[j].hops + slotcntforward + slotcnt;
                Internal_Table.NoSlot[pointer].slotsTotdmaExpires = overalltdmaslots - slotpassed - Internal_Table.mybranch[j].hops - 1;
                slotcntforward = pSMsg->schedule[i].no_slots - Internal_Table.mybranch[j].hops - 1;
                slotcnt = 0;
                pointer++;
              }
            }
           if (matches == 0)
              slotcnt = slotcnt + pSMsg->schedule[i].no_slots;
            slotpassed = slotpassed + pSMsg->schedule[i].no_slots;
          }
        }
      }

      for (i=0; i<NO_BRANCHES_SCH; i++) {
          if (Internal_Table.mybranch[i].isScheduled) branchesscheduled++;
      }

      if (ImFirstofSchedule) {
        if (ImInsideFarea) scheduleGot = TRUE;
        if (branchesscheduled > 0) positNodeArray = branchesscheduled;
        else positNodeArray = 1;
      } else {
        if (branchesscheduled > 0) {
          positNodeArray = branchesscheduled;
          if (ImInsideFarea) scheduleGot = TRUE;
        }
        else {
          positNodeArray = 0;
          scheduleGot = FALSE;
        }
      }

      if (branchesscheduled < totalbranches) newSchedule = TRUE;
      else newSchedule = FALSE;
      missedSchedule = FALSE;

      if (ImInsideFarea) {
        atomic isTDMA = TRUE;
        atomic isCSMA = FALSE;
        cntpattern++;
        call TimerPattern.start(TIMER_REPEAT,noTDMASlot);
        call TimerMargin.start(TIMER_ONE_SHOT,timer_margin);
      } else {
        atomic isCSMA = TRUE;
        atomic isTDMA = FALSE;
        signal RouteManagement.StartCSMA();
      }
      //dbg(DBG_USR3, "Receive Schedule TDMA%x CSMA%x\n", isTDMA, isCSMA);
    }
    return pMsg;
  }

  event result_t SendMsgD.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    if (id == AM_MULTIHOPMSG) return SUCCESS;
    if (!enableFunnelingMAC) {
      signal SendMsg.sendDone[id](pMsg, success);
      return SUCCESS;
    }
    if (pMsg == FwdBufList[iFwdBufTail]) { // Msg was from forwarding queue
      iFwdBufTail++;
      iFwdBufTail %= FWD_QUEUE_SIZE;
      if (occupancy > 0) occupancy--;
      gGetPacketBusy = FALSE;
    }
    signal SendMsg.sendDone[id](pMsg, success);
    if (TOS_LOCAL_ADDRESS != BASE_STATION_ADDR) {
      if (isCSMA && (occupancy > noAllocatedSlots()))
        call TimerRandomM.start(TIMER_ONE_SHOT, 12);
    }
    else if (occupancy > 0) {
      //call TimerRandomM.start(TIMER_ONE_SHOT, 12);
      post StartTransmission();
    }
    return SUCCESS;
  }

  event result_t SendMsgQ.sendDone(TOS_MsgPtr pMsg, result_t success) {
    uint8_t repeat;
    atomic {
      queryRepeat++;
      repeat = queryRepeat;
    }
    dbg(DBG_USR3, "fmac: SendMsgQ.sendDone\n");
    if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDR && repeat < 3) {
      if ((call SendMsgQ.send(TOS_BCAST_ADDR,sizeof(QueryMsg),&gMsgBuffer)) != SUCCESS) atomic gfSendBusy = FALSE;    
    } else {
      atomic queryRepeat = 0;
      gfSendBusy = FALSE;
      queryTosend = FALSE;
      call CC1000Control.SetRFPower(POWER_LEVEL_SINK);
      dbg(DBG_USR3, "fmac: Sent Query 3 times\n");
    }
    return SUCCESS;
  }

  event result_t SendMsgB.sendDone(TOS_MsgPtr pMsg, result_t success) {
    atomic gfSendBusy = FALSE;
    if (scheduleTosend && !dontsendschedule) {
      gfSendBusy = TRUE;
      post SendSchedule();
    }
    else call CC1000Control.SetRFPower(POWER_LEVEL_SINK);
    if (!scheduleTosend && !dontsendschedule) {
      atomic isCSMA = FALSE;
      cntpatternsink++;
      call TimerWaitForCSMA.start(TIMER_ONE_SHOT,(timer_margin + 10 + singleTDMAslotdur));
    }
    return SUCCESS;
  }

  event result_t SendMsgS.sendDone(TOS_MsgPtr pMsg, result_t success) {
    atomic {
      isCSMA = FALSE;
      gfSendBusy = FALSE;
      scheduleTosend = FALSE;
      needScheduleAgain = FALSE;
    }
    call CC1000Control.SetRFPower(POWER_LEVEL_SINK);
    call TimerWaitForCSMA.start(TIMER_ONE_SHOT,(timer_margin + 10 + singleTDMAslotdur));

    if (gfShowSchedule) {
      if (call SendMsgS.send(TOS_UART_ADDR,sizeof(ScheduleMsg),pMsg) != SUCCESS) {
      } else  atomic gfSendBusy = TRUE;    
      atomic gfShowSchedule = FALSE;
    }
    else atomic gfShowSchedule = TRUE;

    return SUCCESS;
  }

   async default event result_t RouteManagement.StartCSMA() {
     return SUCCESS;
   }

   default event result_t Query.StartSendData(uint16_t rate) {
     return SUCCESS;
   }

}
