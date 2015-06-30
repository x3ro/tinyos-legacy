includes PowerMgmt;

module HelloM {
  provides {
    interface StdControl;
  }

  uses {
    interface Leds;

#if defined(BOARD_MICASB)
    interface StdControl as Sounder;
#elif defined(BOARD_XSM)
    interface Sounder;
#endif

#if defined(PLATFORM_MICA2)
    interface HardwareId;
#elif defined(PLATFORM_XSM)
    interface SerialID as HardwareId;
#endif
    
    interface Timer as BlinkTimer;
    interface SendMsg;
    interface ReceiveMsg;

    interface Receive;
    interface Drip;
    interface Naming;

#ifndef PLATFORM_PC
    command result_t setPowerMode(uint8_t mode);
    interface InternalFlash as IFlash;
#endif

    interface MgmtAttr as MA_Group;
    interface MgmtAttr as MA_ProgramName;
    interface MgmtAttr as MA_ProgramCompileTime;
    interface MgmtAttr as MA_ProgramCompilerID;
    interface MgmtAttr as MA_MoteSerialID;

    interface Random;

    interface StdControl as SNMSControl;
  }
}

implementation {

  void startHelloMsg();
  void sendHelloMsg();
  void sleepMode();
  void hibernateMode();
  void pingDone();

  enum {
    PING_NONE,
    PING_LOCAL,
    PING_TREE,
  };

  enum {
    BLINK_NONE = 0,
    BLINK_HIBERNATE = 1,
    BLINK_BOOTUP = 2,
    BLINK_BOOTED = 3,
    BOOTUP_BLINK_COUNT = 9,
  };

  TOS_Msg msgBuf;

  uint8_t blinkMode = BLINK_NONE;
  uint8_t blinkCount = 0;

  uint8_t  *hardwareIdBuf;
  uint8_t  mode;

  bool msgBufBusy = FALSE;
  bool queryBusy = FALSE;
  bool sticky = FALSE;
  bool sound = FALSE;

  NamingMsg namingMsgCache;
  HelloCmdMsg cmdMsgCache;

  command result_t StdControl.init() {

    call Leds.init();

    call SNMSControl.init();

    call Drip.init(); (void)unique("Drip");

    call MA_Group.init(sizeof(uint8_t), MA_TYPE_UINT);
    call MA_ProgramName.init(10, MA_TYPE_TEXTSTRING);
    call MA_ProgramCompileTime.init(sizeof(uint32_t), MA_TYPE_UNIXTIME);
    call MA_ProgramCompilerID.init(sizeof(uint32_t), MA_TYPE_OCTETSTRING);
    call MA_MoteSerialID.init(8, MA_TYPE_OCTETSTRING);

    return SUCCESS;
  }

  command result_t StdControl.start() {
    
    uint8_t resetHist;

/* Hibernation Disabled - Power Switch Now Present (get)    
    uint16_t bootCount;
    
    call IFlash.read((uint8_t*)IFLASH_HELLO_BOOTCOUNT_ADDR, 
		     &bootCount, sizeof(bootCount));    
    
    if (bootCount == HELLO_FIRST_BOOT) {
      bootCount = 0;
    } else {
      bootCount++;
    }

    call IFlash.write((uint8_t*)IFLASH_HELLO_BOOTCOUNT_ADDR, 
		      &bootCount, sizeof(bootCount));    

#if defined(PLATFORM_XSM) || defined(HELLO_HIBERNATE_ALL_PLATFORMS)
    if (bootCount == 0) {
      // It's the first boot...enter hibernation
      blinkMode = BLINK_HIBERNATE;
      blinkCount = 2;
      call BlinkTimer.start(TIMER_ONE_SHOT, 256);
      hibernateMode();
      return SUCCESS;
    }
#endif
*/

#ifndef PLATFORM_PC
    call IFlash.read((uint8_t*)BL_RESET_HISTORY, &resetHist, 
		     sizeof(uint8_t));
#endif

#ifdef PLATFORM_XSM
    if ((resetHist & BL_RESET_LOG_ENTRY_MASK) != BL_NETPROG_RESET) {
#endif
      // Begin startup sequence
      blinkMode = BLINK_BOOTUP;
      blinkCount = BOOTUP_BLINK_COUNT;
      call BlinkTimer.start(TIMER_ONE_SHOT, 256);

#if defined(BOARD_MICASB)
      call Sounder.start();
#elif defined(BOARD_XSM)
      call Sounder.setInterval(7372800UL/(2*4000));
#endif

#ifdef PLATFORM_XSM      
    } else {
      blinkMode = BLINK_BOOTUP;
      blinkCount = 1;
      call BlinkTimer.start(TIMER_ONE_SHOT, 256);
    }
#endif

    return SUCCESS; 
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t BlinkTimer.fired() {
    
    switch (blinkMode) {
/*
    case BLINK_HIBERNATE:
      switch (blinkCount) {
      case 2:
	call Leds.set(5);
	break;
      case 1:
	call Leds.set(2);
	break;
      case 0:
	call Leds.set(0);
	hibernateMode();
      }
      break;
*/    
    case BLINK_BOOTUP:
      if (blinkCount > 1) {
#if defined(BOARD_XSM)	
	call Sounder.Beep(0xffff);
#endif
	startHelloMsg();
	
	blinkCount--;
	call BlinkTimer.start(TIMER_ONE_SHOT, 256);
	      
      } else if (blinkCount == 1) {
	
	blinkCount = 0;
	blinkMode = BLINK_BOOTED;
	call Leds.redOff();
	
#if defined(BOARD_MICASB)
	call Sounder.stop();
#elif defined(BOARD_XSM)
	call Sounder.Off();
#endif

	call SNMSControl.start();

#ifndef HELLO_NO_SLEEP
	sleepMode();
#endif
      }
      break;
      
    case BLINK_BOOTED:
      if (sound) {
#if defined(BOARD_MICASB)
	call Sounder.start();
#elif defined(BOARD_XSM)
	call Sounder.setInterval(7372800UL/(2*4000));
	call Sounder.Beep(0xffff);
#endif
      }
      if (mode == PING_LOCAL) {
	startHelloMsg(); 
      } else {
	pingDone();
      }
      break;
    }
    
    return SUCCESS;
  }

  void startHelloMsg() {
    HelloMsg *helloMsg = (HelloMsg*) (&msgBuf)->data;

    msgBufBusy = TRUE;
    
#if defined(PLATFORM_MICA2) || defined(PLATFORM_XSM)    
    if (!call HardwareId.read((char*)&(helloMsg->hardwareId))) {
      sendHelloMsg();
    }
#else
    memset(helloMsg->hardwareId, 0xff, 8);
    sendHelloMsg();
#endif
  }
  
  void sendHelloMsg() {
    HelloMsg *helloMsg = (HelloMsg*) (&msgBuf)->data;
      
    strcpy(helloMsg->programName, G_Ident.program_name);
    helloMsg->userHash = IDENT_USER_HASH;
    helloMsg->unixTime = IDENT_UNIX_TIME;
    helloMsg->sourceAddr = TOS_LOCAL_ADDRESS;

    if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(HelloMsg), &msgBuf)) {
      msgBufBusy = FALSE;
    }
  }
  
  void sleepMode() {
#ifndef PLATFORM_PC
    call setPowerMode(POWERMGMT_SLEEP);
#endif
  }

  void hibernateMode() {
#ifndef PLATFORM_PC
    call setPowerMode(POWERMGMT_HIBERNATE);
#endif
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, 
				  result_t success) {

    if (pMsg == &msgBuf && msgBufBusy == TRUE) {
      msgBufBusy = FALSE;

      if (blinkMode == BLINK_BOOTUP) {
	// Still in startup sequence
	call Leds.redToggle(); 
	
      } else if (blinkMode == BLINK_BOOTED) {
	pingDone();
      }
    }
    return SUCCESS;
  }

  void pingDone() {
    if (sticky) {
      call BlinkTimer.start(TIMER_ONE_SHOT, 2048);
      
    } else {
      call Leds.redOff(); 
#if defined(BOARD_MICASB)
      call Sounder.stop();
#elif defined(BOARD_XSM)
      call Sounder.Off();
#endif
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    HelloReqMsg *helloReqMsg = (HelloReqMsg*) &m->data;
    
    if (helloReqMsg->reqAddr == TOS_LOCAL_ADDRESS ||
	helloReqMsg->reqAddr == TOS_BCAST_ADDR) {

      if (blinkCount == 0) {
	
	call Leds.redOn();
	mode = PING_LOCAL;
	call BlinkTimer.start(TIMER_ONE_SHOT, 
			      call Random.rand() % 4096);
      }
    }
    return m;
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
				   uint16_t payloadLen) {

    NamingMsg *namingMsg = (NamingMsg *) payload;
    HelloCmdMsg *cmdMsg = 
      (HelloCmdMsg *) call Naming.getBuffer(namingMsg);
    
    memcpy(&namingMsgCache, namingMsg, sizeof(namingMsgCache));
    memcpy(&cmdMsgCache, cmdMsg, sizeof(cmdMsgCache));
    
    if (!call Naming.isEndpoint(namingMsg))
      return msg;

    sound = FALSE;
    mode = PING_NONE;
    sticky = FALSE;

    if (cmdMsg->light) {
      call Leds.redOn();
    }

    if (cmdMsg->sound) {
      sound = TRUE;
    }

    if (cmdMsg->local) {
      mode = PING_LOCAL; 
    } 

    if (cmdMsg->sticky) {
      sticky = TRUE;
    }

    if (blinkCount == 0) {
      call BlinkTimer.start(TIMER_ONE_SHOT, call Random.rand() % 4096);
    }

    return msg;
  }

  event result_t Drip.rebroadcastRequest(TOS_MsgPtr msg,
					 void *pData) {

    if (call Naming.isIntermediary(&namingMsgCache)) {

      HelloCmdMsg *cmdMsg;
      
      NamingMsg *namingMsg = (NamingMsg*) pData;
      memcpy(namingMsg, &namingMsgCache, sizeof(namingMsgCache));

      call Naming.prepareRebroadcast(msg, namingMsg);

      cmdMsg = (HelloCmdMsg *) call Naming.getBuffer(namingMsg);
      memcpy(cmdMsg, &cmdMsgCache, sizeof(cmdMsgCache));

      call Drip.rebroadcast(msg, pData, 
			    sizeof(namingMsgCache)+sizeof(cmdMsgCache));
      return SUCCESS;
    }

    return FAIL;
  }

  event result_t MA_Group.getAttr(uint8_t *buf) {
    memcpy(buf, &TOS_AM_GROUP, sizeof(TOS_AM_GROUP));
    return SUCCESS;
  }

  event result_t MA_ProgramName.getAttr(uint8_t *buf) {
    strncpy(buf, G_Ident.program_name, IDENT_MAX_PROGRAM_NAME_LENGTH);
    return SUCCESS;
  }
  
  event result_t MA_ProgramCompileTime.getAttr(uint8_t *buf) {
    memcpy(buf, &G_Ident.unix_time, sizeof(G_Ident.unix_time));
    return SUCCESS;
  }

  event result_t MA_ProgramCompilerID.getAttr(uint8_t *buf) {
    uint8_t i;
    for(i = 0; i < sizeof(G_Ident.user_hash); i++) {
      buf[i] = ((uint8_t*)(&G_Ident.user_hash))[sizeof(G_Ident.user_hash) - 1 - i];
    }
    // This is an octet-string, so we must store it in big-endian
//    memcpy(buf, &G_Ident.user_hash, sizeof(G_Ident.user_hash));
    return SUCCESS;
  }

  event result_t MA_MoteSerialID.getAttr(uint8_t *buf) {
    hardwareIdBuf = buf;
#if defined(PLATFORM_MICA2)
    if (call HardwareId.read(buf)) {
      queryBusy = TRUE;
      return FAIL; 
    } else {
      return SUCCESS;
    }
#else
    memset(buf, 0xff, 8);
    return SUCCESS;
#endif
  }

  task void callHWAttrDone() {
    call MA_MoteSerialID.getAttrDone(hardwareIdBuf);
  }

#if defined(PLATFORM_MICA2) || defined(PLATFORM_XSM)

#if defined(PLATFORM_MICA2)
  event result_t HardwareId.readDone(uint8_t *buf, result_t ok) {

#elif defined(PLATFORM_XSM)
  event result_t HardwareId.readDone() {

#endif

    if (msgBufBusy == TRUE)
      sendHelloMsg();
    if (queryBusy == TRUE) {
      queryBusy = FALSE;
      post callHWAttrDone();
    }
    return SUCCESS;
  }
#endif
}
  



