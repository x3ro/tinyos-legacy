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
module RadioTimingC
{
  provides interface RadioTiming;
}
implementation
{

  event_t* radioTimingEvents[TOSNODES] __attribute__ ((C));
  
  command uint16_t RadioTiming.getTiming() {
    event_t* fevent;
    long long ftime;

    if (radioTimingEvents[NODE_NUM] != NULL) {
      dbg(DBG_ERROR, "radioTIMING is in bad shape...");
    }

    fevent = (event_t*)malloc(sizeof(event_t));

    //adding 400 clock ticks so that from this time to 'tos_state.tos_time + 400', all 1's
    //received will be ignored
    ftime = tos_state.tos_time + 400;
    event_radio_timing_create(fevent, NODE_NUM, ftime, 0);
    TOS_queue_insert_event(fevent);
    
    radioTimingEvents[NODE_NUM] = fevent;
    
    return SUCCESS;

    //enable input capture.
    //	
    //cbi(DDRB, 4);
    //while(TOSH_READ_RFM_RXD_PIN()) { }
    //outp(0x41, TCCR1B);
    //sbi(TIFR, ICF1);
    //wait for the capture.
    //while((inp(TIFR) & (0x1 << ICF1)) == 0) { }
    //sbi(PORTB, 6);
    //cbi(PORTB, 6);
    //return __inw_atomic(ICR1L);
  }

  command uint16_t RadioTiming.currentTime() {
    //return __inw_atomic(TCNT1L);
    return tos_state.tos_time;
  }

  void event_radio_timing_handle(event_t* fevent,
				struct TOS_state* state) {
    event_queue_t* queue = &(state->queue);
    radio_timing_data_t* data = (radio_timing_data_t*)fevent->data;

    if (data->valid) {
      if(dbg_active(DBG_RADIO)) {
	char ftime[128];
	ftime[0] = 0;
	printTime(ftime, 128);
	dbg(DBG_RADIO, "RADIO: radio timing event handled for mote %i at %s with interval of %i.\n", fevent->mote, ftime, data->interval);
	//dbg(DBG_RADIO, "RADIO: radio timing event handled for mote %i at %lli\n", fevent->mote, fevent->time);
      }
      
      event_radio_timing_invalidate(fevent);
      radioTimingEvents[NODE_NUM] = NULL;
      fevent->time = fevent->time + data->interval;
      queue_insert_event(queue, fevent);

      radioWaitingState[NODE_NUM] = WAITING_FOR_ONE_TO_CAPTURE;
      //finishedTiming is defined in MicaHighSpeedRadioM.td ... prepares SpiByteFifo for shifting in bits
      finishedTiming();
      
    }
    else {
      dbg(DBG_RADIO, "RADIO: invalid radio timing event for mote %i at %lli discarded.\n", data->mote, fevent->time);
      
      fevent->cleanup(fevent);
    }
  }
  
  void event_radio_timing_create(event_t* fevent, int mote, long long ftime, int interval) __attribute__ ((C, spontaneous)) {
    //int time = THIS_NODE.time;
  
    radio_timing_data_t* data = (radio_timing_data_t*)malloc(sizeof(radio_timing_data_t));
    dbg(DBG_MEM, "malloc radio timing event data.\n");
    data->interval = interval;
    data->mote = mote;
    data->valid = 1;
    
    fevent->mote = mote;
    fevent->data = data;
    fevent->time = ftime;
    fevent->handle = event_radio_timing_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;
  }
  
  void event_radio_timing_invalidate(event_t* fevent) __attribute__ ((C, spontaneous)) {
    radio_timing_data_t* data = fevent->data;
    data->valid = 0;
  }

}

