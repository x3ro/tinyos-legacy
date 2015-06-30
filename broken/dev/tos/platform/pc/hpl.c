/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*******************************************************************************
 ******************** The Clock implementation for Nido ************************
 *******************************************************************************/


static int clockScales[] = {-1, 122, 976, 3906, 7812, 15625, 31250, 125000};

static event_t* clockEvents[TOSNODES];

TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE2, (void));
TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE1A, (void));
void TOSH_adc_data_ready(uint16_t data);
void TOSH_rfm_bit_event(void);
void TOSH_uart_putdone(void);


void TOSH_clock_set_rate(char interval, char scale) 
{
  long long ticks;
  event_t* event = NULL;
  
  if (clockEvents[NODE_NUM] != NULL) {
    event_clocktick_invalidate(clockEvents[NODE_NUM]);
  }
  
  ticks = clockScales[(int)(scale & 0xff)] * (int)(interval & 0xff);
  
  
  
  if (ticks > 0) {
    dbg(DBG_BOOT, "Clock initialized for mote %i to %lli ticks.\n", NODE_NUM, ticks);
    
    event = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc clock tick event: 0x%x.\n", (int)event);
    event_clocktick_create(event, NODE_NUM, tos_state.tos_time, ticks);
    TOS_queue_insert_event(event);
  }
  
  clockEvents[NODE_NUM] = event;
  return ; 
}

void event_clocktick_handle(event_t* event,
			    struct TOS_state* state) {
  
  
  event_queue_t* queue = &(state->queue);
  clock_tick_data_t* data = (clock_tick_data_t*)event->data;
  TOS_LOCAL_ADDRESS = (short)(event->mote & 0xffff);
  
  if (TOS_LOCAL_ADDRESS != event->mote) {
    dbg(DBG_ERROR, "ERROR in clock tick event handler! Things are probably ver bad....\n");
  }

  if (data->valid) {
    if (dbg_active(DBG_CLOCK)) {
      char buf[1024];
      printTime(buf, 1024);
      dbg(DBG_CLOCK, "CLOCK: event handled for mote %i at %s with interval of %i.\n", event->mote, buf, data->interval);
    }
    
    event->time = event->time + data->interval;
    queue_insert_event(queue, event);
    
    TOS_ISSUE_INTERRUPT(SIG_OUTPUT_COMPARE2)();
  }
  else {
    dbg(DBG_CLOCK, "CLOCK: invalid event discarded.\n");
    
    event->cleanup(event);
  }
}

void event_clocktick_create(event_t* event, int mote, long long eventTime, int interval) {
  //long long time = THIS_NODE.time;
  
  clock_tick_data_t* data = malloc(sizeof(clock_tick_data_t));
  dbg(DBG_MEM, "malloc data entry for clock event: 0x%x\n", (int)data);
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  
  event->mote = mote;
  event->pause = 1;
  event->data = data;
  event->time = eventTime + interval;
  event->handle = event_clocktick_handle;
  event->cleanup = event_total_cleanup;
}


void event_clocktick_invalidate(event_t* event) {
  clock_tick_data_t* data = event->data;
  data->valid = 0;
}



/*******************************************************************************
 ********************** The ADC implementation for Nido ************************
 *******************************************************************************/

enum {
  ADC_LATENCY = 200
};

static int adcScales[] = {3750, 7500, 15000, 30000, 60000, 120000, 240000, 480000};

static event_t* adcEvents[TOSNODES];
static char adcSamplingRates[TOSNODES];

void TOSH_adc_init(void) {
}


void TOSH_adc_set_sampling_rate(uint8_t rate)
{
  adcSamplingRates[tos_state.current_node] = rate;
}


void TOSH_adc_sample_port(uint8_t port)
{
  event_t* event = NULL;
  dbg(DBG_ADC, "ADC: request for port %i\n", (int)port);
  if (NULL == adcEvents[tos_state.current_node]) {
    event = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc adc tick event: 0x%x.\n", (int)event);
    event_adc_create(event, NODE_NUM, port, tos_state.tos_time, adcSamplingRates[tos_state.current_node]);
    adcEvents[tos_state.current_node] = event;
  }
  else {
    event = adcEvents[tos_state.current_node];
    event_adc_update(event, NODE_NUM, port, tos_state.tos_time, adcSamplingRates[tos_state.current_node]);
  }
  
  TOS_queue_insert_event(event);
    
}

void TOSH_adc_sample_again(void)
{
  event_t* event = adcEvents[tos_state.current_node];
  adc_tick_data_t* data = event->data;
  if (NULL == event)
    dbg(DBG_ERROR, "TOSH_adc_sample_again called after TOSH_adc_sample_stop without calling TOSH_adc_sample_port again...VERY BAD!!");
  
  event->time += adcScales[(int)adcSamplingRates[tos_state.current_node]];
  data->valid = 1;
}

void TOSH_adc_sample_stop(void)
{
  ((adc_tick_data_t*)adcEvents[tos_state.current_node]->data)->valid = 0;
}



int get_adc_data(char port) {
  return (int)tos_state.adc->read(tos_state.current_node, port, tos_state.tos_time);
}

TOS_SIGNAL_HANDLER(SIG_ADC, ()) {
  // Data model will go here;
  int data;
  data = get_adc_data(((adc_tick_data_t*) adcEvents[tos_state.current_node]->data)->port);
  TOSH_adc_data_ready(data);
}




void event_adc_handle(event_t* event, struct TOS_state* state) {
  TOS_ISSUE_SIGNAL(SIG_ADC)();
  if (((adc_tick_data_t*) event->data)->valid) {
    TOS_queue_insert_event(event);
  }
  else {
    event->cleanup(event);
    adcEvents[tos_state.current_node] = NULL;
  }
}

void event_adc_update(event_t* event, int mote, uint8_t port, long long eventTime, int interval) {
  adc_tick_data_t* data = event->data;
  data->valid = 1;
  data->port = port;

  event->time = eventTime + interval;
}

void event_adc_create(event_t* event, int mote, uint8_t port, long long eventTime, int interval) {
  adc_tick_data_t* data = (adc_tick_data_t*) malloc(sizeof(adc_tick_data_t));
  dbg(DBG_MEM, "malloc data entry for adc event: 0x%x\n", (int)data);
  data->valid = 1;
  data->port = port;

  event->data = data;
  event->mote = mote;
  event->pause = 0;
  event->time = eventTime + interval;
  event->handle = event_adc_handle;
  event->cleanup = event_total_cleanup;
}


/*******************************************************************************
 ********************** The RFM implementation for Nido ************************
 *******************************************************************************/

event_t* radioTickEvents[TOSNODES];
int tickScale[] = {2000, 3000, 4000};
uint8_t radioWaitingState[TOSNODES];
char TOSH_MHSR_start[12] = {0xf0, 0xf0, 0xf0, 0xff, 0x00, 0xff, 0x0f, 0x00, 0xff, 0x0f, 0x0f, 0x0f}; //40 Kbps

enum {
  NOT_WAITING = 0,
  WAITING_FOR_ONE_TO_PASS = 1,
  WAITING_FOR_ONE_TO_CAPTURE = 2
};



TOS_SIGNAL_HANDLER(SIG_OUTPUT_COMPARE1A, ()) {
  tos_state.rfm->stop_transmit(NODE_NUM);
  TOSH_rfm_bit_event();
}

// 2 = TX rate 10 Kbit/sec 4 tick
// 1 = received start state, offset to TX  3 tick
// 0 = receive start (double sample) 20 Kbit/sec 2 tick
void TOSH_rfm_set_bit_rate(uint8_t level) {
  event_t* event;
  long long ftime;
  long long timerSpacing;
  
  if (radioTickEvents[NODE_NUM] != NULL) {
    event_radiotick_invalidate(radioTickEvents[NODE_NUM]);
  }
  dbg(DBG_MEM, "malloc radio bit event.\n");
  event = (event_t*)malloc(sizeof(event_t));
  
  // Calculate the timer ticks between radio interrupts; higher
  // kbit rates result in shorter ticks (duh).
  timerSpacing = tickScale[(int)level] / tos_state.radio_kb_rate;
  ftime = tos_state.tos_time + timerSpacing;

  event_radiotick_create(event, NODE_NUM, ftime, timerSpacing);
  TOS_queue_insert_event(event);

  radioTickEvents[NODE_NUM] = event;
}

void TOSH_rfm_init(void)
{
  TOSH_rfm_set_bit_rate(0);
  dbg(DBG_BOOT, "RFM initialized\n");
}

uint8_t TOSH_rfm_rx_bit(void)
{
  uint8_t data;
  data = tos_state.rfm->hears(NODE_NUM);
  dbg(DBG_RADIO, "RFM: Mote %i got bit %x\n", NODE_NUM, data);
  return data;
}

/* This function transmits the low-order bit of 'data' */
void TOSH_rfm_tx_bit(uint8_t data)
{
  tos_state.rfm->transmit(NODE_NUM, (char)(data & 0x01));
  dbg(DBG_RADIO, "RFM: Mote %i sent bit %x\n", NODE_NUM, data & 0x01);
}


void TOSH_rfm_power_off(void) {}

void TOSH_rfm_disable_timer(void) {}

void TOSH_rfm_enable_timer(void) {}

void TOSH_rfm_tx_mode(void) {}

void TOSH_rfm_rx_mode(void) {}


void event_radiotick_handle(event_t* event,
			    struct TOS_state* state) {
  event_queue_t* queue = &(state->queue);
  radio_tick_data_t* data = (radio_tick_data_t*)event->data;
  if (data->valid) {
    if(dbg_active(DBG_RADIO)) {
      char ftime[128];
      ftime[0] = 0;
      printTime(ftime, 128);
      dbg(DBG_RADIO, "RADIO: tick event handled for mote %i at %s with interval of %i.\n", event->mote, ftime, data->interval);
      //dbg(DBG_RADIO, "RADIO: tick event handled for mote %i at %lli\n", event->mote, event->time);
    }
    
    event->time = event->time + data->interval;
    queue_insert_event(queue, event);
    
    TOS_ISSUE_SIGNAL(SIG_OUTPUT_COMPARE1A)();
  }
  else {
    dbg(DBG_RADIO, "RADIO: invalid tick event for mote %i at %lli discarded.\n", data->mote, event->time);
    
    event->cleanup(event);
  }
}

void event_radiotick_create(event_t* event, int mote, long long ftime, int interval) {
  //int time = THIS_NODE.time;

  radio_tick_data_t* data = (radio_tick_data_t*)malloc(sizeof(radio_tick_data_t));
  dbg(DBG_MEM, "malloc radio clock bit event data.\n");
  data->interval = interval;
  data->mote = mote;
  data->valid = 1;
  
  event->mote = mote;
  event->data = data;
  event->time = ftime;
  event->handle = event_radiotick_handle;
  event->cleanup = event_total_cleanup;
  event->pause = 0;
}

void event_radiotick_invalidate(event_t* event) {
  clock_tick_data_t* data = event->data;
  data->valid = 0;
}


