/*									tab:4
 * EXPERIMENT.c
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:   Solomon Bien
 * History:   created 8/14/2001
 *
 */

/* This component provides the following capabilities:
   -start an experiment (or topology_query app)
         -specify delay and duration
   -end an experiment (or topology_query app)
         -specify delay
   -handle discover messages--info about a node is sent back in response
   -change the experimental ID (group ID)

   
   All of these things are triggered through AM interfaces.  In order to start
   and stop an experiment, it is necessary to provide mappings for the
   EXPERIMENT_SUB_START_EXPERIMENT() and EXPERIMENT_SUB_STOP_EXPERIMENT()
   functions.  See apps/experiment_test.desc as an example.

   This component uses AM handlers # 89, 90, 91, 92, and 95.
*/

#include "tos.h"
#include "EXPERIMENT.h"

#define MAX_NUM_NEIGHBORS 4  /* must have the same value as the same constant
				in TOPOLOGY_QUERY.c */
#define HIGH_TRANSMIT_POWER 60

typedef struct{
  char exp_id;    // value to which the group ID should be changed
} experiment_msg;

typedef struct{
  short src;          // address of this node
  char pot_setting;   // current POT setting of this node
  //  char naming_scheme;  //include this line if using the NAMING component
  char mote_mode;     // current mode/role of this node
  short neighbors[MAX_NUM_NEIGHBORS];   /* addresses of this node's one-hop 
					   neighbors */
} discover_msg;

typedef struct{
  char start_connectivity;    /* 1 if the start_exp message should start 
				 TOPOLOGY_QUERY, 0 if it should start the 
				 chosen experiment */
  char delay;         // number of clock ticks before experiment should start
  char duration;      // number of clock ticks for which experiment should run
} start_exp_msg;

typedef struct{
  char mode;          // value to which the mode/role should be changed
} mote_mode_msg;

#define MONITOR_MODE     0   // the node is monitoring the experiment
#define EXPERIMENT_MODE  1   // the node is taking part in the experiment

#define TOS_FRAME_TYPE EXPERIMENT_frame
TOS_FRAME_BEGIN(EXPERIMENT_frame) {
  char exp_start_in_x_secs;
  char remaining_running_time;
  char duration_tmp;
  char mode;
  /* uncomment next two lines if signal strength should be increased
     before sending responses to control messages */
  //char pot_stored;
  //char current_pot;
  short respond;
  char pending;
  TOS_Msg data;
}
TOS_FRAME_END(EXPERIMENT_frame);


char TOS_COMMAND(EXPERIMENT_INIT)(){
  TOS_CALL_COMMAND(EXPERIMENT_SUB_INIT)();
  VAR(exp_start_in_x_secs) = -1;
  VAR(remaining_running_time) = -1;
  VAR(mode) = EXPERIMENT_MODE;
  /* uncomment next line if signal strength should be increased
     before sending responses to control messages */
  //VAR(pot_stored) = 0;
  VAR(respond) = 0xffff;
  VAR(pending) = 0;
  return 1;
}

char TOS_COMMAND(EXPERIMENT_START)(){
  TOS_CALL_COMMAND(EXPERIMENT_SUB_START)();
  return 1;
}


char TOS_EVENT(EXPERIMENT_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
  /* uncomment next lines if signal strength should be increased
     before sending responses to control messages */
  //if(VAR(pot_stored) == 1) {
  //  TOS_CALL_COMMAND(EXPERIMENT_POT_SET)(VAR(current_pot));
  //  VAR(pot_stored) = 0;
  //}
  
  if (VAR(pending) && msg == &VAR(data)) {
    VAR(pending) = 0;
    return 1;
  }
  return 0;
}

// handler that changes the group/experimental ID
TOS_MsgPtr TOS_MSG_EVENT(SET_EXP_ID_MSG)(TOS_MsgPtr msg){
  experiment_msg * t;
  
  t = (experiment_msg *) msg->data;
  
  LOCAL_GROUP = t->exp_id;

  return msg;
}

// handler that responds with the current node's info
TOS_MsgPtr TOS_MSG_EVENT(DISCOVER_MSG)(TOS_MsgPtr msg){
  discover_msg * t;
  
  t = (discover_msg *) msg->data;

  TOS_CALL_COMMAND(EXPERIMENT_GREEN_LED_ON)();
  
  if(t->src == 0) {
    VAR(respond) = t->src;
    
    t = (discover_msg *) VAR(data).data;
    
    t->src = TOS_LOCAL_ADDRESS;
    t->pot_setting = TOS_CALL_COMMAND(EXPERIMENT_POT_GET)();
    t->mote_mode = TOS_CALL_COMMAND(EXPERIMENT_GET_MODE)();
    TOS_CALL_COMMAND(EXPERIMENT_YELLOW_LED_ON)();
    // uncomment the next line if using the NAMING component
    //t->naming = TOS_CALL_COMMAND(EXPERIMENT_NAMING_GET_NAMING_SCHEME)();
    /* uncomment next lines if signal strength should be increased
       before sending responses to control messages */
    //VAR(pot_stored) = 1;
    //VAR(current_pot) = TOS_CALL_COMMAND(EXPERIMENT_POT_GET)();
    //TOS_CALL_COMMAND(EXPERIMENT_POT_SET)(HIGH_TRANSMIT_POWER);
    TOS_CALL_COMMAND(EXPERIMENT_GREEN_LED_OFF)();
    TOS_CALL_COMMAND(EXPERIMENT_NEIGHBORS_GET_NEIGHBORS)(t->neighbors,MAX_NUM_NEIGHBORS);
    TOS_CALL_COMMAND(EXPERIMENT_YELLOW_LED_OFF)();
    if(! VAR(pending)) {
      VAR(pending) = 1;
      TOS_CALL_COMMAND(EXPERIMENT_SUB_SEND_MSG)(VAR(respond),AM_MSG(DISCOVER_MSG),&VAR(data));
      TOS_CALL_COMMAND(EXPERIMENT_GREEN_LED_ON)();
    }
  }
  return msg;
}

// handler that starts an experiment
TOS_MsgPtr TOS_MSG_EVENT(START_EXP_MSG)(TOS_MsgPtr msg){
  start_exp_msg * t;

  t = (start_exp_msg *) msg->data;

  if(t->start_connectivity) {
    TOS_CALL_COMMAND(EXPERIMENT_CONNECTIVITY_START)();
  } else {
    if(t->delay == 0) {
      // a mapping for this function must be provided
      TOS_CALL_COMMAND(EXPERIMENT_SUB_START_EXPERIMENT)();
      VAR(remaining_running_time) = t->duration;
    } else {
      VAR(exp_start_in_x_secs) = t->delay;
      VAR(duration_tmp) = t->duration;
    }
  }
  
  return msg;
}


TOS_MsgPtr TOS_MSG_EVENT(STOP_EXP_MSG)(TOS_MsgPtr msg){
  start_exp_msg * t;
  
  t = (start_exp_msg *) msg->data;

  if(t->start_connectivity) {
    TOS_CALL_COMMAND(EXPERIMENT_CONNECTIVITY_STOP)();
  } else {
    if(t->delay == 0) {
      // a mapping for this function must be provided
      TOS_CALL_COMMAND(EXPERIMENT_SUB_STOP_EXPERIMENT)();
    } else {
      VAR(remaining_running_time) = t->delay;
    }
  }
  
  return msg;
}


void TOS_EVENT(EXPERIMENT_CLOCK_EVENT)(){
  if(VAR(remaining_running_time) == 0) {
    TOS_CALL_COMMAND(EXPERIMENT_SUB_STOP_EXPERIMENT)();
  }
  if(VAR(remaining_running_time) >= 0) {
    VAR(remaining_running_time)--;
  }
  
  if(VAR(exp_start_in_x_secs) == 0) {
    TOS_CALL_COMMAND(EXPERIMENT_SUB_START_EXPERIMENT)();
    VAR(remaining_running_time) = VAR(duration_tmp);
  }
  if(VAR(exp_start_in_x_secs) >= 0) {
    VAR(exp_start_in_x_secs)--;
  }
}

char TOS_COMMAND(EXPERIMENT_GET_MODE)() {
  return VAR(mode);
}

// handler that changes the mode/role of the current node
TOS_MsgPtr TOS_MSG_EVENT(MOTE_MODE_MSG)(TOS_MsgPtr msg){
  mote_mode_msg * t;
    
  t = (mote_mode_msg *) msg->data;

  VAR(mode) = t->mode;

  return msg;
}
