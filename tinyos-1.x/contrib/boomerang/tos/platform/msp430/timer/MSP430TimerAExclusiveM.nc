// $Id: MSP430TimerAExclusiveM.nc,v 1.1.1.1 2007/11/05 19:11:34 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names 
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
 */
module MSP430TimerAExclusiveM {
  provides {
    interface TimerExclusive;
  }
  uses {
    interface ResourceValidate;
    interface MSP430Timer as TimerA;
    interface MSP430TimerControl as ControlA0;
    interface MSP430TimerControl as ControlA1;
    interface MSP430Compare as CompareA0;
    interface MSP430Compare as CompareA1;
  }
}
implementation {

  async command result_t TimerExclusive.prepareTimer(uint8_t rh, uint16_t interval, uint16_t csSAMPCON, uint16_t cdSAMPCON)
  {

    MSP430CompareControl_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };

    if (!call ResourceValidate.validateUser(rh))
      return FAIL;

    call TimerA.disableEvents();
    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    call TimerA.clear();
    call TimerA.setClockSource(csSAMPCON);
    call TimerA.setInputDivider(cdSAMPCON);
    call ControlA0.setControl(ccResetSHI);
    call CompareA0.setEvent(interval-1);
    call CompareA1.setEvent((interval-1)/2);
    return SUCCESS;
  }
    
  async command result_t TimerExclusive.startTimer(uint8_t rh)
  {
    MSP430CompareControl_t ccSetSHI = {
      ccifg : 0, cov : 0, out : 1, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    MSP430CompareControl_t ccResetSHI = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 0, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };
    MSP430CompareControl_t ccRSOutmod = {
      ccifg : 0, cov : 0, out : 0, cci : 0, ccie : 0,
      outmod : 7, cap : 0, clld : 0, scs : 0, ccis : 0, cm : 0 };

    if (!call ResourceValidate.validateUser(rh))
      return FAIL;

    // manually trigger first conversion, then switch to Reset/set mode
    call ControlA1.setControl(ccResetSHI);
    call ControlA1.setControl(ccSetSHI);
    call ControlA1.setControl(ccResetSHI); 
    call ControlA1.setControl(ccRSOutmod);
    call TimerA.setMode(MSP430TIMER_UP_MODE); // go!
    return SUCCESS;
  }    

  async command result_t TimerExclusive.stopTimer(uint8_t rh) {
    if (!call ResourceValidate.validateUser(rh))
      return FAIL;

    call TimerA.setMode(MSP430TIMER_STOP_MODE);
    return SUCCESS;
  }

  async event void TimerA.overflow(){ }
  async event void CompareA0.fired(){ }
  async event void CompareA1.fired(){ }

}
