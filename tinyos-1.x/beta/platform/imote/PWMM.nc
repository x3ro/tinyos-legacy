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

module PWMM
{
  provides {
    interface StdControl;
    interface PWM;
  }
  uses {
    interface GPIO;
  }
}

implementation
{
  // time stamps for the most recent rise and fall of the signal
  uint32 rise, fall;

  int last_state; // last state of the PWM bit (in case multiple inputs toggle)



  command result_t StdControl.init() {
    rise = 0;
    fall = 0;
    last_state = 1;

    call GPIO.init();
    // set I/O 0 as an input pin
    call GPIO.input(0);

    return SUCCESS;
  }



  command result_t StdControl.start() {

    StartRTOSClock();
    SetRTOSClockRate(1 << 15);
    rise = fall = GetRTOSClockValue();

    last_state = 1;

    // enable GPIO interrupts
    call GPIO.enable();

    return SUCCESS;
  }



  command result_t StdControl.stop() {

    StopRTOSClock();
    call GPIO.disable();

    return SUCCESS;
  }



  default event result_t PWM.Pulse(uint32 period, uint32 high_phase) {
    return SUCCESS;
  }



  /*
   * Detect any changes on PWM input.  This routine is called when any of the
   * GPIO states change.
   *
   * GPIO2 = PWM
   */
  event GPIO.stateChanged() {
    int input_state;
    uint32 tmp;

    input_state = (GPIO.get() >> 0) & 0x1; // GPIO0

    if (input_state ^ last_state) { // state changed
      if (input_state) { // rising edge
        tmp = GetRTOSClockValue();
        signal PWM.Pulse((rise < tmp) ? rise + (0x8000 - tmp) : rise - tmp,
                         (rise < fall) ? rise + (0x8000 - fall) : rise - fall);
        rise = tmp;

        SetRTOSClockRate(1 << 15);
        rise = GetRTOSClockValue();
      } else { // falling edge
        fall = GetRTOSClockValue();
      }
    }

    last_state = input_state;

  }

}
