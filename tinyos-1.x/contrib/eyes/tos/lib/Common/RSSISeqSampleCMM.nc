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
 * - Description ----------------------------------------------------------
 * 
 * Implementation of Clear Channel Assessment based on sequential sampling 
 * of RSSI
 *
 * - Author --------------------------------------------------------------
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

includes shellsort;
module RSSISeqSampleCMM {
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

    /*
     * These constants stem from the application of 
     * sequential sampling theory
     */

    // mu + 3*sigma -> rare event, outlier? 
#define THREE_SIGMA          105    

// 31 * delta/(2*sigma**2), sigma = 35 mV
#define SEQ_SAMPLING_DIVISOR 1      

// difference between the two hypothesis [mV]
#define SEQ_SAMPLING_DELTA  110

// 31*log(0.10/0.90) if below this threshold: channel free 
#define SEQ_SAMPLING_LOG_B -49

// 31 * log(0.9/0.1) if above this threshold: channel busy
#define SEQ_SAMPLING_LOG_A  49

// max number of times to measure before giving up
#define SEQ_SAMPLING_MAX_TRIALS 20  

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
        
    // sequential sampling
    uint8_t counter;
    int16_t sumzi;

    // last rssi reading
    int16_t rssi;           // rssi in [mV]
    
    /****************  Tasks  *******************/
    task void UpdateNoiseFloorTask();
    task void GetChannelStateTask();
    task void CcaCheckValueTask();
    task void SnrReadyTask();
    task void CalibrateNoiseFloorTask();
    task void GetSnrTask();
    task void CalibrateTask();
    task void RescheduleTask();


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
            sumzi = 0;
            counter = 0;
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
                    res = post CcaCheckValueTask();
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
    command result_t ChannelMonitor.start() {
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
        sumzi = 0;
        counter = 0;
        atomic state = IDLE;
    }

    void addSample()  {
        atomic {
            if(rssiindex < NSAMPLES) rssisamples[rssiindex++] = rssi;
            deadlockCounter = 0;
        }
        if(rssiindex >= NSAMPLES) post UpdateNoiseFloorTask();
    }
               
    
    void channelBusy () {
        int16_t snr;
        atomic {
            if(++deadlockCounter >= DEADLOCK)
                addSample();
            snr = computeSNR();
        }
        resetState();
        signal ChannelMonitor.channelBusy(snr);
    }

    void channelIdle() {
        addSample();
        resetState();
        signal ChannelMonitor.channelIdle();
    }

    task void CcaCheckValueTask() {
        uint16_t data;
        atomic data = rssi;

        // update seq sampling estimator
        counter++;
        sumzi = sumzi + (((int16_t)data*2)-((int16_t)noisefloor*2)-SEQ_SAMPLING_DELTA)/
            SEQ_SAMPLING_DIVISOR;

        // seq sampling decision 
        if((sumzi <= SEQ_SAMPLING_LOG_B) || (counter > SEQ_SAMPLING_MAX_TRIALS)) {
            channelIdle();
        }
        else if(sumzi >= SEQ_SAMPLING_LOG_A) {
            channelBusy();
        }
        else {
            call RSSImV.getData();
        }
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
        uint16_t data;
        atomic data = rssi;

        if(rssiindex < NSAMPLES) {
            rssisamples[rssiindex++] = data;
        } else { 
            shellsort(rssisamples,NSAMPLES);
            if(rssisamples[MINIMUM_POSITION] < noisefloor + THREE_SIGMA) 
            {
                atomic noisefloor = (7*noisefloor + rssisamples[NSAMPLES/2])/8;
                ++deadlockCounter;
            }
            else 
            {
                atomic noisefloor += THREE_SIGMA/8;
            }
            rssiindex = 0; 
        }

        if(deadlockCounter < UPDATE_NF_RUNS) {
            if(call Timer.setOneShot(TIMER_INTERVAL) == FAIL) {
                post RescheduleTask();
            }
        } else {
            atomic {
                state = IDLE;
                deadlockCounter = 0;
            }
            signal ChannelMonitorControl.updateNoiseFloorDone();
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

