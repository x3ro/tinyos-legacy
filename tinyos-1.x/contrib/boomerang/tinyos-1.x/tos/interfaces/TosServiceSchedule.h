// $Id: TosServiceSchedule.h,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $

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

/* Author:  Robert Szewczyk
 *
 * $Id: TosServiceSchedule.h,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $
 */

/**
 * @author Robert Szewczyk
 */


#ifndef _TOSSERVICESCHEDULE_H
#define _TOSSERVICESCHEDULE_H 1

#include "TosTime.h"

/**
 * tos_service_schedule describes the schedule of the service.  The service is
 * to be started at start_time, and run for on_time seconds.  If the off_time
 * is a non-negative number, the service is ran again after off_seconds
 * from the stop condition, otherwise it is treated as an one-time service.
 * Flags field is used for scheduling and coordination hints: they indicate
 * the state of the service at any point in time, as well as scheduling
 * policies for the particular service.  To that effect, the lower nibble of
 * the flags field is reserved for the scheduling policy and the upper nibble
 * is used to indicate the runtime state of the service. 
 */
typedef struct {
    tos_time_t start_time;
    int32_t on_time;
    int32_t off_time;
    uint8_t flags;
} tos_service_schedule;

enum {
    DISABLED = 0x00,
    ENABLED = 0x40,
    STOP = 0x10,
    START = 0x20
    
};

#endif /* _TOSSERVICESCHEDULE_H */

