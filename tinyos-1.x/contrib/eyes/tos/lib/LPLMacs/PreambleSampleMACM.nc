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
 * - Description ---------------------------------------------------------
 * A low power listening MAC based on preamble sampling 
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module PreambleSampleMACM {
    provides {
        interface StdControl;
        interface GenericMsgComm;
        interface PacketRx as UpPacketRx;
        interface LPLControl;
    }
    uses {
        interface GenericMsgComm as MarshallerGenericMsgComm;
        interface PacketRx as DownPacketRx;
        interface FrameSync;
        
        interface TDA5250Modes as RadioModes;  

        interface ChannelMonitor;
        interface ChannelMonitorControl;  

        interface Random;
        interface TimerJiffy as AckTimer;
        interface TimerJiffy as BackoffTimer;

//        interface LedsNumbered as Leds;
    }
}
implementation
{
#define MACM_DEBUG
#define CHECK_TIME 68
#define RX_THRESHOLD 13 // SNR should be at least RX_THRESHOLD dB before RX attempt
    
    /**************** Module Global Variables  *****************/
    uint8_t* txBufPtr;

    typedef enum {
        INIT,
        SW_PS,   // switching to preamble sampling mode
        PS,      // preamble sampling mode
        SW_CCA,  // switch to CCA
        CCA,     // clear channel assessment       
        TX_P,    // transmitting packet
        SW_RX,   // switch to receive
        RX_P,    // rx mode done, receive packet
        RX_NEXT, // recvNext called
        RX_VOID
    } macState_t;

    macState_t macState;
#ifdef MACM_DEBUG
    macState_t oldmacState;
    int place;
    void storeOldState(int p) {
        atomic {
            oldmacState = macState;
            place = p;
        }
    }
#else
    void storeOldState(int p) {};
#endif
    /** the value in this variable denotes how often we have seen
     * the channel busy when trying to access it
     */
    
    uint8_t inBackoff;
    bool ackTimerFired; // ack timer fired
    bool backoffTimerFired; // backoff timer fired

    /* on and off times for preamble sampling mode in jiffies */
    bool timesDirty;
    uint16_t sleepTime;
    uint16_t wakeTime;
    uint16_t slotModulo;

    /* drop packet if we see the channel busy 
     * MAX_TX_ATTEMPTS times in a row 
     */
#define MAX_TX_ATTEMPTS 5

    /******** for atomic acks: allow  between packet and ACK ****/
#define DIFS 2 // disabled, work around msp430 clock bug

    /* jiffies per MSEC */
#define MSEC 33
    
    /****** Helper functions  ***********************/
    void signalFailure() {
#ifdef MACM_DEBUG
        atomic {
            for(;;) {
                ;
            }
        }
#endif
    }

    /****************  StdControl  *****************/
    command result_t StdControl.init(){
        call Random.init();
        atomic {
            txBufPtr = NULL;
            macState = INIT;
            inBackoff = 0;
            ackTimerFired = FALSE;
            backoffTimerFired = FALSE;
            timesDirty = TRUE;
#ifdef MACM_DEBUG
            oldmacState = INIT;
#endif
        }
//        call Leds.init();
        return SUCCESS;
    }

    command result_t StdControl.start() { 
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        result_t ok1, ok2;
        ok1 = call AckTimer.stop();
        ok2 = call BackoffTimer.stop();
        return rcombine(ok1,ok2);
    }

    /****** Helper tasks *****************************/
    void setAckTimer();
    task void SetAckTimerTask();
    
    task void StopAckTimerTask();

    task void RandomSleepTimerTask();

    void setCheckTimer();
    task void SetCheckTimerTask();
    
    task void CheckSendTask();
    void checkSend();

    /****** Secure switching of radio modes ***/
    task void CCAModeTask();
    task void SleepModeTask();
    task void SetSelfPollingTask();
    task void ResetSelfPollingTask();
    task void SetRxModeTask();

    
    void setCCAMode() {
        if(call RadioModes.CCAMode() == SUCCESS) {
            atomic backoffTimerFired = FALSE;
        } else {
            post CCAModeTask();
        }
    }

    task void CCAModeTask() {
        macState_t ms;
        atomic ms = macState;
        if((ms == SW_CCA) || (ms == INIT)) setCCAMode();
    }

    void setPollMode() {
        if(call RadioModes.SetSelfPollingMode(wakeTime/MSEC, sleepTime/MSEC) == SUCCESS){
            atomic {
                timesDirty = FALSE;
                storeOldState(1);
                macState = PS;
            }            
        } else {
            post  SetSelfPollingTask();
        } 
    }
    
    task void SetSelfPollingTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == SW_PS) setPollMode();
    }
    
    void resetPollMode() {
        bool btf;
        atomic if(timesDirty)
        {
            setPollMode();
        } else {
            if(call RadioModes.ResetSelfPollingMode() == SUCCESS) {
                atomic {
                    storeOldState(2);
                    macState = PS;
                    btf = backoffTimerFired;
                }
                if(btf) post CheckSendTask();
            } else {
                post ResetSelfPollingTask();
            }
        }
    }

    task void ResetSelfPollingTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == SW_PS) resetPollMode();
    }

    void setRxMode() {
        if(call RadioModes.RxMode() == FAIL) {
            post SetRxModeTask();
        }
    }
    
    task void SetRxModeTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == SW_RX) setRxMode();
    }

    void setSleepMode() {
        if(call RadioModes.SleepMode() == FAIL) {
            post SleepModeTask();
        }
    }

    task void SleepModeTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == SW_PS) setSleepMode();
    }
    
    /****** RadioMode events *************************/
    event result_t RadioModes.ready() {
        result_t res;
        macState_t ms;
        atomic ms = macState;
        if(ms == INIT) {
            setCCAMode();
            res = SUCCESS;
        } 
        else {
            signalFailure();
            res = FAIL;
        }
        return res;
    }

    event result_t RadioModes.CCAModeDone() {
        result_t res = SUCCESS;
        atomic  {
            if(macState == SW_CCA) {
                if(call ChannelMonitor.start() == SUCCESS) {
                    ackTimerFired = FALSE;
                    setAckTimer();
                    storeOldState(3);
                    macState = CCA;
                } else {
                    setCCAMode();
                }
            }
            else if(macState == INIT) {
                if(call ChannelMonitorControl.updateNoiseFloor() == FAIL) {
                    setCCAMode();
                }
            } else {
                res = FAIL;
            }
        }
        return res;
    }
    
    async event void RadioModes.interrupt() {
        macState_t ms = PS;
        atomic {
            if(macState == PS) {
                storeOldState(4);
                ms = macState = SW_RX;
            }
        }
        if(ms == SW_RX) setRxMode();
    }

    event result_t RadioModes.RxModeDone() {
        bool action = FALSE;
        atomic {
            if(macState == SW_RX) {
                storeOldState(5);
                macState = RX_P;
                action = TRUE;
            }
            else {
                signalFailure(); 
            }
        }
        if(action) setCheckTimer();
        return SUCCESS;
    }

    event result_t RadioModes.SleepModeDone() {
        return post RandomSleepTimerTask();
    }

    /****** MarshallerGenericMsgComm events **********************/

    async event result_t MarshallerGenericMsgComm.recvDone(uint8_t* recv, bool crc) {
        atomic {
            if(macState == RX_NEXT) {
                storeOldState(6);
                macState = RX_VOID;
            }
        }
        return signal GenericMsgComm.recvDone(recv, crc);
    }
    
    async event result_t MarshallerGenericMsgComm.sendDone(uint8_t* sent, result_t result) {
        macState_t ms = RX_VOID;
        atomic {
            txBufPtr = NULL;
            inBackoff = 0;
            storeOldState(7);
            if(macState == TX_P) ms = macState = SW_PS;
        }
        if(ms == SW_PS) {
            setSleepMode();
        } else {
            signalFailure();
        }
        return signal GenericMsgComm.sendDone(sent, result);
    }

    /****** AckTimer **********************************/
    
    event result_t AckTimer.fired() {
        int action = 0;
        atomic {
            if(macState == CCA) {
                ackTimerFired = TRUE;
            }
            else if(macState == SW_PS) {
                action = 1;
            }
            else if(macState == RX_P) {
                if(call FrameSync.isReceiving() == FALSE) {
                    macState = SW_PS;
                    action = 2;
                } else {
                    action = 3;
                }
            }
            else if(macState == INIT) {
                storeOldState(9);
                macState = SW_PS;
                action = 4;
            }
        }
        switch(action) {
            case 1:
                resetPollMode();
                break;
            case 2:
                setSleepMode();
                break;
            case 3:
                setCheckTimer();
                break;
            case 4:
                setPollMode();
                break;
        }
        return SUCCESS;
    }
    
    task void StopAckTimerTask() {
        call AckTimer.stop();
    }

    void setAckTimer() {
        call AckTimer.stop();
        if(call AckTimer.setOneShot(DIFS) == FAIL) {
            post SetAckTimerTask();
        }
    }
    
    task void SetAckTimerTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == CCA) setAckTimer();
    }
    
    task void RandomSleepTimerTask() {
        macState_t ms;
        uint32_t slot;
        atomic ms = macState;
        if((ms == SW_PS) || (ms == INIT)) {
            slot = ((call Random.rand() & slotModulo) + MSEC);
            if(call AckTimer.setOneShot(slot) == FAIL) {
                post RandomSleepTimerTask();
            }
        }
    }
    
    void setCheckTimer() {
        call AckTimer.stop();
        if(call AckTimer.setOneShot(CHECK_TIME) == FAIL) {
            post SetCheckTimerTask();
        }
    }
    
    task void SetCheckTimerTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == RX_P) setCheckTimer();
    }
    
    /****** BackoffTimer ******************************/
    
    task void SetBackoffTimerTask() {
        int32_t slot;
        int32_t iB;
        uint16_t window;
        atomic {
            backoffTimerFired = FALSE;
            iB = inBackoff;
        }
        window = 2 * iB;
        slot = call Random.rand();
        slot %= window;
        ++slot;
        slot *= (sleepTime + wakeTime);
        slot += (call Random.rand() & slotModulo);
        if(call BackoffTimer.setOneShot(slot) == FAIL) {
            if(post SetBackoffTimerTask() == FAIL) signalFailure();
        }
    }
    
    event result_t BackoffTimer.fired() {
        macState_t ms = RX_VOID;
        atomic {
            backoffTimerFired = TRUE;
            if(macState == PS) {
                storeOldState(10);
                ms = macState = SW_CCA;
            }
            else if(macState == INIT) {
                ms = INIT;
            }
        }
        if(ms == SW_CCA) {
            setCCAMode();
        }
        else if(ms == INIT) {
            post SetBackoffTimerTask();
        }
        return SUCCESS;
    }

    /****** CheckSend *****************************/
    void checkSend() {
        macState_t ms = RX_VOID;
        atomic {
            storeOldState(11);
            if(((macState == RX_VOID) || (macState == PS)) &&
               (inBackoff > 0) && (backoffTimerFired == TRUE)) {
                ms = macState = SW_CCA;
            } else {
                ms = macState = SW_PS;
            }
        }
        if(ms == SW_CCA) {
            setCCAMode();
        } else if(ms == SW_PS) {
            setSleepMode();
        } 
    }

    task void CheckSendTask() {
        checkSend();
    }
    
    /****** GenericMsgComm events *********************/
    result_t handleRecvNext(uint8_t* msg) {
        result_t res;
        return res;
    }

    async command result_t GenericMsgComm.sendNext(uint8_t *msg) {
        result_t res = FAIL;
        atomic {
            if(inBackoff == 0) {
                switch(macState) {
                    case CCA:
                    case SW_CCA:
                    case TX_P:
                        break;
                    default:
                        inBackoff = 1;
                        txBufPtr = msg;
                        post SetBackoffTimerTask();
                        res = SUCCESS;
                        break;
                }
            } 
        }
        return res;
    }
    
    async command result_t GenericMsgComm.recvNext(uint8_t *msg) {
        result_t res = FAIL;
        macState_t ms = CCA; // some value
        atomic {
            if(macState == RX_P) {
                post StopAckTimerTask();
                res = call MarshallerGenericMsgComm.recvNext((uint8_t*) msg);
                storeOldState(12);
                if(res == SUCCESS) {
                    ms = macState = RX_NEXT;
                } else {
                    ms = macState = RX_VOID;
                }
            }
        }
        if(ms == RX_VOID) checkSend();
        return res;
    }

    /******* PacketRx/Tx *******************************/
    async event void DownPacketRx.detected() {
        if(macState == RX_P) {
            signal UpPacketRx.detected();
        } else {
            call DownPacketRx.reset();
        }
    }

    async command result_t UpPacketRx.reset() {
        macState_t ms = CCA; // some value
        atomic {
            if(macState == RX_P) {
                post StopAckTimerTask();
                storeOldState(13);
                ms = macState = RX_VOID;
            }
            else if(macState == RX_NEXT) {
                storeOldState(14);
                ms = macState = RX_VOID;                
            }
            else if(macState == RX_VOID) {
                ms = macState; // valid
            } else {
                signalFailure();
            }
        }
        if(ms == RX_VOID) checkSend();
        return call DownPacketRx.reset();
    }

    /****** ChannelMonitor events *********************/

    event result_t ChannelMonitor.channelBusy(int16_t snr) {
        macState_t ms = RX_VOID;
        uint8_t *msg = NULL;
        atomic {
            if(macState == CCA) {
                ++inBackoff;
                storeOldState(15);
                ms = macState = SW_RX;
                if(inBackoff <= MAX_TX_ATTEMPTS) {
                    post SetBackoffTimerTask();
                } else {
                    msg = txBufPtr;
                    txBufPtr = NULL;
                    inBackoff = 0;
                }
            }
        }
        if(ms == SW_RX) {
            call AckTimer.stop();
            setRxMode();
            if(msg != NULL) signal GenericMsgComm.sendDone(msg, FAIL);
        }
        return SUCCESS;
    }
  
    event result_t ChannelMonitor.channelIdle() {
        macState_t ms = RX_VOID;
        uint8_t *msg;
        atomic {
            msg = txBufPtr;
            if(macState == CCA) {
                storeOldState(16);
                if(ackTimerFired == FALSE) {
                    ms = CCA;
                } else {
                    ms = macState = TX_P;
                    ackTimerFired = FALSE;
                }
                if(call MarshallerGenericMsgComm.sendNext(msg) == FAIL) {
                    ms = macState = SW_PS;
                    txBufPtr = NULL;
                    inBackoff = 0;
                }
            }
        }
        if(ms == CCA) {
            call ChannelMonitor.start(); 
        } else if(ms == SW_PS) {
            resetPollMode();
            signal GenericMsgComm.sendDone(msg, FAIL);
        }
        return SUCCESS;   
    }


    /****** ChannelMonitorControl events **************/

    event result_t ChannelMonitorControl.updateNoiseFloorDone() {
        result_t res;
        atomic {
            if(macState == INIT) {
                post RandomSleepTimerTask();
                res = SUCCESS;
            } else {
                signalFailure();
                res = FAIL;
            }
        }
        return res;
    }

    /******** LPLControl ******************************/
    command result_t LPLControl.setProperties(uint16_t sleep, uint16_t wake, uint16_t modulo) {
        atomic {
            timesDirty = TRUE;
            sleepTime = sleep;
            wakeTime = wake;
            slotModulo = modulo;
        }
        return SUCCESS;
    }

    default async event result_t LPLControl.numCS(uint8_t ncs) {
        return SUCCESS;
    }
    
}
