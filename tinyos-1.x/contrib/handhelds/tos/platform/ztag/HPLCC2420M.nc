// $Id: HPLCC2420M.nc,v 1.1 2005/07/29 18:29:31 adchristian Exp $

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
 * Date last modified:  $Revision: 1.1 $
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
    interface HPLUSARTFeedback as USARTFeedback;
    interface MSP430Interrupt as FIFOPInterrupt;
    interface BusArbitration;
  }
}
implementation
{

  norace uint8_t* rxbuf;
  norace uint8_t* txbuf;
  norace uint8_t* rambuf;
  norace uint8_t* rxrambuf;
  norace uint8_t txlen;
  norace uint8_t rxlen;
  norace uint8_t ramlen;
  norace uint16_t ramaddr;
  norace uint8_t rxramlen;
  norace uint16_t rxramaddr;
  norace uint8_t txDoneFlag;
  norace uint8_t rxDoneFlag;
  
  //#define WAIT_TX_FLAG() {while (!txDoneFlag); atomic{ txDoneFlag=0;}}
  //#define WAIT_RX_FLAG() {while (!rxDoneFlag);atomic{rxDoneFlag=0;}}
  
  //#define WAIT_TX_FLAG() {while (!txDoneFlag); txDoneFlag=0;}
  //#define WAIT_RX_FLAG() {while (!rxDoneFlag);rxDoneFlag=0;}
#define WAIT_TX_FLAG() {TOSH_uwait(300);}
  
  command result_t StdControl.init() {
    TOSH_SET_RADIO_CSN_PIN();
    TOSH_MAKE_RADIO_CSN_OUTPUT();
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    atomic{
      txDoneFlag = 0;
      rxDoneFlag = 0;
    }
    
    return SUCCESS;
  } 

  command result_t StdControl.start() {
    TOSH_SET_RADIO_CSN_PIN();
    TOSH_MAKE_RADIO_CSN_OUTPUT();
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
    call USARTControl.disableSPI();
    return SUCCESS;
  }

 /**
  * function: enableFIFOP
  *  enable CC2420 fifop interrupt
  */
  async command result_t HPLCC2420.enableFIFOP(){
    // set FIFOP to a rising edge interrupt
    atomic {
      call FIFOPInterrupt.disable();
      call FIFOPInterrupt.clear();
      call FIFOPInterrupt.edge(FALSE);
      call FIFOPInterrupt.enable();

      if ( !(call FIFOPInterrupt.getValue()) && 
	   !(call FIFOPInterrupt.getPending())) {
	call FIFOPInterrupt.setPending();
      }
    }
    return SUCCESS;
  }

  /**
   * function: disbleFIFOP
   *  disable CC2420 fifop interrupt
   */
  async command result_t HPLCC2420.disableFIFOP(){
    // disable FIFOP interrupt
    call FIFOPInterrupt.disable();
    return SUCCESS;
  }

  inline void sendCommand() {
  }

  /**
   * Send a command strobe
   * 
   * @return status byte from the chipcon
   */ 
  async command uint8_t HPLCC2420.cmd(uint8_t addr) {
    uint8_t status = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr);


      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      status = call USARTControl.rx();
      TOSH_SET_RADIO_CSN_PIN();
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
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      status = call USARTControl.rx();
      call USARTControl.tx((data >> 8) & 0x0FF);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      call USARTControl.tx(data & 0x0FF);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      TOSH_SET_RADIO_CSN_PIN();
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
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(addr | 0x40);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      call USARTControl.rx();
      call USARTControl.tx(0);
      WAIT_TX_FLAG();      
      //TOSH_uwait(250);
      data = (call USARTControl.rx() << 8) & 0xFF00;
      call USARTControl.tx(0);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      data = data | (call USARTControl.rx() & 0x0FF);
      WAIT_TX_FLAG();
      TOSH_SET_RADIO_CSN_PIN();
      call BusArbitration.releaseBus();
    }
    return data;      
  }

  task void signalRAMRd() {
    signal HPLCC2420RAM.readDone(rxramaddr, rxramlen, rxrambuf);
  }

  async command result_t HPLCC2420RAM.read(uint16_t addr, uint8_t length, uint8_t* buffer) {
    uint8_t i = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
        rxramaddr = addr;
        rxramlen = length;
        rxrambuf = buffer;
      }

      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();

      call USARTControl.tx((rxramaddr & 0x7F) | 0x80);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      call USARTControl.rx();
      call USARTControl.tx(((rxramaddr >> 1) & 0xC0) | 0x20);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      call USARTControl.rx();

      if (rxramlen > 0) {
        for (i = 0; i < rxramlen; i++) {
          call USARTControl.tx(0);
	  WAIT_TX_FLAG();
          //TOSH_uwait(250);
          rxrambuf[i] = call USARTControl.rx();
        }
      }
      TOSH_SET_RADIO_CSN_PIN();    
      call BusArbitration.releaseBus();
      return post signalRAMRd();
    }
    return FAIL;
  }

  task void signalRAMWr() {
    signal HPLCC2420RAM.writeDone(ramaddr, ramlen, rambuf);
  }

  async command result_t HPLCC2420RAM.write(uint16_t addr, uint8_t length, uint8_t* buffer) {
    uint8_t i = 0;
    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
        ramaddr = addr;
        ramlen = length;
        rambuf = buffer;
      }
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx((ramaddr & 0x7F) | 0x80);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      call USARTControl.tx(((ramaddr >> 1) & 0xC0));
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      for (i = 0; i < ramlen; i++) {
        call USARTControl.tx(rambuf[i]);
	WAIT_TX_FLAG();
	//TOSH_uwait(250);       
      }
      TOSH_uwait(250);
      TOSH_SET_RADIO_CSN_PIN();
      call BusArbitration.releaseBus();
      return post signalRAMWr();
    }
    return FAIL;
  }

  task void signalRXFIFO() {
    signal HPLCC2420FIFO.RXFIFODone(rxlen, rxbuf);
  }

  /**
   * Read from the RX FIFO queue.  Will read bytes from the queue
   * until the length is reached (determined by the first byte read).
   * RXFIFODone() is signalled when all bytes have been read or the
   * end of the packet has been reached.
   *
   * @param length number of bytes requested from the FIFO
   * @param data buffer bytes should be placed into
   *
   * @return SUCCESS if the bus is free to read from the FIFO
   */
  async command result_t HPLCC2420FIFO.readRXFIFO(uint8_t length, uint8_t *data) {
    uint8_t i;
    if (call BusArbitration.getBus() == SUCCESS) {
      atomic rxbuf = data;
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(CC2420_RXFIFO | 0x40);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      rxlen = call USARTControl.rx();
      call USARTControl.tx(0);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      // get the length of the buffer
      rxlen = call USARTControl.rx();
      if (rxlen > 0) {
        rxbuf[0] = rxlen;
        // total length including the length byte
        rxlen++;
        // protect against writing more bytes to the buffer than we have
        if (rxlen > length) rxlen = length;
        for (i = 1; i < rxlen; i++) {
          call USARTControl.tx(0);
	  WAIT_TX_FLAG();
          //TOSH_uwait(250);
          rxbuf[i] = call USARTControl.rx();
        }
      }
      TOSH_SET_RADIO_CSN_PIN();    
      call BusArbitration.releaseBus();
    }
    else {
      return FAIL;
    }
    if (rxlen > 0) {
      return post signalRXFIFO();
    }
    else {
      return FAIL;
    }
  }

  task void signalTXFIFO() {
    signal HPLCC2420FIFO.TXFIFODone(txlen, txbuf);
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
    if (call BusArbitration.getBus() == SUCCESS) {
      atomic {
        txlen = length;
        txbuf = data;
      }
      TOSH_CLR_RADIO_CSN_PIN();
      // clear the RX flag if set
      call USARTControl.isTxIntrPending();
      call USARTControl.rx(); //isRxIntrPending();
      call USARTControl.tx(CC2420_TXFIFO);
      WAIT_TX_FLAG();
      //TOSH_uwait(250);
      for (i = 0; i < txlen; i++) {
        call USARTControl.tx(txbuf[i]);
	WAIT_TX_FLAG();
        //TOSH_uwait(250);
      }
      TOSH_uwait(250);
      TOSH_SET_RADIO_CSN_PIN();
      call BusArbitration.releaseBus();
      return post signalTXFIFO();
    }
    return FAIL;
  }


  async event void FIFOPInterrupt.fired() {
    signal HPLCC2420.FIFOPIntr();
    call FIFOPInterrupt.clear();
  }


  event result_t BusArbitration.busFree() {
    return SUCCESS;
  }


  
   async event result_t USARTFeedback.txDone() {
#if 0
     atomic{
       txDoneFlag = 1;
     }
#else
       txDoneFlag = 1;     
#endif
     
     return SUCCESS;
   }
   async event result_t USARTFeedback.rxDone(uint8_t data) {
#if 0
     atomic{
       rxDoneFlag = 1;
     }
#else
     rxDoneFlag = 1;
#endif
     
     return SUCCESS;
   }

  default async event result_t HPLCC2420FIFO.RXFIFODone(uint8_t length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420FIFO.TXFIFODone(uint8_t length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t length, uint8_t *data) { return SUCCESS; }

}
  
