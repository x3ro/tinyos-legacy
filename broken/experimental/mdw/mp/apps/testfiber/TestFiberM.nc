includes Fiber;

module TestFiberM {
  provides interface StdControl;
  uses interface Fiber;
  uses interface NCSLib;
  uses interface NCSSensor;
  uses interface Leds;
} implementation {

  void fiber_go_yield(void *arg) {
    int i = 0;
    int num = (int)arg;
    while (1) {
      dbg(DBG_USR1, "Fiber %d running: %d\n", num, i);
      if (++i % 10 == 0) {
	//if (num == 0) {
	//  call Leds.redToggle();
	//} else {
	//  call Leds.greenToggle();
	//}
	dbg(DBG_USR1, "Fiber %d yielding\n", num);
	call Fiber.yield();
	dbg(DBG_USR1, "Fiber %d resumed\n", num);
      }
    }
  }

  fiber_t *sleep_queue;

  void fiber_go_sleep(void *arg) {
    int i = 0;
    int num = (int)arg;
    while (1) {
      dbg(DBG_USR1, "Fiber %d running: %d\n", num, i);
      if (++i % 10 == 0) {
	dbg(DBG_USR1, "Fiber %d calling wakeup\n", num);
	call Fiber.wakeup(&sleep_queue);
	dbg(DBG_USR1, "Fiber %d sleeping\n", num);
	call Fiber.sleep(&sleep_queue);
	dbg(DBG_USR1, "Fiber %d resumed\n", num);
      }
    }
  }

  void fiber_go_sleep2(void *arg) {
    int i = 0;
    int num = (int)arg;
    while (1) {
      dbg(DBG_USR1, "Fiber %d running: %d\n", num, i);
      //  if (++i % 10 == 0) {
      if (num == 0) {
	call Leds.redToggle();
      } else {
	call Leds.greenToggle();
      }
      dbg(DBG_USR1, "Fiber %d calling sleep\n", num);
      call NCSLib.sleep(500);
      dbg(DBG_USR1, "Fiber %d resumed\n", num);
      //    }
    }
  }

  void fiber_go_photo(void *arg) {
    uint16_t data;
    while (1) {
      dbg(DBG_USR1, "Photo fiber running\n");
      call Leds.redToggle();
      dbg(DBG_USR1, "Photo fiber calling sleep\n");
      call NCSLib.sleep(100);
      dbg(DBG_USR1, "Photo fiber calling getData\n");
      data = call NCSSensor.getData();
      dbg(DBG_USR1, "Photo fiber got data: 0x%x\n", data);
      if (data > 0x100) call Leds.greenOn();
      else call Leds.greenOff();
    }
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "Creating Fiber 0\n");
    call Fiber.start(fiber_go_photo, (void *)0);
    dbg(DBG_USR1, "Done creating fibers\n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }



}
