module TestStrawM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer;
    interface SplitControl;
    
    interface Mount;
    interface BlockRead;
    interface Straw;
  }
}
implementation
{
  enum {
    RETRY_INTRV = 17,
  };


  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, RETRY_INTRV);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }


  event result_t SplitControl.initDone() {
    return SUCCESS;
  }
  event result_t SplitControl.startDone() {
    return SUCCESS;
  }
  event result_t SplitControl.stopDone() {
    return SUCCESS;
  }


  event result_t Timer.fired() {
    if (!call Mount.mount(FLASH_LOG_ID)) {
      call Timer.start(TIMER_ONE_SHOT, RETRY_INTRV);
    }
    return SUCCESS;
  }



  event void Mount.mountDone(storage_result_t result, volume_id_t id) {
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

