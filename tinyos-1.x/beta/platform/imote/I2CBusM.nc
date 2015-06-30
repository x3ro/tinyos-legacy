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
/*
 * This module provides the bus level interface for the I2C controller
 * It detects logic state transitions for the SCL and SDA pins and sends the
 * appropriate event up to the higher level.
 * This module also puts individual transistions on the bus, detects whether
 * they were accepted (won/ lost arbitration), and signals success or failure
 * to the higher level.
 *
 * I2C's open collector behavior is simulated by switching the direction of the
 * GPIO, not the registered value.  When driving a low logic value, the output
 * data is set to 0, and the pin direction is set to output.  When driving a
 * high logic value, the output data is set to 0 (arbitrary) and the pin
 * direction is set to input.:q

 */

module I2CBusM
{
  provides {
    interface StdControl;
    interface I2CBus;
  }
}
implementation
{
  // This should move to HPLInterrupt
  extern void TM_PIOIsr_ISR() __attribute__ ((C, spontaneous));

  uint8 currentSCL, currentSDA;
  char buf[128];
  uint8 index;
uint32 tmp2;
char currentByte;
uint8 cnt, bitCount;
    uint8 bit;
int ack, state, last, wait;
uint32 time;

  enum {LOW, HIGH, START, STOP};

  command result_t StdControl.init() {

currentByte = 0;
bitCount = 0;
tmp2 = 0;
cnt = 1; // idle state
bit = 1;
state = HIGH;
last = 0x3;
time = 0;
    wait = 0;
    index = 0;
    currentSCL = 1;
    currentSDA = 3; // holds two bits, both SCL and SDA?
    TM_RegisterInterrupt(eTM_PIO, (tIntFunc) TM_PIOIsr_ISR, eTM_ProLow);
    TM_SetPioAsInput(0);
    TM_SetPioAsInput(1);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    TM_EnablePIOInt();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    TM_DisablePIOInt();
    return SUCCESS;
  }

  command result_t I2CBus.readyToReceive() {

    index = 0;
#if 0
    if (index > 0) {
      signal I2CBus.printBuf(buf);
      index = 0;
    } else {
      TM_SetPioAsInput(0);
    }
#endif

    return SUCCESS;
  }

  command result_t I2CBus.notReadyToReceive() {

    // strict timing requires us to wait for the min clock high phase
    // (4us for standard mode, 0.6 us for fast mode).  Ignore this for now
    TM_SetPioAsOutput(0);
    TM_ResetPio(0);

    return SUCCESS;

  }

  default event result_t I2CBus.receiveStartCond() {
    return SUCCESS;
  }

#if 0
  default event result_t I2CBus.readBit(char data) {
    return SUCCESS;
  }
#endif

  default event result_t I2CBus.readByte(char byte, uint8 a) {
    return SUCCESS;
  }

  default event result_t I2CBus.receiveStopCond() {
    return SUCCESS;
  }

  default event result_t I2CBus.printBuf(char *data) {
    return SUCCESS;
  }

  default event result_t I2CBus.dumpBytes() {
    return SUCCESS;
  }

  task void dumpBytesTask() {
    signal I2CBus.dumpBytes();
  }

  /*
   * Detect any changes on the I2C bus.  This routine is called when any of the
   * GPIO states change.  Currently, only two pins are monitored for input:
   *
   * GPIO0 = SCL
   * GPIO1 = SDA
   */

  void TM_PIO_InterruptHdl() __attribute__ ((C, spontaneous)) {
    uint32 inp, tmp;
    int t, t2;

    inp = (*((uint32 *) (0x300604))) & 0x3; // latch input register values
    t2 = TM_ReadSysClk(0, SysTmrClk);
    buf[index++] = inp;                     // save all transitions
    buf[index++] = (char) ((t2 - time) & 0x3f);
    time = t2;

#if 0
    if (inp & 0x1) {
      if (last & 0x1) {                     // data transition during high phase
        state = (inp & 0x2) ? STOP : START;
      } else {                              // process on the rising edge
        if (state == START) {
          bitCount = 0;
          currentByte = 0;
          // signal start
        } else if (state == STOP) {
          post dumpBytesTask();
          // signal STOP
        } else {
          if (bitCount < 8) {
            currentByte = currentByte << 1;
            if (state == HIGH) currentByte |= 1;
            bitCount++;
          } else if (bitCount == 8) {
            ack = (state == HIGH) ? 1 : 0;
            wait = 1;
          }
        }
        state = (inp & 0x2) ? HIGH : LOW;
      }
    } else if (wait) {
      wait = 0;
      TM_SetPioAsOutput(0);
      TM_ResetPio(0);
      signal I2CBus.readByte(currentByte, ack);
    }
    last = inp;
#endif
    if (index == 80) signal I2CBus.printBuf(buf);
    TM_ClearPioInterrupt();





#if 0
    //tmp = *((uint32*) 0x300608);
    //inp &= ~tmp;
   // buf[index++] = inp & 0x3;
    if (inp & 0x1) {
      bit = (inp & 0x2) >> 1;
      cnt++;
      TM_ClearPioInterrupt();
    } else {
      TM_SetPioAsOutput(0);
      TM_ResetPio(0);
      if (cnt > 1) { // data switched during high phase
        cnt = 0;
        if (bit) {
          buf[index++] = 'P';
          buf[index++] = 0;
          index = 0;
          signal I2CBus.printBuf(buf);
          //signal I2CBus.receiveStopCond();
          TM_ClearPioInterrupt();
        } else {
          buf[index++] = 'S';
          //signal I2CBus.receiveStartCond();
          TM_ClearPioInterrupt();
          TM_SetPioAsInput(0);
        }
      } else if (cnt == 1) {
        cnt = 0;
        if (bitCount < 8) {
          currentByte = currentByte << 1;
          currentByte |= bit;
          bitCount++;
          TM_ClearPioInterrupt();
          TM_SetPioAsInput(0);
        } else { // ack bit
          t = (currentByte >> 4) & 0xf;
          buf[index++] = (t < 10) ? '0' + t : 'A' + t - 10;
          t = currentByte & 0xf;
          buf[index++] = (t < 10) ? '0' + t : 'A' + t - 10;
          buf[index++] = ' ';
          buf[index++] = (bit) ? '1' : '0';
          //signal I2CBus.readByte(currentByte, bit);
          bitCount = currentByte = 0;
          TM_ClearPioInterrupt();
          TM_SetPioAsInput(0);
        }
      } else { // data change during low phase
        TM_ClearPioInterrupt();
        TM_SetPioAsInput(0); // ???
      }
    }
#endif
  }
          
    
#if 0
  void TM_PIO_InterruptHdl() __attribute__ ((C, spontaneous))
  {
    uint8 newSCL;
    uint32 tmp, inp;

//    TM_DisablePIOInt();
//if (index < 50) {buf[index++] = ((TM_PioRegs->PioInData) & 0x3);}
//    newSCL = ((TM_PioRegs->PioInData) >> I2C_BUS1_SCL_GPIO) & 0x1;
//    newSDA = ((TM_PioRegs->PioInData) >> I2C_BUS1_SDA_GPIO) & 0x1;

    inp = *((uint32 *) (0x300604)); // latch input register values
    tmp = *((uint32*) 0x300608);
    inp &= ~tmp;
buf[index++] = inp & 0xff;
if (index < 50) {
  TM_ClearPioInterrupt();
  return;
}
TM_SetPioAsOutput(0);
TM_ResetPio(0);
signal I2CBus.printBuf(buf);
index = 0;
TM_ClearPioInterrupt();
TM_SetPioAsInput(0);
return;
    if (inp & 0x1) {
      tmp2 = inp;
      cnt++;
      *((uint32 *) (0x300600)) = 1;  // TM_ClearPioInterrupt();
      return;
    }
    // TM_SetPioAsOutput(0);
    tmp = *((uint32*) 0x300608);
    *((uint32*) 0x300608) = tmp | 0x1;
    // TM_ResetPio(0);
    tmp = *((uint32*) 0x300610);
    *((uint32*) 0x300610) = tmp & ~(0x1);

if (cnt > 1) {
  currentSDA = tmp2 & 0x3;
} else {
  currentSDA = tmp2 & 0x2;
}
cnt = 0;
tmp2 = 0;
index = 0;
     
    //buf[index++] = inp;
    newSCL = inp & 0x1;
    if (newSCL == 0) {                   // process events during low phase
      //TM_SetPioAsOutput(0);
      //TM_ResetPio(0);
      if (currentSDA & 0x1) {            // data transition during high phase
        if (currentSDA & 0x2) {          // last transition was low to high
          signal I2CBus.receiveStopCond();
        } else {                         // last transition was high to low
          signal I2CBus.receiveStartCond();
        }
      } else {                           // data was latched on the rising edge
        signal I2CBus.readBit ((currentSDA & 0x2) >> 1);
      }
      currentSDA = currentSCL = 0;
    } else {
      currentSDA = (inp & 0x2) | (currentSCL & 0x1);
      currentSCL = 1;
    }
#if 0
    } else if (currentSCL == 0) {        // latch data on the rising edge
      currentSDA = inp & 0x2;
      currentSCL = 1;
    } else {                             // data changed during clock high phase
      currentSDA = inp & 0x3;            // bit 0 = data change during SCL high
                                         // bit 1 = last SDA value
    }
#endif

//if (index == 50) signal I2CBus.printBuf(buf);
    *((uint32 *) (0x300600)) = 1;  // TM_ClearPioInterrupt();
// let higher level send ready signal    TM_SetPioAsInput(0);
    //TM_EnablePIOInt();

  }
#endif

}
