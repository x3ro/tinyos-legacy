/*									tab:4
 *
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
 * Authors:		Deepak Ganesan
 *
 *
 */
#include "tos.h"
#include "CONNECTIVITY.h"

#define IDLE 0
#define BEACON_WAIT 1
#define BEACON 2
#define FLUSH_LOG 3

#define BEACON_INTERVAL 8

/* Rate of sending Proximity Beacons (4secs)*/
#define BEACON_RATE 64

#define MAX_PACKETS_PER_POT 20
#define MAX_POT_INDEX 16

#define COMMAND_START_CONNECTIVITY  5
#define COMMAND_STOP_CONNECTIVITY   6

#define START_OF_LOG  1
#define MAX_LINES 2047
#define BASELINE 1

#define BUFFERMASK 0x1f
#define OFLOWMASK 0x10

extern short TOS_LOCAL_ADDRESS;

static unsigned char pot[16]={79,77,75,74,73,72,71,70,69,68,67,66,65,63,61,59};

typedef struct {
  short src;
  unsigned char seq;
  unsigned char pot;
}connectivity_msg;

//your FRAME
#define TOS_FRAME_TYPE CONNECTIVITY_frame
TOS_FRAME_BEGIN(CONNECTIVITY_frame) {
  char state;			/* Component counter state */
  unsigned char flash_countdown;
  TOS_Msg data; 		/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
  char beacon_interval;
  unsigned char pot_index;
  char log_buffer[32];
  unsigned char log_buffer_counter;
  char prev_oflow_mask;
  int log_line;
  int connectivity_packets;
  char logger_pending;
  unsigned char seq;
  short current_src;
}TOS_FRAME_END(CONNECTIVITY_frame);

/* CONNECTIVITY_INIT:  
   turn on the LEDs
   initialize lower components.
   clock init to once a second
*/
char TOS_COMMAND(CONNECTIVITY_INIT)(){
  VAR(state) = IDLE;
  VAR(send_pending) = 0;
  VAR(beacon_interval) = 0;

  VAR(pot_index) = 0;

  VAR(log_line) = BASELINE;

  VAR(connectivity_packets) = 0;

  VAR(logger_pending) = 0;
  
  VAR(seq) = 0;

  VAR(current_src) = 0;

  // So that it wraps around
  VAR(log_buffer_counter) = 0xff;

  VAR(prev_oflow_mask) = 0;

  SET_YELLOW_LED_PIN();

  //  TOS_CALL_COMMAND(CONNECTIVITY_SUB_INIT)();
  TOS_CALL_COMMAND(CONNECTIVITY_SUB_CLOCK_INIT)(tick8ps);

  return 1;
}

char TOS_COMMAND(CONNECTIVITY_START)(){
  return 1;
}

/* Clock Event Handler: 
   If BaseStation has signalled, send beacons
*/

void TOS_EVENT(CONNECTIVITY_CLOCK_EVENT)(){
  connectivity_msg *p;
  
  if (VAR(state)==IDLE || VAR(state) == FLUSH_LOG) return;

  /* Wait for a random interval (beacon_countdown) before
     going into BEACON mode. This lets the command be propagated 
     thro' network
  */
  if (VAR(state)==BEACON_WAIT) {
    if ((--VAR(beacon_interval))==0) VAR(state)=BEACON;
    else return;
  }

  /*
    If in BEACON mode send packet every tick
  */
  p = (connectivity_msg *)&(VAR(data).data[0]);
  if (VAR(send_pending) == 0) {
    p->src = TOS_LOCAL_ADDRESS;
    p->seq = VAR(seq);
    p->pot = pot[VAR(pot_index)];
    if (TOS_CALL_COMMAND(CONNECTIVITY_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(CONNECTIVITY_BEACON_MSG),&VAR(data))) {
      CLR_RED_LED_PIN();
      VAR(send_pending) = 1;
      VAR(seq)++;
    }
  }
}


/*   
     CONNECTIVITY_SUB_MSG_SEND_DONE event handler:
*/
char TOS_EVENT(CONNECTIVITY_MSG_SEND_DONE)(TOS_MsgPtr msg){
  if(&VAR(data) == msg){ 
    VAR(send_pending) = 0;
    SET_RED_LED_PIN();
    /* check if pot setting needs to be changed */
    if ((++VAR(connectivity_packets)) == MAX_PACKETS_PER_POT) {
      if ((++VAR(pot_index)) == MAX_POT_INDEX) VAR(state) = IDLE;
      else {
	VAR(connectivity_packets) = 0;
	TOS_CALL_COMMAND(CONNECTIVITY_SET_POT)(pot[VAR(pot_index)]);
      }
    }
    return 1;
  }
  return 0;
}

/*   AM_msg_handler_9
     
 */
TOS_MsgPtr TOS_MSG_EVENT(CONNECTIVITY_BEACON_MSG)(TOS_MsgPtr data){
  connectivity_msg *p = (connectivity_msg *)&(data->data[0]);
  
  if (VAR(current_src) != p->src) {
    VAR(current_src) = p->src;
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfe; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfe; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (p->src >> 8) & 0xff;
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = p->src & 0xff;
  }
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = p->seq;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = p->pot;

  if ((VAR(log_buffer_counter) & OFLOWMASK) != VAR(prev_oflow_mask)) {
    if (VAR(logger_pending)==0 && VAR(log_line) < MAX_LINES) {    
      TOS_CALL_COMMAND(CONNECTIVITY_SUB_WRITE_LOG)(VAR(log_line), (char *)&VAR(log_buffer)[VAR(prev_oflow_mask)]);
      if (++VAR(log_line) == MAX_LINES) CLR_GREEN_LED_PIN();
      VAR(logger_pending) = 1;
    }
  }
  return data;
}
 
char TOS_EVENT(CONNECTIVITY_WRITE_LOG_DONE)(char success){
  if (success == 1) {
    VAR(logger_pending) = 0;
    if (VAR(state) == FLUSH_LOG) {
      VAR(log_line) ++;
      if (VAR(log_line) == MAX_LINES) {
	VAR(log_line) = BASELINE;
	VAR(state) = IDLE;
	SET_YELLOW_LED_PIN();
      } else {
	TOS_CALL_COMMAND(CONNECTIVITY_SUB_WRITE_LOG)(VAR(log_line), (char *)&VAR(log_buffer)[0]);
	VAR(logger_pending) = 1;
      }
      return 1;
    }
    VAR(prev_oflow_mask) = VAR(log_buffer_counter) & OFLOWMASK;
  }
  return 1;
}

/*
char TOS_COMMAND(CONNECTIVITY_SET_MODE)(char mode){
  if (mode==COMMAND_START_CONNECTIVITY) {
    if (VAR(state)==IDLE) {
      VAR(state)=BEACON_WAIT;
      VAR(beacon_interval) = BEACON_INTERVAL;
    }
  } else {
    VAR(state) = IDLE;
  }
  return 1;
}
*/

TOS_MsgPtr TOS_MSG_EVENT(CONNECTIVITY_START_MSG)(TOS_MsgPtr data) {
  connectivity_msg *p = (connectivity_msg *)&(data->data[0]);

  if (p->src == TOS_LOCAL_ADDRESS) {
    VAR(state) = BEACON;
    VAR(beacon_interval) = BEACON_INTERVAL;
    VAR(connectivity_packets) = 0;
    VAR(pot_index) = 0;
    CLR_RED_LED_PIN();
    TOS_CALL_COMMAND(CONNECTIVITY_SET_POT)(pot[VAR(pot_index)]);
    VAR(seq) = 0;
  }
  return data;
}

TOS_MsgPtr TOS_MSG_EVENT(CONNECTIVITY_FLUSH_LOG)(TOS_MsgPtr data) {
  int i;

  CLR_YELLOW_LED_PIN();
  VAR(state) = FLUSH_LOG;
  VAR(log_line) = BASELINE;
  for (i=0; i<16; i++) VAR(log_buffer)[i] = 0xff;
  VAR(log_line) = BASELINE;
  if (VAR(logger_pending)==0)
    TOS_CALL_COMMAND(CONNECTIVITY_SUB_WRITE_LOG)(VAR(log_line), (char *)&VAR(log_buffer)[0]);
  
  return data;
}
