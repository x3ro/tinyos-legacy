/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: events.h
 * AUTHOR: pal
 *   DESC: Declaration of hardware clock events. They are defined in the
 *         component files pertaining to the part (e.g. CLOCK.c). Otherwise,
 *         linkage errors occur.
 */

#ifndef EVENTS_H_INCLUDED
#define EVENTS_H_INCLUDED

#include "event_queue.h"
#include "tossim.h"

typedef struct {
  int interval;
  int mote;
  int valid;
} clock_tick_data_t;

typedef struct {
  int interval;
  int mote;
  int valid;
} radio_tick_data_t;

typedef struct {
  int interval;
  int source;
  int bit;
} radio_done_data_t;

extern void event_default_cleanup(event_t* event);
extern void event_total_cleanup(event_t* event);

extern void event_clocktick_create(event_t* event,
				   int mote,
				   long long  time,
				   int interval);

extern void event_clocktick_handle(event_t* event,
				   struct TOS_state* state);

extern void event_clocktick_invalidate(event_t* event);

extern void event_radiotick_create(event_t* event,
				   int mote,
				   long long time,
				   int interval);

extern void event_radiotick_handle(event_t* event,
				   struct TOS_state* state);

extern void event_radiotick_invalidate(event_t* event);


extern void event_radiodone_create(event_t* event,
				   int source,
				   long long  time,
				   int length,
				   int bit);

extern void event_radiodone_handle(event_t* event,
				   struct TOS_state* state);

#endif // EVENTS_H_INCLUDED
