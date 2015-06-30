
module RadioControlM {
  provides interface StdControl;
  uses {
    interface StdControl as CommControl;
    interface StdControl as ComponentControl;

    command result_t softStart();
    command result_t softStop();

    interface Receive;
    interface Drip;
    interface Naming;
  }
}

implementation {

  NamingMsg namingMsgCache;
  RadioControlCmdMsg cmdMsgCache;
  
  command result_t StdControl.init() {
    call Drip.init(); (void) unique("Drip");

    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
				   uint16_t payloadLen) {

    NamingMsg *namingMsg = (NamingMsg *) payload;
    RadioControlCmdMsg *cmdMsg = 
      (RadioControlCmdMsg *) call Naming.getBuffer(namingMsg);
    
    memcpy(&namingMsgCache, namingMsg, sizeof(namingMsgCache));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(cmdMsgCache));
    
    if (!call Naming.isEndpoint(namingMsg))
      return msg;
    
    if (cmdMsg->active == TRUE) {
      call softStart();
      call ComponentControl.start();
    } else {
      call softStop();
      call ComponentControl.stop();
    }

    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {

    if (call Naming.isIntermediary(&namingMsgCache)) {
      RadioControlCmdMsg *cmdMsg;
      
      NamingMsg *namingMsg = (NamingMsg*) pData;
      memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));

      call Naming.prepareRebroadcast(msg, namingMsg);

      cmdMsg = (RadioControlCmdMsg *) call Naming.getBuffer(namingMsg);
      memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

      call Drip.rebroadcast(msg, pData, sizeof(namingMsgCache)+sizeof(cmdMsgCache));
      return SUCCESS;
    }
    return FAIL;
  }

}

