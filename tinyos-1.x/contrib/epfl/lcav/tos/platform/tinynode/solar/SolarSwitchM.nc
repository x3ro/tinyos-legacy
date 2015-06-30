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

/*
 * Solar panel energy source selection algorithm.
 *
 * @author: Henri Dubois-Ferriere
 *
 */

// $Id: SolarSwitchM.nc,v 1.6 2006/02/08 16:49:41 henridf Exp $



module SolarSwitchM {
  provides {
    interface StdControl; 
  }

  uses {
    interface ADC as ADCVsupSuperCap;  // supercap voltage
    interface ADC as ADCVsupExtSupply;  // external power supply voltage
    interface SolarControl;
    interface Timer;
    interface Leds;
  }
}

implementation {

  norace uint16_t last_vsupSuperCap; // used sequentially by the supercap and extsupply reads, so no races

  // reading/4096 * 1.5 * 3.666 == voltage  -> voltage = reading * 5.5 / 4096
  // reading = voltage * 4096 / 5.5 
  enum { 
    vsup_1_6V = 1191, // 
    vsup_2V = 1489, 
    vsup_2_5V = 1861,
    vsup_3V = 2234,
    vsup_4V = 2978,
    vsup_4_4V = 3277,
    vsup_4_5V = 3351,
    vsup_4_6V = 3425,
    vsup_5V = 3724,
    vsup_5_2V = 3872,
    vsup_5_3V = 3947,
    vsup_5_4V = 4021,
    vsup_5_5V = 4095
  };

  enum {
#ifdef NIMH
    supply_cap_lower_thresh = vsup_4_4V,
    supply_cap_upper_thresh = vsup_4_6V,
    charge_cap_lower_thresh = vsup_4_6V,
    charge_cap_upper_thresh = vsup_5_3V, 
#else
    supply_cap_lower_thresh = vsup_1_6V,
    supply_cap_upper_thresh = vsup_5V,
    charge_cap_lower_thresh = vsup_4V,
    charge_cap_upper_thresh = vsup_5_4V, 
#endif
  };



  enum {
#ifdef MINICAP
    sbd_sample_interval = 500
#else
    sbd_sample_interval = 5000
#endif
  };

  command result_t StdControl.init() { 
    return SUCCESS; 
  }

  command result_t StdControl.start()   __attribute__ ((noinline)) {
    call Timer.start(TIMER_REPEAT, sbd_sample_interval);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Timer.fired()   __attribute__ ((noinline)) {
    call ADCVsupSuperCap.getData();

    return SUCCESS;
  }

  // This is where everything happens: we look at the supercap and extsupply voltages, 
  // and decide:
  // - whether to draw power from battery or supercap
  // - whether to charge or not the battery
  //
  void adjustEnergySource(uint16_t vsupSuperCap, uint16_t vExtSupply) {
    if (vExtSupply < vsup_2_5V) { // External power not connected
      if (vsupSuperCap <= supply_cap_lower_thresh) {
	call SolarControl.SupplyFromBattery();
	call Leds.greenOn();
      }

      if (vsupSuperCap >= supply_cap_upper_thresh) {
	call SolarControl.SupplyFromSuperCap();
	call Leds.greenOff();
      }

      if (vsupSuperCap >= charge_cap_upper_thresh) {
	call SolarControl.StartBatteryCharge();
	call Leds.yellowOn();
      }

      if (vsupSuperCap <= charge_cap_lower_thresh) {
	call SolarControl.StopBatteryCharge();
	call Leds.yellowOff();
      }
    } else { // External power connected: draw power from external supply and charge battery
      call SolarControl.SupplyFromSuperCap();
      call SolarControl.StartBatteryCharge();
    }

    if (call SolarControl.isSupplyFromBattery()) 
      call Leds.greenOn();

    if (call SolarControl.isBatteryCharging()) 
      call Leds.yellowOn();

  }

  async event result_t ADCVsupSuperCap.dataReady(uint16_t data) {
    call ADCVsupExtSupply.getData();
    last_vsupSuperCap = data;
    return SUCCESS;
  }

  async event result_t ADCVsupExtSupply.dataReady(uint16_t data) {

    adjustEnergySource(last_vsupSuperCap, data);
    return SUCCESS;
  }

}

