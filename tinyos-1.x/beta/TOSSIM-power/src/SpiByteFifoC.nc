// $Id: SpiByteFifoC.nc,v 1.2 2004/04/22 20:05:16 shnayder Exp $

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
module SpiByteFifoC
{
  provides interface SpiByteFifo;
  //uses interface SlavePin;
  uses interface PowerState;
}
implementation
{
  uint8_t nextByte;
  uint8_t state;
  uint8_t spdr;
  uint8_t radioState;
  

  enum {
    IDLE,
    FULL,
    OPEN,
    READING
  };

  enum {
    RADIO_RECEIVING,
    RADIO_SENDING,
    RADIO_IDLE
  };
  
  enum {
    TOSH_BIT_RATE = 20 * 4 / 2 * 5/4,
  };


  TOS_SIGNAL_HANDLER(SIG_SPI,()) {
    uint8_t temp = spdr;
    spdr = nextByte;
    state = OPEN;
    signal SpiByteFifo.dataReady(temp);
  }

  command result_t SpiByteFifo.send(uint8_t data) {
    event_t* fevent;
    long long ftime;

    if(state == OPEN){
      nextByte = data;	
      state = FULL;
      return SUCCESS;
    }if(state == IDLE){
      state = OPEN;
      signal SpiByteFifo.dataReady(0);
      spdr = data;
      radioState = RADIO_SENDING;
      call PowerState.radioTxMode();
      if (spiByteEvents[NODE_NUM] != NULL) {
	event_spi_byte_invalidate(spiByteEvents[NODE_NUM]);
      }
      dbg(DBG_MEM, "malloc spi byte event.\n");
      fevent = (event_t*)malloc(sizeof(event_t));
      
      ftime = tos_state.tos_time + RADIO_TICKS_PER_EVENT;
      event_spi_byte_create(fevent, NODE_NUM, ftime, RADIO_TICKS_PER_EVENT, 0);
      TOS_queue_insert_event(fevent);
      
      spiByteEvents[NODE_NUM] = fevent;
      
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SpiByteFifo.idle() {
    spdr = 0;
    nextByte = 0;
    radioState = RADIO_IDLE;
    // IDLE is equivalent to SLEEP???
    /* Technically, yes, but since everyone is using mica2s, which goes to Rx (at least in terms of power, go to RX here*/
    call PowerState.radioRxMode(); 
    
    state = IDLE;
    nextByte = 0;
    
    if (spiByteEvents[NODE_NUM] != NULL) {
      event_spi_byte_end(spiByteEvents[NODE_NUM]);
      spiByteEvents[NODE_NUM] = NULL;
    }
    
    return SUCCESS;
  }

  command result_t SpiByteFifo.startReadBytes(uint16_t timing) {
    if(state == IDLE){
      //if (spiByteEvents[NODE_NUM] != NULL)
      //dbg(DBG_ERROR, "SpiByteFifo is in a wacked state...\n");
      
      state = READING;
      radioState = RADIO_RECEIVING;
      call PowerState.radioRxMode();      
      spdr = 0;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t SpiByteFifo.txMode() {
    radioState = RADIO_SENDING;
    call PowerState.radioTxMode();
    TOSH_CLR_RFM_CTL0_PIN();
    TOSH_SET_RFM_CTL1_PIN();
    return SUCCESS;
  }

  command result_t SpiByteFifo.rxMode() {
    radioState = RADIO_RECEIVING;
    call PowerState.radioRxMode();
    TOSH_CLR_RFM_TXD_PIN();
    TOSH_MAKE_RFM_TXD_INPUT();
    TOSH_SET_RFM_CTL0_PIN();
    TOSH_SET_RFM_CTL1_PIN();
    return SUCCESS;
  }

  command result_t SpiByteFifo.phaseShift() {
    event_t* fevent;
    long long ftime;
    if (spiByteEvents[NODE_NUM] != NULL) {
      event_spi_byte_invalidate(spiByteEvents[NODE_NUM]);
    }
    dbg(DBG_MEM, "malloc spi byte event.\n");
    fevent = (event_t*)malloc(sizeof(event_t));
    
    ftime = tos_state.tos_time + RADIO_TICKS_PER_EVENT + 50;
    event_spi_byte_create(fevent, NODE_NUM, ftime, RADIO_TICKS_PER_EVENT, 0);
    TOS_queue_insert_event(fevent);
    
    spiByteEvents[NODE_NUM] = fevent;

    return SUCCESS;
  }

  void event_spi_byte_handle(event_t* fevent,
			     struct TOS_state* fstate) __attribute__ ((C, spontaneous)) {
    event_t* nevent;
    long long ftime;
    int i;
    event_queue_t* queue = &(fstate->queue);
    spi_byte_data_t* data = (spi_byte_data_t*)fevent->data;
    uint8_t temp;
    link_t* current_link;
    radioWaitingState[NODE_NUM] = NOT_WAITING;
    if (data->ending) {
      spiByteEvents[NODE_NUM] = NULL;
      tos_state.rfm->stop_transmit(NODE_NUM);
      dbg(DBG_RADIO, "RADIO: Spi Byte event ending for mote %i at %lli discarded.\n", data->mote, fevent->time);
      event_cleanup(fevent);
    }
    
    else if (data->valid) {
      tos_state.rfm->stop_transmit(NODE_NUM);
      if (dbg_active(DBG_RADIO)) {
	char ttime[128];
	ttime[0] = 0;
	printTime(ttime, 128);
	dbg(DBG_RADIO, "RADIO: Spi Byte event handled for mote %i at %s with interval of %i.\n", fevent->mote, ttime, data->interval);
	//dbg(DBG_RADIO, "RADIO: Spi Byte event handled for mote %i at %lli\n", fevent->mote, fevent->time);
      }
      
      if (radioState == RADIO_RECEIVING) {
	temp = TOSH_rfm_rx_bit();
	temp &= 0x01;
	spdr <<= 1;
	spdr |= temp;
	
      }
      else if (radioState == RADIO_SENDING) {
	temp = (spdr >> 0x7) & 0x1;
	TOSH_rfm_tx_bit(temp);
	spdr <<= 1;
	
	//if transmitting a 1, check to see if it is necessary to update other mote's events...
	if (temp) {
	  current_link = tos_state.rfm->neighbors(NODE_NUM);
	  while (current_link) {
	    i = current_link->mote;
	    if ((radioWaitingState[i] == WAITING_FOR_ONE_TO_CAPTURE) &&
		(spiByteEvents[i] == NULL || spiByteEvents[i]->time > tos_state.tos_time + 419)) {
	      if (spiByteEvents[i] != NULL) {
		event_spi_byte_invalidate(spiByteEvents[i]);
	      }
	      dbg(DBG_MEM, "malloc spi byte event.\n");
	      nevent = (event_t*)malloc(sizeof(event_t));
	      ftime = tos_state.tos_time + 419;
	      event_spi_byte_create(nevent, i, ftime, RADIO_TICKS_PER_EVENT, 0);
	      TOS_queue_insert_event(nevent);
	      
	      spiByteEvents[i] = nevent;	    
	    }
	    current_link = current_link->next_link;
	  }
	}
      }
      else {
	dbg(DBG_ERROR, "SpiByteFifo is seriously wacked\n");
      }
      
      
      if (data->count == 7) {
	TOS_ISSUE_SIGNAL(SIG_SPI)();
      }
      
      data->count = (data->count+1) & 0x07;
      fevent->time = fevent->time + data->interval;
      queue_insert_event(queue, fevent);
      
    }
    else {
      dbg(DBG_RADIO, "RADIO: invalid Spi Byte event for mote %i at %lli discarded.\n", data->mote, fevent->time);
      
      event_cleanup(fevent);
    }
  }
  
  void event_spi_byte_create(event_t* fevent, int mote, long long ftime, int interval, int count) __attribute__ ((C, spontaneous)) {
    //int time = THIS_NODE.time;
    
    spi_byte_data_t* data = (spi_byte_data_t*)malloc(sizeof(spi_byte_data_t));
    dbg(DBG_MEM, "malloc Spi Byte event data.\n");
    data->interval = interval;
    data->mote = mote;
    data->valid = 1;
    data->count = count;
    data->ending = 0;
    
    fevent->mote = mote;
    fevent->data = data;
    fevent->time = ftime;
    fevent->handle = event_spi_byte_handle;
    fevent->cleanup = event_total_cleanup;
    fevent->pause = 0;
  }
  
  void event_spi_byte_invalidate(event_t* fevent) __attribute__ ((C, spontaneous)) {
    spi_byte_data_t* data = fevent->data;
    data->valid = 0;
  }

  void event_spi_byte_end(event_t* fevent) __attribute__ ((C, spontaneous)) {
    spi_byte_data_t* data = fevent->data;
    data->ending = 1;
  }


} 
