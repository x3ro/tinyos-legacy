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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description --------------------------------------------------------
 * Implementation of Link Layer for PreambleSampleMAC
 *
 * This Link layer assumes
 *  - link speed on air is 19200 bit/s
 *  - a marshaller that handles packet reception, including timeouts
 *  - the sleep time to be around 100 ms
 *  - the wake time to be around 6ms
 *  - a MAC that handles busy channels and sleeping of the radio
 *  
 * This link layer provides:
 *  - adaptation of preamble length based on packet type (unicast with
 *    a preamble of full length, broadcast with reduced length)
 *  - strength field in dB (rather than some
 *    hardware specific measure), assuming a gradient of 14mv/dB
 *  - no retransmissions
 *  
 * - Author -------------------------------------------------------------
 * @author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */
includes DTClock;

// #define WITH_TIME_STAMP 2

module PreambleSampleLLCM {
    provides {
        interface StdControl;
        interface ReceiveMsg as Receive;
        interface BareSendMsg as Send;
    }
    uses {
        interface GenericMsgComm;
        interface MarshallerControl;
        interface PacketRx;
        interface LPLControl;
        interface ChannelMonitorData;
//        interface LedsNumbered as Leds;
        interface TimerJiffy as PacketTimer;

#ifdef WITH_TIME_STAMP
        interface DeltaTStamp;
        interface DTClock;
        interface DTDelta;
#endif         
    }
}
implementation
{
#define AUX_BYTES 10

// all times in jiffies, define different duty cycles
// #define BYTE_DURATION  9
#define BYTE_DURATION  17

#define DC_WAKE_TIME    165

#define DC_0_SLOT_MODULO  0xFF
#define DC_0_SLEEP_TIME   DC_0_SLOT_MODULO - DC_WAKE_TIME

#define DC_1_SLOT_MODULO  0x1FF
#define DC_1_SLEEP_TIME   DC_1_SLOT_MODULO - DC_WAKE_TIME

#define DC_2_SLOT_MODULO  0x3FF
#define DC_2_SLEEP_TIME   DC_2_SLOT_MODULO - DC_WAKE_TIME

#define DC_3_SLOT_MODULO  0x7FF
#define DC_3_SLEEP_TIME   DC_3_SLOT_MODULO - DC_WAKE_TIME

#define DC_4_SLOT_MODULO  0xFFF    
#define DC_4_SLEEP_TIME   DC_5_SLOT_MODULO - DC_WAKE_TIME

#define DC_5_SLOT_MODULO  0x1FFF    
#define DC_5_SLEEP_TIME   DC_5_SLOT_MODULO - DC_WAKE_TIME

#define DC_6_SLOT_MODULO  0x3FFF    
#define DC_6_SLEEP_TIME   DC_6_SLOT_MODULO - DC_WAKE_TIME
    
#define DC_7_SLOT_MODULO  0x7FFF    
#define DC_7_SLEEP_TIME   DC_7_SLOT_MODULO - DC_WAKE_TIME

#define DC_8_SLOT_MODULO  0xFFFF    
#define DC_8_SLEEP_TIME   DC_8_SLOT_MODULO - DC_WAKE_TIME

#define UNI_TO_BCAST 1
    
    uint16_t nPreamblesUni;
    uint16_t nPreamblesBcast;

// #define LLCM_DEBUG

    TOS_Msg rxMsg;            // receive buffer
    TOS_Msg* rxMsgPtr;        // pointer to it
    bool rxBusy;              // and a flag to protect it during async/sync conv.
    
    TOS_Msg* txMsgPtr;        // transmit msg pointer, used for async/sync conv.
    uint8_t seqNo;
    uint16_t packetDuration;

    bool timerDirty;
    
    /**************** Helper functions ******/
    void signalFailure() {
#ifdef LLCM_DEBUG
        atomic {
            for(;;) {
                ;
            }
        }
#endif
    }

    /************** LPL *********************/
    void setLPLProperties(uint8_t set) {
        uint16_t cModulo;
        switch(set) {
            case 0:
                call LPLControl.setProperties(DC_0_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_0_SLOT_MODULO);
                cModulo = DC_0_SLOT_MODULO;
                break;
            case 1:
                call LPLControl.setProperties(DC_1_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_1_SLOT_MODULO);
                cModulo = DC_1_SLOT_MODULO;
                break;
            case 2:
                call LPLControl.setProperties(DC_2_SLEEP_TIME,
                                                  DC_WAKE_TIME,
                                                  DC_2_SLOT_MODULO);
                cModulo = DC_2_SLOT_MODULO;
                break;
            case 3:
                call LPLControl.setProperties(DC_3_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_3_SLOT_MODULO);
                cModulo = DC_3_SLOT_MODULO;
                break;
            case 4:
                call LPLControl.setProperties(DC_4_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_4_SLOT_MODULO);
                cModulo = DC_4_SLOT_MODULO;
                break;
            case 5:
                call LPLControl.setProperties(DC_5_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_5_SLOT_MODULO);
                cModulo = DC_5_SLOT_MODULO;
                break;                
            case 6:
                call LPLControl.setProperties(DC_6_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_6_SLOT_MODULO);
                cModulo = DC_6_SLOT_MODULO;
                break;
            case 7:
                call LPLControl.setProperties(DC_7_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_7_SLOT_MODULO);
                cModulo = DC_7_SLOT_MODULO;
                break;
            case 8:
            default:
                call LPLControl.setProperties(DC_8_SLEEP_TIME,
                                              DC_WAKE_TIME,
                                              DC_8_SLOT_MODULO);
                cModulo = DC_8_SLOT_MODULO;
                break;
        }
        nPreamblesUni = (cModulo/BYTE_DURATION)*12/10;
        nPreamblesBcast  = nPreamblesUni / UNI_TO_BCAST;
    }

    /**************** Init  *****************/
    command result_t StdControl.init(){
        atomic {
            rxMsgPtr = &rxMsg;
            txMsgPtr = NULL;
            rxBusy = FALSE;
            seqNo = 0;
            packetDuration = BYTE_DURATION * (MSG_DATA_SIZE + AUX_BYTES);
            timerDirty = FALSE;
        }
//        call Leds.init();
        return SUCCESS;
    }

    /**************** Start  *****************/
    command result_t StdControl.start(){
        call MarshallerControl.setProperties(MSG_HEADER_SIZE,
                                             LENGTH_BYTE_NUMBER, 
                                             nPreamblesUni,
                                             TOSH_DATA_LENGTH,
                                             BYTE_DURATION);

        setLPLProperties(0);
        return SUCCESS;
    }

    /**************** Stop  *****************/
    command result_t StdControl.stop(){
        return SUCCESS;
    } 

    task void ClearDirtyTask() {
        atomic timerDirty = FALSE;
    }

    task void StopPacketTimerTask() { 
        call PacketTimer.stop();
        post ClearDirtyTask();
    }
    
    void stopPacketTimer() {
        timerDirty = TRUE;
        post StopPacketTimerTask();
    }
    
    task void PacketTimeoutTask() {
        call PacketTimer.stop();
        if(call PacketTimer.setOneShot(packetDuration) == FAIL) signalFailure();
        post ClearDirtyTask();
    }

    void startPacketTimer() {
        timerDirty = TRUE;
        post PacketTimeoutTask();
    }
    
    /**************** Send ****************/
    task void PacketSentSuccess() {
        TOS_MsgPtr pBuf;
        atomic {
            pBuf = txMsgPtr;
            txMsgPtr = NULL;
        }
        signal Send.sendDone(pBuf, SUCCESS);
    }

    task void PacketSentFail() {
        TOS_MsgPtr pBuf;
        atomic {
            pBuf = txMsgPtr;
            txMsgPtr = NULL;
        }
        signal Send.sendDone(pBuf, FAIL);
    }
    
    command result_t Send.send(TOS_Msg *msg) {
        uint16_t nP = nPreamblesUni;
        result_t res;
        timeval_t tv;
        msg->seq_num = ++seqNo;
        msg->s_addr = TOS_LOCAL_ADDRESS;
        res = call GenericMsgComm.sendNext((uint8_t*)msg);
        if(res == SUCCESS) {
            if(msg->addr == TOS_BCAST_ADDR) nP = nPreamblesBcast;
            call MarshallerControl.setNumPreambles(nP);
#ifdef WITH_TIME_STAMP
            tv.tv_sec = msg->time_s;
            tv.tv_usec = msg->time_us;
            call DeltaTStamp.setTime(&tv);       
#endif
        }
        return res;
    }


    async event result_t GenericMsgComm.sendDone(uint8_t* sent, result_t result) { 
        atomic {
            txMsgPtr = (TOS_MsgPtr) sent;
            txMsgPtr->ack = 1; // this is rather stupid
            rxBusy = FALSE;
        }
        if(result) {
            if(post PacketSentSuccess() == FAIL) signalFailure();
        } else {
            if(post PacketSentFail() == FAIL) signalFailure();
        }
        return SUCCESS;
    }

    /**************** Receive ****************/
    async event void PacketRx.detected() {
        int action = 0;
        atomic {
            if(rxBusy == FALSE) {
                rxBusy = TRUE;
                rxMsgPtr->strength = 0xFFFF;
                action = 1;
            } else {
                action = 2;
            }
        }
        switch(action) {
            case 1:
                if(call GenericMsgComm.recvNext((uint8_t*)rxMsgPtr) == SUCCESS) {
                    call ChannelMonitorData.getSnr();
                    post PacketTimeoutTask();
                    //                    call Leds.led1On();
                } else {
                    atomic rxBusy = FALSE;
                    call PacketRx.reset();
//                    call Leds.led1Off();
                }
                break;
            case 2:
                call PacketRx.reset();
//                call Leds.led1Off();
                break;
        }
    }
    

    task void PacketRcvd() {
        TOS_MsgPtr pBuf;
        uint16_t dest;
        uint8_t group;
        atomic {
            pBuf = rxMsgPtr;
            rxBusy = FALSE;
            dest = rxMsgPtr->addr;
            group = rxMsgPtr->group;
        }
//        call Leds.led1Off();
//        if(group == TOS_AM_GROUP) {
//            if((dest == TOS_BCAST_ADDR) || (dest == TOS_LOCAL_ADDRESS)) {
                pBuf = signal Receive.receive(pBuf);
                atomic rxMsgPtr = pBuf;
//            }
//        }
    }
    
    async event result_t GenericMsgComm.recvDone(uint8_t* msgPtr, bool crc) {
        atomic {
            if(rxBusy) {
                call PacketRx.reset();
                stopPacketTimer();
                rxMsgPtr = (TOS_MsgPtr) msgPtr;
                if(crc) {
                    rxMsgPtr->crc = crc;
                    post PacketRcvd();
                } else {
                    rxBusy = FALSE;
                }
            }
        }
        return SUCCESS;
    }

    /*************** packet timed out ********/
    event result_t PacketTimer.fired() {
        atomic {
            if(timerDirty == TRUE) {
                timerDirty = FALSE;
            }
            else if(rxBusy) {
                call PacketRx.reset();
                rxBusy = FALSE;
            }
        }
        return SUCCESS;
    }

#ifdef WITH_TIME_STAMP
    /**************** time reading ************/
    event result_t DeltaTStamp.ready(const timeval_t *t) {
        atomic if(rxBusy) {
            rxMsgPtr->time_s = t->tv_sec;
            rxMsgPtr->time_us = t->tv_usec;
        }
        return SUCCESS;
    }
#endif
    
    /**************** strength reading ********/

    async event result_t ChannelMonitorData.getSnrDone(int16_t data) {
        atomic if(rxBusy) rxMsgPtr->strength = data;
        return SUCCESS;
    }

    /*************** number of CS before success *********/

    async event result_t LPLControl.numCS(uint8_t nc) {
        return SUCCESS;
    }

    /*************** default events ***********/

    /* for lazy buggers who do not want to do something with a packet */
    default event result_t Send.sendDone(TOS_MsgPtr sent, result_t success) {
        return SUCCESS;
    }

    default event TOS_MsgPtr Receive.receive(TOS_MsgPtr m) {
        return m;
    }     
}



