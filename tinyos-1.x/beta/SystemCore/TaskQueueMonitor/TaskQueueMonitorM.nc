module TaskQueueMonitorM {
  provides interface StdControl;
  uses {
    interface MgmtAttr as MA_TaskQueueDiscards;
  }
}

implementation {

  command result_t StdControl.init() {
    call MA_TaskQueueDiscards.init(sizeof(uint8_t), MA_TYPE_UINT);
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }

  command result_t StdControl.stop() { return SUCCESS; }

  event result_t MA_TaskQueueDiscards.getAttr(uint8_t *buf) {
    atomic {
      memcpy(buf, &TOSH_sched_task_queue_discards, 
	     sizeof(TOSH_sched_task_queue_discards));
      if (TOSH_sched_task_queue_discards == 0xff) {
	TOSH_sched_task_queue_discards = 0;
      }
    }
    return SUCCESS;
  }
}
