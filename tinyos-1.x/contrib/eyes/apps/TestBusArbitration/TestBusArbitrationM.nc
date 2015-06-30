/* -*- mode:c++; indent-tabs-mode: nil -*-
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Test Application for TDA5250 Radio Operation
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2005/09/20 08:32:41 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
module TestBusArbitrationM {
    provides {
        interface StdControl;
    }
    uses {
        interface PageEEPROM;
        interface ReceiveMsg as RadioReceive;
        interface BareSendMsg as RadioSend;
        interface LedsNumbered as Leds;
        interface DTClock;
    }
}
implementation {
#define DATA_LENGTH 25
#define PAGE_NUMBER 3
#define PAGE_OFFSET 25
#define MAX_COUNT 25
  
    TOS_Msg sendMsg;
    uint8_t data[DATA_LENGTH];
    uint16_t count;
  
    void writeToFlash() {
        call PageEEPROM.write(PAGE_NUMBER, PAGE_OFFSET, &data, DATA_LENGTH);  
    }

    task void SendTask();

    command result_t StdControl.init() {
        int i;
        call Leds.init();
    
        for(i=0; i<DATA_LENGTH; i++)
            data[i] = i;
        count = 0;
        sendMsg.length = DATA_LENGTH;
        sendMsg.type = 20;
        sendMsg.addr = TOS_BCAST_ADDR;
        sendMsg.s_addr = TOS_LOCAL_ADDRESS;
        return SUCCESS;
    }

    /**
     * Starts the SensorControl and CommControl components.
     * @return Always returns SUCCESS.
     */
    command result_t StdControl.start() {
        writeToFlash();
        post SendTask();    
        return SUCCESS;
    }

    /**
     * Stops the SensorControl and CommControl components.
     * @return Always returns SUCCESS.
     */
    command result_t StdControl.stop() {
        return SUCCESS;
    }

    task void SendTask() {
        timeval_t tv;
        result_t res;
        call DTClock.getTime(&tv);
        sendMsg.time_s = tv.tv_sec;
        sendMsg.time_us = tv.tv_usec;
        res = call RadioSend.send(&sendMsg);
        if(res == SUCCESS) call Leds.led2Off(); 
    }
    /**
     * Signalled when the reset message counter AM is received.
     * @return The free TOS_MsgPtr. 
     */
    event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr m) {
        call Leds.led0Toggle();
        return m;
    }
  
    event result_t RadioSend.sendDone(TOS_MsgPtr Msg, result_t success) {
        call Leds.led2On();
        post SendTask();
        return SUCCESS;
    }    
  
    event result_t PageEEPROM.writeDone(result_t result) {
        if(count == MAX_COUNT) {
            call Leds.led1Toggle();
            count = 0;
        }
        writeToFlash();
        count++;
        return SUCCESS;
    }

    event result_t PageEEPROM.eraseDone(result_t result) {
        return SUCCESS;
    }

    event result_t PageEEPROM.syncDone(result_t result) {
        return SUCCESS;
    }

    event result_t PageEEPROM.flushDone(result_t result) {
        return SUCCESS;
    }

    event result_t PageEEPROM.readDone(result_t result) {
        return SUCCESS;
    }

    event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
        return SUCCESS;
    }
}


