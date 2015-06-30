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

module MDA300IOM {
  provides {
    interface StdControl;
    interface MateBytecode as EnableTrigger;
    interface MateBytecode as SetPinDirection;
    interface MateBytecode as ReadPin;
    interface MateBytecode as WritePin;
  }
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
    interface MateQueue as Queue;
    interface MateError as Error;
    interface MateContextSynch as Synch;
    interface MateEngineStatus as EngineStatus;
    interface MateAnalysis as Analysis;
    interface MateHandlerStore as PinHandler;
    
    interface DigitalIO;
    interface StdControl as DigitalControl;
  }
}
implementation {
  MateQueue readWaitQueue;
  MateQueue writeWaitQueue;
  MateQueue setPinWaitQueue;
  MateContext *sensingContext;
  uint8_t portState = 0xff;
  uint8_t portDdr = 0x3f;
  uint8_t currentPin;
  
  event void EngineStatus.rebooted() {
    call Queue.init(&readWaitQueue);
    call Queue.init(&writeWaitQueue);
    call Queue.init(&setPinWaitQueue);
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
    /* Hack: sensingContext points to current pin during boot-time
       reset of PCF8574APWR (see StdControl.start) */
    if (sensingContext != (MateContext *)&currentPin)
      call Synch.resumeContext(sensingContext, sensingContext);
    sensingContext = NULL;
  }

  void updateState(uint8_t newState, MateContext *context) {
    if (newState != portState)
      {
	portState = newState;
	check(call DigitalIO.set(newState), context);
      }
  }

  void writePin(MateContext *context) {
    MateStackVariable *onoff = call Stacks.popOperand(context);
    MateStackVariable *pinv = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, onoff, MATE_TYPE_INTEGER) &&
	call Types.checkTypes(context, pinv, MATE_TYPE_INTEGER))
      {
	uint8_t newState = portState;
	int16_t pin = pinv->value.var;

	if (pin < 0 || pin >= 8)
	  call Error.error(context, MATE_ERROR_INDEX_OUT_OF_BOUNDS);
	else if (portDdr & 1 << pin)
	  call Error.error(context, MATE_ERROR_INVALID_SENSOR);
	else if (onoff->value.var)
	  newState |= 1 << pin;
	else
	  newState &= ~(1 << pin);

	updateState(newState, context);
      }
  }

  command result_t WritePin.execute(uint8_t instr, MateContext *context) {
    if (sensingContext)
      wait(&writeWaitQueue, context);
    else
      writePin(context);
    return SUCCESS;
  }

  command uint8_t WritePin.byteLength() {return 1;}

  void readPin(MateContext* context) {
    MateStackVariable *pinv = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, pinv, MATE_TYPE_INTEGER))
      {
	int16_t pin = pinv->value.var;

	if (pin < 0 || pin >= 6) // can't read the relays!
	  call Error.error(context, MATE_ERROR_INDEX_OUT_OF_BOUNDS);
	else if (!(portDdr & 1 << pin))
	  call Error.error(context, MATE_ERROR_INVALID_SENSOR);
	else 
	  {
	    currentPin = pin;
	    check(call DigitalIO.get(), context);
	  }
      }
  }
  
  command result_t ReadPin.execute(uint8_t instr, MateContext* context) {
    if (sensingContext)
      wait(&readWaitQueue, context);
    else
      readPin(context);
    return SUCCESS;
  }

  command uint8_t ReadPin.byteLength() {return 1;}

  void setPinDirection(MateContext* context) {
    MateStackVariable *inout = call Stacks.popOperand(context);
    MateStackVariable *pinv = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, inout, MATE_TYPE_INTEGER) &&
	call Types.checkTypes(context, pinv, MATE_TYPE_INTEGER))
      {
	uint8_t newState = portState;
	int16_t pin = pinv->value.var;

	if (pin < 0 || pin >= 6) // can't read the relays!
	  call Error.error(context, MATE_ERROR_INDEX_OUT_OF_BOUNDS);
	else if (inout->value.var) // 1 is in
	  {
	    portDdr |= 1 << pin;
	    newState |= 1 << pin;
	  }
	else // 0 is out
	  {
	    portDdr &= ~(1 << pin);
	    newState &= ~(1 << pin);
	  }

	updateState(newState, context);
      }
  }
  
  command result_t SetPinDirection.execute(uint8_t instr, MateContext* context) {
    if (sensingContext)
      wait(&setPinWaitQueue, context);
    else
      setPinDirection(context);
    return SUCCESS;
  }

  command uint8_t SetPinDirection.byteLength() {return 1;}

  void checkReadQueue() {
    if (!sensingContext && !call Queue.empty(&readWaitQueue))
      readPin(call Queue.dequeue(NULL, &readWaitQueue));
  }

  void checkWriteQueue() {
    if (!sensingContext && !call Queue.empty(&writeWaitQueue))
      writePin(call Queue.dequeue(NULL, &writeWaitQueue));
  }

  void checkSetPinQueue() {
    if (!sensingContext && !call Queue.empty(&setPinWaitQueue))
      setPinDirection(call Queue.dequeue(NULL, &writeWaitQueue));
  }

  event result_t DigitalIO.getDone(uint8_t port, result_t ok) {
    if (!sensingContext)
      return FAIL;

    call Stacks.pushReading(sensingContext, MATE_TYPE_INTEGER,
			    (port >> currentPin) & 0x1);
    resume();

    checkWriteQueue();
    checkSetPinQueue();
    checkReadQueue();

    return SUCCESS;
  }

  event result_t DigitalIO.setDone(result_t ok) {
    if (!sensingContext)
      return FAIL;

    resume();

    checkReadQueue();
    checkSetPinQueue();
    checkWriteQueue();

    return SUCCESS;
  }

  MateContext pinContext;

  event result_t DigitalIO.change() {
    // if already running, just lose the event
    if (pinContext.state == MATE_STATE_HALT)
      {
	call Synch.initializeContext(&pinContext);
	call Synch.resumeContext(&pinContext, &pinContext);
      }
    return SUCCESS;
  }

  command result_t EnableTrigger.execute(uint8_t instr, MateContext* context) {
    MateStackVariable *onoff = call Stacks.popOperand(context);

    if (call Types.checkTypes(context, onoff, MATE_TYPE_INTEGER))
      call DigitalIO.enable(onoff->value.var != 0);
    return SUCCESS;
  }

  command uint8_t EnableTrigger.byteLength() {
    return 1;
  }

  command result_t StdControl.init() {
    pinContext.which = MATE_CONTEXT_PIN;
    pinContext.state = MATE_STATE_HALT;
    pinContext.rootHandler = MATE_HANDLER_PIN;
    pinContext.currentHandler = MATE_HANDLER_PIN;
    call Analysis.analyzeVars(MATE_HANDLER_PIN);
    return call DigitalControl.init();
  }

  command result_t StdControl.start() {
    call DigitalControl.start();
    signal EngineStatus.rebooted();
    /* Hack: we use a fake context to represent the internal action of 
       resetting the PCF8574APWR state (see test in resume) */
    sensingContext = (MateContext *)&currentPin;
    call DigitalIO.set(portState);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call DigitalControl.stop();
  }

  event void PinHandler.handlerChanged() {
    call Synch.initializeContext(&pinContext);
  }

}
