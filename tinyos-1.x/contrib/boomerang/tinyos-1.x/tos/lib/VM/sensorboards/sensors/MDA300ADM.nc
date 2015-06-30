/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * History:   Feb 10, 2004         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 * @author David Gay <dgay@intel-research.net>
 */


includes Mate;

module MDA300ADM {
  provides {
    interface MateBytecode as Excite;
    interface MateBytecode as Adread;
  }
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
    interface MateQueue as Queue;
    interface MateError as Error;
    interface MateContextSynch as Synch;
    interface MateEngineStatus as EngineStatus;
    
    interface Sensor[uint8_t channel];
    interface Power[uint8_t voltage];
  }
}
implementation {
  MateQueue senseWaitQueue;
  MateQueue exciteWaitQueue;
  MateContext *sensingContext;
  
  event void EngineStatus.rebooted() {
    call Queue.init(&senseWaitQueue);
    call Queue.init(&exciteWaitQueue);
    sensingContext = NULL;
  }

  void check(result_t ok, MateContext* context) {
    if (ok) {
      sensingContext = context;
      context->state = MATE_STATE_BLOCKED;
      call Synch.yieldContext(context);
    }
    else // oops. somebody else stole the mda300ca, or invalid arg.
      call Error.error(context, MATE_ERROR_SENSOR_FAIL);
  }
  
  void wait(MateQueue *q, MateContext *context) {
    call Queue.enqueue(context, q, context);
    context->state = MATE_STATE_WAITING;
    call Synch.yieldContext(context);
  }

  void resume() {
    call Synch.resumeContext(sensingContext, sensingContext);
    sensingContext = NULL;
  }

  void execExcite(MateContext *context) {
    MateStackVariable *onoff = call Stacks.popOperand(context);
    MateStackVariable *voltage = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, onoff, MATE_TYPE_INTEGER) &&
	call Types.checkTypes(context, voltage, MATE_TYPE_INTEGER))
      check(call Power.set[voltage->value.var](onoff->value.var), context);
  }

  command result_t Excite.execute(uint8_t instr, MateContext *context) {
    if (sensingContext)
      wait(&exciteWaitQueue, context);
    else
      execExcite(context);
    return SUCCESS;
  }

  command uint8_t Excite.byteLength() {return 1;}

  default command result_t Power.set[uint8_t excitation](bool on) {
    return FAIL;
  }

  void execSense(MateContext* context) {
    MateStackVariable *channel = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, channel, MATE_TYPE_INTEGER))
      check(call Sensor.getData[channel->value.var](), context);
  }
  
  command result_t Adread.execute(uint8_t instr, MateContext* context) {
    if (sensingContext)
      wait(&senseWaitQueue, context);
    else
      execSense(context);
    return SUCCESS;
  }

  command uint8_t Adread.byteLength() {return 1;}

  event result_t Sensor.error[uint8_t channel](uint16_t datum) {
    return SUCCESS;
  }

  void checkSenseQueue() {
    if (!sensingContext && !call Queue.empty(&senseWaitQueue))
      execSense(call Queue.dequeue(NULL, &senseWaitQueue));
  }

  void checkExciteQueue() {
    if (!sensingContext && !call Queue.empty(&exciteWaitQueue))
      execExcite(call Queue.dequeue(NULL, &exciteWaitQueue));
  }

  event result_t Sensor.dataReady[uint8_t channel](uint16_t datum) {
    if (!sensingContext)
      return FAIL;

    call Stacks.pushReading(sensingContext, MATE_TYPE_INTEGER, datum);
    resume();

    /* Check excite first to give round-robin behaviour */
    checkExciteQueue();
    checkSenseQueue();

    return SUCCESS;
  }
  
  event result_t Power.setDone[uint8_t voltage]() {
    if (!sensingContext)
      return FAIL;

    resume();

    /* Check sense first to give round-robin behaviour */
    checkSenseQueue();
    checkExciteQueue();

    return SUCCESS;
  }
}
