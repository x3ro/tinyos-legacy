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

includes Fiber;
includes Location;

/**
 * Blocking (NCSLib) version of contour finding.
 * Compare to apps/contour/ContourM.nc in terms of complexity and length.
 */
module ContourM {
  provides interface StdControl;
  uses interface Fiber;
  uses interface NCSLib;
  uses interface NCSSensor;
  uses interface NCSNeighborhood;
  uses interface NCSLocation;
  uses interface NCSSharedVar as SV_location;
  uses interface NCSSharedVar as SV_belowset;
  uses interface Leds;
} implementation {

  enum {
    SLEEP_TIME = 1000,
    TIMEOUT = 5000,
    MAX_NEIGHBORS = 8,                 // Max # neighbors to consider
    THRESHOLD = 50,                    // Sensor threshold
  };

  uint16_t neighbors[MAX_NEIGHBORS];
  bool belowset_remote[MAX_NEIGHBORS];
  location_3d_t Location_remote[MAX_NEIGHBORS];
  location_3d_t contourpoints[MAX_NEIGHBORS];

  static location_3d_t midpoint(location_3d_t a, location_3d_t b) {
    location_3d_t mid;
    mid.x = (a.x + b.x) / 2.0;
    mid.y = (a.y + b.y) / 2.0;
    mid.z = (a.z + b.z) / 2.0;
    return mid;
  }

  void fiber_run(void *arg) {
    int n, num_cpoints;
    uint16_t adc_data;
    location_3d_t *my_location;
    bool aboveset = FALSE;
    bool belowset = FALSE;
    int num_neighbors;
    bool found = FALSE;

    while (1) {
      dbg(DBG_USR1, "ContourM: Top of loop\n");
      call NCSLib.sleep(SLEEP_TIME);

      for (n = 0; n < MAX_NEIGHBORS; n++) belowset_remote[n] = 0;
      adc_data = call NCSSensor.getData();
      dbg(DBG_USR1, "ContourM: Got sensor data: %d\n", adc_data);

      if ((my_location = call NCSLocation.getLocation(TIMEOUT)) == NULL) {
	continue;
      }
      call SV_location.set(my_location, sizeof(*my_location));
      dbg(DBG_USR1, "ContourM: Set my location\n");

      if (adc_data < THRESHOLD) {
	// Below threshold
        dbg(DBG_USR1, "ContourM: Below threshold\n");
	belowset = TRUE;
      } else {
        dbg(DBG_USR1, "ContourM: Above threshold\n");
	belowset = FALSE;
      }
      call SV_belowset.set(&belowset, sizeof(belowset));

      // Do this regardless - if you don't request a neighborhood you don't 
      // end up advertising (whoops!)
      dbg(DBG_USR1, "ContourM: Above threshold\n");
      num_neighbors = call NCSNeighborhood.getNeighbors(neighbors, 
	  MAX_NEIGHBORS, TIMEOUT);
      dbg(DBG_USR1, "ContourM: Got neighbors: %d\n", num_neighbors);
      if (num_neighbors < 1) {
	continue;
      }

      if (adc_data >= THRESHOLD) {
    	// Get belowset from neighbors
     	for (n = 0; n < num_neighbors; n++) {
  	  call SV_belowset.get(neighbors[n], &(belowset_remote[n]), 
  	      sizeof(belowset_remote[n]), 0);
   	}
        dbg(DBG_USR1, "ContourM: Started belowset fetch\n");
    	if (!call SV_belowset.sync(TIMEOUT)) {
          dbg(DBG_USR1, "ContourM: Belowset sync timeout\n");
	  continue;
	}
        dbg(DBG_USR1, "ContourM: Got belowset\n");

     	// Get location from neighbors in belowset
      	for (n = 0; n < num_neighbors; n++) {
  	  if (belowset_remote[n]) {
  	    found = TRUE;
  	    call SV_location.get(neighbors[n], &(Location_remote[n]),
  		sizeof(Location_remote[n]), 0);
  	  }
   	}

     	// Calculate contour points
    	if (!found) {
          dbg(DBG_USR1, "ContourM: No neighbors with belowset set\n");
	  return;
	}
        dbg(DBG_USR1, "ContourM: Started location fetch\n");
      	if (!call SV_location.sync(TIMEOUT)) {
          dbg(DBG_USR1, "ContourM: Location sync timeout\n");
	  continue;
	}
       	for (n = 0; n < num_neighbors; n++) {
  	  if (belowset_remote[n]) {
  	    num_cpoints++;
  	    contourpoints[n] = midpoint(*my_location, Location_remote[n]);
  	    dbg(DBG_USR1, "CONTOUR POINT: %f %f %f\n", contourpoints[n].x, contourpoints[n].y, contourpoints[n].z);
  	  }
   	}
      }
      dbg(DBG_USR1, "ContourM: Done with loop\n");
    }
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1, "Creating main fiber\n");
    call Fiber.start(fiber_run, NULL);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }



}
