module GrouperM {
  provides interface StdControl;
  uses {
    interface Receive;
    interface Drip;
    interface Naming;

    command uint16_t getTreeID();
  }
}

implementation {

  NamingMsg namingMsgCache;
  GrouperCmdMsg cmdMsgCache;
  
  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Drip.init(); (void) unique("Drip");
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
				   uint16_t payloadLen) {

    NamingMsg *namingMsg = (NamingMsg *) payload;
    GrouperCmdMsg *cmdMsg = 
      (GrouperCmdMsg *) call Naming.getBuffer(namingMsg);
    
    memcpy(&namingMsgCache, namingMsg, sizeof(namingMsgCache));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(cmdMsgCache));
    
    if (!call Naming.isEndpoint(namingMsg))
      return msg;

    if (call getTreeID() == cmdMsg->treeID ||
	cmdMsg->treeID == 0xffff) {
      atomic TOS_AM_GROUP = cmdMsg->newGroupID;
    }

    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void* pData) {

    GrouperCmdMsg *cmdMsg;
    NamingMsg *namingMsg = (NamingMsg*) pData;

    if (!call Naming.isIntermediary(&namingMsgCache))
      return FAIL;

    memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));
    
    call Naming.prepareRebroadcast(msg, namingMsg);
    
    cmdMsg = (GrouperCmdMsg *) call Naming.getBuffer(namingMsg);
    memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

    /* JWHUI: what is going on here? they dripMsg and dripMsgData are
     * undeclared and causing compile errors.

       dripMsg = msg;
       dripMsgData = pData;
    */

    call Drip.rebroadcast(msg, pData, 
			  sizeof(namingMsgCache) + 
			  sizeof(cmdMsgCache));
    return SUCCESS;
  }
}

