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

includes flagFunctions;

module SyncSampleMACM {
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
        // interface Watchdog;
        interface TDA5250Modes as RadioModes;  

        interface ChannelMonitor;
        interface ChannelMonitorControl;  

        interface Random;
        interface TimerJiffy as MinClearTimer;
        interface TimerJiffy as RxAliveTimer;
        interface TimerJiffy as RandomSleepTimer;
        interface TimerJiffy as BackoffTimer;
        interface TimerJiffy as SampleTimer;      
        // interface LedsNumbered as Leds;
    }
}
implementation
{
// #define MACM_DEBUG
#define CHECK_TIME 68
#define RX_THRESHOLD 13 // SNR should be at least RX_THRESHOLD dB before RX attempt
#define MAX_BUSY_NO_RX 20
    
    /**************** Module Global Variables  *****************/
    uint8_t* txBufPtr;

    typedef enum {
        INIT,
        SW_PS_SLEEP,     // switching to preamble sampling mode
        PS_SLEEP,        // preamble sampling sleep mode
        SW_PS_LISTEN,    // preamble sampling listen mode
        PS_LISTEN,       // preamble sampling listen mode
        SW_CCA,          // switch to CCA
        CCA,             // clear channel assessment       
        TX_P,            // transmitting packet
        SW_RX,           // switch to receive
        RX_P,            // rx mode done, receive packet
        RX_NEXT,         // recvNext called
        RX_VOID
    } macState_t;

    macState_t macState;

    typedef enum {
        MIN_CLEAR_TIMER = 1,
        RX_ALIVE_TIMER = 2,
        RANDOM_SLEEP_TIMER = 4,
        BACKOFF_TIMER = 8,
        SAMPLE_TIMER = 16
    } timerPos_t;

    uint8_t dirtyTimers;
    uint8_t firedTimers;
    uint8_t runningTimers;
    uint8_t restartTimers;
    uint8_t busyNoRxCnt;
    
#ifdef MACM_DEBUG
    #define HISTORY_ENTRIES 40
    typedef struct {
        int index;
        macState_t state;
        int        place;
    } history_t;

    history_t history[HISTORY_ENTRIES];
    unsigned histIndex;
    void storeOldState(int p) {
        atomic {
            history[histIndex].index = histIndex;
            history[histIndex].state = macState;
            history[histIndex].place = p;
            histIndex++;
            if(histIndex >= HISTORY_ENTRIES) histIndex = 0;
        }
    }
#else
    void storeOldState(int p) {};
#endif
    /** the value in this variable denotes how often we have seen
     * the channel busy when trying to access it
     */
    
    uint8_t inBackoff;
    
    /* milli second in jiffies */
#define MSEC 33
    
    /* on and off times for preamble sampling mode in jiffies */
    
    uint16_t sleepTime;
    uint16_t wakeTime;
    uint16_t slotModulo;

/* drop packet if we see the channel busy 
 * MAX_TX_ATTEMPTS times in a row 
 */
#define MAX_TX_ATTEMPTS 5

    /******** for atomic acks: allow  between packet and ACK ****/
#define DIFS 2 // disabled, work around msp430 clock bug

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
            firedTimers = 0;
            dirtyTimers = 0;
            runningTimers = 0;
            sleepTime = 858;
            wakeTime = 165;
            slotModulo = 0x3FF;
            busyNoRxCnt = 0;
#ifdef MACM_DEBUG
            histIndex = 0;
#endif
        }
        return SUCCESS;
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call MinClearTimer.stop();
        call RxAliveTimer.stop();
        call RandomSleepTimer.stop();
        call BackoffTimer.stop();
        call SampleTimer.stop();
        return SUCCESS;
    }

    /****** Helper tasks *****************************/

    task void CheckSendTask();
    void checkSend();

    task void StopMinClearTimerTask();
    task void StopRxAliveTimerTask();
    task void StopRandomSleepTimerTask();
    task void StopBackoffTimerTask();

    // cs = clear and maybe start, only start if start requested and in correct
    // mac state
    task void CSMinClearTimerTask()   {
        atomic {
            clearFlag(&dirtyTimers, MIN_CLEAR_TIMER);
            if(isFlagSet(&restartTimers, MIN_CLEAR_TIMER)) {
                if(macState == CCA) {
                    if(call MinClearTimer.setOneShot(DIFS) == SUCCESS) {
                        clearFlag(&restartTimers, MIN_CLEAR_TIMER);
                        setFlag(&runningTimers, MIN_CLEAR_TIMER);
                    } else {
                        post CSMinClearTimerTask();
                    }
                } else {
                    clearFlag(&restartTimers, MIN_CLEAR_TIMER);
                }
            }
        }
    };
    
    task void CSRxAliveTimerTask()    {
        atomic {
            clearFlag(&dirtyTimers, RX_ALIVE_TIMER);
            if(isFlagSet(&restartTimers, RX_ALIVE_TIMER)) {
                if(macState == RX_P) {
                    if(call RxAliveTimer.setOneShot(CHECK_TIME) == SUCCESS) {
                        clearFlag(&restartTimers, RX_ALIVE_TIMER);
                        setFlag(&runningTimers, RX_ALIVE_TIMER);
                    } else {
                    post CSRxAliveTimerTask();
                    }
                } else {
                    clearFlag(&restartTimers, RX_ALIVE_TIMER);
                }
            }
        }
    }
    
    task void CSRandomSleepTimerTask(){
        int32_t slot;
        atomic {
            clearFlag(&dirtyTimers, RANDOM_SLEEP_TIMER);
            if(isFlagSet(&restartTimers, RANDOM_SLEEP_TIMER)) {
                if((macState == PS_SLEEP) || (macState == INIT)) {
                    slot = ((call Random.rand() & slotModulo) + MSEC);
                    if(call RandomSleepTimer.setOneShot(slot) == SUCCESS) {
                        clearFlag(&restartTimers, RANDOM_SLEEP_TIMER);
                        setFlag(&runningTimers, RANDOM_SLEEP_TIMER);
                    }
                } else {
                    post CSRandomSleepTimerTask();
                }
            }
        }
    }
    
    task void CSBackoffTimerTask() {
        int32_t slot;
        int32_t iB;
        uint16_t window;
        bool action = FALSE;
        atomic {
            iB = inBackoff;
            clearFlag(&dirtyTimers, BACKOFF_TIMER);
            if(isFlagSet(&restartTimers, BACKOFF_TIMER)) {
                action = TRUE;
            }
        }
        if(action) {
            window = 2 * iB;
            // window = 1 << iB;
            slot = call Random.rand();
            slot %= window;
            ++slot;
            slot *= (sleepTime + wakeTime);
            slot += (call Random.rand() & slotModulo);
            if(call BackoffTimer.setOneShot(slot) == SUCCESS) {
                atomic {
                    clearFlag(&restartTimers, BACKOFF_TIMER);
                    setFlag(&runningTimers, BACKOFF_TIMER);
                }
            } else {
                post CSBackoffTimerTask();
            }
        }
    }

    void csMinClearTimer(bool inAsync) {
        atomic {
            if(isFlagSet(&runningTimers, MIN_CLEAR_TIMER)) {
                setFlag(&dirtyTimers, MIN_CLEAR_TIMER);
                if(inAsync) {
                    post StopMinClearTimerTask();
                } else {
                    clearFlag(&runningTimers, MIN_CLEAR_TIMER);
                    call MinClearTimer.stop();
                    post CSMinClearTimerTask();
                }
            } else if(isFlagSet(&restartTimers, MIN_CLEAR_TIMER)) {
                post CSMinClearTimerTask();
            }
        }
    }
    task void StopMinClearTimerTask() { csMinClearTimer(FALSE); }
    void stopMinClearTimer(bool inAsync) {
        clearFlag(&restartTimers, MIN_CLEAR_TIMER);
        csMinClearTimer(inAsync);
    }
    void restartMinClearTimer(bool inAsync) {
        setFlag(&restartTimers, MIN_CLEAR_TIMER);
        csMinClearTimer(inAsync);
    }
    
    void csRxAliveTimer(bool inAsync) {
        atomic {
            if(isFlagSet(&runningTimers, RX_ALIVE_TIMER)) {
                setFlag(&dirtyTimers, RX_ALIVE_TIMER);
                if(inAsync) {
                    post StopRxAliveTimerTask();
                } else {
                    clearFlag(&runningTimers, RX_ALIVE_TIMER);
                    call RxAliveTimer.stop();
                    post CSRxAliveTimerTask();
                }
            }
            else if(isFlagSet(&dirtyTimers, RX_ALIVE_TIMER)) {
                // do nothing
            }
            else if(isFlagSet(&restartTimers, RX_ALIVE_TIMER)) {
                    post CSRxAliveTimerTask();
            }
        }
    }
    task void StopRxAliveTimerTask() { csRxAliveTimer(FALSE); };
    void stopRxAliveTimer(bool inAsync) {
        clearFlag(&restartTimers, RX_ALIVE_TIMER);
        csRxAliveTimer(inAsync);
    };
    void restartRxAliveTimer(bool inAsync) {
        setFlag(&restartTimers, RX_ALIVE_TIMER);
        csRxAliveTimer(inAsync);
    };
    
    void csRandomSleepTimer(bool inAsync) {
        atomic {
            if(isFlagSet(&runningTimers, RANDOM_SLEEP_TIMER)) {
                setFlag(&dirtyTimers, RANDOM_SLEEP_TIMER);
                if(inAsync) {
                    post StopRandomSleepTimerTask();
                } else {
                    clearFlag(&runningTimers, RANDOM_SLEEP_TIMER);
                    call RandomSleepTimer.stop();
                    post CSRandomSleepTimerTask();
                }
            }
            else if(isFlagSet(&dirtyTimers, RANDOM_SLEEP_TIMER)) {
                // do nothing
            }
            else if(isFlagSet(&restartTimers, RANDOM_SLEEP_TIMER)) {
                post CSRandomSleepTimerTask();
            }
        }
    }
    task void StopRandomSleepTimerTask() { csRandomSleepTimer(FALSE); };
    void stopRandomSleepTimer(bool inAsync) {
        clearFlag(&restartTimers, RANDOM_SLEEP_TIMER);
        csRandomSleepTimer(inAsync);
    };
    void restartRandomSleepTimer(bool inAsync) {
        setFlag(&restartTimers, RANDOM_SLEEP_TIMER);
        csRandomSleepTimer(inAsync);
    };
    
    void csBackoffTimer(bool inAsync) {
        atomic {
            if(isFlagSet(&runningTimers, BACKOFF_TIMER)) {
                setFlag(&dirtyTimers, BACKOFF_TIMER);
                if(inAsync) {
                    post StopBackoffTimerTask();
                } else {
                    clearFlag(&runningTimers, BACKOFF_TIMER);
                    call BackoffTimer.stop();
                    post CSBackoffTimerTask();
                }
            }
            else if(isFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
                // do nothing
            }
            else if(isFlagSet(&restartTimers, BACKOFF_TIMER)) {
                post CSBackoffTimerTask();
            }
        }
    }
    task void StopBackoffTimerTask() { csBackoffTimer(FALSE); };
    void stopBackoffTimer(bool inAsync) {
        clearFlag(&restartTimers, BACKOFF_TIMER);
        csBackoffTimer(inAsync);
    };
    void restartBackoffTimer(bool inAsync) {
        setFlag(&restartTimers, BACKOFF_TIMER);
        csBackoffTimer(inAsync);
    };
    /****** Secure switching of radio modes ***/
    task void CCAModeTask();
    task void PSSleepTask();
    task void PSListenTask();
    task void SetRxModeTask();

    void setCCAMode() {
        if(call RadioModes.CCAMode() == SUCCESS) {
            storeOldState(0);
        } else {
            post CCAModeTask();
        }
    }

    task void CCAModeTask() {
        macState_t ms;
        atomic ms = macState;
        if((ms == SW_CCA) || (ms == INIT)) setCCAMode();
    }

    void setPSSleep() {
        if(call RadioModes.SleepMode() == SUCCESS) {
            atomic {
                storeOldState(1);
                macState = SW_PS_SLEEP;
            }
        } else {
            post PSSleepTask();
        }
    }

    task void PSSleepTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == SW_PS_SLEEP) setPSSleep();
    }

    void setPSListen() {
        
        if(call RadioModes.CCAMode() == FAIL) {
            post PSListenTask();
        }
    }

    task void PSListenTask() {
        macState_t ms;
        atomic ms = macState;
        if(ms == SW_PS_LISTEN) setPSListen();
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
                    clearFlag(&firedTimers, MIN_CLEAR_TIMER);
                    restartMinClearTimer(FALSE);
                    storeOldState(2);
                    macState = CCA;
                } else {
                    storeOldState(3);
                    setCCAMode();
                }
            }
            else if(macState == SW_PS_LISTEN) {
                if(call ChannelMonitor.start() == SUCCESS) {
                    storeOldState(4);
                    macState = PS_LISTEN;
                } else {
                    storeOldState(5);
                    setPSListen();
                }
            }
            else if(macState == INIT) {
                storeOldState(6);
                if(call ChannelMonitorControl.updateNoiseFloor() == FAIL) {
                    setCCAMode();
                }
            } else {
                storeOldState(7);
                res = FAIL;
            }
        }
        return res;
    }
    
    async event void RadioModes.interrupt() {
        storeOldState(8);
        signalFailure();
    }

    event result_t RadioModes.RxModeDone() {
        atomic {
            if(macState == SW_RX) {
//                call Leds.led2On();
                storeOldState(9);
                macState = RX_P;
                clearFlag(&firedTimers, RX_ALIVE_TIMER);
                restartRxAliveTimer(FALSE);
            }
            else {
                signalFailure(); 
            }
        }
        return SUCCESS;
    }

    event result_t RadioModes.SleepModeDone() {
        macState_t ms = RX_VOID;
        result_t res = SUCCESS;
        atomic {
            if(macState == SW_PS_SLEEP) {
                storeOldState(10);
                ms = macState = PS_SLEEP;
            } else {
                storeOldState(11);
                signalFailure();
            }
        }
        if(ms == PS_SLEEP) {
            clearFlag(&firedTimers, RANDOM_SLEEP_TIMER);
            restartRandomSleepTimer(FALSE);
        }
        return res;
    }

        /****** SendDone signal *******************/
    result_t sendDone(uint8_t *msg, result_t result, uint8_t iB, bool goSleep) {
        result_t res;
        if((macState == TX_P) || (macState == CCA)) {
            if(iB <= MAX_TX_ATTEMPTS) signal LPLControl.numCS(iB);
            res = signal GenericMsgComm.sendDone(msg, result);
            txBufPtr = NULL; 
            inBackoff = 0;
            if(goSleep) {
                macState = SW_PS_SLEEP;
                setPSSleep();
            }
        } else {
            res = FAIL;
            signalFailure();
        }
        return res;
    }
    

    /****** MarshallerGenericMsgComm events **********************/

    async event result_t MarshallerGenericMsgComm.recvDone(uint8_t* recv, bool crc) {
        atomic {
            if(macState == RX_NEXT) {
                stopRxAliveTimer(TRUE);
                storeOldState(12);
                macState = RX_VOID;
            } else {
                signalFailure();
            }
        }
        return signal GenericMsgComm.recvDone(recv, crc);
    }
    
    async event result_t MarshallerGenericMsgComm.sendDone(uint8_t* sent, result_t result) {
        result_t res = FAIL;
        atomic {
            storeOldState(13);
            if(macState == TX_P) res = sendDone(sent, result, inBackoff, TRUE);
        }
        return res;
    }

    /****** RandomSleepTimer ******************************/

    event result_t RandomSleepTimer.fired() {
        bool action = FALSE;
        atomic {
            if(isFlagSet(&dirtyTimers, RANDOM_SLEEP_TIMER)) {
                storeOldState(14);
            } else {
                if(macState == PS_SLEEP) {
                    setFlag(&firedTimers, RANDOM_SLEEP_TIMER);
                    storeOldState(15);
                    action = TRUE;
                } else if(macState == INIT) {
                    storeOldState(16);
                    macState = SW_PS_SLEEP;
                    setPSSleep();
                    clearFlag(&dirtyTimers, SAMPLE_TIMER);
                    setFlag(&runningTimers, SAMPLE_TIMER);
                    call SampleTimer.setPeriodic(sleepTime+wakeTime);
                } else {
                    signalFailure();
                }
                clearFlag(&runningTimers, RANDOM_SLEEP_TIMER);
            }
        }
        if(action) checkSend();
        return SUCCESS;
    }

    /****** MinClearTimer ******************************/
    event result_t MinClearTimer.fired() {
        atomic {
            if(isFlagSet(&dirtyTimers, MIN_CLEAR_TIMER)) {
                storeOldState(17);
            } else {
                if(macState == CCA) {
                    setFlag(&firedTimers, MIN_CLEAR_TIMER);
                    storeOldState(18);
                } else {
                    signalFailure();
                }
                clearFlag(&runningTimers, MIN_CLEAR_TIMER);
            }
        }
        return SUCCESS;
    }
    
    /****** RxAliveTimer ******************************/
    event result_t RxAliveTimer.fired() {
        atomic {
            if(isFlagSet(&dirtyTimers, RX_ALIVE_TIMER)) {
                storeOldState(19);
            }
            else {
                if(macState == RX_P) {
                    setFlag(&firedTimers, RX_ALIVE_TIMER);
                    if(call FrameSync.isReceiving() == FALSE) {
                        macState = SW_PS_SLEEP;
                        setPSSleep();
                        storeOldState(20);
//                        call Leds.led2Off();
                    } else {
//                        call Leds.led3On();
                        storeOldState(21);
                        restartRxAliveTimer(FALSE);
                        busyNoRxCnt = 0;
                    }
                } else {
                    storeOldState(22);
                    signalFailure();
                }
                clearFlag(&runningTimers, RX_ALIVE_TIMER);
            }
        }
        return SUCCESS;
    }
    
    /****** BackoffTimer ******************************/
    
    event result_t BackoffTimer.fired() {
        macState_t ms = RX_VOID;
        atomic {
            if(isFlagSet(&dirtyTimers, BACKOFF_TIMER)) {
                storeOldState(23);
            }
            else {
                if(macState == PS_SLEEP) {
                    setFlag(&firedTimers, BACKOFF_TIMER);
                    stopRandomSleepTimer(FALSE);
                    storeOldState(24);
                    ms = macState = SW_CCA;
                }
                else if(macState == INIT) {
//                    setFlag(&firedTimers, BACKOFF_TIMER);
                    storeOldState(25);
                    ms = INIT;
                } else {
                    setFlag(&firedTimers, BACKOFF_TIMER);
                    storeOldState(26);
                }
                clearFlag(&runningTimers, BACKOFF_TIMER);
            }
        }
        if(ms == SW_CCA) {
            setCCAMode();
        }
        else if(ms == INIT) {
            restartBackoffTimer(FALSE);
        }
        return SUCCESS;
    }
    
    /****** SampleTimer ***************************/
    event result_t SampleTimer.fired() {
        atomic {
            if(macState == PS_SLEEP) {
                stopRandomSleepTimer(FALSE);
                if(isFlagSet(&dirtyTimers, SAMPLE_TIMER)) {
                    clearFlag(&dirtyTimers, SAMPLE_TIMER);
                    call SampleTimer.stop();
                    call SampleTimer.setPeriodic(sleepTime+wakeTime);
                }
                storeOldState(27);
                macState = SW_PS_LISTEN;
                setPSListen();
            }
        }
        return SUCCESS;
    }
    

    /****** CheckSend *****************************/
    void checkSend() {
        macState_t ms = RX_VOID;
        atomic {
            if(((macState == RX_VOID) || (macState == PS_SLEEP)) &&
               (inBackoff > 0) && isFlagSet(&firedTimers, BACKOFF_TIMER)) {
                storeOldState(28);
                ms = macState = SW_CCA;
            } else {
                storeOldState(29);
            }
        }
        if(ms == SW_CCA) {
            setCCAMode();
        }
    }

    task void CheckSendTask() {
        checkSend();
    }
    
    /****** GenericMsgComm events *********************/

    async command result_t GenericMsgComm.sendNext(uint8_t *msg) {
        result_t res = FAIL;
        atomic {
            if(inBackoff == 0) {
                storeOldState(50);
                switch(macState) {
                    case CCA:
                    case SW_CCA:
                    case TX_P:
                        break;
                    default:
                        inBackoff = 1;
                        txBufPtr = msg;
                        restartBackoffTimer(TRUE);
                        res = SUCCESS;
                        break;
                }
            } else {
                storeOldState(51);
            }
        }
        return res;
    }
    
    async command result_t GenericMsgComm.recvNext(uint8_t *msg) {
        result_t res = FAIL;
        macState_t ms = CCA; // some value
        atomic {
            busyNoRxCnt = 0;
            if(macState == RX_P) {
                stopRxAliveTimer(TRUE);
                res = call MarshallerGenericMsgComm.recvNext((uint8_t*) msg);
                if(res == SUCCESS) {
                    storeOldState(52);
                    ms = macState = RX_NEXT;
                } else {
                    storeOldState(53);
                    ms = macState = SW_PS_SLEEP;
                }
            }
        }
        if(ms == SW_PS_SLEEP) setPSSleep();
        return res;
    }

    /******* PacketRx/Tx *******************************/
    async event void DownPacketRx.detected() {
        if(macState == RX_P) {
            storeOldState(4);
            signal UpPacketRx.detected();
            call ChannelMonitor.rxSuccess();
        } else {
            storeOldState(34);
            call DownPacketRx.reset();
        }
        busyNoRxCnt = 0;
    }

    async command result_t UpPacketRx.reset() {
        macState_t ms = CCA; // some value
        atomic {
//            call Leds.led3Off();
            if(macState == RX_P) {
                stopRxAliveTimer(TRUE);
                storeOldState(55);
                ms = macState = SW_PS_SLEEP;
            }
            else if(macState == RX_NEXT) {
                storeOldState(56);
                ms = macState = SW_PS_SLEEP;                
            }
            else if(macState == RX_VOID) {
                storeOldState(57);
                ms = macState = SW_PS_SLEEP;
            } else {
                signalFailure();
            }
        }
        if(ms == SW_PS_SLEEP) setPSSleep();
        return call DownPacketRx.reset();
    }

    /****** ChannelMonitor events *********************/

    async event result_t ChannelMonitor.channelBusy(int16_t snr) {
        bool sendFailed = FALSE;
        atomic {
            if((snr > RX_THRESHOLD) && (++busyNoRxCnt > MAX_BUSY_NO_RX))
                // call Watchog.enable();
            if(macState == CCA) {
                ++inBackoff;
                clearFlag(&firedTimers, BACKOFF_TIMER);
                storeOldState(58);
                if(inBackoff <= MAX_TX_ATTEMPTS) {
                    storeOldState(60);
                    restartBackoffTimer(TRUE);
                } else {
                    storeOldState(61);
                    sendFailed = TRUE;
                    stopBackoffTimer(TRUE);
                }
            } else if(macState == PS_LISTEN) {
                storeOldState(62);
            }

            stopMinClearTimer(TRUE);

            if(sendFailed) sendDone(txBufPtr, FAIL, inBackoff, FALSE);

            macState = SW_RX;
            setRxMode();
        }
        return SUCCESS;
    }
  
    async event result_t ChannelMonitor.channelIdle() {
        atomic {
            if(macState == CCA) {
                if(!isFlagSet(&firedTimers, MIN_CLEAR_TIMER)) {
                    storeOldState(64);
                    call ChannelMonitor.start();         
                } else {
                    if(txBufPtr == NULL) signalFailure();
                    clearFlag(&firedTimers, MIN_CLEAR_TIMER);
                    clearFlag(&firedTimers, BACKOFF_TIMER);
                    macState = TX_P;
                    if(call MarshallerGenericMsgComm.sendNext(txBufPtr) == FAIL) {
                        storeOldState(65);
                        sendDone(txBufPtr, FAIL, inBackoff, TRUE);
                    } else {
                        storeOldState(66);
                    }
                }
            } else if(macState == PS_LISTEN) {
                storeOldState(67);
                macState = SW_PS_SLEEP;
                setPSSleep();
            }
        }
        return SUCCESS;   
    }


    /****** ChannelMonitorControl events **************/

    event result_t ChannelMonitorControl.updateNoiseFloorDone() {
        result_t res;
        atomic {
            storeOldState(68);
            if(macState == INIT) {
                restartRandomSleepTimer(FALSE);
                res = SUCCESS;
            } else {
                signalFailure();
                res = FAIL;
            }
        }
        return res;
    }

    /******** LPLControl ******************************/
    command result_t LPLControl.setProperties(uint16_t s, uint16_t w, uint16_t m) {
        atomic {
             sleepTime = s;
             wakeTime = w;
             slotModulo = m;
             setFlag(&dirtyTimers, SAMPLE_TIMER);
        }
        return SUCCESS;
    }
}
