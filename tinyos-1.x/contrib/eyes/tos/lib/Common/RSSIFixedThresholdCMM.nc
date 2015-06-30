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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006/03/02 11:52:39 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

includes shellsort;
module RSSIFixedThresholdCMM {
    provides {
        interface StdControl;
        interface ChannelMonitor;
        interface ChannelMonitorControl;
        interface ChannelMonitorData;
    }
    uses {     
        interface RSSImV;
        interface TimerMilli as Timer;
    }
}
implementation
{

    /* 
     * Number of samples for noisefloor estimation
     * Actually the size of the array for the median
     */
#define NSAMPLES 5
        
    /*
     * If the channel is seen more then DEADLOCK times 
     * in a row busy, update noisefloor nonetheless.
     */
#define DEADLOCK 10
        
    /* 
     * Initital noisefloor from data sheet ca. 350mV 
     * Seems to depend on many things, usually values around
     * 250 mV are observed for the eyesIFXv2 node, but 450 has also 
     * been measured as noise floor. It is also not stable, depending
     * on the placement of the node (USB cable shielding!) 
     */
#define NOISE_FLOOR 350

#define DELTA 93

    // mu + 3*sigma -> rare event, outlier? 
#define THREE_SIGMA          105    

    /*** calibration stuff *************************/
#define UPDATE_NF_RUNS   50
#define MINIMUM_POSITION 0
#define TIMER_INTERVAL   20 // it makes no sense to check the channel too often

    /*** variable type definitions ******************/
    typedef enum {
        VOID,
        CALIBRATE, // update noisefloor
        IDLE,      // noisefloor up to date, nothing is currently attempted
        CCA,       // in clear channel assessment
        SNR        // measureing SNR
    } state_t;
    
    /****************  Variables  *******************/
    state_t state;       // what we try to do
    int16_t gradient;    // how to convert mV to dB in mV/dB

    uint16_t noisefloor; // [mV]

    // noise floor estimation
    int16_t rssisamples[NSAMPLES];
    uint8_t rssiindex;

    // deadlock protection counter
    uint8_t deadlockCounter;

    // last rssi reading
    int16_t rssi;           // rssi in [mV]
    
    /****************  Tasks  *******************/
    task void UpdateNoiseFloorTask();
    task void GetChannelStateTask();
    task void SnrReadyTask();
    task void CalibrateNoiseFloorTask();
    task void GetSnrTask();
    task void CalibrateTask();
    task void RescheduleTask();
    result_t ccaCheckValue();

    /***************** Helper function *************/
    int16_t computeSNR() {
        int16_t delta = rssi - noisefloor;
        delta = delta/(int16_t)gradient;
        if(delta < 0) delta = 0;
        return delta;
    }

    /**************** StdControl *******************/
    command result_t StdControl.init() {
        atomic {
            noisefloor = NOISE_FLOOR;
            rssiindex = 0;
            state = VOID;
            gradient = 14; // gradient of TDA5250
        }
        return SUCCESS;
    }
   
    command result_t StdControl.start() { 
        return SUCCESS;
    }
   
    command result_t StdControl.stop() {
        return call Timer.stop();
    }
     
    /**************** RSSI *******************/

    async event result_t RSSImV.dataReady(uint16_t data) {
        result_t res = SUCCESS;
        atomic {
            rssi = data;
            switch(state) 
            {
                case CCA:
                    res = ccaCheckValue();
                    break;
                case SNR:
                    res = post SnrReadyTask();    
                    break;
                case CALIBRATE:
                    res = post CalibrateNoiseFloorTask();    
                    break;
                default:
                    break;
            }
        }
        return res;
    }
    
    /**************** ChannelMonitor *******************/  
    async command result_t ChannelMonitor.start() {
        result_t res;
        atomic {
            if(state != VOID) {
                res = post GetChannelStateTask();
            } else {
                res = FAIL;
            }
        }
        return res;
    }

    async command void ChannelMonitor.rxSuccess() {
        atomic {
            if((deadlockCounter > 0) && (deadlockCounter < DEADLOCK)) {
                --deadlockCounter;
            }
        }
    }
    
    task void GetChannelStateTask() {
        atomic {
            if(state != IDLE) {
                post GetChannelStateTask();
            } else {
                state = CCA;
                call RSSImV.getData();
            }
        }
    }

    void resetState() {
        state = IDLE;
    }

    void addSample()  {
        if(rssiindex < NSAMPLES) rssisamples[rssiindex++] = rssi;
        deadlockCounter = 0;
        if(rssiindex >= NSAMPLES) post UpdateNoiseFloorTask();
    }
               
    
    void channelBusy () {
        atomic {
            if(++deadlockCounter >= DEADLOCK) addSample();
            resetState();
        }
        signal ChannelMonitor.channelBusy(computeSNR());
    }

    void channelIdle() {
        atomic {
            addSample();
            resetState();
        }
        signal ChannelMonitor.channelIdle();
    }

    result_t ccaCheckValue() {
        uint16_t data;
        atomic data = rssi;
        if(data < noisefloor + DELTA) {
            channelIdle();
        } else {
            channelBusy();
        }
        return SUCCESS;
    }

    task void UpdateNoiseFloorTask() {
        shellsort(rssisamples,NSAMPLES);
        atomic { 
            noisefloor = (5*noisefloor + rssisamples[NSAMPLES/2])/6;
            rssiindex = 0; 
        }
    }

    /**************** ChannelMonitorControl ************/ 

    command async result_t ChannelMonitorControl.updateNoiseFloor() {
        return post CalibrateTask();
    }

    task void CalibrateTask() {
        atomic {
            if((state != IDLE) && (state != VOID)) {
                post CalibrateTask();
            } else {
                state = CALIBRATE;
                deadlockCounter = 0;
                call RSSImV.getData();
            }
        }
    }

    task void CalibrateNoiseFloorTask() {
        atomic {
            if(rssiindex < NSAMPLES) {
                rssisamples[rssiindex++] = rssi;
            } else { 
                shellsort(rssisamples,NSAMPLES);
                if(rssisamples[MINIMUM_POSITION] < noisefloor + THREE_SIGMA) 
                {
                    noisefloor = (7*noisefloor + rssisamples[NSAMPLES/2])/8;
                    ++deadlockCounter;
                }
                else 
                {
                    noisefloor += THREE_SIGMA/8;
                }
                rssiindex = 0; 
            }

            if(deadlockCounter < UPDATE_NF_RUNS) {
                if(call Timer.setOneShot(TIMER_INTERVAL) == FAIL) {
                    post RescheduleTask();
                }
            } else {
                state = IDLE;
                deadlockCounter = 0;
                signal ChannelMonitorControl.updateNoiseFloorDone();
            }
        }
        
    }

    event result_t Timer.fired() {
        call RSSImV.getData();
        return SUCCESS;
    }

    task void RescheduleTask() {
        if(call Timer.setOneShot(TIMER_INTERVAL) == FAIL) {
            post RescheduleTask();
        }
    }

    /**************** ChannelMonitorData ************/  
    async command result_t ChannelMonitorData.setGradient(int16_t grad) {
        // needed to convert RSSI into dB
        atomic gradient = grad;
        return SUCCESS;
    }
    
    async command int16_t ChannelMonitorData.getGradient() {
        int16_t v;
        atomic v = gradient;
        return v;
    }
    
    async command uint16_t ChannelMonitorData.getNoiseFloor() {
        uint16_t v;
        atomic v = noisefloor;
        return v;
    }

    /** get SNR in dB **/

    async command result_t ChannelMonitorData.getSnr() {
        result_t res;
        atomic {
            if(state != VOID) {
                res = post GetSnrTask();
            } else {
                res = FAIL;
            }
        }
        return res;
    }

    task void GetSnrTask() {
        atomic {
            if(state != IDLE) {
                post GetSnrTask();
            } else {
                state = SNR;
                call RSSImV.getData();
            }
        }
    }
    
    task void SnrReadyTask() {
        int16_t snr;
        atomic {
            snr = computeSNR();
            state = IDLE;
        }
        signal ChannelMonitorData.getSnrDone(snr);
    }

    default async event result_t ChannelMonitorData.getSnrDone(int16_t snr) {
        return SUCCESS;
    }
}
