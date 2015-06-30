/*
 * Copyright (c) 2004, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names
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
 * - Description ---------------------------------------------------------
 * Displays the lower 4 bits of an integer on the Infineon board LEDs
 * Based on the original IntToLeds
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2004/01/26 19:03:34 $
 * @author: Vlado Handziski
 * ========================================================================
 */

module IntToLedsNumberedM {
  uses interface LedsNumbered;

  provides interface IntOutput;
  provides interface StdControl;
}
implementation
{
  command result_t StdControl.init()
  {
    call LedsNumbered.init();
    call LedsNumbered.led0Off();
    call LedsNumbered.led1Off();
    call LedsNumbered.led2Off();
    call LedsNumbered.led3Off();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }


  task void outputDone()
  {
    signal IntOutput.outputComplete(1);
  }

  command result_t IntOutput.output(uint16_t value)
  {
    if (value & 1) call LedsNumbered.led0On();
    else call LedsNumbered.led0Off();
    if (value & 2) call LedsNumbered.led1On();
    else call LedsNumbered.led1Off();
    if (value & 4) call LedsNumbered.led2On();
    else call LedsNumbered.led2Off();
    if (value & 8) call LedsNumbered.led3On();
    else call LedsNumbered.led3Off();

    post outputDone();

    return SUCCESS;
  }
}

