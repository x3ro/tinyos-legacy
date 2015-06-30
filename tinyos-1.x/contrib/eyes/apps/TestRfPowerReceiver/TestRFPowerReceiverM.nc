/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Description ----------------------------------------------------------
 * Basic Application testing functionality of RFPower setting for radio
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/03/17 16:42:35 $
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module TestRFPowerReceiverM {
  provides {
    interface StdControl;
  }
  uses {
    interface RawDump;
    interface Leds;
    interface PacketRx;
    interface TDA5250Modes;
    interface RSSImV;
    interface ByteComm;    
  }
}

implementation {

  norace uint16_t rssiVal;
  norace uint16_t dataVal;
  
  task void DumpTask();

  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;  
  }

  command result_t StdControl.stop() {
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/
  
  event result_t TDA5250Modes.ready() {    
    call RawDump.init('\t',TRUE);   
    call TDA5250Modes.RxMode();  
    return SUCCESS;  
  }  
  
  event result_t TDA5250Modes.RxModeDone(){ 
     call PacketRx.reset();  
     return SUCCESS;
  }
  
  async event result_t PacketRx.detected() {
    call Leds.redToggle();    
    call RSSImV.getData();  
    return SUCCESS;
  }
  
  async event result_t RSSImV.dataReady(uint16_t data) {
    call Leds.greenToggle();  
    atomic rssiVal = data;  
    return SUCCESS;
  }
 
  task void DumpTask() {
/*  
    call RawDump.dumpString("\n******************\n");  
    call RawDump.dumpString("RFPower Value: ");  
    call RawDump.dumpNumAsASCII(dataVal);  
    call RawDump.dumpString("\nRSSI Value: ");    
    call RawDump.dumpNumAsASCII(rssiVal);       
    call RawDump.dumpString("\n******************\n");   
*/
    call RawDump.dumpNumAsASCII(dataVal);
    call RawDump.dumpNumAsASCII(rssiVal);    
    call RawDump.dumpString("\n");    
  }
  
  async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) { 
    atomic dataVal = data;    
    post DumpTask();
    call PacketRx.reset();
    return SUCCESS;
  }
  
  async event result_t ByteComm.txByteReady(bool success) {
    return success;
  }
  
  async event result_t ByteComm.txDone() {
    return SUCCESS;
  }   
  
  async event void TDA5250Modes.interrupt() {
  } 
  
  event result_t TDA5250Modes.SleepModeDone(){
     return SUCCESS;
  }
  event result_t TDA5250Modes.CCAModeDone(){
     return SUCCESS;
  }  
}


