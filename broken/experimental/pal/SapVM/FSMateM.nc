includes Mate;
includes Storage;
includes FSMate;

module FSMateM {
  provides interface MateBytecode as FWrite;
  provides interface MateBytecode as FFormat;
  provides interface MateBytecode as FRead;
  provides interface StdControl;
  provides command void getRecordSize(int16_t* sensors, int16_t* total);

  uses {
    interface MateQueue as Queue;
    interface MateStacks as Stacks;
    interface MateBuffer as Buffer;
    interface MateTypes as TypeCheck;
    interface MateContextSynch as Synch;
    interface MateEngineStatus as EngineStatus;
    interface LogWrite;
    interface LogRead;
    interface VolumeInit;
    interface InternalFlash as IFlash;
    interface StdControl as DataCacheControl; //reset sequence numbers
    command void DataCacheReset();
    command void flashError();
    interface Leds;
  }
}

implementation {
  FlashStatus fStatus = OFF;
  int16_t databuf[MATE_BUF_LEN]; // in 2-byte words
  int16_t datalengthInWords;
  log_cookie_t rid;
  MateDataBuffer* outputBuf;
  MateContext* currentContext;
  MateQueue writeQueue;
  MateQueue readQueue;

  // this is no longer constant, but I'm still using #define, so be careful
  // initialize to zero, this forces the user to initialize with opcode
  int16_t SENSOR_READINGS = 0;

  /* two error handling functions to abort in case of failure anywhere */
  void opFailed(MateContext* context) {
    call Stacks.pushValue(context, 0);
    call flashError();
  }
  void opFailedInIO() {
    opFailed(currentContext);
    if(currentContext != NULL) {
      call Synch.resumeContext(currentContext, currentContext);
    }
    fStatus = READY;
    currentContext = NULL;
  }

  /* Just some function prototypes for later */
  result_t tryWrite(MateContext* context);
  result_t tryRead(MateContext* context);

  /*
   * Initialize context queues in case file accesses are rapid and need
   * arbitration.
   */
  command result_t StdControl.init() {
    currentContext = NULL;
    call Queue.init(&writeQueue);
    call Queue.init(&readQueue);
    call IFlash.read((void*)16, (void *)&(SENSOR_READINGS), 2);
    return SUCCESS;
  }

  /*
   * Initialize the DataCacheM component. Basically initializes
   * sequence numbers and variables 
   */
  command result_t StdControl.start() {
    result_t rval;
    rval = call DataCacheControl.init();
    if(rval != SUCCESS) {
      return FAIL;
    }
    return SUCCESS;
  }
  command result_t StdControl.stop() { return SUCCESS; }
  
  /* BEGIN WRITE CODE */

  /*
   * This code is composed of 3 main pieces:
   * 1. Typecheck the buffer and move its contents into private memory.
   * 2. Try to append, fail gracefully if it can't do it.
   * 3. If successful, change the status and block/yield the context.
   */
  result_t tryWrite(MateContext* context) {
    MateStackVariable* mBuffer;
    MateDataBuffer* tempbuf;
    int i;

    mBuffer = call Stacks.popOperand(context);
    call TypeCheck.checkTypes(context, mBuffer, MATE_TYPE_BUFFER);    

    // Save the size of the buffer
    tempbuf = mBuffer->buffer.var;
    datalengthInWords = tempbuf->size;

    // copy the mate buffer data to private component buffer
    for(i = 0; i < datalengthInWords; i++) {
      databuf[i] = tempbuf->entries[i];
    }
    if(call LogWrite.append((void*)databuf,
			    (log_len_t)datalengthInWords*sizeof(int16_t))
       == FAIL) {
      // abort abort!
      // Ignore the following block comment.
      /*
      call Stacks.pushOperand(context, mBuffer);
      context->state = MATE_STATE_WAITING;
      call Queue.enqueue(context, &writeQueue, context);
      return SUCCESS;
      */
      opFailed(context);
      return SUCCESS;
    }
    // change the state and block the context
    fStatus = WRITE;
    currentContext = context;
    context->state = MATE_STATE_BLOCKED;
    call Synch.yieldContext(context);
    return SUCCESS;
  }

  /*
   * Mate execution code. Checks if the flash is busy, and queues context
   * if it is. Otherwise, try to write.
   */  
  command result_t FWrite.execute(uint8_t instr, MateContext* context) {
    if(fStatus != READY) {
      context->state = MATE_STATE_WAITING;
      call Queue.enqueue(context, &writeQueue, context);
      return SUCCESS;
    }
    return tryWrite(context);
  }
  command uint8_t FWrite.byteLength() { return 1; }

  /*
   * Given the the append went through. Check if it was actually successful.
   * Then sync() it in case there was disk buffering (e.g. force it to
   * actual flash).
   */  
  event void LogWrite.appendDone(storage_result_t rval,
				 void* data, 
				 log_len_t numBytes) {
    if(rval != STORAGE_OK) {
      opFailedInIO();
      return;
    }
    if(numBytes != datalengthInWords*sizeof(int16_t)) {
      opFailedInIO();
      return;
    }
    if(call LogWrite.sync() != SUCCESS) {
      opFailedInIO();
      return;
    }
  }

  /*
   * Check if everything is OK. If so, push a success value onto Mate
   * operand stack, reset the state, and resume the context. Dequeue
   * any waiting contexts.
   */
  event void LogWrite.syncDone(storage_result_t rval) {
    if(rval != STORAGE_OK) {
      opFailedInIO();
      return;
    }
    // return to mate script that it was successful
    call Stacks.pushValue(currentContext, 1);
    if(currentContext != NULL) {
      call Synch.resumeContext(currentContext, currentContext);
    }
    // Reset the state to READY
    currentContext = NULL;
    fStatus = READY;

    // Dequeue any waiting contexts with read priority.
    if (!call Queue.empty(&readQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &readQueue);
      tryRead(context);
      return;
    }
    if (!call Queue.empty(&writeQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &writeQueue);
      tryWrite(context);
      return;
    }
  }

  /* BEGIN READ CODE */

  /*
   * Pop operands from TinyScript and move into private area. Then try
   * to seek to the correct block offset on flash. If successful, change
   * the state, and block/yield context.
   */
  result_t tryRead(MateContext* context) {
    MateStackVariable* mBuffer;
    MateStackVariable* mId;
    
    mId = call Stacks.popOperand(context);
    mBuffer = call Stacks.popOperand(context);
    call TypeCheck.checkTypes(context, mBuffer, MATE_TYPE_BUFFER);
    call TypeCheck.checkTypes(context, mId, MATE_TYPE_INTEGER);

    // put out the actual values
    outputBuf = mBuffer->buffer.var;
    rid = mId->value.var;

    if(call LogRead.seek(rid*RECORD_SIZE_IN_WORDS*sizeof(int16_t)) == FAIL) {
      // abort abort!
      // Ignore the following comment block
      /*
      call Stacks.pushOperand(context, mBuffer);
      call Stacks.pushOperand(context, mId);
      context->state = MATE_STATE_WAITING;
      call Queue.enqueue(context, &readQueue, context);
      return SUCCESS;
      */
      opFailed(context);
      return SUCCESS;
    }
    fStatus = READ;
    currentContext = context;
    context->state = MATE_STATE_BLOCKED;
    call Synch.yieldContext(context);
    return SUCCESS;
  }

  command result_t FRead.byteLength() { return 1; }

  /*
   * Mate Execution code. Check if flash is busy. If so, queue it.
   * Otherwise, try to read.
   */
  command result_t FRead.execute(uint8_t instr, MateContext* context) {
    if(fStatus != READY) {
      context->state = MATE_STATE_WAITING;
      call Queue.enqueue(context, &readQueue, context);
      return SUCCESS;
    }
    return tryRead(context);
  }

  /*
   * Check if seek was successful. If so, setup MateBuffer metadata by
   * clearing the buffer and setting it to type INTEGER. Then prepare
   * for read.
   */
  event void LogRead.seekDone(storage_result_t rval, log_cookie_t cookie) {
    if(rval != STORAGE_OK) {
      opFailedInIO();
      return;
    }
    // clear the buffer and set its type
    call Buffer.clear(currentContext, outputBuf);
    outputBuf->type = MATE_TYPE_INTEGER;

    if(call LogRead.read((uint8_t*)databuf,
			 RECORD_SIZE_IN_WORDS*sizeof(int16_t))
       == FAIL) {
      opFailedInIO();
      return;
    }
  }

  /*
   * This code is composed of 3 main pieces:
   * 1. Check if data was properly read, and stuff it into buffer passed in
   * 2. Push a successful value onto stack, resume context, and READY status
   * 3. Dequeue any waiting contexts with readers taking priority
   */
  event void LogRead.readDone(storage_result_t rval,
			      void* data,
			      log_len_t numBytes) {
    int i;
    int readLen;

    if(rval != STORAGE_OK) {
      opFailedInIO();
      return;
    }
    readLen = numBytes/sizeof(int16_t);
    // stuff the array into the mate buffer
    for(i = 0; i < readLen; i++) {
      outputBuf->entries[i] = databuf[i];
    }
    // set the length
    outputBuf->size = readLen;
    //call Stacks.pushBuffer(currentContext, outputBuf);
    call Stacks.pushValue(currentContext, 1);
    if(currentContext != NULL) {
      call Synch.resumeContext(currentContext, currentContext);
    }
    currentContext = NULL;
    fStatus = READY;
    // readers take priority
    if (!call Queue.empty(&readQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &readQueue);
      tryRead(context);
      return;
    }
    if (!call Queue.empty(&writeQueue)) {
      MateContext* context = call Queue.dequeue(NULL, &writeQueue);
      tryWrite(context);
      return;
    }
  }

  /* BEGIN ERASE CODE */
  command result_t FFormat.byteLength() { return 1; }

  /*
   * Mate execution code to erase the flash.
   */
  command result_t FFormat.execute(uint8_t instr, MateContext* context) {
    MateStackVariable* mSize;
    int16_t newSize;
    
    mSize = call Stacks.popOperand(context);
    call TypeCheck.checkTypes(context, mSize, MATE_TYPE_INTEGER);
    newSize = mSize->value.var;
    if(newSize > MATE_BUF_LEN - (sizeof(RecordMetadata) / 2)) {
      opFailed(context);
      return SUCCESS;
    }
    SENSOR_READINGS = newSize;
    call IFlash.write((void*)LOC_RECSIZE, (void *)&(SENSOR_READINGS), 2);

    if(fStatus != READY) {
      opFailed(context);
      return SUCCESS;
    }
    
    call Leds.set(4);
    if(call LogWrite.erase() != SUCCESS) {
      opFailed(context);
      return SUCCESS;
    }
    fStatus = DEL;
    context->state = MATE_STATE_BLOCKED;
    currentContext = context;
    call Synch.yieldContext(context);
    return SUCCESS;
  }

  event void LogWrite.eraseDone(storage_result_t sval) {
    if(sval != STORAGE_OK) {
      opFailedInIO();
      return;
    }
    call Leds.set(2);
    call DataCacheReset(); // reset sequence number

    call Stacks.pushValue(currentContext, 1);
    if(currentContext != NULL) {
      call Synch.resumeContext(currentContext, currentContext);
    }
    currentContext = NULL;
    fStatus = READY;
  }

  /*
   * Initialize the DataCacheM. Now that I think about it, this might be
   * redundant. This is actually signalled from FlashLogger/FlashLoggerM.
   * If everything went OK, green LEDs turn on and flash is ready for use.
   */  
  event void VolumeInit.initDone(storage_result_t sval) {
    // this call gets signaled at the end of the bootup phase
    if((sval == STORAGE_OK) && (call DataCacheControl.init() == SUCCESS)) {
      call Leds.set(2);
    }
    fStatus = READY;
  }

  /*
   * If the Mate ever reboots, clean up after itself. Ready the flash
   * and clear out the queues.
   */  
  event void EngineStatus.rebooted() {
    call Queue.init(&writeQueue);
    call Queue.init(&readQueue);
    currentContext = NULL;
    fStatus = READY;
  }

  command void getRecordSize(int16_t* sensors, int16_t* total) {
    *sensors = SENSOR_READINGS;
    *total = RECORD_SIZE_IN_WORDS;
  }
}
