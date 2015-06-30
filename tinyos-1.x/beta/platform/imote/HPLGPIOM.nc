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

module HPLGPIOM
{
  provides interface GPIO
}

implementation
{
  command result_t GPIO.init() {
    InitializeGPIOInterrupt();
    return SUCCESS;
  }

  command result_t GPIO.enable() {
    EnableGPIOInterrupt();
    return SUCCESS;
  }

  command result_t GPIO.disable() {
    DisableGPIOInterrupt();
    return SUCCESS;
  }


  command result_t GPIO.set(uint8 state) {
    SetGPIOState(state);
    return SUCCESS;
  }

  command uint8 get() {
    return GetGPIOState();
  }

  command result_t GPIO.input(uint8 reg) {
    SetGPIOInput(reg);
    return SUCCESS;
  }

  command result_t GPIO.output(uint8 reg) {
    SetGPIOOutput(reg);
    return SUCCESS;
  }


  void GPIOInterrupt() {
    signal GPIO.stateChanged():
  }

  default event result_t stateChanged() { return SUCCESS; }

}
 
