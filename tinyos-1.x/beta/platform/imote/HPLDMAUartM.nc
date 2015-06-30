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

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that Flex is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component

includes motelib;
includes TargetManager;
includes TargetSupervisor;

module HPLDMAUartM {
  provides {
     interface HPLDMAUart;
  }
}

implementation
{
  //Rx side buffer info
  uint8 *RxBuffer;
  uint16 RxSize;

  //tx side buffer info
  uint8 *TxBuffer;
  uint8  fault;
  uint8  localBaudrate;
  
  async command result_t HPLDMAUart.init(uint8 baudrate) {
      
    atomic {
      fault=false;
      localBaudrate=baudrate;
    }
    //return (InitializeMainUart(baudrate) ? SUCCESS : FAIL);
    InitializeMainUart(baudrate);
    //    TM_MainUartReg->intEnable |= TM_UART_EN_RX_BUF_FULL_INT_MASK;
    TM_MainUartReg->fifoControl=0;
    TM_MainUartReg->fifoControl=0x1 | 0x8 | 0x80;
    return SUCCESS;
  }

  async command result_t HPLDMAUart.start(uint8 *newRxBuffer, uint16 newRxSize  ) {
    uint8 lfault, lbaud;
    
    atomic {
      lfault = fault;
      lbaud = localBaudrate;
    }
    if (lfault) call HPLDMAUart.init(lbaud);
      
    SetNextReceiveBuffer(newRxBuffer, newRxSize);

    atomic {
      RxSize = newRxSize;
      RxBuffer = newRxBuffer;
    }

    return SUCCESS;
  }



  async command result_t HPLDMAUart.stop(){      

    DisableMainUart();

    return SUCCESS;
  }

  

  async command result_t HPLDMAUart.put(uint8 *newTxBuffer, uint16 newTxBytes) {
	  
    // save the buffer that we're transmitting so that we can return it later
    // without losing it
    atomic TxBuffer=newTxBuffer;

    MainUartTransmit(newTxBuffer, newTxBytes);
    return SUCCESS;
  }

  void MainUartInterrupt(uint16 Id, tIoStatus UartStatus) __attribute__ ((C, spontaneous)) { 
      TM_SetPioAsOutput(4);
      TM_SetPioAsOutput(5);
      TM_SetPioAsOutput(6);
      TM_ResetPio(5);
      TM_ResetPio(6);
      TM_ResetPio(4);
      if(Id==TM_UART_RX_LINE_STATUS){
          switch(UartStatus){
          case eTM_OverrunError:
              TM_SetPio(4);
              break;
          case eTM_BreakError:
              TM_SetPio(5);
              break;
          case eTM_FramError:
              TM_SetPio(6);
              break;
         default:
              TM_SetPio(4);
              TM_SetPio(6);
              break;
          }
          while(1);  //die here so we can tell...
          fault=true;
      }
      else{
          //TM_SetPio(4);
          //TM_SetPio(5);
          //TM_SetPio(6);
          //TMFlushUartDmaRxBuffer();
      }
}


  void MainUartTransmitInterrupt() __attribute__ ((C, spontaneous)) {
    char *buf;
    atomic buf = TxBuffer;
    signal HPLDMAUart.putDone(buf); 
  }

  void MainUartReceiveInterrupt(uint8 *pRxBuf, int RxLen) __attribute__ ((C, spontaneous)) {
    char *ret;
    uint16 lsize;

    if(!(ret=signal HPLDMAUart.get(pRxBuf, RxLen))){
      
      atomic {
	RxBuffer = ret;
	RxSize = 0;
	lsize = RxSize;
      }
    }
    else{
      atomic {
	RxBuffer = ret;
	lsize = RxSize;
      }
      SetNextReceiveBuffer(ret, lsize);
    }   
  }
 

/*********************
 *events 
  ***********/
  
  default event uint8 *HPLDMAUart.get(uint8 *DataPtr, uint16 NumBytes) {
    return NULL;
  }

  default event result_t HPLDMAUart.putDone(uint8 *data) { return SUCCESS; } 
  
}
