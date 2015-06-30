/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL), Switzerland
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne nor the names
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
 * ========================================================================
 */

// @author henri Dubois-Ferriere

// $Id: TestSolar.nc,v 1.8 2005/11/13 18:01:52 henridf Exp $

configuration TestSolar { }
implementation
{
  components Main,
    SolarBoardC, 
    SolarSwitchC,
    TestSolarM, 
    XE1205RadioC,
    XE1205RadioM,
    TimerC, 
    LedsC,
    GenericComm as Comm, 
#ifdef CUSTOM_SCOPE
    SolarScopeC as OscopeC
#else
    OscopeC
#endif
;

  
  Main.StdControl -> TimerC;
  Main.StdControl -> SolarBoardC;
  Main.StdControl -> TestSolarM;
  Main.StdControl -> Comm;

  TestSolarM.SwitchControl ->  SolarSwitchC;

  TestSolarM.XE1205Control -> XE1205RadioC;
  TestSolarM.XE1205LPL -> XE1205RadioC;

  TestSolarM.SolarControl -> SolarBoardC;
  TestSolarM.ADCVsupBat -> SolarBoardC.ADCVsupBat;
  TestSolarM.ADCVsupMux -> SolarBoardC.ADCVsupMux;
  TestSolarM.ADCVsupSuperCap -> SolarBoardC.ADCVsupSuperCap;
  TestSolarM.ADCVsupExtSupply -> SolarBoardC.ADCVsupExtSupply;
  TestSolarM.ADCCsupBat -> SolarBoardC.ADCCsupBat;
  TestSolarM.ADCCsupPanel -> SolarBoardC.ADCCsupPanel;

  TestSolarM.OscopeVsupBat -> OscopeC.Oscope[0];
  TestSolarM.OscopeVsupMux -> OscopeC.Oscope[1];
  TestSolarM.OscopeVsupSuperCap -> OscopeC.Oscope[2];
  TestSolarM.OscopeVsupExtSupply -> OscopeC.Oscope[3];
  TestSolarM.OscopeCsupBat -> OscopeC.Oscope[4];
  TestSolarM.OscopeCsupPanel -> OscopeC.Oscope[5];
#ifdef CUSTOM_SCOPE
  TestSolarM.sendAll -> OscopeC.sendAll;
#endif

  TestSolarM.Timer -> TimerC.Timer[unique("Timer")];
  TestSolarM.Leds -> LedsC;

  TestSolarM.enableInitialBackoff -> XE1205RadioM.enableInitialBackoff; 
  TestSolarM.disableInitialBackoff -> XE1205RadioM.disableInitialBackoff; 
  TestSolarM.CSMAControl -> XE1205RadioC;

}


