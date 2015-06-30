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
/* Original copyright:
 *       Copyright © 2002 International Business Machines Corporation, 
 *       Massachusetts Institute of Technology, and others. All Rights Reserved. 
 * Originally Licensed under the IBM Public License, see:
 * http://www.opensource.org/licenses/ibmpl.html
 * Previously a part of the bluehoc and blueware simulators
 */

includes bt;


/**
 * This component represents the baseband.
 *
 * <p>Really, that is all I know.</p> */
module BTBasebandM
{
  provides {
    interface BTBaseband;
    interface BTHostSig;
  }
  uses {
    interface BTTaskScheduler as TaskScheduler; /* To run the checkTasks interface */
    interface BTFHChannel;
    interface BTScheduler;
    interface BTLinkController;
    interface BTLMP;
    interface BTHost;
  }
}

implementation
{
  struct baseband bb;

  //forward decls

  void setIacFilter(btaddr_t*, int, bool);
  void setIAC(btaddr_t);
  void event_clkn_create(event_t*, int, long long);
  enum device_role_t currentRole();
  btaddr_t lid2addr1(linkid_t);
  btaddr_t lid2addr(linkid_t, bool);
  linkid_t addr2lid(btaddr_t);
  btaddr_t lid2pid(linkid_t);
  linkid_t pid2lid(btaddr_t);
  linkid_t am2lid(amaddr_t);
  amaddr_t lid2am(linkid_t);
  enum hci_cmd tm2hci(enum timer_t);

  void handleInqRespTO();
  void handlePageRespTO();
  void handleNewConnectionTO();

  void switchFHInputs(btaddr_t);
  void holdPiconet(btaddr_t, int);
  void delSlaveLink(btaddr_t);
  void prepareMasLink();
  void prepareSlvLink();
  void delMasterLink(amaddr_t);
  void initInqPageParam();
  void updateInqPageParam();
  void inquiryComplete(enum state_t, bool);
  void switchRoles(long long, struct BTPacket*);
  void updateTxTimer(enum clock_t);
  void updateHoldTimer(struct con_attr*, int);
  int clockDiff(int);
  linkid_t newLid();

  void scheduleNext();
  void sendPacket(struct BTPacket*);
  struct BTPacket* sendPOLLPacket(amaddr_t);
  void sendNULLPacket(amaddr_t);
  void sendIDPacket(btaddr_t);
  void sendFHSPacket();
  bool isWithinRange(int, int);
  bool isErrorFree(struct BTPacket*);
  int isValidPacket(struct BTPacket*);
  void dropped(struct BTPacket*);

  void event_switch_create(event_t*, int, long long);
  void event_rswitch_create(event_t*, int, long long);
  void event_id_create(event_t*, int, long long);
  void event_clk_create(event_t*, int, long long, btaddr_t);
  void event_clkn_create(event_t*, int, long long);
  void event_tx_create(event_t*, int, long long, struct BTPacket*);
  void event_recvfull_create(event_t*, int, long long, struct BTPacket*);
  void event_sess_create(event_t*, int, long long);

  /* **********************************************************************
   * BTBaseband.init
   * *********************************************************************/
  /**
   * Initialize the baseband.
   *
   * <p>Initializes the baseband. (Timers, counter, lots of variables), the scheduler
   * and the host.</p> */
  command result_t BTBaseband.init() {
    int i;
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    bb.giac_ = GIAC;

    /* Setup the address as a random value and NODE_NUM */
    // bb.bd_addr_ = (randRange(0, 1 << 15) << 16) + NODE_NUM;
    // bb.bd_addr_ = (0x42 << 16) + NODE_NUM;
    bb.bd_addr_ = NODE_NUM;
    TRACE_BT(LEVEL_FUNCTION, "Setting address to %08x\n", bb.bd_addr_);

    bb.diac_ = 0;
    bb.clkn_ = bb.clkf_ = bb.clke_ = 0;
    bb.new_am_addr_ = 0;
    //trace_ = NULL;

    bb.num_piconets_ = 0;
    bb.curr_piconet_ = InvalidPiconetNo;
    bb.next_piconet_ = InvalidPiconetNo;
    bb.last_piconet_ = InvalidPiconetNo;

    //reply_slot_ = 0;

    // initialize timers
    bb.tx_timer_ = 0;
    bb.inq_timer_ = bb.inqscan_timer_ = bb.inqbackoff_timer_ = bb.inqresp_timer_ = 0;
    bb.page_timer_ = bb.pagescan_timer_ = bb.pageresp_timer_ = bb.new_connection_timer_ = 0;
    bb.wait_timer_ = PageWaitTime;

    // initialize counters
    bb.nmr_ = bb.nsr_ = bb.nfhs_ = 0;
    bb.nsr_incr_offset_ = 0;
    bb.num_id_ = bb.num_trains_sent_ = 0;
    //last_paged_ = 0; //unused
    bb.freeze_ = 0;
    bb.polled_ = 0;
    //am_addr_ = 0; //unused

    bb.train_type_ = A;
    bb.state_ = STANDBY;
    bb.prev_state_ = NUM_STATE;
    bb.next_state_ = CONNECTION;
    bb.tdd_state_ = IDLE;
    bb.tx_clock_ = CLKN;

    bb.num_acl_links_ = 0;   // TODO: I sent mail about this, verify usage

    for (i = 0; i < MaxNumSlaves + 1; i++)
      bb.active_list_[i] = -1; // 0 is a valid address

    bb.state_prog_ = NONE_IN_PROG;
    bb.prev_clk_ = -1;
    bb.other_addr_ = InvalidAddr;
    //other_offset_ = 0; //unused

    for(i = 0; i < MaxNumLinks; i++)
      bb.link_pids_[i] = InvalidPiconetNo;

    for(i = 0; i < MaxNumLinks; i++)
      bb.time_spent_in_conn_[i] = 0;

    //last_recv_ = NULL; //unused

    bb.vip_pkt_ = NULL;
    bb.vip_piconet_ = InvalidPiconetNo;
    bb.last_even_tick_ = 0;
    bb.role_ = AS_MASTER;
    bb.max_scan_period_ = RAND_MAX; // This seems wrong

    memset(&bb.my_piconet_attr_, 0, sizeof(bb.my_piconet_attr_));
    bb.my_piconet_attr_.mode = Disconnected;

    memset(bb.piconet_attr_, 0, sizeof(struct con_attr*)*MaxNumLinks);

    memset(bb.tms_, 0, sizeof(bb.tms_));
    bb.tms_[INQ_SCAN_TM].window = TwInqScan;
    bb.tms_[PAGE_SCAN_TM].window = TwPageScan;
    bb.tms_[INQ_SCAN_TM].period = TinqScan;
    bb.tms_[PAGE_SCAN_TM].period = TpageScan;

    bb.host_timer_ = 0;
    bb.b_stop_ = FALSE;
    bb.iac_filter_accept_ = FALSE;
    bb.b_connect_as_master_ = TRUE;

    memset(bb.cache_, 0, sizeof(struct cache_entry)*num_sequence);
    bb.n_hits_ = 0;

    bb.recv_freq_ = InvalidFreq;
    bb.b_switch_ = FALSE;

    bb.curr_lid_ = InvalidLid;
    bb.tx_lid_ = InvalidLid;

    for(i = 0; i < NUM_STATE; i++)
      bb.time_spent_[i] = 0;

    bb.iac_filter_ = NULL;
    bb.iac_filter_length = 0;

    bb.clkn_ev_ = NULL;

    bb.request_q_.valid = FALSE;

    bb.addr_vec_ = NULL;
    bb.addr_vec_size = 0;

    for (i = 0; i < MaxNumLinks; i++)
      call BTLMP.Init(&bb.linkq_[i], i < MaxNumSlaves, (amaddr_t)(i+1));
    for (i = 0; i < MaxNumLinks; i++)
      call BTLinkController.Init(&bb.lc_[i], (amaddr_t)(i < MaxNumSlaves ? i+1 : 0), &bb.linkq_[i]);
    call BTScheduler.Init(bb.lc_);
    call BTHost.Init(bb.linkq_);
    srand(time(NULL));
    TRACE_BT(LEVEL_FUNCTION, "%s (%d)\n", __FUNCTION__, __LINE__);
    return SUCCESS;
  }

  /* **********************************************************************
   * BTBaseband.stop
   * *********************************************************************/
  /**
   * Stop the baseband.
   *
   * <p>Stop the baseband. Never call this function. (So, why is it here?)</p> */
  command result_t BTBaseband.stop() {
    assert(0);
  }

  /* **********************************************************************
   * updateRole
   * *********************************************************************/
  /**
   * Change the role of the baseband.
   *
   * @param new_role one of AS_MASTER, AS_SLAVE or BOTH (last used during init?) */
  void updateRole(enum device_role_t new_role) {
    bb.role_ |= new_role;
  }

  /**
   * Start the baseband.
   *
   * <p>This does a lot of things. One of the things is that the clkn is created and
   * set to be triggered in ClockTick time from now.</p> */
  command result_t BTBaseband.start() {
    int i;
    dbg(DBG_USR1, "BTBaseband.start()\n");
    addToBbs(&bb);
    bb.b_stop_ = FALSE;

    bb.uap_lap_ = randRange(0U, UINT_MAX); // assign a random addr

    updateRole(AS_SLAVE);
    updateRole(AS_MASTER);

    for(i = 0; i < MaxNumSlaves; i++)
      bb.link_pids_[i] = bb.bd_addr_;

    // backward compatibility //@GT
    if(bb.diac_ != 0) {
      int n = 0;
      btaddr_t* filter = (btaddr_t*)malloc(sizeof(btaddr_t)*32);
      i = 0;
      dbg(DBG_MEM, "malloc filter.\n");
      while(n < 32) {
	if(!((bb.diac_ >> n) & 0x01)) { // Do not accept those not on the list
	  filter[i] = (btaddr_t)(n + IACLow);
	  i++;
	}
	n++;
      }
      setIacFilter(filter, i, FALSE);
    }

    //setIAC(IACLow + pid());
    setIAC(GIAC);

    bb.sess_ev_ = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc session event.\n");
    bb.sess_ev_->data = (void*)malloc(sizeof(struct sess_ev_data));
    dbg(DBG_MEM, "malloc session.data event.\n");

    bb.switch_ev_ = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc session event.\n");
    bb.switch_ev_->data = (void*)malloc(sizeof(struct sess_switch_data));
    dbg(DBG_MEM, "malloc session.data event.\n");

    bb.clkn_ev_ = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc clkn event.\n");

    event_clkn_create(bb.clkn_ev_, NODE_NUM, tos_state.tos_time + ClockTick);
    TOS_queue_insert_event(bb.clkn_ev_);

    //if(bb.bd_addr_ > gMaxBDAddr)
    //gMaxBDAddr = bb.bd_addr_;

    bb.scat_id_ = bb.prev_scat_id_ = bb.bd_addr_;
    gScatCount++;
    gNodeCount++;

    assert(bb.clkn_ >= 0);
    bb.start_clkn_ = bb.clkn_;

    TRACE_BT(LEVEL_ACCT, "BB START %d\t clock: %10lld, xpos %.4d, ypos %.4d, clkn %d\n",
	     bb.bd_addr_, tos_state.tos_time, bb.xpos_, bb.ypos_,  bb.clkn_);

    return SUCCESS;
  }
  
  /* **********************************************************************
   * BTBaseband.sendSlotOffset
   * *********************************************************************/
  /**
   * Send a SLOT_OFFSET command to the LMP layer.
   *
   * <p>Only call when the role is AS_SLAVE.</p>
   *
   * @param lid The linkid of the connection to send the SLOT_OFFSET on. */
  command void BTBaseband.sendSlotOffset(linkid_t lid) {
    assert(currentRole() == AS_SLAVE);
    call BTLMP.sendLMPCommand2(&bb.linkq_[lid], LMP_SLOT_OFFSET, 
			       (unsigned int)(bb.clkn_ - bb.master_clk_), 
			       (unsigned int)bb.bd_addr_);
    bb.newconn_addr_ = lid2addr1(lid);
  }

  /* **********************************************************************
   * BTBaseband.recvSlotOffset
   * *********************************************************************/
  /**
   * BTBaseband.recvSlotOffset.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.recvSlotOffset(btaddr_t slv_addr) {
    //bb.other_offset_ = offset;
    bb.newconn_addr_ = bb.other_addr_ = slv_addr;
  }

  /* **********************************************************************
   * currentRole
   * *********************************************************************/
  /**
   * What is our current role.
   *
   * <p>Checks if the address of the current piconet is the same as our addresse and
   * not an invalid piconet. If so, we are the master, otherwise the slave.</p>
   *
   * @return AS_MASTER or AS_SLAVE */
  enum device_role_t currentRole() {
    return ((bb.curr_piconet_ == bb.bd_addr_ && bb.bd_addr_ != InvalidPiconetNo) ? AS_MASTER : AS_SLAVE);
  }


  /* **********************************************************************
   * getTimer
   * *********************************************************************/
  /**
   * getTimer.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  bool getTimer(enum timer_t type, int* period, int* window) {
    if(period)
      *period = bb.tms_[type].period;
    if(window)
      *window = bb.tms_[type].window;
    return bb.tms_[type].valid;
  }


  /* **********************************************************************
   * setIacFilter
   * *********************************************************************/
  /**
   * setIacFilter.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void setIacFilter(btaddr_t* filter, int length, bool bAccept) {
    unsigned int i;
    bb.iac_filter_ = filter;
    bb.iac_filter_length = length;
    for(i = 0; i < length; i++)
      assert(filter[i] >= IACLow && filter[i] <= IACHigh);
    bb.iac_filter_accept_ = bAccept;
  }


  /* **********************************************************************
   * getIacFilter
   * *********************************************************************/
  /**
   * getIacFilter.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  bool getIacFilter(int** filter, int* length) {
    if (filter) {
      int* filterl = (int*)malloc(sizeof(int)*bb.iac_filter_length);
      dbg(DBG_MEM, "malloc filter.\n");
      memcpy(filterl, bb.iac_filter_, sizeof(int)*bb.iac_filter_length);
      *length = bb.iac_filter_length;
      *filter = filterl;
    }
    return bb.iac_filter_accept_;
  }


  /* **********************************************************************
   * setIAC
   * *********************************************************************/
  /**
   * Set the IAC used to send out during PAGE or INQUIRY.
   *
   * @param iac IAC to set. Must be valid (IACLow <= iac <= IACHigh) */
  void setIAC(btaddr_t iac) {
    assert(iac >= IACLow && iac <= IACHigh);
    bb.iac_ = iac;
  }
  

  /* **********************************************************************
   * checkWrapAround
   * *********************************************************************/
  /**
   * checkWrapAround.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void checkWrapAround(int* clk) {
    if (*clk > MaxClock) {
      TRACE_BT(LEVEL_ACCT, "_%d_ CLOCK WRAP AROUND\n", bb.bd_addr_);
      *clk = modulo(*clk, MaxClock);
    }
  }


  /* **********************************************************************
   * updateTimeSpent
   * *********************************************************************/
  /**
   * updateTimeSpent.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void updateTimeSpent(enum state_t state, long long dur, btaddr_t addr) {
    bb.time_spent_[state] += dur;
    if(state == CONNECTION) {
      if(addr != InvalidAddr)
	bb.time_spent_in_conn_[addr2lid(addr)] += dur;
    }
  }


  /* **********************************************************************
   * newAmAddr
   * *********************************************************************/
  /**
   * newAmAddr.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  int newAmAddr() {
    amaddr_t i = 1;
    for (; bb.active_list_[i] != InvalidAddr && i < MaxNumSlaves + 1; i++)
      ;
    bb.new_am_addr_ = i;
    return i;
  }


  /* **********************************************************************
   * freqCacheHit
   * *********************************************************************/
  /**
   * freqCacheHit.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  int freqCacheHit(int clk, int clk_frozen, enum fhsequence_t seq, int addr) {
    int res;
    return InvalidFreq;
    switch(seq) {
    case channel_hopping:
    case page_scan:
    case inquiry_scan:
      res = cache_equal3(&bb.cache_[seq], clk, addr);
      break;

    case page_hopping:
    case inquiry_hopping:
      res = cache_equal4(&bb.cache_[seq], clk, addr, bb.train_type_);
      break;
    default:
      //case slave_response:
      //case master_response:
      //case inquiry_response:
      res = cache_equaln(&bb.cache_[seq], clk, clk_frozen, addr, bb.tdd_state_, bb.nsr_, bb.nmr_, bb.train_type_, bb.nfhs_);
      break;
    }
    return res;
  }

  /* **********************************************************************
   * FH_kernel
   * *********************************************************************/
  /**
   * Frequency Hop Kernel.
   *
   * <p>clk can be Master clk or clkn or clke, the esimate of paged
   * unit's clk by the paging unit, clk_frozen is the frozen value of
   * the clock when page/inquiry message is received. this is same as
   * clk, if clk is not frozen inquiry: clk = CLKN. page: clk =
   * CLKE</p>
   *
   * <p>This procedure closely follows the Baseband Spec 1.1. The only
   * difference is in choosing Y1 (ip1_EXOR2) and Y2 (ip4_ADD_79) for
   * master/slave response and inquiry response hopping
   * sequences. Instead of relying on the clk_1 bit (which does not
   * work) as the Spec suggested we rely on the tdd_state_.</p>
   *
   * <p>Also, the Baseband Spec 1.1 has some bugs in calculating the
   * inquiry hopping sequence and as a result, the worst case scenario
   * for two nodes, one in INQ and the other in INQ_SCAN, to discover
   * each other can be more than 10.24s as suggested by the Spec.</p>
   *
   * @param clk See description
   * @param clk_frozen See description
   * @param fh_seq TODO: No clue
   * @param addr TODO: No clue
   * @return */
  int FH_kernel(int clk, int clk_frozen, enum fhsequence_t fh_seq, int addr) {
    int ip1_ADD_32, ip1_EXOR2, ip4_ADD_79; // X, Y1, Y2
    int ip2_ADD_32, ip2_EXOR1, ip2_EXOR2, ip3_PERM, ip2_ADD_79, ip3_ADD_79; // A, B, C, D, E, F
    int Xp_or_i, Xp_or_i_rs, Xprm, k_off;
    int ones = -1;
    int clk_1, clk_12to16, clk_frozen_12to16, clk_0_2to4, clk_frozen_0_2to4;
    int ip1_EXOR1, ip1_PERM, ip2_PERM, ip1_ADD_79, aindex, freq;
    int res;

#undef FH_KERNEL_DEBUG
#ifdef FH_KERNEL_DEBUG
    dbg(DBG_BT, "FH_kernel(%d, %d, %d, %d)\n", clk, clk_frozen, fh_seq, addr);
#endif

    if (addr != GIAC) {
      assert(addr >= 0 && addr < MaxNumLinks);
      addr = (int)modulo(findBbs(addr)->uap_lap_, (unsigned)(1 << 28)); // only 28 bits are used
    }

#ifdef FH_KERNEL_DEBUG
    dbg(DBG_BT, "FH_kernel, addr= %d\n", addr);
#endif

    res = freqCacheHit(clk, clk_frozen, fh_seq, addr);
    if(res != InvalidFreq) {
      bb.n_hits_++;
      return res;
    }

    clk_1 = subBits(clk, 1, 1, 0);
    clk_12to16 = subBits(clk, 12, 5, 0);
    clk_frozen_12to16 = subBits(clk_frozen, 12, 5, 0);
    clk_0_2to4 = (clk & 0x01) + subBits(clk, 2, 3, 1);
    clk_frozen_0_2to4 = (clk_frozen & 0x01) + subBits(clk_frozen, 2, 3, 1);

    if (bb.train_type_ == A)
      k_off = 24;
    else
      k_off = 8;

#ifdef FH_KERNEL_DEBUG
    dbg(DBG_BT, "FH_kernel, k_off= %d\n", k_off);
#endif

    //make something up if its too slow
    //hash_map<unsigned, addr_inputs>::const_iterator it = addr_cache_.find(addr);
    //if (it == addr_cache_.end()) {
    ip2_ADD_32 = subBits(addr,23, 5, 0); // A
    ip2_EXOR1  = subBits(addr,19, 4, 0);  // B
    ip2_EXOR2  = subBits(addr, 0, 1, 0) +
      subBits(addr, 2, 1, 1) + subBits(addr, 4, 1, 2) +
      subBits(addr, 6, 1, 3) + subBits(addr, 8, 1, 4); // C
    ip3_PERM = (addr >> 10) & 0x01ff; // D
    ip2_ADD_79 = subBits(addr, 1, 1, 0) +
      subBits(addr, 3, 1, 1) + subBits(addr, 5, 1, 2) +
      subBits(addr, 7, 1, 3) + subBits(addr, 9, 1, 4) +
      subBits(addr,11, 1, 5) + subBits(addr,13, 1, 6); // E
    //addr_inputs inputs;
    //inputs.init(ip2_ADD_32, ip2_EXOR1, ip2_EXOR2, ip3_PERM, ip2_ADD_79);
    //addr_cache_[addr] = inputs;
    //}
    //else {
    //ip2_ADD_32 = it->second.ip2_ADD_32_;
    //ip2_EXOR1 = it->second.ip2_EXOR1_;
    //ip2_EXOR2 = it->second.ip2_EXOR2_;
    //ip3_PERM  = it->second.ip3_PERM_;
    //ip2_ADD_79 = it->second.ip2_ADD_79_;
    //}
    ip3_ADD_79 = 0; // F

    switch  (fh_seq) {
    case inquiry_hopping:
    case page_hopping:
      Xp_or_i = modulo(clk_12to16 + k_off + modulo(clk_0_2to4 - clk_12to16, 16), 32);
      ip1_ADD_32 = Xp_or_i & 0x1f; // X
      ip1_EXOR2 = clk_1; // Y1
      ip4_ADD_79 =  32 * clk_1; // Y2
      //TRACE_BT(LEVEL_INQPG, "clk 0x%x, clk_12to16 0x%x, k_off %d, clk_0_2to4 0x%x, clk_12to16 0x%x\n", 
      //		 clk, clk_12to16, k_off, clk_0_2to4, clk_12to16);
      break;
    case page_scan:
    case inquiry_scan:
#ifndef VER11
      ip1_ADD_32 = clk_12to16;
#else
      // 1.1 says we should use the same as INQ RESPONSE for INQ_SCAN
      ip1_ADD_32 = modulo(clk_12to16 + bb.nfhs_, 32);
#endif
      ip1_EXOR2 = 0;
      ip4_ADD_79 = 0;
      break;
    case slave_response:
      Xp_or_i_rs = modulo(clk_frozen_12to16 + bb.nsr_, 32);
      ip1_ADD_32 = Xp_or_i_rs & 0x1f;

      if (bb.tdd_state_ == TRANSMIT) {
	ip1_EXOR2 = 1;
	ip4_ADD_79 =  32;
      }
      else {
	ip1_EXOR2 = 0;
	ip4_ADD_79 = 0;
      }
      break;

    case inquiry_response:
#ifdef FH_KERNEL_DEBUG
      dbg(DBG_BT, "FH_kernel, setting up an inquiry_response\n");
#endif
#ifndef VER_11
      Xp_or_i_rs = modulo(clk_frozen_12to16 + bb.nfhs_, 32);
#else
      // 1.1 says frozen is unnecessary and just use clk_12to16
      Xp_or_i_rs = modulo(clk_12to16 + bb.nfhs_, 32);
#endif
      ip1_ADD_32 = Xp_or_i_rs & 0x1f;

      if (bb.tdd_state_ == TRANSMIT) {
#ifdef FH_KERNEL_DEBUG
	dbg(DBG_BT, "FH_kernel, leg one\n");
#endif
	ip1_EXOR2 = 1;
	ip4_ADD_79 = 32;	
      }
      else {
#ifdef FH_KERNEL_DEBUG
	dbg(DBG_BT, "FH_kernel, leg two\n");
#endif
	ip1_EXOR2 = 0;
	ip4_ADD_79 = 0;
      }
      break;

    case master_response:
      Xprm = modulo(modulo(clk_frozen_0_2to4 - clk_frozen_12to16, 16) +
		    clk_frozen_12to16 + k_off + bb.nmr_, 32);

      ip1_ADD_32 = Xprm & 0x1f;

      if (bb.tdd_state_ == TRANSMIT) {
	ip1_EXOR2 = 0;
	ip4_ADD_79 = 0;
      }
      else {
	ip1_EXOR2 = 1;
	ip4_ADD_79 = 32;
      }
      break;
    case channel_hopping: {
      int clk_2to6, clk_21to25, clk_16to20, clk_7to15, clk_7to27;
      clk_2to6 = subBits(clk, 2, 5, 0); //(int)(clk >> 2) & 0x1f;
      ip1_ADD_32 = clk_2to6;

      ip1_EXOR2 = clk_1;
      ip4_ADD_79 = 32 * clk_1;

      clk_21to25 = subBits(clk, 21, 5, 0); //(int)(clk >> 21) & 0x1f;
      ip2_ADD_32 = EXOR_5(ip2_ADD_32, clk_21to25);

      clk_16to20 = subBits(clk, 16, 5, 0);
      ip2_EXOR2 = EXOR_5(ip2_EXOR2, clk_16to20);

      clk_7to15 = subBits(clk, 7, 9, 0); //(clk >> 7) & 0x01ff;
      ip3_PERM = EXOR_9(ip3_PERM, clk_7to15);

      clk_7to27 = subBits(clk, 7, 21, 0); //(int)(clk >> 7) & 0x001fffff;
      ip3_ADD_79 = modulo(16 * clk_7to27, 79) & 0x7f;
      //(int)((16 * clk_7to27) % 79) & 0x7f;

      break;
    }
    case num_sequence:
    default:
      //shut up warnings
      ip1_ADD_32=0;
      ip1_EXOR2=0;
      ip4_ADD_79=0;
      assert(0);
      break;
    }

    // Y1 will bit-wise XORed with every bit of C
    if(ip1_EXOR2 == 1) {
      ip1_EXOR2 = (ones & 0x1f);
    }

    assert(ip2_EXOR1 < (1 << 4));
    ip1_EXOR1 = ADD_mod32(ip1_ADD_32, ip2_ADD_32); // (X + A) mod 32
    ip1_PERM  = EXOR_5(ip1_EXOR1, ip2_EXOR1); //  ip1_EXOR xor B
    ip2_PERM  = EXOR_5(ip1_EXOR2, ip2_EXOR2); // (Y1 extended) xor C
    ip1_ADD_79 = PERM(ip1_PERM, ip2_PERM, ip3_PERM); // PERM(ip1_PERM, ip2_PERM, D)

    aindex = ADD_mod79(ip1_ADD_79, ip2_ADD_79, ip3_ADD_79, ip4_ADD_79); // ip1_ADD_79, E, F, Y2
    freq = mappedFreq(aindex);

    //TRACE_BT(LEVEL_INQPG, "clk 0x%x, addr 0x%x\n", clk, addr);
    // TRACE_BT(LEVEL_INQPG, "ip1_ADD_32 %d ip2_ADD_32 %d, ip1_EXOR1 %d, ip1_PERM %d, ip2_PERM %d, ip1_ADD_79 %d, i %d, f %d\n",
    //ip1_ADD_32, ip2_ADD_32, ip1_EXOR1, ip1_PERM, ip2_PERM, ip1_ADD_79, aindex, freq);

    cache_init(&bb.cache_[fh_seq], clk, clk_frozen, fh_seq, addr, bb.tdd_state_,
	       bb.nsr_, bb.nmr_, bb.train_type_, bb.nfhs_, freq);

#ifdef FH_KERNEL_DEBUG
    dbg(DBG_BT, "FH_kernel, aindex = %d, result = %d\n", aindex, freq);
#endif
    return freq;
  }


  /* **********************************************************************
   * updateRecvFreq
   * *********************************************************************/
  /**
   * updateRecvFreq.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void updateRecvFreq() {
    int clocka;
    int clockf;
    int address;
    enum fhsequence_t hop_type;

    if(bb.state_ == STANDBY)
      return;

    switch (bb.state_) {
    case PAGE_SCAN:
      clocka = bb.clkn_;
      clockf = bb.clkf_;//@GT 12/08
      address = bb.bd_addr_;
      hop_type = page_scan;
      break;
    case PAGE:
      clocka = bb.clke_;
      clockf = bb.clkf_;//@GT 12/08
      address = bb.page_addr_;
      hop_type = page_hopping;
      break;
    case SLAVE_RESP:
      clocka = bb.clkn_;
      clockf = bb.clkf_;
      address = bb.bd_addr_;
      hop_type = slave_response;
      break;
    case MASTER_RESP:
      clocka = bb.clke_;
      clockf = bb.clkf_;
      address = bb.page_addr_;
      hop_type = master_response;
      break;
    case INQUIRY:
      clocka = bb.clkn_;
      clockf = bb.clkf_;
      address = bb.giac_;
      hop_type = inquiry_hopping;
      break;
    case INQ_SCAN:
      clocka = bb.clkn_;
      clockf = bb.clkf_;
      address = bb.giac_;
#ifndef VER_11
      hop_type = (bb.freeze_) ? inquiry_response : inquiry_scan;
#else
      hop_type = inquiry_scan; //@GT 10/07
#endif
      break;
    case INQ_RESP:
      clocka = bb.clkn_;
      clockf = bb.clkf_;
      address = bb.giac_;
      hop_type = inquiry_response;
      break;
    case CONNECTION:
      if(currentRole() == AS_MASTER) {
	clocka = bb.clkn_;
	address = bb.bd_addr_;
      }
      else {
	clocka = bb.master_clk_;
	address = bb.master_addr_;
      }
      clockf = clocka;
      hop_type = channel_hopping;
      break;
    case STANDBY:
    case SLAVE_RESP_ID_SENT:
    case NUM_STATE:
      assert(0); //not implemented or impossible
    default:
      assert(0); //impossible
      //shut up warnings
      clocka = bb.clkn_;
      clockf = bb.clkf_;
      address = bb.bd_addr_;
      hop_type = page_scan;
    }


    if(bb.recv_freq_ != InvalidFreq) {
      call BTFHChannel.removeFromChannel(bb.recv_freq_, NODE_NUM);
    }

    bb.recv_freq_ = FH_kernel(clocka, clockf, hop_type, address);
    call BTFHChannel.addToChannel(bb.recv_freq_, NODE_NUM);
    //TRACE_BT(LEVEL_TMP, "_%d_ LISTEN FREQ %d STATE %s CLOCK 0x%x CLOCKF 0x%x HOP %d ADDR %d\n",
    // bd_addr(), recv_freq_, StateTypeStr[getState()], clock, clockf, hop_type, address);
  }

  /* **********************************************************************
   * changeState
   * *********************************************************************/
  /**
   * Change the current state.
   *
   * @param state The state to change to.
   * @param addr If addr != 1, ADDR is used to print out stats. */
  void changeState(enum state_t state, btaddr_t addr) {
    long long clocka = tos_state.tos_time;
    enum state_t old_state = bb.state_;
    if(state == bb.state_ && addr == InvalidAddr)
      return;

    bb.state_ = state;
    //NS stuff, unused
    //           if (nam_trace_) {
    //                BTNodeTrace* ns = (BTNodeTrace*)downtarget_;
    //                // inform the nam trace object about state change
    //                // old state required for back-trace in nam
    //                ns->changeNodeColor(state, old_state);
    //           }

    switch(state) {
    case INQUIRY:
      bb.tx_clock_ = CLKN;
      break;
    case SLAVE_RESP:
      bb.tx_clock_ = CLK;
      break;
    case CONNECTION:
      if(currentRole() == AS_SLAVE)
	bb.tx_clock_ = CLK;
      else
	bb.tx_clock_ = CLKN;
      break;
    default:
      break;
    }

    bb.tdd_state_ = IDLE;

    addr = (addr == InvalidAddr) ? bb.curr_piconet_ : addr;
    if(bb.prev_clk_ >= 0) {
      TRACE_BT(LEVEL_MED, "%s  _%d_ (%d) STATE %s LASTED %10lld NEXT %s\n", TraceAcctStr, bb.bd_addr_, addr,
	       StateTypeStr[old_state], (clocka - bb.prev_clk_), StateTypeStr[bb.state_]);
      updateTimeSpent(old_state, clocka - bb.prev_clk_, addr);
    }

    bb.prev_clk_ = clocka;
    if(state != old_state) {
      TRACE_BT(LEVEL_STATE, "_%d_ (%d) CHANGING STATE %s -> %s, prev %s next %s prog %s\n",
	       bb.bd_addr_, addr, StateTypeStr[old_state], StateTypeStr[bb.state_],
	       StateTypeStr[bb.prev_state_], StateTypeStr[bb.next_state_], ProgTypeStr[bb.state_prog_]);
    }

    if(bb.state_ != CONNECTION)
      bb.curr_lid_ = InvalidLid;
  }


  /* **********************************************************************
   * saveAndChangeState
   * *********************************************************************/
  /**
   * Save and change state.
   *
   * <p>Save the current state (in bb.prev_state) and change to another (by calling
   * <code>changeState</code>.</p>
   *
   * @param state The state to change to. */
  void saveAndChangeState(enum state_t state) {
    assert(bb.prev_state_ != STANDBY || bb.state_ == STANDBY || bb.state_ == CONNECTION);

    // We need to cancel the current state by not setting
    // prev_state, otherwise we would override prev_state_.  The
    // rule is to make a special case for CONNECTION which does
    // not happen periodically and is the default state.
    if(bb.prev_state_ != CONNECTION)
      bb.prev_state_ = bb.state_; // BUG-4 fix: cancel the current state
    changeState(state, InvalidAddr);
  }

  /* **********************************************************************
   * getPnetAttr
   * *********************************************************************/
  /* **********************************************************************
   * getPnetAttr
   * *********************************************************************/
  /**
   * getPnetAttr.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  struct con_attr* getPnetAttr(btaddr_t pnet) {
    if(pnet != bb.bd_addr_) {
      return bb.piconet_attr_[pid2lid(pnet)];
    }
    else {
      return &bb.my_piconet_attr_;
    }
  }


  /* **********************************************************************
   * switchPiconet
   * *********************************************************************/
  // Switch to NEXT piconet. Hold off the current piconet if necessary.
  /* **********************************************************************
   * switchPiconet
   * *********************************************************************/
  /**
   * switchPiconet.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void switchPiconet(btaddr_t nexta) {
    if(bb.curr_piconet_ != InvalidAddr) {
      if(getPnetAttr(bb.curr_piconet_)->mode == Hold) {
	switchFHInputs(nexta);
      }
      else {
	if(getPnetAttr(bb.curr_piconet_)->mode == Active) {
	  //if(!gUsingTSS)
	  holdPiconet(bb.curr_piconet_, PICONET_HOLD_TIME);
	  //else {
	  //	TRACE_BT(LEVEL_HIGH, "_%d_ FAILED cur %d next %d %s\n",
	  //		  bd_addr(), bb.curr_piconet_, nexta, ProgTypeStr[call BTBaseband.getSessionInProg()]);
	  //	assert(0);
	  //}
	}
	switchFHInputs(nexta);
      }
    }
    else {
      switchFHInputs(nexta);
    }
  }


  /* **********************************************************************
   * switchFHInputs
   * *********************************************************************/
  /**
   * switchFHInputs.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void switchFHInputs(btaddr_t piconet_no) {
    TRACE_BT(LEVEL_STATE, "BD_ADDR %d SWITCHING TO PICONET %d PARAMETERS\n", bb.bd_addr_, piconet_no);

    bb.tdd_state_ = IDLE;
    bb.curr_piconet_ = piconet_no;
    if(piconet_no != bb.bd_addr_) {
      bb.piconet_attr_[pid2lid(piconet_no)]->mode = Active;
      bb.master_addr_ = bb.piconet_attr_[pid2lid(piconet_no)]->master_addr;
      bb.master_clk_ = bb.piconet_attr_[pid2lid(piconet_no)]->mclk;
      bb.tx_clock_ = CLK;
    }
    else {
      bb.my_piconet_attr_.mode = Active;
      bb.tx_clock_ = CLKN;
    }
  }


  /* **********************************************************************
   * btmode
   * *********************************************************************/
  /**
   * btmode.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  enum btmode btmode(linkid_t lid) {
    if(call BTBaseband.isMasLink(lid))
      return call BTScheduler.mode(lid);
    return bb.piconet_attr_[lid]->mode;
  }


  // Hold the link with LID for INTV ticks, i.e. from now until the master clock
  // reached MCLK+INTV.  BRECV is TRUE if this node received the ACCEPTED pkt and thus,
  // needed to send back ACK.
  /* **********************************************************************
   * BTBaseband.holdLink
   * *********************************************************************/
  /**
   * BTBaseband.holdLink.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.holdLink(linkid_t lid, int intv, int mclk, bool bRcvd) {
    int i, ticks;
    TRACE_BT(LEVEL_LOW, "_%d_ BTBaseband::holdLink CLKN %-5d %-5s %-5d\n", bb.bd_addr_, bb.clkn_,
	     btmodeStr[bb.my_piconet_attr_.mode], bb.my_piconet_attr_.hold_time);
    for(i= MaxNumSlaves; i < MaxNumLinks; i++) {
      if(bb.piconet_attr_[i]) {
	TRACE_BT(LEVEL_LOW, "\tPNET %-2d %-5s %-5d\n",
		 lid2pid(i), btmodeStr[bb.piconet_attr_[i]->mode], bb.piconet_attr_[i]->hold_time);
      }
    }

    assert(bb.curr_piconet_ == lid2pid(lid));
    assert(btmode(lid) == Active);

    if(bRcvd) {
      long long atime;
      struct sess_switch_data* swe;
      assert(call BTBaseband.isSessionAvail(InvalidLid));
      call BTBaseband.beginSession(HOLD_IN_PROG, 30, NULL);
      // Schedule it until the next even slot so that this node can ack back
      // the last packet received before it puts LID link on hold. This is
      // true for both master and slave.
      atime = SlotTime - (tos_state.tos_time - bb.recv_start_) + 100*usec;
      assert(atime >= 0);

      swe = (struct sess_switch_data*)bb.switch_ev_->data;
      swe->mclkn_ = mclk;
      swe->lid_ = lid;
      swe->b_rcvd_ = FALSE;
      swe->intv_ = intv;
      swe->valid = TRUE;
      event_switch_create(bb.switch_ev_, NODE_NUM, tos_state.tos_time + atime);
      TRACE_BT(LEVEL_MED, "_%d_ Scheduling to hold link %d in %lld s; cur %d next %d.\n",
	       bb.bd_addr_, lid, atime, bb.curr_piconet_, bb.next_piconet_);
      return;
    }

    ticks = mclk - call BTBaseband.mclkn(lid) + intv;
    if(call BTBaseband.isMasLink(lid)) {
      call BTScheduler.hold(lid, ticks, bb.clkn_);
      if(call BTScheduler.numLinks(Active) == 0) {
	changeState(STANDBY, lid2addr1(lid));
	holdPiconet(bb.bd_addr_, call BTScheduler.tillNextActiveLink(bb.clkn_, NULL));
      }
      else {
	changeState(CONNECTION, lid2addr1(lid));
      }
    }
    else {
      changeState(STANDBY, lid2addr1(lid));
      holdPiconet(lid2addr1(lid), ticks);
    }
    if(call BTBaseband.getSessionInProg() == HOLD_IN_PROG)
      call BTBaseband.endSession(HOLD_IN_PROG);
    signal BTHostSig.hciModeChangeEvent(lid, TRUE, Hold, ticks);
  }


  /* **********************************************************************
   * linkHoldExpires
   * *********************************************************************/
  /**
   * linkHoldExpires.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void linkHoldExpires(linkid_t lid, bool bSuccess) {
    TRACE_BT(LEVEL_MED, "_%d_ LINK %d HOLD EXPIRES CLKN %d\n", bb.bd_addr_, lid, bb.clkn_);
#ifdef HOLD_LINK_FOREVER
    if(call BTBaseband.isMasLink(lid)) {
      TRACE_BT(LEVEL_MED, "_%d_ GT_HACK: HOLDING MAS LINK %d FOREVER\n", bd_addr(), lid);
      call BTBaseband.holdLink(lid, MaxHoldTime * 100, clkn(), FALSE);
      return;
    }
#endif
    if(bSuccess) {
      changeState(CONNECTION, InvalidAddr);
      if(call BTBaseband.isMasLink(lid)) {
	call BTScheduler.holdExpires(lid);
      }
      bb.curr_lid_ = lid;
      signal BTHostSig.hciModeChangeEvent(lid, TRUE, Active, 0);
    }
    else {
      signal BTHostSig.hciHoldExpiredEvent(lid);
    }
  }


  /* **********************************************************************
   * resetPolledStates
   * *********************************************************************/
  /**
   * resetPolledStates.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void resetPolledStates() {
    bb.polled_ = 0;
    //bb.reply_slot_ = 0;
  }


  // The hold timer has expired for NEXT piconet. We need to hold the current piconet
  // and switch it to NEXT if possible.
  /* **********************************************************************
   * holdExpires
   * *********************************************************************/
  /**
   * holdExpires.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  bool holdExpires(btaddr_t nexta, linkid_t lid) {
    bool bResult = TRUE;
    TRACE_BT(LEVEL_LOW, "BD_ADDR %d PICONET %d HOLD TIMER EXPIRED, cur %d %s\n",
	     bb.bd_addr_, nexta, bb.curr_piconet_, ProgTypeStr[call BTBaseband.getSessionInProg()]);
    if(bb.state_ != CONNECTION && bb.state_ != STANDBY)
      bResult = FALSE; // let scan finish first
    else if(call BTBaseband.getSessionInProg() != NONE_IN_PROG) // some session in Connection mode
      bResult = FALSE;
    else if(bb.new_connection_timer_) //this is like a session
      bResult = FALSE;
    if(bResult) {
      resetPolledStates();
      if(bb.curr_piconet_ != nexta && bb.curr_piconet_ != InvalidAddr) {
	switchPiconet(nexta);
      }
      else {
	switchFHInputs(nexta);
      }
      linkHoldExpires(lid, TRUE);
    }
    else {
      if(call BTBaseband.getSessionInProg() == SCHED_IN_PROG || call BTBaseband.getSessionInProg() == HOLD_IN_PROG) {
	TRACE_BT(LEVEL_LOW, "_%d_ %s: RETRY\n", bb.bd_addr_, ProgTypeStr[call BTBaseband.getSessionInProg()]);
      }
      else {
	linkHoldExpires(lid, FALSE);
      }
    }
    return bResult;
  }


  // Hold PNET piconet for HOLD_TIME. If the piconet is already on hold,
  // the timer is not updated. If NEXT_STATE is one of the scan states,
  // switch from the current state.
  /* **********************************************************************
   * holdPiconet
   * *********************************************************************/
  /**
   * holdPiconet.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void holdPiconet(btaddr_t pnet, int hold_time) {
    bool bUpdate = TRUE;
    TRACE_BT(LEVEL_LOW, "_%d_ Baesband::holdPiconet PNET %d\n", bb.bd_addr_, pnet);

    if (bb.next_state_ == PAGE_SCAN || bb.next_state_ == INQ_SCAN) {
      enum state_t cur = bb.next_state_;
      bb.tdd_state_ = IDLE;
      bb.prev_state_ = bb.state_;
      bb.next_state_ = CONNECTION;
      changeState(cur, InvalidAddr);
      if(cur == PAGE_SCAN) {
	bb.pagescan_timer_ = 0;
      }
      else if(cur == INQ_SCAN) {
	bb.inqscan_timer_ = 0;
      }
      if(pnet == InvalidPiconetNo || getPnetAttr(pnet)->mode == Hold)
	bUpdate = FALSE;
    }
    if(bUpdate && pnet != InvalidPiconetNo) {
      if (hold_time < 1)
	hold_time = 1;

      updateHoldTimer(getPnetAttr(pnet), hold_time);
      if(pnet != bb.bd_addr_) // slave
	resetPolledStates();
    }

    if(pnet == bb.curr_piconet_) {
      bb.curr_piconet_ = InvalidPiconetNo;
    }
  }


  /* **********************************************************************
   * resetState
   * *********************************************************************/
  /**
   * resetState.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void resetState() {
    // a new link has been created or deleted
    if(bb.num_acl_links_ <= 0 && bb.num_piconets_ <= 0) {
      bb.prev_state_ = STANDBY;
      changeState(STANDBY, InvalidAddr);
    }
    else {
      changeState(CONNECTION, InvalidAddr);
    }
  }


  /* **********************************************************************
   * reduceScatCount
   * *********************************************************************/
  /**
   * reduceScatCount.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void reduceScatCount() {
    if(bb.prev_scat_id_ != bb.scat_id_) {
      bb.scat_id_ = bb.prev_scat_id_;
      gScatCount++;
    }
  }


  /* **********************************************************************
   * updateScatCount
   * *********************************************************************/
  /**
   * updateScatCount.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void updateScatCount(struct baseband* n1, struct baseband* n2) {
    if(n2->scat_id_ < n1->scat_id_) {
      int i;
      int oldScat = n1->scat_id_;
      n1->prev_scat_id_ = oldScat;
      n1->scat_id_ = n2->scat_id_;
      if(gScatCount > 0) gScatCount--;

      for(i = 0; i < bbs_length; i++) {
	if(bbs[i]->scat_id_ == oldScat) {
	  bbs[i]->prev_scat_id_ = bbs[i]->scat_id_; // this is prob unnecess
	  bbs[i]->scat_id_ = n2->scat_id_;
	}
      }
    }
    else {
      n1->prev_scat_id_ = n1->scat_id_; // n1 wins, so write its own id
    }
  }


  /*****************************************************************************
   *                             Session related functions
   ****************************************************************************/

  /* **********************************************************************
   * cancel
   * *********************************************************************/
  /**
   * cancel.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void cancel(enum timer_t type) {
    assert(type == INQ_SCAN_TM || type == PAGE_SCAN_TM || type == PAGE_TM || type == INQ_TM || type == HOST_TM);
    bb.tms_[type].valid = FALSE;

    switch(type) {
    case INQ_SCAN_TM:
      if(call BTBaseband.getSessionInProg() != NONE_IN_PROG)
	handleInqRespTO();
      else
	call BTBaseband.endScan(INQ_SCAN);
      break;
    case PAGE_SCAN_TM:
      if(call BTBaseband.getSessionInProg() == PAGE_IN_PROG) {
	handlePageRespTO();
	assert(!bb.new_connection_timer_);
      }
      else
	call BTBaseband.endScan(PAGE_SCAN);
      break;
    case PAGE_TM:
      assert(call BTBaseband.getSessionInProg() == NONE_IN_PROG);
      break;
    case INQ_TM:
      assert(call BTBaseband.getSessionInProg() == NONE_IN_PROG);
      if(bb.state_ == INQUIRY)
	/* Since we are cancelling, don't do a callback */
	inquiryComplete(bb.prev_state_, FALSE);
      break;
    }
  }


  /* **********************************************************************
   * BTBaseband.getSessionInProg
   * *********************************************************************/
  /**
   * BTBaseband.getSessionInProg.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command enum state_progress_t BTBaseband.getSessionInProg() {
    if(bb.state_prog_ != NONE_IN_PROG)
      return bb.state_prog_;
    else if(bb.b_switch_)
      return SWITCH_IN_PROG;
    else if(bb.new_connection_timer_)
      return NEW_CONN_IN_PROG;
    return bb.state_prog_;
  }


  // Change state progress
  /* **********************************************************************
   * changeProg
   * *********************************************************************/
  /**
   * changeProg.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void changeProg(enum state_progress_t prog) {
    TRACE_BT(LEVEL_FUNCTION, "_%d_ CHANGING SESSION PROGRESS: %s -> %s\n",
	     bb.bd_addr_, ProgTypeStr[bb.state_prog_], ProgTypeStr[prog]);
    bb.state_prog_ = prog;
  }


  /* **********************************************************************
   * scan
   * *********************************************************************/
  /**
   * Perform inquiry or page scan.
   *
   * <p>TODO: I think this procedure starts a scan, that is, sets the baseband in
   * scan mode. I have no idea what the actual consequenses are...</p>
   *
   * @param scan_state one of INQ_SCAN or PAGE_SCAN
   * @return wheter the scan mode was changed succesfully */
  command bool BTBaseband.scan(enum state_t scan_state) {
    enum timer_t tm = (scan_state == INQ_SCAN) ? INQ_SCAN_TM : PAGE_SCAN_TM;
    TRACE_BT(LEVEL_TIMER, "_%d_ %s TIMER EXPIRED. state %s, prog %s\n",
	     bb.bd_addr_, StateTypeStr[scan_state], StateTypeStr[bb.state_], ProgTypeStr[bb.state_prog_]);
    
    if(bb.state_prog_ != NONE_IN_PROG || (bb.state_ != CONNECTION && bb.state_ != STANDBY))
      return FALSE;
    
    assert(scan_state == INQ_SCAN || scan_state == PAGE_SCAN);
    assert(bb.state_ != scan_state);
    
    if (bb.state_ == CONNECTION) {
      //TRACE_BT(LEVEL_LOW, "BD_ADDR %d PUTTING PICONET %d ON HOLD FOR %s FOR %d ticks.\n",
      //	  bd_addr_, curr_piconet_, StateTypeStr[scan_state], MinHoldTime);
      bb.next_state_ = scan_state;
      holdPiconet(bb.curr_piconet_, bb.tms_[tm].window + 2);
    }
    else {
      saveAndChangeState(scan_state);
    }
    signal BTHostSig.hciCommandStatusEvent(tm2hci(tm), TRUE);
    return TRUE;
  }


  // End the scan started with scan()
  /* **********************************************************************
   * endScan
   * *********************************************************************/
  /**
   * End the scan started with scan.
   *
   * <p>TODO: Ends the scan started with scan by...</p>
   *
   * @param state one of INQ_SCAN and PAGE_SCAN */
  command void BTBaseband.endScan(enum state_t state) {
    assert(state == INQ_SCAN || state == PAGE_SCAN);
    if ((state == bb.state_ && bb.state_ == INQ_SCAN && !bb.freeze_) || bb.state_ == PAGE_SCAN) {
      changeState(STANDBY, InvalidAddr);
      if(bb.state_ == PAGE_SCAN)
	changeProg(NONE_IN_PROG);
    }
  }


  /* **********************************************************************
   * BTBaseband.beginSession
   * *********************************************************************/
  /**
   * BTBaseband.beginSession.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.beginSession(enum state_progress_t prog, int ticks, struct LMP* lmp) {
    TRACE_BT(LEVEL_LOW, "_%d_ BEGIN SESSION: %s %d ticks\n",
	     bb.bd_addr_, ProgTypeStr[prog], ticks);

    assert(bb.state_prog_ == NONE_IN_PROG);

    changeProg(prog);
    ((struct sess_ev_data*)(bb.sess_ev_->data))->lmp = lmp;
    ((struct sess_ev_data*)(bb.sess_ev_->data))->prog_ = prog;
    ((struct sess_ev_data*)(bb.sess_ev_->data))->valid = TRUE;
    event_sess_create(bb.sess_ev_, NODE_NUM, tos_state.tos_time + ticks*ClockTick);
    TOS_queue_insert_event(bb.sess_ev_);
  }


  /* **********************************************************************
   * BTBaseband.endSession
   * *********************************************************************/
  /**
   * BTBaseband.endSession.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.endSession(enum state_progress_t prog) {
    TRACE_BT(LEVEL_LOW, "_%d_ END SESSION: %s\n", bb.bd_addr_, ProgTypeStr[prog]);

    assert(bb.state_prog_ == prog);

    changeProg(NONE_IN_PROG);

    ((struct sess_ev_data*)(bb.sess_ev_->data))->valid = FALSE;

    if (prog == HOLD_IN_PROG)
      bb.next_piconet_ = -1;

    if(((struct sess_ev_data*)(bb.sess_ev_->data))->lmp)
      call BTLMP.handle(((struct sess_ev_data*)(bb.sess_ev_->data))->lmp);
    ((struct sess_ev_data*)(bb.sess_ev_->data))->lmp = NULL;
  }


  /* **********************************************************************
   * BTBaseband.isSessionAvail
   * *********************************************************************/
  /**
   * BTBaseband.isSessionAvail.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command bool BTBaseband.isSessionAvail(linkid_t lid) {
    if(lid == InvalidLid)
      return bb.state_prog_ == NONE_IN_PROG;
    else
      return (bb.state_prog_ == NONE_IN_PROG) && (lid2pid(lid) == bb.curr_piconet_);
  }


  /* **********************************************************************
   * beginPageRespSession
   * *********************************************************************/
  /**
   * beginPageRespSession.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void beginPageRespSession() {
    assert(call BTBaseband.getSessionInProg() == NONE_IN_PROG);

    call BTBaseband.beginSession(PAGE_IN_PROG, PageRespTO + 6, NULL);

    bb.freeze_ = 1; // freeze the clock

    if(bb.state_ == PAGE_SCAN) {
      // Initiate slave response procedure

      // Page message received, sync to master clock by setting the next
      // transmission event at exactly 625 usec after we started receiving
      // the page ID packet
      bb.clkf_ = bb.clkn_;
      changeState(SLAVE_RESP, InvalidAddr);
      bb.tx_clock_ = CLK;
      bb.newconn_addr_ = InvalidAddr;
      assert(!bb.id_ev_);
      bb.id_ev_ = (event_t*)malloc(sizeof(event_t));
      dbg(DBG_MEM, "malloc id packet event.\n");
      event_id_create(bb.id_ev_, NODE_NUM, tos_state.tos_time + SlotTime - (tos_state.tos_time - bb.recv_start_));
      TOS_queue_insert_event(bb.id_ev_);
    }
    else {
      //Initiate master response procedure.
      assert(bb.state_ == PAGE);

      //Received a valid page response, freeze the estimated clock for rest
      //of the paging procedure.
      bb.clkf_ = bb.clke_;
      changeState(MASTER_RESP, InvalidAddr);
    }
    TRACE_BT(LEVEL_ACCT, "_%d_ BEGIN PAGE RESPONSE SESSION CLKN %d CLKF %d CLKE %d %s\n",
	     bb.bd_addr_, bb.clkn_, bb.clkf_, bb.clke_, StateTypeStr[bb.state_]);
  }


  /* **********************************************************************
   * endPageRespSession
   * *********************************************************************/
  /**
   * endPageRespSession.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void endPageRespSession() {
    call BTBaseband.endSession(PAGE_IN_PROG);

    if(bb.state_ == MASTER_RESP) {
      bb.clke_ = 0;
      bb.nmr_ = 0;
      prepareMasLink();
      bb.newconn_addr_ = bb.page_addr_;
      bb.pageresp_timer_ = 0;
      bb.freeze_ = 0;
    }
    else {
      assert(bb.state_ == SLAVE_RESP && bb.new_connection_timer_);
      TRACE_BT(LEVEL_HIGH, "_%d_ SENDING ID-PKT TO MAS %d IN RESPONSE TO FHS\n",
	       bb.bd_addr_, bb.scanned_addr_);

      if(!bb.id_ev_) {
	// wait until the next slot boundary (see SPEC)
	bb.id_ev_ = (event_t*)malloc(sizeof(event_t));
	dbg(DBG_MEM, "malloc session event.\n");
	event_id_create(bb.id_ev_, NODE_NUM, tos_state.tos_time + SlotTime - (tos_state.tos_time - bb.recv_start_));
	TOS_queue_insert_event(bb.id_ev_);
      }
      bb.pageresp_timer_ = 0;
      // we reset bb.freeze_ in RespIdHandler::handle since the ID packet still needs to use the frozen clock
      bb.newconn_addr_ = bb.scanned_addr_;
    }
  }


  /*****************************************************************************
   *                             link handling
   ****************************************************************************/

  /* **********************************************************************
   * BTBaseband.detach
   * *********************************************************************/
  /**
   * BTBaseband.detach.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.detach(struct LMP* linkq) {
    linkid_t i;
    for(i = 0; i < MaxNumLinks; i++)
      if(linkq == &bb.linkq_[i])
	break;

    if(i < MaxNumSlaves) {
      assert(currentRole() == AS_MASTER);
      delMasterLink(lid2am(i));
    }
    else {
      assert(i < MaxNumLinks);
      assert(bb.curr_piconet_ == bb.link_pids_[i]);

      delSlaveLink(bb.link_pids_[i]);
    }
  }


  /* **********************************************************************
   * BTBaseband.switchSlaveRole
   * *********************************************************************/
  /**
   * BTBaseband.switchSlaveRole.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.switchSlaveRole(amaddr_t am_addr) {
    struct hdr_bt* bt;
    struct fhspayload* fhs;
    float delay;
    // Schedule a FHS packet to be sent to the master
    assert(!bb.vip_pkt_);
    bb.vip_pkt_ = call BTBaseband.allocPkt(BT_FHS, am_addr);
    bt = &(bb.vip_pkt_->bt);

    fhs = (struct fhspayload*)(bt->ph.data);
    fhs->piconet_no = bb.bd_addr_;
    bb.vip_piconet_ = bb.curr_piconet_;

    delay = SlotTime - (tos_state.tos_time - bb.recv_start_) + 10*usec;
    switchRoles(delay, NULL);
  }


  /* **********************************************************************
   * initSlaveLink
   * *********************************************************************/
  /**
   * Initialize a slave link.
   * 
   * <p>Initialize a slave link based on the FHS packet received from
   * the master.</p>
   *
   * <p>Also, the clk clock is created in here.</p>
   * 
   * @param p The FHS packet from the master
   * @param new_conn Wheter or not this is a new connection */
  void initSlaveLink(struct BTPacket* p, bool new_conn) {
    int i;
    struct hdr_bt*  bt = &(p->bt);
    struct fhspayload* fhs;
    btaddr_t addr;
    int clocka;
    btaddr_t piconet_no;
    int linkId;
    long long delay;
    event_t* clk_ev;
    assert(bt->type == BT_FHS);

    fhs = (struct fhspayload*)(bt->ph.data);
    addr = fhs->addr;
    clocka = fhs->clock;
    piconet_no = fhs->piconet_no;

    if(bb.scanned_addr_ != addr && !bb.b_switch_) {
      TRACE_BT(LEVEL_MED, "_%d_ DBG ACCIDENTALLY WE HAVE RECEIVED A DIFFERENT FHS_PKT _"
	       " THAN EXPECTED (during pagescan)addr %d, now %d. DROPPED\n",
	       bb.bd_addr_, bb.scanned_addr_, addr);
      return;
      // if we accept this packet there is a small window where we might
      // recieve this wrong fhs_pkt before we even finish sending the
      // page_ack back to the correct one. we should fix this or propose a
      // modification to the standard if necessary to prevent these
      // situations
      bb.scanned_addr_ = addr;
    }

    for(i = 0; i < MaxNumLinks; i++) {
      if(bb.link_pids_[i] == piconet_no && bb.link_pids_[i] != InvalidAddr) {
	// This rarely happens. It means that two nodes paging are on the
	// same frequency. we should fix this by dropping packets nicely.
	// this unexpected fhs packet from a node (which we already have
	// connection to) so just return;
	return;
      }
    }

    // FHS packet received from the master, send a packet 625usec after we
    // started receiving the packet
    if(new_conn) {
      bb.new_connection_timer_ = NewConnectionTimeout;
      bb.b_connect_as_master_ = FALSE;
    }

    bb.tx_clock_ = CLK;
    bb.num_piconets_++;

    linkId = newLid();
    delay = SlotTime - (tos_state.tos_time - fhs->real_time);
    if(delay < 0) {
      clocka += 4; // next even slot
      delay += (2*SlotTime);
    }

    if(linkId >= MaxNumLinks) {
      TRACE_BT(LEVEL_HIGH, "_%d_ MAX NUMBER OF SLAVE LINKS HAVE REACHED!\n", bb.bd_addr_);
      bb.max_scan_period_ = bb.clkn_ + 2;
      return;
    }

    bb.link_pids_[linkId] = piconet_no;

    // bb.piconet_attr_[linkId] = (struct con_attr*)malloc(sizeof(struct con_attr));
    bb.piconet_attr_[linkId] = new_conn_attr();
    dbg(DBG_MEM, "new con_attr.\n");

    bb.master_addr_ = bb.piconet_attr_[linkId]->master_addr = addr;
    bb.master_clk_ = bb.piconet_attr_[linkId]->mclk = clocka + 1; //GT plus 1 here and another 1 in CLKHandler for odd slot

    bb.piconet_attr_[linkId]->mode = Active;

    call BTLinkController.Initialize(&bb.lc_[linkId]); // Initialize LC so that SEQN are reset!

    // Remain active in the new initialized piconet by switch to it if necessary
    switchPiconet(piconet_no);

    clk_ev = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc clk event.\n");
    /* Start the clk clock */
    event_clk_create(clk_ev, NODE_NUM, tos_state.tos_time + delay, piconet_no);
    TOS_queue_insert_event(clk_ev);
    bb.piconet_attr_[linkId]->clk_ev_ = clk_ev;

    bb.polled_ = 0;

    updateScatCount(&bb, findBbs(addr));
  }


  /* **********************************************************************
   * delSlaveLink
   * *********************************************************************/
  /**
   * delSlaveLink.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void delSlaveLink(btaddr_t piconet_no) {
    int linkId;
    int addr;
    bb.num_piconets_--;
    linkId = pid2lid(piconet_no);
    addr = lid2addr(linkId, TRUE);
    bb.link_pids_[linkId] = InvalidPiconetNo;

    TRACE_BT(LEVEL_ACCT, "%s _%d_ DISCONNECTED: MAS %d-%d SLV\n",
	     TraceAcctStr, bb.bd_addr_, addr, lid2addr(linkId, FALSE));

    bb.piconet_attr_[linkId]->clk_ev_->data = (void*)InvalidPiconetNo;
    bb.piconet_attr_[linkId] = NULL; //its freed when its triggered

    bb.curr_piconet_ = InvalidAddr; // just invalidate and wait until other timers expire
    bb.tx_clock_ = CLKN;

    if(bb.num_acl_links_ <= 0 && bb.num_piconets_ <= 0)
      bb.prev_state_ = STANDBY;

    assert(call BTBaseband.getSessionInProg() == NONE_IN_PROG || call BTBaseband.getSessionInProg() == HOST_IN_PROG ||
	   call BTBaseband.getSessionInProg() == SCHED_IN_PROG || call BTBaseband.getSessionInProg() == SWITCH_IN_PROG);

    changeState(STANDBY, InvalidAddr); // don't use addr since this link has been destroyed
    reduceScatCount();
    call BTLMP.linkDestroyed(&bb.linkq_[linkId], FALSE);

    call BTLinkController.Initialize(&bb.lc_[linkId]);
  }

  
  /* **********************************************************************
   * prepareSlvLink
   * *********************************************************************/
  /**
   * prepareSlvLink.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void prepareSlvLink() {
    changeState(CONNECTION, InvalidAddr);
    updateRole(AS_SLAVE);
  }


  /* **********************************************************************
   * prepareMasLink
   * *********************************************************************/
  /**
   * prepareMasLink.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void prepareMasLink() {
    assert(bb.bd_addr_ != InvalidAddr);
    //master_index_ = pid() + 1;
    bb.curr_piconet_ = bb.bd_addr_;
    changeState(CONNECTION, InvalidAddr);
    bb.new_connection_timer_ = NewConnectionTimeout;
    bb.b_connect_as_master_ = TRUE;
    updateRole(AS_MASTER);
  }


  /* **********************************************************************
   * linkEstablished
   * *********************************************************************/
  /**
   * linkEstablished.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void linkEstablished(linkid_t lid) {
    if(bb.b_switch_) {
      call BTLMP.roleChanged(&bb.linkq_[lid], call BTBaseband.isMasLink(lid));
    }
    else {
      call BTLMP.linkEstablished(&bb.linkq_[lid], call BTBaseband.isMasLink(lid));
    }
  }


  /* **********************************************************************
   * detach
   * *********************************************************************/
  /**
   * detach.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void detach(struct LMP* linkq) {
    linkid_t i = 0;
    for(i = 0; i < MaxNumLinks; i++)
      if(linkq == &bb.linkq_[i])
	break;

    if(i < MaxNumSlaves) {
      assert(currentRole() == AS_MASTER);
      delMasterLink(lid2am(i));
    }
    else {
      assert(i < MaxNumLinks);
      assert(bb.curr_piconet_ == bb.link_pids_[i]);
      delSlaveLink(bb.link_pids_[i]);
    }
  }


  /* **********************************************************************
   * initMasterLink
   * *********************************************************************/
  /**
   * initMasterLink.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void initMasterLink(amaddr_t am_addr) {
    bb.new_connection_timer_ = 0;
    bb.active_list_[am_addr] = bb.page_addr_;
    bb.num_acl_links_++;
    bb.new_am_addr_ = 0;
    TRACE_BT(LEVEL_HIGH, "POLL_ACK %d-->%d\t\t CLK:  %-10d clock: %10lld PICONET: %d AM_ADDR: %d\n",
	     bb.page_addr_, bb.bd_addr_, bb.clkn_, tos_state.tos_time, bb.bd_addr_, am_addr);

    // create first LMP message to be sent to the new slave. This is also the
    // first packet that is sent using stop and wait ARQ at the link controller
    call BTScheduler.connect(am2lid(am_addr));
    bb.my_piconet_attr_.mode = Active;
    updateScatCount(&bb, findBbs(bb.page_addr_));

    // THIS MUST COME AFTER SCHED->CONNECT!!!!
    linkEstablished(am2lid(am_addr));
  }


  // Delete the master link associated with AM_ADDR since the slave node is no longer active.
  /* **********************************************************************
   * delMasterLink
   * *********************************************************************/
  /**
   * delMasterLink.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void delMasterLink(amaddr_t am_addr) {
    int linkId;
    int addr;
    assert(am_addr > 0  && am_addr < (MaxNumSlaves + 1));

    linkId = am2lid(am_addr);
    addr = lid2addr(linkId, FALSE);
    TRACE_BT(LEVEL_ACCT, "%s _%d_ DISCONNECTED: MAS %d-%d SLV\n", TraceAcctStr,
	     bb.bd_addr_, lid2addr(linkId, TRUE), addr); //lid2addr(linkId, FALSE));

    bb.new_am_addr_ = 0;
    bb.active_list_[am_addr] = InvalidAddr;

    call BTScheduler.disconnect(am2lid(am_addr));

    bb.num_acl_links_--;
    if(bb.num_acl_links_ <= 0) {
      bb.my_piconet_attr_.mode = Disconnected;
    }
    else {
      int hold = call BTScheduler.tillNextActiveLink(bb.clkn_, NULL);
      //if(hold <= 0 && gUsingTSS)
      assert(hold > 0);
      bb.my_piconet_attr_.hold_time = hold;
      bb.my_piconet_attr_.mode = Hold;
    }
    bb.curr_piconet_ = InvalidAddr;

    if(bb.num_acl_links_ <= 0 && bb.num_piconets_ <= 0)
      bb.prev_state_ = STANDBY;

    assert(call BTBaseband.getSessionInProg() == NONE_IN_PROG || call BTBaseband.getSessionInProg() == HOST_IN_PROG ||
	   call BTBaseband.getSessionInProg() == SCHED_IN_PROG || call BTBaseband.getSessionInProg() == SWITCH_IN_PROG);

    changeState(STANDBY, InvalidAddr); // don't use addr since this link has been destroyed
    reduceScatCount();
    call BTLMP.linkDestroyed(&bb.linkq_[am2lid(am_addr)], TRUE);
  }


  /* **********************************************************************
   * BTBaseband.roleChangeInProg
   * *********************************************************************/
  /**
   * BTBaseband.roleChangeInProg.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command void BTBaseband.roleChangeInProg(bool b) {
    bb.b_switch_ = b;
  }


  /* **********************************************************************
   * switchRoles
   * *********************************************************************/
  /**
   * switchRoles.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void switchRoles(long long delay, struct BTPacket* p) {
    btaddr_t mas = InvalidAddr, slv = InvalidAddr;
    linkid_t lid = InvalidLid;
    if(delay > 0) {
      event_t* sw_ev = (event_t*)malloc(sizeof(event_t));
      dbg(DBG_MEM, "switch handler delay event.\n");
      event_rswitch_create(sw_ev, NODE_NUM, tos_state.tos_time + delay);
      TRACE_BT(LEVEL_MED, "_%d_ Scheduling to switch roles in %lld clocks.\n", bb.bd_addr_, delay);
      return;
    }

    if(bb.curr_piconet_ == bb.bd_addr_) {
      // Change role with the slave
      struct hdr_bt* bt;
      assert(p);
      bt = &(p->bt);
      lid = am2lid(bt->am_addr);
      mas = lid2addr(lid, TRUE);
      slv = lid2addr(lid, FALSE);

      delMasterLink(bt->am_addr);
      initSlaveLink(p, TRUE);
      assert(bb.new_connection_timer_); // it can't be the existing connection.
      prepareSlvLink();
    }
    else {
      btaddr_t addr;
      // Change role with the master of curr_piconet_
      lid = pid2lid(bb.curr_piconet_);
      // set page_addr_ so that correct link is formed when initMasterLink is called
      addr = lid2addr1(lid);
      mas = lid2addr(lid, TRUE);
      slv = lid2addr(lid, FALSE);

      delSlaveLink(bb.curr_piconet_);
      bb.page_addr_ = addr;
      prepareMasLink();
    }
    TRACE_BT(LEVEL_HIGH, "_%d_ SWITCHING ROLE: MAS %d <-> %d SLV\n",
	     bb.bd_addr_, mas, slv);
  }


  /*****************************************************************************
   *                             event CREATORS/HANDLERS
   ****************************************************************************/

  // Hand the packet down to the lower layer.
  /* **********************************************************************
   * event_tx_handle
   * *********************************************************************/
  /**
   * event_tx_handle.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_tx_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    struct BTPacket* p;
    struct hdr_bt* bt;
    //TRACE_BT(LEVEL_TMP, "_%d_ GT handle: %s \n", bb.bd_addr_, ptoString(p));

    if(bb.b_stop_)
      return;

    p = (struct BTPacket*)(fevent->data);
    bt = &(p->bt);
    TRACE_BT(LEVEL_PACKET, "_%d_ SEND %s %s %d\n",
	     bb.bd_addr_, ptoString(p),
	     PacketTypeStr[p->ch.ptype], p->ch.uid);
    //           if(bb.trace_)
    //                bb.trace_->recv(COPYP(p), lm_);

    call BTFHChannel.sendUp(p);
    //call free, not cleanup
    free(fevent);
  }


  /* **********************************************************************
   * event_sess_handle
   * *********************************************************************/
  /**
   * event_sess_handle.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_sess_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    if (!((struct sess_ev_data*)(fevent->data))->valid)
      return;

    TRACE_BT(LEVEL_FUNCTION, "_%d_ SESSION TIME OUT %s\n",
	     bb.bd_addr_, ProgTypeStr[((struct sess_ev_data*)(fevent->data))->prog_]);
    call BTBaseband.endSession(((struct sess_ev_data*)(fevent->data))->prog_);
  }


  /* **********************************************************************
   * event_clkn_handle
   * *********************************************************************/
  // Handles all the events synchronized with a CLKN tick (tick =
  // 312.5usec). This is the native clock handler and there is only one
  // instance for each device.

  // clkn is our own real clock, clk is the clock of the master we may
  // be connected to.
  /**
   * Main event handler for the baseband.
   * 
   * <p>Called by the TOS event queue for each and every clock tick
   * (TODO: event more than that?) This is the native clock handler
   * and there is only one instance for each device.</p>
   *
   * <p>clkn is our own real clock, whereas clk is the clock of the
   * master we may be connected to.</p>
   *
   * <p>For each call, some updates of the state is done, then the
   * event is updated to trigger when ClockTick (a tick is 312.5 usec)
   * time have passed, and reinserted into the TOS queue. Then all the
   * different timers are checked and handled.</p>
   * 
   * @param fevent The event as registered in the event queue, and set up by 
   *       <code>event_clkn_create</code>
   * @param state The TOS state */
  void event_clk_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    btaddr_t piconet_no;
    struct con_attr* attr;
    int clkmod4;
    if(bb.b_stop_) {
      free(fevent);
      return;
    }

    piconet_no = (btaddr_t)fevent->data;
    if (piconet_no == InvalidPiconetNo) {
      free(fevent);
      return;
    }

    attr = bb.piconet_attr_[pid2lid(piconet_no)];
    clkmod4 = (++(attr->mclk)) % 4;
    checkWrapAround(&(attr->mclk));

    fevent->time = fevent->time + ClockTick;
    TOS_queue_insert_event(fevent);

    if (attr->mode == Hold) {
      if (--(attr->hold_time) == 0) {
#ifdef HOLD_LINK_FOREVER
	TRACE_BT(LEVEL_MED, "_%d_ TEST: HOLDING PNET %d FOREVER\n", bb.bd_addr(), piconet_no);
	return;
#endif
	if(!holdExpires(piconet_no, pid2lid(piconet_no))) {
	  if(attr->hold_time <= 0)
	    attr->hold_time = Tretry;
	}
      }
      if(attr->mode == Hold)
	return;
    }

    if (piconet_no == bb.curr_piconet_) {
      bb.master_clk_ = attr->mclk;
      updateRecvFreq();
    }
    else {
      return;
    }

    updateTxTimer(CLK);

    // If no packet is being transmitted or received try to transmit one
    if (bb.tdd_state_ == IDLE && bb.tx_clock_ == CLK) {
      // Slave transmissions
      if (bb.state_ == SLAVE_RESP && bb.new_connection_timer_) {
	assert(piconet_no == bb.scanned_addr_);

	// Send ID packet as an ack for the FHS packet recv from master */
	endPageRespSession();
	TRACE_BT(LEVEL_LOW, "_%d_ DBG MASTERCLK mas %d  masclk %d, real masclkn %d\n",
		 bb.bd_addr_, piconet_no, bb.master_clk_, findBbs(piconet_no)->clkn_);
      }
      else if (bb.polled_ && clkmod4 == 2) {
	// if the slave has been polled and clkmod4 corresponds to the start
	// of an odd slot send a response

	if (bb.new_connection_timer_) {
	  // send ack to the 'first' poll packet by the master
	  bb.new_connection_timer_ = 0;
	  sendNULLPacket(attr->am_addr);
	  linkEstablished(pid2lid(piconet_no));
	}
	else if (bb.state_ == CONNECTION) {
	  struct BTPacket* pkt = NULL;
	  if(bb.vip_piconet_ == piconet_no) {
	    // handle the special baseband packet first
	    pkt = bb.vip_pkt_;
	    bb.vip_piconet_ = InvalidAddr;
	    bb.vip_pkt_ = NULL;
	  }

	  if(!pkt) {
	    int lid = pid2lid(piconet_no);
	    // if hold_in_prog, it must be a one-slot packet
	    pkt = call BTLinkController.send(&bb.lc_[lid], call BTBaseband.getSessionInProg() == HOLD_IN_PROG ? 1 : -1);
	  }

	  if (pkt)
	    sendPacket(pkt);
	  else
	    sendNULLPacket(attr->am_addr);
	}
	// replied to poll from master hence reset polled
	resetPolledStates();
      }
      else if (!bb.polled_ && clkmod4 == 2) {
	// The link is active. Let the host know that a poll has been missed.
	signal BTHostSig.pollMissed(pid2lid(piconet_no));
      }
    }
  }


  /* **********************************************************************
   * event_clkn_handle
   * *********************************************************************/
  // Handles all the events synchronized with a CLKN tick (tick =
  // 312.5usec). This is the native clock handler and there is only one
  // instance for each device.

  // MADS: I think this is important.
  // Called for each and every clock tick, main handler for clock, something like that.
  // clkn is our own real clock, clk is the clock of the master we may be connected to.
  /**
   * Main event handler for the baseband.
   * 
   * <p>Called by the TOS event queue. This is the native clock handler and there is only one 
   * instance for each device.</p>
   *
   * <p>clkn is our own real clock, whereas clk is the clock of the master we may be
   * connected to.</p>
   *
   * <p>For each call, some updates of the state is done, then the event is updated
   * to trigger when ClockTick (a tick is 312.5 usec) time have passed, and
   * reinserted into the TOS queue. Then all the different timers are checked and
   * handled.</p>
   * 
   * @param fevent The event as registered in the event queue, and set up by 
   *       <code>event_clkn_create</code>
   * @param state The TOS state */
  void event_clkn_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    int clkmod4;
    /* Sanity check - we only want the event we anticipate */
    assert(fevent == bb.clkn_ev_);

    if(bb.b_stop_) {
      free(fevent);
      bb.clkn_ev_ = NULL;
      return;
    }

    bb.clkn_++;
    if (bb.clke_)
      bb.clke_++;

    checkWrapAround(&bb.clkn_);
    checkWrapAround(&bb.clke_);

    clkmod4 = bb.clkn_ % 4;
    if(clkmod4 == 0)
      bb.last_even_tick_ = tos_state.tos_time;

    /* Update and insert the event into the TOS queue again */
    fevent->time = fevent->time + ClockTick;
    TOS_queue_insert_event(fevent);

    if(bb.my_piconet_attr_.mode == Hold) {
      if (--bb.my_piconet_attr_.hold_time == 0) {
	int lid = 0;
	int hold = call BTScheduler.tillNextActiveLink(bb.clkn_, &lid);
	if(hold <= 0) {
	  if(!holdExpires(bb.bd_addr_, lid)) {
	    if(bb.my_piconet_attr_.hold_time <= 0)
	      bb.my_piconet_attr_.hold_time = Tretry;
	  }
	}
	else {
	  bb.my_piconet_attr_.hold_time = hold;
	}
      }
      assert(bb.my_piconet_attr_.hold_time >= 0);
    }

    // Handle timer events
    if (bb.tms_[HOST_TM].valid && ((--bb.host_timer_) == 0)) {
      signal BTHostSig.hci2HostTimerExpiredEvent();
    }

    // Timers common to master and slaves
    if (bb.pageresp_timer_) {
      if (bb.state_ == MASTER_RESP && clkmod4 == 0)
	bb.nmr_++;
      else if (bb.state_ == SLAVE_RESP) {
	if (bb.nsr_ == 0) {
	  bb.nsr_ = 1;
	  bb.nsr_incr_offset_ = clkmod4;
	}
	else if (clkmod4 == bb.nsr_incr_offset_)
	  bb.nsr_++;
      }
    }

    // Timers used by the master
    if (bb.role_ & AS_MASTER == AS_MASTER) {

      /* INQUIRY */
      if (bb.state_ == INQUIRY && --bb.inq_timer_ == 0) {
	dbg(DBG_USR2, "Inquiry Complete, bb.inq_timer = %d\n", bb.inq_timer_); 
	// Inquiry scan complete
	// Send results to host and restore previous state.
	inquiryComplete(bb.prev_state_, TRUE);
	assert(call BTBaseband.getSessionInProg() == NONE_IN_PROG);
      }

      /* STANDBY */
      if (bb.tms_[INQ_TM].valid && bb.state_ == STANDBY && bb.inq_timer_ > 0) {
	// Time to start an Inquiry scan (Mads: Scan???)
	saveAndChangeState(INQUIRY);
	signal BTHostSig.hciCommandStatusEvent(HCI_INQ, TRUE);
      }

      /* PAGE */
      if (bb.state_ == PAGE && --bb.page_timer_ == 0) {
	// Page timeout happens. Let host know about the unsuccessful connection establishment.
	initInqPageParam();
	changeState(bb.prev_state_, InvalidAddr);

	changeProg(NONE_IN_PROG);
	signal BTHostSig.hciConnectionCompleteEvent(-1, TRUE);
      }
    } //master

    // Timers used by slaves
    if(bb.role_ & AS_SLAVE) {
      // Timeouts related to inquiry scan and page scan
      if (bb.tms_[INQ_SCAN_TM].valid && ++bb.inqscan_timer_ == bb.tms_[INQ_SCAN_TM].window) {
	// A short inquiry scan has been done so schedule the inquiry scan event
	// to happen in next TinqScan ticks.
	bb.inqscan_timer_ = -bb.tms_[INQ_SCAN_TM].period; //-TinqScan;
	call BTBaseband.endScan(INQ_SCAN);
	signal BTHostSig.hciScanCompleteEvent(INQ_SCAN_TM, FALSE);
      }

      if (bb.tms_[PAGE_SCAN_TM].valid && ++bb.pagescan_timer_ == bb.tms_[PAGE_SCAN_TM].window) {
	// A short page scan has been done so schedule the page scan event
	// to happen in next TpageScan ticks.
	if (bb.state_ == PAGE_SCAN) {
	  // If a PAGE_RESP session has begun, we let it proceed. If no successful connection
	  // happens, handleNewConnectionTO will be called. OTH, we do, however, stop the scanning
	  // even if the node is in INQ_RESP state. This because SCANNING is part of the
	  // INQ_RESP session that lasts until inqresp_timer_ expires. @GT 10/17/02
	  bb.pagescan_timer_ = -bb.tms_[PAGE_SCAN_TM].period;//-TpageScan;
	  call BTBaseband.endScan(PAGE_SCAN);
	  signal BTHostSig.hciScanCompleteEvent(PAGE_SCAN_TM, FALSE); // GT new HCI event?
	}
      }

      if (bb.clkn_ == bb.max_scan_period_) {
	TRACE_BT(LEVEL_HIGH, "_%d_ CLKN is max_scan_period_. STOP all scans.\n", bb.bd_addr_);
	resetState();
      }

      // Time to perform another inquiry scan.
      if (bb.tms_[INQ_SCAN_TM].valid && bb.inqscan_timer_ == 0 &&
	  bb.clkn_ < bb.max_scan_period_ && bb.inqbackoff_timer_ == 0) {
	if(!call BTBaseband.scan(INQ_SCAN))
	  bb.inqscan_timer_ = -Tretry;
      }

      // Time to perform another page scan.
      if (bb.tms_[PAGE_SCAN_TM].valid && bb.pagescan_timer_ == 0 && bb.clkn_ < bb.max_scan_period_) {
	if(!call BTBaseband.scan(PAGE_SCAN))
	  bb.pagescan_timer_ = -Tretry;
      }

      // Random backoff timeout in inquiry response procedure
      if (bb.inqbackoff_timer_) {
	if (--bb.inqbackoff_timer_ == 0) {
	  TRACE_BT(LEVEL_TIMER, "_%d_ Inqbackofftimer expired. state %s, prog %s.\n",
		   bb.bd_addr_, StateTypeStr[bb.state_], ProgTypeStr[call BTBaseband.getSessionInProg()]);
	  assert(call BTBaseband.getSessionInProg() == INQ_IN_PROG);
	  bb.prev_state_ = bb.state_;
	  changeState(INQ_RESP, InvalidAddr);
	}
      }
    } //slave

    // Transmit timer
    updateTxTimer(CLKN);

    if (bb.pageresp_timer_) {
      if (--bb.pageresp_timer_ == 0) {
	handlePageRespTO();
      }
    }

    if (bb.inqresp_timer_) {
      if (--bb.inqresp_timer_ == 0) {
	TRACE_BT(LEVEL_TIMER, "_%d_ Inquiry response timeout\n", bb.bd_addr_);
	handleInqRespTO();
	signal BTHostSig.hciScanCompleteEvent(INQ_SCAN_TM, TRUE);
      }
    }

    if (bb.new_connection_timer_) {
      if (--bb.new_connection_timer_ == 0) {
	TRACE_BT(LEVEL_TIMER, "_%d_ New connection timer expired.\n", bb.bd_addr_);
	handleNewConnectionTO();
      }
    }

    // If no packet is being transmitted or received try to transmit one
    // For master transmissions only since tx_clock_ = CLKN
    if (bb.tdd_state_ == IDLE && bb.tx_clock_ == CLKN && bb.role_ & AS_MASTER) {
      if (bb.state_ == PAGE) {
	// send two ID packets per even slot
	if (clkmod4 < 2)
	  sendIDPacket(bb.page_addr_);
      }
      else if (bb.request_q_.valid) {
	// Find if a Page request is pending
	if (bb.state_ == CONNECTION && bb.wait_timer_-- && clkmod4 == 0
	    && currentRole() == AS_MASTER) {
	  scheduleNext();
	}

	if (bb.wait_timer_ == 0 || bb.state_ == STANDBY) {
	  if (bb.num_acl_links_ < MaxNumLinks) {
	    bb.request_q_.valid = FALSE;
	    saveAndChangeState(PAGE);
	    signal BTHostSig.hciCommandStatusEvent(HCI_PAGE, TRUE);
	    initInqPageParam();
	    bb.page_timer_ = bb.tms_[PAGE_TM].period;
	    bb.clke_ =  bb.clkn_ - bb.request_q_.clock_offset;
	    TRACE_BT(LEVEL_ACCT, "_%d_ CLKN %d PAGING %d DEVICE CLKE %d ACTUAL CLKN %d MOD4 %d\n",
		     bb.bd_addr_, bb.clkn_, bb.request_q_.bd_addr, bb.clke_, findBbs(bb.request_q_.bd_addr)->clkn_, clkmod4);

	    bb.page_addr_ = bb.request_q_.bd_addr;
	    if (clkmod4 <2)
	      sendIDPacket(bb.page_addr_);
	    bb.wait_timer_ = PageWaitTime;
	  }
	}
      }
      else if (bb.state_ == INQUIRY) {
	// Send two ID packets per even slot
	if (clkmod4 < 2)
	  sendIDPacket(bb.iac_);
      }
      else if (bb.state_ == MASTER_RESP && clkmod4 == 0) {
	// Follow master response page procedure
	if (bb.pageresp_timer_ == 0) {
	  bb.nmr_ = 1;
	  bb.pageresp_timer_ = PageRespTO;

	}
	sendFHSPacket();
      }
      else if (bb.new_connection_timer_ && clkmod4 == 0) {
	// Send POLL packet to the new connection with a new am_addr
	struct BTPacket* p;
	struct hdr_bt* bt;
	if (bb.new_am_addr_==0) newAmAddr();
	assert(bb.new_am_addr_ < (MaxNumSlaves + 1));
	p = sendPOLLPacket(bb.new_am_addr_);
	bt = &(p->bt);
	assert(bb.newconn_addr_ != InvalidAddr);
	TRACE_BT(LEVEL_MED, "_%d_ SENDING POLL PKT TO %d FOR NEWCONN. SENDFQ %d RECVFQ %d %s\n",
		 bb.bd_addr_, bb.newconn_addr_, bt->fs_,
		 findBbs(bb.newconn_addr_)->recv_freq_, ptoString(p));
      }
      else if (bb.state_ == CONNECTION && clkmod4 == 0 && currentRole() == AS_MASTER) {
	scheduleNext();
      }
    }

    if(bb.state_ != CONNECTION || currentRole() == AS_MASTER) {
      updateRecvFreq();
    }

    /* TODO: I have no idea if this is anywhere near correct, but I will try... */
    // call TaskScheduler.checkTasks(tos_state.tos_time / SlotTime);
    call TaskScheduler.checkTasks(call BTBaseband.clkn());
  }

  // First bit of a packet received. All packets reach all nodes (on a freqency)
  // because of broadcast. This is required for collision detection.
  /* **********************************************************************
   * event_recv1bit_handle
   * *********************************************************************/
  /**
   * event_recv1bit_handle.
   *
   * <p>This will be called, when the first bit is received. Then what?</p>
   *
   * @param
   * @return */
  void event_recv1bit_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    struct BTPacket* p = (struct BTPacket*)fevent->data;
    struct hdr_cmn* ch;
    struct hdr_bt*  bt;
    bool check;
    assert(p);
    if(bb.b_stop_ || bb.state_ == STANDBY) {
      FREEP(p);
      free(fevent);
      return;
    }

    check = TRUE;

    ch = &(p->ch);
    bt = &(p->bt);

    // If no useful reception is taking place change the receiving frequency if required
    if (bb.tdd_state_ == IDLE) {
      if (!isWithinRange(bt->xpos_, bt->ypos_)) {
	// dropCnt++; //davh commented out, we cant drop a packet we never recieve
	FREEP(p);
	free(fevent);
	return;
      }

      if(bb.state_ == CONNECTION) {
	if(currentRole() == AS_MASTER) {
	  bt->lid_ = am2lid(bt->am_addr);
	}
	else {
	  if(bb.num_piconets_ && bb.curr_piconet_ != InvalidAddr)
	    bt->lid_ = pid2lid(bb.curr_piconet_);
	  else {
	    bt->lid_ = InvalidAddr;
	    check = FALSE;
	  }
	}
      }
    }

    /*  find if the packet is to be received  */
    /* that is, are we listening, is it free from errors, valid, etc */
    if(bb.tdd_state_ == IDLE && bt->fs_ == bb.recv_freq_ 
       && isErrorFree(p) && isValidPacket(p)) {
      /* Figure out how long the transmission time is, create an event, when
	 transmission complete. */
      int transmittime = ch->size*8*MHz/BandWidth - 1;
      assert(check);
      bb.recv_start_ = tos_state.tos_time;
      bb.tdd_state_ = RECEIVE;
      // max size in bytes * bit/byte * number of clocks to send one bit minus the one added in fhchannel
      event_recvfull_create(fevent, NODE_NUM, tos_state.tos_time + transmittime, p);
      TOS_queue_insert_event(fevent);
      bb.tx_timer_ = (int)(2*SlotSize[bt->type]);
    }
    else {
      //if(bt->send_id_ == 0 && bt->type == BT_ID && bt->state_ == PAGE && bb.bd_addr_ == 29 && bb.state_==PAGE_SCAN)
      TRACE_BT(LEVEL_FUNCTION, "_%d_ DISCARDING PAGED PKT\n", bb.bd_addr_);
      FREEP(p);
      free(fevent);
      return;
    }
  }


  // valid packet completely received
  /* **********************************************************************
   * event_recvfull_handle
   * *********************************************************************/
  /**
   * event_recvfull_handle.
   *
   * <p>Called when a valid packet is completly received.</p>
   *
   * @param
   * @return */
  void event_recvfull_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    struct BTPacket* p = (struct BTPacket*)fevent->data;
    struct hdr_cmn* ch = &(p->ch);
    struct hdr_bt*  bt = &(p->bt);

    int clocka, addr;
    struct fhspayload* fhs;

    // calulate distance between Rx and Tx
    // double dist = distance(bb.xpos_, bb.ypos_, bt->xpos_, bt->ypos_);
    // evaluate loss probability for the packet
    // double fer = calcLossProb(bt->type, dist);
    // fer = (bt->type == BT_ID) ? 0.0 : fer;

    int uptarget = 0;
    if(currentRole() == AS_MASTER)
      uptarget = -1;
    else if(bb.curr_piconet_ != InvalidAddr)
      uptarget = pid2lid(bb.curr_piconet_) + 1; // just add 1 to make sure > 0

    // if (Random::uniform() > fer) {
    //if(TRUE) { // Packet collision should be handled in isErrorFree
    //           TRACE_BT(LEVEL_PACKET, "_%d_ RECV %s %s %s %d\n", bb.bd_addr_, bt->toString(bt),
    //                    HDR_L2CAP(p)->toString(), packet_info.name(&(p->ch)->ptype()), &(p->ch)->uid_); // TODO: FIXME

    //                if(bb.last_recv_)
    //                     FREEP(bb.last_recv_);
    //                bb.last_recv_ = COPYP(p);

    // We should also remove the interface from channel_ when the entire node is on hold to speed up.
    if((bb.state_ == CONNECTION && bb.curr_piconet_ !=  InvalidAddr &&
	getPnetAttr(bb.curr_piconet_)->mode == Hold && bt->recv_id_ != bb.bd_addr_)
       || (bb.state_ == STANDBY)) {
      //TRACE_BT(LEVEL_TMP, "_%d_ NEW FIX %s\n", bb.bd_addr_, bt->toString());
      FREEP(p);
      free(fevent);
      return;
    }

    if (bt->ph.l_ch == LMP_CHAN) {
      bb.polled_ = 1;
      assert(uptarget);
      free(fevent);
      /* Is this a link controller packet or a data packet? 
	 Wrong names, Dennis don't remember... */
      if (uptarget == -1) {
	call BTScheduler.recv(p);
      }
      else {
	call BTLinkController.recv(&bb.lc_[uptarget-1], p);
      }
      return;
    }

    switch (bt->type) {
    case BT_ID:
      if (bb.state_ == INQ_SCAN) {
	int randn = randRange(1, MaximumBackoff);
	// start backoff timer for upto 1024 slots and go to previous state
	if (bb.freeze_ == 0) {
	  // start a new inquiry response session freeze clock to be
	  // used for the rest of the session as the current value of
	  // the native clock
	  bb.inqresp_timer_ = InqRespTO + randn;
	  bb.freeze_ = 1;
	  bb.clkf_ = bb.clkn_;
	  bb.nfhs_ = 0;
	  call BTBaseband.beginSession(INQ_IN_PROG, InqRespTO + randn + 2, NULL);
	}

	TRACE_BT(LEVEL_PACKET, "INQ_MSG %d***-->%d\t CLKN: %-10d code: %d backoff: %d\n",
		 bt->send_id_, bb.bd_addr_, bb.clkn_, ch->uid, randn);
	changeState(bb.prev_state_, InvalidAddr);
	bb.inqbackoff_timer_ = randn;
      }
      else if(bb.state_ == INQ_RESP) {
	// First inquiry message received after backoff.  sync to master
	// clock by setting the next transmission event at exactly
	// 625usec after we started receiving the inquiry ID packet
	TRACE_BT(LEVEL_PACKET, "INQ_MSG AFTER BO *-->%d\t CLKN: %-10d clock: %10lld, code %d \n",
		 bb.bd_addr_, bb.clkn_, tos_state.tos_time, ch->uid);
	// Should only schedule to respond if the session is available
	if(!bb.id_ev_) {
	  bb.id_ev_ = (event_t*)malloc(sizeof(event_t));
	  dbg(DBG_MEM, "malloc id packet event.\n");
	  dbg(DBG_BT, "tos_time: %llu, SlotTime: %d, bb.recv_start_: %d\n",
	      tos_state.tos_time, SlotTime, bb.recv_start_);
	  event_id_create(bb.id_ev_, NODE_NUM, tos_state.tos_time + SlotTime - (tos_state.tos_time - bb.recv_start_));
	  TOS_queue_insert_event(bb.id_ev_);
	}
      }
      else if(bb.state_ == PAGE_SCAN) {
	bb.scanned_addr_ = bt->send_id_; // debug
	beginPageRespSession();
	TRACE_BT(LEVEL_PACKET, "PAGE_MSG ****-->%d\t CLKN: %-10d clock: %10lld CLKF: %-10d %s\n",
		 bb.bd_addr_, bb.clkn_, tos_state.tos_time, bb.clkf_, ptoString(p));
      }
      else if (bb.state_ == PAGE) {
	beginPageRespSession();
	TRACE_BT(LEVEL_PACKET, "PAGE_ACK %d-->%d\t\t CLKN: %-10d clock: %10lld CLKF: %-10d %s\n",
		 ch->uid, bb.bd_addr_, bb.clkn_, tos_state.tos_time, bb.clkf_, ptoString(p));
      }
      else if (bb.state_ == MASTER_RESP) {
	// Received ack of the FHS packet
	endPageRespSession();
	TRACE_BT(LEVEL_PACKET, "FHS_ACK %d-->%d\t\t CLKN: %-10d clock: %10lld\n",
		 ch->uid, bb.bd_addr_, bb.clkn_, tos_state.tos_time);
      }
      FREEP(p);
      break;
    case BT_FHS:
      fhs = (struct fhspayload*)(bt->ph.data);
      addr = fhs->addr;
      clocka = fhs->clock;

      TRACE_BT(LEVEL_PACKET, "FHS_PKT %d-->%d\t\t CLKN: %-10d CLKE: %-10d offset %-10d clock: %10lld\n",
	       addr, bb.bd_addr_, bb.clkn_, clocka, ((bb.clkn_ & 0xfffffffc) - clocka), tos_state.tos_time);

      if (bb.state_ == INQUIRY) {
	// this packet may be as a result of page response FHS packet
	if(bt->state_ != INQ_RESP) {
	  // TODO: occassionally, we may be accepting the wrong FHS
	  // pkt (from page response state).  Not sure whether/how the
	  // BT Spec distinguishes between the two.  For now, state_
	  // is set at the packet header and we check against that
	  // field.
	  TRACE_BT(LEVEL_ERROR, "_%d_ GT_HACK DISCARDING WRONG FHS PKT %s\n",
		   bb.bd_addr_, ptoString(p));
	}
	else {
	  // FHS packet received at the master with clock and address information
	  int new = 1;
	  // Find if the packet corresponds to a new device discovery
	  struct fhspayload* found = bb.addr_vec_;
	  while(found) {
	    if (found->addr == addr) {
	      new = 0;
	      break;
	    }
	    found = found->next;
	  }

	  if (new) {
	    // store the info received to be sent to BThost
	    struct fhspayload* info = (struct fhspayload*)malloc(sizeof(struct fhspayload));
	    dbg(DBG_MEM, "malloc new fhs packet recv.\n");
	    info->addr = addr;
	    info->clock = clockDiff(clocka);
	    info->next = bb.addr_vec_;
	    bb.addr_vec_ = info;
	    bb.addr_vec_size++;
	    if (bb.addr_vec_size == bb.num_responses_) {
	      // If the specified number of responses in the
	      // hciInquiry command have been received, send
	      // hciInquiry_Result with the info collected so
	      // far and stop further inquiry
	      inquiryComplete(bb.prev_state_, TRUE);
	    }
	  }
	}
      }
      else if (bb.state_ == SLAVE_RESP) {
	if(bt->state_ != MASTER_RESP) {
	  TRACE_BT(LEVEL_ERROR, "_%d_ DBG RECEIVING POTENTIALLY BAD FHS PACKET %s %s. DROPPED\n",
		   bb.bd_addr_, ptoString(p), StateTypeStr[bt->state_]);
	  // Bluetooth needs a better way of dealing with this stuff!
	  // A bluetooth node in page response session might receive
	  // an inquiry response packet accidentally.
	}
	else {
	  // if the timer has started we are already attempting to create a conn
	  if(!bb.new_connection_timer_)
	    initSlaveLink(p, TRUE);
	}
      }
      else if(bb.state_ == CONNECTION) {
	if(addr == bb.other_addr_ && bb.b_switch_) {
	  switchRoles(0, p);
	  call BTBaseband.recvSlotOffset(InvalidAddr); //reset the variables
	}
      }
      FREEP(p);
      break;
    case BT_POLL:
      if (bb.new_connection_timer_) {
	// First poll pkt received by a slave
	bb.piconet_attr_[pid2lid(bb.curr_piconet_)]->am_addr = bt->am_addr;
	call BTLinkController.setAmAddr(&bb.lc_[pid2lid(bb.curr_piconet_)],bt->am_addr);
      }

      // remember to reply at the next odd slot boundary
      bb.polled_ = 1;
      assert(uptarget);
      if (uptarget == -1) {
	call BTScheduler.recv(p);
      }
      else {
	call BTLinkController.recv(&bb.lc_[uptarget-1], p);
      }
      break;
    case BT_NULL:
      if (bb.new_connection_timer_) {
	// Ack for the first poll packet sent to a slave received at the
	// master. It is safe to bring it in the piconet now
	if(bb.page_addr_ == bt->send_id_) {
	  // check whether this packet is from the node we are expecting from
	  initMasterLink(bt->am_addr);
	}
	FREEP(p);
      }
      else {
	// null packets don't contain data but might contain ack hence
	// link controller needs to know about it
	if(bb.role_ & AS_SLAVE)
	  bb.polled_ = 1; // Dennis, why poll here? AFAIK we _must_ only respond if its a POLL
	assert(uptarget);
	if (uptarget == -1) {
	  call BTScheduler.recv(p);
	}
	else {
	  call BTLinkController.recv(&bb.lc_[uptarget-1], p);
	}
      }
      break;
    default:
      if(currentRole() == AS_SLAVE) {
	// Remember to respond in the next odd slot
	bb.polled_ = 1;
      }

      if(uptarget)
	if (uptarget == -1) {
	  call BTScheduler.recv(p);
	}
	else {
	  call BTLinkController.recv(&bb.lc_[uptarget-1], p);
	}
      else {
	dropped(p);
	FREEP(p);
      }
    }
    free(fevent);
  }


  /* **********************************************************************
   * event_id_handle
   * *********************************************************************/
  /**
   * Handle an id event.
   *
   * <p>Unsure, but I suppose it is called when an ID packet is received.  If we are
   * in the INQ_RESP state, a FHS packet is send, the state is changed, and
   * BTHostSig.hciInqRespSentEvent is signalled.</p>
   * 
   * <p>If the node is not in the INQ_RESP state, I am unsure what happens.</p>
   *
   * @param fevent the event that was registered with the clock thingy
   * @param state the current TOS state. */
  void event_id_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    assert(bb.id_ev_ == fevent);
    if (bb.state_ == INQ_RESP) {
      sendFHSPacket();
      changeState(INQ_SCAN, InvalidAddr);
      bb.nfhs_++;
      bb.tx_clock_ = CLKN;
      signal BTHostSig.hciInqRespSentEvent();
    }
    else if (bb.state_ == SLAVE_RESP) {
      TRACE_BT(LEVEL_LOW,"_%d_ respidhandler CLKN %d CLKF %d CLKE %d RECVFREQ %d %s\n",
	       bb.bd_addr_, bb.clkn_, bb.clkf_, bb.clke_, bb.recv_freq_, StateTypeStr[bb.state_]);

      if (bb.newconn_addr_ == -1) {
	// The first ID response
	bb.nsr_ = 0;
	bb.pageresp_timer_ = PageRespTO;
	sendIDPacket(bb.bd_addr_);
	bb.tx_clock_ = CLKN;
      }
      else {  // The second ID response after receiving the FHS pkt
	sendIDPacket(bb.bd_addr_);
	prepareSlvLink();
	bb.nsr_ = 0;
	bb.freeze_ = 0; // end the page response session
      }
    }
    free(fevent);
    bb.id_ev_ = NULL;
  }


  /* **********************************************************************
   * event_switch_handle
   * *********************************************************************/
  /**
   * event_switch_handle.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_switch_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    struct sess_switch_data* ev = (struct sess_switch_data*)fevent->data;
    call BTBaseband.holdLink(ev->lid_, ev->intv_, ev->mclkn_, ev->b_rcvd_);
  }


  /* **********************************************************************
   * event_rswitch_handle
   * *********************************************************************/
  /**
   * event_rswitch_handle.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_rswitch_handle(event_t* fevent, struct TOS_state* state) __attribute__ ((C, spontaneous)) {
    switchRoles(0, NULL);
    free(fevent);
  }


  /* **********************************************************************
   * event_switch_create
   * *********************************************************************/
  /**
   * event_switch_create.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_switch_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    //fevent->data = (void*)data; //already set
    fevent->time = ftime;
    fevent->handle = event_switch_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_rswitch_create
   * *********************************************************************/
  /**
   * event_rswitch_create.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_rswitch_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    fevent->data = NULL;
    fevent->time = ftime;
    fevent->handle = event_rswitch_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_id_create
   * *********************************************************************/
  /**
   * event_id_create.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_id_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    fevent->data = NULL;
    fevent->time = ftime;
    fevent->handle = event_id_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_clk_create
   * *********************************************************************/
  /**
   * Initialize the first clk event. 
   *
   * @param fevent the event that will be set up
   * @param mote the mote number that it is created for (this mote)
   * @param ftime the time the event will fire
   * @param data data to store in the event (used for piconet number) */ 
  void event_clk_create(event_t* fevent, int mote, long long ftime, btaddr_t data) {
    fevent->mote = mote;
    fevent->data = (void*)data;
    fevent->time = ftime;
    fevent->handle = event_clk_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_clkn_create
   * *********************************************************************//**
   * Initialize the first clkn event. 
   *
   * @param fevent the event that will be set up
   * @param mote the mote number that it is created for (this mote)
   * @param ftime the time the event will fire */ 
  void event_clkn_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    fevent->data = NULL;
    fevent->time = ftime;
    fevent->handle = event_clkn_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_tx_create
   * *********************************************************************/
  /**
   * event_tx_create.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_tx_create(event_t* fevent, int mote, long long ftime, struct BTPacket* data) {
    fevent->mote = mote;
    fevent->data = (void*)data;
    fevent->time = ftime;
    fevent->handle = event_tx_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * BTBaseband.event_recv_create
   * *********************************************************************/
  /**
   * BTBaseband.event_recv_create.
   *
   * <p>Dennis says: emulates a transmission delay on the first bit.</p>
   *
   * @param
   * @return */
  command void BTBaseband.event_recv_create(event_t* fevent, int mote, long long ftime, struct BTPacket* data) {
    TRACE_BT(LEVEL_FUNCTION, "%s(%p, %d, %llu, %p)\n", __FUNCTION__,
	     fevent, mote, ftime, data);
    fevent->mote = mote;
    fevent->data = (void*)data;
    fevent->time = ftime;
    fevent->handle = event_recv1bit_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_recvfull_create
   * *********************************************************************/
  /**
   * event_recvfull_create.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_recvfull_create(event_t* fevent, int mote, long long ftime, struct BTPacket* data) {
    fevent->mote = mote;
    fevent->data = (void*)data;
    fevent->time = ftime;
    fevent->handle = event_recvfull_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }


  /* **********************************************************************
   * event_sess_create
   * *********************************************************************/
  /**
   * event_sess_create.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void event_sess_create(event_t* fevent, int mote, long long ftime) {
    fevent->mote = mote;
    //fevent->data = (void*)data; //already set
    fevent->time = ftime;
    fevent->handle = event_sess_handle;
    fevent->cleanup = NULL;
    fevent->pause = 0;
  }

  /*=================================================================
    Timer Related Routines
    ==================================================================*/

  // Activate a timer. The specified event will occur every TICKS ticks for WINDOW
  // ticks. The first even occurs OFFSET ticks after setTimer is called.  OFFSET is
  // only used when TYPE is INQ_SCAN_TM or PAGE_SCAN_TM.
  /* **********************************************************************
   * setTimer
   * *********************************************************************/
  /**
   * setTimer.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void setTimer(enum timer_t type, int ticks, int window) {
    TRACE_BT(LEVEL_LOW, "_%d_ set_timer: %s ticks=%d, window=%d\n", bb.bd_addr_, TimerTypeStr[type], ticks, window);

    switch(type) {
    case INQ_TM:
      // inquiry activity will stop
      bb.inq_timer_ = ticks + 1;
      break;
    case INQ_SCAN_TM:
      // inquiry scan will periodically happen
      bb.inqscan_timer_ = -1; // happen right away
      break;
    case PAGE_SCAN_TM:
      // start page scan at every pagescan_timer_ ticks
      bb.pagescan_timer_ = -1;
      break;
      //           case ALL_SCAN_TM:
      //                bb.max_scan_period_ = ticks;
      //                break;
    case INQ_BACKOFF_TM:
      // enter INQ_RESP state
      assert(0);
      bb.inqbackoff_timer_ = ticks  + 1;
      break;
    case INQ_RESP_TM:
      // will stop current INQ_SCAN or INQ_RESP activity and enter the previous state
      assert(0);
      bb.inqresp_timer_ = ticks + 1;
      break;
    case PAGE_TM:
      assert(0);
      // paging activity will stop. inform host of an unsuccessful paging session.
      bb.page_timer_ = ticks + 1;
      break;
    case PAGE_RESP_TM:
      assert(0);
      bb.pageresp_timer_ = ticks + 1;
      break;
    case NEW_CONN_TM:
      assert(0);
      bb.new_connection_timer_ = ticks + 1;
      break;
    case HOST_TM:
      bb.host_timer_ = ticks + 1;
      break;
    default:
      assert(0);
    }
    bb.tms_[type].window = window;
    bb.tms_[type].period = ticks;
    bb.tms_[type].valid = TRUE;
  }


  /* **********************************************************************
   * updateHoldTimer
   * *********************************************************************/
  /**
   * updateHoldTimer.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void updateHoldTimer(struct con_attr* attr, int hold_time) {
    if(attr->mode == Hold) { // if it's already on hold we should not update the hold time
      if (hold_time < attr->hold_time)
	attr->hold_time = hold_time;
    }
    else
      attr->hold_time = hold_time;
    attr->mode = Hold;
    TRACE_BT(LEVEL_MED, "_%d_ HOLDING PICONET %d for %d ticks, next %d, last %d\n",
	     bb.bd_addr_, bb.curr_piconet_, attr->hold_time, bb.next_piconet_, bb.last_piconet_);
  }


  // Update tx_timer_ if TYPE == tx_clock_.
  /* **********************************************************************
   * updateTxTimer
   * *********************************************************************/
  /**
   * updateTxTimer.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void updateTxTimer(enum clock_t type) {
    if (bb.tx_timer_ && bb.tx_clock_ == type) {
      if (--bb.tx_timer_ == 0) {
	bb.tdd_state_ = IDLE;
	if(bb.tx_lid_ != InvalidLid && bb.lc_[bb.tx_lid_].valid) {
	  call BTLinkController.transmitted(&bb.lc_[bb.tx_lid_]);
	  bb.tx_lid_ = InvalidLid;
	}
      }
    }
  }


  /* **********************************************************************
   * handlePageRespTO
   * *********************************************************************/
  /**
   * Handle a page response timeout.
   *
   * <p>Handles a page response timeout by resetting the state, etc.</p> */
  void handlePageRespTO() {
    call BTBaseband.endSession(PAGE_IN_PROG);

    if(bb.role_ & AS_MASTER && bb.page_timer_) {
      if(bb.state_ == MASTER_RESP)
	changeState(PAGE, InvalidAddr);
      bb.freeze_ = 0;
      bb.nmr_ = 0;
    }

    if(bb.role_ & AS_SLAVE) {
      if(bb.state_ == PAGE_SCAN || bb.state_ == SLAVE_RESP)
	changeState(bb.prev_state_, InvalidAddr);
      bb.freeze_ = 0;
      bb.nsr_ = 0;
    }
    bb.pageresp_timer_ = 0;
  }


  /* **********************************************************************
   * handleInqRespTO
   * *********************************************************************/
  /**
   * Handle an inquiry response timeout.
   *
   * <p>Handles an inquiry response timeout by resetting the state, etc.</p> */
  void handleInqRespTO() {
    bb.inqresp_timer_ = 0;
    bb.inqbackoff_timer_ = 0;
    bb.inqscan_timer_ = -TinqScan;
    bb.freeze_ = 0;
    bb.nfhs_ = 0;

    if(call BTBaseband.getSessionInProg() == INQ_IN_PROG)
      call BTBaseband.endSession(INQ_IN_PROG);

    if(bb.state_ == INQ_SCAN || bb.state_ == INQ_RESP) {
      // Should only change it if BB is in the right state.
      changeState(bb.prev_state_, InvalidAddr);
    }
  }


  /* **********************************************************************
   * handleNewConnectionTO
   * *********************************************************************/
  /**
   * Handle a new connection timeout.
   *
   * <p>Handle a new connection timeout. Deletes slavelinks etc. as
   * appropiate.</p> */
  void handleNewConnectionTO() {
    // We need to cater for the case when it really timeouts.
    if(bb.state_ == CONNECTION) {// real connection timeouts since master or slave does not respond!
      assert(!bb.b_switch_);
      if(bb.b_connect_as_master_)
	inquiryComplete(bb.prev_state_, TRUE);
      else {
	// we need to delete the slave link
	TRACE_BT(LEVEL_TIMER, "_%d_ DBG NEWCONNECTION TIMEOUT DURING PAGE SCAN\n",
		 bb.bd_addr_);
	delSlaveLink(bb.curr_piconet_);
	signal BTHostSig.hciScanCompleteEvent(PAGE_SCAN_TM, TRUE); // inform host of the failure
      }
    }
    else if (bb.role_ & AS_MASTER && bb.state_ == MASTER_RESP) {
      if (bb.page_timer_)
	changeState(PAGE, InvalidAddr);
      else
	changeState(bb.prev_state_, InvalidAddr);
    }
    else if(bb.role_ & AS_SLAVE && bb.state_ == SLAVE_RESP) {
      // This happens when slave does not receive the POLL pkt following the paging procedure.
      changeState(bb.prev_state_, InvalidAddr);
    }
    bb.newconn_addr_ = InvalidAddr;
  }


  /* **********************************************************************
   * clockDiff
   * *********************************************************************/
  /**
   * clockDiff.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  int clockDiff(int clocka) {
    return ((bb.clkn_ & 0xfffffffc) - clocka);
  }


  /*=================================================================
    Packet Related Routines
    ==================================================================*/


  /* **********************************************************************
   * BTBaseband.allocPkt
   * *********************************************************************/
  /**
   * BTBaseband.allocPkt.
   *
   * <p>Fill in description</p>
   *
   * @param pktType one of BT_NULL, BT_POLL, BT_FHS, BT_DM1, etc.
   * @param addr used to set the packets am_addr field. "Which slave
   * to receive the packet"
   * @return */
  command struct BTPacket* BTBaseband.allocPkt(enum btpacket_t pktType, 
					       amaddr_t addr) {
    struct BTPacket* p = ALLOCP();
    struct hdr_cmn* ch = &(p->ch);
    struct hdr_bt* bt = &(p->bt);
    ch->size = 0;
    ch->ptype = pktType;
    bt->type = pktType;
    bt->am_addr = addr;

    switch(pktType) {
    case BT_FHS: {
      struct fhspayload* fhs =  (struct fhspayload*)bt->ph.data;
      fhs->addr = bb.bd_addr_;
      fhs->piconet_no = bb.bd_addr_;
      assert(bb.bd_addr_ != InvalidAddr);
      bt->ph.length = sizeof(struct fhspayload);
      break;
    }
    case BT_ID:
      ch->uid = addr;
      break;
    default:
      break;
    }
    return p;
  }


  // Called back by the link controller when it drops the packet.
  /* **********************************************************************
   * dropped
   * *********************************************************************/
  /**
   * Callback for the link controller when a packet is dropped???.
   *
   * <p>Fill in description</p>
   *
   * @param p A packet */
  void dropped(struct BTPacket* p) {
    TRACE_BT(LEVEL_LOW, "_%d_ BASEBAND DROPPED  %s\n",
	     bb.bd_addr_, ptoString(p));
  }


  /* **********************************************************************
   * isValidPacket
   * *********************************************************************/
  /**
   * isValidPacket.
   *
   * <p>Determine whether the packet is valid</p>
   *
   * @param p the packet to check
   * @return whether the packet is valid or not */
  int isValidPacket(struct BTPacket* p) {
    unsigned int i;
    struct hdr_cmn* ch = &(p->ch);
    struct hdr_bt*  bt = &(p->bt);
    btaddr_t access_code = 0;
    bool respond = FALSE;
    int flag = 0;
    amaddr_t curr_am_addr = 0;

    flag = (bt->fs_ == bb.recv_freq_);
    if (!flag)
      return flag;

    if (currentRole() == AS_MASTER)
      curr_am_addr = bb.am_addr_;
    else if(bb.curr_piconet_ != InvalidPiconetNo)
      curr_am_addr = bb.piconet_attr_[pid2lid(bb.curr_piconet_)]->am_addr;

    switch(bt->type) {
    case BT_ID:
      access_code = ch->uid;
      if(access_code >= IACLow) {
	respond = !bb.iac_filter_accept_;
	for(i = 0; i < bb.iac_filter_length; i++)
	  if(bb.iac_filter_[i] == access_code) {
	    respond = bb.iac_filter_accept_;
	    break;
	  }
      }

      flag &= ((bb.state_ == INQ_SCAN && respond) || (bb.state_ == INQ_RESP && respond) ||
	       (bb.state_ == PAGE_SCAN && access_code == bb.bd_addr_) ||
	       (bb.state_ == PAGE && access_code == bb.page_addr_) ||
	       (bb.state_ == MASTER_RESP && access_code == bb.page_addr_));
      TRACE_BT(LEVEL_LOW, "BD_ADDR %d, access_code %d, respond %d, flag %d, %s %s\n",
	       bb.bd_addr_, access_code, respond, flag, StateTypeStr[bb.state_], ptoString(p));
      break;
    case BT_FHS:
      flag &= ((bb.state_ == INQUIRY) || (bb.state_ == SLAVE_RESP) || (bb.state_ == CONNECTION));
      break;
    case BT_POLL:
      flag &= (bb.state_ == CONNECTION && bb.role_ & AS_SLAVE);
      flag &= (curr_am_addr == 0 || curr_am_addr == bt->am_addr);
      break;
    default:
      flag &= (bb.tdd_state_ == IDLE);
      flag &= ((curr_am_addr == bt->am_addr) || bt->am_addr == 0);
      flag &= (bb.bd_addr_ == bt->recv_id_);
      flag &= (bb.state_ == CONNECTION); //All other packets should only be received in CONNECTION state!
      break;
    }

    // We need to check for channel access code to validate that packets are intended for this piconet.
    // We treat piconet_no as the channel access code.
    if(bb.state_ ==  CONNECTION) {
      flag &= (bb.curr_piconet_ == bt->piconet_no);
    }

    return flag;
  }


  /* **********************************************************************
   * isErrorFree
   * *********************************************************************/
  /**
   * isErrorFree.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  bool isErrorFree(struct BTPacket* p) {
    // We need to have a reasonable error model implemented here!  Lacking the
    // error model will not significantly affect the Bluetooth Inquiry
    // operations.  This is because ID packets are very short and thus,
    // collissions are highly unlikely.  The assumption here is also that there
    // are no noise in the channel!
    return TRUE;
  }


  /* **********************************************************************
   * scheduleNext
   * *********************************************************************/
  /**
   * scheduleNext.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void scheduleNext() {
    struct BTPacket* p;
    if(bb.my_piconet_attr_.mode != Active)
      return;
    p = call BTScheduler.schedulePkt(bb.clkn_, (call BTBaseband.getSessionInProg() == HOLD_IN_PROG) ? 1 : -1);
    if (p)
      sendPacket(p);
  }


  /* **********************************************************************
   * sendPOLLPacket
   * *********************************************************************/
  /**
   * sendPOLLPacket.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  struct BTPacket* sendPOLLPacket(amaddr_t am_addr) {
    struct BTPacket* p = call BTBaseband.allocPkt(BT_POLL, am_addr);
    sendPacket(p);
    return p;
  }


  /* **********************************************************************
   * sendNULLPacket
   * *********************************************************************/
  /**
   * sendNULLPacket.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void sendNULLPacket(amaddr_t am_addr) {
    struct BTPacket* p = call BTBaseband.allocPkt(BT_NULL, am_addr);
    sendPacket(p);
  }


  /* **********************************************************************
   * sendIDPacket
   * *********************************************************************/
  /**
   * sendIDPacket.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void sendIDPacket(btaddr_t addr) {
    struct BTPacket* p;
    if (bb.state_ == PAGE || bb.state_ == INQUIRY)
      updateInqPageParam();

    p = call BTBaseband.allocPkt(BT_ID, (amaddr_t)addr);
    sendPacket(p);
  }


  /* **********************************************************************
   * sendFHSPacket
   * *********************************************************************/
  /**
   * Send an FHS packet.
   *
   * <p>Allocates a packet of type BT_FHS and sends it.</p> */
  void sendFHSPacket() {
    struct BTPacket* p = call BTBaseband.allocPkt(BT_FHS, 0);
    sendPacket(p);
  }


  // Schedules the packet to be sent on the appropriate hopping sequence.
  /* **********************************************************************
   * sendPacket
   * *********************************************************************/
  /**
   * Send a packet.
   *
   * <p>Schedules the packet to be sent on the appropiate hopping sequence.</p>
   *
   * @param p the packet to send. */
  void sendPacket(struct BTPacket* p) {
    enum fhsequence_t hop_type;
    int address;
    int clocka, clockf;
    struct hdr_cmn* ch = &(p->ch);
    struct hdr_bt* bt = &(p->bt);
    event_t* tx_ev;

    bb.tdd_state_ = TRANSMIT; // Beam me over scotty
    bb.tx_timer_ = (int)(2*SlotSize[bt->type]); // Set the number of timerinterrupts needed to send this packet
    bt->piconet_no = bb.bd_addr_;

    switch (bb.state_) {
    case INQUIRY:
      clocka = bb.clkn_;
      address = bb.giac_;
      hop_type = inquiry_hopping;
      bt->am_addr = 0; // used for broadcast in animation
      break;
    case PAGE:
      clocka = bb.clke_;
      address = bb.page_addr_;
      hop_type = page_hopping;
      bt->am_addr = 0; // used for broadcast in animation
      bt->recv_id_ = bb.page_addr_;
      break;
    case INQ_RESP:
      clocka = bb.clkn_;
      address = bb.giac_;
      hop_type = inquiry_response;
      bt->recv_id_ = 0;
      break;
    case SLAVE_RESP:
      clocka = bb.clkn_;
      address = bb.bd_addr_;
      hop_type = slave_response;
      bt->recv_id_ = 0;
      break;
    case MASTER_RESP:
      clocka = bb.clke_;
      address = bb.page_addr_;

      if(bb.clke_ != findBbs(address)->last_even_tick_) {
	TRACE_BT(LEVEL_LOW, "_%d_ DBG LAST EVEN TICK DIFFERENT clkf_ %d clke_ %d, realeventick %10lld\n",
		 bb.bd_addr_, bb.clkf_, bb.clke_, findBbs(address)->last_even_tick_);
      }
      hop_type = master_response;
      bt->recv_id_ = bb.page_addr_;
      break;
    case CONNECTION:
      if(currentRole() == AS_MASTER) {
	address = bb.bd_addr_;
	clocka = bb.clkn_;
	bb.am_addr_ = bt->am_addr;
	bt->recv_id_ = bb.active_list_[bt->am_addr];
      }
      else {
	assert(currentRole() == AS_SLAVE);
	address = bb.master_addr_;
	clocka = bb.master_clk_;
	bt->recv_id_ = address;
      }
      bt->piconet_no = bb.curr_piconet_;
      hop_type = channel_hopping;
      break;
    case STANDBY:
      assert(0); //send packet while in standby?
    case PAGE_SCAN:
    case INQ_SCAN:
      assert(0); //send packet while scanning?
    case SLAVE_RESP_ID_SENT:
      assert(0); //send packet while waiting for response?
    case NUM_STATE:
      assert(0);
    default:
      //shut up warnings
      hop_type = channel_hopping;
      address = bb.master_addr_;
      clocka = bb.master_clk_;
      assert(0);
    }

    bt->send_id_ = bb.bd_addr_;
    if (ch->size == 0)
      ch->size = Payload[bt->type];

    clockf = (bb.freeze_) ? bb.clkf_ : clocka;
    bt->fs_ = FH_kernel(clocka, clockf, hop_type, address);

    //TRACE_BT(LEVEL_TMP, "_%d_ SEND FREQ %d STATE %s CLOCK 0x%x CLOCKF 0x%x HOP %d ADDR %d\n",
    // bb.bd_addr_, bt->fs_, StateTypeStr[getState()], clocka, clockf, hop_type, address);

#ifdef DEBUG_BB                 // Does NOT work
    BTBaseband* bb = lm(bb.scanned_addr_);
    int ce = bb->clke_;
    int cf = bb->clkf_;
    tdd_state_type prevState = bb->tdd_state_;
    bb->tdd_state_ = IDLE;
    for(int i = ce - 10; i < ce + 11;  i++) {
      for(int j = cf - 10; j < cf + 11;  j++) {
	bb->clke_ = i;
	bb->clkf_ = j;
	bb->updateRecvFreq();
	TRACE_BT(LEVEL_TMP, "_%d_ DBG MAS %d clke_ %d clkf_ %d recv_freq %d\n",
		 bb.bd_addr_, bb.scanned_addr_, bb->clke_, bb->clkf_, bb->recv_freq_);
      }
    }
    bb->clke_ = ce;
    bb->clkf_ = cf;
    bb->tdd_state_ = prevState;
    bb->updateRecvFreq();
    TRACE_BT(LEVEL_TMP, "_%d_ DBG MAS %d clke_ %d clkf_ %d recv_freq %d\n",
	     bb.bd_addr_, bb.scanned_addr_, bb->clke_, bb->clkf_, bb->recv_freq_);
#endif

    bt->xpos_ = bb.xpos_;
    bt->ypos_ = bb.ypos_;
    if(bb.state_ == CONNECTION) {
      bb.tx_lid_ = bt->lid_ = (currentRole() == AS_MASTER) ? am2lid(bt->am_addr) : pid2lid(bb.curr_piconet_);
      //bt->dir = call BTBaseband.isMasLink(bt->lid_);
    }
    else {
      bb.tx_lid_ = bt->lid_ = InvalidLid;
      //bt->dir = (uchar)-1;
    }

    if(bt->type == BT_FHS) {
      // Set the clock information right before the packet is transmitted
      struct fhspayload* fhs = (struct fhspayload*)(bt->ph.data);
      fhs->clock = bb.clkn_ & 0xfffffffc; // even tick
      fhs->real_time = bb.last_even_tick_;
    }

    tx_ev = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc prop delay event.\n");

    event_tx_create(tx_ev, NODE_NUM, tos_state.tos_time + PropDelay, p);
    TOS_queue_insert_event(tx_ev);

    // debugging purposes and to solve occassional acceptance of wrong packets (see RecvHandler::handle)
    bt->state_ = bb.state_;

    // Check LMP commands to make sure whether BB needs to do anything.
    if(bt->ph.l_ch == LMP_CHAN && bt->ph.data[0] == LMP_DETACH)
      detach(&bb.linkq_[bt->lid_]);
  }


  /*=================================================================
    Inquiry Related Routines
    ==================================================================*/

  /* **********************************************************************
   * updateInqPageParam
   * *********************************************************************/
  /**
   * updateInqPageParam.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void updateInqPageParam() {
    int n = (bb.state_ == INQUIRY) ? N_INQ_TRAIN : N_PAGE_TRAIN;

    // Time to change train
    if (bb.num_id_ == TRAINSIZE) {
      bb.num_id_ = 0;   // reset numpackets
      bb.num_trains_sent_++;
      if (bb.num_trains_sent_ == n) {
	TRACE_BT(LEVEL_STATE, "_%d_ SWITCHING TRAIN FROM %d to %d\n",
		 bb.bd_addr_, bb.train_type_, (bb.train_type_ == A) ? B : A);
	bb.num_trains_sent_ = 0;
	bb.train_type_ = (bb.train_type_ == A) ? B : A;
      }
    }
    bb.num_id_++;
  }


  /* **********************************************************************
   * initInqPageParam
   * *********************************************************************/
  /**
   * initInqPageParam.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  void initInqPageParam() {
    bb.num_id_ = 0;
    bb.train_type_ = A;
    bb.num_trains_sent_ = 0;
  }

  /* **********************************************************************
   * inquiryComplete
   * *********************************************************************/
  /**
   * Complete an inquiry.
   *
   * <p>Completes an inquiry, and sets up for the next. Signals
   * BTHostSig.hciInquiryResult if requested.</p>
   *
   * @param state TODO: no idea
   * @param callback Wheter the BTHostSig.hciInquiryResult should be signalled or not. 
   *        Set to false for an inquiry cancel operation.
   */
  void inquiryComplete(enum state_t state, bool callback) {
    dbg(DBG_USR1, "inquiryComplete\n");
    bb.inq_timer_ = 0;
    initInqPageParam();
    changeState(state, InvalidAddr);
    if(callback) {
      signal BTHostSig.hciInquiryResult(bb.addr_vec_); // remember that called must free() it
      // TODO: Is this right? I think so...
      signal BTHostSig.hciInquiryComplete();
    } else {
      struct fhspayload* fhs = bb.addr_vec_;
      while (fhs) {
	struct fhspayload* fhst = fhs->next;
	free(fhs);
	fhs = fhst;
      }
    }
    bb.addr_vec_size = 0;
    bb.addr_vec_ = NULL;
    bb.tms_[INQ_TM].valid = FALSE;
  }


  /*=================================================================
    Convert between lid/addr etc Related Routines
    ==================================================================*/

  /* **********************************************************************
   * lid2addr1
   * *********************************************************************/
  /**
   * Get an address from an linkid.
   *
   * <p>Looks up linkid in the list of active connections in the piconet, return the
   * address. If lid >= MaxNumSlaves (7) the master addr is returned.</p>
   *
   * <p>TODO: We are sometimes calling this as slaves? Does that matter?</p>
   *
   * @param lid the linkid to look up 
   * @return the address of the linkid in the list of active connections, or the
   * master address if out of bounds */
  btaddr_t lid2addr1(linkid_t lid) {
    if(lid< MaxNumSlaves)
      return bb.active_list_[lid+1]; //active_list_'s index starts from 1!
    return bb.piconet_attr_[lid]->master_addr;
  }


  /* **********************************************************************
   * lid2addr
   * *********************************************************************/
  /**
   * lid2addr.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  btaddr_t lid2addr(linkid_t lid, bool bMaster) {
    if(lid< MaxNumSlaves) {
      if(bMaster)
	return bb.bd_addr_;
      else
	return bb.active_list_[lid+1]; //active_list_'s index starts from 1!
    }
    else {
      if(bMaster)
	return bb.piconet_attr_[lid]->master_addr;
      else
	return bb.bd_addr_;
    }
  }


  /* **********************************************************************
   * addr2lid
   * *********************************************************************/
  /**
   * addr2lid.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  linkid_t addr2lid(btaddr_t addr) {
    linkid_t i = 0;
    for(i = 0; i < MaxNumSlaves; i++) {
      if(addr == bb.active_list_[i+1]) //active_list_'s index starts from 1
	return i;
    }
    for(i = MaxNumSlaves; i < MaxNumLinks; i++) {
      if(bb.piconet_attr_[i] && bb.piconet_attr_[i]->master_addr == addr)
	return i;
    }
    assert(i != 0);
    return InvalidLid;
  }


  /* **********************************************************************
   * lid2pid
   * *********************************************************************/
  /**
   * lid2pid.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  btaddr_t lid2pid(linkid_t linkIndex) {
    return bb.link_pids_[linkIndex];
  }


  /* **********************************************************************
   * pid2lid
   * *********************************************************************/
  /**
   * pid2lid.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  linkid_t pid2lid(btaddr_t pid) {
    linkid_t i;
    assert(pid > 0);
    for(i = MaxNumSlaves; i < MaxNumLinks; i++)
      if(bb.link_pids_[i] == pid)
	return i;
    assert(0);
    return InvalidLid;
  }


  /* **********************************************************************
   * am2lid
   * *********************************************************************/
  /**
   * am2lid.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  linkid_t am2lid(amaddr_t am) {
    return (linkid_t)(am-1);
  }


  /* **********************************************************************
   * lid2am
   * *********************************************************************/
  /**
   * lid2am.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  amaddr_t lid2am(linkid_t l) {
    return (amaddr_t)(l+1);
  }

  // USE ONLY FROM OUTSIDE
  /* **********************************************************************
   * BTBaseband.bd_addr
   * *********************************************************************/
  /**
   * BTBaseband.bd_addr.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  command btaddr_t BTBaseband.bd_addr() {
    return bb.bd_addr_;
  }


  // Generate a new LID (link id).
  /* **********************************************************************
   * newLid
   * *********************************************************************/
  /**
   * newLid.
   *
   * <p>Fill in description</p>
   *
   * @param
   * @return */
  linkid_t newLid() {
    linkid_t i = InvalidLid;
    // LIDs 1-MaxNumSlaves are reserved for the slaves belonging to THIS piconet.
    for (i= MaxNumSlaves; (bb.link_pids_[i] != InvalidLid && i < MaxNumLinks); i++)
      ;
    assert(i != InvalidLid);
    return i;
  }


  /* **********************************************************************
   * BTBaseband.isMasLink
   * *********************************************************************/
  /**
   * Checks if this host is the master on a given linkid.
   *
   * \param lid the linkid to check
   * @return whether or not this host is a master on the linkid. */
  command bool BTBaseband.isMasLink(linkid_t lid) {
    assert(lid >= 0 && lid < MaxNumLinks);
    return lid < MaxNumSlaves;
  }


  /* **********************************************************************
   * BTBaseband.mclkn
   * *********************************************************************/
  /** Get the masters natural clock (wall clock) for a specific link id.
   * 
   * <p>First checks if \a lid is a masterlink, in that case the master clock is
   * returned, otherwise the master clock for the piconet of the specified link id is
   * returned.</p>
   *
   * \param lid the linkid to get the clock for
   * \return the master clock for the piconet of the specified link id */
  command int BTBaseband.mclkn(linkid_t lid) {
    if(call BTBaseband.isMasLink(lid))
      return bb.clkn_;
    return bb.piconet_attr_[lid]->mclk;
  }


  /* **********************************************************************
   * BTBaseband.clkn
   * *********************************************************************/
  /**************************************************************************/
  /** Get the natural clock for this host.
   *
   * \return the natural clock for this host  */
  command int BTBaseband.clkn() {
    return bb.clkn_;
  }


  /* **********************************************************************
   * tm2hci
   * *********************************************************************/
  /**
   * Convert a timer enum value to a HCI enum value.
   *
   * \param tm the timer value to convert. 
   * @return the corresponding HCI enum value. */
  enum hci_cmd tm2hci(enum timer_t tm) {
    switch(tm) {
    case INQ_TM:
      return HCI_INQ;
    case INQ_SCAN_TM:
      return HCI_INQ_SCAN;
    case PAGE_TM:
      return HCI_PAGE;
    case PAGE_SCAN_TM:
      return HCI_PAGE_SCAN;
    default:
      assert(0);
    }
  }


  /*=================================================================
    x/y coordinat Related Routines
    ==================================================================*/

  /* **********************************************************************
   * isWithinRange
   * *********************************************************************/
  /**
   * Check if a coordinate is within BTMaxRange from this node.
   *
   * @param xpos the x coordinate to check against
   * @param ypos the y coordinate to check against
   * @return wheter the distance to the argument point is <= BTMaxRange */
  bool isWithinRange(int xpos, int ypos) {
    return (sqrt(pow((double)(bb.xpos_ - xpos), 2) + pow((double)(bb.ypos_ - ypos), 2)) <= BTMaxRange);
  }




  /*=================================================================
    commands to initiate something from the host
    ==================================================================*/

  /** 
   * Tell the baseband to do an inquiry.
   * 
   * <p>The implementation works by setting the INQ_TM timer to inqlen.</p>
   * 
   * @param inqlen The length of the inquiry in ticks (312.5usec).
   * @param num_responses The number of responses, 0 for unlimited
   * @param iac The Inquiry Access Code. Uses <code>setIac</code> and 
   *        <code>getIac</code> to set and get the code. */
  command void BTBaseband.inquire(int inqlen, int num_responses, int iac) {
    TRACE_BT(LEVEL_MED, "_%d_ hciINQUIRY: period=%d, responses=%d, iac=%d\n",
	     bb.bd_addr_, inqlen, num_responses, iac);

    bb.num_responses_ = num_responses;
    setTimer(INQ_TM, inqlen, 0);
    /* Clear all the inquiry responses we have until now, if the
       user was silly enough to call inquiry before the current was terminated.
       OR, previous responses... argh. */
    {
      struct fhspayload* fhs = bb.addr_vec_;
      while (fhs) {
	struct fhspayload* fhst = fhs->next;
	free(fhs);
	fhs = fhst;
      }

    }
    bb.addr_vec_ = 0;
    bb.addr_vec_size = 0;
    /* Set the access code we are interessted in */
    setIAC(iac);
  }

  /** 
   * Tell the baseband to do a page.
   * 
   * <p>The implementation works by filling in the bt.request_q_ structure and 
   * the PAGE_TM timer...</p>
   * 
   * @param addr the addr to page
   * @param clock_offset I suppose this is the clock offset of the receiver
   * @param pageto the page timeout, I reckon. */
  command void BTBaseband.page(int addr, int clock_offset, int pageto)  {
    TRACE_BT(LEVEL_ACCT, "_%d_ Baseband::hciCreateConnection %d -> %d clk_offset %d pageto %d\n", 
	     bb.bd_addr_, bb.bd_addr_, addr, clock_offset, pageto); 
    /* Set up the request_q single instance */
    bb.request_q_.bd_addr      = addr; 
    bb.request_q_.clock_offset = clock_offset;
    bb.request_q_.valid        = TRUE;

    /* I am not sure about these... */
    bb.tx_clock_ = CLKN;
    
    if(call BTBaseband.getSessionInProg() == SCHED_IN_PROG) {
      assert(0);
    }
    bb.tms_[PAGE_TM].period = pageto; 
    dbg(DBG_BT, "TODO: We need bb.tdd_state == IDLE && bb.role_  & AS_MASTER... dont we?\n");

  }	
  
} /* Module... */


