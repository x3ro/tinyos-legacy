// $Id: RadioTimingC.nc,v 1.1.1.1 2007/11/05 19:10:35 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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

  norace event_t* radioTimingEvents[TOSNODES] __attribute__ ((C));
  
  async command uint16_t RadioTiming.getTiming() {
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

  async command uint16_t RadioTiming.currentTime() {
    //return __inw_atomic(TCNT1L);
    return tos_state.tos_time;
  }

  // for some reason this is needed for MHSRTinySec to compile for pc
  result_t finishedTiming() __attribute__ ((C,spontaneous));

  void event_radio_timing_handle(event_t* fevent,
				struct TOS_state* state) {
    event_t* nevent;
    long long ntime;
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

      if (spiByteEvents[NODE_NUM] != NULL) {
	event_spi_byte_invalidate(spiByteEvents[NODE_NUM]);
      }

      dbg(DBG_MEM, "malloc spi byte event.\n");
      nevent = (event_t*)malloc(sizeof(event_t));
      
      ntime = tos_state.tos_time + 819;
      event_spi_byte_create(nevent, NODE_NUM, ntime, RADIO_TICKS_PER_EVENT, 0);
      TOS_queue_insert_event(nevent);
      
      spiByteEvents[NODE_NUM] = nevent;	    
      //finishedTiming is defined in MicaHighSpeedRadioM.td ... prepares SpiByteFifo for shifting in bits
      finishedTiming();
      
    }
    else {
      dbg(DBG_RADIO, "RADIO: invalid radio timing event for mote %i at %lli discarded.\n", data->mote, fevent->time);
      
      event_cleanup(fevent);
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

