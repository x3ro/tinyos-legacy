/* TOSBaseM
   - captures all the packets that it can hear and report it back to the UART
   - forward all incoming UART messages out to the radio
*/

/**
 * @author Phil Buonadonna
 * Brano Kusy, kusy@isis.vanderbilt.edu (RaTS extension added)
 */

includes TestTimeSyncPollerMsg;
includes FloodRoutingSyncMsg;
includes TimeSyncMsg;
includes Timer;

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

    interface RadioCoordinator as RadioSendCoordinator;
    interface TimeStamping;
    interface Timer;
    interface Leds;
  }
}
implementation
{
#ifndef TIMESYNC_RATE
#define TIMESYNC_RATE 30
#endif
  uint32_t ticks;

  enum {
    QUEUE_SIZE = 50,
    INITIAL_RATE = 5, //TIMESYNC_RATE>>3,
    INITIAL_COUNT = 10, 
    PHASE2_RATE = 5,
    PHASE2_COUNT = 0,
  };

  enum {
    TXFLAG_BUSY = 0x1,
    TXFLAG_TOKEN = 0x2
  };

  TOS_Msg gRxBufPool[QUEUE_SIZE]; 
  TOS_MsgPtr gRxBufPoolTbl[QUEUE_SIZE];
  uint8_t gRxHeadIndex,gRxTailIndex;
  
  TOS_Msg    gTxBuf, tsMsg;

  TOS_MsgPtr gpTxMsg, tsMsgp;
  uint8_t    gTxPendingToken;
  uint8_t    gfTxFlags;

#define tsMsgRoutingData   ((FloodRoutingSyncMsg*)&(tsMsgp->data))
#define tsMsgTokenData     ((ts_data_token *)tsMsgRoutingData->data)

  void initMsg(){
    tsMsgp = &tsMsg;
    
    tsMsgp->group = TOS_AM_GROUP;
    tsMsgp->length = TIMESYNC_TOKEN_SIZE+FLOODROUTINGSYNC_HEADER+TIMESTAMP_LENGTH;
    tsMsgp->type = AM_FLOODROUTINGSYNC;
    tsMsgp->addr = TOS_BCAST_ADDR;

    tsMsgRoutingData->appId = TIMESYNC_ID;
    tsMsgRoutingData->location = TOS_LOCAL_ADDRESS;
    tsMsgRoutingData->nodeId = TOS_LOCAL_ADDRESS;
    tsMsgRoutingData->timeStamp=0;
  }

  task void RadioRcvdTask() {
    TOS_MsgPtr pMsg;
    result_t   Result;

    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");
    atomic {
      pMsg = gRxBufPoolTbl[gRxTailIndex];
      gRxTailIndex++; gRxTailIndex %= QUEUE_SIZE;
    }
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

    tsMsgTokenData->seqNum = 1;
    call Timer.start(TIMER_REPEAT, (uint32_t)1000);
    ticks = 10;
    ticks |= (uint32_t)(INITIAL_COUNT+PHASE2_COUNT)<<16;

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

      if (Msg->type == AM_TIMESYNCPOLL){
        uint32_t arrivalTime = call TimeStamping.getStamp();
        Msg->length = 8;
        Msg->type = 177;
        memcpy(Msg->data,&TOS_LOCAL_ADDRESS,2) ;
        //data+2 contains msg_id set by the poller, don't touch it
        memcpy(Msg->data+4,&arrivalTime,4) ;
        
        //post report();
      }

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
    if (Msg->type == AM_FLOODROUTINGSYNC)
        ++ tsMsgTokenData->seqNum;

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
  
  event result_t Timer.fired(){
    if ( (--ticks & 0xFFFF) != 0)
        return SUCCESS;
    
    if (ticks == 0)
        ticks = TIMESYNC_RATE;
    else{
        uint32_t remaining_ticks = (ticks>>16)-1;
        ticks = remaining_ticks<<16;
        if ( remaining_ticks < PHASE2_COUNT )
            ticks += PHASE2_RATE;
        else
            ticks += INITIAL_RATE;
    }
    
    call Leds.yellowToggle();
    initMsg();
    if (call RadioSend.send(tsMsgp)==SUCCESS)
        call TimeStamping.addStamp(offsetof(FloodRoutingSyncMsg,timeStamp));

    return SUCCESS;
  }

  async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount){
    if( byteCount == 6 ){
        memcpy( (int8_t*)msg->data + FLOODROUTINGSYNC_HEADER+offsetof(ts_data_token, sendingTime),
            (int8_t*)msg->data + offsetof(FloodRoutingSyncMsg,timeStamp),
            4);
        memcpy( (int8_t*)msg->data + FLOODROUTINGSYNC_HEADER+offsetof(ts_data_token, sendingTime)+TIMESTAMP_LENGTH,
            (int8_t*)msg->data + offsetof(FloodRoutingSyncMsg,timeStamp),
            4);
    }

  }
  async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
  async event void RadioSendCoordinator.blockTimer() {}

}  
