/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License
 *
 *  Copyright (c) 2002 Intel Corporation
 *  All rights reserved.
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component
includes motelib;

module HPLDebugUartM {
    provides interface HPLUART as UART;
    }

implementation
{
    
    //note, this is the maximum standard rate that the Debug UART will run at
    #define DEFAULT_BAUDRATE eTM_B57600
    
    bool bInitialized = false;
    uint8 baudrate = DEFAULT_BAUDRATE;
    
    async command result_t UART.init() {
        if(InitializeDebugUart(baudrate) == SUCCESS) {
            bInitialized = true;
            return SUCCESS;
        }
        else{
            bInitialized = false;
            return FAIL;
        }
    }

    command result_t UART.setRate(uint8 newbaudrate){
        if((bInitialized==false) && (newbaudrate <=eTM_B921600)){
            baudrate=newbaudrate;
            return SUCCESS;
        }
        else{
            return FAIL;
        }
    }

    async command result_t UART.stop() {
        return SUCCESS;
    }
    
    async command result_t UART.put(uint8_t data) {
        if(bInitialized==true)
            DebugUartTransmit(data);
        return SUCCESS;
    }
    
    void DebugUartInterrupt(uint16 Id, tIoStatus UartStatus) __attribute__((C, spontaneous)) {
      //something bad happened...need to figure out what to do...most likely just ignore
    }
    
    void DebugUartTransmitInterrupt() __attribute__ ((C, spontaneous)) { 
        signal UART.putDone();
    }

    void DebugUartReceiveInterrupt(uint8 data) __attribute__ ((C, spontaneous)) { 
        signal UART.get(data);
    }

    default async event result_t UART.get(uint8 data) { return SUCCESS; }
    
    default async event result_t UART.putDone() { return SUCCESS; }

}
