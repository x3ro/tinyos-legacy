// $Id: ServiceScheduler.nc,v 1.6 2003/10/07 21:46:14 idgay Exp $

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
// $Id: ServiceScheduler.nc,v 1.6 2003/10/07 21:46:14 idgay Exp $


/** 
 * Interface to the scheduler module
 */

includes TosServiceSchedule;

interface ServiceScheduler {
    
    /** 
     * This command is used to (re)schedule a service.  ServiceScheduler
     * assumes the time syncronization and consequently uses an absolute timer
     * to express the schedule. 
     */
    
    command result_t reschedule(uint8_t svc_id,
				tos_service_schedule sched
				);

    /** 
     * This command allows an external component to get the schedule for an
     * individual component. 
     */

    command tos_service_schedule get(uint8_t svc_id);

    /** 
     * This command allows an external component to start all services.  This
     * is useful when it is desirable to disable the service coordinator and
     * leave it in a fully operational state.  
     *
     * @return SUCCESS if all coordinated services were started successfully,
     * FAIL if at least one of them failed. 
     */

    command result_t start_all();

    command result_t setNextEventTime(uint8_t svc_id, tos_time_t nextTime);


    command tos_time_t getNextEventTime(uint8_t svc_id);


    command result_t setExtraSleepTime(uint8_t svc_id, int32_t extraTime);


    command result_t remove(uint8_t svc_id);
}
