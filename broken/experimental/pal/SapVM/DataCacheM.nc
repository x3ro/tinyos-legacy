includes Mate;
includes FSMate;
includes HALSTM25P;

module DataCacheM {
  provides interface MateBytecode as Stamp;
  provides interface MateBytecodeLock;
  provides interface StdControl;
  provides command void reset();
  provides command void flashError();
  uses {
    interface InternalFlash as IFlash;
    interface MateError as Error;
    interface MateStacks as Stacks;
    interface MateBuffer as Buffer;
    interface MateTypes as TypeCheck;
    interface MateLocks as Locks;
    interface GlobalTime;
    interface MateEngineStatus as EngineStatus;
    interface Leds;
    command void getRecordSize(int16_t* sensors, int16_t* total);
  }
}

implementation {
  typedef enum {
    SAVIA_BUF_LOCK = unique("MateLock"),
  } SaviaLockName;

  int16_t sensorReadings;
  int16_t totalRecordSize;

  RecordMetadata metadata;
  MateDataBuffer databuf; //return this to user
  // initialize metadata book keeping
  uint32_t iflashStart = 0;

  /*
   * Initialize reading values
   */
  command result_t StdControl.init() {
    call IFlash.read((void*)12, (void *)&(metadata.seqNo), 4);
    // if just reprogrammed, don't use -1... minor hack
    // you shouldn't have 4 billion timestamps anyway
    if(metadata.seqNo == -1) {
      metadata.seqNo = 0;
    }
    metadata.timeStamp = 0;
    metadata.status = 0;
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  command int16_t MateBytecodeLock.lockNum(uint8_t instr, uint8_t id,
					   uint8_t pc) {
    return SAVIA_BUF_LOCK;
  }

  command result_t Stamp.byteLength() { return 1; }

  /*
   * Read in the values from TinyScript and store them into the variables.
   * Grab the timestamp and increment the sequence number for the person
   * pulling the data out from passed in buffer. Also store the sequence number
   * into metadata in case power goes out. See README for InternalFlash
   * addresses
   */
  command result_t Stamp.execute(uint8_t instr, MateContext* context) {
    // for writing
    MateStackVariable* buf;
    int16_t* bufdata;
    int i;
    uint8_t lock;

    // for reading
    uint32_t *tempPtr;
    int16_t* destPtr = databuf.entries + sizeof(RecordMetadata) / 2;
    // int payloadIndex;

    call getRecordSize(&sensorReadings, &totalRecordSize);

    // check locks
    lock = SAVIA_BUF_LOCK;
    if ((lock == 255) || !call Locks.isHeldBy(lock, context)) {
      call Error.error(context, MATE_ERROR_INVALID_ACCESS);
      return FAIL;
    }

    buf = call Stacks.popOperand(context);
    call TypeCheck.checkTypes(context, buf, MATE_TYPE_BUFFER);
    // Let's not type check inside because they could be arbitrary integers
    // However, we should check there aren't more entries than they stated.
    if(buf->buffer.var->size > sensorReadings) {
      call Error.error(context, MATE_ERROR_BUFFER_OVERFLOW);
      return SUCCESS;
    }
    if(buf->buffer.var->size < sensorReadings) {
      call Error.error(context, MATE_ERROR_BUFFER_UNDERFLOW);
      return SUCCESS;
    }

    // initialize target buffer
    call Buffer.clear(context, &databuf);
    databuf.type = MATE_TYPE_INTEGER;
    databuf.size = totalRecordSize; // sum of stuff

    // process the mate buffer and store it
    bufdata = buf->buffer.var->entries;
    for(i = 0; i < buf->buffer.var->size; i++) {
      destPtr[i] = bufdata[i];
    }

    call GlobalTime.getGlobalTime(&(metadata.timeStamp));
    metadata.seqNo++;
    // save sequence number in case system crashes
    call IFlash.write((void*)LOC_SEQNO, (void *)&(metadata.seqNo), 4);

    // now copy the metadata to the new buffer
    tempPtr = (uint32_t *)&(databuf.entries[0]);
    *tempPtr = metadata.timeStamp;
    tempPtr = (uint32_t *)&(databuf.entries[2]);
    *tempPtr = metadata.seqNo;
    databuf.entries[4] = metadata.status;

    return call Stacks.pushBuffer(context, &databuf);
  }
  /*
   * Reset any readings and reset metadata for sequence number to 0
   */
  command void reset() {
    call IFlash.write((void*)LOC_SEQNO, (void *)&iflashStart, 4);
    metadata.seqNo = 0;
    metadata.timeStamp = 0;
    metadata.status = 0;
  }

  /*
   * Alert user if there is a flash problem by setting status bits
   * in buffer/packet
   */
  command void flashError() {
    metadata.status = metadata.status | 0x1;
  }

  /*
   * Clear buffer if reboot context
   */
  event void EngineStatus.rebooted() {
    databuf.type = MATE_TYPE_NONE;
    databuf.size = 0;
  }
}
