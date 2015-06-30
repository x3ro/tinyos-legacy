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
 * Test Sender for LPL MAC
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

includes DTClock;

module SenderM {
    provides {
        interface StdControl;
    }
    uses {
        interface TimerMilli as TimeoutTimer;
        interface Leds;
        interface BareSendMsg;
        interface ReceiveMsg;
        interface TDA5250Config;
        interface DTClock;
    }
}
implementation {
#define TIME_BETWEEN_MSGS     2
    norace TOS_Msg sendMsg;  
    norace uint16_t seq_no;
    timeval_t tv;
    unsigned txpower;
    unsigned rxpower;
    bool powerFailed;

    /**
     * Send a Message
     **/
    result_t SendMsg() {
        result_t res;
        sendMsg.length = 20;
        sendMsg.group = 20;
        sendMsg.type = 20;
        sendMsg.seq_num = seq_no;
        sendMsg.addr = TOS_BCAST_ADDR;
        sendMsg.s_addr = TOS_LOCAL_ADDRESS;
        sendMsg.data[0] = 'a';
        sendMsg.data[1] = 'b';
        sendMsg.data[2] = 'c';
        sendMsg.data[3] = 'd';
        sendMsg.data[4] = 'e';
        sendMsg.data[5] = 'f';
        sendMsg.data[6] = 'g';
        sendMsg.data[7] = 'h';
        sendMsg.data[8] = 'i';
        sendMsg.data[9] = 'j';
        sendMsg.data[10] = '0';
        sendMsg.data[11] = '0';
        sendMsg.data[12] = '0';
        sendMsg.data[13] = '0';
        sendMsg.data[14] = 'o';
        sendMsg.data[15] = 'p';
        sendMsg.data[16] = 'q';
        sendMsg.data[17] = 'r';
        sendMsg.data[18] = 's';
        sendMsg.data[19] = 't';
        call DTClock.getTime(&tv);
        sendMsg.time_s = tv.tv_sec;
        sendMsg.time_us = tv.tv_usec;
        res = call BareSendMsg.send(&sendMsg);
        return res;
    }

    task void SendMsgTask()  {
        SendMsg();
    }
    
    task void PowerTask() {
/*        result_t r1, r2;
        r1 = r2 = FAIL;
        if(powerFailed == FALSE) {
            rxpower += 10;
            if(rxpower > 255) {
                rxpower = 106;
                txpower = (txpower+1)%2;
            }
        }
        if(txpower == 0) {
            r1 = call TDA5250Config.UseLowTxPower();
        } else {
            r1 = call TDA5250Config.UseHighTxPower();
        }
        r2 = call TDA5250Config.SetRFPower(rxpower);
        if(r1 == r2 == SUCCESS) {
            powerFailed = FALSE;
        } else {
            powerFailed = TRUE;
        }
        if(powerFailed) post PowerTask();
*/
    }

    event result_t TDA5250Config.ready() {
        return post PowerTask();
    }

    /**
     * Initializing the components. 
     **/
    command result_t StdControl.init() {
        call Leds.init();
        seq_no = 0;
        txpower = 0;
        rxpower = 106;
        powerFailed = FALSE;
        return SUCCESS;
    }

    /**
     * Start the component. Send first message.
     * 
     * @return returns <code>SUCCESS</code> or <code>FAILED</code>
     **/
    command result_t StdControl.start() {
        return call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS);
    }
   
    /**
     * Stop the component. Do nothing.
     * 
     * @return returns <code>SUCCESS</code> or <code>FAILED</code>
     **/   
    command result_t StdControl.stop() {
        return SUCCESS;
    }
   
    task void TimoutTimerTask() {
        if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
            post TimoutTimerTask();   
    }

    /**
     * Message sent. Now set timer to send another random message sometime
     within the next 512 msec
    */
    event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
        seq_no++;
        call Leds.redToggle();
        if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
            post TimoutTimerTask();
        post PowerTask();
        return SUCCESS;
    }  
   
    /**
     * Receive a message, but do nothing
     **/
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
        call Leds.greenToggle();
        return m;
    }
   
    /**
     * Timer fired, so send another random message
     */
    event result_t TimeoutTimer.fired() {
        if(SendMsg() == FAIL)
        {
            if(call TimeoutTimer.setOneShot(TIME_BETWEEN_MSGS) == FAIL)
                post TimoutTimerTask(); 
        }
        return SUCCESS;
    }
}
