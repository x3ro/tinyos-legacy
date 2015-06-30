/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * History:   Feb 10, 2004         Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


includes Mate;

module OPadreadM {
  provides {
    interface StdControl;
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
  }
}
implementation {
  MateQueue senseWaitQueue;
  MateQueue exciteWaitQueue;
  MateContext *sensingContext;
  
  command result_t StdControl.init() {
    call Queue.init(&senseWaitQueue);
    call Queue.init(&exciteWaitQueue);
    sensingContext = NULL;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event void EngineStatus.rebooted() {
    call StdControl.init();
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
  
  void wait(MateQueue *q) {
    call Queue.enqueue(context, q, context);
    context->state = MATE_STATE_WAITING;
    call Synch.yieldContext(context);
  }

  void resume() {
    call Synch.resumeContext(sensingContext, sensingContext);
    sensingContext = NULL;
  }

  command void execExcite(MateContext *context) {
    MateStackVariable *onoff = call MateStacks.popOperand(context);
    MateStackVariable *voltage = call MateStacks.popOperand(context);

    if (call MateTypes.checkTypes(context, onoff, MATE_TYPE_INTEGER) &&
	call MateTypes.checkTypes(context, voltage, MATE_TYPE_INTEGER))
      check(call Power.set[voltage->value.var](onoff->value.var));
  }

  command result_t Excite.execute(uint8_t instr, MateContext *context) {
    if (sensingContext)
      wait(&exciteWaitQueue);
    else
      execExcite(context);
    return SUCCESS;
  }

  command uint8_t Excite.byteLength() {return 1;}

  default command result_t Power.set[uint8_t excitation]() {
    return FAIL;
  }

  void execSense(MateContext* context) {
    MateStackVariable *channel = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, channel, MATE_TYPE_INTEGER))
      check(call Sensor.getData[channel->value.var]());
  }
  
  command result_t Adread.execute(uint8_t instr, MateContext* context) {
    if (sensingContext)
      wait(&senseWaitQueue);
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

    resume();
    call Stacks.pushReading(sensingContext, MATE_TYPE_INTEGER, datum);

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
