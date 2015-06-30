module PowerMgmtM {
  provides {
    interface StdControl;
    command result_t setPowerMode(uint8_t);
  }

  uses {
    interface StdControl as CommControl;
    interface StdControl as ComponentControl;
    
    command result_t softStart();
    command result_t softStop();

    command result_t PowerEnable();
    command result_t PowerDisable();

    interface StdControl as RadioControl;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
#endif

    interface Receive;
    interface Drip;
    interface Naming;

    interface Timer as PowerChangeTimer;

    interface MgmtAttr as MA_LPLMode;

    interface Leds;

    interface Time;
  }
}

implementation {

  NamingMsg namingMsgCache;
  PowerMgmtCmdMsg cmdMsgCache;

#ifdef DBG_POWERMGMT
  uint32_t wakeupTime;
  uint32_t sleepTime;
#endif

  command result_t StdControl.init() {
    call MA_LPLMode.init(sizeof(uint8_t), MA_TYPE_UINT);
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Drip.init(); (void) unique("Drip");
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command result_t setPowerMode(uint8_t mode) {
    cmdMsgCache.powerMode = mode;
    call PowerChangeTimer.start(TIMER_ONE_SHOT, LPL_CHANGE_DELAY);
    return SUCCESS;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
				   uint16_t payloadLen) {
#ifdef DBG_POWERMGMT
    tos_time_t theTime;
#endif

    NamingMsg *namingMsg = (NamingMsg *) payload;
    PowerMgmtCmdMsg *cmdMsg = 
      (PowerMgmtCmdMsg *) call Naming.getBuffer(namingMsg);

    memcpy(&namingMsgCache, namingMsg, sizeof(namingMsgCache));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(cmdMsgCache));
    
    if (!call Naming.isEndpoint(namingMsg))
      return msg;

    switch (cmdMsg->powerMode) {
    case POWERMGMT_ON:
#ifdef DBG_POWERMGMT
      theTime = call Time.get();
      wakeupTime = theTime.low32;
#endif
      call Leds.redOn();
      call PowerDisable();
      call softStart();
      call ComponentControl.start();
      call PowerChangeTimer.start(TIMER_ONE_SHOT, 
				  (cmdMsg->changeDelay == 0 ? 
				   LPL_CHANGE_DELAY : cmdMsg->changeDelay));
      break;

    case POWERMGMT_LPL:
      break;

    case POWERMGMT_SLEEP:
#ifdef DBG_POWERMGMT
      theTime = call Time.get();
      sleepTime = theTime.low32;
#endif
      call PowerChangeTimer.start(TIMER_ONE_SHOT,
				  (cmdMsg->changeDelay == 0 ? 
				   LPL_SLEEP_DELAY : cmdMsg->changeDelay));
      break;
    case POWERMGMT_HIBERNATE:
      // For now, make the node inoperative until a power cycle
      call ComponentControl.stop();
      call RadioControl.stop();
      call PowerEnable();
      break;
    default:
      return msg;
    }

    return msg;
  }

  event result_t PowerChangeTimer.fired() {

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
    result_t result;
#endif

    switch (cmdMsgCache.powerMode) {

    case POWERMGMT_ON:
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
      atomic result = call SetListeningMode(CC1K_FPL);
      if (!result) {
	call PowerChangeTimer.start(TIMER_ONE_SHOT, LPL_CHANGE_RETRY_DELAY); 
      } else 
#endif
      {
	call Leds.redOff();
      }
      break;

    case POWERMGMT_SLEEP:
      call softStop();
      call ComponentControl.stop();
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
      atomic result = call SetListeningMode(CC1K_LPL);      
      if (!result) {
	call PowerChangeTimer.start(TIMER_ONE_SHOT, LPL_CHANGE_RETRY_DELAY); 
      } else 
#endif
      {
	call Leds.redOff();
	call PowerEnable();
      }
      break;

    case POWERMGMT_LPL:
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
      atomic result = call SetListeningMode(CC1K_LPL);      
      if (!result)
	call PowerChangeTimer.start(TIMER_ONE_SHOT, LPL_CHANGE_RETRY_DELAY);
#endif
      break;

    case POWERMGMT_HIBERNATE:
      call ComponentControl.stop();
      call RadioControl.stop();
      call PowerEnable();
      break;
    }

    return SUCCESS;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg, void *pData) {

    if (call Naming.isIntermediary(&namingMsgCache)) {
      PowerMgmtCmdMsg *cmdMsg;
      NamingMsg *namingMsg = (NamingMsg*) pData;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
      /* Drop into long-preamble mode to retransmit a wakeup msg */
      if (cmdMsgCache.powerMode == POWERMGMT_ON) {
	atomic call SetListeningMode(CC1K_LPL);
	call PowerChangeTimer.start(TIMER_ONE_SHOT, LPL_CHANGE_RETRY_DELAY);
      }
#endif

      memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));

      call Naming.prepareRebroadcast(msg, namingMsg);

      cmdMsg = (PowerMgmtCmdMsg *) call Naming.getBuffer(namingMsg);
      memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

      call Drip.rebroadcast(msg, pData, sizeof(namingMsgCache)
			    + sizeof(cmdMsgCache));
      return SUCCESS;
    }
    return FAIL;
  }

  event result_t MA_LPLMode.getAttr(uint8_t *buf) {
    uint8_t lplMode = 0;
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_XSM)    
    atomic lplMode = call GetListeningMode();
#endif
    memcpy(buf, &lplMode, sizeof(lplMode));
    return SUCCESS;
  }
}

