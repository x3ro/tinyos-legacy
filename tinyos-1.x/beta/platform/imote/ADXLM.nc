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
 * This module provides an interface for a pulse width modulated (PWM) signal.
 * After starting, the module triggers an event on the rising edge of the
 * clock, returning the duty cycle of the most recent pulse.  Two values are
 * returned, the duration of the period and the duration of the high phase.
 */

module ADXLM
{
  provides {
    interface StdControl;
    interface ADXL;
  }
}

implementation
{
    
    // This should move to HPLInterrupt
    extern void TM_PIOIsr_ISR() __attribute__ ((C, spontaneous));
    
    // time stamps for the most recent rise and fall of the signal
        
    signed short Ta, Tb, Tc, Td, tempX, tempY;
    unsigned short T1x,T1y,Time;
    enum eState{getTa, getTb, getTc, done}state;
    
    command result_t StdControl.init() {
        TM_RegisterInterrupt(eTM_PIO, (tIntFunc) TM_PIOIsr_ISR, eTM_ProLow);
        TM_SetPioAsOutput(0);
        TM_SetPioAsOutput(1);
        TM_SetPioAsInput(2);
        //TM_SetPioAsInput(3);
        TM_SetPioAsOutput(3);
        TM_SetPioAsOutput(4);
        TM_SetPioAsOutput(5);
        TM_SetPioAsOutput(6);
        TM_SetPioAsOutput(7);
        
        state = getTa;
        return SUCCESS;
    }
    
    command result_t StdControl.start() {
        TM_LOAD_SVR(0x7FFFFFFF);  
        TM_SET_SVR_CTRL(TM_TMR_ENABLE | TM_TMR_FREERUN_MODE);
        // TM_LOAD_RTOS(0x7FFFFFFF);  
        //TM_SET_RTOS_CTRL(TM_TMR_ENABLE | TM_TMR_FREERUN_MODE);
        TM_Dis_WDTmrClk();
        TM_EnablePIOInt();
        return SUCCESS;
    }
    
    command result_t StdControl.stop() {
        TM_DisablePIOInt();
        return SUCCESS;
    }
    
    default event result_t ADXL.Pulse(unsigned short x, unsigned short y, unsigned short period){ 
        //default event result_t ADXL.Pulse(signed short a, signed short b, signed short c, signed short d){ 
        return SUCCESS;
    }
    
    
  /*
   * Detect any changes on PWM input.  This routine is called when any of the
   * GPIO states change.
   *
   * GPIO2 = PWMx, GPIO3 = PWMy
   */
  void TM_PIO_InterruptHdl() __attribute__ ((C, spontaneous)) {
           
      TM_DisablePIOInt();
      Time = TM_GetSvrTmrCnter();
      //Time = TM_GetRtosTmrCnter();
     
      switch(state)
          {
              //Note:  Apparently our timer is based on the 32k crystal and is only 16 bits
              //       For some terrible reason, it also seems to count down instead of up.
          case getTa:
              if(TM_ReadPio(2))
              {//need to make sure that we align to the rising edge of GPIO2
                  Ta = Time;
                  state = getTb;
              }
              break;
          case getTb:
              //should be the falling edge of GPIO2
              if(TM_ReadPio(2) == 0)
                  {
                      Tb = Time;
                      tempX = Ta-Tb;
                      T1x = (unsigned short)tempX;
                      TM_SetPioAsOutput(2);
                      TM_SetPioAsInput(3);
                      state = getTc;
                  }
              break;
          case getTc:
              //should be the rising edge of GPIO3
              if(TM_ReadPio(3))
                  {
                  Tc = Time;
                  state = done;
              }
              break;
          case done:
              //should be the falling edge of GPIO3
              if(TM_ReadPio(3) == 0)
              {
                  Td = Time;
                  tempY = Tc-Td;
                  T1y = (unsigned short)(tempY);
                  //signal ADXL.Pulse(T1x, T1y, (unsigned)( (Ta- (((signed)T1x)>>2))   - (((signed)T1y)>>2)));
                  TM_SetPioAsInput(2);
                  TM_SetPioAsOutput(3);
                  TM_LOAD_SVR(0x7FFFFFFF);  
                  //TM_LOAD_RTOS(0x7FFFFFFF);  //for some reason, I occasionally miss a Pio interrupt when the timer underflows
                  state = getTa;
                  signal ADXL.Pulse(T1x, T1y, (unsigned short)((Ta - (((signed short)T1x)>>2))  - (Tc - (((signed short)T1y)>>2))));
                  //                 signal ADXL.Pulse(Ta, Tb, Tc, Td);

                  
              }
              break;
          }
      
      TM_ClearPioInterrupt();
      TM_EnablePIOInt();
  }                                 
}

  
