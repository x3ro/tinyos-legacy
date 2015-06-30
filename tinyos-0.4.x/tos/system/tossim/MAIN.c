/*									tab:4
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
 * Authors:		Philip Levis <pal@cs.berkeley.edu>
 *
 *
 */

/*
 *   FILE: MAIN.c
 * AUTHOR: pal
 *   DESC: Main file for event-based TOS mote simulator.
 */


/*
 * TOSSim uses a discrete event simulation of motes and their interaction.
 * The event queue interface is provided by event_queue.h; it uses a
 * minimizing heap-based priority queue (lower values are higher priority).
 *
 * The queue and a few other pieces of global state are defined in a
 * TOS_state_t named tos_state. tossim.h contains a few preprocessor macros
 * to more easily access this state. In theory, all access should be
 * mitigated by a programming interface, to allow easy modification of the
 * global state implementation. Write one, clean up on the second.
 *
 * Events, their creation and their use are specified in events.h.
 * It would be nice to have a separate .h for each group of events, but
 * this would mean having a .c, .comp, .h, event.c, and event.h for each
 * TOS component. This would be a bit ridiculous. The current logical
 * organization is based on the thought that there won't be *that* many
 * events (as few as possible, to maintain a minimal simulator interface).
 *
 * The goal is to keep hardware/real-world abstractions as hidden as possible
 * from TinyOS. For example, a mote sends a radio message, unaware of
 * what mote connectivity graph the simulator is using. This way, improved
 * simulation can be easily incorporated while not requiring any modification
 * to TinyOS code (which would be very bad).
 *
 * Frames and mote state is maintained by a series of arrays. When a mote
 * accesses a frame field, it actually indexes into the frame array based
 * on which mote is currently active (stored as global state in tos_state).
 * These tricks are stored in tos.h.
 */



#include "tos.h"
#include "MAIN.h"
#include "dbg.h"
#include "tossim.h"
#include "external_comm.h"
#include "rfm_model.h"
#include "rfm_space_model.h"
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include "time.h"

struct timespec delay, delay1;
int cnt = 0;



/* grody stuff to set mote address into code image */

short TOS_LOCAL_ADDRESS = 160;
char LOCAL_GROUP = DEFAULT_LOCAL_GROUP;

/**************************************************************
 *  Generic main routine.  Issues an init command to subordinate
 *  modules and then a start command.  These propagate down the
 *  tree as required.  The application component sits below main
 *  and above various levels of hardware support components
 *************************************************************/

TOS_state_t tos_state;


void handle_signal(int sig, siginfo_t* info, void* data) {
  if (sig == SIGINT) {
    printf("Exiting on SIGINT after %i seconds of simulation.\n", (int)(tos_state.tos_time / 2000000));
    exit(0);
  }
}

void usage(char *progname) {
  fprintf(stderr, "Usage: %s [-r <static|simple>] [-p usec] num_nodes\n", progname);
  fprintf(stderr, "Exiting...\n");
  exit(-1);
}

int main(int argc, char **argv) {
  struct sigaction action;
  long long i;
  int num_nodes;
  char* model_name = NULL;
  int start_time = 0;
  int pause_time = 0;
  
  if (argc == 6) {
    if (strcmp(argv[argc - 3], "-p") == 0) {
      usage(argv[0]);
    }
    if (strcmp(argv[argc - 5], "-r") == 0) {
      usage(argv[0]);
    }
    pause_time = atoi(argv[argc - 2]);
    model_name = argv[argc - 4];
  }
  if (argc == 4) {
    if (strcmp(argv[argc - 3], "-p") == 0) {
      pause_time = atoi(argv[argc - 2]);
    }
    else if (strcmp(argv[argc - 3], "-r") == 0) {
      model_name = argv[argc - 2];
    }
    else {
      usage(argv[0]);
    }
  }
  if (argc == 2 || argc == 4 || argc == 6) {
    if (argc == 2 && strcmp(argv[1], "-h") == 0) {
      usage(argv[0]);
    }
    num_nodes = atoi(argv[argc - 1]);
    if (num_nodes < 0) {
      usage(argv[0]);
    }
  }
  else {
    usage(argv[0]);
  } 

  action.sa_handler = handle_signal;
  sigemptyset(&action.sa_mask);
  action.sa_flags = 0;
  sigaction(SIGINT, &action, NULL);


  dbg_init();
  
  if (num_nodes > TOSNODES) {
    fprintf(stderr, "compiled for maximum of %d nodes\n", TOSNODES);
    fprintf(stderr, "Exiting...\n");
    exit(-1);
  }

  tos_state.num_nodes = num_nodes;

  // RFM model initialized (only one model for now)
  
  if (model_name == NULL || strcmp(model_name, "simple") == 0) {
    tos_state.rfm = create_simple_model();
  }
  else if (strcmp(model_name, "static") == 0) {
    tos_state.rfm = create_static_model();
  }
  else if (strcmp(model_name, "space") == 0) {
    tos_state.rfm = create_space_model();
  }
  else {
    dbg(DBG_ERROR, ("Don't recognize RFM model type: %s\n", model_name));
    tos_state.rfm = create_simple_model();
  }
  

  tos_state.rfm->init();
  init_hardware();
  
  queue_init(&(tos_state.queue), pause_time);
  dbg(DBG_SIM, ("SIM: event queue initialized.\n"));

  initializeIncomingUART();
  initializeOutgoingUART();
  initializeIncomingRadio();
  initializeOutgoingRadio();
  initializeOutgoingBitRadio();
  initializeIncomingRTRadio();

  for (i = 0; i < num_nodes; i++) { /* initialize machine state */
    int rval = rand() % 600;
    start_time += (rval) + 400;
    dbg(DBG_SIM, ("Time for mote %lli initialized to %i from %i.\n", i, start_time, rval));
    tos_state.node_state[i].time = start_time;
  }
  
  for (i = 0; i < num_nodes; i++) { /* initialize applications */
    tos_state.current_node = i;
    TOS_LOCAL_ADDRESS = tos_state.current_node;
    tos_state.tos_time = tos_state.node_state[i].time;
    TOS_CALL_COMMAND(MAIN_SUB_INIT)();
    //tos_state.tos_time++;
    TOS_CALL_COMMAND(MAIN_SUB_START)();
    tos_state.node_state[i].pot_setting = 73;
  }
  
  while(!queue_is_empty(&(tos_state.queue))) {
    //while(!TOS_schedule_task()) {
    tos_state.tos_time = queue_peek_event_time(&(tos_state.queue));
    queue_handle_next_event(&(tos_state.queue));
    TOS_schedule_task();
    //}
  }

  printf("Simulation completed.\n");
  return 0;
}

char TOS_EVENT(MAIN_SUB_SEND_DONE)(TOS_MsgPtr msg){return 1;}





