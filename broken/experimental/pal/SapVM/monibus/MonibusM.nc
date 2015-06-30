//$Id: MonibusM.nc,v 1.9 2005/08/18 00:47:52 neturner Exp $

/**
 * @author Neil E. Turner
 */

module MonibusM {

  provides {
    interface MateBytecode;
    interface StdControl;
  }

  uses {
    interface MateContextSynch as Synch;
    interface MateEngineStatus as EngineStatus;
    interface MateQueue as Queue;
    interface MateStacks as Stacks;
    interface MateTypes as TypeCheck;

    interface HPLUART as Monibus;

    interface Leds;
    interface Timer as ResponseTimeout;
    interface Timer as NoResponseTimeout;
  }
}

implementation {

  result_t preExecute(MateContext* context);
  result_t tryExecute(MateContext* context);

  ////////////// Constants //////////////
  /**
   * The maximum number of values between '0' and '9'
   * that are to be expected in a monibus response.
   * <p>
   */
  enum {
    MAX_VALUES = 4
  };

  /**
   * The amount of time, in milliseconds, that must pass
   * after the last byte
   * in order to consider the
   * Monibus response completed.
   * <p>
   */
  enum {
    MESSAGE_TIMEOUT = 35
  };

  /**
   * The error code that is pushed onto the Mate stack to indicate
   * that no monibus response was found.
   * <p>
   */
  enum {
    MONIBUS_ABSENT_ERROR = 11111
  };

  /**
   * The amount of time, in milliseconds, that must pass
   * after the monibus query is issued and no monibus
   * response has begun (not a single byte received) in order to
   * consider that an error has occured.
   * <p>
   */
  enum {
    NO_RESPONSE_TIMEOUT = 50
  };


  ////////////// Member variables //////////////
  /**
   *
   */
  bool busy;

  /**
   * The index into the data field of the current Mate buffer indicating
   * where the next byte in the buffer will be written.
   * <p>
   */
  uint8_t dataByteNumber = 0;

  /**
   * The array to where incoming bytes from the Monibus device are stored.
   * <p>
   */
  uint16_t dataBytes[MAX_VALUES];

  /**
   *
   */
  MateContext* executingContext;

  /**
   * The flag to signify a negative-valued Monibus response.
   */
  bool isNegative = FALSE;

  /**
   * The number of arguments on the Mate operand stack.
   */
  int16_t numberOfArguments;

  /**
   *
   */
  MateQueue waitQueue;

  ////////////// Tasks //////////////
  /**
   * Push the error code
   * onto the stack and resume execution of the context.
   * <p>
   * This task is called when a byte has been put on the Monibus
   * (see tryExecute()), but no response is found on the Monibus
   * within <code>NO_RESPONSE_TIMEOUT</code> milliseconds.
   * (see NoResponseTimeout.fired()).
   * <p>
   * @see tryExecute()
   * @see NoResponseTimeout.fired()
   * <p>
   */
  task void monibusAbsent() {
    // reset the index into the array to prep for later calls to this OP
    dataByteNumber = 0;

    busy = FALSE;
    if (executingContext != NULL) {
      call Stacks.pushValue(executingContext, MONIBUS_ABSENT_ERROR);
      call Synch.resumeContext(executingContext, executingContext);
      executingContext = NULL;
    }

    if (!call Queue.empty(&waitQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &waitQueue);
      preExecute(context);
    }

  }

  /**
   * Push the converted (ASCII to int) value of the the Monibus
   * response onto the stack and resume execution of the context.
   * <p>
   * This task is called when either <code>dataBytes[]</code> is full (see
   * Monibus.get()) or when the Monibus
   * device is finished sending the response (see ResponseTimeout.fired()).
   * <p>
   * @see Monibus.get()
   * @see ResponseTimeout.fired()
   * <p>
   */
  task void monibusDone() {

    //counter in the for loop
    uint8_t i;
    //Intermediate variable
    int16_t sum = 0;
    //the final resting place of the monibus response that is pushed
    // the Mate stack
    int16_t monibusResponse = 0;

    for (i = 0; i < dataByteNumber; i++) {
      sum = sum + dataBytes[i];
    }

    if (isNegative) {
      monibusResponse = -sum;
      isNegative = FALSE; // reset the flag after using it
    } else {
      monibusResponse = sum;
    }

    // reset the index into the array to prep for later calls to this OP
    dataByteNumber = 0;

    busy = FALSE;
    if (executingContext != NULL) {
      call Stacks.pushValue(executingContext, monibusResponse);
      call Synch.resumeContext(executingContext, executingContext);
      executingContext = NULL;
    }

    if (!call Queue.empty(&waitQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &waitQueue);
      preExecute(context);
    }
  }

  ////////////// StdControl Commands //////////////
  /**
   *
   */
  command result_t StdControl.init() {
    call Queue.init(&waitQueue);
    executingContext = NULL;
    busy = FALSE;

    return SUCCESS;
  }

  /**
   *
   */
  command result_t StdControl.start() {
    return SUCCESS;
  }

  /**
   *
   */
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  ////////////// MateBytecode Commands //////////////
  /**
   *
   */
  command result_t MateBytecode.execute(uint8_t instruction,
					MateContext* context)
  {
    if (busy) {
      dbg(DBG_USR1,
	  "VM(%i): Executing monibus, but busy, put on queue.\n",
	  (int)context->which);
      context->state = MATE_STATE_WAITING;
      call Queue.enqueue(context, &waitQueue, context);
      return SUCCESS;
    } else {
      dbg(DBG_USR1, "VM (%i): Executing monibus.\n", (int)context->which);
      return preExecute(context);
    }
  }

  /**
   *
   */
  command uint8_t MateBytecode.byteLength() {
    return 1;
  }

  ////////////// Monibus Events //////////////

  /**
   * Save the byte if it is between '0' and '9' (inclusive),
   * otherwise discard it.
   * Post the monibusDone() task when the Monibus
   * response is complete.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t Monibus.get(uint8_t data) {

    //counter in the for loop
    uint8_t i;

    //If a monibus query has been issued and a response is expected
    if (busy) {
      /* Then
       * 1. reset the timeout timer
       * 2. save the date byte if it's between '0' and '9'
       * 3. check if this byte makes the array full
       */

      //stop the NoResponseTimeout timer
      call NoResponseTimeout.stop();

      // restart the timeout timer
      call ResponseTimeout.stop();
      call ResponseTimeout.start(TIMER_ONE_SHOT, MESSAGE_TIMEOUT);

      //if the first byte is the negative sign
      if (data == '-' && dataByteNumber == 0) {
	//then set the flag signifying this is a negative value
	isNegative = TRUE;
      }

      //if the byte is between ASCII '0' and ASCII '9'
      if (data >= '0' && data <= '9') {
	//then 
	// 1. for each previous byte increase its decimal place by one
	for (i = 0; i < dataByteNumber; i++) {
	  dataBytes[i] = dataBytes[i] * 10;
	}
	// 2. save this byte in the "ones" place
	dataBytes[dataByteNumber++] = data - '0';
      }

      // if the array is full
      if (dataByteNumber == MAX_VALUES) {
	/* then
	   1. stop the Monibus/UART (thereby freeing the bus)
	   2. post the task
	   3. stop the timeout timer
	*/
	call Monibus.stop();
	post monibusDone();
	call ResponseTimeout.stop();
      }
    }
    return SUCCESS;
  }

  /**
   * If there are more characters to put on the Monibus,
   * put the next character on the Monibus.
   * Start the NoResponseTimeout timer.
   *
   * @return Always return SUCCESS.
   */
  async event result_t Monibus.putDone() {
    int16_t queryCharacter16;
    uint8_t queryCharacter8;
    MateStackVariable* mateValue;

    if (numberOfArguments > 0) {
      //pop the next argument
      mateValue = call Stacks.popOperand(executingContext);
      //decrement the number of arguments remaining
      numberOfArguments--;

      //check the argument's type
      //if the argument is not an integer
      if (!call TypeCheck.checkTypes(executingContext,
				     mateValue,
				     MATE_TYPE_INTEGER)) {
	//then return fail
	return FAIL;
      }

      //get the int16_t out of the mate integer
      queryCharacter16 = mateValue->value.var;

      //if the value does not represent a valid ASCII character (0 - 255)
      if (!(queryCharacter16 >= 0) || !(queryCharacter16 <=255)) {
	//then return fail
	return FAIL;
      }

      //translate the value to an 8-bit unsigned representation
      queryCharacter8 = queryCharacter16;

      //attempt to put the character on the monibus
      //if it is not successful
      if (call Monibus.put(queryCharacter8) != SUCCESS) {
	//putFailed = TRUE;
      } else { // Otherwise
	//putFailed = FALSE;

	dbg(DBG_USR1,
	    "VM (%i): OPmonibusM putting a character (%x) on the Monibus.\n",
	    (int)context->which,
	    queryCharacter8);
      }
    }

    call NoResponseTimeout.start(TIMER_ONE_SHOT, NO_RESPONSE_TIMEOUT);

    return SUCCESS;
  }

  ////////////// EngineStatus Events //////////////
  /**
   *
   */
  event void EngineStatus.rebooted() {
    //Upon reboot no context is executing.
    executingContext = NULL;

    //Upon reboot all operations in the queue should be cleared out 
    call Queue.init(&waitQueue);
  }

  ////////////////  NoResponseTimeout events  ////////////////
  /**
   * Stop the UART and post the task responsible for wrapping up
   * in the case of no monibus response.
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t NoResponseTimeout.fired() {
    // stop the Monibus
    //(which sets the bus to SPI mode and resets the baud rate)
    call Monibus.stop();
    // post the task
    post monibusAbsent();

    return SUCCESS;
  }

  ////////////////  ResponseTimeout events  ////////////////
  /**
   * Stop the UART and post the task responsible for wrapping up the operation.
   * <p>
   * This firing signifies that the Monibus
   * has experienced enough idle time thereby indicating that the 
   * Monibus response is completed.  When the response is completed,
   * then the UART should be stopped (thereby freeing the bus
   * so that the radio can use it).
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t ResponseTimeout.fired() {
    //stop the Monibus
    //(which sets the bus to SPI mode and resets the baud rate)
    call Monibus.stop();
    // post the task
    post monibusDone();

    return SUCCESS;
  }

  ////////////// Functions //////////////
  /**
   * Discover the number of arguments expected for this op and call
   * <code>tryExecute</code> with this value.
   */
  result_t preExecute(MateContext* context) {
    MateStackVariable* mateVariable;

    mateVariable = call Stacks.popOperand(context);
    numberOfArguments = mateVariable->value.var;

    return tryExecute(context);
  }

  /**
   * Put the first ASCII character on the monibus, mark the component
   * as busy, and yield to other contexts.
   */
  result_t tryExecute(MateContext* context) {
    int16_t queryCharacter16;
    uint8_t queryCharacter8;
    MateStackVariable* mateValue;

    //if the Monibus is not able to be initialized
    if (call Monibus.init() != SUCCESS) {
      //then return fail
      return FAIL;
    } else {
      //otherwise

      if (numberOfArguments > 0) {
	//pop the argument
	mateValue = call Stacks.popOperand(context);
	//decrement the number of arguments remaining
	numberOfArguments--;

	//check the argument's type
	//if the argument is not an integer
	if (!call TypeCheck.checkTypes(context, mateValue, MATE_TYPE_INTEGER)){
	  //then return fail
	  return FAIL;
	}

	//get the int16_t out of the mate integer
	queryCharacter16 = mateValue->value.var;

	//if the value does not represent a valid ASCII character (0 - 255)
	if (!(queryCharacter16 >= 0) || !(queryCharacter16 <=255)) {
	  //then return fail
	  return FAIL;
	}

	//translate the value to an 8-bit unsigned representation
	queryCharacter8 = queryCharacter16;

	//attempt to put the character on the monibus
	//if it is not successful
	if (call Monibus.put(queryCharacter8) != SUCCESS) {
	  //putFailed = TRUE;
	} else { // Otherwise
	  //putFailed = FALSE;

	  dbg(DBG_USR1,
	      "VM (%i): OPmonibusM putting a character (%x) on the Monibus.\n",
	      (int)context->which,
	      queryCharacter8);
	}
      }

      //1. Mark the component as busy so other contexts can't run monibus
      //operations at the same time.
      busy = TRUE;

      //2. Mark this context as the context that is currently
      //executing this operation
      executingContext = context;

      //3. Mark this context's state as blocked (due to the split-phased
      //nature of the operation this op/context has to block here)
      context->state = MATE_STATE_BLOCKED;

      //4. yield the "processor" (unlock shared resources)
      //so other contexts can operate
      //while this one is blocked
      call Synch.yieldContext(context);

      return SUCCESS;
    }
  }
}
