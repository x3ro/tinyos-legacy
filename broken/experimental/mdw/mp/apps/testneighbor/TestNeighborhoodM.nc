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
 * Test program for neighborhood construction.
 */
module TestNeighborhoodM {
  provides {
    interface StdControl;
  }
  uses {
    interface Neighborhood;
  }
}
implementation {

  enum {
    MAX_NEIGHBORS = 16,	               // Max # neighbors to consider
  };

  int num_neighbors;
  uint16_t neighbors[MAX_NEIGHBORS];

  /*********************************************************************** 
   * Initialization 
   ***********************************************************************/

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call Neighborhood.getNeighborhood();
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void got_neighbors_task() {
    int n;
    num_neighbors = call Neighborhood.getNeighbors(neighbors, MAX_NEIGHBORS);
    dbg(DBG_USR1, "TestNeighborhoodM: Got %d neighbors\n", num_neighbors);
    for (n = 0; n < num_neighbors; n++) {
      dbg(DBG_USR1, "TestNeighborhoodM: neighbors[%d] is %d\n", n, neighbors[n]);
    }
  }

  event void Neighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR1, "TestNeighborhoodM: getNeighborhoodDone\n");
    if (success) {
      post got_neighbors_task();
    } else {
      dbg(DBG_USR1, "TestNeighborhoodM: neighborhood failed\n");
    }
  }

}


