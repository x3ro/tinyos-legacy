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
 * Test Bouncer for LPL MAC
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

includes DTClock;

module BounceM {
    provides {
        interface StdControl;
    }
    uses {
        interface Leds;
        interface BareSendMsg;
        interface ReceiveMsg;
        interface TDA5250Config;
        interface DTClock;
    }
}
implementation {
    norace TOS_Msg sendMsg;  
    bool sending;
    
    /**
     * Send a Message
     **/
    result_t SendMsg() {
        result_t res;
        res = call BareSendMsg.send(&sendMsg);
        return res;
    }

    task void SendMsgTask()  {
        if(SendMsg() == FAIL) post SendMsgTask();
    }
    
   event result_t TDA5250Config.ready() {
       return SUCCESS;
    }

    /**
     * Initializing the components. 
     **/
    command result_t StdControl.init() {
        call Leds.init();
        sending = FALSE;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }
   
    command result_t StdControl.stop() {
        return SUCCESS;
    }
   
    /**
     * Receive a message, copy fields
     **/
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
        if(!sending && (m->addr == TOS_LOCAL_ADDRESS)) {
            sending = TRUE;
            call Leds.redOn();
            sendMsg.length = 2;
            sendMsg.type = m->type;
            sendMsg.seq_num = m->seq_num;
            sendMsg.addr = m->s_addr;
            sendMsg.s_addr = TOS_LOCAL_ADDRESS;
            sendMsg.data[0] = ((uint8_t *)(&m->strength))[0];
            sendMsg.data[1] = ((uint8_t *)(&m->strength))[1];
            post SendMsgTask();
        }
        return m;
    }

    /**
     * Message sent.
     */
    event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
        sending = FALSE;
        call Leds.redOff();
        return SUCCESS;
    }  
}
