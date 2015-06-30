/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2005/02/03 16:53:20 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module RSSILevelM {
  provides {
    interface StdControl;
    interface RSSILevel;
  }
  uses {
    interface MSP430ADC12Single as RSSIADC;
  }
}
implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call RSSIADC.bind(MSP430ADC12_RSSI_SETTINGS); 
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }  
  
  async command result_t RSSILevel.get() {
    if(call RSSIADC.getData() == MSP430ADC12_FAIL)
       return FAIL;
    return SUCCESS;
  }
  
  async event result_t RSSIADC.dataReady(uint16_t data) {
    signal RSSILevel.getDone(data);
    return SUCCESS;
  }
}

