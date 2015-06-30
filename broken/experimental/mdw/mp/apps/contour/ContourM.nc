/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes SharedVar;
includes Location;

/** 
 * Contour finding: Find boundary points between regions in the sensor 
 * network above or below a given threshold sensor reading.
 */

module ContourM {
  provides {
    interface StdControl;
  }
  uses {
    interface SharedVar as SV_location;
    interface SharedVar as SV_belowset;
    interface ADC;
    interface Neighborhood;
    interface Timer;
    interface Location;
    interface Barrier;
  }
}
implementation {

  enum {
    TIMER_RATE = 1000,	               // Timer rate in ms
    TIMER_CONTOUR_COUNT = 1,           // Timer ticks for running contour
    MAX_NEIGHBORS = 8,	               // Max # neighbors to consider
    THRESHOLD = 50,		       // Sensor threshold
  };

  /* Continuation states */
  int state;
  enum {
    STATE_CONTOUR_TASK_0,
    STATE_CONTOUR_TASK_1,
    STATE_CONTOUR_TASK_2,
    STATE_CONTOUR_TASK_3,
    STATE_CONTOUR_TASK_4,
    STATE_CONTOUR_TASK_5,
    STATE_CONTOUR_TASK_6,
    STATE_CONTOUR_TASK_7,
    STATE_IDLE,
  };

  /* Global state - effectively what gets passed around in continuations.
   * Normally there would be separate continuation structures for each
   * task, but, since everything is in the same scope here I cheat with
   * globals.
   */
  int timer_ticks;
  uint16_t Reading;
  location_3d_t *myLocation;
  int num_neighbors;
  bool aboveset;
  bool belowset;
  int outstanding_read_count;
  int outstanding_write_count;
  uint16_t neighbors[MAX_NEIGHBORS];
  bool belowset_remote[MAX_NEIGHBORS];
  location_3d_t Location_remote[MAX_NEIGHBORS];
  location_3d_t contourpoints[MAX_NEIGHBORS];

  /*********************************************************************** 
   * Initialization 
   ***********************************************************************/

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    state = STATE_IDLE;
    return call Timer.start(TIMER_REPEAT, TIMER_RATE);
  }

  command result_t StdControl.stop() {
    state = STATE_IDLE;
    return call Timer.stop();
  }

  /***********************************************************************
   * Utilities
   ***********************************************************************/
  static location_3d_t midpoint(location_3d_t a, location_3d_t b) {
    location_3d_t mid;
    mid.x = (a.x + b.x) / 2.0;
    mid.y = (a.y + b.y) / 2.0;
    mid.z = (a.z + b.z) / 2.0;
    return mid;
  }

  /***********************************************************************
   * Tasks
   ***********************************************************************/

  task void contour_task_0();
  task void contour_task_1();
  task void contour_task_2();
  task void contour_task_3();
  task void contour_task_4();
  task void contour_task_5();
  task void contour_task_6();
  task void contour_task_7();

  // Initiate ADC read
  task void contour_task_0() {
    int n;
    state = STATE_CONTOUR_TASK_0;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);
    for (n = 0; n < MAX_NEIGHBORS; n++) belowset_remote[n] = 0;
    if (!call ADC.getData()) {
      dbg(DBG_USR1, "Contour: ADC.getData failed\n");
      state = STATE_IDLE;
    }
    return;
  }

  // Get local location and write to SV
  // (Could have been rolled into contour_task_0)
  task void contour_task_1() {
    state = STATE_CONTOUR_TASK_1;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);
    dbg(DBG_USR1, "Contour: My reading is %d\n", Reading);

    if (!call Location.getLocation()) {
      dbg(DBG_USR1, "Contour: getLocation failed\n");
      state = STATE_IDLE;
    }
    return;
  }

  // Set local aboveset/belowset and write belowset to SV
  task void contour_task_2() {
    state = STATE_CONTOUR_TASK_2;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);
    dbg(DBG_USR1, "Contour: My Location is %f %f %f\n", myLocation->x, myLocation->y, myLocation->z);

    if (!call SV_location.put(myLocation, sizeof(*myLocation))) {
      dbg(DBG_USR1, "Contour: SV_location.put failed\n");
      state = STATE_IDLE;
      return;
    }

    if (Reading >= THRESHOLD) {
      aboveset = TRUE;
    }
    if (Reading < THRESHOLD) {
      belowset = TRUE;
      if (!call SV_belowset.put(&belowset, sizeof(belowset))) {
   	// XXX Should we pass the failure onto the user?
      }
      post contour_task_3();
    } else {
      // XXX Interesting: Have to be conservative about continuations;
      // still post this task even though we could just continue operating
      // in the same task (maybe just call the function instead?)
      post contour_task_3();
    }
  }

  // Get neighbors
  task void contour_task_3() {
    state = STATE_CONTOUR_TASK_3;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);
    if (!call Neighborhood.getNeighborhood()) {
      dbg(DBG_USR1, "Contour: getNeighborhood failed\n");
      state = STATE_IDLE;
    }
    return;
  }

  // If in aboveset, read belowset of neighbors
  task void contour_task_4() {
    int count, n;

    state = STATE_CONTOUR_TASK_4;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);

    if (aboveset) {
      num_neighbors = call Neighborhood.getNeighbors(neighbors, MAX_NEIGHBORS);
      dbg(DBG_USR1, "Contour: I have %d neighbors\n", num_neighbors);
      for (n = 0; n < num_neighbors; n++) {
	dbg(DBG_USR1, "Contour: neighbors[%d] is %d\n", n, neighbors[n]);
      }

      // Issuing all reads in parallel (not separate tasks)
      count = 0;
      for (n = 0; n < num_neighbors; n++) {
	// XXX What to do if some of these reads fail?
	outstanding_read_count++;
	call SV_belowset.get(neighbors[n], &(belowset_remote[n]), sizeof(belowset_remote[n]));
      }
      if (outstanding_read_count == 0) call Barrier.barrier();
    } else {
      // Not in aboveset
      call Barrier.barrier();
    }
  }

  // If in aboveset, read location of neighbors in belowset
  task void contour_task_5() {
    int n;
    bool found = FALSE;
    state = STATE_CONTOUR_TASK_5;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);

    // Note that aboveset *must* be true here, since other nodes
    // are still in barrier()
    for (n = 0; n < num_neighbors; n++) {
      if (belowset_remote[n]) {
	outstanding_read_count++;
	found = TRUE;
	call SV_location.get(neighbors[n], &(Location_remote[n]), sizeof(Location_remote[n]));
      }
    }

    if (!found) post contour_task_6();
  }

  // If in aboveset, compute midpoint of each neighbor in belowset 
  // and write to SM
  task void contour_task_6() {
    int num_cpoints, n;
    state = STATE_CONTOUR_TASK_6;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);

    for (n = 0; n < num_neighbors; n++) {
      if (belowset_remote[n]) {
	num_cpoints++;
	contourpoints[n] = midpoint(*myLocation, Location_remote[n]);
	dbg(DBG_USR1, "CONTOUR POINT: %f %f %f\n", contourpoints[n].x, contourpoints[n].y, contourpoints[n].z);
      }
    }
    post contour_task_7();
  }

  // Done with contourpoints write, do barrier
  task void contour_task_7() {
    state = STATE_CONTOUR_TASK_7;
    dbg(DBG_USR1, "Contour: Entering state %d\n", state);
    call Barrier.barrier();
  }

  /*********************************************************************** 
   * ADC, SM, and Timer events
   ***********************************************************************/

  // Gee, it would be nice to have compiler-supported continuations
  event result_t ADC.dataReady(uint16_t data) {
    dbg(DBG_USR1, "Contour: ADC.dataReady, state %d\n", state);

    switch (state) {
      case STATE_CONTOUR_TASK_0:
	Reading = data;
	post contour_task_1();
	break;
      default:
	dbg(DBG_USR1, "Contour: ERROR: ADC.dataReady in unknown state %d\n", state);
	break;
    }
    return SUCCESS;
  }


  // Gee, it would be nice to have compiler-supported continuations
  event void Location.locationDone(location_3d_t *loc) {
    dbg(DBG_USR1, "Contour: Location.locationDone, state %d\n", state);

    switch (state) {
      case STATE_CONTOUR_TASK_1:
	myLocation = loc;
	post contour_task_2();
	break;
      default:
	dbg(DBG_USR1, "Contour: ERROR: Location.locationDone in unknown state %d\n", state);
	break;
    }
  }

  event void Neighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR1, "Contour: getNeighborhoodDone, state %d\n", state);
    switch (state) {
      case STATE_CONTOUR_TASK_3:
	post contour_task_4();
	break;
      default:
	dbg(DBG_USR1, "Contour: ERROR: getNeighborhoodDone in unknown state %d\n", state);
	break;
    }
  }

  event void SV_belowset.getDone(uint16_t moteaddr, void *buf, int buflen, result_t success) {
    dbg(DBG_USR1, "Contour: SV_belowset.getDone, state %d\n", state);
    switch (state) {
      case STATE_CONTOUR_TASK_4:
	if (--outstanding_read_count == 0) {
	  // XXX Note that failed read not noted here
	  post contour_task_5();
	}
	break;
      default:
	dbg(DBG_USR1, "Contour: ERROR: getDone in unknown state %d\n", state);
	break;
    }
  }

  event void SV_location.getDone(uint16_t moteaddr, void *buf, int buflen, result_t success) {
    dbg(DBG_USR1, "Contour: SV_location.getDone, state %d\n", state);
    switch (state) {
      case STATE_CONTOUR_TASK_5:
	if (--outstanding_read_count == 0) {
	  // XXX Note that failed read not noted here
	  post contour_task_6();
	}
	break;
      default:
	dbg(DBG_USR1, "Contour: ERROR: getDone in unknown state %d\n", state);
	break;
    }
  }
  
  event result_t Timer.fired() {
    dbg(DBG_USR1, "Contour: Timer fired, state %d\n", state);
    timer_ticks++;
    if (state == STATE_IDLE && (timer_ticks % TIMER_CONTOUR_COUNT == 0)) {
      post contour_task_0();
    }
    return SUCCESS;
  }

  event void Barrier.barrierDone() {
    dbg(DBG_USR1, "Contour: Barrier done, entering STATE_IDLE\n");
    state = STATE_IDLE;
  }

}


