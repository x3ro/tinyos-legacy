
module MainP {
  provides interface Boot;
  uses interface Scheduler;
  uses interface Init as PlatformInit;
  uses interface StdControl as StdControl;

  // For a given id, you MUST only use AT MOST one of the following four
  // interfaces.  You MUST NOT use id 255.

  uses interface SplitControl as MainSplitControl[uint8_t id];
  uses interface StdControl as MainStdControl[uint8_t id];
  uses interface Init as MainInit[uint8_t id];
}
implementation {

  uint8_t m_starting;

  void init() {
    uint8_t i;
    call PlatformInit.init();
    for( i=0; i<255; i++ )
      call MainSplitControl.init[i]();
    call StdControl.init();
  }

  void startDone( uint8_t started ) {
    if( started == m_starting ) {

      do {
        m_starting++;
        if( call MainSplitControl.start[m_starting]() == SUCCESS )
          return;
      } while( m_starting < 255 );

      call StdControl.start();
      signal Boot.booted();

    }
  }


 int main() __attribute__ ((C, spontaneous)) {
    atomic { 
      call Scheduler.init(); 
      init();
      while (call Scheduler.runNextTask(FALSE));
    }
    
    // Enable interrupts now that system is ready.
    __nesc_enable_interrupt();

    m_starting = 255;
    startDone( 255 );

    // Spin on the Scheduler, passing TRUE so the Scheduler will, when
    // there are no more tasks to run, put the CPU to sleep until the
    // next interrupt arrives.
    for(;;) {
      call Scheduler.runNextTask(TRUE);
    }
  }


  default command result_t MainSplitControl.init[uint8_t id]() {
    call MainStdControl.init[id]();
    return FAIL; //no done event coming
  }

  default command result_t MainSplitControl.start[uint8_t id]() {
    call MainStdControl.start[id]();
    return FAIL; //no done event coming
  }

  default command result_t MainSplitControl.stop[uint8_t id]() {
    call MainStdControl.stop[id]();
    return FAIL; //no done event coming
  }


  default command result_t MainStdControl.init[uint8_t id]() {
    return call MainInit.init[id]();
  }

  default command result_t MainStdControl.start[uint8_t id]() {
    return FAIL;
  }

  default command result_t MainStdControl.stop[uint8_t id]() {
    return FAIL;
  }


  default command result_t MainInit.init[uint8_t id]() {
    return FAIL;
  }


  event result_t MainSplitControl.initDone[uint8_t id]() {
    return SUCCESS;
  }

  event result_t MainSplitControl.startDone[uint8_t id]() {
    startDone(id);
    return SUCCESS;
  }

  event result_t MainSplitControl.stopDone[uint8_t id]() {
    return SUCCESS;
  }



  default command result_t StdControl.init() {
    return SUCCESS;
  }

  default command result_t StdControl.start() {
    return SUCCESS;
  }

  default command result_t StdControl.stop() {
    return SUCCESS;
  }


  default event void Boot.booted() {
  }
}

