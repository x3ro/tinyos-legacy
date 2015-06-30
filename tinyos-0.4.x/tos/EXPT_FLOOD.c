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
/* This component floods the network with probabilistic flooding algorithm.*/

#include "tos.h"
#include "EXPT_FLOOD.h"

/* Possible states of the mote */
#define IDLE 0
#define CONNECTIVITY_WAIT 1
#define CONNECTIVITY 2
#define FLUSH_LOG 3
#define FLOOD_ORIGIN 4

/* Commands from Base Station */
#define SET_IDLE IDLE
#define SET_CONNECTIVITY_WAIT CONNECTIVITY_WAIT
#define SET_CONNECTIVITY CONNECTIVITY
#define SET_FLUSH_LOG FLUSH_LOG
#define SET_FLOOD_ORIGIN FLOOD_ORIGIN

#define START_OF_LOG  1
#define MAX_LINES 2047
#define BASELINE 1

#define BUFFERMASK 0x1f
#define OFLOWMASK 0x10

#define MAX_PACKETS_PER_POT 5
#define MAX_POT_INDEX 8

#define FLOOD_PERIOD 5

/* This is the ID of the mote retrieved from the EEPROM */
extern short TOS_LOCAL_ADDRESS;

/* Timestamp global defines */
extern uint32_t ts;
extern uint32_t ts_radio_out;
extern uint8_t tcnt0_radio_out;
extern uint32_t ts_radio_backoff;
extern uint8_t tcnt0_radio_backoff;

extern uint8_t maxNumBackoff;
extern uint16_t macRandomDelay;

/* Array for accessing pot settings for expt */
static uint8_t pot[8]={77,75,73,71,69,67,65,63};

// Flood Message Structure
typedef struct {
  short origin;
  short seqno;       // sequence number
  short parent;
  uint8_t hop_count;            // hop count of the source
  short dest;
  uint8_t prob;
  uint8_t pot;
  uint8_t command;
  uint8_t npkts;
  uint8_t maxNumBackoff;
  uint16_t macRandomDelay;
}floodmsg_t;

typedef struct {
  short src;
  uint8_t pot;
}connectivitymsg_t;

// Frame of the component
#define TOS_FRAME_TYPE EXPT_FLOOD_obj_frame
TOS_FRAME_BEGIN(EXPT_FLOOD_obj_frame) {
    TOS_Msg data;	       // flood message buffer
    TOS_MsgPtr msg;            // message ptr
    char state;
    char flood_send_pending;   // flag to see if flood buffer is sending
    short lastSeqno;       // seq no
    uint16_t prob;
    char log_buffer[32];
    uint8_t log_buffer_counter;
    uint8_t prev_oflow_mask;
    int log_line;
    int8_t sent_packets;
    int16_t countdown;
    uint8_t pot_index;
    char logger_pending;
    short current_src;
    char current_pot;
    char current_stats;
    short current_origin;
    uint8_t origin_pot;
    uint8_t origin_prob;
    uint8_t origin_npkts;
    uint8_t origin_maxNumBackoff;
    uint16_t origin_macRandomDelay;
}
TOS_FRAME_END(EXPT_FLOOD_obj_frame);

char TOS_COMMAND(EXPT_FLOOD_INIT)(){
  //initialize sub components
  TOS_CALL_COMMAND(EXPT_FLOOD_SUB_TIMESTAMP_INIT)();
  TOS_CALL_COMMAND(EXPT_FLOOD_SUB_CLOCK_INIT)(tick1ps);
  // Initialize settings

  VAR(state) = IDLE;

  VAR(msg) = &VAR(data);
  VAR(flood_send_pending) = 0;
  VAR(lastSeqno)=0;
  
  VAR(log_line) = BASELINE;
  // So that it wraps around
  VAR(log_buffer_counter) = 0xff;

  VAR(sent_packets) = 0;
  VAR(countdown) = 0;

  VAR(prev_oflow_mask) = 0;

  VAR(current_src) = 0;
  VAR(current_pot) = 50;
  VAR(current_stats) = 0;
  VAR(current_origin) = 0;
  
  VAR(origin_pot) = 0;
  VAR(origin_prob) = 0;
  VAR(origin_npkts) = 0;
  VAR(origin_maxNumBackoff)=0;
  VAR(origin_macRandomDelay) = 0;

  return 1;
}

char TOS_COMMAND(EXPT_FLOOD_START)(){
    return 1;
}



void TOS_EVENT(EXPT_FLOOD_CLOCK_EVENT)(){
  connectivitymsg_t *cptr;
  floodmsg_t *fptr;

  switch (VAR(state)) {
  case FLUSH_LOG:
      VAR(log_line) ++;
      if (VAR(log_line) == MAX_LINES) {
	  VAR(log_line) = BASELINE;
	  VAR(state) = IDLE;
	  SET_YELLOW_LED_PIN();
      } else {
	CLR_YELLOW_LED_PIN();
	  TOS_CALL_COMMAND(EXPT_FLOOD_SUB_WRITE_LOG)(VAR(log_line), (char *)&VAR(log_buffer)[0]);
	  VAR(logger_pending) = 1;
      }
      break;
  case CONNECTIVITY_WAIT:
      if (--VAR(countdown) == 0) {
	CLR_RED_LED_PIN();
	  VAR(state) = CONNECTIVITY;
	  VAR(sent_packets) = 0;
	  VAR(pot_index) = 0;
	  TOS_CALL_COMMAND(EXPT_FLOOD_SET_POT)(pot[VAR(pot_index)]);
	  TOS_CALL_COMMAND(EXPT_FLOOD_SUB_CLOCK_INIT)(tick8ps);
      }
      break;
  case CONNECTIVITY:
      if (VAR(flood_send_pending) == 0) {
	  cptr = (connectivitymsg_t *)&(VAR(msg)->data[0]);
	  cptr->src = TOS_LOCAL_ADDRESS;
	  cptr->pot = pot[VAR(pot_index)];
	  VAR(flood_send_pending) = TOS_CALL_COMMAND(EXPT_FLOOD_SUB_SEND_MSG)(TOS_BCAST_ADDR, 21,VAR(msg));
      }
      break;
  case FLOOD_ORIGIN:
      /* Use presets of base station command to send
	 flood message every FLOOD_PERIOD seconds.
	 FLOOD_PERIOD hardcoded. Needs change??
       */
      if (VAR(flood_send_pending) == 0 && (--VAR(countdown) <= 0)) {
	  fptr = (floodmsg_t *)&(VAR(msg)->data[0]);
	  fptr->origin = TOS_LOCAL_ADDRESS;
	  fptr->seqno = (++VAR(lastSeqno));
	  fptr->parent = TOS_LOCAL_ADDRESS;
	  fptr->hop_count = 0;
	  fptr->prob = VAR(origin_prob);
	  fptr->pot = VAR(origin_pot);
	  fptr->command = IDLE;
	  fptr->maxNumBackoff = VAR(origin_maxNumBackoff);
	  fptr->macRandomDelay = VAR(origin_macRandomDelay);
	  VAR(flood_send_pending) = TOS_CALL_COMMAND(EXPT_FLOOD_SUB_SEND_MSG)(TOS_BCAST_ADDR, 20,VAR(msg));
	  VAR(countdown) = FLOOD_PERIOD;
      }
      break;
  }
}

// Handler for the flooding the message.
TOS_MsgPtr TOS_MSG_EVENT(EXPT_FLOOD_UPDATE)(TOS_MsgPtr msg){
  floodmsg_t * fmsg = (floodmsg_t *) msg->data;
  TOS_MsgPtr tmp;
  int i;
  
  tmp = msg;

  if (VAR(current_origin) != fmsg->origin) {
    VAR(current_origin) = fmsg->origin;
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfd; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfd; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (fmsg->origin >> 8) & 0xff;
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = fmsg->origin & 0xff;
  } else {
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfe; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfe; //Delimiter
  }
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (fmsg->seqno >> 8) & 0xff;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = fmsg->seqno & 0xff;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (fmsg->parent >> 8) & 0xff;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = fmsg->parent & 0xff;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = fmsg->hop_count;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = fmsg->prob;
  VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = fmsg->pot;

  // If this is the new flood message
  if ( ((short)((fmsg->seqno) - VAR(lastSeqno))) > 0){

    // Update last sequence number
    VAR(lastSeqno) = fmsg->seqno;	   

    switch (fmsg->command) {
    case SET_IDLE:
	/* Set state to idle. Backup to get system out of
	   one of the other states (specifically CONNECTIVITY_WAIT)
	   Only IDLE state packets are logged.
	*/
	VAR(state) = IDLE;
	break;
    case SET_FLUSH_LOG: 
      VAR(state) = FLUSH_LOG;
      VAR(log_line) = BASELINE;
      for (i=0; i<BUFFERMASK; i++) VAR(log_buffer)[i] = 0xff;
      /* Flush log every 64 ms */
      TOS_CALL_COMMAND(EXPT_FLOOD_SUB_CLOCK_INIT)(tick64ps);
      break;
    case SET_CONNECTIVITY_WAIT: 
      VAR(state) = CONNECTIVITY_WAIT;
      /* Wait 5 secs per node before beginning xmn */
      VAR(countdown) = TOS_LOCAL_ADDRESS * 5;
      /* Initialize clock to be 1tick per second */
      TOS_CALL_COMMAND(EXPT_FLOOD_SUB_CLOCK_INIT)(tick1ps);
      break;
    case SET_CONNECTIVITY:
      /* Start sending connectivity packets if id matches.
	 Backup case if need to control connectivity from base station
	 or CONNECTIVITY_WAIT screws up due to clock skew
      */
      if (fmsg->dest == TOS_LOCAL_ADDRESS) {
	VAR(state) = CONNECTIVITY_WAIT;
	VAR(countdown) = 1;
	/* Initialize clock to be 1tick per second */
	TOS_CALL_COMMAND(EXPT_FLOOD_SUB_CLOCK_INIT)(tick1ps);
      }
      break;
    case SET_FLOOD_ORIGIN:
      /* Set initiator of flood packets to fmsg->origin.
	 ONLY the user-controlled base station can initiate
	 these packets
      */
      if (fmsg->dest == TOS_LOCAL_ADDRESS && VAR(state) != FLOOD_ORIGIN) {
	CLR_RED_LED_PIN();
	VAR(state) = FLOOD_ORIGIN;
	/* Initialize packets sent & countdown to next packet */
	VAR(sent_packets) = 0;
	VAR(countdown) = FLOOD_PERIOD;
	VAR(origin_pot) = fmsg->pot;
	VAR(origin_npkts) = fmsg->npkts;
	VAR(origin_prob) = fmsg->prob;
	VAR(origin_maxNumBackoff) = fmsg->maxNumBackoff;
	/* Initialize clock to be 1tick per second */
	TOS_CALL_COMMAND(EXPT_FLOOD_SUB_CLOCK_INIT)(tick1ps);
      }
      break;
    }

    /* If pot != current pot setting, reinitialize pot.
       Initialization: current_pot=0, so pot is set for first packet
    */
    if (fmsg->pot != VAR(current_pot)) {
      VAR(current_pot) = fmsg->pot;
      TOS_CALL_COMMAND(EXPT_FLOOD_SET_POT)(VAR(current_pot));
    }

    /* If global variable maxNumBackoff does not match,
       change it. maxNumBackoff used in experimental SEC_DED
    */
    if (fmsg->maxNumBackoff != maxNumBackoff)
	maxNumBackoff = fmsg->maxNumBackoff;

    /* If global variable macRandomDelay does not match,
       change it. macRandomDelay used in experimental SEC_DED
    */
    if (fmsg->macRandomDelay != macRandomDelay)
	macRandomDelay = fmsg->macRandomDelay;

    /* Unsigned char probability in packet converted to short.
       Special case for 0xff so that brute-force flooding can be
       done.
    */
    if (fmsg->prob == 0xff) 
	VAR(prob) = 0xffff;
    else
	VAR(prob) = (uint16_t)((fmsg->prob << 8) & 0xff00);

      
    if (VAR(prob) >= (uint16_t)TOS_CALL_COMMAND(EXPT_FLOOD_GET_RANDOM)()) {
	// set hop count and source of flood message
	fmsg->parent = TOS_LOCAL_ADDRESS;
	(fmsg->hop_count)++;
	
	// Start sending the flood message
	if (VAR(flood_send_pending) == 0){
	  CLR_GREEN_LED_PIN();
	    VAR(flood_send_pending) = TOS_CALL_COMMAND(EXPT_FLOOD_SUB_SEND_MSG)(TOS_BCAST_ADDR, 20,msg);
	    tmp = VAR(msg);
	    VAR(msg) = msg;
	}
    }
  }
  
  check_log_write();
  
  //set to msg by default. changed if msg fwded
  return tmp; 
}

TOS_MsgPtr TOS_MSG_EVENT(EXPT_FLOOD_CONNECTIVITY)(TOS_MsgPtr data) {
  connectivitymsg_t *cptr = (connectivitymsg_t *)&(data->data[0]);

  if (VAR(current_src) != cptr->src) {
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfc; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = 0xfc; //Delimiter
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (cptr->src >> 8) & 0xff;
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = cptr->src & 0xff;    
    VAR(current_stats) = 0;
    VAR(current_src) = cptr->src;
    VAR(current_pot) = cptr->pot;
  }
  
  if (VAR(current_pot) != cptr->pot) {
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = VAR(current_pot);
    VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = VAR(current_stats);
    VAR(current_pot) = cptr->pot;
    VAR(current_stats) = 0;
  }

  VAR(current_stats)++;

  check_log_write();
  
  return data;
}



//Event: finish sending a flood message.
char TOS_EVENT(EXPT_FLOOD_SEND_DONE)(TOS_MsgPtr data){

  if(data == VAR(msg)) {
    VAR(flood_send_pending) = 0;

    SET_GREEN_LED_PIN();    
    switch (VAR(state)) {	
    case IDLE:
      VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (ts_radio_backoff >> 8) & 0xff;     
      VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (ts_radio_backoff & 0xff);
      VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = tcnt0_radio_backoff & 0xff;
      VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (ts_radio_out >> 8) & 0xff;     
      VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = (ts_radio_out & 0xff);
      VAR(log_buffer)[(++VAR(log_buffer_counter)) & BUFFERMASK] = tcnt0_radio_out & 0xff;
      check_log_write();
      break;
    case FLOOD_ORIGIN:
	/* If specified number of packets have been sent,
	   go back to idle state
	*/
	if ((++VAR(sent_packets))>=VAR(origin_npkts)) {
	  SET_RED_LED_PIN();
	    VAR(sent_packets) = 0;
	    VAR(state) = IDLE;
	    VAR(origin_npkts) = 0;
	    VAR(origin_prob) = 0;
	    VAR(origin_pot) = 0;
	    VAR(origin_maxNumBackoff) = 0;
	}
	break;
    case CONNECTIVITY:
      /* check if pot setting needs to be changed */
      if ((++VAR(sent_packets)) == MAX_PACKETS_PER_POT) {
	if ((++VAR(pot_index)) == MAX_POT_INDEX) {
	  SET_RED_LED_PIN();
	  VAR(state) = IDLE;
	} else {
	  VAR(sent_packets) = 0;
	  TOS_CALL_COMMAND(EXPT_FLOOD_SET_POT)(pot[VAR(pot_index)]);
	  CLR_RED_LED_PIN();
	}
      }
    }
    return 1;
  }
  return 0;
}


void check_log_write() {
  if ((VAR(log_buffer_counter) & OFLOWMASK) != VAR(prev_oflow_mask)) {
    if (VAR(logger_pending)==0 && VAR(log_line) < MAX_LINES) {    
      CLR_YELLOW_LED_PIN();
      TOS_CALL_COMMAND(EXPT_FLOOD_SUB_WRITE_LOG)(VAR(log_line), (char *)&VAR(log_buffer)[VAR(prev_oflow_mask)]);
      if (++VAR(log_line) == MAX_LINES) CLR_YELLOW_LED_PIN();
      VAR(logger_pending) = 1;
    }
  }
}


char TOS_EVENT(EXPT_FLOOD_WRITE_LOG_DONE)(char success){
  if (success == 1) {
    VAR(logger_pending) = 0;
    SET_YELLOW_LED_PIN();
    VAR(prev_oflow_mask) = VAR(log_buffer_counter) & OFLOWMASK;
  }
  return 1;
}
