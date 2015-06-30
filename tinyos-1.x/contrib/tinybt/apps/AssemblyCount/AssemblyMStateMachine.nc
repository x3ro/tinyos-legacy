/*
  Assembly program - second version of self assembly program
  Based on an approach where children are looking for their parents.
  This file contains most the state machine.

  Copyright (C) 2002 & 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* **********************************************************************
 * **********************************************************************
 * **********************************************************************
 * **********************************************************************
 * Bluetooth handling
 * **********************************************************************
 * **********************************************************************
 * **********************************************************************
 * *********************************************************************/

/* **********************************************************************
 * **********************************************************************
 * Error handling
 * **********************************************************************
 * *********************************************************************/

/**
 * Callback for Bluetooth errors on bt0.
 * 
 * <p>Will call btfail.</p>
 *
 * @param err Bluetooth errorcode (see types/btpackets.h)
 * @param param Any additional information */
async event void Bluetooth0.error(errcode err, uint16_t param) {
  btfail(bt_dev_0, err, param);
}
/**
 * Callback for Bluetooth errors on bt1.
 * 
 * <p>Will call btfail.</p>
 *
 * @param err Bluetooth errorcode (see types/btpackets.h)
 * @param param Any additional information */
async event void Bluetooth1.error(errcode err, uint16_t param) {
  btfail(bt_dev_1, err, param);
}
  
/* **********************************************************************
 * Handle buffers through the postComplete event
 * The buffers are just released
 * At the same time, it is checked if there are any outstanding buffers
 * and if so, one is tried to be posted.
 * *********************************************************************/
/**
 * Post the first buffer in the queue for bt0, if one is present.
 * 
 * <p>Checks the queue, if a packet is available, try to post it, if if
 * fails, reinsert the packet at the front of the queue.</p> */
task void checkDelay0() {
  if (delay_pending(bt_dev_0)) {
    hci_acl_data_pkt * tmp = delay_get(bt_dev_0);
    if (call Bluetooth0.postAcl(tmp) == FAIL) {
      delay_putfront(bt_dev_0, tmp);
    }
  }
} 

/**
 * Post the first buffer in the queue for bt1, if one is present.
 * 
 * <p>Checks the queue, if a packet is available, try to post it, if if
 * fails, reinsert the packet at the front of the queue.</p> */
task void checkDelay1() {
  if (delay_pending(bt_dev_1)) {
    hci_acl_data_pkt * tmp = delay_get(bt_dev_1);
    if (call Bluetooth1.postAcl(tmp) == FAIL) {
      delay_putfront(bt_dev_1, tmp);
    }
  }
} 

/**
 * Callback for the noCompletedPkts event for bt0.
 *
 * <p>Calls checkDelay0.</p>
 * 
 * @param pkt The number of completed packets
 * @return The parameter pkt */
event gen_pkt * Bluetooth0.noCompletedPkts(num_comp_pkts_pkt *p) {
  post checkDelay0();
  return (gen_pkt*) p;
}

/**
 * Callback for the noCompletedPkts event for bt1.
 *
 * <p>Calls checkDelay1.</p>
 * 
 * @param pkt The number of completed packets
 * @return The parameter pkt */
event gen_pkt * Bluetooth1.noCompletedPkts(num_comp_pkts_pkt *p) {
  post checkDelay1();
  return (gen_pkt*) p;
}

/**
 * Callback for the postComplete event for bt0.
 * 
 * <p>Calls checkDelay0, then inserts the buffer into the 
 * pool of buffers.</p>
 *
 * @param p The buffer that the lower layer have completed sending to the Bluetooth hardware. */
async event void Bluetooth0.postComplete(gen_pkt * p) {
  post checkDelay0();
  buffer_put(p);
  return;
}

/**
 * Callback for the postComplete event for bt1.
 * 
 * <p>Calls checkDelay1, then inserts the buffer into the 
 * pool of buffers.</p>
 *
 * @param p The buffer that the lower layer have completed sending to the Bluetooth hardware. */
async event void Bluetooth1.postComplete(gen_pkt * p) {
  post checkDelay1();
  buffer_put(p);
  return;
}

/* **********************************************************************
 * **********************************************************************
 * Ready events
 * Signalled when a device is ready
 * **********************************************************************
 * *********************************************************************/
    
/* **********************************************************************
 * Child READY event
 * *********************************************************************/

/**
 * Child interface (bt0) state change; NotReady + ready =>
 * ReadBDAddrPending.
 *
 * <p>Child interface state change<br>
 * <table>
 * <tr><td> event         </td><td> ready </td></tr>
 * <tr><td> assumed state </td><td> NotReady </td></tr>
 * <tr><td> action        </td><td> postReadBDAddr </td></tr>
 * <tr><td> new state     </td><td> ReadBDAddrPending </td></tr>
 * </table></p> */
task void childBTReady() {
  if (csNotReady != childState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, DEBUG_CHILDEVENT_READY);
  }
  //TODO: This call could actually fail.... Check it, fail properly.
  call Bluetooth0.postReadBDAddr(buffer_get());
  childState = csReadBDAddrPending;
  debug(DEBUG_CHILDSTATE_READBDADDRPENDING);
}

/**
 * Callback for Bluetooth ready event for bt0. 
 *
 * <p>Posts childBTReady.</p> */
event void Bluetooth0.ready() {
  debug(DEBUG_CHILDEVENT_READY);
  post childBTReady();
}

/* **********************************************************************
 * Parent READY event
 * *********************************************************************/
/**
 * Parent interface (bt1) state change; NotReady + ready => Closed.
 * 
 * <p>Parent interface state change<br>
 * <table>
 * <tr><td> event         </td><td> ready </td></tr>
 * <tr><td> assumed state </td><td> NotReady </td></tr>
 * <tr><td> action        </td><td> <none> </td></tr>
 * <tr><td> new state     </td><td> Closed </td></tr>
 * </table></p> */
task void parentBTReady() {
  if (psNotReady != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_READY);
  }
  parentState = psClosed;
  debug(DEBUG_PARENTSTATE_CLOSED);
}
/**
 * Callback for Bluetooth ready event for bt1.
 * 
 * <p>Posts parentBTReady.</p> */
event void Bluetooth1.ready() {
  debug(DEBUG_PARENTEVENT_READY);
  post parentBTReady();
}

/* **********************************************************************
 * **********************************************************************
 * Child interface readBDAddrComplete event
 * **********************************************************************
 * *********************************************************************/

/**
 * Enable scan on the Child interface (bt0). 
 *
 * <p>A helper funktion. Post a scanChange, then sets the child
 * interface state to scanEnablePending.</p> */
static void childScanEnable() {
  postScanChange(bt_dev_0, CHILD_SCAN_ENABLEMODE);
  childState = csScanEnablePending;
  debug(DEBUG_CHILDSTATE_SCANENABLEPENDING);
}

/**
 * Child interface (bt0) state change; readBDAddrPending +
 * readBDAddrComplete => scanEnablePending.
 * 
 * <p>Child interface state change<br>
 * <table>
 * <tr><td> event         </td><td> readBDAddrComplete </td></tr>
 * <tr><td> assumed state </td><td> readBDAddrPending </td></tr>
 * <tr><td> action        </td><td> postScanEnable </td></tr>
 * <tr><td> new state     </td><td> scanEnablePending </td></tr>
 * </table></p> */
task void childReadBDAddr() {
  if (csReadBDAddrPending != childState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_READBDADDRCOMPLETE);
  }
  childScanEnable();
}

/**
 * Callback for when the Bluetooth layer have figured out the local Bluetooth address.
 *
 * <p>Posts childReadBDAddr.</p>
 *
 * @param p The address of the bt0 device
 * @return An unused packet */
event gen_pkt * Bluetooth0.readBDAddrComplete(read_bd_addr_pkt *p) {
  debug(DEBUG_CHILDEVENT_READBDADDRCOMPLETE);
  if (p->start->status) {
    FAIL2(FAIL_GENERAL, FAIL_BT_READBDADDR);
  } else {
    memcpy(&childAddr,
	   &p->start->bdaddr,
	   sizeof(bdaddr_t));
    post childReadBDAddr();
  }
  return (gen_pkt *) p;
}


/* **********************************************************************
 * **********************************************************************
 * Child interface scanEnableComplete event
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; scanEnablePending +
 * scanEnableComplete => inqPending.
 * 
 * <p>Child interface state change<br>
 * <table>
 * <tr><td> event         </td><td> scanEnableComplete </td></tr>
 * <tr><td> assumed state </td><td> scanEnablePending </td></tr>
 * <tr><td> action        </td><td> postInq </td></tr>
 * <tr><td> new state     </td><td> idle </td></tr>
 * </table></p> */
task void childScanEnableComplete() {
  /* Check transition */
  if (csScanEnablePending != childState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_SCANENABLECOMPLETE);
  }
  
  /* Change state */
  childState = csIdle;
  debug(DEBUG_CHILDSTATE_IDLE);
  signal Assembly.ready(&childAddr);
}
/* The actual bluetooth event handler follows further below, as it
   handles both disable and enable completed events */
  
/* **********************************************************************
 * **********************************************************************
 * Child InquiryComplete event handler. 
 * **********************************************************************
 * *********************************************************************/
/** Callback handler for inquiryComplete for bt0.
 * 
 * <p>Signals Assembly.joinTimeout.</p> */
event void Bluetooth0.inquiryComplete() {
  /* PostInq, if we have not yet found a parent */
  if (csInqPending == childState) {
    childState = csIdle;
    signal Assembly.joinTimeout();
    debug(DEBUG_CHILDSTATE_IDLE);
  }
}

/* **********************************************************************
 * **********************************************************************
 * Child interface inq result handler
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; inqPending + inqResult =>
 * inqCancelPending.
 *
 * <p>Child interface event handler<br>
 * <tr><td> event         </td><td> inqResult </td></tr>
 * <tr><td> assumed state </td><td> inqPending </td></tr>
 * <tr><td> action        </td><td> postInqCancel </td></tr>
 * <tr><td> new state     </td><td> inqCancelPending </td></tr>
 * </table></p> */
task void childInquiryResult() {
  /* This check may very well be a bit too strict */
  if (childState != csInqPending
      || childInqResultPkt == NULL) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_INQRESULT);
  }
  if (FAIL == call Bluetooth0.postInquiryCancel(buffer_get())) {
    FAIL2(FAIL_POST | bt_dev_0, FAIL_POST_INQCANCEL);
  }
  childState = csInqCancelPending;
  debug(DEBUG_CHILDSTATE_INQCANCELPENDING);
}



/**
 * Bluetooth inquiryResult handler for bt0.
 *
 * <p>Posts childInquiryResult.</p>
 *
 * @param p The inquiry result packet
 * @return An unused buffer. */
event gen_pkt* Bluetooth0.inquiryResult(inq_resp_pkt* p) {
  /* Ignore if we are already treating a result */
  INT_START;
  INT_DISABLE;
  if (childInqResultPkt != NULL) {
    INT_ENABLE;
    return (gen_pkt *) p;
  }
  childInqResultPkt = p;
  INT_ENABLE;
  INT_STOP;
  post childInquiryResult();
  return buffer_get();
}

/* **********************************************************************
 * **********************************************************************
 * child inqCancel complete
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; inqCancelPending +
 * inqCancelComplete => connCompletePending.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> inqCancelComplete </td></tr>
 * <tr><td> assumed state </td><td> inqCancelPending </td></tr>
 * <tr><td> action        </td><td> postConnReq </td></tr>
 * <tr><td> new state     </td><td> connCompletePending </td></tr>
 * </table></p> */
task void childInqCancelComplete() {
  create_conn_pkt * conn_create;
  /* This may be a little too much??? */
  if (csInqCancelPending != childState
      || childInqResultPkt == NULL
      || connections[PARENT_CONNECTION_NUM].state != invalid) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_INQCANCELCOMPLETE);
  }
  conn_create = (create_conn_pkt *) buffer_get();
  // conn_create->cp.pkt_type = HCI_DM3 | HCI_DH3;
  conn_create->cp.pkt_type = HCI_DM1 | HCI_DH1;
    
  // conn_create->cp.pkt_type = 0x0008 | 0x0010;
  memcpy(&(conn_create->cp.bdaddr),
	 &(childInqResultPkt->start->infos->bdaddr),
	 sizeof(bdaddr_t));
    
  // The child interface always wants to be the slave... 
  // check 4.5.5 in the HCI spec // Master(0x0)/slave(0x1) switch
  conn_create->cp.role_switch    = 0x01;
  conn_create->cp.pscan_rep_mode = childInqResultPkt->start->infos->pscan_rep_mode;
  conn_create->cp.pscan_mode     = childInqResultPkt->start->infos->pscan_mode;
  conn_create->cp.clock_offset   = childInqResultPkt->start->infos->clock_offset;
    
  rst_send_pkt((gen_pkt *) conn_create);
  conn_create->start              = &conn_create->cp;
    
  if (FAIL == call Bluetooth0.postCreateConn(conn_create)) {
    FAIL2(FAIL_POST | bt_dev_0, FAIL_POST_CREATECONN);
  }

  /* Set the new state */
  childState          = csConnCompletePending;
  debug(DEBUG_CHILDSTATE_CONNCOMPLETEPENDING);
  
  /* Set the state for the connection */
  connections[PARENT_CONNECTION_NUM].state = connCompletePending;
  connections[PARENT_CONNECTION_NUM].btdev = bt_dev_0;
  memcpy(&(connections[PARENT_CONNECTION_NUM].bdaddr),
	 &(childInqResultPkt->start->infos->bdaddr),
	 sizeof(bdaddr_t));
  /* Handle will be filled out by connectionComplete */

  /* Release the buffer - not protected, no need to */
  childInqResultPkt 
    = (inq_resp_pkt *) buffer_put((gen_pkt *) childInqResultPkt);
  return;
}

/**
 * Bluetooth handler for inquiryCancelComplete on bt0.
 * 
 * <p>Posts childInqCancelComplete.</p> */
event gen_pkt* Bluetooth0.inquiryCancelComplete(status_pkt* pkt) {
  debug(DEBUG_CHILDEVENT_INQCANCELCOMPLETE);
  /* Hmm. We do not need to check the status, as they reason we
     can fail is that there is no inq going on, I think. 
  if (0 != pkt->start->status) {
    FAIL2(FAIL_COMPLETE | bt_dev_0, FAIL_COMPLETE_INQCANCEL);
    return (gen_pkt*) pkt;
  }
  */
  post childInqCancelComplete();
  return (gen_pkt*) pkt;
}  


/* **********************************************************************
 * **********************************************************************
 * Connection request for the child interface
 // NOTE: This code is currently broken/unused
 * **********************************************************************
 * *********************************************************************/
#ifdef NOT_USED_NEEDS_FIXING
/**
 * Child interface (bt0) state change; inqPending + connRequest =>
 * connCompletePending.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> connRequest </td></tr>
 * <tr><td> assumed state </td><td> inqPending </td></tr>
 * <tr><td> action        </td><td> postAcceptConn, (abortInq), (stopTimer) </td></tr>
 * <tr><td> new state     </td><td> connCompletePending </td></tr>
 * </table></p> */
task void childConnRequest() {
  accept_conn_req_pkt * accept_conn; 
  if (csInqPending != childState 
      || childConnRequestPkt == NULL) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, DEBUG_CHILDEVENT_CONNREQUEST);
  }

  /* The connection request is in childConnectRequestPkt */
  accept_conn        = (accept_conn_req_pkt *) buffer_get();
  rst_send_pkt((gen_pkt *) accept_conn);
  accept_conn->start = &accept_conn->cp;
  
  memcpy(&accept_conn->cp.bdaddr,
	 &childConnRequestPkt->start->bdaddr,
	 sizeof(bdaddr_t));
  accept_conn->cp.role = 0x1; // Master(0x0)/slave(0x1) switch
  if (FAIL == call Bluetooth0.postAcceptConnReq(accept_conn)) {
    FAIL2(FAIL_POST | bt_dev_0, FAIL_POST_CONNACCEPT);
  }
  /* Drop connreq buffer */
  childConnRequestPkt 
    = (conn_request_pkt *) buffer_put((gen_pkt *) childConnRequestPkt);

  childState          = csConnCompletePending;
  debug(DEBUG_CHILDSTATE_CONNCOMPLETEPENDING);
}
#endif /* NOT USED */

/**
 * Bluetooth level handler for connRequest on bt0.
 * 
 * <p>NOTE: Unused currently, otherwise posts childConnRequest.</p> */
event gen_pkt* Bluetooth0.connRequest(conn_request_pkt* pkt) {
  // NOTE: This code is currently broken/unused
  return (gen_pkt *) pkt;
  debug(DEBUG_CHILDEVENT_CONNREQUEST);
#ifdef NOT_USED
  childConnRequestPkt = pkt;
  post childConnRequest();
  return (gen_pkt *) buffer_get();
#endif /* NOT_USED */
}

/* **********************************************************************
 * **********************************************************************
 * Connection Complete event for the child interface
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; connCompletePending +
 * connComplete => writeLinkPolicyPending.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> connComplete </td></tr>
 * <tr><td> assumed state </td><td> connCompletePending </td></tr>
 * <tr><td> action        </td><td> postWriteLinkPolicy </td></tr>
 * <tr><td> new state     </td><td> writeLinkPolicyPending </td></tr>
 * </table></p> */
task void childConnComplete() {
  write_link_policy_pkt * wpkt;
  /* Check the transition */
  if (childState != csConnCompletePending 
      || connections[PARENT_CONNECTION_NUM].state != connCompletePending) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_CONNCOMPLETE);
  }
  /* Post a link policy change command */
  wpkt = (write_link_policy_pkt *)buffer_get();
  rst_send_pkt((gen_pkt *) wpkt);
  wpkt->start = &(wpkt->cp);
  wpkt->start->handle = connections[PARENT_CONNECTION_NUM].handle;
  wpkt->start->policy = 0xF;
  if (FAIL == call Bluetooth0.postWriteLinkPolicy(wpkt)) {
    FAIL2(FAIL_POST | bt_dev_0, FAIL_POST_WRITELINKPOLICY);
  };
  /* Change the state */
  connections[PARENT_CONNECTION_NUM].state = policyPending;
  childState                               = csWriteLinkPolicyPending;
  debug(DEBUG_CHILDSTATE_WRITELINKPOLICYPENDING);
}
  
/**
 * Child interface (bt0) state change; connCompletePending +
 * connFailed => inqPending.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> connFailed </td></tr>
 * <tr><td> assumed state </td><td> connCompletePending </td></tr>
 * <tr><td> action        </td><td> postInq </td></tr>
 * <tr><td> new state     </td><td> inqPending </td></tr>
 * </table></p> */
task void childConnFailed() {
  if (childState != csConnCompletePending) { 
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_CONNFAILED);
  }

  /* Note: this relies on the fact that we are using single inq */
  /* PostInq 
  if (FAIL == call Bluetooth0.postInquiryDefault(buffer_get())) {
    FAIL2(FAIL_POST | bt_dev_0, FAIL_POST_INQ);
  }
  */
  connections[PARENT_CONNECTION_NUM].state = invalid;
  /* childState = csInqPending;
     debug(DEBUG_CHILDSTATE_INQPENDING); */
  childState = csIdle;
  signal Assembly.joinTimeout();
  debug(DEBUG_CHILDSTATE_IDLE);
}  
/**
 * Bluetooth level event handler for connComplete on bt0.
 * 
 * <p>Posts either childConnFailed or childConnComplete.</p>
 *
 * @param p The connection complete packet.
 * @return An unused packet */
event gen_pkt* Bluetooth0.connComplete(conn_complete_pkt* p) {
  debug(DEBUG_CHILDEVENT_CONNCOMPLETE);
  if (p->start->status != 0) {
    /* Used to fail if connection failed. Not any more...
       FAIL4(FAIL_GENERAL, FAIL_CONNECTION_CONNNOTFOUND,
       p->start->status, p->start->status >> 4); */
    post childConnFailed();
  } else {
    if (connections[PARENT_CONNECTION_NUM].state == connCompletePending) {
      connections[PARENT_CONNECTION_NUM].handle = p->start->handle;
      /* Already filled by inqCancelComplete or... hmm 
      memcpy(&(connections[PARENT_CONNECTION_NUM].bdaddr),
	     &p->start->bdaddr,
	     sizeof(bdaddr_t));
      */
      post childConnComplete();
    } else {
      FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	    DEBUG_CHILDEVENT_CONNCOMPLETE);
    }
  }
  return (gen_pkt*) p;
}

/* **********************************************************************
 * **********************************************************************
 * child writeLinkPolicy complete
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; writeLinkPolicyPending +
 * writeLinkPolicyComplete => postScanDisablePending.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> writeLinkPolicyComplete </td></tr>
 * <tr><td> assumed state </td><td> writeLinkPolicyPending </td></tr>
 * <tr><td> action        </td><td> postScanDisable </td></tr>
 * <tr><td> new state     </td><td> postScanDisablePending </td></tr>
 * </table></p> */
task void childWriteLinkPolicyComplete() {
  if (childState != csWriteLinkPolicyPending
      || connections[PARENT_CONNECTION_NUM].state != policyPending) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_WRITELINKPOLICYCOMPLETE);
  }
  postScanChange(bt_dev_0, CHILD_SCAN_DISABLEMODE);
  /* The connection for the child interface goes directly to
     connected, because the other end must take initiative to
     switch. */
  connections[PARENT_CONNECTION_NUM].state = connected;
  childState                               = csScanDisablePending;
  debug(DEBUG_CHILDSTATE_SCANDISABLEPENDING);
}

/**
 * Bluetooth level event handler for writeLinkPolicyComplete on bt0.
 * 
 * <p>Posts childWriteLinkPolicyComplete.</p>
 * 
 * @param p A packet containing information about the new/current policy */
event void Bluetooth0.writeLinkPolicyComplete(write_link_policy_complete_pkt* p) {
  post childWriteLinkPolicyComplete();
  return;
}

/* **********************************************************************
 * **********************************************************************
 * child scanDisableComplete event
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; scanDisablePending +
 * scanDisableComplete => haveParent.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> scanDisableComplete </td></tr>
 * <tr><td> assumed state </td><td> scanDisablePending </td></tr>
 * <tr><td> action        </td><td> signal openParentInterface, signal Assembly.newConnection() </td></tr>
 * <tr><td> new state     </td><td> haveParent </td></tr>
 * </table></p> */
task void childScanDisableComplete() {
#ifdef ASSEMBLY_CHATTER    
  char buf[80];
  char * bufp;
#endif
  /* Check transition */
  if (csScanDisablePending != childState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, childState, 
	  DEBUG_CHILDEVENT_SCANENABLECOMPLETE);
  }
#ifdef FRIDAY_TEST
  /* Friday test: only bc and be can have kids */
  if (0xbc == childAddr.b[0] || 0xbe == childAddr.b[0]) {
#endif
    /* signal parentConnected to the other bluetooth interface */
    post openParentInterface();
#ifdef FRIDAY_TEST
  }
#endif
  
  /* Update state */
  childState = csHaveParent;
  debug(DEBUG_CHILDSTATE_HAVEPARENT);

  /* signal the Assembly interface stuff */
  signal Assembly.newConnection(&(connections[PARENT_CONNECTION_NUM]));
  
#ifdef ASSEMBLY_CHATTER    
  strcpy(buf, "Got master ");
  bufp = buf + strlen(buf);
  bdaddrToAscii(bufp, &connections[PARENT_CONNECTION_NUM].bdaddr);
  sendChildCharACL(buf);
#endif
}
/**
 * Bluetooth level event handler for writeScanEnableComplete for bt0.
 * 
 * <p>Posts either childScanEnableComplete or childScanDisableComplete.</p>
 * 
 * @param p Status of the scan change command
 * @return An unused packet */
event gen_pkt * Bluetooth0.writeScanEnableComplete(status_pkt * p) {
  debug(DEBUG_CHILDEVENT_SCANENABLECOMPLETE);
  if (0 != p->start->status) {
    FAIL2(FAIL_COMPLETE | bt_dev_0 , FAIL_COMPLETE_SCANENABLE);
    return (gen_pkt*) p;
  }
  if (csScanEnablePending == childState) {
    post childScanEnableComplete();
  } else {
    post childScanDisableComplete();
  }
  return (gen_pkt*) p;
}
  
/* **********************************************************************
 * **********************************************************************
 * Child disconnected event
 * **********************************************************************
 * *********************************************************************/
/* Forward declare the handler to handle that we want to shut down the
   parent interface. */
task void closeParentInterface();
/**
 * Child interface (bt0) state change; haveParent + connDisconnect =>
 * waitForParentInqDisable.
 *
 * <p>Child interface state change<br>
 * <tr><td> event         </td><td> connDisconnect </td></tr>
 * <tr><td> assumed state </td><td> haveParent </td></tr>
 * <tr><td> action        </td><td> posts closeParentInterface, signal Assembly.disconnection() </td></tr>
 * <tr><td> new state     </td><td> waitForParentInqDisable </td></tr>
 * </table></p> */
task void childParentDisconnected() {
  if (childState != csHaveParent 
      || connections[PARENT_CONNECTION_NUM].state != connected) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, 
	  childState, DEBUG_CHILDEVENT_CONNDISCONNECT);
  }
  // childParentConnHandle = 0;
  connections[PARENT_CONNECTION_NUM].state = invalid;
  signal Assembly.disconnection(&(connections[PARENT_CONNECTION_NUM]));
  /* Will be restarted by the other interface, when it is no 
     longer inq'able. */
  childState                               = csWaitForParentInqDisable;
  debug(DEBUG_CHILDSTATE_WAITFORPARENTINQDISABLE);
  post closeParentInterface();
}

/** 
 * Bluetooth level event handler for disconnComplete on bt0.
 *
 * <p>Posts childParentDisconnected.</p>
 *
 * @param p Information about the connection that disconnected
 * @return An unused buffer */
event gen_pkt * Bluetooth0.disconnComplete(disconn_complete_pkt* p) {
  if (0 != p->start->status) {
    FAIL2(FAIL_COMPLETE | bt_dev_0, FAIL_COMPLETE_DISCONNECT);
    return (gen_pkt*) p;
  }
  /* We post for the parent first, as we need to disable inqs */
  post childParentDisconnected();
  return (gen_pkt*) p;
}

/* **********************************************************************
 * **********************************************************************
 * child get parentInqDisabled (pseudo event from parent state machine)
 * **********************************************************************
 * *********************************************************************/
/**
 * Child interface (bt0) state change; waitForParentInqDisable +
 * "parentInqDisabled" => scanEnablePending.
 *
 * <p>Child interface state change<br>
 * <tr><td> "event"       </td><td> parentInqDisabled </td></tr>
 * <tr><td> assumed state </td><td> waitForParentInqDisable </td></tr>
 * <tr><td> action        </td><td> postScanEnable </td></tr>
 * <tr><td> new state     </td><td> scanEnablePending </td></tr>
 * </table></p> */
task void childParentInqDisable() {
  if (childState != csWaitForParentInqDisable 
      || connections[PARENT_CONNECTION_NUM].state != invalid) {
    FAIL3(FAIL_STATEFAIL | bt_dev_0, 
	  childState, DEBUG_CHILDEVENT_PARENTINQDISABLE);
  }
  childScanEnable();
}

  
/* **********************************************************************
 * **********************************************************************
 * Parent connected parent interface event
 * Note, this is triggered from an event on the child interface
 * **********************************************************************
 * *********************************************************************/

/**
 * Parent interface (bt1) state change; Closed + "parentConnected"
 * => scanEnablePending.
 * 
 * <p>Parent interface state change<br>
 * <tr><td> event         </td><td> "parentConnected" </td></tr>
 * <tr><td> assumed state </td><td> Closed </td></tr>
 * <tr><td> action        </td><td> postScanEnable </td></tr>
 * <tr><td> new state     </td><td> scanEnablePending </td></tr>
 * </table></p> */
task void openParentInterface() {
  if (psClosed != parentState) {
      //      || connections[PARENT_CONNECTION_NUM].state != connected) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_CONNCOMPLETE);
  }
  /* Enable scanning on this interface */
  postScanChange(bt_dev_1, PARENT_SCAN_ENABLEMODE);
  parentState = psScanEnablePending;
  debug(DEBUG_PARENTSTATE_SCANENABLEPENDING);
}

/* **********************************************************************
 * **********************************************************************
 * Parent interface scanEnableComplete event
 * **********************************************************************
 * *********************************************************************/

/**
 * Parent interface (bt1) state change; scanEnablePending +
 * scanEnableComplete => Open.
 *
 * <p>Parent interface state change<br>
 * <tr><td> event         </td><td> scanEnableComplete </td></tr>
 * <tr><td> assumed state </td><td> scanEnablePending </td></tr>
 * <tr><td> action        </td><td> <none> </td></tr>
 * <tr><td> new state     </td><td> Open </td></tr>
 * </table></p> */
task void parentScanEnableComplete() {
  if (psScanEnablePending != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_SCANENABLECOMPLETE);
  }
  parentState = psOpen;
  debug(DEBUG_PARENTSTATE_OPEN);
}
/* Bluetooth level event later */

/* **********************************************************************
 * **********************************************************************
 * Connection request for the parent interface
 * **********************************************************************
 * *********************************************************************/
/**
 * Parent interface (bt1) event handler; Open + connRequest =>
 * Open.
 *
 * <p>Parent interface state change<br>
 * <tr><td> event         </td><td> connRequest </td></tr>
 * <tr><td> assumed state </td><td> Open </td></tr>
 * <tr><td> action        </td><td> postAcceptConn </td></tr>
 * </table></p> */
task void parentConnRequest() {
  uint8_t i;
  /* Check state machine */
  if (psOpen != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_CONNREQUEST);
  }
  /* Locate a childInfo that needs accept */
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (needAccept == connections[i].state) {
      accept_conn_req_pkt * accept_conn;
      /* Setup the connection accept packet */
      accept_conn        = (accept_conn_req_pkt *) buffer_get();
      rst_send_pkt((gen_pkt *) accept_conn);
      // accept_conn->end   = &accept_conn->data[200];
      accept_conn->start = &accept_conn->cp;

      memcpy(&accept_conn->cp.bdaddr,
	     &(connections[i].bdaddr),
	     sizeof(bdaddr_t));
      /* The parent will want to be the master - 
	 but we have to change roles after the connection is completed. */
      accept_conn->cp.role = 0x1; // Master(0x0)/slave(0x1) switch
      if (FAIL == call Bluetooth1.postAcceptConnReq(accept_conn)) {
	FAIL2(FAIL_POST | bt_dev_1, FAIL_POST_CONNACCEPT);
      }
      /* Update the status of this child */
      connections[i].state = connCompletePending;
      return;
    }
  }
  /* If we reach here, we had some kind of error */
  FAIL2(FAIL_CONNECTION, FAIL_CONNECTION_CONNREQUEST);
  return;
}

/** 
 * Bluetooth level event handler for connRequest on bt1.
 *
 * <p>Post parentConnRequest.</p>
 * 
 * @param pkt Information about the connection request 
 * @return An unused packet */
event gen_pkt* Bluetooth1.connRequest(conn_request_pkt* pkt) {
  uint8_t i;
  debug(DEBUG_PARENTEVENT_CONNREQUEST);
  /* Locate a free childinfo buffer */
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (connections[i].state == invalid) {
      memcpy(&(connections[i].bdaddr), &(pkt->start->bdaddr), 
	     sizeof(bdaddr_t));
      connections[i].state = needAccept;
      connections[i].btdev = bt_dev_1;
      post parentConnRequest();
      return (gen_pkt *) pkt;
    }
  }
  FAIL2(FAIL_CONNECTION, FAIL_CONNECTION_TOOMANY);
  return NULL;
}

/* **********************************************************************
 * **********************************************************************
 * Parent interface conn complete handler 
 * **********************************************************************
 * *********************************************************************/
/**
 * Parent interface (bt1) event handler; Open + connComplete => Open.
 *
 * <p>Parent interface event handler<br>
 * <tr><td> event         </td><td> connComplete </td></tr>
 * <tr><td> assumed state </td><td> Open </td></tr>
 * <tr><td> action        </td><td> registerConn, sendParentInfo, setPolicy for connection </td></tr>
 * </table></p> */
task void parentConnComplete() {
  uint8_t i;
  /* Check state machine */
  if (psOpen != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_CONNCOMPLETE);
  }
  /* Locate a childInfo that is completed and should need switch  */
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (connComplete == connections[i].state) {
      /* Found it - set the link policy*/
      write_link_policy_pkt * wpkt 
	= (write_link_policy_pkt *)buffer_get();
      rst_send_pkt((gen_pkt *) wpkt);
      wpkt->start = &(wpkt->cp);
      wpkt->start->handle = connections[i].handle;
      wpkt->start->policy = 0xF;
      if (FAIL == call Bluetooth1.postWriteLinkPolicy(wpkt)) {
	FAIL2(FAIL_POST | bt_dev_1, FAIL_POST_WRITELINKPOLICY);
      };
      connections[i].state = policyPending;
      /* connComplete => policyPending => policyComplete */
      return;
    }
  }
  /* If we reach here, we had some kind of error */
  FAIL2(FAIL_CONNECTION, FAIL_CONNECTION_CONNCOMPLETE);
  return;
}
  
/**
 * Bluetooth level event handler for connComplete on bt1.
 *
 * <p>Locates the entry in question. Failure: updates entry
 * Succes: post a parentConnComplete task.</p>
 *
 * @param p Information about the connection
 * @return An unused buffer */
event gen_pkt* Bluetooth1.connComplete(conn_complete_pkt* p) {
  /* Locate the childinfo with the right state and bdaddr */
  uint8_t i;
  debug(DEBUG_PARENTEVENT_CONNCOMPLETE);
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (connCompletePending == connections[i].state) {
      if (0 == memcmp(&(connections[i].bdaddr), 
		      &(p->start->bdaddr), 
		      sizeof(bdaddr_t))) {
	/* Found it */
	if (p->start->status != 0) {
	  /* Trouble - remove the pending */
	  /* FAIL4(FAIL_CONNECTION, FAIL_CONNECTION_CONNNOTFOUND,
	     p->start->status, p->start->status >> 4); */
	  connections[i].state = invalid;
	  return (gen_pkt*) p;
	} else {
	  /* OK - set up for posting .. */
	  connections[i].handle = p->start->handle;
	  connections[i].state = connComplete; 
	  /* connCompletePending => connComplete => policyPending */
	  post parentConnComplete();
	  return (gen_pkt*) p;
	}
      }
    }
  }
  /* If we reach here, trouble */
  FAIL3(FAIL_CONNECTION, FAIL_CONNECTION_CONNNOTFOUND, FAIL_CONNECTION_CONNCOMPLETE);
  return (gen_pkt*) p;
}
  

/* **********************************************************************
 * **********************************************************************
 * Parent link policy set event
 * **********************************************************************
 * *********************************************************************/
/**
 * Parent interface (bt1) event handler; Open +
 * writeLinkPolicyComplete => Open.
 *
 * <p>Parent interface event handler<br>
 * <tr><td> event         </td><td> writeLinkPolicyComplete </td></tr>
 * <tr><td> assumed state </td><td> Open </td></tr>
 * <tr><td> action        </td><td> Change Role </td></tr>
 * </table></p> */
task void parentWriteLinkPolicyComplete() {
  uint8_t i;
  /* Check state machine */
  if (psOpen != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_WRITELINKPOLICYCOMPLETE);
  }
  /* Locate a childInfo that is completed and should need switch  */
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (policyComplete == connections[i].state) {
      /* Found it - post a role change */
      switch_role_pkt * rpkt 
	= (switch_role_pkt *) buffer_get();
      rst_send_pkt((gen_pkt *) rpkt);
      rpkt->start = &(rpkt->cp);
      memcpy(&(rpkt->start->bdaddr), &(connections[i].bdaddr), 
	     sizeof(bdaddr_t));
      rpkt->start->role = 0x0; /* 0 == Master, 1 == slave (4.6.8) */
      if (FAIL == call Bluetooth1.postSwitchRole(rpkt)) {
	FAIL2(FAIL_POST | bt_dev_1, FAIL_POST_SWITCHROLE);
      };
      connections[i].state = switchPending;
      /* policyComplete => switchPending => switched */
      return;
    }
  }
  /* If we reach here, we had some kind of error */
  FAIL2(FAIL_CONNECTION, FAIL_CONNECTION_LINKPOLICY);
  return;
}

/**
 * Bluetooth level event handler for writeLinkPolicyComplete on bt1.
 *
 * <p>Locates the entry in question. Failure: updates entry
 * Succes: post parentWriteLinkPolicyComplete.</p>
 *
 * @param p Information about the connection and policy change */
event void Bluetooth1.writeLinkPolicyComplete(write_link_policy_complete_pkt* p) {
  /* Locate the childinfo with the right state and bdaddr */
  uint8_t i;
  debug(DEBUG_PARENTEVENT_WRITELINKPOLICYCOMPLETE);
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (policyPending == connections[i].state) {
      if (connections[i].handle == p->start->handle) {
	/* Found it */
	if (p->start->status != 0) {
	  /* Trouble - panic - maybe we should disconnect */
	  FAIL2(FAIL_CONNECTION, FAIL_CONNECTION_LINKPOLICY);
	  return;
	} else {
	  /* OK - set up for posting .. */
	  connections[i].state = policyComplete;
	  /* policyPending => policyComplete => switchPending */
	  post parentWriteLinkPolicyComplete();
	  return;
	}
      }
    }
  }
  /* If I reach here, trouble */
  FAIL3(FAIL_CONNECTION, FAIL_CONNECTION_CONNNOTFOUND, FAIL_CONNECTION_LINKPOLICY);
  return;
}
/* **********************************************************************
 * **********************************************************************
 * Parent role switched complete! (Finally)
 * **********************************************************************
 * *********************************************************************/
/**
 * Bluetooth (bt1) event handler for RoleChange.
 * 
 * <p>At this point the connection is set up, and
 * Assembly.newConnection() is signalled.</p>
 *
 * @param pkt The connection whose role changed */
event void Bluetooth1.roleChange(evt_role_change_pkt * pkt) { 
  /* Locate the childinfo with the right state and bdaddr */
  uint8_t i;
  debug(DEBUG_PARENTEVENT_ROLECHANGE);
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (switchPending == connections[i].state) {
      if (0 == memcmp(&(connections[i].bdaddr), 
		      &(pkt->start->bdaddr), 
		      sizeof(bdaddr_t))) {
	/* Found it */
	if (pkt->start->status != 0) {
	  /* TODO: Trouble - panic - maybe we should disconnect 
	     This event ooccurs once in a while. I have no idea why.
	     The other end should set OK to rolechange in its acceptConn, so
	     this should never happen. Perhaps it would be wiser to simply
	     disconnect. 
	     Obviously this does happen, if the connecting end have not
	     set its rolechange correctly. */
	  FAIL4(FAIL_CONNECTION, FAIL_CONNECTION_ROLECHANGE, 
		pkt->start->status, pkt->start->status >> 4);
	  return;
	} else {
	  /* OK - signal .. */
	  connections[i].state = connected;
	  signal Assembly.newConnection(&(connections[i]));
	  /* If friday test: bc can only have one child */
#ifdef FRIDAY_TEST
	  if (0xbc == childAddr.b[0]) {
	    postScanChange(bt_dev_1, PARENT_SCAN_DISABLEMODE);
	  }
#endif
	  return;
	}
      }
    }
  }
  /* If I reach here, trouble */
  FAIL3(FAIL_CONNECTION, FAIL_CONNECTION_CONNNOTFOUND, FAIL_CONNECTION_ROLECHANGE);
  return;
}


/* **********************************************************************
 * **********************************************************************
 * Parent disconnect event
 * **********************************************************************
 * *********************************************************************/
/* Forward declare task that disconnects all children */
task void parentDisconnectChildren();

/** 
 * Bluetooth level event handler for disconnComplete on bt1.
 *
 * <p>Locates the entry, fails or signals Assembly.disconnection().</p>
 * 
 * @param p Information about the connection that was disconnected
 * @return An unused packet */
event gen_pkt * Bluetooth1.disconnComplete(disconn_complete_pkt* p) {
  int i;
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    if (invalid != connections[i].state 
	&& connections[i].handle == p->start->handle) {
      connections[i].state = invalid;
      signal Assembly.disconnection(&(connections[i]));
      /* Check if we are closing, reschedule */
      if (parentState == psClosing) {
	post parentDisconnectChildren();
      }
      return (gen_pkt *) p; 
    }
  }
  /* If we reach here, trouble */
  FAIL3(FAIL_CONNECTION, FAIL_CONNECTION_CONNNOTFOUND, FAIL_CONNECTION_DISCONNCOMPLETE);
  return (gen_pkt *) p;
}

/* **********************************************************************
 * **********************************************************************
 * Parent disconnected parent interface event
 * **********************************************************************
 * *********************************************************************/
/**
 * Parent interface state change; Open + parentDisconnected =>
 * scanDisablePending.
 * 
 * <p>Parent interface state change<br>
 * <tr><td> event         </td><td> parentDisconnected </td></tr>
 * <tr><td> assumed state </td><td> Open </td></tr>
 * <tr><td> action        </td><td> postScanDisable </td></tr>
 * <tr><td> new state     </td><td> scanDisablePending </td></tr>
 * </table></p> */
task void closeParentInterface() {
  if (psOpen != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_PARENTDISCONNECT);
  }
  /* Disable scanning on this interface */
  postScanChange(bt_dev_1, PARENT_SCAN_DISABLEMODE);
  parentState = psScanDisablePending;
  debug(DEBUG_PARENTSTATE_SCANDISABLEPENDING);
}
  
/* **********************************************************************
 * Disconnect from all children
 * *********************************************************************/

/**
 * Disconnect from all children on parent.
 *
 * <p>This is used when we loose the parent, we will have to
 * disconnect from all our children.</p> */
task void parentDisconnectChildren() {
  int i;
  if (parentState != psClosing) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTTASK_DISCONNECTCHILDREN);
  }
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    /* If we have a connCompletePending or better, it needs to be
       disconnected */
    if (invalid != connections[i].state && needAccept != connections[i].state) { 
      disconnect_pkt * pkt = (disconnect_pkt *) buffer_get();
      rst_send_pkt((gen_pkt *) pkt);
      pkt->start = (disconnect_cp *) (pkt->end - DISCONNECT_CP_SIZE);
      pkt->start->handle = connections[i].handle;
      pkt->start->reason = 0x13; /* Seems the proper reason... */
      if (FAIL == call Bluetooth1.postDisconnect(pkt)) {
	/* Try again later... */
	// FAIL();
	buffer_put((gen_pkt *) pkt);
	post childParentInqDisable();
      }
      /* We return and let the close handler repost */
      return;
    }
  }
  /* No one found, make sure that we restart the child interface */
  parentState = psClosed;
  post childParentInqDisable();
}
 
/* **********************************************************************
 * **********************************************************************
 * Parent interface scanEnableComplete event
 * **********************************************************************
 * *********************************************************************/

/**
 * Parent interface (bt1) state change; scanDisablePending +
 * scanDisableComplete => Closed.
 *
 * <p>Parent interface state change<br>
 * <tr><td> event         </td><td> scanDisableComplete </td></tr>
 * <tr><td> assumed state </td><td> scanDisablePending </td></tr>
 * <tr><td> action        </td><td> signal childParentInqDisable </td></tr>
 * <tr><td> new state     </td><td> Closed </td></tr>
 * </table></p> */
task void parentScanDisableComplete() {
  /* Don't mind this, if testing and we are bc */
#ifdef FRIDAY_TEST
  if (0xbc == childAddr.b[0]) {
    return;
  }
#endif
  if (psScanDisablePending != parentState) {
    FAIL3(FAIL_STATEFAIL | bt_dev_1, parentState, 
	  DEBUG_PARENTEVENT_SCANDISABLECOMPLETE);
  }
  /* Make sure all children are disconnected */
  parentState = psClosing;
  debug(DEBUG_PARENTSTATE_CLOSING);
  post parentDisconnectChildren();
}

/**
 * Bluetooth level event handler for writeScanEnableComplete on bt1.
 *
 * <p>Posts either parentScanEnableComplete or parentScanDisableComplete.</p>
 * 
 * @param p Information about the status of the scan change command
 * @return An unused packet */
event gen_pkt * Bluetooth1.writeScanEnableComplete(status_pkt * p) {
  debug(DEBUG_PARENTEVENT_SCANENABLECOMPLETE);
  if (0 != p->start->status) {
    FAIL2(FAIL_COMPLETE | bt_dev_1 , FAIL_COMPLETE_SCANENABLE);
    return (gen_pkt*) p;
  }
  if (psScanEnablePending == parentState) {
    post parentScanEnableComplete();
  } else {
    post parentScanDisableComplete();
  }
  return (gen_pkt*) p;
}

/* **********************************************************************
 * ACL events
 * *********************************************************************/

/**
 * Bluetooth level event handler for recvAcl on bt0.
 * 
 * <p>Signals Assembly.recv().</p>
 * 
 * @param p The data packet
 * @return An unused packet */
async event gen_pkt* Bluetooth0.recvAcl(hci_acl_data_pkt* p) {
  // debug(DEBUG_BT0_ACL_DATA);
  /* This check is a bit to hard, really, but until it is a 
     problem, I will go on with it */
  if (connections[PARENT_CONNECTION_NUM].state != connected) {
    FAIL2(FAIL_CONNECTION, FAIL_PARENT_NOT_CONNECTED);
    return (gen_pkt *) p;
  }
  return (gen_pkt *) signal Assembly.recv(&(connections[PARENT_CONNECTION_NUM]), p);
}

/**
 * Bluetooth level event handler for recvAcl on bt1.
 * 
 * <p>Signals Assembly.recv() or fails if it can not find the
 * connection.</p>
 * 
 * @param p The data packet
 * @return An unused packet */
async event gen_pkt* Bluetooth1.recvAcl(hci_acl_data_pkt* p) {
  int i;
  // debug(DEBUG_BT1_ACL_DATA);
  for (i = FIRST_CHILD_NUM; i < MAX_NUM_CONNECTIONS; i++) {
    /* We can get acl data from the connection before it is switched, 
       which is why the check below is a bit relaxed */
    if (invalid != connections[i].state 
	&& connections[i].handle == (unsigned) p->start->handle) {
      return (gen_pkt *) signal Assembly.recv(&(connections[i]), p);
    }
  }
  /* If we reach here, trouble */
  FAIL3(FAIL_CONNECTION, FAIL_CONNECTION_CONNNOTFOUND, 
	FAIL_CONNECTION_RECVACL);
  return (gen_pkt *) p;
}

/* **********************************************************************
 * **********************************************************************
 * Events that should never happen - actually they should be handled
 * by default handlers, but they are not.
 * **********************************************************************
 * *********************************************************************/

/** Default/dummy/unused event handler */
event gen_pkt* Bluetooth1.readBDAddrComplete(read_bd_addr_pkt* pkt) {
  return (gen_pkt*) pkt;
}
/** Default/dummy/unused event handler */
event gen_pkt* Bluetooth0.readBufSizeComplete(read_buf_size_pkt* pkt) {
  return (gen_pkt *) pkt;
}
/** Default/dummy/unused event handler */
event gen_pkt* Bluetooth1.readBufSizeComplete(read_buf_size_pkt* pkt) {
  return (gen_pkt *) pkt;
}
/** Default/dummy/unused event handler */
event void Bluetooth0.modeChange(evt_mode_change_pkt* p) {
}
/** Default/dummy/unused event handler */
event void Bluetooth1.modeChange(evt_mode_change_pkt* p) {
}
/** Default/dummy/unused event handler */
event void Bluetooth0.roleChange(evt_role_change_pkt * pkt) {
}
/** Default/dummy/unused event handler */
event gen_pkt * Bluetooth0.writeInqActivityComplete(gen_pkt * p) {
  return (gen_pkt*) p;
}
/** Default/dummy/unused event handler */
event gen_pkt * Bluetooth1.writeInqActivityComplete(gen_pkt * p) {
  return (gen_pkt*) p;
}
/** Default/dummy/unused event handler */
event gen_pkt* Bluetooth1.inquiryResult(inq_resp_pkt* p) {
  return (gen_pkt*) p;
}
/** Default/dummy/unused event handler */
event void Bluetooth1.inquiryComplete() {
  return;
}
/** Default/dummy/unused event handler */
event gen_pkt* Bluetooth1.inquiryCancelComplete(status_pkt* pkt) {
  return (gen_pkt*) pkt;
}
/** Default/dummy/unused event handler */
event void Bluetooth0.connPTypeChange(evt_conn_ptype_changed_pkt* p) {
}
/** Default/dummy/unused event handler */
event void Bluetooth1.connPTypeChange(evt_conn_ptype_changed_pkt* p) {
}
