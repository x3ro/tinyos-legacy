generic module SplitControlCountP() {
  provides {
    interface SplitControl;
    interface Get<int8_t> as GetRefCount;
    interface Set<int8_t> as SetRefCount;
  }
  uses interface SplitControl as LowerControl;
}
implementation {

  enum {
    FLAG_START = 0x01,
    FLAG_STOP = 0x02,
    FLAG_START_PEND = 0x04,
    FLAG_STOP_PEND = 0x08,
  };

  uint8_t m_flags;
  norace int8_t m_refcount = 0;

  async command int8_t GetRefCount.get() {
    return m_refcount;
  }

  async command void SetRefCount.set(int8_t _r) {
    atomic m_refcount = _r;
  }

  task void nextAction() {
    /*
    if (m_flags & (FLAG_START | FLAG_STOP))
      return;
    if (m_flags & (FLAG_START_PEND)) {
      if (call LowerControl.start() == SUCCESS) {
	m_flags &= ~FLAG_START_PEND;
	m_flags |= FLAG_START;
      }
      else
	post nextAction();
    }
    else if (m_flags & (FLAG_STOP_PEND)) {
      if (call LowerControl.stop() == SUCCESS) {
	m_flags &= ~FLAG_STOP_PEND;
	m_flags |= FLAG_STOP;
      }
      else
	post nextAction();
    }
    */
  }

  command result_t SplitControl.init() {
    return call LowerControl.init();
  }

  command result_t SplitControl.start() {
    m_refcount++;
    return call LowerControl.start();
    /*
    if (m_refcount <= 1) {
      m_refcount = 1;
      if (call LowerControl.start() == SUCCESS) {
	m_flags |= FLAG_START;
      }
      else {
	m_flags |= FLAG_START_PEND;
	post nextAction();
      }
    }
    else 
      signal SplitControl.startDone();
    return SUCCESS;
    */
  }

  command result_t SplitControl.stop() {
    m_refcount--;
    return call LowerControl.stop();
    /*
    if (m_refcount <= 0) {
      m_refcount = 0;
      if (call LowerControl.stop() == SUCCESS) {
	m_flags |= FLAG_STOP;
      }
      else {
	m_flags |= FLAG_STOP_PEND;
	post nextAction();
      }
    }
    else 
      signal SplitControl.startDone();
    return SUCCESS;
    */
  }

  event result_t LowerControl.initDone() {
    return signal SplitControl.initDone();
  }
  event result_t LowerControl.startDone() {
    m_flags &= ~FLAG_START;
    post nextAction();
    return signal SplitControl.startDone();
  }
  event result_t LowerControl.stopDone() {
    m_flags &= ~FLAG_STOP;
    post nextAction();
    return signal SplitControl.stopDone();
  }
}
