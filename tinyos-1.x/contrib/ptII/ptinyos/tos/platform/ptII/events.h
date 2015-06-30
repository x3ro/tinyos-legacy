// $Id: events.h,v 1.1 2005/04/19 01:16:13 celaine Exp $

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
/*
 *
 * Authors:             Philip Levis, Nelson Lee
 *
 */

/*
 *   FILE: events.h
 * AUTHOR: pal
 *   DESC: Declaration of hardware clock events. They are defined in the
 *         component files pertaining to the part (e.g. CLOCK.c). Otherwise,
 *         linkage errors occur.
 */

/**
 * @author Philip Levis
 * @author Nelson Lee
 * @author pal
 */


#ifndef EVENTS_H_INCLUDED
#define EVENTS_H_INCLUDED

typedef struct {
  int interval;
  int mote;
  int valid;
  int disabled;
} clock_tick_data_t;

typedef struct {
  int valid;
  char port;
} adc_tick_data_t;

typedef struct {
  int interval;
  int mote;
  int valid;
} radio_tick_data_t;

typedef struct {
  int interval;
  int mote;
  int valid;
} channel_mon_data_t;

typedef struct {
  int interval;
  int mote;
  int valid;
  int count; //ranges from 0 to 7
  int ending;
} spi_byte_data_t;

typedef struct {
  int interval;
  int mote;
  int valid;  
} radio_timing_data_t;

  



void event_default_cleanup(event_t* event);

void event_total_cleanup(event_t* event);

void event_clocktick_create(event_t* event,
				   int mote,
				   long long eventTime,
				   int interval);

void event_clocktick_handle(event_t* event,
				   struct TOS_state* state);

void event_clocktick_invalidate(event_t* event);


void event_radiotick_create(event_t* event,
				   int mote,
				   long long eventTime,
				   int interval);

void event_radiotick_handle(event_t* event,
				   struct TOS_state* state);

void event_radiotick_invalidate(event_t* event);

void event_adc_update(event_t* event, int mote, uint8_t port, long long eventTime, int interval);

void event_adc_create(event_t* event, int mote, uint8_t port, long long eventTime, int interval);

void event_channel_mon_handle(event_t* event, struct TOS_state* state);

void event_channel_mon_create(event_t* event, int mote, long long ftime, int interval);

void event_channel_mon_invalidate(event_t* event);

void event_spi_byte_handle(event_t* event, struct TOS_state* state);

void event_spi_byte_create(event_t* event, int mote, long long ftime, int interval, int count);

void event_spi_byte_invalidate(event_t* event);

void event_spi_byte_end(event_t* fevent);

void event_radio_timing_handle(event_t* fevent, struct TOS_state* state);

void event_radio_timing_create(event_t* fevent, int mote, long long ftime, int interval);

void event_radio_timing_invalidate(event_t* fevent);

void event_cleanup(event_t *fevent);

#endif // EVENTS_H_INCLUDED
