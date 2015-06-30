// $Id: ServiceSchedulerM.nc,v 1.1.1.1 2007/11/05 19:10:43 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


// Authors: Robert Szewczyk
// $Id: ServiceSchedulerM.nc,v 1.1.1.1 2007/11/05 19:10:43 jpolastre Exp $

includes pqueue;
includes TosServiceSchedule;
#ifndef MAX_NUM_SERVICES
#define MAX_NUM_SERVICES	10
#endif

module ServiceSchedulerM {
    provides interface ServiceScheduler;
    provides interface StdControl as SchedulerClt;
    
    uses {
	interface StdControl as Services[uint8_t id];
	interface AbsoluteTimer;
	interface TimeUtil;
	interface Time;
    }
    
}

implementation {
    
    enum {
	MAX_SERVICES = MAX_NUM_SERVICES
    };

    struct {
	char (*compare) (pq_element e1, pq_element e2);
	uint8_t size;
	uint8_t n_elements;
	pq_element heap[10];
    } event_q;

    int32_t extraSleep;

    /*    struct {
	uint8_t state;
	uint16_t on_time;
	uint16_t off_time;
	tos_time_t time;
	} */

    tos_service_schedule sched_info[MAX_SERVICES];

    char compare_elts(pq_element i, pq_element j) {
	return call TimeUtil.compare(sched_info[i].start_time,
				     sched_info[j].start_time);
    }

    /**
     *
     */

    event result_t AbsoluteTimer.fired() {
	uint32_t increment;
	pq_element svcidx = pqueue_dequeue((pqueue_t *) &event_q);
	tos_time_t now;
       

	if (svcidx < 0) // should never happen.
	    return FAIL;

	now = sched_info[svcidx].start_time;

	if (sched_info[svcidx].flags & START) {
	    call Services.start[svcidx](); // start the service
	    // schedule the stop event: update the flags, the time of next
	    // event, and go. 
	    sched_info[svcidx].flags ^= (START | STOP);
	    increment = sched_info[svcidx].on_time; //on time is in milliseconds
	    sched_info[svcidx].start_time = 
		call TimeUtil.addUint32(sched_info[svcidx].start_time, increment);
	    pqueue_enqueue((pqueue_t *)&event_q, svcidx);
	} else if (sched_info[svcidx].flags & STOP) {
	    call Services.stop[svcidx](); // stop the service
	    // schedule the stop event: update the flags, the time of next
	    // event, and go. 
	    sched_info[svcidx].flags ^= (START | STOP);
	    if (sched_info[svcidx].off_time > 0) {
		increment = sched_info[svcidx].off_time + extraSleep; //on time is in milli seconds
		extraSleep = 0;
		sched_info[svcidx].start_time = 
		    call TimeUtil.addUint32(sched_info[svcidx].start_time, increment);
		pqueue_enqueue((pqueue_t *)&event_q, svcidx);
	    }
	}
	svcidx = pqueue_peek((pqueue_t *)&event_q);
	if (svcidx < 0) 
	    return SUCCESS;

	//check and see if the first event fires at the currnet time;
	// if so, go ahead and fire it
	if (call TimeUtil.compare(sched_info[svcidx].start_time,now) == 0) {
	   return signal AbsoluteTimer.fired();
	}	
	else {
	  return call AbsoluteTimer.set(sched_info[svcidx].start_time);
	}
    }

    default command  result_t Services.init[uint8_t id]() {
	return SUCCESS;
    }

    default command result_t Services.start[uint8_t id]() {
	return SUCCESS;
    }
    
    default command  result_t Services.stop[uint8_t id]() {
	return SUCCESS;
    }

    /** 
     * Initialize the service scheduler.  It boils down to initializing the
     * scheduling queue and the service scheduling info.  All services are
     * initialized in the DISABLED state. 
     */

    command result_t SchedulerClt.init() {
	int i;
	pqueue_init((pqueue_t *) &event_q, MAX_SERVICES, compare_elts);
	// initialize the state of the service schedule.  The real question is
	// of course where does the initial schedule come from 
	for (i = 0; i < MAX_SERVICES; i++) {
	    sched_info[i].flags = DISABLED;
	}
	return SUCCESS;
    }
    
    /** 
     * Start the service scheduler. Note that this is not at all synonymous
     * with starting the subordinate services. Instead, if there are runnable
     * serivces ready to be scheduled, this will fire off the timer. 
     */

    command result_t SchedulerClt.start() {
	int8_t svc_id;
	if ((svc_id = pqueue_peek((pqueue_t *)&event_q)) < 0)
	    return SUCCESS;  // nothing to do; we are successful
	return call AbsoluteTimer.set(sched_info[svc_id].start_time);
    }

    /**
     * Stop the service scheduler: leave the services in their current state
     * and just stop the timer.
     */

    command result_t SchedulerClt.stop() {
	int8_t svc_id;
	if ((svc_id = pqueue_peek((pqueue_t *)&event_q)) < 0)
	    return SUCCESS;  // nothing to do; we are successful
	return call AbsoluteTimer.cancel();
    }
 
    command result_t ServiceScheduler.reschedule(uint8_t svc_id,
						 tos_service_schedule sched
						 ) {
	// tos_time_t now = call Time.get();
	//uint32_t interval;
	
	// roll the clock forward, assume that the schedule is relatively
	// fresh. 
	//interval = (sched.off_time + sched.on_time) << 10;
	
	//while (call TimeUtil.compare(now, sched.start_time) > 0){
	//    sched.start_time = 
	//		call TimeUtil.addUint32(sched.start_time, interval);
	//}
	// the new schedule immediately overrides the previous schedule.  We
	// remove it from the queue, and stop it if appropriate
	pqueue_remove((pqueue_t *)&event_q, svc_id);

	if (sched_info[svc_id].flags & STOP) { // the service is running
	    call Services.stop[svc_id]();
	}
	sched_info[svc_id] = sched;
	// The next event for this service is start
	sched_info[svc_id].flags = ENABLED | START;

	if (pqueue_enqueue((pqueue_t *)&event_q, svc_id) == FAIL)
	    return FAIL;
	if (pqueue_peek((pqueue_t *)&event_q) == svc_id) {
	    call AbsoluteTimer.cancel();
	    return call AbsoluteTimer.set(sched.start_time);
	}
	return SUCCESS;
    }

    command result_t ServiceScheduler.setNextEventTime(uint8_t svc_id, tos_time_t nextTime) {
	if (pqueue_peek((pqueue_t *)&event_q) == svc_id) {
	  call AbsoluteTimer.cancel();
	  sched_info[svc_id].start_time = nextTime;
	  call AbsoluteTimer.set(nextTime);
	}
	return SUCCESS;
    }

    command tos_time_t ServiceScheduler.getNextEventTime(uint8_t svc_id) {
      return sched_info[svc_id].start_time;

    }


    command result_t ServiceScheduler.setExtraSleepTime(uint8_t svc_id, int32_t extraTime) {
      if (extraTime >0 || (extraTime * -1) <  sched_info[svc_id].off_time)
	extraSleep = extraTime;
      if (extraTime < 0 && abs(extraTime) > sched_info[svc_id].off_time)
	extraSleep = -1* (sched_info[svc_id].off_time - 1);
      return SUCCESS;
    }

    command tos_service_schedule ServiceScheduler.get(uint8_t svc_id) {
	tos_service_schedule ret;
	if ((svc_id < MAX_SERVICES)) 
	    return sched_info[svc_id];
	else {
	    ret.flags = DISABLED;
	    return ret;
	}
    }

    command result_t ServiceScheduler.start_all() {
	result_t accumulate = SUCCESS;
	uint8_t i;
	for (i=0; i < MAX_SERVICES; i++) {
	    if (sched_info[i].flags & ENABLED) {
		accumulate = rcombine(call Services.start[i](), accumulate);
	    }
	}
	return accumulate;
    }

    command result_t ServiceScheduler.remove(uint8_t svc_id) {
	result_t res = pqueue_remove((pqueue_t *)&event_q, svc_id);
	call Services.stop[svc_id]();
	sched_info[svc_id].flags = DISABLED;
	return res;
    }
}
