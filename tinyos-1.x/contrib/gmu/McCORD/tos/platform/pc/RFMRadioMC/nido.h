// $Id: nido.h,v 1.1.1.1 2008/03/24 01:31:47 lhuang2 Exp $

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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: nido.h
 * AUTHOR: pal
 *   DESC: Core simulation data.
 *
 *   This file declares the core structures used by NIDO, including
 *   the global simulation state (time, etc.) and individual node state.
 *
 *   This file also defines a few macros for simulation state abstraction.
 *
 */

/**
 * @author Philip Levis
 * @author pal
 */


#ifndef NIDO_H_INCLUDED
#define NIDO_H_INCLUDED


/* in nesc/nesc-cpp.c, the TOSH_NUM_NODES macro is defined, so that
   TOSNODES is set to the value specified to the nesc compiler by the flag
   "-fnesc-nido-tosnodes=___" */
enum {
  TOSNODES = TOSH_NUM_NODES,
};

#ifndef DEFAULT_EEPROM_SIZE
#define DEFAULT_EEPROM_SIZE (512 * 1024)  // 512 KB
#endif

enum {
  TOSSIM_RADIO_MODEL_SIMPLE = 0,
  TOSSIM_RADIO_MODEL_LOSSY = 1,
  TOSSIM_RADIO_MODEL_PACKET = 2
};


#include <event_queue.h>
#include <adjacency_list.h>
#include <rfm_model.h>
#include <adc_model.h>
#include <spatial_model.h>
#include <nido_eeprom.h>
#include <events.h>
#include <packet_sim.h>
#include <sys/time.h>

//lhuang2:
typedef struct nodelist {
  uint16_t mote;
  struct nodelist * next;
} nodelist_t;

typedef struct TOS_node_state{
  long long time; // Time at which mote booted
  int pot_setting;
  uint8_t channel; // lhuang2: the current channel the mote sends and receives.
  nodelist_t * senderlist;  //lhuang2:
} TOS_node_state_t;

typedef struct TOS_state {
  long long tos_time;
  int radio_kb_rate;
  short num_nodes;
  short current_node;
  TOS_node_state_t node_state[TOSNODES];
  event_queue_t queue;
  uint8_t radioModel;    // Simple, lossy (bit), or packet, from above enum
  rfm_model* rfm;        // The actual functions that implement the model
  adc_model* adc;
  spatial_model* space;
  bool moteOn[TOSNODES];
  bool cancelBoot[TOSNODES];

  /* Synchronization */
  bool paused;
  pthread_mutex_t pause_lock;
  pthread_cond_t pause_cond;
  pthread_cond_t pause_ack_cond;
} TOS_state_t;

#define NODE_NUM (tos_state.current_node)
#define THIS_NODE (tos_state.node_state[tos_state.current_node])
#define TOS_queue_insert_event(event) \
        queue_insert_event(&(tos_state.queue), event);

extern TOS_state_t tos_state;

int notifyTaskPosted(char* name);
int notifyEventSignaled(char* name);
int notifyCommandCalled(char* name);
void set_sim_rate(uint32_t);
uint32_t get_sim_rate();
static void __nesc_nido_initialise(int mote);

#include <dbg_modes.h>

/* This function is here because it uses function pointers */
void tos_state_model_init(void) 
{
  tos_state.space->init();
  tos_state.rfm->init();
  tos_state.adc->init();
}

extern void doChannelSwitch(uint16_t moteID, uint8_t newChannel); //lhuang2

//lhuang2:
#define SENDERLIST(X) (tos_state.node_state[X].senderlist)
bool add_sender(uint16_t receiver, uint16_t sender) {
  nodelist_t * node = malloc(sizeof(nodelist_t));
  node->mote = sender;
  node->next = SENDERLIST(receiver);
  SENDERLIST(receiver) = node;
  return TRUE;
}
bool remove_sender(uint16_t receiver, uint16_t sender) {
  nodelist_t * list = SENDERLIST(receiver);
  nodelist_t * prev_list;
  for (prev_list = list; 
       list != NULL; 
       prev_list = list, list = list->next) {
    if (list->mote == sender) {
      if (prev_list == list) //head
        SENDERLIST(receiver) = list->next;
      else
        prev_list->next = list->next;
      free(list);
      return TRUE;
    } 
  }
  return FALSE;
}
void remove_all_senders(uint16_t receiver) {
  nodelist_t * list = SENDERLIST(receiver);
  while (list != NULL) {
    SENDERLIST(receiver) = list->next;
    free(list);
    list = SENDERLIST(receiver);
  }
}

#endif

