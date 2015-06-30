/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#define BAUD_115200 eTM_B115200
#define BAUD_230400 eTM_B230400
#define BAUD_460800 eTM_B460800
#define BAUD_921600 eTM_B921600   // not tested
#define NEW_SENSOR 1

module SensorM {
    provides {
        interface Sensor;
        interface StdControl;
    }
    uses {
        interface HPLUART;
        interface HPLDMA;
        interface Memory;
        interface StatsLogger;
    }
}
implementation {
    
    extern tTOSBufferVar *TOSBuffer __attribute__ ((C)); 
    uint8 clkDiv;
    
    uint8 *RxBuffer, *UARTBuffer;
    uint8 BufferSize;

    int rxBytesTotal, rxBytesCurrent;
    int bytesPerSample, numSamples;
    uint8 CurrentSensor;
    
    bool  TurnedOnBoard;
    bool AcquiringSamples;

    
    command result_t StdControl.init() {
        clkDiv = BAUD_460800;
        //clkDiv = BAUD_115200;
        TurnedOnBoard = false;
        AcquiringSamples = false;
        call HPLUART.setRate(clkDiv);
        call HPLUART.init();

        /*
         * Sensor Board interface : All pins assumed active high
         * pins [0 - 2] : Sensor Selection, 
         * pin 3 : power on board, 
         * pin 7 : collect Samples
         */
       
        TM_ResetPio(0);
        TM_ResetPio(1);
        TM_ResetPio(2);
        TM_ResetPio(3);
        TM_SetPio(7);

        TM_SetPioAsOutput(0);
        TM_SetPioAsOutput(1);
        TM_SetPioAsOutput(2);
        TM_SetPioAsOutput(3);
        TM_SetPioAsOutput(7);

        bytesPerSample = 2; // default 2 bytes per sample
        RxBuffer=0;
        UARTBuffer=0;
        BufferSize=0;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        // Turn on board
        TM_SetPio(3);
        TurnedOnBoard = true;
        call StatsLogger.StartTimer(MSEC_SENSOR_BOARD_ON);
        return SUCCESS;
    }
    
    command result_t StdControl.stop() {
        // Turn off board
        TM_ResetPio(3);
        TurnedOnBoard = false;
        TM_SetPio(7);
        AcquiringSamples=false;
        call StatsLogger.StopTimerUpdateCounter(MSEC_SENSOR_BOARD_ON);
        return SUCCESS;
    }
    
    command result_t Sensor.SetSamplingRate(uint8 SensorID, uint32 SamplingRate) {
        
        // Do nothing for now
        return SUCCESS;
    }
    
    // SampleWidth is in bytes per sample
    command result_t Sensor.SetSampleWidth(uint8 SensorID, uint8 SampleWidth) {
        bytesPerSample = SampleWidth;
        return SUCCESS;
    }
    
    result_t SelectSensor(uint8 SensorID) {
        
        // Select the sensor
        TM_SetPioAsOutput(0);
        TM_SetPioAsOutput(1);
        TM_SetPioAsOutput(2);

        if (SensorID & 1) {
            TM_SetPio(0);
        } else {
            TM_ResetPio(0);
        }
        if (SensorID & 2) {
           TM_SetPio(1);
        } else {
           TM_ResetPio(1);
        }
        if (SensorID & 4) {
           TM_SetPio(2);
        } else {
           TM_ResetPio(2);
        }
        
        return SUCCESS;
    }
    
    command result_t Sensor.SelectSensor(uint8 SensorID) {
        if (AcquiringSamples) {
          return FAIL;
        }
        SelectSensor(SensorID);
        return SUCCESS;
    }
    
    command result_t Sensor.AcquireSamples(uint8 SensorID,
                                           uint8 *Buffer,
                                    uint16 NumSamples) {
        
        if (!TurnedOnBoard || AcquiringSamples) {
            return FAIL;
        }
        
        if (CurrentSensor != SensorID) {
            CurrentSensor = SensorID;
            SelectSensor(SensorID);
        }

        //remember buffer that we want to store into
        RxBuffer = Buffer;
        
        
        rxBytesCurrent = 0;
        rxBytesTotal = (int) NumSamples*bytesPerSample;
        //rxBytesLeft = (int) NumSamples*bytesPerSample;
        numSamples = NumSamples;
        AcquiringSamples = true;
        
        
#if 0
        //allocate the buffer to be used by the UART and start collecting
        if(!UARTBuffer){
            if((UARTBuffer = call Memory.alloc(100))){
                BufferSize=100;
                
            }
            else{
                UARTBuffer=TOSBuffer->UARTRxBuffer;
                BufferSize=32;
            }
        }
#endif
            //something is wrong and the UART is not empty
        if(TM_MainUartReg->lineStatus & TM_UART_RX_READY_MASK){
            TM_SetPioAsOutput(4);
            TM_SetPioAsOutput(5);
            TM_SetPioAsOutput(6);
            TM_SetPio(4);
            TM_ResetPio(5);
            TM_SetPio(6);
            while(1);
        }
        
        call HPLDMA.DMAGet(RxBuffer, rxBytesTotal);
        TM_ResetPio(7);
        
        return SUCCESS;
    }
    
    command result_t Sensor.AbortCollection() {
        if (!AcquiringSamples) {
            return FAIL;
        }
        
        atomic {
            TM_SetPio(7);
            AcquiringSamples = false;
        }
        
        SelectSensor(0);
        return SUCCESS;
    }
    task void SignalSamplesAcquired(){
        // signal Sensor.SamplesAcquired(CurrentSensor, RxBuffer, rxBytesCurrent/bytesPerSample);
        signal Sensor.SamplesAcquired(CurrentSensor, RxBuffer, numSamples);
        return;
    }
    
    async event uint8 *HPLDMA.DMAGetDone(uint8 *data, uint16 NumBytes) {
        if(AcquiringSamples){
            if(NumBytes!=rxBytesTotal){
                TM_SetPioAsOutput(4);
                TM_SetPioAsOutput(5);
                TM_SetPioAsOutput(6);
                
                TM_ResetPio(4);
                TM_ResetPio(5);
                TM_SetPio(6);
                while(1);
            }           
            rxBytesCurrent+=NumBytes;
            TM_SetPio(7);
            AcquiringSamples = false;
            //signal Sensor.SamplesAcquired(CurrentSensor, RxBuffer, numSamples);
            post SignalSamplesAcquired();
            //return UARTBuffer;
        }
        return NULL;
    }
    
    async event result_t HPLDMA.DMAPutDone(uint8 *data) {
        return SUCCESS;
    }   

    async event result_t HPLUART.get(uint8 data){
        return SUCCESS;
    }
    
    async event result_t HPLUART.putDone(){
        return SUCCESS;
    }
}
    
