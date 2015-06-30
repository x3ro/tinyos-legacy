module TestNeighborM {
  provides {
    interface StdControl;
  }
  uses {
    interface Fiber;
    interface NCSNeighborhood;
  }
}
implementation {

  enum {
    MAX_NEIGHBORS = 16,
//    TIMEOUT = 10000,
    TIMEOUT = 0,
  };

  int num_neighbors;
  uint16_t neighbors[MAX_NEIGHBORS];

  /*********************************************************************** 
   * main fiber
   ***********************************************************************/

  void fiber_run(void *arg) {
    int i, n;

    dbg(DBG_USR1, "TestNeighborM: Calling getNeighbors\n");
    n = call NCSNeighborhood.getNeighbors(neighbors, MAX_NEIGHBORS, TIMEOUT);
    dbg(DBG_USR1, "TestNeighborM: Got %d neighbors\n", n);
    for (i = 0; i < n; i++) {
      dbg(DBG_USR1, "TestNeighborM: neighbors[%d] is %d\n", i, neighbors[i]);
    }
  }

  /*********************************************************************** 
   * Initialization 
   ***********************************************************************/

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call Fiber.start(fiber_run, NULL);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

}


