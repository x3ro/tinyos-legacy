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
 * Authors:		Philip Levis, Jason Hill
 *
 *    FILE: tossim/RFM.c
 *   DESCR: TOSSIM radio emulation.
 *
 */

/*
 * This component performs bit level control over the RF Monolitics radio.
 * Addtionally, it controls the amount of time per bit by using TCNT1.
 * The sample period can be set to 1/2x, 3/4x, and x. Where x is the 
 * bit transmisison period. 1/2 and 3/4 are provided to do sampling 
 * and then read at the point half way between samples.
 * 
 */



#include "tos.h"
#include "RFM.h"
#include "dbg.h"
#include "event_queue.h"
#include "events.h"
#include "external_comm.h"
#include "rfm_model.h"

#define TOS_FRAME_TYPE RFM_frame
TOS_FRAME_BEGIN(RFM_frame) {
        char state;
	char rate;
}
TOS_FRAME_END(RFM_frame);

//states:
// 0 == receive mode;
// 1 == transmit mode;
// 2 == low power mode;

event_t* radioTickEvents[TOSNODES];
int tickScale[] = {100, 150, 200};

TOS_SIGNAL_HANDLER(_output_compare1a_, ()){
  char in;

  dbg(DBG_RADIO, ("mote %i in state %d\n", NODE_NUM, VAR(state)));

  tos_state.rfm->stop_transmit(NODE_NUM);
 
  if(VAR(state) == 1){
    //if we are writing, then fire the bit send event.
    TOS_SIGNAL_EVENT(RFM_TX_BIT_EVENT)(); 
  }
  //  else if(VAR(state) == 0 && THIS_NODE.radio_active){
  else if(VAR(state) == 0){
    in = tos_state.rfm->hears(NODE_NUM);
    dbg(DBG_RADIO, ("RFM: Mote %i got  bit %x\n", NODE_NUM, in));
    
    TOS_SIGNAL_EVENT(RFM_RX_BIT_EVENT)(in);
  }
}

char TOS_COMMAND(RFM_TX_BIT)(char data){
  //if not in the transmit mote fail.
  if(VAR(state) != 1) {
    dbg(DBG_RADIO, ("RFM: Trying to transmit in non-transmit state.\n"));
    return 0;
  }

  tos_state.rfm->transmit(NODE_NUM, (char)(data & 0x01));
  
  dbg(DBG_RADIO, ("RFM: Mote %i sent bit %x\n", NODE_NUM, data & 0x01));
   
  return 1;
}
  
char TOS_COMMAND(RFM_PWR)(char mode){
  if(mode == 0){
#ifndef FULLPC
    //turn off the RFM chip.
    CLR_RFM_CTL0_PIN();
    CLR_RFM_CTL1_PIN();
    // disable timer1 interupt
    outp(0x00, TCCR1B); // scale the counter
    cbi(TIMSK, OCIE1A); 
#endif
    //record the current state.
    VAR(state) = 2;
  }else if(mode == 1){
#ifndef FULLPC
    VAR(state) = 3;
    outp(0x09, TCCR1B); // scale the counter
    sbi(TIMSK, OCIE1A); 
#endif
  }
  return 1;
}


 char TOS_COMMAND(RFM_TX_MODE)(){
    if(VAR(state) == 2) return 0;

    dbg(DBG_RADIO, ("RADIO: mote %i set TX mode....\n", NODE_NUM));

    //record the current state.
     VAR(state) = 1;
     return 1;
 }

char TOS_COMMAND(RFM_RX_MODE)(){
    if(VAR(state) == 2) return 0;

    dbg(DBG_RADIO, ("RADIO: mote %i set RX mode....\n", NODE_NUM));

    //record the current state.
     VAR(state) = 0;
     return 1;
}

// 2 = TX rate 10 Kbit/sec 4 tick
// 1 = received start state, offset to TX  3 tick
// 0 = receive start (double sample) 20 Kbit/sec 2 tick

char TOS_COMMAND(RFM_SET_BIT_RATE)(char level){
  event_t* event;
  int time;
  
  VAR(rate) = level;
  
  if (radioTickEvents[NODE_NUM] != NULL) {
    event_clocktick_invalidate(radioTickEvents[NODE_NUM]);
  }
  event = (event_t*)malloc(sizeof(event_t));
  time = tos_state.tos_time + tickScale[(int)level];

  event_radiotick_create(event, NODE_NUM, time, tickScale[(int)level]);
  TOS_queue_insert_event(event);

  radioTickEvents[NODE_NUM] = event;
  
  return 1;
}


char TOS_COMMAND(RFM_INIT)(){
  TOS_CALL_COMMAND(RFM_SET_BIT_RATE)(0);
  
  dbg(DBG_BOOT, ("RFM initialized\n"));
  return 1;
 }

void event_radiotick_handle(event_t* event,
			    struct TOS_state* state) {

  
  
  event_queue_t* queue = &(state->queue);
  radio_tick_data_t* data = (radio_tick_data_t*)event->data;
  if (data->valid) {
    dbg(DBG_RADIO, ("RADIO: tick event handled for mote %i at %lli with interval of %i.\n", event->mote, event->time, data->interval));
    
    event->time = event->time + data->interval;
    queue_insert_event(queue, event);
    
    TOS_ISSUE_SIGNAL(_output_compare1a_)();
  }
  else {
    dbg(DBG_RADIO, ("RADIO: invalid tick event for mote %i at %lli discarded.\n", data->mote, event->time));

    event->cleanup(event);
    free(event);
  }
}

void event_radiotick_create(event_t* event, int mote, long long time, int interval) {
  //int time = THIS_NODE.time;

  clock_tick_data_t* data = (clock_tick_data_t*)malloc(sizeof(radio_tick_data_t));
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  
  event->mote = mote;
  event->data = data;
  event->time = time;
  event->handle = event_radiotick_handle;
  event->cleanup = event_default_cleanup;
  event->pause = 0;
}

void event_radiotick_invalidate(event_t* event) {
  clock_tick_data_t* data = event->data;
  data->valid = 0;
}

