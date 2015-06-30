/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
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
 * ========================================================================
 */
/*
 * Low-level XE1205 interrupt access module for tinynode platform.
 *
 * @author Remy Blank
 * @author Henri Dubois-Ferriere
 *
 */

module HPLXE1205InterruptM {
  provides {
    interface HPLXE1205Interrupt as IRQ0;
    interface HPLXE1205Interrupt as IRQ1;
  }
  uses {
    interface MSP430Interrupt as IRQ0Interrupt;
    interface MSP430Interrupt as IRQ1Interrupt;
  }
}


implementation {
  async command void IRQ0.enable(bool lowToHigh)
  {
    atomic {
      call IRQ0Interrupt.disable();
      call IRQ0Interrupt.edge(lowToHigh);
      call IRQ0Interrupt.clear();
      call IRQ0Interrupt.enable();
    }
  }

  async command void IRQ0.clear()
  {
    call IRQ0Interrupt.clear();
  }

  async command void IRQ0.reEnable()
  {
    call IRQ0Interrupt.enable();
  }

  async command void IRQ0.disable()
  {
    call IRQ0Interrupt.disable();
  }

  async event void IRQ0Interrupt.fired()
  {
    call IRQ0Interrupt.disable();
    signal IRQ0.fired();
  }

  default async event void IRQ0.fired()
  {
  }

  async command void IRQ1.enable(bool lowToHigh)
  {
    atomic {
      call IRQ1Interrupt.disable();
      call IRQ1Interrupt.edge(lowToHigh);
      call IRQ1Interrupt.clear();
      call IRQ1Interrupt.enable();
    }
  }

  async command void IRQ1.clear()
  {
    call IRQ1Interrupt.clear();
  }

  async command void IRQ1.reEnable()
  {
    call IRQ1Interrupt.enable();
  }

  async command void IRQ1.disable()
  {
    call IRQ1Interrupt.disable();
  }

  async event void IRQ1Interrupt.fired()
  {
    call IRQ1Interrupt.disable();
    signal IRQ1.fired();
  }

  default async event void IRQ1.fired()
  {
  }
}
  
