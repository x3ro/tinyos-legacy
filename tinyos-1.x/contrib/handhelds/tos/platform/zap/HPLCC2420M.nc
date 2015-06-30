// $Id: HPLCC2420M.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

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
    interface SPI;
    interface ZapInterrupt as FIFOPInterrupt;
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
    atomic{
      txDoneFlag = 0;
      rxDoneFlag = 0;
    }
    
    return SUCCESS;
  } 

  command result_t StdControl.start() {
    TOSH_SET_RADIO_CSN_PIN();
    TOSH_MAKE_RADIO_CSN_OUTPUT();
    return SUCCESS;
  }

  command result_t StdControl.stop() { 
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
      // call FIFOPInterrupt.edge(FALSE);
      call FIFOPInterrupt.enable();
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

      printf("HPLCC2420.cmd\r\n");
      call SPI.startTransfer();
      status = call SPI.transferByte(addr);
      call SPI.endTransfer();

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

      call SPI.startTransfer();
      status = call SPI.transferByte(addr);
      call SPI.transferByte((data >> 8) & 0x0FF);
      call SPI.transferByte(data & 0x0FF);
      call SPI.endTransfer();

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
      call SPI.startTransfer();
      call SPI.transferByte(addr | 0x40);
      data = (call SPI.transferByte(0) << 8) & 0xFF00;
      data = data | (call SPI.transferByte(0) & 0x0FF);
      call SPI.endTransfer();
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

      call SPI.startTransfer();

      call SPI.transferByte((rxramaddr & 0x7F) | 0x80);
      call SPI.transferByte(((rxramaddr >> 1) & 0xC0) | 0x20);

      if (rxramlen > 0) {
        for (i = 0; i < rxramlen; i++) {
          rxrambuf[i] = call SPI.transferByte(0);
        }
      }
      call SPI.endTransfer();
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
      call SPI.startTransfer();
      call SPI.transferByte((ramaddr & 0x7F) | 0x80);
      call SPI.transferByte(((ramaddr >> 1) & 0xC0));
      for (i = 0; i < ramlen; i++) {
        call SPI.transferByte(rambuf[i]);
      }
      call SPI.endTransfer();
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
      call SPI.startTransfer();
      rxlen = call SPI.transferByte(CC2420_RXFIFO | 0x40);
      rxlen = call SPI.transferByte(0);
      if (rxlen > 0) {
        rxbuf[0] = rxlen;
        // total length including the length byte
        rxlen++;
        // protect against writing more bytes to the buffer than we have
        if (rxlen > length) rxlen = length;
        for (i = 1; i < rxlen; i++) {
          rxbuf[i] = call SPI.transferByte(0);
        }
      }
      call SPI.endTransfer();
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
      call SPI.startTransfer();
      call SPI.transferByte(CC2420_TXFIFO);
      for (i = 0; i < txlen; i++) {
	   call SPI.transferByte(txbuf[i]);
      }
      call SPI.endTransfer();
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

  default async event result_t HPLCC2420FIFO.RXFIFODone(uint8_t length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420FIFO.TXFIFODone(uint8_t length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t length, uint8_t *data) { return SUCCESS; }

  default async event result_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t length, uint8_t *data) { return SUCCESS; }

}
  
