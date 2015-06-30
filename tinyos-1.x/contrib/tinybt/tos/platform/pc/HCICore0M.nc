/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
 /* Based in part on code from the Blueware and Bluehoc simulators by IBM.
 */

includes bt;

//macrosafe, p_ only called once

#define DUMPP() do { dbg(DBG_USR2, "keepp1 = %p\n", keepp1); dbg(DBG_USR2, "keepp2 = %p\n", keepp2); } while(0)
#define PUTP(p_) do { gen_pkt* privp=(gen_pkt*)p_; dbg(DBG_USR2, "PUTP\n"); DUMPP(); assert(privp);if (!keepp1)keepp1=(gen_pkt*)privp;else if (!keepp2)keepp2=(gen_pkt*)privp;else assert(0); } while (0)
#define GETP(p_) do { typeof(p_) privp = p_; dbg(DBG_USR2, "GETP\n"); DUMPP(); if (keepp1){privp=(typeof(p_))keepp1;keepp1=NULL;}else if (keepp2){privp=(typeof(p_))keepp2;keepp2=NULL;}else assert(0); p_ = privp; } while (0)

/** 
 * HCICore0M module.
 * 
 * <p>Provides an implementation of the Bluetooth interface.</p> 
 *
 * <p>This module replaces the BTHost module from the Blueware and Bluehoc
 * simulators. Part of it is an adaption of this code.</p> 
 *
 * <p>According to the semantics from the Bluetooth interface, we need to keep to an
 * postCommand, postComplete, commandComplete order of commands/events. This is
 * achieved by having most postCommands delay execution of the actual command by
 * posting a task to handle the command at a later time. A number of temporary
 * variables are used for this.</p> */
module HCICore0M
{
  provides {
    interface Bluetooth; // Provide a Bluetooth interface for applications to use.
    interface BTHost;    // This is used by the BTLMPM module (LMP) 
  }
  uses {
    interface BTTaskScheduler as TaskScheduler; /* Schedule lowlevel inq and page tasks */
    interface BTTaskSchedulerSig as TaskSchedulerSig;
    interface BTBaseband as Baseband;
    interface BTHostSig;
    interface BTLMP;
    interface BTLinkController;
  }
}

implementation
{
  /**
   * Representation of a BTHost??? */
  struct bthost bh;

  /** A spare packet to send up */
  gen_pkt* keepp1; //
  /** A spare packet to send up */
  gen_pkt* keepp2; 
  /** The initial packet we reference in keep1 */
  gen_pkt spare_pkt;

  /** Used by postWriteScanEnable to store the scan status to be enabled, when
      delaying. */
  uint8_t scanMode;

#ifdef I_DONT_THINK_SO
  /* Initialization of this component */
  command result_t StdControl.init() {
    keepp1 = NULL;
    keepp2 = NULL;
    PUTP(&spare_pkt);
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    call Baseband.init(); // this module get initialized by baseband
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    return SUCCESS;
  }

  /* Command to control the power of the network stack */
  command result_t StdControl.stop() {
    call Baseband.stop();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Baseband.start();
    return SUCCESS;
  }
#endif


  /* **********************************************************************
   * BTHost interface implementation.
   * *********************************************************************/




  /* **********************************************************************
   * BTHost.Init
   * *********************************************************************/
  /**
   * BTHost.Init.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTHost.Init(struct LMP* linkq) {
    int i;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    bh.curr_paged_ = 0;
    bh.app_start_ = tos_state.tos_time;

    for (i=0; i < MaxNumLinks; i++)
      bh.active_addr_[i] = InvalidAddr;
    //           proto1_.value = 0;
    //           proto2_.value = 1;
    //           for(int i = 0; i < MaxNumNodes; i++) {
    //                proto1_.arp_table_[i] = (uchar)-1;
    //                proto2_.arp_table_[i] = (uchar)-1;
    //           }
    bh.linkq_ = linkq;

    bh.prev_clk_ = -1;
    bh.prev_dur_ = 0;

    bh.stats_.total_delay_ = 0;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    dbg(DBG_USR1, "BTHost.Init() << -- called\n");
  }


  /* **********************************************************************
   * BTHost.hciGetBdAddr()
   * *********************************************************************/
  /** Get the bdaddr from the host.
   * 
   * \return the bdaddr of the host. */
  command btaddr_t BTHost.hciGetBdAddr() {
    return call Baseband.bd_addr();
  }


  /* **********************************************************************
   * BTHost.droppedApplPacket
   * *********************************************************************/
  /**
   * BTHost.droppedApplPacket.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTHost.droppedApplPacket(struct BTPacket* p) {
    TRACE_BT(LEVEL_HIGH, "_%d_ DROPPED PACKET %d %s\n",
	     call Baseband.bd_addr(), p->ch.ptype, PacketTypeStr[p->ch.ptype]);
  }

  // Packet RECVDPKT was recevied on link LID. P is the data packet this node has
  // transmitted in the previous time slot. Must not modify both P and RECVDPKT.
  /* **********************************************************************
   * BTHost.recvd
   * *********************************************************************/
  /**
   * BTHost.recvd.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTHost.recvd(struct BTPacket* p, linkid_t lid, struct BTPacket* recvdPkt) {
    //           CALLBACK(recvd(p, lid, recvdPkt));
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
  }

  // P has been transmitted on link LID. If P == NULL, a control pkt such as POLL or
  // NULL pkt has been transmitted.
  /* **********************************************************************
   * BTHost.transmitted
   * *********************************************************************/
  /**
   * BTHost.transmitted.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTHost.transmitted(struct BTPacket* p, linkid_t lid) {
    //          CALLBACK(transmitted(p, lid));
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
  }

  // Called with the packet last transmitted and the one just recieved. Dont free
  // packets
  /* **********************************************************************
   * BTHost.recvdAppl
   * *********************************************************************/
  /**
   * BTHost.recvdAppl.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTHost.recvdAppl(struct BTPacket* p, linkid_t lid, struct BTPacket* recvdPkt) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           CALLBACK(recvd(p, lid, recvdPkt));
  }

  // There is no data to send on LID link which is currently active.
  /* **********************************************************************
   * BTHost.send
   * *********************************************************************/
  /**
   * BTHost.send.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command struct BTPacket* BTHost.send(linkid_t lid) {
    //           return taskScheduler.send(lid);
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    return NULL;
  }

  /* **********************************************************************
   * taskFinished
   * *********************************************************************/
  /**
   * taskFinished.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void taskFinished(enum task_type type) {
    //           taskScheduler.currTaskFinished();
    //           if(topo_ev_) {        // TODO: FIXME
    //                delete topo_ev_;
    //                topo_ev_ = NULL;
    //           }
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
  }


  // A new link with handle CH has been established.
  /* **********************************************************************
   * BTHost.linkEstablished
   * *********************************************************************/
  /**
   * BTHost.linkEstablished.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTHost.linkEstablished(linkid_t ch, bool bMaster) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           long long clk = tos_state.tos_time;
    //           //assert(Baseband.last_recv());

    //           const char* str = (bMaster) ? "MAS" : "SLV";
    //           long long dur = clk - bh.prev_clk_;
    //           if(Baseband.numLinks() <= 1) {
    //                str = (bMaster) ? "FIRST MAS" : "FIRST SLV";
    //                dur = (clk - bh.start_clk_);
    //           }
    //           TRACE_BT(LEVEL_ACCT, "%s _%d_ %s LINK ESTABLISHED %d -> %d DELAY %f\n",
    //                    TraceAcctStr, Baseband.bd_addr(), str, Baseband.bd_addr(), Baseband.lid2addr(ch), dur);
    //           bh.prev_dur_ = dur;
    //           bh.prev_clk_ = clk;
  }




  /* **********************************************************************
   * The BTHostSig interface implementation.
   * *********************************************************************/





  /* **********************************************************************
   * BTHostSig.dropped
   * *********************************************************************/
  /**
   * BTHostSig.dropped.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.dropped(struct BTPacket* p) {
    TRACE_BT(LEVEL_MED, "_%d_ DROPPED BTHOST %d %s\n",
	     call Baseband.bd_addr(), p->ch.ptype, PacketTypeStr[p->ch.ptype]);
  }

  // The LMP data queue associated with link OUTLID is full. This is as a result of an
  // incoming packet on link INLID. If the packet is generated by this node, INLID is
  // InvalidLid (see recv()).
  /* **********************************************************************
   * BTHostSig.queueFull
   * *********************************************************************/
  /**
   * BTHostSig.queueFull.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.queueFull(linkid_t outLid, linkid_t inLid) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //TRACE_BT(LEVEL_HIGH, "_%d_ LID %d QUEUE FULL\n", hciGetBdAddr(), lid);
    //           if(inLid != InvalidLid) {
    //                sched_->queueFull(outLid, inLid);
    //           }
  }

  /*=================================================================
    HCI events
    ==================================================================*/

  /* **********************************************************************
   * BTHostSig.hci2HostTimerExpiredEvent
   * *********************************************************************/
  /**
   * BTHostSig.hci2HostTimerExpiredEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hci2HostTimerExpiredEvent() {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s \n",
    //                    Baseband.bd_addr(), __FUNCTION__);
  }

  /* **********************************************************************
   * BTHostSig.hciCommandStatusEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciCommandStatusEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciCommandStatusEvent(enum hci_cmd cmd, bool succ) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s (hci_cmd: %s, succes %s) \n",
    //                    Baseband.bd_addr(), __FUNCTION__, hcicmdStr[cmd], succ?"yes":"no");
  }

  // Results of the hciCreateConnection command. If successful, CH contains the
  // connection handle and -1 otherwise.
  /* **********************************************************************
   * BTHostSig.hciConnectionCompleteEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciConnectionCompleteEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciConnectionCompleteEvent(linkid_t ch, bool bMasRole) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);

    // This stuff needs to be implemented...

    //           if(bMasRole) {
    //                taskFinished(PAGE_TSK);
    //           }
    //           else {
    //                enum task_type scan_type = timer2task(PAGE_SCAN_TM);
    //                if (taskScheduler().currTask() && taskScheduler().currTask()->type() == scan_type) { // @GT 10/17/02
    //                     taskFinished(scan_type);
    //                }
    //           }

    //           if(ch != InvalidLid) {
    //                linkEstablished(ch, bMasRole);
    //                if (bMasRole)
    //                     bh.active_addr_[ch] = bh.curr_paged_;
    //           }
    //           CALLBACK(hciConnectionCompleteEvent(ch, bMasRole));
    //           if(ch != InvalidLid && Baseband.isMasLink(ch))
    //                l2cap_->L2CA_ConnectReq(0, ch, BT_DH5); // TODO: FIXME
  }


  /* **********************************************************************
   * BTHostSig.hciConnectionRequestEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciConnectionRequestEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciConnectionRequestEvent(linkid_t ch) {
    TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s (ch: %d) \n",
	     call Baseband.bd_addr(), __FUNCTION__, ch);
  }

  /* **********************************************************************
   * BTHostSig.hciDisconnectionCompleteEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciDisconnectionCompleteEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciDisconnectionCompleteEvent(linkid_t ch) {
    TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s (ch: %d) \n",
	     call Baseband.bd_addr(), __FUNCTION__, ch);
  }

  // The link's hold timer has expired. However, because of other Baseband activities
  // this link cannot be changed to the Active status. Otherwise, modeChangeEvent would
  // have been called.
  /* **********************************************************************
   * BTHostSig.hciHoldExpiredEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciHoldExpiredEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciHoldExpiredEvent(linkid_t ch) {
    TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s (ch: %d) \n",
	     call Baseband.bd_addr(), __FUNCTION__, ch);
  }

  /* **********************************************************************
   * BTHostSig.hciInqRespSentEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciInqRespSentEvent.
   *
   * <p>Signalled from the baseband, when an inquiry response is sent.</p>*/
  event void BTHostSig.hciInqRespSentEvent() {
    TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s\n",
	     call Baseband.bd_addr(), __FUNCTION__);
  }

  
  /* **********************************************************************
   * BTHostSig.hciInquiryResult
   * *********************************************************************/
  /**
   * Inquiry Result.
   * 
   * <p>Signalled from the Baseband. In turs signal the Bluetooth.inquiryResult
   * handler. TODO: Seems we signal a 0 numresp packets, instead of an
   * inquiryComplete??? Dennis says this should work, although it is untested.</p>
   * 
   * <p>This function is called from the Baseband::inquiryComplete function.</p>
   * 
   * @param addr_vec a list of addresses found or NULL if no adressses. This
   *         functions frees addr_vec if it is != NULL */
  event void BTHostSig.hciInquiryResult(struct fhspayload* addr_vec) {
    int num_resp = 0;
    inq_resp_pkt* p = NULL;
    TRACE_BT(LEVEL_FUNCTION, "_%d_  HCIEvent %s\n",
	     call Baseband.bd_addr(), __FUNCTION__);
    if (!addr_vec) {
      TRACE_BT(LEVEL_FUNCTION, "NO FHS RESPONSE!\n");
      return;
    }
    GETP(p);
    p->start = (void*)&p->data[0];
    while (addr_vec) {
      struct fhspayload* addr_vect = addr_vec->next;
      dbg(DBG_BT, "%s,  btaddr_t = %d, bdaddr_t = %s\n",
	  __FUNCTION__, addr_vec->addr,
	  btaddr2string(addr_vec->addr));
      btaddr2bdaddr(&p->start->infos[num_resp].bdaddr, addr_vec->addr);
      TRACE_BT(LEVEL_FUNCTION, "TODO: Lots of fields not set in pscan and dev class\n");
      p->start->infos[num_resp].pscan_rep_mode = 0; // TODO: FILL VALUE
      p->start->infos[num_resp].pscan_period_mode = 0; // TODO: FILL VALUE
      p->start->infos[num_resp].pscan_mode = 0; // TODO: FILL VALUE
      p->start->infos[num_resp].dev_class[0] = 0; // TODO: FILL VALUE
      p->start->infos[num_resp].dev_class[1] = 0; // TODO: FILL VALUE
      p->start->infos[num_resp].dev_class[2] = 0; // TODO: FILL VALUE
      p->start->infos[num_resp].clock_offset =  addr_vec->clock;
      num_resp++;
      TRACE_BT(LEVEL_MED, "  FHS RESPONSE: addr: %d_ clock: %d read_time: %10lld piconet: %d\n",
	       addr_vec->addr, addr_vec->clock, addr_vec->real_time, addr_vec->piconet_no);
      free(addr_vec);
      addr_vec = addr_vect;
    }
    p->start->numresp = num_resp;
    p->end = (uint8_t*)p->start + num_resp*sizeof(inquiry_info) + sizeof(uint8_t);
    PUTP(signal Bluetooth.inquiryResult(p));
    //           taskFinished(INQ_TSK);
    //           bh.vec_addr_ = addr_vec;
  }

  /* **********************************************************************
   * BTHostSig.hciInquiryResult
   * *********************************************************************/
  /**
   * Inquiry complete.
   * 
   * <p>Signalled from the Baseband. In turs signal the Bluetooth.inquiryComplete
   * handler.</p>
   * 
   * <p>This function is called from the Baseband::inquiryComplete
   * function.</p> */
  event void BTHostSig.hciInquiryComplete() {
    signal Bluetooth.inquiryComplete();
  }
   
  // If BSUCCESS is true, the device mode has been changed to CUR mode with interval of
  // INTV ticks.  Otherwise, the attempt to change to CUR mode has failed.
  /* **********************************************************************
   * BTHostSig.hciModeChangeEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciModeChangeEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciModeChangeEvent(linkid_t ch, bool bSuccess, enum btmode cur, int intv) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           TRACE_BT(LEVEL_MED, "_%d_  HCIEvent %s (link %d, succ %s, btmode %s, intv %d)\n",
    //                    Baseband.bd_addr(), __FUNCTION__, ch, succ?"yes":"no", btmodeStr[cur], intv);
  }

  // BMASTER is true if the current role of this node on the connection CH is master.
  /* **********************************************************************
   * BTHostSig.hciRoleChangeEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciRoleChangeEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciRoleChangeEvent(bool bMaster, linkid_t ch) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           TRACE_BT(LEVEL_ACCT, "%s _%d_ ROLE_CHANGE EVENT: MAS %d-%d SLV, LASTLINK %.4f\n", TraceAcctStr,
    //                    Baseband.bd_addr(), Baseband.lid2addr(ch, true), Baseband.lid2addr(ch, false), bh.prev_dur_);
    //           CALLBACK(hciRoleChangeEvent(bMaster, ch));
    //           if(ch != InvalidLid && bMaster)
    //                l2cap_->L2CA_ConnectReq(0, ch, BT_DH5); // TODO: FIXME
  }

  // If BRESPTO = TRUE, the scan operation in progress has failed after recieving a
  // response from another node. Otherwise, the scan operation has completed.
  /* **********************************************************************
   * BTHostSig.hciScanCompleteEvent
   * *********************************************************************/
  /**
   * BTHostSig.hciScanCompleteEvent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.hciScanCompleteEvent(enum timer_t tm, bool bRespTO) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           if(!bRespTO) { // if this is a response or connection timeout, we would
    //                          // have received this event already
    //                taskFinished(timer2task(tm));	
    //           }
    //           else {
    //                TRACE_BT(LEVEL_TSF, "_%d_ hciCoreM::hciScanCompleteEvent TIMEOUT %d\n", Baseband.bd_addr(), TimerTypeStr[tm]);
    //                enum task_type scan_type = timer2task(PAGE_SCAN_TM);
    //                if (tm == PAGE_SCAN_TM && taskScheduler.currTask() &&
    //                    taskScheduler.currTask()->type() == scan_type) { // @GT 10/17/02
    //                     taskFinished(scan_type);
    //                }
    //           }

    //           CALLBACK(hciScanCompleteEvent(tm, bRespTO));
    //           int ticks, window;
    //           if(Baseband.getTimer(tm, &ticks, &window) && !bRespTO) {
    //                TopoEvent* e = scheduleTopoTask(timer2task(tm), window, ticks, 3, tm, ticks, window); // TODO: FIXME
    //                if(Baseband.getSessionInProg() == NONE_IN_PROG) {
    //                     Baseband.cancel(tm);
    //                     e->first_ = true; // TODO: FIXME
    //                }
    //                else {
    //                     e->first_ = false; // should not call scan again
    //                }
    //           }
  }

  // The slave has been active but not been polled by the master. Only applies to slave links.
  /* **********************************************************************
   * BTHostSig.pollMissed
   * *********************************************************************/
  /**
   * BTHostSig.pollMissed.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.pollMissed(linkid_t lid) {
    // TODO: This is an empty function in bt-taskscheduler.cc - some
    // stuff implemented in lcs.cc - but we do not use that. I think.
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //taskScheduler.pollMissed(lid);
  }

  /* **********************************************************************
   * BTHostSig.recvPkt
   * *********************************************************************/
  /**
   * BTHostSig.recvPkt.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.recvPkt(struct BTPacket* p, linkid_t ch) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    //           FREEP(p);
  }

  /* **********************************************************************
   * BTHostSig.recvPktAppl
   * *********************************************************************/
  /**
   * BTHostSig.recvPktAppl.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  event void BTHostSig.recvPktAppl(struct BTPacket* p) {
    TRACE_BT(LEVEL_FUNCTION, "%s called - unimplemented\n", __FUNCTION__);
    // TODO: Send it up
    FREEP(p);
  }



  /* **********************************************************************
   * Bluetooth interface implementation
   * *********************************************************************/




  /*=================================================================
    Bluetooth Commands
    ==================================================================*/

  /* **********************************************************************
   * This is needed to make sure that all functions are complete before
   * postcomplete is posted
   * *********************************************************************/
#define delay_postComplete(p_) PUTP(p_); post local_postComplete() 
  /**
   * Post a postComplete event.
   * 
   * <p>Gets a local buffer, then do a postcomplete.*/
  task void local_postComplete() {
    gen_pkt * p;
    GETP(p);
    signal Bluetooth.postComplete(p);
  }
     

  /* **********************************************************************
   * Basic stuff 
   * *********************************************************************/

  /**
   * Delay ready signal.*/
  task void local_postReady() {
    signal Bluetooth.ready();
  }

  /**
   * Initialize Bluetooth interface.
   *
   * <p>This operation will signal ready when done.</p>
   *
   * @param pkt An unused packet, needed to send the initial commands to 
   *            the Bluetooth device. This packet will be returned through
   *            the postComplete event later.
   * @return SUCCESS, wait for ready event */
  command result_t Bluetooth.init(gen_pkt* pkt) {
    keepp1 = NULL;
    keepp2 = NULL;
    PUTP(&spare_pkt);
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    call Baseband.init(); // this module get initialized by baseband
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    TRACE_BT(LEVEL_HIGH, "init requested\n");

    /* Init the TaskScheduler */
    call TaskScheduler.init();
    
    /* Start the baseband layer */
    call Baseband.start();

    //signal Bluetooth.postComplete(pkt);
    delay_postComplete(pkt);
    //signal Bluetooth.ready();
    post local_postReady();
    return SUCCESS;
  }

  /**
   * Post a HCI command. 
   *
   * <p>The resulting events are:
   *   <ul><li>postComplete for the buffer</li>
   *       <li>Optionally an "Complete" event for the command</li>
   *   </ul>
   * </p>
   *
   * @param pkt The packet with the HCI command. <code>p->start</code> must point
   *            to the beginning of a well-formed HCI request, including header.
   * @return SUCCESS (for now) */
  command result_t Bluetooth.postCmd(gen_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postCmd requested - unimplemented!!!!! - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

  /**
   * Actually figure out the BD address, post it to the caller.
   * 
   * <p>The node number is used for this...</p> */
  task void delay_readBDAddrComplete() {
    /* Setup a packet for signalling, get the btaddr from the baseband component. */
    btaddr_t bd_addr = call Baseband.bd_addr();
    read_bd_addr_pkt * res;
    TRACE_BT(LEVEL_HIGH, "task delay_readBDAddrComplete running\n");
    GETP(res);
    rst_send_pkt((gen_pkt *) res);
    res->start         = (typeof(res->start)) ((uint8_t *)res->end - sizeof(read_bd_addr_rp));
    res->start->status = 0;
    // memcpy(&res->start->bdaddr, &bd_addr, sizeof(bdaddr_t));
    btaddr2bdaddr(&(res->start->bdaddr), bd_addr);
    res = (read_bd_addr_pkt *) signal Bluetooth.readBDAddrComplete(res);
    PUTP(res);
  }
  /**
   * Read the local Blutooth address.
   *
   * <p>If successful, will result in a readBDAddrComplete event.</p>
   *
   * @param pkt An empty buffer
   * @return Whether the packet could be accepted/queued or not */
  command result_t Bluetooth.postReadBDAddr(gen_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postReadBDAddr requested\n");
    delay_postComplete(pkt);
    post delay_readBDAddrComplete();
    return SUCCESS;
  }

  /* **********************************************************************
   * Inquiry and page
   * *********************************************************************/

  /**
   * Set the inquiry scan parameters.
   *
   * <p>If successfull, this will result in a writeInqActivityComplete event.</p>
   * 
   * @param pkt A wellformed packet with the parameters for the inquiry scan.
   * @return An unused packet */
  command result_t Bluetooth.postWriteInqActivity(write_inq_activity_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postWriteInqActivity requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

#ifdef NOT_USED_ANWAY
  /**
   * Return a random number in a given range.
   * 
   * <p>Returns a random number between \a low and \a high.</p> 
   *
   * \todo Not sure about the exact range, actually. I think it is [l, u].
   *
   * \param l low limit
   * \param h high limit
  */
  static int randRange(int l, int u) {
    double r = (double)rand();
    double intv = u - l + 1;
    assert(r <= RAND_MAX);
    return (l+(int)(intv *  (r / (RAND_MAX+1.0))));
  }
#endif

  /**
   * Handler for when a task is started.
   * 
   * <p>The current scan mode is checked, and if the event reflects
   * one of the scanmodes, the Basebands scan operation is
   * called.</p>
   *
   * @param ev the event that was scheduled
   * @param currentTick the current tick
   * @param handled set this to true, if you handle this event. */
  event void TaskSchedulerSig.beginTask(TopoEvent * ev, int currentTick, bool * handled) {
    dbg(DBG_BT, "HCICore0M::TaskScheduler::beginTask, at %d\n", currentTick);
    if (*handled == TRUE) return;
    if (ev->type_ == INQ_SCAN_TSK && scanMode & SCAN_INQUIRY) {
      if (call Baseband.scan(INQ_SCAN)) {
	dbg(DBG_BT, "HCICore0M::TaskScheduler::beginTask -> Baseband.scan(INQ_SCAN)\n");
      } else {
	dbg(DBG_BT, "Error calling HCICore0M::TaskScheduler::beginTask -> Baseband.scan(INQ_SCAN)\n");
      }
      *handled = TRUE;
    } else {
      if (ev->type_ == PAGE_SCAN_TSK && scanMode & SCAN_PAGE) {
	if (call Baseband.scan(PAGE_SCAN)) {
	  dbg(DBG_BT, "HCICore0M::TaskScheduler::beginTask -> Baseband.scan(PAGE_SCAN)\n");
	} else {
	  dbg(DBG_BT, "Error calling HCICore0M::TaskScheduler::beginTask -> Baseband.scan(PAGE_SCAN)\n");
	}
	*handled = TRUE;
      } else {
	if (ev->type_ == PAGE_TSK) {
	  dbg(DBG_BT, "%s - handling PAGE_TSK(%d, %d, %d)\n", __FUNCTION__,
	      ev->data[1], ev->data[2], ev->data[3]);
	  call Baseband.page(ev->data[1], ev->data[2], ev->data[3]);
	  *handled = TRUE;
	} else {

	  dbg(DBG_BT, "%s - not handling event with type %d\n", __FUNCTION__,
	      ev->type_);
	}
      }
    }
  }


  /**
   * Handler for when a task is ended.
   * 
   * <p>If the event is one of those we handle (PAGE_SCAN_TSK |
   * INQ_SCAN_TSK), any current scan is ended (by calling
   * Baseband.endScan). If necc. (scanMode) a the task is
   * rescheduled.</p>
   *
   * @param ev the event that was scheduled
   * @param currentTick the current tick
   * @param handled set this to true, if you handle this event. NB, if you 
   *        handle this event, you are responsible for freeing it. If not, leave
   *        it be. */
  event void TaskSchedulerSig.endTask(TopoEvent * ev, int currentTick, bool * handled) {
    dbg(DBG_BT, "HCICore0M::TaskScheduler::endTask, at %d\n", currentTick);
    if (*handled == TRUE) return;
    if (ev->type_ == PAGE_SCAN_TSK) {
      call Baseband.endScan(PAGE_SCAN);
      if (scanMode & SCAN_PAGE) {
	call TaskScheduler.schedule(PAGE_SCAN_TSK, TwPageScan, ev, TpageScan, -1, 0);
      }
      *handled = TRUE;
    } else if (ev->type_ == INQ_SCAN_TSK) {
      call Baseband.endScan(INQ_SCAN);
      if (scanMode & SCAN_INQUIRY) {
	call TaskScheduler.schedule(INQ_SCAN_TSK, TwPageScan, ev, TpageScan, -1, 0);
      }
      *handled = TRUE;
    } 
  }

  /* **********************************************************************
   * delay_writeScanEnableComplete
   * *********************************************************************/
  /**
   * Delayed writeScanEnableComplete event.
   * 
   * <p>Depending on the value of scanMode, tasks for scanning are
   * posted to the TaskScheduler, using the schedule method.</p>. */
  task void delay_writeScanEnableComplete() {
    status_pkt * pkt; GETP(pkt);

    if (scanMode & SCAN_INQUIRY) {
      TopoEvent* ev = new_TopoEvent(timer2task(INQ_SCAN_TM));
      // TRACE_BT(LEVEL_HIGH, "postWriteScanEnable requested\n");
      ev->duration_ = TwInqScan;
      call TaskScheduler.schedule(timer2task(INQ_SCAN_TM), TwInqScan, ev, 0, -1, 0);
    } else {
      TRACE_BT(LEVEL_HIGH, "postWriteScanEnable requested - TODO: cancel INQUIRY_SCAN\n");
    }
    if (scanMode & SCAN_PAGE) {
      TopoEvent* ev = new_TopoEvent(timer2task(PAGE_SCAN_TM));
      TRACE_BT(LEVEL_HIGH, "postWriteScanEnable requested - TODO: handler...\n");
      ev->duration_ = TwPageScan;
      call TaskScheduler.schedule(timer2task(PAGE_SCAN_TM), TwPageScan, ev, 0, -1, 0);
    } else {
      // TODO: We need to make sure that perform a page scan after we get an 
      // inquiry, thats what the spec say...
      // That is not really related to this code though...
      TRACE_BT(LEVEL_HIGH, "postWriteScanEnable requested - TODO: cancel PAGE_SCAN\n");
    }
    

#ifdef THIS_IS_THE_CODE_I_AM_TRYING_TO_REPLACE
    /* The only one I could find that calls TSF::scan is tsf.cc: */
    if(tm == INQ_SCAN_TM || tm == PAGE_SCAN_TM) {
      if(isOkToAcceptNewLink(false)) {
	if(tm == PAGE_SCAN_TM) {
	  scan(tm, period, TsfPageScan, TwPageScan);
	} else {
	  scan(tm, period, TinqScan, TwInqScan);
	}
      } else {
	TRACE_BT(LEVEL_TSF, "_%d_ %s CANNOT ACCEPT MORE LINKS\n", host()->hciGetBdAddr(), NodeTypeStr[type_]);
	curr_tm_ = NUM_TM;
	curr_period_ = prev_period_ = 0;
	return;
      }
    }
    /* The only one I could find that calls BTHost::hciScan is tsf.cc: */
    void TSF::scan(timer_type tm, int intv, int period, int window) {
      nscan_ = intv / period; 
      if(intv % period > 0)
	nscan_++; 
      b_topo_in_prog_ = true; // safe guard
      TRACE_BT(LEVEL_TSF, "_%d_ scan: setting b_topo_in_prog_ %d\n", host()->hciGetBdAddr(), b_topo_in_prog_);
      host()->hciScan(tm, period, window);
    }
       
    /* In the original blueware, there is an implementation, called scan..
       Code from bt-host.cc: */
    void BTHost::hciScan(timer_type type, int ticks, int window) {
      scheduleTopoTask(timer2task(type), window, 0, 3, type, ticks, window);
    }

    // Schedule a topo contrution related task TSK for DURATION period. 
    TopoEvent*
      BTHost::scheduleTopoTask(task_type tsk, int duration, int offset, int nArgs, ...) {
      TopoEvent* ev = new TopoEvent(tsk);
      
      va_list ap;
      va_start(ap, nArgs);
      for(int i = 0; i < nArgs; i++)
	*(ev->data+i) = (int)va_arg(ap, int);
      va_end(ap);
      ev->handler_ = this;
      ev->duration_ = duration;
      if((tsk == INQ_TSK || tsk == PAGE_TSK || tsk == PAGE_SCAN_TSK || tsk == INQ_SCAN_TSK) 
	 && dynamic_cast<LCS*>(sched_)) {
	dynamic_cast<LCS*>(sched_)->scheduleTopoTask(duration, this, ev, offset);
      }
      else {
	sched_->schedule(tsk, duration, this, ev, offset);
      }
      return ev;
    }
#endif      
    
    /* Signal up the Bluetooth interface */
    rst_send_pkt((gen_pkt *)pkt);
    pkt->start = (typeof(pkt->start)) ((uint8_t*)pkt->end - sizeof(status_rp));
    pkt->start->status = 0;
    pkt = (status_pkt*) signal Bluetooth.writeScanEnableComplete(pkt);
    PUTP(pkt);
  }

  /**
   * Enable or disable inquiry and page scanning.
   * 
   * <p>This call can be used to enable or disable inquiry scanning.</p>
   *
   * <p>If successful it will trigger a writeScanEnableComplete event.</p>
   * 
   * <p>Example (note this example uses a fictive function <code>buffer_get</code>
   * to allocate a new buffer):<br>
   * <code>
   * gen_pkt * cmd_buffer = buffer_get();<br>
   * rst_send_pkt(cmd_buffer);<br>
   * cmd_buffer->start    = cmd_buffer->end - 1;<br>
   * // Enable Inquiry and Page scan<br>
   * (*(cmd_buffer->start)) = SCAN_INQUIRY | SCAN_PAGE;<br>
   * call Bluetooth.postWriteScanEnable(cmd_buffer);</code></p>
   *
   * @param pkt The scan mode (spec p. 647) must be passed as the last byte in
   *            the buffer.. Scanmode is enabled by setting the following bits.
   *            Use the defines for readability:<br>
   *            0x0 SCAN_DISABLED - no scans<br>
   *            0x1 SCAN_INQUIRY  - inquiry scan enabled<br>
   *            0x2 SCAN_PAGE     - page scan enabled
   * @return Whether the command was accepted/queued or not */
  command result_t Bluetooth.postWriteScanEnable(gen_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postWriteScanEnable requested\n");
    scanMode = *(pkt->start);
    delay_postComplete(pkt);
    post delay_writeScanEnableComplete();
    return SUCCESS;
  }
     
  /**
   * Start an inquiry with default parameters from GAP.
   *
   *  <p>Triggers a inquiryResult if we get any answers. Triggers a
   * inquiryComplete when done.</p>
   *
   * @param pkt An unused packet
   * @return SUCCESS (for now) */
  command result_t Bluetooth.postInquiryDefault(gen_pkt* pkt) {
    // lap[0], Lap[1], Lap[2], length, numrsp
    /* Note: If these are changed, they must be changed in the btnode2_2 platform too */
    uint8_t inq_parms[]  = {0x33, 0x8b, 0x9e, 10, 0};
    TRACE_BT(LEVEL_HIGH, "postInquiryDefault requested\n");
    assert(pkt);
    rst_send_pkt(pkt);
    pkt->start = pkt->end - INQUIRY_CP_SIZE;
    memcpy(pkt->start, inq_parms, INQUIRY_CP_SIZE);
    return call Bluetooth.postInquiry((inq_req_pkt*) pkt);
  }

  /**
   * Start an inquiry with custom parameters. 
   *
   * <p>The packet must contain all arguments at the end of the buffer to make
   * room for headers. Triggers an inquiryResult if we get any answers. Triggers
   * an inquiryComplete when done.</p>

   * @param pkt A wellformed inquiry packet
   * @return SUCCESS (for now) */
  command result_t Bluetooth.postInquiry(inq_req_pkt* p) {
    int iac;
    TRACE_BT(LEVEL_HIGH, "INQUIRY requested - unchecked...\n");
    assert(p);
    iac = lap2int(p->req.lap);
    /* Adjust the length to ticks == 312.5 usecs */
    call Baseband.inquire(p->req.length*4096, p->req.num_rsp, iac);
    /* This may be needed, don't really know... */
    signal Bluetooth.postComplete((gen_pkt *) p);
    // KEEP(p);
    return SUCCESS;
  }

  /**
   * Cancel a pending inquiry. 
   * 
   * <p>No inquiry complete event will be returned.</p>
   *
   * <p>TODO: Martin, return value?</p>
   * @param pkt An unused buffer.
   * @return inqiryCancelComplete has no return parameters */ 
  command result_t Bluetooth.postInquiryCancel(gen_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postInquiryCancel requested - not implemented\n");
    assert(0);
    return SUCCESS;
  }


  /* **********************************************************************
   * Connections
   * *********************************************************************/

  /**
   * Create an ACL connection.
   *
   * <p>Attempts to create a connection with the specified device. For faster
   * connection time fillout cp with values from inquiry otherwise fill in
   * 0's.</p>
   *
   * <p>Some time after calling this, connComplete will be signalled.</p>
   * 
   * @param pkt A wellformed connection create packet
   * @return Whether the command could be accepted or not */
  command result_t Bluetooth.postCreateConn(create_conn_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postCreateConn requested - Scheduling a PAGE_TSK\n");
    dbg(DBG_BT, "TODO: Check that connection is not already existing\n");

    memcpy(&bh.curr_paged_, &pkt->start->bdaddr, sizeof(bdaddr_t));
    {
      TopoEvent * ev = new_TopoEvent(PAGE_TSK);
      // TODO?: The pscan modes are not used at all...
      ev->duration_ = PageTO;
      ev->data[0] = 3; // I do not think this is used....
      ev->data[1] = bdaddr2btaddr(&pkt->start->bdaddr);
      ev->data[2] = pkt->start->clock_offset;
      ev->data[3] = PageTO;
      call TaskScheduler.schedule(PAGE_TSK, PageTO, ev, 0, -1, 0);
    }      
    delay_postComplete(pkt);
    return SUCCESS;
  }

  /**
   * Post a connection accept reply.
   *
   * <p>Some time after calling this, connComplete will be signalled.</p>
   *
   * @param pkt A wellformed accept package.
   * @return Whether the command could be accepted or not. */
  command result_t Bluetooth.postAcceptConnReq(accept_conn_req_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postAcceptConnReq requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

  /**
   * Disconnect a given connection.
   *
   * @param pkt A wellformed packet with hhe handle and a reason (se spec p. 571)
   * @return Wheter the packet could be accepted to be queued or not */
  command result_t Bluetooth.postDisconnect(disconnect_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postDisconnect requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }
     
  /**
   * Read the maximum allowed size for ACL databuffers.
   *
   * <p>Some time after calling this, readBufSize will be signalled.</p>
   *
   * @param pkt An empty buffer
   * @return Whether the command could be accepted or not. */
  command result_t Bluetooth.postReadBufSize(gen_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postReadBufSize requested - unimplemented - pkt leaked!\n");
    return SUCCESS;
  }
     
  /**
   * Post an ACL packet to be send over the air.
   *
   * <p>Results in a postComplete event which _doesn't_ mean that the data has
   * been sent over the air, but just to the Bluetooth device!</p>
   *
   * @param pkt A wellformed ACL packet. You need to fill in the header
   *            and place data right after the header
   * @return Wheter the packet could be accepted/queued or not */
  command result_t Bluetooth.postAcl(hci_acl_data_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postAcl requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

  /* **********************************************************************
   * Other stuff
   * *********************************************************************/

  /**
   * Request sniff-mode operation.
   *
   * @param pkt Requested sniff mode intervals
   * @return modeChange will inform about the mode, 
   *         selected intervals and errors. */
  command result_t Bluetooth.postSniffMode(sniff_mode_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postSniffMode requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

  /**
   * Write link - policy (allow M/S switch, hold/sniff/park mode).
   *
   * <p>Some time after calling this, writeLinkPolicyComplete will be triggered.</p>
   *
   * @param pkt Sets what to allow:<br>
   * 0x0 - Disable all<br>
   * 0x1 - Enable master/slave switch<br>
   * 0x2 - Enable Hold mode<br>
   * 0x4 - Enablse Sniff mode<br>
   * 0x8 - Enable Park mode
   *
   * @return modeChange will inform about the mode, 
   *         selected intervals and errors */
  command result_t Bluetooth.postWriteLinkPolicy(write_link_policy_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postWriteLinkPolicy requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

  /**
   * Set the role (master/slave) for a connection with another device.
   *
   * @param pkt The address of the remote device
   * @return Wheter the packet could be accepted to be queued or not */
  command result_t Bluetooth.postSwitchRole(switch_role_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postSwitchRole requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }

  /**
   * Change the allowed packet types for SENDING data.
   *
   * @param ptype - Bitstring showing allowed types */
  command result_t Bluetooth.postChgConnPType(set_conn_ptype_pkt* pkt) {
    TRACE_BT(LEVEL_HIGH, "postChgConnPType requested - unimplemented - pkt leaked!\n");
    assert(0);
    return SUCCESS;
  }
}
