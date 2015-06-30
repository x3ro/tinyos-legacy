//includes EventLoggerPerl;

module CC1000InterfaceM {
  provides {
    interface StdControl;
  }

  uses {
    interface Receive;
    interface Drip;
    interface Naming;

//    interface EventLogger;

    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
    interface CC1000Control;

    interface Timer as ChangeTimer;

    interface MgmtAttr as MA_RFPower;
    interface MgmtAttr as MA_LPLMode;
  }
}

implementation {

  NamingMsg namingMsgCache;
  CC1000InterfaceDripMsg cmdMsgCache;

  enum {
    CHANGE_DELAY = 8192,
  };

  command result_t StdControl.init() {
    call MA_RFPower.init(sizeof(uint8_t));
    call MA_LPLMode.init(sizeof(uint8_t));
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Drip.init();
    (void)unique("Drip");
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }  

  event result_t ChangeTimer.fired() {
    if (cmdMsgCache.rfPowerChanged) {
      uint8_t result;
      result = call CC1000Control.SetRFPower(cmdMsgCache.rfPower);
/*
      <snms>
	 logEvent("RF: %1d Result: %1d", cmdMsgCache.rfPower, result);
      </snms>
*/
    }

    if (cmdMsgCache.lplPowerChanged) {
      uint8_t result;
      atomic result = call SetListeningMode(cmdMsgCache.lplPower);
/*
      <snms>
	 logEvent("LPL: %1d Result: %1d", cmdMsgCache.lplPower, result);
      </snms>
*/
    }

    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, 
				   void* payload, uint16_t payloadLen) {

    NamingMsg *namingMsg = (NamingMsg *) payload;
    CC1000InterfaceDripMsg *cmdMsg = 
      (CC1000InterfaceDripMsg *) call Naming.getBuffer(namingMsg);
/*
    uint8_t namingSize = sizeof(NamingMsg);
    uint8_t cmdSize = sizeof(CC1000InterfaceDripMsg);
    uint8_t changeByte;
    changeByte = ((uint8_t*)&cmdMsgCache)[0];
*/

    memcpy(&namingMsgCache, namingMsg, sizeof(NamingMsg));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(CC1000InterfaceDripMsg));

/*
      <snms>
	 logEvent("CB: %1d RF: %1d LPL: %1d NamingSize: %1d CmdSize: %1d", changeByte, cmdMsg->rfPower, cmdMsg->lplPower, namingSize, cmdSize);
      </snms>    
*/

    if (!call Naming.isEndpoint(namingMsg))
      return msg;

    call ChangeTimer.stop();
    call ChangeTimer.start(TIMER_ONE_SHOT, CHANGE_DELAY);

    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void* payload) {

    if (call Naming.isIntermediary(&namingMsgCache)) {
      CC1000InterfaceDripMsg *cmdMsg;
      
      NamingMsg *namingMsg = (NamingMsg*) payload;
      memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));

      call Naming.prepareRebroadcast(msg, namingMsg);

      cmdMsg = (CC1000InterfaceDripMsg *) call Naming.getBuffer(namingMsg);
      memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

      call Drip.rebroadcast(msg, payload, sizeof(namingMsgCache) + 
			    sizeof(cmdMsgCache));
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t MA_RFPower.getAttr(uint8_t *buf) {
    uint8_t rfPower = call CC1000Control.GetRFPower();
    memcpy(buf, &rfPower, sizeof(rfPower));
    return SUCCESS;
  }

  event result_t MA_LPLMode.getAttr(uint8_t *buf) {
    uint8_t lplMode;
    atomic lplMode = call GetListeningMode();
    memcpy(buf, &lplMode, sizeof(lplMode));
    return SUCCESS;
  }
}



