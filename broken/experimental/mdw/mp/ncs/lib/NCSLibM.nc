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
includes NCS;
includes SharedVar;

/** 
 * NCSLib is a set of "blocking" wrappers to various useful library 
 * routines.
 */

module NCSLibM {

  provides {
    interface StdControl;
    interface NCSLib;
    interface NCSSensor[uint8_t type];
    interface NCSSharedVar[uint8_t id];
    interface NCSNeighborhood as NCSRadioNeighborhood;
    interface NCSNeighborhood as NCSYaoNeighborhood;
    interface NCSNeighborhood as NCSGeoNeighborhood;
    interface NCSLocation;
  }
  uses {
    interface Timer[uint8_t id];
    interface Fiber;
    interface Leds;
    interface ADC as PhotoADC;
    interface Location;
    interface SharedVar[uint8_t id];
    interface Neighborhood as RadioNeighborhood;
    interface Neighborhood as YaoNeighborhood;
    interface Neighborhood as GeoNeighborhood;
  }

} implementation {

  // XXX This is ugly - hope we don't collide with other users of
  // the interface. Can't wire to anything above NUM_TIMERS in Timer.h
  enum {
    TIMER_KEY_BASE = 10,
  };

  fiber_t *sleep_queue;
  fiber_t *adc_queue[NCS_MAX_SENSORS];
  uint16_t adc_return_data[NCS_MAX_SENSORS];
  fiber_t *location_queue;
  fiber_t *radio_neighborhood_queue, *yao_neighborhood_queue, 
    *geo_neighborhood_queue;

  struct _ncslib_state_t {
    location_3d_t *location_return_data;
    bool timeout_occurred;
  } ncslib_state[MAX_FIBERS];

  struct _sv_state_t {
    fiber_t *queue;
    int pending_get;
  } sv_state[SHAREDVAR_MAX_KEY];

  command result_t StdControl.init() {
    int i;
    for (i = 0; i < SHAREDVAR_MAX_KEY; i++) {
      sv_state[i].pending_get = 0;
      sv_state[i].queue = NULL;
    }
    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  bool sleep_on(fiber_t **queue, int timeout) {
    fiber_t *cf; 
    cf = call Fiber.curfiber();
    if (cf == NULL) return FALSE;
    if (timeout > 0) {
      ncslib_state[cf->fiber_num].timeout_occurred = FALSE;
      dbg(DBG_USR2, "NCSLib: sleep_on setting timeout for %d\n", timeout);
      call Timer.start[cf->fiber_num+TIMER_KEY_BASE](TIMER_ONE_SHOT, timeout);
    }
    call Fiber.sleep(queue);
    return TRUE;
  }

  event result_t Timer.fired[uint8_t id]() {
    fiber_t *fiber;
    dbg(DBG_USR2, "NCSLib: Timer.fired called, id %d\n", id);
    if (id < TIMER_KEY_BASE) return SUCCESS;
    fiber = call Fiber.getfiber(id-TIMER_KEY_BASE);
    dbg(DBG_USR2, "NCSLib: Timer.fired cur_fiber 0x%lx\n", fiber);
    // XXX Assume nobody is using something above this range
    if (fiber == NULL) {
      dbg(DBG_USR2, "NCSLib: Timer.fired: Bad ID %d\n", id);
      return SUCCESS;
    }
    dbg(DBG_USR2, "NCSLib: fiber num %d\n", fiber->fiber_num);
    ncslib_state[fiber->fiber_num].timeout_occurred = TRUE;
    call Fiber.wakeup_one(fiber->queue, fiber);
    return SUCCESS;
  }

  command void NCSLib.sleep(uint16_t sleep_ms) {
    dbg(DBG_USR2, "NCSLib.sleep called: %d ms\n", sleep_ms);
    sleep_on(&sleep_queue, sleep_ms);
  }

  command uint16_t NCSSensor.getData[uint8_t type]() {
    dbg(DBG_USR2, "NCSSensor.getData called, type %d\n", type);
    switch (type) {
      case NCS_SENSOR_PHOTO:
	if (!call PhotoADC.getData()) {
	  dbg(DBG_USR2, "NCSSensor.getData: PhotoADC.getData() failed\n");
	  return -1;
	}
	break;
      default:
      	dbg(DBG_USR2, "NCSLib.getPhoto: getData() failed\n");
	return -1;
	break;
    }
    call Fiber.sleep(&adc_queue[type]);
    return adc_return_data[type];
  }

  event result_t PhotoADC.dataReady(uint16_t data) {
    adc_return_data[NCS_SENSOR_PHOTO] = data;
    call Leds.yellowToggle();
    call Fiber.wakeup(&adc_queue[NCS_SENSOR_PHOTO]);
    return SUCCESS;
  }

  command location_3d_t *NCSLocation.getLocation(int timeout) {
    fiber_t *cf = call Fiber.curfiber();
    if (cf == NULL) return FALSE;
    ncslib_state[cf->fiber_num].location_return_data = NULL;
    if (!call Location.getLocation()) return NULL;
    if (!sleep_on(&location_queue, timeout)) return NULL;
    return ncslib_state[cf->fiber_num].location_return_data;
  }

  event void Location.locationDone(location_3d_t *loc) {
    fiber_t *f = call Fiber.wakeup(&location_queue);
    if (f == NULL) {
      dbg(DBG_USR2,"NCSLib: Location.locationDone: no fiber on location_queue\n");
      return;
    }
    ncslib_state[f->fiber_num].location_return_data = loc;
  }

  // If timeout is 0, return immediately, else sleep
  command result_t NCSSharedVar.get[uint8_t key](uint16_t moteaddr, 
      void *buf, int buflen, int timeout) {
    fiber_t *cf = call Fiber.curfiber();
    if (cf == NULL) return FAIL;
    if (!call SharedVar.get[key](moteaddr, buf, buflen)) {
      return FAIL;
    }
    sv_state[key].pending_get++;
    if (timeout > 0) {
      if (!sleep_on(&sv_state[key].queue, timeout)) {
	sv_state[key].pending_get--;
	return FAIL;
      }
    }
    return SUCCESS;
  }

  command result_t NCSSharedVar.sync[uint8_t key](int timeout) {
    fiber_t *cf = call Fiber.curfiber();
    if (sv_state[key].pending_get > 0) {
      if (timeout > 0) {
	if (!sleep_on(&sv_state[key].queue, timeout)) {
	  return FAIL;
	}
	if (ncslib_state[cf->fiber_num].timeout_occurred && 
	  sv_state[key].pending_get > 0) { 
	  return FAIL;
	}
      }
    }
    if (sv_state[key].pending_get > 0) {
      return FAIL;
    } else {
      return SUCCESS;
    }
  }

  event void SharedVar.getDone[uint8_t key](uint16_t moteaddr, 
      void *buf, int buflen, result_t success) {
    if (--sv_state[key].pending_get == 0) {
      fiber_t *f = call Fiber.wakeup(&sv_state[key].queue);
      if (f == NULL) {
	dbg(DBG_USR2,"NCSLib: Sharedvar.getDone: no fiber on sv_state[%d].queue\n", key);
	return;
      } 
    }
  }

  command void NCSSharedVar.set[uint8_t type](void *buf, int buflen) {
    call SharedVar.put[type](buf, buflen);
  }

  command int NCSRadioNeighborhood.getNeighbors(uint16_t *neighbors, int max_neighbors, int timeout) {
    if (!call RadioNeighborhood.getNeighborhood()) return 0;
    if (!sleep_on(&radio_neighborhood_queue, timeout)) return 0;
    return call RadioNeighborhood.getNeighbors(neighbors, max_neighbors);
  }

  event void RadioNeighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR2, "NCSLibM: RadioNeighborhood done - waking up\n");
    call Fiber.wakeup(&radio_neighborhood_queue);
  }

  command int NCSYaoNeighborhood.getNeighbors(uint16_t *neighbors, int max_neighbors, int timeout) {
    dbg(DBG_USR2, "NCSLibM: Calling YaoNeighborhood.getNeighborhood\n");
    if (!call YaoNeighborhood.getNeighborhood()) return 0;
    dbg(DBG_USR2, "NCSLibM: Sleeping on 0x%lx for %d ms\n", &yao_neighborhood_queue, timeout);
    if (!sleep_on(&yao_neighborhood_queue, timeout)) return 0;
    dbg(DBG_USR2, "NCSLibM: Returned from YaoNeighborhood sleep\n");
    return call YaoNeighborhood.getNeighbors(neighbors, max_neighbors);
  }

  event void YaoNeighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR2, "NCSLibM: YaoNeighborhood done - waking up\n");
    call Fiber.wakeup(&yao_neighborhood_queue);
  }

  command int NCSGeoNeighborhood.getNeighbors(uint16_t *neighbors, int max_neighbors, int timeout) {
    dbg(DBG_USR2, "NCSLibM: Calling GeoNeighborhood.getNeighborhood\n");
    if (!call GeoNeighborhood.getNeighborhood()) return 0;
    dbg(DBG_USR2, "NCSLibM: Sleeping on 0x%lx for %d ms\n", &geo_neighborhood_queue, timeout);
    if (!sleep_on(&geo_neighborhood_queue, timeout)) return 0;
    dbg(DBG_USR2, "NCSLibM: Returned from GeoNeighborhood sleep\n");
    return call GeoNeighborhood.getNeighbors(neighbors, max_neighbors);
  }

  event void GeoNeighborhood.getNeighborhoodDone(result_t success) {
    dbg(DBG_USR2, "NCSLibM: GeoNeighborhood done - waking up\n");
    call Fiber.wakeup(&geo_neighborhood_queue);
  }


}

