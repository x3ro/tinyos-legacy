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
 *   FILE: tossim.h
 * AUTHOR: pal
 *   DESC: Core simulation data.
 *
 *   This file declares the core structures used by TOSSIM, including
 *   the global simulation state (time, etc.) and individual node state.
 *
 *   This file also defines a few macros for simulation state abstraction.
 *
 */

#ifndef TOSSIM_H_INCLUDED
#define TOSSIM_H_INCLUDED

#ifndef TOSNODES
#define TOSNODES 1000    // Defines the maximum number of motes in the sim
#endif

#define DEFAULT_EEPROM_SIZE (512 * 1024)  // 512 KB

#include "event_queue.h"
#include "events.h"
#include "rfm_model.h"
#include "adc_model.h"
#include "spatial_model.h"

typedef struct TOS_node_state{
  long long time; // Time at which mote booted
  int pot_setting;
} TOS_node_state_t;

typedef struct TOS_state {
  long long tos_time;
  int radio_kb_rate;
  short num_nodes;
  short current_node;
  TOS_node_state_t node_state[TOSNODES];
  event_queue_t queue;
  rfm_model* rfm;
  adc_model* adc;
  spatial_model* space;
} TOS_state_t;

#define NODE_NUM (tos_state.current_node)
#define THIS_NODE (tos_state.node_state[tos_state.current_node])
#define TOS_queue_insert_event(event) \
        queue_insert_event(&(tos_state.queue), event);

extern TOS_state_t tos_state;

int notifyTaskPosted(char* name);
int notifyEventSignaled(char* name);
int notifyCommandCalled(char* name);
int printTime(char* buf, int len);

#endif
