generic module ServiceOrController(char* str) {
  provides {
    interface ServiceControl[uint8_t id];
  }
  uses {
    interface ServiceControl as SubControl;
  }

}
implementation {

  enum {
    USER_COUNT = uniqueCount(str),
    MASK_SIZE = ((USER_COUNT + 7) / 8)
    
  }
  uint8_t mask[MASK_SIZE];

  bool anyOn() {
    int i;
    for (i = 0; i < MASK_SIZE; i++) {
      if (mask[i] != 0) {
	return TRUE;
      }
    }
    return FALSE;
  }

  bool isOn(uint8_t id) {
    uint8_t m = mask[id / 8];
    m = m >> (id % 8);
    return (m & 1);
  }

  void set(uint8_t id) {
    mask[id / 8] |= (1 << (id % 8));
  }

  void clear(uint8_t id) {
    mask[id / 8] &= ~(1 << (id % 8));
  }
  
  command error_t ServiceControl.start[uint8_t id]() {
    bool start;
    if (id >= USER_COUNT) {return EINVALID;}
    if (isOn(id)) {return SUCCESS;}
    start = !anyOn();

    set(id);
    if (start) {
      call SubControl.start();
    }
  }

  command error_t ServiceControl.stop[uint8_t id]() {
    if (id >= USER_COUNT) {return EINVALID;}
    if (isOn(id) == FALSE) {return SUCCESS;}
    clear(id);
    if (anyOn() == FALSE) {
      call SubControl.stop();
    }
  }
}
