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

/**
 * GeoNeighborhoodM: Pick all one-hop radio neighbors within a given radius 
 * of the node.
 */
module GeoNeighborhoodM {
  provides {
    interface StdControl;
    interface Neighborhood;
    interface GeoNeighborhoodControl;
  }
  uses {
    interface SharedVar as SV_location;
    interface Neighborhood as RadioNeighborhood;
    interface Location;
    interface Timer;
  }

} implementation {

  bool nbr_requested, rn_ready, dist_ready;
  location_3d_t *myLocation;
  int outstanding_reads;
  double maxdist;

  enum { 
    MAX_NEIGHBORS = 16,
    EMPTY_ADDR = 0xffff,
    INIT_MAXDIST = 20,
    GET_LOCATION_TIMEOUT = 10000,
  }; 

  struct neighbor {
    uint16_t addr;
    location_3d_t loc;
    float dist;
  } neighbors[MAX_NEIGHBORS];

  // Note: This needs to be smaller than SHAREDVAR_BUFLEN
  uint16_t exported_neighbors[MAX_NEIGHBORS];

  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void init_neighbor(struct neighbor *neighbor) {
    neighbor->addr = EMPTY_ADDR;
    neighbor->dist = -1.0;
    neighbor->loc.x = -1.0;
    neighbor->loc.y = -1.0;
  }

  static void initialize() {
    int n;
    dbg(DBG_USR1, "GeoNeighborhoodM: initialize\n");

    maxdist = INIT_MAXDIST;
    nbr_requested = FALSE;
    rn_ready = FALSE;
    dist_ready = FALSE;
    myLocation = NULL;

    for (n = 0; n < MAX_NEIGHBORS; n++) {
      init_neighbor(&neighbors[n]);
      exported_neighbors[MAX_NEIGHBORS] = EMPTY_ADDR;
    }
  }

  /***********************************************************************
   * StdControl
   ***********************************************************************/

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (!call Location.getLocation()) {
      dbg(DBG_USR1, "GeoNeighborhoodM: Can't call Location.getLocation\n");
    } 
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  } 

  /***********************************************************************
   * GeoNeighborhoodControl
   ***********************************************************************/

  command void GeoNeighborhoodControl.setMaxDist(double md) {
    maxdist = md;
  }

  command double GeoNeighborhoodControl.getMaxDist() {
    return maxdist;
  }

  /***********************************************************************
   * Internal functions
   ***********************************************************************/

  static void add_neighbor(uint16_t addr) {
    int n;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == addr) {
	return;
      }
    }
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr == EMPTY_ADDR)  {
	neighbors[n].addr = addr;
	break;
      }
    }
  }

  task void getLocationTask() {
    int num_rn, n;
    uint16_t tmp_neighbors[MAX_NEIGHBORS];
    if (!rn_ready || myLocation == NULL) return;

    num_rn = call RadioNeighborhood.getNeighbors(tmp_neighbors, MAX_NEIGHBORS);
    if (num_rn == 0) return;
    for (n = 0; n < num_rn; n++) {
      add_neighbor(tmp_neighbors[n]);
    }
    for (n = 0; n < num_rn; n++) {
      outstanding_reads++;
      if (!call SV_location.get(neighbors[n].addr, &neighbors[n].loc, sizeof(neighbors[n].loc))) {
	dbg(DBG_USR2, "GeoNeighborhoodM: Unable to call SV_loc.get for neighbor %d\n", n);
	outstanding_reads--;
      }
    }
    dbg(DBG_USR2, "GeoNeighborhoodM: getLocationTask(): outstanding reads %d\n", outstanding_reads);
    if (outstanding_reads == 0) {
      rn_ready = FALSE;
      signal Neighborhood.getNeighborhoodDone(FAIL);
    } else {
      if (!call Timer.start(TIMER_ONE_SHOT, GET_LOCATION_TIMEOUT)) {
	dbg(DBG_USR2, "GeoNeighborhoodM: Can't start timer\n");
	rn_ready = FALSE;
	signal Neighborhood.getNeighborhoodDone(FAIL);
      }
    }
  }

  double calc_dist(location_3d_t *loc) {
    double dist;
    dist = (loc->x - myLocation->x) * (loc->x - myLocation->x);
    dist += (loc->y - myLocation->y) * (loc->y - myLocation->y);
    return sqrt(dist);
  }

  task void calcDistTask() {
    int n;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR && neighbors[n].loc.x > 0.0) {
	neighbors[n].dist = calc_dist(&neighbors[n].loc);
	dbg(DBG_USR2, "GeoNeighborhoodM: neighbors[%d] addr %d dist %f maxdist %f\n",
	    n, neighbors[n].addr, neighbors[n].dist, maxdist);
	if (neighbors[n].dist > maxdist) neighbors[n].addr = EMPTY_ADDR;
      }
    }
    dist_ready = TRUE;
    signal Neighborhood.getNeighborhoodDone(SUCCESS);
  }

  /***********************************************************************
   * Neighborhood
   ***********************************************************************/

  command result_t Neighborhood.getNeighborhood() {
    nbr_requested = TRUE;
    return call RadioNeighborhood.getNeighborhood();
  }

  command int Neighborhood.numNeighbors() {
    int n, count = 0;
    if (!dist_ready) return 0;
    for (n = 0; n < MAX_NEIGHBORS; n++) {
      if (neighbors[n].addr != EMPTY_ADDR) count++;
    }
    dbg(DBG_USR2, "GeoNeighborhoodM: numNeighbors %d\n", count);
    return count;
  }

  command int Neighborhood.getNeighbors(uint16_t *buf, int size) {
    int n, count = 0;
    if (!dist_ready) return 0;
    for (n = 0; n < size && n < MAX_NEIGHBORS; n++) {
      dbg(DBG_USR2, "YaoNeighborhoodM: getNeighbors: n[%d] addr %d\n", n, neighbors[n].addr);
      if (neighbors[n].addr != EMPTY_ADDR && neighbors[n].dist > 0.0) {
	buf[count] = neighbors[n].addr;
	count++;
      }
    }
    dbg(DBG_USR2, "GeoNeighborhoodM: getNeighbors returning %d\n", count);
    return count;
  }


  /***********************************************************************
   * RadioNeighborhood
   ***********************************************************************/

  event void RadioNeighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR2, "GeoNeighborhoodM: RN.getNeighborhoodDone\n");
    if (success == SUCCESS && nbr_requested) {
      dbg(DBG_USR2, "GeoNeighborhoodM: posting getLocationTask\n");
      rn_ready = TRUE;
      post getLocationTask();
    } else if (nbr_requested) {
      // Try to get radio neighborhood again
      dbg(DBG_USR2, "GeoNeighborhoodM: Retrying getNeighborhood\n");
      if (!call RadioNeighborhood.getNeighborhood()) {
	dbg(DBG_USR2, "GeoNeighborhoodM: Can't call getNeighborhood\n");
	signal Neighborhood.getNeighborhoodDone(FAIL);
      }
    }
  }

  /***********************************************************************
   * Location
   ***********************************************************************/

  event void Location.locationDone(location_3d_t *loc) {
    dbg(DBG_USR2, "GeoNeighborhoodM: locationDone\n");
    if (loc != NULL) {
      myLocation = loc;

      dbg(DBG_USR2, "GeoNeighborhoodM: myLocation (%f,%f)\n", myLocation->x, myLocation->y);

      if (nbr_requested) post getLocationTask();
      if (!call SV_location.put(myLocation, sizeof(*myLocation))) {
	dbg(DBG_USR2, "GeoNeighborhoodM: Can't put SV_location\n");
      }
    } else {
      // Try to get location again
      dbg(DBG_USR2, "GeoNeighborhoodM: Retrying getLocation\n");
      if (!call Location.getLocation()) {
       	dbg(DBG_USR1, "GeoNeighborhoodM: Can't call getLocation\n");
      } 
    }
  }

  /***********************************************************************
   * Timer
   ***********************************************************************/
  event result_t Timer.fired() {
    dbg(DBG_USR2, "GeoNeighborhoodM: Timer fired, posting calcDistTask\n");
    post calcDistTask();
    return SUCCESS;
  }


  /***********************************************************************
   * SharedVar
   ***********************************************************************/

  event void SV_location.getDone(uint16_t moteaddr, void *buf, int buflen, result_t success) {
    outstanding_reads--;
    dbg(DBG_USR2, "GeoNeighborhoodM: getLocationTask(): outstanding reads now %d\n", outstanding_reads);
    if (outstanding_reads == 0) post calcDistTask();
  }


}
