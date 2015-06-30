/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPhandlerM {
  provides {
    interface MateBytecode as ExecHandler;
    interface MateBytecodeLock as ExecHandlerLocks;
  }
  uses {
    interface MotlleGlobals as G;
    interface MotlleStack as S;
    interface MotlleGC as GC;
    interface MateBytecode as Exec;
    interface MotlleTypes as T;
  }
}
implementation {
  command result_t ExecHandler.execute(uint8_t instr, MateContext *context) {
    uint8_t handler = context->currentHandler;
    mvalue hval;

    if (handler == MATE_HANDLER_ONCE) // special...
      hval = call GC.entry_point();
    else /* Handler n is stored in global n and called with 0 arguments */
      hval = call G.read(handler);

    // suppress undefined handlers
    // (the PC will fall through to 1, which means OP_HALT, in this case)
    if (hval != call T.nil())
      {
	call S.reset(context);
	if (call S.push(context, hval))
	  call Exec.execute(OP_MEXEC4 + 0, context);
      }
    return SUCCESS;
  }

  command uint8_t ExecHandler.byteLength() {
    return 1;
  }

  command int16_t ExecHandlerLocks.lockNum(uint8_t instr, uint8_t handlerId, uint8_t pc) {
    /* Motlle handlers cannot be run concurrently. We just pretend to 
       always use the same variable ... */
    return GLOBAL_MOTLLE_LOCK;
 }

}
