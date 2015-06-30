//$Id: DrainGroupManagerM.nc,v 1.3 2005/07/16 01:30:26 gtolle Exp $

module DrainGroupManagerM {
  provides interface DrainGroup;

  uses interface Intercept;
  uses interface Send;
  uses interface SendMsg;
  uses interface GroupManager;
}
implementation {
  TOS_Msg msgBuf;
  bool msgBufBusy;

  command result_t DrainGroup.joinGroup(uint16_t group, uint16_t timeout) {
    uint16_t length;

    DrainGroupRegisterMsg *regMsg = (DrainGroupRegisterMsg*) 
      call Send.getBuffer(&msgBuf, &length);

    if (msgBufBusy) { return FAIL; }
    msgBufBusy = TRUE;

    regMsg->group = group;
    regMsg->timeout = timeout; // XXX: pick something good

    if (call SendMsg.send(TOS_DEFAULT_ADDR,
			  sizeof(DrainGroupRegisterMsg),
			  &msgBuf) == FAIL) {
      msgBufBusy = FALSE;
      dbg(DBG_ROUTE, "DrainGroupManagerM: couldn't send group-join %d\n", group);
      return FAIL;
    } else {
      dbg(DBG_ROUTE, "DrainGroupManagerM: joining group %d\n", group);
      call GroupManager.joinGroup(group, timeout);
    }	

    return SUCCESS;
  }

  event result_t Intercept.intercept(TOS_MsgPtr msg, void* payload, 
				     uint16_t payloadLen) {

    DrainGroupRegisterMsg *regMsg = (DrainGroupRegisterMsg*) payload;

    call GroupManager.joinForward(regMsg->group, regMsg->timeout);

    dbg(DBG_ROUTE, "DrainGroupManagerM: becoming forwarder for group %d\n", 
	regMsg->group);

    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    // do-nothing
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == &msgBuf) {
      msgBufBusy = FALSE;
    }
    return SUCCESS;
  }
}
