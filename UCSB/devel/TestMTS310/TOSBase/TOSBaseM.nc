/* TOSBaseM
   - captures all the packets that it can hear and report it back to the UART
   - forward all incoming UART messages out to the radio
*/

includes CmdMsg;
 
module TOSBaseM {
  provides interface StdControl;
  uses {
    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;
    interface TokenReceiveMsg as UARTTokenReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;

    interface Leds;
  }
}
implementation
{
  enum {
    QUEUE_SIZE = 5
  };

  enum {
    TXFLAG_BUSY = 0x1,
    TXFLAG_TOKEN = 0x2
  };


  TOS_Msg gRxBufPool[QUEUE_SIZE]; 
  TOS_MsgPtr gRxBufPoolTbl[QUEUE_SIZE];
  uint8_t gRxHeadIndex,gRxTailIndex;

  TOS_Msg    gTxBuf;
  TOS_MsgPtr gpTxMsg;
  uint8_t    gTxPendingToken;
  uint8_t    gfTxFlags;

  task void RadioRcvdTask() {
    TOS_MsgPtr pMsg;
    result_t   Result;
	MTS310DataMsg * mts310Data;
	
    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");
    atomic {
      pMsg = gRxBufPoolTbl[gRxTailIndex];
      gRxTailIndex++; 
      gRxTailIndex %= QUEUE_SIZE;
    }
    mts310Data = (struct MTS310DataMsg *)pMsg->data;
    mts310Data->strength = pMsg->strength;
    
    Result = call UARTSend.send(pMsg);
    if (Result != SUCCESS) {
      pMsg->length = 0;
    }
    else {
      call Leds.greenToggle();
    }
  }

  task void UARTRcvdTask() {
    result_t Result;

    dbg (DBG_USR1, "TOSBase forwarding UART packet to Radio\n");
    gpTxMsg->group = TOS_AM_GROUP;
    Result = call RadioSend.send(gpTxMsg);

    if (Result != SUCCESS) {
      atomic gfTxFlags = 0;
    }
    else {
      call Leds.redToggle();
    }
  }

  task void SendAckTask() {
     call UARTTokenReceive.ReflectToken(gTxPendingToken);
     call Leds.yellowToggle();
     atomic {
       gpTxMsg->length = 0;
       gfTxFlags = 0;
     }
  } 

  command result_t StdControl.init() {
    result_t ok1, ok2, ok3;
    uint8_t i;

    for (i = 0; i < QUEUE_SIZE; i++) {
      gRxBufPool[i].length = 0;
      gRxBufPoolTbl[i] = &gRxBufPool[i];
    }
    gRxHeadIndex = 0;
    gRxTailIndex = 0;

    gTxBuf.length = 0;
    gpTxMsg = &gTxBuf;
    gfTxFlags = 0;

    ok1 = call UARTControl.init();
    ok2 = call RadioControl.init();
    ok3 = call Leds.init();

    dbg(DBG_BOOT, "TOSBase initialized\n");

    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();

    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop() {
    result_t ok1, ok2;
    
    ok1 = call UARTControl.stop();
    ok2 = call RadioControl.stop();

    return rcombine(ok1, ok2);
  }

  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr Msg) {
    TOS_MsgPtr pBuf;

    dbg(DBG_USR1, "TOSBase received radio packet.\n");

    if (Msg->crc) {

      /* Filter out messages by group id */
      if (Msg->group != TOS_AM_GROUP)
        return Msg;

      atomic {
	pBuf = gRxBufPoolTbl[gRxHeadIndex];
	if (pBuf->length == 0) {
	  gRxBufPoolTbl[gRxHeadIndex] = Msg;
	  gRxHeadIndex++; gRxHeadIndex %= QUEUE_SIZE;
	}
	else {
	  pBuf = NULL;
	}
      }
      
      if (pBuf) {
	post RadioRcvdTask();
      }
      else {
	pBuf = Msg;
      }
    }
    else {
      pBuf = Msg;
    }

    return pBuf;
  }
  
  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr Msg) {
    TOS_MsgPtr  pBuf;

    dbg(DBG_USR1, "TOSBase received UART packet.\n");

    atomic {
      if (gfTxFlags & TXFLAG_BUSY) {
        pBuf = NULL;
      }
      else {
        pBuf = gpTxMsg;
        gfTxFlags |= (TXFLAG_BUSY);
        gpTxMsg = Msg;
      }
    }

    if (pBuf == NULL) {
      pBuf = Msg; 
    }
    else {
      post UARTRcvdTask();
    }

    return pBuf;

  }

  event TOS_MsgPtr UARTTokenReceive.receive(TOS_MsgPtr Msg, uint8_t Token) {
    TOS_MsgPtr  pBuf;
    
    dbg(DBG_USR1, "TOSBase received UART token packet.\n");

    atomic {
      if (gfTxFlags & TXFLAG_BUSY) {
        pBuf = NULL;
      }
      else {
        pBuf = gpTxMsg;
        gfTxFlags |= (TXFLAG_BUSY | TXFLAG_TOKEN);
        gpTxMsg = Msg;
        gTxPendingToken = Token;
      }
    }

    if (pBuf == NULL) {
      pBuf = Msg; 
    }
    else {

      post UARTRcvdTask();
    }

    return pBuf;
  }
  
  event result_t UARTSend.sendDone(TOS_MsgPtr Msg, result_t success) {
    Msg->length = 0;
    return SUCCESS;
  }
  
  event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {


    if ((gfTxFlags & TXFLAG_TOKEN)) {
      if (success == SUCCESS) {
        
        post SendAckTask();
      }
    }
    else {
      atomic {
        gpTxMsg->length = 0;
        gfTxFlags = 0;
      }
    }
    return SUCCESS;
  }
}  
