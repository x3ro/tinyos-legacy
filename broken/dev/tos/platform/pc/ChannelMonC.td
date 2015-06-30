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
/*
 *
 */

module ChannelMonC {
  provides interface ChannelMon;
  uses {
    interface Random;
  }
}
implementation {
  enum {
    IDLE_STATE,
    START_SYMBOL_SEARCH,
    PACKET_START,
    DISABLED_STATE
  };

  enum {
    SAMPLE_RATE = 100/2*4
  };
  event_t* channelMonEvents[TOSNODES];
  unsigned short CM_search[2];
  char CM_state;
  unsigned char CM_lastBit;
  unsigned char CM_startSymBits;
  short CM_waiting;

  command result_t ChannelMon.init() {
    CM_waiting = -1;
    return call ChannelMon.startSymbolSearch();
  }

  command result_t ChannelMon.startSymbolSearch() {
    event_t* fevent;
    long long ftime;
    
    //Reset to idle state.
    CM_state = IDLE_STATE;
    
    if (channelMonEvents[NODE_NUM] != NULL) {
      event_channel_mon_invalidate(channelMonEvents[NODE_NUM]);
    }
    dbg(DBG_MEM, "malloc channel mon event.\n");
    fevent = (event_t*)malloc(sizeof(event_t));
    
    //ChannelMon samples the network at 20 kb/s (200 = 4MHz/20kb/s)
    ftime = tos_state.tos_time + 200;
    
    event_channel_mon_create(fevent, NODE_NUM, ftime, 200);
    TOS_queue_insert_event(fevent);
    
    channelMonEvents[NODE_NUM] = fevent;


    return SUCCESS;
  }
  


  TOS_SIGNAL_HANDLER(SIG_OUTPUT_COMPARE2B, ()) {
    uint8_t bit = TOSH_rfm_rx_bit();
    //fire the bit arrived event and send up the value.
    if (CM_state == IDLE_STATE) {
      CM_search[0] <<= 1;
      CM_search[0] = CM_search[0] | (bit & 0x1);
      if(CM_waiting != -1){
	CM_waiting --;
	if(CM_waiting == 1){
	  if ((CM_search[0] & 0xfff) == 0) {
	    CM_waiting = -1;
	    call ChannelMon.stopMonitorChannel();
	    signal ChannelMon.idleDetect();
	  }else{
	    CM_waiting = (call Random.rand() & 0x1ff) + 50;
	  } 
	}
      }
      if ((CM_search[0] & 0x777) == 0x707){
	CM_state = START_SYMBOL_SEARCH;
	CM_search[0] = CM_search[1] = 0;
	CM_startSymBits = 30;
      }
    }else if(CM_state == START_SYMBOL_SEARCH){
      unsigned int current = CM_search[CM_lastBit];
      CM_startSymBits--;
      if (CM_startSymBits == 0){
	CM_state = IDLE_STATE;
	return;
      }
      current <<= 1;
      current &=  0x1ff;  // start symbol is 9 bits
      if(bit) current |=  0x1;  // start symbol is 9 bits
      if (current == 0x135) {
	call ChannelMon.stopMonitorChannel();
	CM_state = IDLE_STATE;

	radioWaitingState[tos_state.current_node] = WAITING_FOR_ONE_TO_PASS;
	
	signal ChannelMon.startSymDetect();
	return;
      }
      CM_search[CM_lastBit] = current;
      CM_lastBit ^= 1;
    }
    return;
  }
  
  command result_t ChannelMon.stopMonitorChannel() {
    //disable timer
    event_channel_mon_invalidate(channelMonEvents[tos_state.current_node]);
    channelMonEvents[tos_state.current_node] = NULL; 
    
    CM_state = DISABLED_STATE;
    return SUCCESS;
  }
  
  command result_t ChannelMon.macDelay() {
    CM_search[0] = 0xff;
    if(CM_waiting == -1) {
      CM_waiting = (call Random.rand() & 0x3f) + 100;
    }
    return SUCCESS;
  }

  void event_channel_mon_handle(event_t* fevent,
				struct TOS_state* state) {
    event_queue_t* queue = &(state->queue);
    channel_mon_data_t* data = (channel_mon_data_t*)fevent->data;
    if (data->valid) {
      if(dbg_active(DBG_RADIO)) {
	char ftime[128];
	ftime[0] = 0;
	printTime(ftime, 128);
	dbg(DBG_RADIO, "RADIO: Channel Mon event handled for mote %i at %s with interval of %i.\n", fevent->mote, ftime, data->interval);
	//dbg(DBG_RADIO, "RADIO: Channel Mon event handled for mote %i at %lli\n", fevent->mote, fevent->time);
      }
      
      fevent->time = fevent->time + data->interval;
      queue_insert_event(queue, fevent);
      
      TOS_ISSUE_SIGNAL(SIG_OUTPUT_COMPARE2B)();
    }
    else {
      dbg(DBG_RADIO, "RADIO: invalid Channel Mon event for mote %i at %lli discarded.\n", data->mote, fevent->time);
      
      fevent->cleanup(fevent);
    }
  }
  
  void event_channel_mon_create(event_t* fevent, int mote, long long ftime, int interval) __attribute__ ((C, spontaneous)) {
    //int time = THIS_NODE.time;
  
    channel_mon_data_t* data = (channel_mon_data_t*)malloc(sizeof(channel_mon_data_t));
    dbg(DBG_MEM, "malloc Channel Mon event data.\n");
    data->interval = interval;
    data->mote = mote;
    data->valid = 1;
    
    fevent->mote = mote;
    fevent->data = data;
    fevent->time = ftime;
    fevent->handle = event_channel_mon_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;
  }
  
  void event_channel_mon_invalidate(event_t* fevent) __attribute__ ((C, spontaneous)) {
    channel_mon_data_t* data = fevent->data;
    data->valid = 0;
  }
}
  
  
  
