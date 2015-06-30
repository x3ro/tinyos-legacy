// $Id: HPLSTM25PM.nc,v 1.1 2006/08/03 19:16:50 ayer1 Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module HPLSTM25PM {
  provides {
    interface StdControl;
    interface HPLSTM25P;
  }
  uses {
    interface BusArbitration;
    interface HPLUSARTControl as USARTControl;    
    interface Leds;
  }
}

implementation {

  command result_t StdControl.init() { 
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 
    call USARTControl.setModeSPI();
    call USARTControl.disableRxIntr();
    call USARTControl.disableTxIntr();
    return SUCCESS; 
  }

  command result_t StdControl.stop() { 
    call USARTControl.disableSPI();
    return SUCCESS; 
  }

  async command result_t HPLSTM25P.getBus() {
    return call BusArbitration.getBus();
  }
  
  async command result_t HPLSTM25P.releaseBus() {
    return call BusArbitration.releaseBus();
  }

  async command void HPLSTM25P.beginCmd() {
    TOSH_CLR_FLASH_CS_PIN();
    call HPLSTM25P.unhold();
  }

  async command void HPLSTM25P.endCmd() {
    while(!(call USARTControl.isTxEmpty()));
    TOSH_SET_FLASH_CS_PIN();
  }

  async command void HPLSTM25P.hold() {
    TOSH_CLR_FLASH_HOLD_PIN();
  }

  async command void HPLSTM25P.unhold() {
    TOSH_SET_FLASH_HOLD_PIN();
  }
  
  async command void HPLSTM25P.txBuf(void* buf, stm25p_addr_t len) {
    
    uint8_t* tmpBuf = buf;
    
    call USARTControl.isTxIntrPending();
    for ( ; len; len-- ) {
      call USARTControl.tx(*tmpBuf++);
      while(!(call USARTControl.isTxIntrPending()));
    }

  }

  async command uint16_t HPLSTM25P.rxBuf(void* buf, stm25p_addr_t len, uint16_t crc) {

    uint8_t* tmpBuf = buf;
    uint8_t tmp;

    call USARTControl.rx(); // clear receive interrupt
    call USARTControl.tx(0);
    for ( ; len > 0; len-- ) {
      atomic {
	while(!call USARTControl.isTxIntrPending());
	call USARTControl.tx(0);
	while(!call USARTControl.isRxIntrPending());
	tmp = call USARTControl.rx();
      }
      if (buf != NULL)
	*tmpBuf++ = tmp;
      else
	crc = crcByte(crc, tmp);
    }

    return crc;

  }

  event result_t BusArbitration.busFree() { return SUCCESS; }

}
