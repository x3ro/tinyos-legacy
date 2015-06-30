/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * Link estimator for MultiHop router.  Assists with MultiHopDataM
 * in assigning routes and forwarding messages.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module MultiHopLQIM {

  provides {
    interface StdControl;
    interface RouteSelect;
    interface RouteControl;
    interface RouteStatistics;
  }

  uses {
    interface SPSend;
    interface ReceiveMsg;
    interface Detect as BaseStation;
    interface Random;
    interface Timer as RouteTimer;
  }

}
implementation {

  enum {
    MHOP_INVALID_PARENT = TOS_BCAST_ADDR,
    MHOP_INVALID_COST = 0x7FFF,
    MHOP_INVALID_HOPCOUNT = 0xFF,
  };

  /***************************** VARIABLES *****************************/

  uint16_t m_updateInterval;       // time between route updates (in sec)

  TOS_Msg m_routemsg;              // route beacon message
  sp_message_t m_spmsg;
  bool m_ispending;                // is a message send pending?
  
  // keep a list of parents, switch between them when acks fail
  ParentEntry parents[MHOP_PARENT_SIZE];
  uint8_t m_parent;
  uint16_t m_seqNo;

  void sendRouteUpdate();
  void insert(TOS_Msg* _msg, TOS_MHopMsg* _mhopmsg, BeaconMsg* _bmsg);
  void evict(int number);
  void nullify(int number);
  int find(uint16_t addr);
  void selectParent();
  uint16_t electNextHop(uint8_t _retries, TOS_MsgPtr _msg);

  /***************************** HELPER FUNCTIONS **********************/

  uint16_t correlation(uint8_t v) {
    uint16_t c = (80 - (v - 40));
    c = (((c * c) >> 3) * c) >> 3;
    return c;
  }

  void sendRouteUpdate() {
    int i;
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)&m_routemsg.data[0];
    BeaconMsg* _bmsg = (BeaconMsg*)&_mhopmsg->data[0];

    if (m_ispending == TRUE)
      return;

    // update all parents, evict parents that have timed out
    for (i = 0; i < MHOP_PARENT_SIZE; i++) {
      if (parents[i].addr != MHOP_INVALID_PARENT) {
	// time out parents if we haven't heard from them in a while
	parents[i].lastheard++;
	// evict parents if they exceed a timeout
	if (parents[i].lastheard > MHOP_BEACON_TIMEOUT) {
	  evict(i);
	}
      }
    
      // update our parent selection
      selectParent();
    }

    atomic {
      _mhopmsg->sourceaddr = _mhopmsg->originaddr = TOS_LOCAL_ADDRESS;
      _mhopmsg->ttl = 1;
      _bmsg->hopcount = parents[m_parent].hopcount;
      _bmsg->parent = parents[m_parent].addr;
      _bmsg->cost = parents[m_parent].cost + parents[m_parent].estimate;
      _mhopmsg->originseqno = m_seqNo;
      _mhopmsg->seqno = m_seqNo++;
    }

    if (!m_ispending) {
      if (call SPSend.send( &m_spmsg, m_spmsg.msg, TOS_BCAST_ADDR, offsetof(TOS_MHopMsg,data) + sizeof(BeaconMsg) ) == SUCCESS) {
	m_ispending = TRUE;
      }
    }
  }

  void nullify(int _parent) {
    parents[_parent].addr = MHOP_INVALID_PARENT;
    parents[_parent].cost = MHOP_INVALID_COST;
    parents[_parent].estimate = MHOP_INVALID_COST;
    parents[_parent].hopcount = MHOP_INVALID_HOPCOUNT;
  }

  void evict(int _parent) {
    // if we're currently connected to the base station
    // keep the parent active
    if (((TOS_LOCAL_ADDRESS == MHOP_BASE_STATION_ADDR) ||
	 (call BaseStation.isConnected())) && 
	(parents[_parent].addr == TOS_UART_ADDR)) {
      // don't nullify a parent if they're the current base station
      parents[_parent].lastheard = 0;
    }
    else {
      // this parent may be nullified
      nullify(_parent);
    }
  }

  int find(uint16_t addr) {
    int i;
    for (i = 0; i < MHOP_PARENT_SIZE; i++) {
      if (parents[i].addr == addr)
	return i;
    }
    return -1;
  }

  void insert(TOS_Msg* _msg, TOS_MHopMsg* _mhopmsg, BeaconMsg* _bmsg) {
    int i;
    bool found = FALSE;
    bool changes = FALSE;

    // update if in our parent list
    for (i = 0; i < MHOP_PARENT_SIZE; i++) {
      if (_mhopmsg->sourceaddr == parents[i].addr) {
	// don't allow a cycle to form or use a bad parent
	found = TRUE;
	if (_bmsg->hopcount == MHOP_INVALID_HOPCOUNT) {
	  evict(i);
	  changes = TRUE;
	}
	else if (_bmsg->parent == TOS_LOCAL_ADDRESS) {
	  // weaken the neighbor because it has set us as its parent
	  parents[i].cost = parents[i].cost + (parents[i].cost >> 2);
	}
	else {
	  parents[i].lastheard = 0;
	  parents[i].cost = _bmsg->cost;
	  parents[i].estimate = correlation(_msg->lqi);
	  parents[i].hopcount = _bmsg->hopcount + 1;
	}
      }
    }

    // if this parent is currently not in our table,
    // find out if they are better than our current options
    if (!found) {
      // if the neighbor has no parent, don't consider them
      if ((_bmsg->hopcount == MHOP_INVALID_HOPCOUNT) ||
	  (_bmsg->parent == TOS_LOCAL_ADDRESS) ||
	  (TOS_LOCAL_ADDRESS == MHOP_BASE_STATION_ADDR) ||
	  (call BaseStation.isConnected())) {
      }
      else {
	for (i = 0; i < MHOP_PARENT_SIZE; i++) {
	  // make sure you don't pick a parent that creates a cycle
	  if (((uint32_t) _bmsg->cost + (uint32_t) correlation(_msg->lqi) 
	       <
	       ((uint32_t) parents[i].cost + (uint32_t) parents[i].estimate) -
	       (((uint32_t) parents[i].cost + (uint32_t) parents[i].estimate) >> 2))) {
	    evict(i);
	    changes = TRUE;
	    parents[i].lastheard = 0;
	    parents[i].addr = _mhopmsg->sourceaddr;
	    parents[i].cost = _bmsg->cost;
	    parents[i].estimate = correlation(_msg->lqi);
	    parents[i].hopcount = _bmsg->hopcount + 1;
	    break;
	  }
	}
      }
    }

    if (changes)
      selectParent();
  }

  void selectParent() {
    int i;
    int newparent = m_parent;
    uint16_t parentestimate = parents[m_parent].cost + parents[m_parent].estimate;

    // if our parent is invalid, pick the best parent
    if (parents[m_parent].addr == MHOP_INVALID_PARENT) {
      for (i = 0; i < MHOP_PARENT_SIZE; i++) {
	if (parents[i].cost + parents[i].estimate < parentestimate) {
	  newparent = i;
	  parentestimate = parents[i].cost + parents[i].estimate;
	}
      }
    }
    // if we have a parent, don't switch unless they're worthwhile
    else {
      for (i = 0; i < MHOP_PARENT_SIZE; i++) {
	if (((uint32_t) parents[i].cost + (uint32_t) parents[i].estimate)
	    <
	    ((uint32_t) parentestimate) -
	    (((uint32_t) parentestimate) >> 2)) {
	  newparent = i;
	  parentestimate = parents[i].cost + parents[i].estimate;
	}
      }
    }
    m_parent = newparent;
  }

  // select the next hop parent based on the number of retries
  uint16_t electNextHop(uint8_t _retries, TOS_MsgPtr _msg) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;
    int i, j, selectaddr = 0;
    uint8_t size;
    uint8_t min;
    // don't include the current parent
    struct {
      uint16_t addr;
      uint16_t estimate;
    } parentsort[MHOP_PARENT_SIZE - 1];
    
    // cycle around parents
    // equivalent to _retries % MHOP_PARENT_SIZE w/o the division
    while (_retries >= MHOP_PARENT_SIZE)
      _retries -= MHOP_PARENT_SIZE;

    // if == 0, then use the current parent as long as it isn't already there
    if ((_retries == 0) &&
	(_mhopmsg->sourceaddr != parents[m_parent].addr) &&
	(_mhopmsg->originaddr != parents[m_parent].addr)) {
      return parents[m_parent].addr;
    }

    // create a new sorted array of parents, parentsort[]
    j = 0;
    for (i = 0; i < MHOP_PARENT_SIZE; i++) {
      // don't select our parent or an invalid parent for the next hop
      // when this message is being retried
      if ((i != m_parent) && (parents[i].addr != TOS_BCAST_ADDR)) {
	// make sure we don't create a cycle
	if ((_mhopmsg->sourceaddr != parents[i].addr) &&
	    (_mhopmsg->originaddr != parents[i].addr)) {
	  parentsort[j].addr = parents[i].addr;
	  parentsort[j].estimate = parents[i].estimate + parents[i].cost;
	  j++;
	}
	// prevent cycles
	else {
	  // JP: 2006/12/26:
	  // don't evict, it may be a transient cycle due to multiple parents
	  // evict(j);
	  // selectParent();
	}
      }
    }

    if (j < _retries - 1) {
      _retries = j + 1;
    }

    // if no other valid parents are found, retry our previous parent
    // which will be the broadcast address if there are no parents in the
    // table
    if (j == 0) {
      return parents[m_parent].addr;
    }

    size = j;
    min = 0;

    // pick an entry between 0 and _retries - 1 (not including our parent)
    for (j = 0; j < _retries - 1; j++) {
      for (i = 0; i < size; i++) {
	if ((parentsort[i].estimate != 0xFFFF) &&
	    ((parentsort[i].estimate < parentsort[(int)min].estimate) ||
	     (parentsort[(int)min].estimate == 0xFFFF))) {
	  min = i;
	}
      }
      selectaddr = parentsort[(int)min].addr;
      parentsort[(int)min].estimate = 0xFFFF;
    }

    return selectaddr;
  }

  /************************* DETECT (BASE STATION) *********************/

  void setBaseStation() {
    int i;
    parents[0].addr = TOS_UART_ADDR;
    parents[0].cost = 0;
    parents[0].estimate = 0;
    parents[0].hopcount = 0;
    for (i = 1; i < MHOP_PARENT_SIZE; i++) 
      nullify(i);
  }

  event void BaseStation.connected() {
    setBaseStation();
  }

  event void BaseStation.disconnected() {
    if (TOS_LOCAL_ADDRESS != 0)
      nullify(0);
  }

  /***************************** STDCONTROL ****************************/

  command result_t StdControl.init() {
    int i;

    m_updateInterval = MHOP_BEACON_PERIOD;

    for (i = 0; i < MHOP_PARENT_SIZE; i++) {
      nullify(i);
    }

    if ((TOS_LOCAL_ADDRESS == MHOP_BASE_STATION_ADDR) ||
	(call BaseStation.isConnected())) {
      setBaseStation();
    }

    m_spmsg.msg = &m_routemsg;

    call Random.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call RouteTimer.start(TIMER_ONE_SHOT, ((call Random.rand() & 0x3f) << 2) + ((uint32_t)m_updateInterval << 10));
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /***************************** ROUTE TIMER ***************************/

  task void fireNextTimer() {
    call RouteTimer.start(TIMER_ONE_SHOT, ((uint32_t)m_updateInterval << 10) + 1 );
  }

  event result_t RouteTimer.fired() {
    post fireNextTimer();
    sendRouteUpdate();
    return SUCCESS;
  }

  /***************************** SENDMSG (Route Updates) ***************/ 

  event void SPSend.sendDone(sp_message_t* msg, sp_message_flags_t flags, sp_error_t success) {
    if (msg->msg == &m_routemsg) {
      m_ispending = FALSE;
    }
  }

  /***************************** ROUTE SELECT **************************/

  command bool RouteSelect.isActive() {
    return (parents[m_parent].addr != MHOP_INVALID_PARENT);
  }

  command bool RouteSelect.isDuplicate(TOS_MsgPtr _msg, uint8_t id) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;

    if ((TOS_LOCAL_ADDRESS != MHOP_BASE_STATION_ADDR) &&
	(!(call BaseStation.isConnected()))) {
      if (_mhopmsg->ttl == 0)
	return TRUE;
    }

    return FALSE;
  }

  command result_t RouteSelect.selectRoute(TOS_MsgPtr _msg, uint8_t _type, 
					   uint8_t _retries) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;

    // if the message was a broadcast and we have no parent, return fail
    // or if the message has timed out in the system (ttl == 0)
    if ((TOS_LOCAL_ADDRESS != MHOP_BASE_STATION_ADDR) &&
	(!(call BaseStation.isConnected()))) {
      if (((_msg->addr == TOS_BCAST_ADDR) && (parents[m_parent].addr == TOS_BCAST_ADDR)) || (_mhopmsg->ttl == 0)) {
      return FAIL;
      }
    }

    // was the message a local message or a forwarded message
    if ((_retries == 0) && (_mhopmsg->originaddr != TOS_LOCAL_ADDRESS)) {
      _mhopmsg->seqno = m_seqNo++;
      if (_mhopmsg->ttl > 0)
	_mhopmsg->ttl--;
    }
    
    _msg->addr = electNextHop(_retries, _msg);
    _mhopmsg->sourceaddr = TOS_LOCAL_ADDRESS;

    return SUCCESS;
  }

  command result_t RouteSelect.initializeFields(TOS_MsgPtr _msg, uint8_t _type) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;

    _msg->addr = 0; // initialize local message to no particular parent
    _mhopmsg->sourceaddr = _mhopmsg ->originaddr = TOS_LOCAL_ADDRESS;
    _mhopmsg->originseqno = _mhopmsg->seqno = m_seqNo++;
    _mhopmsg->ttl = parents[m_parent].hopcount * 4;

    return SUCCESS;
  }

  command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr _msg, uint16_t* _length) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)(_msg->data);
    *_length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);
    return _mhopmsg->data;
  }

  /***************************** ROUTE CONTROL *************************/

  command uint16_t RouteControl.getParent() {
    return parents[m_parent].addr;
  }

  command uint8_t RouteControl.getQuality() {
    return 255 - (parents[m_parent].estimate >> 5);
  }

  command uint8_t RouteControl.getDepth() {
    return parents[m_parent].hopcount;
  }

  command uint8_t RouteControl.getOccupancy() {
    return 0;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr _msg) {
    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;
    return _mhopmsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t _interval) {
    m_updateInterval = _interval;
    return SUCCESS;
  }

  command result_t RouteControl.manualUpdate() {
    sendRouteUpdate();
    return SUCCESS;
  }

  /***************************** RECEIVEMSG (Route Update) *************/

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr _msg) {

    TOS_MHopMsg* _mhopmsg = (TOS_MHopMsg*)_msg->data;
    BeaconMsg* _bmsg = (BeaconMsg*)_mhopmsg->data;

    insert(_msg, _mhopmsg, _bmsg);

    return _msg;
  }

  /***************************** RECEIVEMSG (Route Update) *************/

  command uint8_t RouteStatistics.getNeighborSize() {
    return MHOP_PARENT_SIZE;
  }

  command void RouteStatistics.getNeighbors(uint16_t* neighbors, uint8_t length) {
    int i;
    for (i = 0; (i < MHOP_PARENT_SIZE) || (i < length); i++) {
      neighbors[i] = parents[i].addr;

    }
  }

  command void RouteStatistics.getNeighborQuality(uint16_t* quality, uint8_t length) {
    int i;
    for (i = 0; (i < MHOP_PARENT_SIZE) || (i < length); i++) {
      quality[i] = parents[i].estimate;
    }
  }

  command uint8_t RouteStatistics.getRetransmissions() {
    return 0;
  }

  command void RouteStatistics.resetRetransmissions() {
  }
}
