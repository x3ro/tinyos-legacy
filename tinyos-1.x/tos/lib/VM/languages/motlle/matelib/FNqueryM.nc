/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module FNqueryM {
  provides {
    interface StdControl;
    interface MateBytecode as Epoch;
    interface MateBytecode as NextEpoch;
    interface MateBytecode as SnoopEpoch;
    interface QueryAgg;
  }
  uses {
    interface MotlleGC as GC;
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MateError as E;

    interface MateContextSynch as Synch;
    interface MateAnalysis as Analysis;
    interface MateHandlerStore as EpochChangeHandler;

    interface RouteControl;
  }
}
implementation {
  void notify_epoch_change();
  uint16_t epoch;
  bool suppress;

  //FN epoch: -> i. Returns current epoch.
  command result_t Epoch.execute(uint8_t instr, MateContext* context) {
    call S.push(context, call T.make_int(epoch));
    return SUCCESS;
  }

  command uint8_t Epoch.byteLength() {
    return 1;
  }

  //FN next-epoch: -> i. Advances and returns epoch.
  command result_t NextEpoch.execute(uint8_t instr, MateContext* context) {
    if (!suppress)
      epoch = (epoch + 1) & 0x3fff;
    suppress = FALSE;
    call S.push(context, call T.make_int(epoch));
    notify_epoch_change();
    return SUCCESS;
  }

  command uint8_t NextEpoch.byteLength() {
    return 1;
  }

  //FN snoop-epoch: i -> . Heard message about epoch i. See if we should
  //  update epoch.
  command result_t SnoopEpoch.execute(uint8_t instr, MateContext* context) {
    mvalue x = call S.pop(context, 1);

    if (call T.intp(x))
      {
	vint heard = call T.intv(x);

	/* Note: this will produce weird effects during the 3fff - 0
	   transition. But these should only last a few epochs. */
	if (heard >=0 && heard > epoch)
	  {
	    epoch = heard;
	    suppress = TRUE;
	    notify_epoch_change();
	  }
      }
    else
      call E.error(context, MOTLLE_ERROR_BAD_TYPE);
    return SUCCESS;
  }

  command uint8_t SnoopEpoch.byteLength() {
    return 1;
  }

  MateContext epochChange;

  command result_t StdControl.init() {
    result_t rval = call EpochChangeHandler.initializeHandler();

    epochChange.which = MATE_CONTEXT_EPOCHCHANGE;
    epochChange.state = MATE_STATE_HALT;
    epochChange.rootHandler = MATE_HANDLER_EPOCHCHANGE;
    epochChange.currentHandler = MATE_HANDLER_EPOCHCHANGE;
    call Analysis.analyzeVars(MATE_HANDLER_EPOCHCHANGE);

    return rval;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void EpochChangeHandler.handlerChanged() {
    epoch = 0;
    call Synch.initializeContext(&epochChange);
  }

  void notify_epoch_change() {
    if (epochChange.state != MATE_STATE_HALT)
      // already running, just lose the event
      return;

    call Synch.initializeContext(&epochChange);
    call Synch.resumeContext(&epochChange, &epochChange);
  }

  command uint8_t QueryAgg.getDepth() {
    return call RouteControl.getDepth();
  }

  command uint16_t QueryAgg.getEpoch() {
    return epoch;
  }
}
