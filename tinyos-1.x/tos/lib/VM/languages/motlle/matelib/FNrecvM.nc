/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNrecvM
{
  provides {
    interface StdControl;
    interface MateBytecode as ReceivedMsg;
  }
  uses {
    interface MateContextSynch as Synch;
    interface MateAnalysis as Analysis;
    interface MateHandlerStore as ReceiveHandler;

    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;

    interface ReceiveMsg;
  }
}
implementation
{
  typedef struct {
    MateContext context;
    TOS_Msg msg;
  } MsgHandler;

  MsgHandler receive;

  void initContext(MsgHandler *h, int context, int handler) {
    h->context.which = context;
    h->context.state = MATE_STATE_HALT;
    h->context.rootHandler = handler;
    h->context.currentHandler = handler;
    call Analysis.analyzeVars(handler);
  }

  command result_t StdControl.init() {
    result_t rval = call ReceiveHandler.initializeHandler();

    initContext(&receive, MATE_CONTEXT_RECEIVE, MATE_HANDLER_RECEIVE);

    return rval;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void ReceiveHandler.handlerChanged() {
    call Synch.initializeContext(&receive.context);
  }

  // Should do a swap
  TOS_MsgPtr doreceive(MsgHandler *h, TOS_MsgPtr msg) {
    if (h->context.state != MATE_STATE_HALT)
      // already running, just lose the event
      return msg;

    call Synch.initializeContext(&h->context);
    call Synch.resumeContext(&h->context, &h->context);
    h->msg = *msg;

    return msg;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msg) {
    return doreceive(&receive, msg);
  }

  void pushmsg(MsgHandler *h) {
    vstring packet = call T.alloc_string(h->msg.length);

    if (packet)
      {
	memcpy(packet->str, h->msg.data, h->msg.length);
	call S.push(&h->context, call T.make_string(packet));
      }
  }

  //FN received-msg: -> s. Return received message
  command result_t ReceivedMsg.execute(uint8_t instr, MateContext* context) {
    if (context != &receive.context)
      call E.error(context, MATE_ERROR_INVALID_INSTRUCTION);
    else
      pushmsg(&receive);
    return SUCCESS;
  }

  command uint8_t ReceivedMsg.byteLength() {
    return 1;
  }
}
