/*
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
 *
 * - Description ----------------------------------------------------------
 * Configuration for Reference Voltage Generator.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.1.1 $
 * $Date: 2007/11/05 19:11:32 $
 * @author: Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#include "RefVolt.h"

/**
 * This component manages the ADC12's reference voltage generator.
 * The internal turn-on time is 17ms, thus the component is programmed  
 * split-phase, i.e. after the command <code>get</code> has been called 
 * you will eventually get the event <code>isStable</code> when vref is 
 * stable.
 * <p>
 * The generator should be turned off to both save power and allow other 
 * components to switch to another reference voltage when not in use.  To
 * do so, the <code>release</code> command is available.
 * <p>
 * There are two different reference voltages available with this 
 * component.  They are a 1.5 reference voltage and a 2.5 reference 
 * voltage.  Only one can be set at any given time, however. If a 
 * component, therefore, tries to call the <code>get</code> command on the
 * reference voltage that is not currently set, the <code>get</code> 
 * command will return a FAIL.  Only once all components using a certain 
 * reference voltage have called the <code>release</code> command, will a 
 * call to the <code>get</code> command with a different reference voltage 
 * return a SUCCESS.
 * <p>
 * Since the 17 millisecond delay is only required when switching the 
 * RefVolt component on after it has been turned off, a timer is used to
 * delay the actual switching off of the component after it has been 
 * released for the last time.  This allows other components to start using
 * the reference voltage immediately if they try to access it within a 
 * reasonable amount of time.  The delay for this timer is set in RefVolt.h
 * as SWITCHOFF_INTERVAL.
 * <p>
 * If a component calls the <code>get</code> command when the RefVolt 
 * component is in the off state and no other components have called the
 * <code>get</code> command before this component calls release, AND the 
 * <code>release</code> command is called before the <code>isStable</code> 
 * event returns, then the RefVolt component will never be turned on and the 
 * <code>isStable</code> event will never be triggered.
 *
 * @author: Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 */
configuration RefVoltC
{
  provides interface RefVolt;
}

implementation
{
  components RefVoltM
    , new TimerMilliC() as Timer1
    , new TimerMilliC() as Timer2
    , HPLADC12M
    ;
  
  RefVolt = RefVoltM;
  RefVoltM.SwitchOnTimer -> Timer1;
  RefVoltM.SwitchOffTimer -> Timer2;
  RefVoltM.HPLADC12 -> HPLADC12M;
}

