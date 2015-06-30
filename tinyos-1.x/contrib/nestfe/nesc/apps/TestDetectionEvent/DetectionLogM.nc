includes DetectionLog;
includes Rpc;

module DetectionLogM
{
  provides {
    interface StdControl;

    command result_t logErase() @rpc();
    command result_t logStart() @rpc();
    command result_t logStop() @rpc();
    command result_t logRead() @rpc();
    command result_t logReset() @rpc();
  }
  uses {
    interface Attribute<uint16_t> as PIRDetectValue @registry("PIRDetectValue");
    interface Mount as LogMount;
    interface Mount as BlockMount;
    interface LogWrite;
    interface BlockRead;
    interface Straw;
  }
}
implementation
{
  uint8_t state;
  command result_t StdControl.init() {
    state = DETECTION_LOG_STATE_IDLE;
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call LogMount.mount(DETECTION_FLASH_ID);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }


  command result_t logErase() {
    if (state == DETECTION_LOG_STATE_IDLE) {
      if (call LogWrite.erase()) {
        state = DETECTION_LOG_STATE_ERASE;
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  command result_t logStart() {
    if (state == DETECTION_LOG_STATE_IDLE) {
      state = DETECTION_LOG_STATE_SAMPLE;
      return SUCCESS;
    }
    return FAIL;
  }
  
  command result_t logStop() {
    if (state == DETECTION_LOG_STATE_SAMPLE) {
      state = DETECTION_LOG_STATE_IDLE;
      if (call LogWrite.sync()) {
        state = DETECTION_LOG_STATE_SYNC;
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  command result_t logRead() {
    if (state == DETECTION_LOG_STATE_IDLE) {
      state = DETECTION_LOG_STATE_READ;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t logReset() {
    state = DETECTION_LOG_STATE_IDLE;
    return SUCCESS;
  }



  event void PIRDetectValue.updated(uint16_t data) {
    if (state == DETECTION_LOG_STATE_SAMPLE) {
      call LogWrite.append(&data, sizeof(uint16_t));
    }
  }


  event void LogMount.mountDone(storage_result_t result, volume_id_t id) {
    call BlockMount.mount(DETECTION_FLASH_ID);
  }
  event void BlockMount.mountDone(storage_result_t result, volume_id_t id) {
  }


  event void LogWrite.eraseDone(storage_result_t result) {
    state = DETECTION_LOG_STATE_IDLE;
  }
  event void LogWrite.appendDone(storage_result_t result, void* data,
    log_len_t numBytes) {
  }
  event void LogWrite.syncDone(storage_result_t result) {
    state = DETECTION_LOG_STATE_IDLE;
  }


  event void BlockRead.readDone(storage_result_t result, block_addr_t addr,
    void* buf, block_addr_t len) {
    call Straw.readDone(result == STORAGE_OK ? SUCCESS : FAIL);
  }
  event void BlockRead.verifyDone(storage_result_t result) {
  }
  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc,
    block_addr_t addr, block_addr_t len) {
  }


  event result_t Straw.read(uint32_t start, uint32_t size, uint8_t* bffr) {
    return call BlockRead.read(start, bffr, size);
  }

}

