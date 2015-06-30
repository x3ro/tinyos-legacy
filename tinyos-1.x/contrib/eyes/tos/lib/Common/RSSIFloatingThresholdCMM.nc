/*
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
 * $Revision: 1.2 $
 * $Date: 2005/01/26 17:02:47 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

includes shellsort;
 
module RSSIFloatingThresholdCMM {
   provides {
      interface StdControl;
      interface ChannelMonitor;
      interface RSSIRegulator;
   }
   uses {     
      interface MSP430ADC12Single as RSSIValueADC;
      interface MSP430ADC12Multiple as RSSIQueryADC;
   }
}
implementation
{
   #define RSSI_INIT_THRESHOLD            0x111  // 100 mV
   #define RSSI_INIT_FLOOR                0x3BB  // 350 mV
   #define NUM_RSSI_SAMPLES               16
   #define TIME_BETWEEN_SAMPLES           8
   #define QUEUE_SIZE                     10
   #define WEIGHT                         0.75
     
   uint16_t rssiValue[NUM_RSSI_SAMPLES];
   uint16_t rssiThreshold;
      
   norace uint16_t rssiFloor;
   norace uint16_t floorQueue[QUEUE_SIZE];   
   norace int queueHead;
   
   
   void CheckRSSIValues();
   void AdjustNoiseFloor(uint16_t value);
  
   command result_t StdControl.init() {
      uint8_t i;
      atomic {
        for(i=0; i<NUM_RSSI_SAMPLES; i++) 
          rssiValue[i] = 0;
        for(i=0; i<QUEUE_SIZE; i++)
          floorQueue[i] = RSSI_INIT_FLOOR;
        rssiThreshold = RSSI_INIT_THRESHOLD;
        rssiFloor = RSSI_INIT_FLOOR;
        queueHead = 0;
      }
      return SUCCESS;
   }
   
   command result_t StdControl.start() {
     call RSSIValueADC.bind(MSP430ADC12_RSSI_SETTINGS); 
     call RSSIQueryADC.bind(MSP430ADC12_RSSI_SETTINGS);
     return SUCCESS;
   }
   
   command result_t StdControl.stop() {
      return SUCCESS;
   }
     
   task void ReadRSSI() {
     if(call RSSIQueryADC.getData(rssiValue, NUM_RSSI_SAMPLES, TIME_BETWEEN_SAMPLES) == MSP430ADC12_FAIL)
       post ReadRSSI();
   }
     
   command result_t RSSIRegulator.setThreshold(uint16_t level) {
      atomic rssiThreshold = level;
      return SUCCESS;
   }
   
   command result_t RSSIRegulator.setNoiseFloor(uint16_t data) {
     int i;
     atomic {
       rssiFloor = data;
       for(i=0; i<QUEUE_SIZE; i++)
         floorQueue[i] = data;      
     }
     return SUCCESS;
   }
       
   command result_t ChannelMonitor.start() {
      post ReadRSSI();
      return SUCCESS;
   }
   
   async command result_t RSSIRegulator.updateNoiseFloor() {
     if(call RSSIValueADC.getData() == MSP430ADC12_FAIL)
       return FAIL;
     return SUCCESS;
   }
  
   async event result_t RSSIValueADC.dataReady(uint16_t data) {
     AdjustNoiseFloor(data);
     return SUCCESS;
   }

   async event uint16_t* RSSIQueryADC.dataReady(uint16_t *buf, uint16_t length) {
     CheckRSSIValues();
     return buf;
   }

  void CheckRSSIValues() {
    int i;
    for(i=0; i<NUM_RSSI_SAMPLES; i++) {
      if(rssiValue[i] > (rssiFloor + rssiThreshold)) {
        if(signal ChannelMonitor.channelBusy() == FAIL)
          post ReadRSSI();
        return;
      }
    }
    if(signal ChannelMonitor.channelIdle() == FAIL)
      post ReadRSSI();
  }
  
  void AdjustNoiseFloor(uint16_t value) {
    uint16_t m;
    uint16_t tempQueue[QUEUE_SIZE];
        
    floorQueue[queueHead++] = value;
    for(m=0; m<QUEUE_SIZE; m++)
      tempQueue[m] = floorQueue[m];
    if(queueHead == QUEUE_SIZE)
      queueHead = 0;
    
    shellsort(tempQueue, QUEUE_SIZE);
    m = tempQueue[QUEUE_SIZE/2];
    rssiFloor = WEIGHT*(float)rssiFloor + (1.0-WEIGHT)*(float)m;
    signal RSSIRegulator.updateNoiseFloorDone();
  }
  
  default async event result_t RSSIRegulator.updateNoiseFloorDone() {
    return SUCCESS;
  }
}
