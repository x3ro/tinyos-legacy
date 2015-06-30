/*									tab:4
 * EXPERIMENT_TEST.c
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
 *
 * This application was written as a sample experiment, in order to show how
 * to use the tools for writing experiments provided in the EXPERIMENT, 
 * LOG_QUERY, TOPOLOGY_QUERY, and POT_KNOB components.
 */

#include "tos.h"
#include "EXPERIMENT_TEST.h"


#define TOS_FRAME_TYPE EXPERIMENT_TEST_frame
TOS_FRAME_BEGIN(EXPERIMENT_TEST_frame) {
  char active;  // keeps track of whether the experiment is running or not
  char pending;
  TOS_Msg data; 
}
TOS_FRAME_END(EXPERIMENT_TEST_frame);


char TOS_COMMAND(EXPERIMENT_TEST_INIT)(){
  TOS_CALL_COMMAND(EXPERIMENT_TEST_SUB_INIT)();

  VAR(active) = 0;

  TOS_CALL_COMMAND(EXPERIMENT_TEST_RED_LED_ON)();
  TOS_CALL_COMMAND(EXPERIMENT_TEST_GREEN_LED_OFF)();
  TOS_CALL_COMMAND(EXPERIMENT_TEST_YELLOW_LED_OFF)();
  return 1;
}

char TOS_COMMAND(EXPERIMENT_TEST_START)(){
  TOS_CALL_COMMAND(EXPERIMENT_TEST_SUB_START)();

  TOS_CALL_COMMAND(EXPERIMENT_TEST_CLOCK_INIT)(255, 5); // set clock interval

  return 1;
}

// called by EXPERIMENT component to start the experiment
char TOS_COMMAND(EXPERIMENT_TEST_START_EXP)(void){
  VAR(active) = 1;
  return 1;
}

// called by EXPERIMENT component to stop the experiment
char TOS_COMMAND(EXPERIMENT_TEST_STOP_EXP)(void){
  VAR(active) = 0;

  return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(EXPERIMENT_TEST_MSG)(TOS_MsgPtr msg){
  
  //when handling any event, check to make sure that the experiment is 
  //running before acting on the received event
  if(VAR(active) == 1) {
    TOS_CALL_COMMAND(EXPERIMENT_TEST_YELLOW_LED_TOGGLE)();
    TOS_CALL_COMMAND(EXPERIMENT_TEST_LOG_RECORD)(msg->data);  
  }

  return msg;
}

void TOS_EVENT(EXPERIMENT_TEST_CLOCK_EVENT)(void){  
  TOS_CALL_COMMAND(EXPERIMENT_TEST_RED_LED_TOGGLE)();

  //when handling any event, check to make sure that the experiment is 
  //running before acting on the received event
  if(VAR(active) == 1) {
    if(TOS_CALL_COMMAND(EXPERIMENT_TEST_GET_MOTE_MODE)() == 0) {
      TOS_CALL_COMMAND(EXPERIMENT_TEST_YELLOW_LED_TOGGLE)();
    } else {
      TOS_CALL_COMMAND(EXPERIMENT_TEST_GREEN_LED_TOGGLE)();
    }
  }
}

char TOS_EVENT(EXPERIMENT_TEST_RECORD_DONE)(char success) {
  return 1;
}
