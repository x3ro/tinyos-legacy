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
 * Low-level XE1205 access configuration for tinynode platform.
 *
 * @author  Remy Blank
 */

configuration HPLXE1205C {
  provides {
    interface StdControl;
    interface HPLXE1205;
    interface HPLXE1205Interrupt as IRQ0;
    interface HPLXE1205Interrupt as IRQ1;
  }
}


implementation {
  components HPLXE1205M, HPLUSART0M, HPLXE1205InterruptM, MSP430InterruptC, BusArbitrationC, BusArbitrationM;


  // Populate provided interfaces with module implementations		
  StdControl = HPLXE1205M;
  HPLXE1205 = HPLXE1205M;
  IRQ0 = HPLXE1205InterruptM.IRQ0;
  IRQ1 = HPLXE1205InterruptM.IRQ1;

  // Wire modules between themselves
  HPLXE1205M.USART -> HPLUSART0M;
  HPLXE1205InterruptM.IRQ0Interrupt -> MSP430InterruptC.Port20;
  HPLXE1205InterruptM.IRQ1Interrupt -> MSP430InterruptC.Port21;
  HPLXE1205M.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
  HPLXE1205M.BusStdControl -> BusArbitrationM;
}

