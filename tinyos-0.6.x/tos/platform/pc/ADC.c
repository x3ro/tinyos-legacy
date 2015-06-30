/*									tab:4
 * ADC.c - TOS abstraction of asynchronous digital photo sensor
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
 * 
 */

/*
 * OS component abstraction of the analog sensor and associated A/D
 * support.  It provides an asynchronous interface to the
 * analog-digital converter (ADC).
 *
 * The values this component returns are determined by the adc_model
 * initialized at simulation startup time. Refer to adc_model.[ch] for
 * more details. The default adc_model always returns 0 for every ADC
 * port
 */

/*  ADC_INIT command initializes the device */
/*  ADC_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  ADC_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/*  TOS task. */

#include "tos.h"
#include "ADC.h"
#include "dbg.h"
#include "tossim.h"

#include <stdlib.h>

#define ADC_LATENCY 200

char PORTMAP[PORTMAPSIZE]={
  TOS_ADC_PORT_0,
  TOS_ADC_PORT_1,
  TOS_ADC_PORT_2,
  TOS_ADC_PORT_3,
  TOS_ADC_PORT_4,
  TOS_ADC_PORT_5,
  TOS_ADC_PORT_6,
  TOS_ADC_PORT_7,
  TOS_ADC_PORT_8,
  TOS_ADC_PORT_9,
};

#define TOS_FRAME_TYPE ADC_frame
TOS_FRAME_BEGIN(ADC_frame) {
        volatile char state;
	volatile char port;
}
TOS_FRAME_END(ADC_frame);


void event_adc_handle(event_t* event, struct TOS_state* state);
void event_adc_create(event_t* event, int mote, long long time);

  /* ADC_INIT: initialize the A/D to access the photo sensor */
char TOS_COMMAND(ADC_INIT)(){
    dbg(DBG_BOOT, ("ADC initialized.\n"));
    return 0;
}

int get_adc_data(char port) {
  return (int)tos_state.adc->read(tos_state.current_node, port, tos_state.tos_time);
}

inline char TOS_EVENT(ADC_NULL_FUNC)(short data){return 0;} /* Signal data event to upper comp */

TOS_SIGNAL_HANDLER(SIG_ADC, ()){
    char port = VAR(port);
    int data;
    if(VAR(state) == 0) return;
    VAR(state) = 0;


    // Data model will go here;
    data = get_adc_data(port);

    dbg(DBG_ADC, ("adc_tick: %d, %i\n", port, data));
    if(port == TOS_ADC_PORT_0){		/* Signal data event to upper comp */
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_0)((int)data); 
    }if(port == TOS_ADC_PORT_1){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_1)((int)data); 
    }if(port == TOS_ADC_PORT_2){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_2)((int)data); 
    }if(port == TOS_ADC_PORT_3){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_3)((int)data); 
    }if(port == TOS_ADC_PORT_4){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_4)((int)data); 
    }if(port == TOS_ADC_PORT_5){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_5)((int)data); 
    }if(port == TOS_ADC_PORT_6){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_6)((int)data); 
    }if(port == TOS_ADC_PORT_7){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_7)((int)data); 
    }
}


char TOS_COMMAND(ADC_GET_DATA)(char port){
    char retval = 0;
    if(VAR(state) == 0){
      event_t* event = NULL;
      VAR(state) = 1;
      port &= 0x7;
      VAR(port) = port;
      
      event = (event_t*)malloc(sizeof(event_t));
      dbg(DBG_MEM, ("malloc ADC event.\n"));
      event_adc_create(event, NODE_NUM, tos_state.tos_time);
      TOS_queue_insert_event(event);
      dbg(DBG_ADC, ("ADC: request for port %i\n", (int)port));
      retval = 1;
    }
    return retval;
}


void event_adc_handle(event_t* event, struct TOS_state* state) {
  TOS_ISSUE_SIGNAL(SIG_ADC)();
  event->cleanup(event);
}

void event_adc_create(event_t* event, int mote, long long time) {
  event->data = NULL;
  event->mote = mote;
  event->pause = 0;
  event->time = time + ADC_LATENCY;
  event->handle = event_adc_handle;
  event->cleanup = event_total_cleanup;
}
