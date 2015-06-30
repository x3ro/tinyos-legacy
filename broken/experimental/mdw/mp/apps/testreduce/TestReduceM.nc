/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */
includes Collective;
includes Timer;

/** 
 * Test program for reduction.
 */

module TestReduceM {
  provides {
    interface StdControl;
  }
  uses {
    interface Reduce;
    interface Command;
    interface Timer;
  }
}
implementation {

  enum {
    ROOT_NODE = 0, 		       // Node to reduce to
  };

  enum {
    REDUCE_MAX,
    REDUCE_SUM,
    REDUCE_MAX_TOALL,
    REDUCE_SUM_TOALL,
    REDUCE_MAX_SOME,
    REDUCE_SUM_SOME,
    REDUCE_DONE,
  };

  int reduceType;
  uint16_t reduceVal, reduceResult;

  enum {
    COMMAND_NEXT_REDUCE = 0x77,
  };

  /*********************************************************************** 
   * Initialization 
   ***********************************************************************/

  task void reduceTask();

  // Only used by ROOT_NODE to initiate commands
  event result_t Timer.fired() {
    if (TOS_LOCAL_ADDRESS == ROOT_NODE) {
      dbg(DBG_USR1, "TestReduceM: Broadcasting command, reduceType %d\n", reduceType);
      call Command.broadcast(COMMAND_NEXT_REDUCE, (uint8_t*)&reduceType, sizeof(reduceType));
      post reduceTask();
    }
    return SUCCESS;
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    reduceType = REDUCE_MAX;
    reduceVal = TOS_LOCAL_ADDRESS;
    call Timer.start(TIMER_ONE_SHOT, 1000);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event void Command.receive(uint16_t cmdid, uint8_t *params, uint16_t paramslen) {
    dbg(DBG_USR1, "TestReduceM: Command.receive called, id 0x%x\n", cmdid);
    if (cmdid == COMMAND_NEXT_REDUCE) {
      reduceType = *((uint16_t*)params);
      post reduceTask();
    }
  }

  // Called on an error condition 
  static void fallout() {
    dbg(DBG_USR1, "TestReduceM: Fallout called, just waiting for next command...\n");
  }

  task void reduceTask() {
    dbg(DBG_USR1, "TestReduceM: reduceTask() called, reduceType %d\n", reduceType);

    switch (reduceType) {
      case REDUCE_MAX:
  	if (!call Reduce.reduceToOne(ROOT_NODE, OP_MAX, TYPE_UINT16, &reduceVal, &reduceResult)) {
   	  dbg(DBG_USR1, "TestReduceM: Failed to initiate reduction\n");
  	  fallout(); return;
   	}
	break;

      case REDUCE_SUM:
  	if (!call Reduce.reduceToOne(ROOT_NODE, OP_ADD, TYPE_UINT16, &reduceVal, &reduceResult)) {
   	  dbg(DBG_USR1, "TestReduceM: Failed to initiate reduction\n");
  	  fallout(); return;
   	}
	break;

      case REDUCE_MAX_TOALL:
  	if (!call Reduce.reduceToAll(ROOT_NODE, OP_MAX, TYPE_UINT16, &reduceVal, &reduceResult)) {
   	  dbg(DBG_USR1, "TestReduceM: Failed to initiate reduction\n");
  	  fallout(); return;
   	}
	break;

      case REDUCE_SUM_TOALL:
  	if (!call Reduce.reduceToAll(ROOT_NODE, OP_ADD, TYPE_UINT16, &reduceVal, &reduceResult)) {
   	  dbg(DBG_USR1, "TestReduceM: Failed to initiate reduction\n");
  	  fallout(); return;
   	}
	break;

      case REDUCE_MAX_SOME:
	if (TOS_LOCAL_ADDRESS % 2 == 0) {
	  if (!call Reduce.reduceToOne(ROOT_NODE, OP_MAX, TYPE_UINT16, &reduceVal, &reduceResult)) {
	    dbg(DBG_USR1, "TestReduceM: Failed to initiate reduction\n");
	    fallout(); return;
	  }
	} else {
	  if (!call Reduce.passThrough()) {
	    dbg(DBG_USR1, "TestReduceM: Failed to initiate passThrough\n");
	    fallout(); return;
	  }
	}
	break;

      case REDUCE_SUM_SOME:
	if (TOS_LOCAL_ADDRESS % 2 == 0) {
	  if (!call Reduce.reduceToOne(ROOT_NODE, OP_ADD, TYPE_UINT16, &reduceVal, &reduceResult)) {
	    dbg(DBG_USR1, "TestReduceM: Failed to initiate reduction\n");
	    fallout(); return;
	  }
	} else {
	  if (!call Reduce.passThrough()) {
	    dbg(DBG_USR1, "TestReduceM: Failed to initiate passThrough\n");
	    fallout(); return;
	  }
	}
	break;
      }

    dbg(DBG_USR1, "TestReduceM: Initiated reduce, type %d\n", reduceType);
  }

  event void Reduce.reduceDone(void *outbuf, result_t res) {
    dbg(DBG_USR1, "TestReduceM: reduceDone (outbuf 0x%lx success %d)\n", *(unsigned long *)outbuf, res);
    if (TOS_LOCAL_ADDRESS == ROOT_NODE) {
      if (res != SUCCESS) {
	reduceResult = 0xffff;
      }
      dbg(DBG_USR1, "TestReduceM: Sending result (type %d) to root: %d\n", reduceType, reduceResult);
      call Command.sendToBase(reduceType, (uint8_t *)&reduceResult, sizeof(reduceResult));
      reduceType++;
      if (reduceType == REDUCE_DONE) reduceType = 0;
      dbg(DBG_USR1, "TestReduceM: Broadcasting command, reduceType %d\n", reduceType);
      call Command.broadcast(COMMAND_NEXT_REDUCE, (uint8_t *)&reduceType, sizeof(reduceType));
      post reduceTask();
    } else {
      // Do nothing - wait for next command
    }
  }


  

}
