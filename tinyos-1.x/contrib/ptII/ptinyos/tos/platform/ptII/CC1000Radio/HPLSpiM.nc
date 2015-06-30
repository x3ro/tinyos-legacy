// $Id: HPLSpiM.nc,v 1.1 2005/04/19 01:19:20 celaine Exp $

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
 * Authors: Jaein Jeong, Philip buonadonna
 * Date last modified: $Revision: 1.1 $
 *
 */

/**
 * @author Jaein Jeong
 * @author Philip buonadonna
 */


module HPLSpiM
{
  provides interface SpiByteFifo;
  uses interface PowerManagement;
}
implementation
{
  norace uint8_t OutgoingByte; // Define norace to prevent nesC 1.1 warnings
  norace uint8_t state;
  norace uint8_t intrstate;
  norace uint8_t spdr;
  norace bool b_spif;

  enum {
    RX_STATE,
    TX_STATE
  };

  enum {
    INTR_ENABLED,
    INTR_DISABLED 
  };

  //by brchen: HANDLER for SPI interrupt
  TOS_SIGNAL_HANDLER(SIG_SPI, ()) {
    uint8_t temp = spdr;
    spdr=OutgoingByte;
    signal SpiByteFifo.dataReady(temp);
  }

  async command result_t SpiByteFifo.writeByte(uint8_t data) {
    //while(bit_is_clear(SPSR,SPIF));
    //outp(data, SPDR);
    OutgoingByte = data;
    return SUCCESS;
  }

  async command result_t SpiByteFifo.isBufBusy() {
    //by brchen
    //return bit_is_clear(SPSR,SPIF);
    return b_spif;
    //return SUCCESS;
  }

  async command uint8_t SpiByteFifo.readByte() {
    //return inp(SPDR);
    return spdr;
  }

  async command result_t SpiByteFifo.enableIntr() {
    //sbi(SPCR,SPIE);
    //outp(0xC0, SPCR);
    //cbi(DDRB, 0);

    intrstate = INTR_ENABLED;
    call PowerManagement.adjustPower();
    return SUCCESS;
  }

  async command result_t SpiByteFifo.disableIntr() {
    //cbi(SPCR, SPIE);
    //sbi(DDRB, 0);
    //cbi(PORTB, 0);
    intrstate = INTR_DISABLED;
    call PowerManagement.adjustPower();
    return SUCCESS;
  }

  async command result_t SpiByteFifo.initSlave() {

    event_t* fevent;
    long long ftime;

    //initialize states
    state = RX_STATE;
    intrstate = INTR_DISABLED;
    spdr = 0;
    b_spif = FALSE;

    //start the spi sampling event loop
    // VS: Put in atomics to get rid of silly warnings (Can't declare
    // spiByteEvents norace since it's defined in C code in hpl.c)
    atomic {
      if (spiByteEvents[NODE_NUM] != NULL) {
	event_spi_byte_invalidate(spiByteEvents[NODE_NUM]);
      }
    }
    dbg(DBG_MEM, "malloc spi byte event.\n");
    fevent = (event_t*)malloc(sizeof(event_t));
    
    ftime = tos_state.tos_time + RADIO_TICKS_PER_EVENT;
    event_spi_byte_create(fevent, NODE_NUM, ftime, RADIO_TICKS_PER_EVENT, 0);
    TOS_queue_insert_event(fevent);
    atomic{
      spiByteEvents[NODE_NUM] = fevent;
    }


  //by brchen:
  /*
    atomic {
      TOSH_MAKE_SPI_SCK_INPUT();
      TOSH_MAKE_MISO_INPUT();	// miso
      TOSH_MAKE_MOSI_INPUT();	// mosi
      cbi(SPCR, CPOL);		// Set proper polarity...
      cbi(SPCR, CPHA);		// ...and phase
      sbi(SPCR, SPIE);	// enable spi port
      sbi(SPCR, SPE);
    }*/ 
    return SUCCESS;
  }
	
  async command result_t SpiByteFifo.txMode() {
    state = TX_STATE;
    /* by brchen
    TOSH_MAKE_MISO_OUTPUT();
    TOSH_MAKE_MOSI_OUTPUT();*/
    return SUCCESS;
  }

  async command result_t SpiByteFifo.rxMode() {
    state = RX_STATE;
    /*by brchen
    TOSH_MAKE_MISO_INPUT();
    TOSH_MAKE_MOSI_INPUT();*/
    
    return SUCCESS;
  }

//modified from SpiByteFifoC.nc

  void event_spi_byte_handle(event_t* fevent,
			     struct TOS_state* fstate) __attribute__ ((C, spontaneous)) {
    event_queue_t* queue = &(fstate->queue);
    spi_byte_data_t* data = (spi_byte_data_t*)fevent->data;
    uint8_t temp;
    radioWaitingState[NODE_NUM] = NOT_WAITING;
    if (data->ending) {
      atomic {
	spiByteEvents[NODE_NUM] = NULL;
      }
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
      
      //if (radioState == RADIO_RECEIVING) {
      if (state == RX_STATE) {
	temp = TOSH_rfm_rx_bit();
	temp &= 0x01;
	spdr <<= 1;
	spdr |= temp;
      }
      //else if (radioState == RADIO_SENDING) {
      else if (state == TX_STATE) {
	temp = (spdr >> 0x7) & 0x1;
	TOSH_rfm_tx_bit(temp);
	spdr <<= 1;
      }
      else {
	dbg(DBG_ERROR, "SpiByteFifo is seriously wacked\n");
      }
      
      
      if (data->count == 7) {
        //only when interrupt is enabled
        if(intrstate == INTR_ENABLED)
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
