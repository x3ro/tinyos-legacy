/* 
 * Testing application that tries to use events
 */

includes Params;
includes PiggyBack;
includes AM;
includes MultiHop;
includes TraceFunctions;
#ifdef _WITH_CHANQ_  
includes ChanQ;
#endif

module TinyDBAppM 
{
  provides interface StdControl;
  uses 
  {
    interface Timer;
    interface EventRegister;
    interface EventUse;
    interface StdControl as EventControl;
    interface StdControl as DBControl;
#ifdef _WITH_CHANQ_    
    interface StdControl as ChQControl;
    interface Send as SndData;
    interface Receive as RecvRequest;
#ifdef USE_CQTEST
    interface Send as SendReq;
#endif
#endif
    interface StdControl as PingControl;
    interface Send as ReplyPing;
    interface Receive as RecvPing;
#ifdef INTMSG
    interface StdControl as InControl;
    interface StdControl as OutControl;
#endif
    interface Leds;
#ifdef TRACEROUTE
    //TraceRoute interface
    interface StdControl as TraceRtCtl;
    interface PiggyBack as PiggyFlood;
    interface PiggyBack as PiggyRoute;
#endif
  }
}

implementation
{
  /* 
   * Internal variables
   */

  ParamList params; /* list of event parameters descriptions */
  ParamVals values; /* list of parameter values */
  uint16_t curTime; /* Current time */
  static char* evName = "mytmevt"; /* event name */
  
  /* Trace route variables */
  TOS_Msg buffer; //message buffer we will provide
  uint16_t tracingHost; //host we are going to trace route
  TOS_Msg backBuffer; //message buffer we will provide for back tracing

  command result_t StdControl.init() 
  {
    result_t dbOk;
    result_t eventOk;
    result_t result;
#ifdef TRACEROUTE
    result_t routeOK;
#endif
#ifdef INTMSG
    result_t inOK;
    result_t outOK;
    result_t ioOK;
#endif
    
    atomic 
    {
      memset(&params, 0, sizeof(ParamList));
      params.numParams = 0;
      params.params[0] = UINT16;

      memset(&values, 0, sizeof(ParamList));
      values.numParams = 0;
      values.paramDataPtr[0] = (char*)&curTime;
    }

    dbOk = call DBControl.init();
    eventOk = call EventControl.init();
#ifdef _WITH_CHANQ_    
    call ChQControl.init();
#endif
    call PingControl.init();
#ifdef TRACEROUTE
    routeOK = call TraceRtCtl.init();
    result = rcombine3(dbOk, eventOk, routeOK);
#else
    result = rcombine(dbOk, eventOk);
#endif

#ifdef INTMSG
    inOK = call InControl.init();
    outOK = call OutControl.init();
    ioOK = rcombine(inOK, outOK);
    
    return rcombine(result, ioOK);
#else
    return result;
#endif
  }


  command result_t StdControl.start() 
  {
    call DBControl.start();
    call EventControl.start();
#ifdef _WITH_CHANQ_    
    call ChQControl.start();
#endif
    call PingControl.start();
#ifdef TRACEROUTE
    call TraceRtCtl.start();
#endif

#ifdef INTMSG
    call InControl.start();
    call OutControl.start();
#endif
    call EventRegister.registerEvent(evName, &params);
#ifdef USE_CQTEST
    call Timer.start(TIMER_REPEAT, 40000);
#else
    call Timer.start(TIMER_REPEAT, 2500);
#endif
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    call Timer.stop();
#ifdef TRACEROUTE
    call TraceRtCtl.stop();
#endif
    call EventRegister.deleteEvent(evName);
#ifdef INTMSG
    call InControl.stop();
    call OutControl.stop();
#endif
    call PingControl.stop();
#ifdef _WITH_CHANQ_    
    call ChQControl.stop();
#endif
    call EventControl.stop();
    call DBControl.stop();
    return SUCCESS;
  }
  
  event result_t EventUse.eventDone(char *name, SchemaErrorNo errorNo)
  {
    if (errorNo != SCHEMA_SUCCESS)
      call Leds.redOn();
    else
      call Leds.redOff();
    return SUCCESS;
  }
  
  event result_t Timer.fired()
  {
#ifdef USE_CQTEST
    uint16_t len;
    ChanQMsg* dest = call SendReq.getBuffer(&backBuffer, &len);
#endif
    EventDescPtr evt;
    if (curTime++ == 0xFFFF)
      curTime = 0;
    
    evt = call EventUse.getEvent(evName);
    if (evt && evt->numCmds > 0)
      call EventUse.signalEvent(evName, &values);
#ifdef USE_CQTEST
    dest->addr = 3;
    dest->id = 4;
    call SendReq.send(&backBuffer, len);
    dbg(DBG_USR1, "\nCQ: DATA COLLECTION STARTED\n");
#endif
    return SUCCESS;
  }

#ifdef TRACEROUTE
  /*
   * PiggyBack Flooding interface functions
   */
  event TOS_MsgPtr PiggyFlood.routeReady(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    return msg;
  }

  event result_t PiggyFlood.getBack(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    PiggyMsg* pPMsg = (PiggyMsg*)payload;  
    TOS_MHopMsg* pMHMsg = (TOS_MHopMsg*)backBuffer.data;
    PiggyMsg* pPMHMsg = (PiggyMsg*)pMHMsg->data;

    //Data length in multihop message
    uint16_t len = (TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg, data));
    
    //FIXME: This may be potentially dangerous
    if (pPMsg->idx > nAvail(len))
      pPMsg->idx = nAvail(len);
    memcpy(pPMHMsg, pPMsg, len);
    call PiggyRoute.gatherBack(&backBuffer, pPMsg->source);
    return FAIL;
  }

  /*
   * PiggyBack Routing interface functions
   */
  event TOS_MsgPtr PiggyRoute.routeReady(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    return msg;
  }

  event result_t PiggyRoute.getBack(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    return SUCCESS;
  }
#endif

#ifdef _WITH_CHANQ_    
  /*
   * Channel Quality interface functions
   */
  /*
   * SndData interface functions 
   */
  event result_t SndData.sendDone(TOS_MsgPtr msg, result_t success)
  {
    return SUCCESS;
  }

  /*
   * Rceive Request interface functions
   */
  event TOS_MsgPtr RecvRequest.receive(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    uint16_t len; //message length
    
    ChanQMsg* src = (ChanQMsg*)payload; 
    ChanQMsg* dest = call SndData.getBuffer(&backBuffer, &len);
    memcpy(dest, src, len);
    dbg(DBG_USR1, "CQ: data collection message received\n");
    call SndData.send(&backBuffer, len);
    return msg;
  }
#ifdef USE_CQTEST
  /*
   * SendReq interface functions 
   */
  event result_t SendReq.sendDone(TOS_MsgPtr msg, result_t success)
  {
    return SUCCESS;
  }
#endif
#endif

  /*
   * Ping interface functions
   */
  /*
   * SndData interface functions 
   */
  event result_t ReplyPing.sendDone(TOS_MsgPtr msg, result_t success)
  {
    return SUCCESS;
  }

  /*
   * Rceive Request interface functions
   */
  event TOS_MsgPtr RecvPing.receive(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    uint16_t len; //message length
    
    PingMsg* src = (PingMsg*)payload; 
    PingMsg* dest = call ReplyPing.getBuffer(&backBuffer, &len);
    memcpy(dest, src, len);
    dbg(DBG_USR1, "Ping: data collection message received\n");
    call ReplyPing.send(&backBuffer, len);
    return msg;
  }

}

//eof
