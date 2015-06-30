module FNmhopM
{
  provides {
    interface StdControl;
    interface MateBytecode as InterceptMsg;
    interface MateBytecode as SnoopMsg;
    interface MateBytecode as MhopSend;
    interface MateBytecode as Parent;
    interface MateBytecode as Depth;
    interface MateBytecode as MhopSetUpdate;
    interface MateBytecode as MhopSetForwarding;
  }
  uses {
    interface MateContextSynch as Synch;
    interface MateAnalysis as Analysis;
    interface MateEngineStatus as EngineStatus;
    interface MateHandlerStore as SnoopHandler;
    interface MateHandlerStore as InterceptHandler;

    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;

    interface Send;
    interface Intercept;
    interface Intercept as Snoop;
    interface RouteControl;
    interface CommControl;
    interface CC1000Control;
#ifndef NOLPL
    interface LowPowerListening;
#endif

    command result_t PowerMgmtEnable();
  }
}
implementation
{
  typedef struct {
    MateContext context;
    TOS_Msg msg;
    uint8_t payload;
    uint8_t len;
  } MhopHandler;

  result_t forwarding;

  MhopHandler snoop, intercept;

  void initContext(MhopHandler *h, int context, int handler) {
    h->context.which = context;
    h->context.state = MATE_STATE_HALT;
    h->context.rootHandler = handler;
    h->context.currentHandler = handler;
    call Analysis.analyzeVars(handler);
  }

  command result_t StdControl.init() {
    result_t rval = rcombine
      (call SnoopHandler.initializeHandler(),
       call InterceptHandler.initializeHandler());

    initContext(&snoop, MATE_CONTEXT_SNOOP, MATE_HANDLER_SNOOP);
    initContext(&intercept, MATE_CONTEXT_INTERCEPT, MATE_HANDLER_INTERCEPT);

    forwarding = SUCCESS;

    return rval;
  }
  
  command result_t StdControl.start() {
    call CommControl.setPromiscuous(TRUE);
    call CC1000Control.SetRFPower(255);
#ifndef NOLPL
#ifndef RADIO_XMIT_POWER
    if (TOS_LOCAL_ADDRESS)
      {
	call PowerMgmtEnable();
	call LowPowerListening.SetListeningMode(4);
      }
    else
      call LowPowerListening.SetTransmitMode(4);
#endif
#endif
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void SnoopHandler.handlerChanged() {
    call Synch.initializeContext(&snoop.context);
  }

  event void InterceptHandler.handlerChanged() {
    call Synch.initializeContext(&intercept.context);
  }

  result_t dointercept(MhopHandler *h, TOS_MsgPtr msg, void *payload, uint16_t len) {
    if (h->context.state != MATE_STATE_HALT)
      // already running, just lose the event but forward the message
      return forwarding; 

    call Synch.initializeContext(&h->context);
    call Synch.resumeContext(&h->context, &h->context);
    h->msg = *msg;
    h->payload = (uint8_t *)payload - (uint8_t *)msg;
    h->len = len;

    return forwarding; 
  }

  event result_t Intercept.intercept(TOS_MsgPtr msg, void *payload, uint16_t len) {
    return dointercept(&intercept, msg, payload, len);
  }

  event result_t Snoop.intercept(TOS_MsgPtr msg, void *payload, uint16_t len) {
    return dointercept(&snoop, msg, payload, len);
  }

  void pushmsg(MhopHandler *h) {
    vstring packet = call T.alloc_string(h->len);

    if (packet)
      {
	memcpy(packet->str, (uint8_t *)&h->msg + h->payload, h->len);
	call S.push(&h->context, call T.make_string(packet));
      }
  }

  //FN intercept_msg: -> s. Return intercepted multihop message
  command result_t InterceptMsg.execute(uint8_t instr, MateContext* context) {
    if (context != &intercept.context)
      call E.error(context, MATE_ERROR_INVALID_INSTRUCTION);
    else
      pushmsg(&intercept);
    return SUCCESS;
  }

  command uint8_t InterceptMsg.byteLength() {
    return 1;
  }

  //FN snoop_msg: -> s. Return snooped multihop message
  command result_t SnoopMsg.execute(uint8_t instr, MateContext* context) {
    if (context != &snoop.context)
      call E.error(context, MATE_ERROR_INVALID_INSTRUCTION);
    else
      pushmsg(&snoop);
    return SUCCESS;
  }

  command uint8_t SnoopMsg.byteLength() {
    return 1;
  }

  //FN parent: -> i. Return parent node
  command result_t Parent.execute(uint8_t instr, MateContext* context) {
    call S.push(context, call T.make_int(call RouteControl.getParent()));
    return SUCCESS;
  }

  command uint8_t Parent.byteLength() {
    return 1;
  }

  //FN depth: -> i. Return depth of node
  command result_t Depth.execute(uint8_t instr, MateContext* context) {
    call S.push(context, call T.make_int(call RouteControl.getDepth()));
    return SUCCESS;
  }

  command uint8_t Depth.byteLength() {
    return 1;
  }

  //FN mhop_set_update: i -> . Set the multihop update interval to i s
  command result_t MhopSetUpdate.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      {
	vint interval = call T.intv(x);

	if (interval > 0)
	  call RouteControl.setUpdateInterval(interval);
	else
	  call E.error(context, MOTLLE_ERROR_BAD_VALUE);
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t MhopSetUpdate.byteLength() {
    return 1;
  }

  //FN mhop_set_forwarding: b -> . Turn automatic forwarding on/off
  command result_t MhopSetForwarding.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.truep(x))
      forwarding = SUCCESS;
    else
      forwarding = FAIL;
    return SUCCESS;
  }

  command uint8_t MhopSetForwarding.byteLength() {
    return 1;
  }

  MateContext *sendingContext;
  TOS_Msg msg;

  //FN mhopsend: s -> b. Send string s via multi-hop routing.
  command result_t MhopSend.execute(uint8_t instr, MateContext* context) {
    mvalue arg = call S.pop(context, 1);
    vstring packet;
    msize len;
    uint16_t maxlen;
    void *payload;

    if (!call T.stringp(arg))
      {
	call E.error(context, MOTLLE_ERROR_BAD_TYPE);
	return SUCCESS;
      }
    packet = call T.string(arg);
    len = call T.string_length(packet);

    payload = call Send.getBuffer(&msg, &maxlen);
    if (len > maxlen)
      {
	call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	return SUCCESS;
      }
    memcpy(payload, packet, len);
    msg.length = len;
    sendingContext = context;

    if (call Send.send(&msg, len))
      {
	context->state = MATE_STATE_BLOCKED;
	call Synch.yieldContext(context);
      }
    else
      // we don't retry - multihop already has a queue
      call S.qpush(context, call T.make_bool(FALSE));

    return SUCCESS;
  }

  command uint8_t MhopSend.byteLength() {
    return 1;
  }

  event result_t Send.sendDone(TOS_MsgPtr mesg, result_t success) {
    MateContext *sender = sendingContext;

    if (sender == NULL) 
      return SUCCESS;

    sendingContext = NULL;
    if (call S.push(sender, call T.make_bool(success)))
      call Synch.resumeContext(sender, sender);

    return SUCCESS;
  }

  event void EngineStatus.rebooted() {
    sendingContext = NULL;
  }
}
