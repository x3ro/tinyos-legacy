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
module TestSolarM {
  provides {
    interface StdControl; 
  }

  uses {
    interface ADC as ADCVsupMux;       // switch output voltage (for verification purposes)
    interface ADC as ADCVsupSuperCap;  // supercap voltage
    interface ADC as ADCVsupBat;       // battery voltage
    interface ADC as ADCCsupBat;       // battery current
    interface ADC as ADCVsupExtSupply; // external power supply voltage
    interface ADC as ADCCsupPanel;     // solar panel current
    interface SolarControl;
    interface StdControl as SwitchControl;
    interface Timer;
    interface Leds;

    interface XE1205Control;
    interface XE1205LPL;
    interface Oscope as OscopeVsupMux;       // switch output voltage (for verification purposes)
    interface Oscope as OscopeVsupSuperCap;  // supercap voltage
    interface Oscope as OscopeVsupBat;       // battery voltage
    interface Oscope as OscopeCsupBat;       // battery current
    interface Oscope as OscopeVsupExtSupply; // external power supply voltage
    interface Oscope as OscopeCsupPanel;     // solar panel current
#ifdef CUSTOM_SCOPE
    command result_t sendAll();
#endif


    interface CSMAControl;
    async command result_t enableInitialBackoff(); 
    async command result_t disableInitialBackoff();
  }
}

implementation {
  uint16_t lastdata;
  uint8_t nmeasures;
  uint16_t measures[100];
  norace int state;
  norace uint16_t vsupSuperCap, vsupMux, vsupBat, vsupextSupply, csupBat, csupPanel;

  enum {
    MEASURE_DELAY = 10,
  };

  enum {
    Sbd_No_Measure = 0,
    Sbd_VsupBat_Measure = 1,
    Sbd_VsupMux_Measure = 2,
    Sbd_VsupSuperCap_Measure = 3,
    Sbd_VsupExtSupply_Measure = 4,
    Sbd_CsupBat_Measure = 5,
    Sbd_CsupPanel_Measure = 6,
  };

  command result_t StdControl.init() { 
    atomic nmeasures = 0; 
    state = Sbd_VsupBat_Measure;

    call SwitchControl.init();
    call Leds.init();
    return SUCCESS; 
  }

  command result_t StdControl.start()   __attribute__ ((noinline)) {
    call SwitchControl.start();
    call XE1205Control.TunePreset(2);
    call XE1205Control.SetRFPower(3);
    call XE1205LPL.SetListeningMode(1);
    call CSMAControl.disableCCA();
    call disableInitialBackoff();

    call Timer.start(TIMER_ONE_SHOT, 1000);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SwitchControl.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()   __attribute__ ((noinline)) {

    // set a timeout in case a task post fails (rare)
    //    call Timer.start(TIMER_ONE_SHOT, 100);
    switch(state) {
    case  Sbd_VsupBat_Measure:
      call Leds.redOn();
      //      call Leds.redToggle();
      if (call ADCVsupBat.getData() == FAIL) call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
      break;
    case Sbd_VsupMux_Measure:
      if (call ADCVsupMux.getData() == FAIL) call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
      break;    
    case Sbd_VsupSuperCap_Measure:
      if (call ADCVsupSuperCap.getData() == FAIL) call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
      break;
    case Sbd_VsupExtSupply_Measure:
      if (call ADCVsupExtSupply.getData() == FAIL) call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
      break;
    case Sbd_CsupBat_Measure:
      if (call ADCCsupBat.getData() == FAIL) call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
      break;
    case Sbd_CsupPanel_Measure:
      if (call ADCCsupPanel.getData() == FAIL) call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
      break;
    case Sbd_No_Measure:
      state = Sbd_VsupBat_Measure;
      call Leds.redOff();
      call Timer.start(TIMER_ONE_SHOT, 5000);
      break;

    default:
      call Timer.start(TIMER_ONE_SHOT, 5000);
    }
    return SUCCESS;
  }

  task void putVsupBat() {
    call OscopeVsupBat.put(vsupBat);
    state = Sbd_VsupMux_Measure;
    call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
  }
  task void putVsupMux() {
    call OscopeVsupMux.put(vsupMux);
    state = Sbd_VsupSuperCap_Measure;
    call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
  }
  task void putVsupSuperCap() {
    call OscopeVsupSuperCap.put(vsupSuperCap);
    state = Sbd_VsupExtSupply_Measure;
    call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
  }
  task void putVsupExtSupply() {
    call OscopeVsupExtSupply.put(vsupextSupply);
    state = Sbd_CsupBat_Measure;
    call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
  }
  task void putCsupBat() {
    call OscopeCsupBat.put(csupBat);
    state = Sbd_CsupPanel_Measure;
    call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
  }
  task void putCsupPanel() {
    call OscopeCsupPanel.put(csupPanel);
#ifdef CUSTOM_SCOPE
    call sendAll();
#endif
    state = Sbd_No_Measure;
    call Timer.start(TIMER_ONE_SHOT, MEASURE_DELAY);
  }




  async event result_t ADCVsupBat.dataReady(uint16_t data)  __attribute__ ((noinline)) {
    if (state != Sbd_VsupBat_Measure) return SUCCESS;
    //    call Leds.redToggle();
    vsupBat=data;
    post putVsupBat();
    return SUCCESS;
  }

  async event result_t ADCCsupBat.dataReady(uint16_t data)  __attribute__ ((noinline)) {
    if (state != Sbd_CsupBat_Measure) return SUCCESS;
    //    call Leds.redToggle();
    csupBat=data;
    post putCsupBat();
    return SUCCESS;
  }

  async event result_t ADCCsupPanel.dataReady(uint16_t data)  __attribute__ ((noinline)) {
    if (state != Sbd_CsupPanel_Measure) return SUCCESS;
    //    call Leds.redToggle();
    csupPanel=data;
    post putCsupPanel();
    return SUCCESS;
  }  

  async event result_t ADCVsupMux.dataReady(uint16_t data)  __attribute__ ((noinline)) {
    if (state != Sbd_VsupMux_Measure) return SUCCESS;
    //    call Leds.redToggle();
    vsupMux=data;
    post putVsupMux();
    return SUCCESS;
  }

  async event result_t ADCVsupSuperCap.dataReady(uint16_t data)  __attribute__ ((noinline)) {
    if (state != Sbd_VsupSuperCap_Measure) return SUCCESS;
    //    call Leds.redToggle();
    vsupSuperCap=data;

    post putVsupSuperCap();
    return SUCCESS;
  }

  async event result_t ADCVsupExtSupply.dataReady(uint16_t data)  __attribute__ ((noinline)) {
    if (state != Sbd_VsupExtSupply_Measure) return SUCCESS;
    //    call Leds.redToggle();
    vsupextSupply=data;
    post putVsupExtSupply();
    return SUCCESS;
  }

}

