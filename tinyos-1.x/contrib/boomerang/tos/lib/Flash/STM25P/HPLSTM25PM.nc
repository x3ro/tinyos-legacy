// $Id: HPLSTM25PM.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

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
    interface ResourceValidate as STM25PValidate;
    interface HPLUSARTControl as USARTControl;
    interface Leds;
  }
}

implementation {

  bool validate( uint8_t rh ) {
    return call STM25PValidate.validateUser( rh );
  }

  command result_t StdControl.init() { 
    return SUCCESS; 
  }
  
  command result_t StdControl.start() { 
    return SUCCESS; 
  }

  command result_t StdControl.stop() { 
    return SUCCESS; 
  }

  async command void HPLSTM25P.beginCmd( uint8_t rh ) {
    if( validate(rh) ) {
      TOSH_CLR_FLASH_CS_PIN();
      call HPLSTM25P.unhold();
    }
  }

  async command void HPLSTM25P.endCmd( uint8_t rh ) {
    if( validate(rh) ) {
      while(!(call USARTControl.isTxEmpty()));
      TOSH_SET_FLASH_CS_PIN();
    }
  }

  async command void HPLSTM25P.hold() {
    TOSH_CLR_FLASH_HOLD_PIN();
  }

  async command void HPLSTM25P.unhold() {
    TOSH_SET_FLASH_HOLD_PIN();
  }
  
  async command void HPLSTM25P.txBuf( uint8_t rh, void* buf, stm25p_addr_t len ) {
    
    if( validate(rh) ) {

      uint8_t* tmpBuf = buf;
      
      call USARTControl.isTxIntrPending();
      for ( ; len; len-- ) {
        call USARTControl.tx(*tmpBuf++);
        while(!(call USARTControl.isTxIntrPending()));
      }
    }

  }

  async command uint16_t HPLSTM25P.rxBuf( uint8_t rh, void* buf, stm25p_addr_t len, uint16_t crc ) {

    if( validate(rh) ) {
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

    }

    return crc;
  }
}

