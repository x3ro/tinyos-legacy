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
 * Authors:		Jason Hill, Philip Levis
 * Description:         New radio bit interface to hardware
 * Major Modifications:
 *
 *
 * This component performs bit level control over the RF Monolitics radio.
 * Addtionally, it controls the amount of time per bit by using TCNT1.
 * It exposes the radio timer for higher level component use.
 *
 * The bitrate or timer value passed to functions represent clock ticks on
 * the 4 MHz clock. Passing a timer of 0 to POWER_OFF will result in
 * interrupts being disabled until POWER_ON is called.
 *
 */



#include "tos.h"
#include "RADIO.h"
#include "dbg.h"

#include <stdlib.h>

#define TOS_FRAME_TYPE RFM_frame
TOS_FRAME_BEGIN(RFM_frame) {
  char mode;
  short rate;
  char pendingChange;
  event_t* radioTickEvent;
}
TOS_FRAME_END(RFM_frame);

#define RADIO_RX_MODE        0
#define RADIO_TX_MODE        1
#define RADIO_OFF_MODE       2

#define RX_PENDING      0x01
#define TX_PENDING      0x02
#define OFF_PENDING     0x04
#define ON_PENDING      0x08
#define BITRATE_PENDING 0x10

#define RATE_LIMIT         0x0190

/* This is a SIGNAL handler that timer1 generates to trigger this
   component to sample on the radio */
TOS_SIGNAL_HANDLER(SIG_OUTPUT_COMPARE1A, ()){
  char in;

  //dbg(DBG_RADIO, ("mote in state %d\n", NODE_NUM, VAR(mode)));

  tos_state.rfm->stop_transmit(NODE_NUM);

  if(VAR(mode) == RADIO_TX_MODE){
    TOS_SIGNAL_EVENT(RADIO_TX_BIT_EVENT)();
  }
  else if(VAR(mode) == RADIO_RX_MODE){
    in = tos_state.rfm->hears(NODE_NUM);
    if (in) {dbg(DBG_RADIO, ("Received %x\n", in));}
    TOS_SIGNAL_EVENT(RADIO_RX_BIT_EVENT)(in);
  }
  else if (VAR(mode) == RADIO_OFF_MODE) {
    VAR(mode) = RADIO_RX_MODE;
    in = tos_state.rfm->hears(NODE_NUM);
    TOS_SIGNAL_EVENT(RADIO_RX_BIT_EVENT)(in);
  }
}

/* This command sets timer1 to different sampling level */
char TOS_COMMAND(RADIO_SET_BIT_RATE)(short rate){
  event_t* event;
  int time;

  dbg(DBG_RADIO, ("RADIO: bit rate set to %i.\n", (int)rate));
  if (VAR(mode) == RADIO_OFF_MODE) {
    return 0;
  }
  else if (rate != VAR(rate)) {
    if (VAR(radioTickEvent) != NULL) {
      event_radiotick_invalidate(VAR(radioTickEvent));
    }

    event = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, ("Allocating radio clock bit event: 0x%x.\n", (unsigned int)event));
    
    time = tos_state.tos_time + (rate / 2);

    event_radiotick_create(event, NODE_NUM, time, (rate / 2));
    TOS_queue_insert_event(event);
    
    VAR(radioTickEvent) = event;  
    VAR(rate) = rate;
  }
  return 1;
}


/* This command sets the RADIO component (radio) to transmit bit "data" */
char TOS_COMMAND(RADIO_TX_BIT)(char data){
  char rval;
  //if not in the transmit mote fail.
  cli();
  if(VAR(mode) != RADIO_TX_MODE) {
    dbg(DBG_RADIO, ("RADIO: Trying to transmit in non-transmit state.\n"));
    rval = 0;
  }
  //sent the output pin accordingly.
  else {
    tos_state.rfm->transmit(NODE_NUM, (char)(data & 0x01));
    dbg(DBG_RADIO, ("RADIO:sending bit %x\n", data & 0x01));
    rval = 1;
  }
  
  sei();
  return rval;
}


/*
 * All of these mode-switching functions need to be executed with interrupts
 * disabled, as the values they modify are checked in the signal handler.
 *
 * Specifically, if VAR(mode) or VAR(rate) is modified, it must be done
 * with interrupts disabled. Also, as some of these operations mess
 * with the timing of interrupts, keeping them disabled for those operations
 * is a paranoid precaution.
 */



/* This command sets the RADIO component (radio) into different power
 * mode */

char TOS_COMMAND(RADIO_PWR_OFF)(short timer){
  cli();
  VAR(mode) = RADIO_OFF_MODE;
  VAR(rate) = timer;
  
  //turn off the RADIO chip.
  CLR_RFM_CTL0_PIN();
  CLR_RFM_CTL1_PIN();
  
  if (timer == 0 && VAR(radioTickEvent) != NULL) {
    // If timer is 0, disable interrupts
    event_radiotick_invalidate(VAR(radioTickEvent));
  }
  else {  // Give wakeup time
    TOS_CALL_COMMAND(RADIO_SET_BIT_RATE)(timer);
  }

  dbg(DBG_RADIO, ("RADIO: Turn off radio with time %i\n", (int)timer));
  
  sei();
  return 1;
}


/* This command sets the RADIO component (radio) into transmit mode */
char TOS_COMMAND(RADIO_TX_MODE)(){

  cli();
  if(VAR(mode) == RADIO_OFF_MODE) {
    sei();
    return 0;
  }
  //set the RADIO chip to TX mode.
  SET_RFM_CTL0_PIN();
  CLR_RFM_CTL1_PIN();
  
  dbg(DBG_RADIO, ("RADIO: set TX mode....\n"));
  
  //record the current mode.
  VAR(mode) = RADIO_TX_MODE;
  
  sei();
  return 1;
}


/* This command sets the RADIO component (radio) into receiving mode */
char TOS_COMMAND(RADIO_RX_MODE)(){

  cli();
  if(VAR(mode) == RADIO_OFF_MODE) {
    sei();
    return 0;
  }
  //set the RADIO to RX mode.
  SET_RFM_CTL0_PIN();
  SET_RFM_CTL1_PIN();
  CLR_RFM_TXD_PIN();
  
  dbg(DBG_RADIO, ("RADIO: set RX mode....\n"));
  
  //record the current mode.
  VAR(mode) = RADIO_RX_MODE;

  sei();
  return 1;
}



// Turns the radio on into RX mode
char TOS_COMMAND(RADIO_PWR_ON)(short bitrate) {
  char val;

  cli();

  if (VAR(rate) == 0) { // radio was fully turned off; turn back on
    sbi(TIMSK, OCIE1A);
  }
  
  VAR(mode) = RADIO_RX_MODE;
  TOS_CALL_COMMAND(RADIO_RX_MODE)();
  val = TOS_CALL_COMMAND(RADIO_SET_BIT_RATE)(bitrate);
  dbg(DBG_RADIO, ("RADIO: Turning RADIO of with time %i.\n", (int)bitrate));
  sei();
  return 1;
}

short TOS_COMMAND(RADIO_GET_BIT_RATE)(void) {
  return VAR(rate);
}

/* Initialization of the Component */
char TOS_COMMAND(RADIO_INIT)(){

  //Reset to idle mode.
  VAR(mode) = RADIO_RX_MODE;
  
  //set the RADIO pins.
  SET_RFM_CTL0_PIN();
  SET_RFM_CTL1_PIN();
  CLR_RFM_TXD_PIN();
  
  cbi(TIMSK, OCIE1A); //clear interrupts
  cbi(TIMSK, TICIE1); //clear interrupts
  cbi(TIMSK, TOIE1);  //clear interrupts
  cbi(TIMSK, OCIE1B); //clear interrupts
  outp(0x09, TCCR1B); //scale the counter
  outp(0x00, TCCR1A);
  outp(0x00, OCR1AH); // set upper byte of comp reg.
  outp(0xc8, OCR1AL); // set the lower byte compare
  sbi(TIMSK, OCIE1A); // enable timer1 interupt
  outp(0x00, TCNT1H); // clear current counter value
  outp(0x00, TCNT1L); // clear current couter high byte value

  TOS_CALL_COMMAND(RADIO_SET_BIT_RATE)(200);
  
  dbg(DBG_BOOT, ("RADIO initialized\n"));

  return 1;
}

void event_radiotick_handle(event_t* event,
			    struct TOS_state* state) {
  
  event_queue_t* queue = &(state->queue);
  radio_tick_data_t* data = (radio_tick_data_t*)event->data;
  if (data->valid) {
    //dbg(DBG_RADIO, ("RADIO: tick event handled for mote %i at %lli with interval of %i.\n", event->mote, event->time, data->interval));
    
    event->time = event->time + data->interval;
    queue_insert_event(queue, event);
    
    TOS_ISSUE_SIGNAL(SIG_OUTPUT_COMPARE1A)();
  }
  else {
    //dbg(DBG_RADIO, ("RADIO: invalid tick event for mote %i at %lli discarded.\n", data->mote, event->time));

    event->cleanup(event);
  }
}

void event_radiotick_create(event_t* event, int mote, long long time, int interval) {
  //int time = THIS_NODE.time;

  clock_tick_data_t* data = (clock_tick_data_t*)malloc(sizeof(radio_tick_data_t));
  dbg(DBG_MEM, ("Allocating radio clock bit event data: 0x%x.\n", (unsigned int)data));
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  
  event->mote = mote;
  event->data = data;
  event->time = time;
  event->handle = event_radiotick_handle;
  event->cleanup = event_total_cleanup;
  event->pause = 0;
}

void event_radiotick_invalidate(event_t* event) {
  clock_tick_data_t* data = event->data;
  data->valid = 0;
}
