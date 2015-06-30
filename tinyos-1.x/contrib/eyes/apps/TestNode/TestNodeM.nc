/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2005, Technische Universitaet Berlin
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
 * test all components of a node
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */
includes shellsort;

module TestNodeM {
    provides {
        interface StdControl;
    }
    uses {
        interface LedsNumbered as Leds;
        interface ReceiveMsg;
	interface BareSendMsg;
        interface PageEEPROM;
        interface TimerMilli as StepTimer;
        interface ADC as PhotoADC;
        interface ADC as TempADC;
    }
}
implementation {
#define MAX_PAGES 2048
#define MAX_SEND  20
#define MAX_PAGE_LENGTH 264
#define PATTERN1 0x00
#define PATTERN2 0xaa
#define MEDIAN_SIZE 9
#define MAX_READINGS 1000
#define TIME_BETWEEN_SAMPLES 20
    
    typedef enum {
        FLASH_P1,
        FLASH_P2,
        RADIO,
        PHOTO,
        TEMP
    } testState_t;
    
    norace TOS_Msg msg;  
    bool sending;
    uint16_t counter;
    testState_t state;
    unsigned readings[MEDIAN_SIZE];
    unsigned readIndex;
    unsigned level;
    uint8_t flashData[MAX_PAGE_LENGTH];
    unsigned exceedCounter;
    
    /*--------- Flash Tests --------------------*/    
    task void EraseTask() {
        if(call PageEEPROM.erase(counter, TOS_EEPROM_ERASE) == SUCCESS) {
            counter++;
            call Leds.led0Toggle();
        } else {
            call Leds.led0On();
            post EraseTask();
        }
    }

    task void WriteTask() {
        if(call PageEEPROM.write(counter, 0, flashData, MAX_PAGE_LENGTH) == SUCCESS) {
            counter++;
            call Leds.led0Toggle();
        } else {
            call Leds.led0On();
            post WriteTask();
        }
    }

    task void InitP1Task() {
        unsigned i;
        for(i = 0; i < MAX_PAGE_LENGTH; i++) {
            flashData[i] = PATTERN1;
        }
        post WriteTask();
    }
    
    task void InitP2Task() {
        unsigned i;
        for(i = 0; i < MAX_PAGE_LENGTH; i++) {
            flashData[i] = PATTERN2;
        }
        post WriteTask();
    }
    
    task void CheckPageTask() {
        unsigned i;
        for(i = 0; i<MAX_PAGE_LENGTH;i++) flashData[i] = 0;
        if(call PageEEPROM.read(counter, 0, &flashData, MAX_PAGE_LENGTH) == SUCCESS) {
            counter++;
            call Leds.led0Toggle();   
        } else {
            call Leds.led0On();
            post CheckPageTask();
        }
    }
    
    
    event result_t PageEEPROM.eraseDone(result_t result) {
        if(result == SUCCESS) {
            if(counter < MAX_PAGES) {
                post EraseTask();
            } else {
                counter = 0;
                if(state == FLASH_P1) {
                    post InitP1Task();
                }
                else if(state == FLASH_P2) {
                    post InitP2Task();
                }
            }
        } else {
            call Leds.led0On();
        }
        return SUCCESS;
    }
        
    event result_t PageEEPROM.writeDone(result_t result) {
        if(result == SUCCESS) {
            call PageEEPROM.flush(counter);
        } else {
            call Leds.led0On();
        }
        return SUCCESS;
    }
    
    event result_t PageEEPROM.flushDone(result_t result) {
        if(result == SUCCESS) {
            if(counter < MAX_PAGES) {
                post WriteTask();
            } else {
                counter = 0;
                post CheckPageTask();
            }
        } else {
            call Leds.led0On();
        }
        return SUCCESS;
    }

    event result_t PageEEPROM.readDone(result_t result) {
        unsigned i;
        uint8_t pattern;
        bool read = TRUE;
        
        if(state == FLASH_P1) {
            pattern = PATTERN1;
        } else {
            pattern = PATTERN2;
        }
        if(result == SUCCESS) {
            for(i = 0; i < MAX_PAGE_LENGTH; i++) {
                if(flashData[i] != pattern) read = FALSE;
            }
            if(counter < MAX_PAGES) {
                if(read) {
                    post CheckPageTask();
                } else {
                    call Leds.led0On();
                }
            } else {
                if(state == FLASH_P1) {
                    counter = 0;
                    state = FLASH_P2;
                    post EraseTask();
                }
                else if(state == FLASH_P2) {
                    call Leds.led0Off();
                    state = PHOTO;
                    counter = 0;
                    atomic readIndex = 0;
                    exceedCounter = 0;
                    call StepTimer.setOneShot(TIME_BETWEEN_SAMPLES);
                }
            }
        } else {
            call Leds.led0On();
        }
        return SUCCESS;
    }
    
    event result_t PageEEPROM.syncDone(result_t result) {
        return SUCCESS;
    }

    event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
        return SUCCESS;
    }
    
    /*--------- Radio Tests --------------------*/
    result_t sendMsg() {
        result_t res;
        if(sending == FALSE) {
            call Leds.led3On();
            msg.length = 20;
            msg.type = 30;
            msg.seq_num = counter;
            msg.addr = 30;
            msg.s_addr = TOS_LOCAL_ADDRESS;
            res = call BareSendMsg.send(&msg);
        } else {
            res = SUCCESS;
        }
        return res;
    }

    task void SendMsgTask()  {
        if(sendMsg() == FAIL) {
            post SendMsgTask();
        } else {
            sending = TRUE;
        }
    }

    event result_t BareSendMsg.sendDone(TOS_MsgPtr m, result_t success){
        sending = FALSE;
        call StepTimer.setOneShot(1000);
        call Leds.led3Off();
        return SUCCESS;
    }
    
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
        uint16_t strength;
        if(state == RADIO) {
            if(m->addr==TOS_LOCAL_ADDRESS) {
                counter++;
                ((uint8_t *)(&strength))[0] = m->data[0];
                ((uint8_t *)(&strength))[1] = m->data[1];
                if(level > 0) {
                    level = ((uint32_t)15*(uint32_t)level + strength)/16;
                } else {
                    level = strength;
                }    
            }
            call StepTimer.stop();
            if(counter <= MAX_SEND) {
                post SendMsgTask();
            } else {
                if(level < 35) {
                    call Leds.led3On();
                } else {
                    call Leds.led0On();
                    call Leds.led1On();
                    call Leds.led2On();
                    call Leds.led3On();
                }
            }
        }
        return m;
    }
    
    /*--------- Photo --------------------------*/
    task void GetPhotoTask() {
        if(call PhotoADC.getData() != SUCCESS) {
            post GetPhotoTask();
        }
    }

    uint16_t getDPhoto(uint16_t data) {
        uint16_t dPhoto;
        if (data < 1775) dPhoto = 250;
	else if(data < 2150) dPhoto = 81;
	else if(data < 3520) dPhoto = 43;
	else if(data < 3730) dPhoto = 29;
	else if(data < 3835) dPhoto = 22;
	else if(data < 3900) dPhoto = 16;
	else if(data < 4000) dPhoto = 10;
	else dPhoto = 5;
        return dPhoto;
    }
    
    task void EvalPhotoTask() {
        uint16_t dPhoto;
        uint16_t data;
        int32_t delta;
        
        shellsort(readings, MEDIAN_SIZE);
        atomic data = readings[MEDIAN_SIZE/2];
        dPhoto = getDPhoto(data);
        if(level == 0) level = data;

        delta = level - data;
        if(delta < 0) delta *= -1;

        if(delta > dPhoto) {
            ++exceedCounter;
            level = data;
        }

        counter++;

        if(counter < MAX_READINGS) {
            call StepTimer.setOneShot(TIME_BETWEEN_SAMPLES);
            if(counter%200 == 0)  call Leds.led1Toggle();
        } else {
            if(exceedCounter < 15) {
                counter = 0;
                level = 0;
                exceedCounter = 0;
                state = TEMP;
                call Leds.led1Off();
                call StepTimer.setOneShot(TIME_BETWEEN_SAMPLES);
            } else {
                call Leds.led1On();
            }
        }
        atomic readIndex = 0;
    }
    
    async event result_t PhotoADC.dataReady(uint16_t data) {
        atomic {
            if(readIndex < MEDIAN_SIZE) {
                readings[readIndex++] = data;
                if(readIndex < MEDIAN_SIZE) {
                    post GetPhotoTask();
                } else {
                    post EvalPhotoTask();
                }
            } 
        }
        return SUCCESS;
    }

    /*------------- Temp Tests ---------------------*/


    task void GetTempTask() {
        if(call TempADC.getData() != SUCCESS) {
            call Leds.led2On();
            post GetTempTask();
        }
    }

    task void EvalTempTask() {
        uint16_t data;
        int32_t delta;
        
        shellsort(readings, MEDIAN_SIZE);
        atomic data = readings[MEDIAN_SIZE/2];

        if(level == 0) level = data;

        delta = level - data;
        if(delta < 0) delta *= -1;

        if(delta > 24) {
            ++exceedCounter;
            level = data;
        }

        counter++;

        if(counter < MAX_READINGS) {
            call StepTimer.setOneShot(TIME_BETWEEN_SAMPLES);
            call Leds.led2Toggle();
        } else {
            if(exceedCounter < 5) {
                counter = 0;
                level = 0;
                exceedCounter = 0;
                state = RADIO;
                call Leds.led2Off();
                post SendMsgTask();
            } else {
                call Leds.led2On();
            }
        }
        atomic readIndex = 0;
    }
    
    async event result_t TempADC.dataReady(uint16_t data) {
        atomic {
            if(readIndex < MEDIAN_SIZE) {
                readings[readIndex++] = data;
                if(readIndex < MEDIAN_SIZE) {
                    post GetTempTask();
                } else {
                    post EvalTempTask();
                }
            } 
        }
        return SUCCESS;
    }

    /*------------- StepTimer -----------------------*/
    
    event result_t StepTimer.fired() {
        if(state == PHOTO) {
            post GetPhotoTask();
        }
        else if(state == TEMP) {
            post GetTempTask();
        }
        else if(state == RADIO) {
            post SendMsgTask();
        }
        return SUCCESS;
    }

    
    /*------------- StdControl ----------------------*/
    command result_t StdControl.init() {
        call Leds.init();
        state = FLASH_P1;
        counter=0;
        atomic readIndex = 0;
        exceedCounter = 0;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        counter = 0;
        post EraseTask();
        return SUCCESS;
    }
   
    command result_t StdControl.stop() {
        return SUCCESS;
    }
}
