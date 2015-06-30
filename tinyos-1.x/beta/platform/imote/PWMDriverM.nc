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
 * period is measured in us, duty cycle is measured as a fraction of 256.
 */

module PWMDriverM
{
  provides {
    interface StdControl();
    command result_t setPeriod(uint32_t period);
    command result_t setDutyCycle(uint32_t duty_cycle);
    command uint32_t getPeriod();
    command uint8_t getDutyCycle();
  }
}

implementation
{
  // Use GPIO7 as the driver port until we generalize the interface

  uint32_t period;
  uint32_t duty_cycle;
  uint32_t count;

  command result_t StdControl.init() { return SUCCESS;}

  extern void TM_RTOSTimer_ISR() __attribute__ ((C, spontaneous));

  void TM_RTOSTmrInt() __attribute__ ((C, spontaneous)) {
    TM_DisableRtosTmrInt();
    TM_ClrRtosTmrIntpt();

    if (count == period) {
      TM_SetPio(5);
      count = 0;
    }
    if (count == duty_cycle) TM_ResetPio(5);
    count++;

    TM_EnableRtosTmrInt();
  }

  command result_t StdControl.start() {
    period = 300; // 900 ms
    duty_cycle = 0;
    count = 0;
    TM_ResetPio(5); // motor control

    TM_Dis_SysTmrClk();
    while (TM_SysClkReg->SysTmrClk & TM_CLK_BUSY) ;

    TM_Set_SysTmrClk_Xtal();
    TM_Set_SysTmrClk_DIV(500); //41.667 us periods

    TM_En_SysTmrClk();
    while (TM_SysClkReg->SysTmrClk & TM_CLK_BUSY) ;

    TM_LOAD_RTOS(72); // 3 ms periods
    TM_SET_RTOS_CTRL(TM_TMR_ENABLE| TM_TMR_PERIOD_MODE);

    TM_RegisterInterrupt(eTM_TimerRTOS, (tIntFunc) TM_RTOSTimer_ISR, eTM_ProLow):
    TM_EnableRtosTmrInt();

    return SUCCESS;
  }

  command result_t StdControl.stop() { return SUCCESS;}

  command result_t setPeriod(uint32_t new_period) {
    period = new_period;
    return SUCCESS;
  }

  command result_t setDutyCycle(uint8_t new_duty_cycle) {
    duty_cycle = new_duty_cycle;
    return SUCCESS;
  }

  command uint32_t getPeriod() {
    return (period);
  }

  command uint8_t getDutyCycle() {
    return (duty_cycle);
  }

}
