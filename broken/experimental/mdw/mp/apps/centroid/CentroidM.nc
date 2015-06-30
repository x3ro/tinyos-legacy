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

includes SharedMem;
includes Location;

/**
 * Centroid finding/object tracking application: find the centroid of 
 * sensor readings above a given threshold.
 */

module CentroidM {
  provides {
    interface StdControl;
  }
  uses {
    interface SharedMem as SM;
    interface ADC;
    interface Neighborhood;
    interface Timer;
    interface Location;
    interface Reduce;
    interface Barrier;
  }
}
implementation {

  enum {
    TIMER_RATE = 1000,	               // Timer rate in ms
    TIMER_CENTROID_COUNT = 1,          // Timer ticks for running contour
    MAX_NEIGHBORS = 16,	               // Max # neighbors to consider
    THRESHOLD = 0,		       // Sensor threshold
  };

  /* Continuation states */
  int state;
  enum {
    STATE_CENTROID_TASK_0 = 0,
    STATE_CENTROID_TASK_1 = 1,
    STATE_CENTROID_TASK_2 = 2,
    STATE_CENTROID_TASK_3 = 3,
    STATE_CENTROID_TASK_4 = 4,
    STATE_CENTROID_TASK_5 = 5,
    STATE_CENTROID_TASK_6 = 6,
    STATE_DONE = 100,
    STATE_IDLE = 200,
  };

  /* Global state - effectively what gets passed around in continuations.
   * Normally there would be separate continuation structures for each
   * task, but, since everything is in the same scope here I cheat with
   * globals.
   */
  int timer_ticks;
  uint16_t Reading;
  uint16_t maxReading;
  location_3d_t myLocation;
  location_3d_t cpoint;
  int num_neighbors;
  bool aboveset;
  int outstanding_read_count;
  int outstanding_write_count;
  uint16_t neighbors[MAX_NEIGHBORS];
  uint16_t Reading_remote[MAX_NEIGHBORS];
  location_3d_t Location_remote[MAX_NEIGHBORS];

  /* Shared mem offsets */
  enum {
    OFFSET_Reading = 0,
    OFFSET_Location = OFFSET_Reading + sizeof(uint16_t),
    OFFSET_centroid = OFFSET_Location + sizeof(location_3d_t),
  };

  /*********************************************************************** 
   * Initialization 
   ***********************************************************************/

  command result_t StdControl.init() {
    state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "Centroid: init\n");
    return call Timer.start(TIMER_REPEAT, TIMER_RATE);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Utilities
   ***********************************************************************/
  static location_3d_t centroid(int n, uint16_t *readings, location_3d_t *locations) {
    int i;
    float sum_m = 0.0, sum_x = 0.0, sum_y = 0.0, sum_z = 0.0;
    location_3d_t tmp;

    sum_m = Reading;
    sum_x += Reading * myLocation.x;
    sum_y += Reading * myLocation.y;
    sum_z += Reading * myLocation.z;

    dbg(DBG_USR1, "Centroid: Computing centroid\n");
    for (i = 0; i < n; i++) {
      dbg(DBG_USR1, "Centroid: readings[%d] is %d\n", i, readings[i]);
      dbg(DBG_USR1, "Centroid: locations[%d] is (%f,%f,%f)\n", i, locations[i].x, locations[i].y, locations[i].z);
      sum_m += readings[i];
      sum_x += readings[i] * locations[i].x;
      sum_y += readings[i] * locations[i].y;
      sum_z += readings[i] * locations[i].z;
    }
    tmp.x = (sum_x / sum_m);
    tmp.y = (sum_y / sum_m);
    tmp.z = (sum_z / sum_m);
    dbg(DBG_USR1, "Centroid: centroid point %f %f %f\n", tmp.x, tmp.y, tmp.z);
    return tmp;
  }

  /***********************************************************************
   * Tasks
   ***********************************************************************/

  task void centroid_task_0();
  task void centroid_task_1();
  task void centroid_task_2();
  task void centroid_task_3();
  task void centroid_task_4();
  task void centroid_task_5();
  task void centroid_task_6();

  // Initiate Location read
  task void centroid_task_0() {
    state = STATE_CENTROID_TASK_0;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);
    dbg(DBG_USR1, "Centroid: getting Location\n");
    if (!call Location.getLocation()) {
      dbg(DBG_USR1, "Centroid: getLocation failed\n");
      post centroid_task_6();
    }
    return;
  }

  task void centroid_task_1() {
    state = STATE_CENTROID_TASK_1;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);
    dbg(DBG_USR1, "Centroid: Calling ADC read\n");
    if (!call ADC.getData()) {
      dbg(DBG_USR1, "Centroid: ADC read failed\n");
      post centroid_task_6();
    }
    return;
  }

  // Write reading and location to SM
  task void centroid_task_2() {
    bool writeok;
    state = STATE_CENTROID_TASK_2;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);

    // Note: SM.writeDone triggered immediately
    outstanding_write_count = 2;
    writeok = TRUE;
    if (!call SM.write(&Reading, TOS_LOCAL_ADDRESS, OFFSET_Reading, sizeof(Reading))) {
      dbg(DBG_USR1, "Centroid: SM.write (Reading) failed\n");
      writeok = FALSE;
      outstanding_write_count--;
    }

    if (!call SM.write(&myLocation, TOS_LOCAL_ADDRESS, OFFSET_Location,
	  sizeof(myLocation))) {
      dbg(DBG_USR1, "Centroid: SM.write (myLocation) failed\n");
      writeok = FALSE;
      outstanding_write_count--;
    }

    // XXX Should pass error to user
    if (!writeok) {
      dbg(DBG_USR1, "Centroid: Could not perform SM.write, going to next state.\n");
      post centroid_task_3();
    }
  }

  // Perform globalmax reduce
  task void centroid_task_3() {
    state = STATE_CENTROID_TASK_3;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);

    if (Reading >= THRESHOLD) {
      if (!call Reduce.reduceToAll(0, OP_MAX, TYPE_UINT16, &Reading, &maxReading)) {
        dbg(DBG_USR1, "Centroid: Failed to initiate reduction\n");
	post centroid_task_4();
      }
    } else {
      // Don't participate in reduction but route packets
      if (!call Reduce.passThrough()) {
        dbg(DBG_USR1, "Centroid: Failed to initiate passThrough\n");
	post centroid_task_4();
      }
    }
  }

  // If ours is the maximum value, read values from neighbors
  task void centroid_task_4() {
    int n;
    bool some_succeeded;

    state = STATE_CENTROID_TASK_4;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);

    dbg(DBG_USR1, "Centroid: Got max reading 0x%x, my reading 0x%x\n", 
	maxReading, Reading);

    if (Reading >= THRESHOLD && Reading == maxReading) {
      num_neighbors = call Neighborhood.getNeighbors(neighbors, MAX_NEIGHBORS);
      dbg(DBG_USR1, "Centroid: I have %d neighbors\n", num_neighbors);

      // Issuing all reads in parallel (not separate tasks)
      outstanding_read_count = num_neighbors*2;
      some_succeeded = FALSE;
      for (n = 0; n < num_neighbors; n++) {
	if (!call SM.read(&(Reading_remote[n]), neighbors[n], OFFSET_Reading, sizeof(Reading_remote[n]))) {
	  dbg(DBG_USR1, "Centroid: SM.read (Reading[%d]) failed\n", n);
	  outstanding_read_count--;
	} else some_succeeded = TRUE;
      }
      for (n = 0; n < num_neighbors; n++) {
	if (!call SM.read(&(Location_remote[n]), neighbors[n], OFFSET_Location, sizeof(Location_remote[n]))) {
	  dbg(DBG_USR1, "Centroid: SM.read (Location[%d]) failed\n", n);
	  outstanding_read_count--;
	} else some_succeeded = TRUE;
      }
      if (!some_succeeded) call Barrier.barrier();

    } else {
      call Barrier.barrier();
    }
  }

  // Compute centroid from fetched values
  task void centroid_task_5() {
    state = STATE_CENTROID_TASK_5;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);

    // Note that aboveset *must* be true here, since other nodes
    // are still in barrier()
    cpoint = centroid(num_neighbors, Reading_remote, Location_remote);

    dbg(DBG_USR1, "Centroid: Writing centroid to SM\n");
    if (!call SM.write(&cpoint, TOS_LOCAL_ADDRESS, OFFSET_centroid, 
	  sizeof(cpoint))) {
      call Barrier.barrier();
    } 
  }

  task void centroid_task_6() {
    state = STATE_CENTROID_TASK_6;
    dbg(DBG_USR1, "Centroid: Entering state %d\n", state);
    call Barrier.barrier();
  }

  /*********************************************************************** 
   * ADC, SM, and Timer events
   ***********************************************************************/

  event void Location.locationDone(location_3d_t *loc) {
    switch (state) {
      case STATE_CENTROID_TASK_0:
	dbg(DBG_USR1, "Centroid: got location: (%f,%f,%f)\n", loc->x, loc->y, loc->z);
	if (loc == NULL) {
	  dbg(DBG_USR1, "Centroid: null location, can't proceed\n");
	  post centroid_task_6();
	} else {
	  memcpy(&myLocation, loc, sizeof(myLocation));
	  post centroid_task_1();
	}
	break;
      default:
	dbg(DBG_USR1, "Centroid: ERROR: Location.locationDone in unknown state %d\n", state);
	break;
    }
  }

  event result_t ADC.dataReady(uint16_t data) {
    dbg(DBG_USR1, "Centroid: ADC.dataReady, state %d\n", state);

    switch (state) {
      case STATE_CENTROID_TASK_1:
	Reading = data;
	post centroid_task_2();
	break;
      default:
	dbg(DBG_USR1, "Centroid: ERROR: ADC.dataReady in unknown state %d\n", state);
	break;
    }
    return SUCCESS;
  }

  event void SM.writeDone(void *buf, uint16_t moteaddr, uint16_t offset, uint16_t len, result_t success) {
    dbg(DBG_USR1, "Centroid: SM.writeDone, state %d\n", state);

    switch (state) {
      case STATE_CENTROID_TASK_2:
	if (--outstanding_write_count == 0) {
	  // XXX Note that failed write not noted here
	  post centroid_task_3();
	}
	break;

      case STATE_CENTROID_TASK_5:
	// XXX Note that failed write not noted here
	post centroid_task_6();
	break;

      default:
	dbg(DBG_USR1, "Centroid: ERROR: SM.writeDone in unknown state %d\n", state);
	break;
    }
  }

  event void SM.readDone(void *buf, uint16_t moteaddr, uint16_t offset, uint16_t len, result_t success) {
    int n;

    dbg(DBG_USR1, "Centroid: SM.readDone, state %d\n", state);

    // debugging
    for (n = 0; n < num_neighbors; n++) {
      if (buf == &(Reading_remote[n])) {
	dbg(DBG_USR1, "Centroid: SM read Reading[%d] value %d\n", n, Reading_remote[n]);
      } else if (buf == &(Location_remote[n])) {
	dbg(DBG_USR1, "Centroid: SM read Location[%d] value (%f,%f,%f)\n", n, Location_remote[n].x, Location_remote[n].y, Location_remote[n].z);
      }
    }

    switch (state) {

      case STATE_CENTROID_TASK_4:
	if (--outstanding_read_count == 0) {
	  // XXX Note that failed read not noted here
	  post centroid_task_5();
	}
	break;

      default:
	dbg(DBG_USR1, "Centroid: ERROR: getDone in unknown state %d\n", state);
	break;

    }
  }
  
  event result_t Timer.fired() {
    dbg(DBG_USR1, "Centroid: Timer fired, state %d\n", state);
    timer_ticks++;
    if (state == STATE_IDLE && (timer_ticks % TIMER_CENTROID_COUNT == 0)) {
      post centroid_task_0();
    }
    return SUCCESS;
  }

  event void Reduce.reduceDone(void *outbuf, result_t res) {
    dbg(DBG_USR1, "Centroid: Reduction done, result %d\n", res);
    post centroid_task_4();
  }

  event void Barrier.barrierDone() {
    dbg(DBG_USR1, "Centroid: Barrier done, entering STATE_IDLE\n");
    call Timer.stop();
    state = STATE_DONE;
  }

}


