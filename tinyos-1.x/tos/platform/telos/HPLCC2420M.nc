// $Id: HPLCC2420M.nc,v 1.19 2005/04/11 05:21:16 jpolastre Exp $

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
 * Authors: Joe Polastre
 * Date last modified:  $Revision: 1.19 $
 *
 */

/**
 * @author Joe Polastre
 */

module HPLCC2420M {
  provides {
    interface StdControl;
    interface HPLCC2420;
    interface HPLCC2420RAM;
    interface HPLCC2420FIFO;
  }
  uses {
    interface HPLUSARTControl as USARTControl;
    interface BusArbitration;
  }
}
implementation
{

  norace uint8_t* txbuf;
  norace uint8_t* rxbuf;
  norace uint8_t* rambuf;
  norace uint8_t* rxrambuf;
  norace uint8_t txlen;
  norace uint8_t rxlen;
  norace uint8_t ramlen;
  norace uint16_t ramaddr;
  norace uint8_t rxramlen;
  norace uint16_t rxramaddr;

  norace struct {
    bool enabled : 1;
    bool busy : 1;
    bool rxbufBusy : 1;
    bool txbufBusy : 1;
  } f; // f for flags

  /** 
   * Zero out the reserved bits since they can be either 0 or 1.
   * This allows the use of "if !cmd(x)" in the radio stack
   */
  uint8_t adjustStatusByte(uint8_t status) {
    return status & 0x7E;
  }

  command result_t StdControl.init() {
    atomic {
      f.busy = f.enabled = f.rxbufBusy = f.txbufBusy = FALSE;
    }

    TOSH_SET_RADIO_CSN_PIN();
    TOSH_MAKE_RADIO_CSN_OUTPUT();
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    return SUCCESS;
  } 

  command result_t StdControl.start() {
    atomic {
      if (!f.busy) {
	TOSH_SET_RADIO_CSN_PIN();
	TOSH_MAKE_RADIO_CSN_OUTPUT();
	call USARTControl.setModeSPI();
	call USARTControl.disableRxIntr();
	call USARTControl.disableTxIntr();
	f.busy = f.rxbufBusy = f.txbufBusy = FALSE;
	f.enabled = TRUE;
      }
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
    atomic {
      // if we're not in the middle of doing something, we can shut off the
      // SPI operations too
      if (!f.busy)
	call USARTControl.disableSPI();
      f.enabled = FALSE;
    }
    return SUCCESS;
  }

  /**
   * Send a command strobe
   * 
   * @return status byte from the chipcon
   */ 
  async command uint8_t HPLCC2420.cmd(uint8_t addr) {
    uint8_t status = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
#if 1
      atomic f.busy = TRUE;
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      status = adjustStatusByte(call USARTControl.rx());
      TOSH_SET_RADIO_CSN_PIN();
      atomic f.busy = FALSE;
#endif
#if 0
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr);
      TOSH_uwait(20);
      status = adjustStatusByte(call USARTControl.rx());
      TOSH_SET_RADIO_CSN_PIN();
#endif
      call BusArbitration.releaseBus();
    }
    return status;
  }

  /**
   * Transmit 16-bit data
   *
   * @return status byte from the chipcon.  0xff is return of command failed.
   */
  async command uint8_t HPLCC2420.write(uint8_t addr, uint16_t data) {
    uint8_t status = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
#if 1
      atomic f.busy = TRUE;
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx();
      call USARTControl.tx(addr);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      status = adjustStatusByte(call USARTControl.rx());
      call USARTControl.tx((data >> 8) & 0x0FF);
      while(f.enabled && !(call USARTControl.isTxIntrPending())) ;
      call USARTControl.tx(data & 0x0FF);
      while(f.enabled && !(call USARTControl.isTxEmpty())) ;
      TOSH_SET_RADIO_CSN_PIN();
      atomic f.busy = FALSE;
#endif
#if 0
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr);
      TOSH_uwait(20);
      status = adjustStatusByte(call USARTControl.rx());
      call USARTControl.tx((data >> 8) & 0x0FF);
      TOSH_uwait(20);
      call USARTControl.tx(data & 0x0FF);
      TOSH_uwait(20);
      TOSH_SET_RADIO_CSN_PIN();
#endif
      call BusArbitration.releaseBus();
    }
    return status;
  }
  
  /**
   * Read 16-bit data
   *
   * @return 16-bit register value
   */
  async command uint16_t HPLCC2420.read(uint8_t addr) {
    uint16_t data = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
#if 1
      atomic f.busy = TRUE;
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr | 0x40);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      call USARTControl.rx();
      call USARTControl.tx(0);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      data = (call USARTControl.rx() << 8) & 0xFF00;
      call USARTControl.tx(0);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      data = data | (call USARTControl.rx() & 0x0FF);
      TOSH_SET_RADIO_CSN_PIN();
      atomic f.busy = FALSE;
#endif
#if 0
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr | 0x40);
      TOSH_uwait(20);
      call USARTControl.rx();
      call USARTControl.tx(0);
      TOSH_uwait(20);
      data = (call USARTControl.rx() << 8) & 0xFF00;
      call USARTControl.tx(0);
      TOSH_uwait(20);
      data = data | (call USARTControl.rx() & 0x0FF);
      TOSH_SET_RADIO_CSN_PIN();
#endif
      call BusArbitration.releaseBus();
    }
    return data;      
  }

  task void signalRAMRd() {
    signal HPLCC2420RAM.readDone(rxramaddr, rxramlen, rxrambuf);
  }

  async command result_t HPLCC2420RAM.read(uint16_t addr, uint8_t _length, uint8_t* buffer) {
    uint8_t i = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
	f.busy = TRUE;
        rxramaddr = addr;
        rxramlen = _length;
        rxrambuf = buffer;
      }

      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();

      call USARTControl.tx((rxramaddr & 0x7F) | 0x80);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      call USARTControl.rx();
      call USARTControl.tx(((rxramaddr >> 1) & 0xC0) | 0x20);
      while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
      call USARTControl.rx();

      if (rxramlen > 0) {
        for (i = 0; i < rxramlen; i++) {
          call USARTControl.tx(0);
	  while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
          rxrambuf[i] = call USARTControl.rx();
        }
      }
      TOSH_SET_RADIO_CSN_PIN();    
      call BusArbitration.releaseBus();
      atomic f.busy = FALSE;
      return post signalRAMRd();
    }
    return FAIL;
  }

  task void signalRAMWr() {
    signal HPLCC2420RAM.writeDone(ramaddr, ramlen, rambuf);
  }

  async command result_t HPLCC2420RAM.write(uint16_t addr, uint8_t _length, uint8_t* buffer) {
    uint8_t i = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
	f.busy = TRUE;
        ramaddr = addr;
        ramlen = _length;
        rambuf = buffer;
      }
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx((ramaddr & 0x7F) | 0x80);
      while(f.enabled && !(call USARTControl.isTxIntrPending())) ;
      call USARTControl.tx(((ramaddr >> 1) & 0xC0));
      while(f.enabled && !(call USARTControl.isTxIntrPending())) ;
      for (i = 0; i < ramlen; i++) {
        call USARTControl.tx(rambuf[i]);
	while(f.enabled && !(call USARTControl.isTxIntrPending())) ;
      }
      while(f.enabled && !(call USARTControl.isTxEmpty())) ;
      TOSH_SET_RADIO_CSN_PIN();
      call BusArbitration.releaseBus();
      atomic f.busy = FALSE;
      return post signalRAMWr();
    }
    return FAIL;
  }

  task void signalRXFIFO() {
    uint8_t _rxlen;
    uint8_t* _rxbuf;

    atomic {
      _rxlen = rxlen;
      _rxbuf = rxbuf;
      f.rxbufBusy = FALSE;
    }

    signal HPLCC2420FIFO.RXFIFODone(_rxlen, _rxbuf);
  }

  async command result_t HPLCC2420FIFO.readRXFIFO(uint8_t length, uint8_t *data) {
    uint8_t i;
    bool returnFail = FALSE;

    atomic {
      if (f.rxbufBusy)
	returnFail = TRUE;
      else
	f.rxbufBusy = TRUE;
    }

    if (returnFail)
      return FAIL;

    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
	f.busy = TRUE;
	rxbuf = data;
	TOSH_CLR_RADIO_CSN_PIN();
	// clear the RX flag if set
	call USARTControl.isTxIntrPending();
	call USARTControl.rx(); //isRxIntrPending();
	call USARTControl.tx(CC2420_RXFIFO | 0x40);
	while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
	rxlen = call USARTControl.rx();
	call USARTControl.tx(0);
	while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
	// get the length of the buffer
	rxlen = call USARTControl.rx();
     }
      if (rxlen > 0) {
        rxbuf[0] = rxlen;
        // total length including the length byte
        rxlen++;
        // protect against writing more bytes to the buffer than we have
        if (rxlen > length) rxlen = length;
        for (i = 1; i < rxlen; i++) {
	  atomic {
	    call USARTControl.tx(0);
	    while(f.enabled && !(call USARTControl.isRxIntrPending())) ;
	    rxbuf[i] = call USARTControl.rx();
	  }
        }
      }
      TOSH_SET_RADIO_CSN_PIN();    
      atomic f.busy = FALSE;
      call BusArbitration.releaseBus();
    }
    else {
      atomic f.rxbufBusy = FALSE;
      return FAIL;
    }
    if (post signalRXFIFO() == FAIL) {
      atomic f.rxbufBusy = FALSE;
      return FAIL;
    }
    return SUCCESS;
  }

  task void signalTXFIFO() {
    uint8_t _txlen;
    uint8_t* _txbuf;

    atomic {
      _txlen = txlen;
      _txbuf = txbuf;
      f.txbufBusy = FALSE;
    }

    signal HPLCC2420FIFO.TXFIFODone(_txlen, _txbuf);
  }

  /**
   * Writes a series of bytes to the transmit FIFO.
   *
   * @param length length of data to be written
   * @param data the first byte of data
   *
   * @return SUCCESS if the bus is free to write to the FIFO
   */
  async command result_t HPLCC2420FIFO.writeTXFIFO(uint8_t length, uint8_t *data) {
    uint8_t i = 0;
    bool returnFail = FALSE;

    atomic {
      if (f.txbufBusy)
	returnFail = TRUE;
      else
	f.txbufBusy = TRUE;
    }

    if (returnFail)
      return FAIL;

    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
	f.busy = TRUE;
        txlen = length;
        txbuf = data;
      }
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(CC2420_TXFIFO);
      while(f.enabled && !(call USARTControl.isTxIntrPending())) ;
      for (i = 0; i < txlen; i++) {
        call USARTControl.tx(txbuf[i]);
        while(f.enabled && !(call USARTControl.isTxIntrPending())) ;
      }
      while(f.enabled && !(call USARTControl.isTxEmpty())) ;
      TOSH_SET_RADIO_CSN_PIN();
      call BusArbitration.releaseBus();
      atomic f.busy = FALSE;
    }
    else {
      atomic f.txbufBusy = FALSE;
      return FAIL;
    }
    if (post signalTXFIFO() == FAIL) {
      atomic f.txbufBusy = FALSE;
      return FAIL;
    }
    return SUCCESS;
  }

  event result_t BusArbitration.busFree() {
    return SUCCESS;
  }

  default async event result_t HPLCC2420FIFO.RXFIFODone(uint8_t _length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420FIFO.TXFIFODone(uint8_t _length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t _length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t _length, uint8_t *data) { return SUCCESS; }

}
  
