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
 * Controlling the TDA5250, switching modes and initializing.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.16 $
 * $Date: 2005/11/29 12:16:07 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module TDA5250M {
    provides {
        interface StdControl;
        interface TDA5250Config;
        interface TDA5250Modes;
        interface ByteComm;
        interface PacketRx;
        interface FrameSync;
        interface PacketTx;
    }
    uses {
        interface Pot;
        interface StdControl as PotControl;
        interface HPLTDA5250Config;
        interface HPLTDA5250Data;
        interface BusArbitration;
        interface TicClock;
        interface TicDelta;
    }
}
implementation {
#include "TDA5250Const.h"
#define BYTE_DURATION 17
// #define TDA5250_DEBUG 

    usartState_t usartState;
    frameState_t frameState;
    busState_t busState;
    phyState_t phyState;
    phyState_t nextPhyState;
    uint16_t preamblesToSend;
    uint8_t  thRssi;
    bool taskPending;
    ticval_t lastRx;

#ifdef TDA5250_DEBUG
    bool fromXT2;
    float onTime;
    float offTime;
#endif

    /*************** helper functions ******************/
    /** bus **/
    result_t getBus();
    result_t tryToGetBus();
    void releaseBus();
    void freezeRx();
    
    /** usart **/
    result_t enableRx();
    result_t enableTx();
    result_t disableUartAndFramer();
    result_t spiLock();
    result_t spiUnlock();
    void sourceDCO();
    void sourceXT2();
    
    /** framer **/
    void transmitByte();
    void receiveByte(uint8_t data);
    
    /** radio busy check **/
    /* acquires necessary semaphore taskPending */
    bool radioBusy();

    /** others **/

    bool getTaskLock() {
        bool old;
        atomic {
            old = taskPending;
            taskPending = TRUE;
        }
        return !old;
    }

    void releaseTaskLock()  {
        atomic taskPending = FALSE;
    }

    void  setupSystem();
    task void SetupSystemTask() {
        phyState_t p;
        atomic p = phyState;
        if(p == RADIO_STARTUP) setupSystem();
    }
    
    /*************** DONE tasks ************************/
    task void SignalRxModeDone() {
        atomic {
#ifdef TDA5250_DEBUG            
            if(nextPhyState != RX) for(;;) { ;}
            if(frameState != FRAMER_IDLE) for(;;) { ;}
            if(usartState >= SPI_LOCKED) for(;;) { ;}
#endif
            nextPhyState = RADIO_IDLE;
            phyState = RX;
            frameState = RX_PREAMBLE;
        }
        call PotControl.start();
        sourceXT2();
        signal TDA5250Modes.RxModeDone();
        enableRx();
        releaseTaskLock();
    }

    task void SignalCcaModeDone() {
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != CCA) for(;;) { ;}
            if(frameState != FRAMER_IDLE) for(;;) { ;}
            if(usartState >= SPI_LOCKED) for(;;) { ;}
#endif
            nextPhyState = RADIO_IDLE;
            phyState = CCA;
        }
        call PotControl.start();
        signal TDA5250Modes.CCAModeDone();
        releaseTaskLock();
    }

    task void SignalTxModeDone() {
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != TX) for(;;) { ;}
            if(frameState != FRAMER_IDLE) for(;;) { ;}
            if(usartState >= SPI_LOCKED) for(;;) { ;}
#endif
            phyState = TX;
            nextPhyState = RADIO_IDLE;
            frameState = TX_PREAMBLE;
        }
        call PotControl.start();
        sourceXT2();
        enableTx();
        transmitByte();
        releaseTaskLock();
    }

    task void SignalSelfPollingModeDone() {
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != SELF_POLLING) for(;;) { ;}
            if(frameState != FRAMER_IDLE) for(;;) { ;}
            if(usartState >= SPI_LOCKED) for(;;) { ;}
            if(fromXT2 == TRUE) for(;;) { ;}
#endif
            phyState = SELF_POLLING;
            nextPhyState = RADIO_IDLE;
        }
        call PotControl.start();
        releaseTaskLock();
    }

    task void SignalTimerModeDone() {
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != TIMER) for(;;) { ;}
            if(frameState != FRAMER_IDLE) for(;;) { ;}
            if(usartState >= SPI_LOCKED) for(;;) { ;}
            if(fromXT2 == TRUE) for(;;) { ;}
#endif
            phyState = TIMER;
            nextPhyState = RADIO_IDLE;
        }
        call PotControl.stop();
        releaseTaskLock();
    }

    task void SignalSleepModeDone() {
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != SLEEP) for(;;) { ;}
            if(frameState != FRAMER_IDLE) for(;;) { ;}
            if(usartState >= SPI_LOCKED) for(;;) { ;}
            if(fromXT2 == TRUE) for(;;) { ;}
#endif
            phyState = SLEEP;
            nextPhyState = RADIO_IDLE;
        }
        call PotControl.stop();
        signal TDA5250Modes.SleepModeDone();
        releaseTaskLock();
    }
    
    /*************** TDA5250Modes **********************/
    async command result_t TDA5250Modes.SetTimerMode(float on_time, float off_time) {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if((radioBusy() == FALSE) && (spiLock() == SUCCESS)) {
            atomic {
                nextPhyState = TIMER;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            } else {
                sourceDCO();
            }
#ifdef TDA5250_DEBUG
            onTime = on_time;
            offTime = off_time;
#endif
            call HPLTDA5250Config.SetTimerMode(on_time, off_time);
            post SignalTimerModeDone();
            spiUnlock();
            releaseBus();
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }
    
    async command result_t TDA5250Modes.ResetTimerMode() {
        result_t res;
        phyState_t p;
#ifdef TDA5250_DEBUG
        return call TDA5250Modes.SetTimerMode(onTime, offTime);
#endif

        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if((radioBusy() == FALSE) && (spiLock() == SUCCESS)) {
            atomic {
                nextPhyState = TIMER;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            } else {
                sourceDCO();
            }
            call HPLTDA5250Config.ResetTimerMode();
            post SignalTimerModeDone();
            spiUnlock();
            releaseBus();
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }
    
    async command result_t TDA5250Modes.SetSelfPollingMode(float on_time, float off_time) {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if((radioBusy() == FALSE) && (spiLock() == SUCCESS)) {
            atomic {
                nextPhyState = SELF_POLLING;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            } else {
                sourceDCO();
            }
#ifdef TDA5250_DEBUG
            onTime = on_time;
            offTime = off_time;
#endif
            call HPLTDA5250Config.UseRSSIDataValidDetection(thRssi, 
                                                            TH1_VALUE_RX, 
                                                            TH2_VALUE_RX);
            call HPLTDA5250Config.SetSelfPollingMode(on_time, off_time);
            post SignalSelfPollingModeDone();
            spiUnlock();
            releaseBus();
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }
    
    async command result_t TDA5250Modes.ResetSelfPollingMode() {
        result_t res;
        phyState_t p;
#ifdef TDA5250_DEBUG
        return call TDA5250Modes.SetSelfPollingMode(onTime, offTime);
#endif
        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if((radioBusy() == FALSE) && (spiLock() == SUCCESS)) {
            atomic {
                nextPhyState = SELF_POLLING;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            } else {
                sourceDCO();
            }
/*            call HPLTDA5250Config.UseRSSIDataValidDetection(thRssi,
              TH1_VALUE_PREAMBLE, 
              TH2_VALUE_PREAMBLE);
*/
            call HPLTDA5250Config.ResetSelfPollingMode();
            post SignalSelfPollingModeDone();
            spiUnlock();
            releaseBus();
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }
    
    async command result_t TDA5250Modes.RxMode() {
        result_t res;
        phyState_t p;
        busState_t b;
        if(!getTaskLock()) return FAIL;
        atomic b = busState;
        if(b == BUS_REQUESTED) {
            releaseTaskLock();
            releaseBus();
            return FAIL;
        }
        res = SUCCESS;
        if(radioBusy() == FALSE) {
            atomic {
                nextPhyState = RX;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            }
            if((p == SELF_POLLING) || (p == CCA) || (p == RX)) {
                post SignalRxModeDone();
            } else {
                call HPLTDA5250Config.SetRxState();
                releaseTaskLock();
            }
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }

    async command result_t TDA5250Modes.CCAMode() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if(radioBusy() == FALSE) {
            atomic {
                nextPhyState = CCA;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            }
            if((p == CCA) || (p == RX)) {
                post SignalCcaModeDone();
            } else {
                call HPLTDA5250Config.SetRxState();
                releaseTaskLock();
            }
            releaseBus();
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;        
    }
    
    async command result_t TDA5250Modes.SleepMode() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if(radioBusy() == FALSE) {
            atomic {
                nextPhyState = SLEEP;
                p = phyState;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode(); 
            } else {
                sourceDCO();
            }
            call HPLTDA5250Config.SetSleepState();
            releaseTaskLock();
            releaseBus();
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }

    /*************** PacketRx ***************************/
    async command result_t PacketRx.reset() {
        result_t res = FAIL;
        atomic {
            if((nextPhyState == RADIO_IDLE) && (phyState == RX) &&
               (frameState >= FRAMER_IDLE) && (frameState <= RX_DATA))
            {
                if(busState == HAVE_BUS) {
                    frameState = RX_PREAMBLE;
                    res = SUCCESS;
                } else if(busState == BUS_REQUESTED) {
                    releaseBus();
                    busState = WANT_BUS;
                }
            }
        }
        return res;
    }

    /*************** PacketTx ***************************/
    async command result_t PacketTx.start(uint16_t numPreambles) {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = SUCCESS;
        if(radioBusy() == FALSE) {
            atomic {
                nextPhyState = TX;
                p = phyState;
                preamblesToSend = numPreambles;
            }
            if(p >= SLEEP) {
                call HPLTDA5250Config.SetSlaveMode();
            }
            if(p == TX) {
                post SignalTxModeDone();
            } else {
                call HPLTDA5250Config.SetTxState();
                releaseTaskLock();
            }
        } else {
            res = FAIL;
            releaseTaskLock();
        }
        return res;
    }

    async command result_t PacketTx.stop() {
        result_t res;
        phyState_t p;
        frameState_t f;
        res = SUCCESS;
        atomic {
            p = phyState;
            f = frameState;
        }
        res = FAIL;
        if((p == TX) && (f >= TX_PREAMBLE)) {
            while(call HPLTDA5250Data.isTxDone() == FAIL);
            disableUartAndFramer();
            signal PacketTx.done();
            res = SUCCESS;
        } 
        return res;
    }

    /*************** HPLTDA5250Data events **************/
    async event void HPLTDA5250Data.txReady() {
        transmitByte();
    }
    
    async event void HPLTDA5250Data.rxDone(uint8_t data) {
        frameState_t f;
        busState_t b;
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != RADIO_IDLE) for(;;) { ;}
            if(phyState != RX) for(;;) { ;}
            if(usartState != UART_RX) for(;;) { ;}
            if(frameState >= TX_PREAMBLE) for(;;) { ;}
            if(frameState == FRAMER_IDLE) for(;;) { ;}
            if(frameState == RX_PREAMBLE_FROZEN) for(;;) { ;}
#endif
            f = frameState;
            b = busState;
            call TicClock.getTime(&lastRx);
        }
        switch(f) {
            case RX_SYNC:
                if(data != PREAMBLE_BYTE) {
                    if (data == SFD_BYTE) {
                        atomic frameState = RX_DATA;
                        signal PacketRx.detected();
                    }
                    else {
                        atomic frameState = RX_SFD;
                    }
                }
                break;
            case RX_DATA:
                signal ByteComm.rxByteReady(data, 0, 0);
                break;
            case RX_SFD:         
                if (data == SFD_BYTE) {
                    atomic frameState = RX_DATA;
                    signal PacketRx.detected();
                }
                else
                    atomic frameState = RX_PREAMBLE;
                break;
            case RX_PREAMBLE:
                if(data == PREAMBLE_BYTE) {
                    atomic frameState = RX_SYNC;
                } else if(b == BUS_REQUESTED) {
                    freezeRx();
                }
                break;
            default:
                break;
        }
    }

    /*************** ByteComm **************************/
    async command result_t ByteComm.txByte(uint8_t data) {
        call HPLTDA5250Data.tx(data);
        return SUCCESS;
    }

    /*************** BusArbitration ********************/
    event result_t BusArbitration.busReleased() {
        busState_t b;
        frameState_t f;
        phyState_t n,p;
        usartState_t u;
        bool t;
        atomic {
            b = busState;
            f = frameState;
            p = phyState;
            n = nextPhyState;
            t = taskPending;
            u = usartState;
        }
        if(b == WANT_BUS) {
            switch(p) {
                case RADIO_STARTUP:
                    if(getBus() == SUCCESS) setupSystem();
                    break;
                case RX:
                    if((f == RX_PREAMBLE_FROZEN) && (u == SPI_IDLE) &&
                       (n == RADIO_IDLE) && (t == FALSE))
                    {
                        if(tryToGetBus() == SUCCESS) {
                            enableRx();
                            atomic frameState = RX_PREAMBLE;
                        }
                    }
                    break;
                default:
                    break;
            };
        }
        return SUCCESS;
    }

    event result_t BusArbitration.busRequested() {
        busState_t b;
        frameState_t f;
        phyState_t n,p;
        usartState_t u;
        bool t;
        atomic {
            b = busState;
            f = frameState;
            p = phyState;
            n = nextPhyState;
            t = taskPending;
            u = usartState;
        }
        if(b == HAVE_BUS) {
            atomic busState = BUS_REQUESTED;
        }
#ifdef TDA5250_DEBUG
        else {
            for(;;) { ;}
        }
#endif
        if((t == FALSE) && (n == RADIO_IDLE)) {
            if(p == RX) {
                if((f == RX_PREAMBLE) && (u == UART_RX)) {
                    TOSH_uwait(521); // Length of one byte period
                    atomic f = frameState;
                    if(f == RX_PREAMBLE) {
                        freezeRx();
                    }
                }
            } else if(p >= SLEEP) {
                releaseBus();
            }
        }
        return SUCCESS;
    }

    /**************** TDA5250Config *******************/
    command result_t TDA5250Config.reset() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = FAIL;
        atomic p = phyState;
        if((p != RX) && (radioBusy() == FALSE) && (spiLock() == SUCCESS))
        {
            call HPLTDA5250Config.reset();
            spiUnlock();
            res = SUCCESS;
        }
        releaseTaskLock();
        return res;
    }
    
    command result_t TDA5250Config.SetRFPower(uint8_t value) {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = FAIL;
        atomic p = phyState;
        if((p != RX) && (radioBusy() == FALSE) && (spiLock() == SUCCESS))
        {
            call Pot.set(value);
            spiUnlock();
            res = SUCCESS;
        }
        releaseTaskLock();
        return res;
    }

    command result_t TDA5250Config.UseLowTxPower() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = FAIL;
        atomic p = phyState;
        if((p != RX) && (radioBusy() == FALSE) && (spiLock() == SUCCESS))
        {
            call HPLTDA5250Config.UseLowTxPower();
            spiUnlock();
            res = SUCCESS;
        }
        releaseTaskLock();
        return res;
    }
    
    command result_t TDA5250Config.UseHighTxPower() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = FAIL;
        atomic p = phyState;
        if((p != RX) && (radioBusy() == FALSE) && (spiLock() == SUCCESS))
        {
            call HPLTDA5250Config.UseHighTxPower();
            spiUnlock();
            res = SUCCESS;
        }
        releaseTaskLock();
        return res;
    }
    
    command result_t TDA5250Config.LowLNAGain() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = FAIL;
        atomic p = phyState;
        if((p != RX) && (radioBusy() == FALSE) && (spiLock() == SUCCESS))
        {
            atomic thRssi = TH_RSSI_LOWGAIN;
            call HPLTDA5250Config.LowLNAGain();
            spiUnlock();
            res = SUCCESS;
        }
        releaseTaskLock();
        return res;
    }
    
    command result_t TDA5250Config.HighLNAGain() {
        result_t res;
        phyState_t p;
        if(!getTaskLock()) return FAIL;
        res = FAIL;
        atomic p = phyState;
        if((p != RX) && (radioBusy() == FALSE) && (spiLock() == SUCCESS))
        {
            atomic thRssi = TH_RSSI_HIGHGAIN;
            call HPLTDA5250Config.HighLNAGain();
            spiUnlock();
            res = SUCCESS;
        }
        releaseTaskLock();
        return res;
    }
    
    /*************** HPLTDA5250Config events ***********/
    event void HPLTDA5250Config.SetTxStateDone() {
        atomic {
            if((nextPhyState == TX) && (taskPending == FALSE)) {
                taskPending = TRUE;
                post SignalTxModeDone();
            }
        }
    }
    
    event void HPLTDA5250Config.SetRxStateDone() {
        atomic {
            if((nextPhyState == RX) && (getTaskLock())) {
                post SignalRxModeDone();
            }
        }
    }

    event void HPLTDA5250Config.SetSleepStateDone() {
        atomic {
            if((nextPhyState == SLEEP) && (getTaskLock())) {
                post SignalSleepModeDone();
            }
        }
    }
    
    event void HPLTDA5250Config.RSSIStable() {
        atomic {
            if((nextPhyState == CCA) && (getTaskLock())) {
                post SignalCcaModeDone();
            }
        }
    }

    async event void HPLTDA5250Config.PWD_DDInterrupt() {
        signal TDA5250Modes.interrupt();
    }

    event void HPLTDA5250Config.ready() {
        if(getBus() == SUCCESS) setupSystem();
    }

    /*************** FrameSync **************************/
    async command bool FrameSync.isReceiving() {
        result_t res;
        ticval_t now, lRx;
        int16_t delta;
        atomic lRx = lastRx;
        call TicClock.getTime(&now);
        res = call TicDelta.getDelta(&lRx, &now, &delta);
        if(res == FAIL) return FALSE;
        if((-2*BYTE_DURATION < delta) && (delta <= 0)) return TRUE;
        return FALSE;
    }


    /*************** StdControl ************************/
    command result_t StdControl.init() {
        atomic {
            usartState = SPI_IDLE;
            frameState = FRAMER_IDLE;
            busState = BUS_RELEASED;
            phyState = RADIO_STARTUP;
            nextPhyState = RADIO_STARTUP;
            thRssi = TH_RSSI_HIGHGAIN;
            taskPending = FALSE;
        }
        sourceDCO();
        return call PotControl.init();
    }

    command result_t StdControl.start() {
        return call PotControl.start();
    }

    command result_t StdControl.stop() {
        return call PotControl.stop();
    }

    /*************** bus helper functions *****************************/
    result_t getBus() {
        result_t res = FAIL;
        busState_t b;
        atomic b = busState;
        if(b >= HAVE_BUS) {
            res = SUCCESS;
        } else {
            res = call BusArbitration.getBus();
            if(res == SUCCESS) {
                atomic busState = HAVE_BUS;
            } else {
                atomic busState = WANT_BUS;
            }
        }
        return res;
    };

    result_t tryToGetBus() {
        result_t res = FAIL;
        busState_t b;
        atomic b = busState;
        if(b >= HAVE_BUS) {
            res = SUCCESS;
        } else {
            res = call BusArbitration.getBus();
            if(res == SUCCESS) atomic busState = HAVE_BUS;
        }
        return res;
    };
    
    void releaseBus() {
        busState_t b;
        atomic b = busState;
        if(b == BUS_REQUESTED) {
            disableUartAndFramer();
            call BusArbitration.releaseBus();
            atomic {
                busState = BUS_RELEASED;
                usartState = SPI_IDLE;
            }
        }
    };

    void freezeRx() {
        call HPLTDA5250Data.disableRx();
        atomic {
            usartState = SPI_IDLE;
            frameState = RX_PREAMBLE_FROZEN;
            busState = WANT_BUS;
            call BusArbitration.releaseBus();
        }
    }
    
    /************* transmitByte *******************************/
    void transmitByte() {
        frameState_t f;
        atomic {
#ifdef TDA5250_DEBUG
            if(nextPhyState != RADIO_IDLE) for(;;) { ;}
            if(phyState != TX) for(;;) { ;}
            if(usartState != UART_TX) for(;;) { ;}
            if(frameState < TX_PREAMBLE) for(;;) { ;}
#endif
            f = frameState;
        }
        switch(f) {   
            case TX_PREAMBLE:
                atomic {
                    if(preamblesToSend > 0) {
                        preamblesToSend--;
                    }
                    else {
                        frameState = TX_SYNC;
                    }
                }
                call HPLTDA5250Data.tx(PREAMBLE_BYTE);
                break;
            case TX_SYNC:
                atomic frameState = TX_SFD;
                call HPLTDA5250Data.tx(SYNC_BYTE);
                break;
            case TX_SFD:
                atomic frameState = TX_DATA;
                call HPLTDA5250Data.tx(SFD_BYTE);
                break;
            case TX_DATA:
                signal ByteComm.txByteReady(SUCCESS);  
                break;
            default:
                break;                     
        }
    }
    

    /************* usart helper functions *********************/
    result_t enableRx() {
        usartState_t u;
        result_t res = SUCCESS;
        atomic u = usartState;
        switch(u) {
            case UART_TX:
            case SPI_LOCKED:
                res = FAIL;
                break;
            case UART_RX:
                break;
            default:
                atomic usartState = UART_RX;
                call HPLTDA5250Data.enableRx();
                break;
        }
        return res;
    }

    result_t enableTx() {
        usartState_t u;
        result_t res = SUCCESS;
        atomic u = usartState;
        switch(u) {
            case UART_RX:
            case SPI_LOCKED:
                res = FAIL;
                break;
            case UART_TX:
                break;
            default:
                atomic usartState = UART_TX;
                call HPLTDA5250Data.enableTx();
                break;
        }
        return SUCCESS;
    }
    
    result_t disableUartAndFramer() {
        usartState_t u;
        atomic u = usartState;
        if(u == UART_RX) {
            call HPLTDA5250Data.disableRx();
            atomic {
                usartState = UART_RX_DISABLED;
                frameState = FRAMER_IDLE;
            }
        } else if(u == UART_TX) {
            call HPLTDA5250Data.disableTx();
            atomic {
                usartState = UART_TX_DISABLED;
                frameState = FRAMER_IDLE;
            }
        }
        return SUCCESS;
    }
    
    result_t spiLock() {
        result_t res = SUCCESS;
        atomic {
            if(usartState >= SPI_LOCKED) {
                res = FAIL;
            } else {
                call HPLTDA5250Config.enableSPI();     
                usartState = SPI_LOCKED;
            }
        }
        return res;
    }

    result_t spiUnlock() {
        atomic usartState = SPI_IDLE;
        return SUCCESS;
    }
    
    /**************** radio busy check ************************/
    bool radioBusy() {
        bool r;
        phyState_t p,n;
        frameState_t f;
        usartState_t u;
        atomic {
            p = phyState;
            n = nextPhyState;
            f = frameState;
            u = usartState;
        }
        r = TRUE;
        if((n == RADIO_IDLE) && (tryToGetBus() == SUCCESS))
        {
            if((u == UART_RX) && (f >= RX_PREAMBLE) && (f <= RX_DATA))
            {
                if(disableUartAndFramer() == SUCCESS) r = FALSE;
            }
            else if((u == SPI_IDLE) && (f == RX_PREAMBLE_FROZEN))
            {
                atomic frameState = FRAMER_IDLE;
                r = FALSE;
            }
            else if(u <= UART_RX_DISABLED)
            {
                r = FALSE;
            }
        }
        return r;
    }

    
    /************* other helper functions *********************/
    void setupSystem() {
        if(getTaskLock() == FAIL) {
            releaseBus();
            post SetupSystemTask();
            return;

        }
        if(spiLock() == FAIL) {
            releaseBus();
            releaseTaskLock();
            post SetupSystemTask();
            return;
        }
        sourceXT2();
        call Pot.set(255);
        call HPLTDA5250Config.reset();     
        call HPLTDA5250Config.UsePeakDetector();
        call HPLTDA5250Config.UseRSSIDataValidDetection(thRssi,
                                                        TH1_VALUE_RX, 
                                                        TH2_VALUE_RX);
        atomic {
            phyState = RADIO_IDLE;
            nextPhyState = RADIO_IDLE;
        }
        spiUnlock();
        releaseTaskLock();
        signal TDA5250Config.ready();
        signal TDA5250Modes.ready();     
    }

    void sourceDCO() {
/* #ifdef TDA5250_DEBUG
   atomic fromXT2 = FALSE;
   #endif
   call HPLTDA5250Config.sourceSMCLKfromDCO();
*/
    }
    
    void sourceXT2() {
/*
  #ifdef TDA5250_DEBUG
  atomic fromXT2 = TRUE;
  #endif
  call HPLTDA5250Config.sourceSMCLKfromRadio();
*/
    }
    
    /*************** default events *********************/
    default async event result_t ByteComm.txDone() {
        return SUCCESS;
    }
    default async event result_t ByteComm.txByteReady(bool success) {
        return success;
    }
    default async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {
        return SUCCESS;
    }
    default async event void PacketRx.detected() {
    }
    default async event void TDA5250Modes.interrupt() {
    }   
    default event result_t TDA5250Modes.RxModeDone(){
        return SUCCESS;
    }
    default event result_t TDA5250Modes.SleepModeDone(){
        return SUCCESS;
    }
    default event result_t TDA5250Modes.CCAModeDone(){
        return SUCCESS;
    }  
    default event result_t TDA5250Config.ready() {
        return SUCCESS;
    }
    default event result_t TDA5250Modes.ready(){
        return SUCCESS;
    }
}
