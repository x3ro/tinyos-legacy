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
 * Solarboard readings and control.
 *
 * @author henri Dubois-Ferriere
 *
 */

// $Id: SolarBoardM.nc,v 1.6 2006/02/08 16:57:26 henridf Exp $


/**
 *
 * @author Henri Dubois-Ferriere
 *
 */
includes solarboard;

module SolarBoardM {

  uses interface ADC as VsupAdcRaw;
  uses interface ADC as CsupAdcRaw;
  uses interface ADCControl;
  uses interface Random;
  uses interface Timer;

  provides interface StdControl;
  provides interface ADC as ADCVsupMux;       // switch output voltage (for verification purposes)
  provides interface ADC as ADCVsupSuperCap;  // supercap voltage
  provides interface ADC as ADCVsupBat;       // battery voltage
  provides interface ADC as ADCCsupBat;       // battery current
  provides interface ADC as ADCVsupExtSupply; // external power supply voltage
  provides interface ADC as ADCCsupPanel;     // solar panel current
  provides interface ADC as ADCCglobal;       // overall current

  provides interface SolarControl;

}

implementation
{

  enum {
    ADC_ENABLE_DELAY = 50
  };

  enum {
    Sbd_Idle = 0,
    Sbd_Voltage_Measure = 1, 
    Sbd_Current_Measure = 2
  };

  enum {
    Sbd_No_Measure = 0,
    Sbd_VsupBat_Measure = 1,
    Sbd_VsupMux_Measure = 2,
    Sbd_VsupSuperCap_Measure = 3,
    Sbd_VsupExtSupply_Measure = 4,
    Sbd_CsupBat_Measure = 5,
    Sbd_CsupPanel_Measure = 6,
    Sbd_Cglobal_Measure = 7,
  };

  enum {
    Sbd_Supply_Battery,
    Sbd_Supply_SuperCap,
  };

  uint8_t measure, measuretype;
  uint8_t supply;
  uint8_t batteryCharging;

  command result_t StdControl.init() {

    atomic {
      measure = Sbd_Idle;
      measuretype = Sbd_No_Measure;
      supply = Sbd_Supply_Battery;
      batteryCharging = FALSE;
    }

    TOSH_CLR_SBD_MUXA1_PIN();
    TOSH_MAKE_SBD_MUXA1_OUTPUT();

    TOSH_CLR_SBD_MUXA0_PIN();
    TOSH_MAKE_SBD_MUXA0_OUTPUT();

    //    call Random.init();
    //    if (call Random.rand() & 1) 
    TOSH_SET_SBD_EN_BAT_PIN();    
    //    else 
    //      TOSH_CLR_SBD_EN_BAT_PIN();    
    
    TOSH_MAKE_SBD_EN_BAT_OUTPUT();


    TOSH_CLR_SBD_SHDN_DC_DC_2_PIN(); //do not charge battery by default
    TOSH_MAKE_SBD_SHDN_DC_DC_2_OUTPUT();

    TOSH_CLR_SBD_EN_MULT_PIN();
    TOSH_MAKE_SBD_EN_MULT_OUTPUT();

    TOSH_CLR_SBD_SENS_VSUP_PIN();
    TOSH_MAKE_SBD_SENS_VSUP_OUTPUT();

    TOSH_MAKE_SBD_VSUP_INPUT();
    TOSH_SEL_SBD_VSUP_MODFUNC();
    TOSH_MAKE_SBD_CSUP_INPUT();
    TOSH_SEL_SBD_CSUP_MODFUNC();
    return SUCCESS;
  }

  command result_t StdControl.start() { 
      result_t ok1, ok2, ok3, ok4;

      ok1 = call ADCControl.init();
      ok2 = call ADCControl.bindPort(TOSH_ADC_SBD_VSUP_PORT, TOSH_ACTUAL_ADC_SBD_VSUP_PORT);

      ok3 = call ADCControl.init();
      ok4 = call ADCControl.bindPort(TOSH_ADC_SBD_CSUP_PORT, TOSH_ACTUAL_ADC_SBD_CSUP_PORT);

      return rcombine4(ok1, ok2, ok3, ok4); 
  }

  command result_t StdControl.stop() { 
    return SUCCESS; 
  }

  void ADCDone(uint16_t data) {
    uint8_t mtype;
    atomic mtype = measuretype;

    switch (mtype) {
    case Sbd_No_Measure:
      return;
    case Sbd_VsupBat_Measure:
      signal ADCVsupBat.dataReady(data);
      break;
    case Sbd_VsupMux_Measure:
      signal ADCVsupMux.dataReady(data);
      break;
    case Sbd_VsupSuperCap_Measure:
      signal ADCVsupSuperCap.dataReady(data);
      break;
    case Sbd_VsupExtSupply_Measure:
      signal ADCVsupExtSupply.dataReady(data);
      break;
    case Sbd_CsupBat_Measure:
      signal ADCCsupBat.dataReady(data);
      break;
    case Sbd_CsupPanel_Measure:
      signal ADCCsupPanel.dataReady(data);
      break;
    case Sbd_Cglobal_Measure:
      signal ADCCglobal.dataReady(data);
      break;
    }

    atomic {
      measuretype = Sbd_No_Measure;
      measure = Sbd_Idle;
    }
    return;
  }

  event result_t Timer.fired() {
    bool isVoltage;
    atomic isVoltage = (measure == Sbd_Voltage_Measure);
    if (isVoltage) {
      return call VsupAdcRaw.getData();  
    } else {
      return call CsupAdcRaw.getData();  
    }
  }

  task void startTimer() {
    if (call Timer.start(TIMER_ONE_SHOT,ADC_ENABLE_DELAY) == FAIL) {
      signal Timer.fired();
    }
  }

  async event result_t VsupAdcRaw.dataReady(uint16_t data) {
    TOSH_CLR_SBD_EN_MULT_PIN(); // Disable multiplexer
    ADCDone(data);
    return SUCCESS;
  }

  async event result_t CsupAdcRaw.dataReady(uint16_t data) {
    TOSH_CLR_SBD_EN_MULT_PIN(); // Disable multiplexer
    ADCDone(data);
    return SUCCESS;
  }

  async command result_t ADCCsupPanel.getData() {
    uint8_t meas;
    atomic meas = measure;

    if (meas != Sbd_Idle)  return FAIL;
    TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
    TOSH_CLR_SBD_MUXA1_PIN(); 
    TOSH_CLR_SBD_MUXA0_PIN(); 
    atomic {
      measure = Sbd_Current_Measure;
      measuretype = Sbd_CsupPanel_Measure;
    }
    if ((post startTimer()) == FAIL) {
      atomic measure = Sbd_Idle;
      return FAIL;
    }
    return SUCCESS;
  }

  async command result_t ADCCsupPanel.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCCsupPanel.dataReady(uint16_t data) {
    return SUCCESS;
  }

  // Cglobal (global current)
  async command result_t ADCCglobal.getData() {
    uint8_t meas;
    atomic meas = measure;
    
    if (meas != Sbd_Idle) return FAIL;
    TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
    TOSH_SET_SBD_MUXA1_PIN();  // xxx/need proper settings
    TOSH_CLR_SBD_MUXA0_PIN(); 
    atomic {
      measure = Sbd_Current_Measure;
      measuretype = Sbd_Cglobal_Measure;
    }
    if ((post startTimer()) == FAIL) {
      atomic  measure = Sbd_Idle;
      return FAIL;
    }
    return SUCCESS;
  }
  
  async command result_t ADCCglobal.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCCglobal.dataReady(uint16_t data) {
    return SUCCESS;
  }
  
  async command result_t ADCCsupBat.getData() {
    uint8_t meas;
    atomic meas = measure;

    if (meas != Sbd_Idle) return FAIL;
      TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
      TOSH_CLR_SBD_MUXA1_PIN(); 
      TOSH_SET_SBD_MUXA0_PIN(); 
      atomic {
	measure = Sbd_Current_Measure;
	measuretype = Sbd_CsupBat_Measure;
      }
      if ((post startTimer()) == FAIL) {
	atomic  measure = Sbd_Idle;
	return FAIL;
      }
      return SUCCESS;
  }

  async command result_t ADCCsupBat.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCCsupBat.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async command result_t ADCVsupBat.getData() {
    uint8_t meas;
    atomic meas = measure;

    if (meas != Sbd_Idle) return FAIL;
      TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
      TOSH_SET_SBD_MUXA1_PIN(); 
      TOSH_CLR_SBD_MUXA0_PIN(); 
      atomic {
	measure = Sbd_Voltage_Measure;
	measuretype = Sbd_VsupBat_Measure;
      }
      if ((post startTimer()) == FAIL) {
	atomic measure = Sbd_Idle;
	return FAIL;
      }
      return SUCCESS;
  }

  async command result_t ADCVsupBat.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCVsupBat.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async command result_t ADCVsupSuperCap.getData() {
    uint8_t meas;
    atomic meas = measure;

    if (meas != Sbd_Idle) return FAIL;
      TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
      TOSH_CLR_SBD_MUXA1_PIN();
      TOSH_SET_SBD_MUXA0_PIN();
      atomic {
	measure = Sbd_Voltage_Measure;
	measuretype = Sbd_VsupSuperCap_Measure;
      }
      if ((post startTimer()) == FAIL) {
	atomic measure = Sbd_Idle;
	return FAIL;
      }
      return SUCCESS;
  }

  async command result_t ADCVsupSuperCap.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCVsupSuperCap.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async command result_t ADCVsupMux.getData() {
    uint8_t meas;
    atomic meas = measure;

    if (meas != Sbd_Idle) return FAIL;
      TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
      TOSH_CLR_SBD_MUXA1_PIN();  
      TOSH_CLR_SBD_MUXA0_PIN();  
      atomic {
	measure = Sbd_Voltage_Measure;
	measuretype = Sbd_VsupMux_Measure;
      }
      if ((post startTimer()) == FAIL) {
	atomic measure = Sbd_Idle;
	return FAIL;
      }
      return SUCCESS;
  }

  async command result_t ADCVsupMux.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCVsupMux.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async command result_t ADCVsupExtSupply.getData() {
    uint8_t meas;
    atomic meas = measure;

    if (meas != Sbd_Idle) return FAIL;
      TOSH_SET_SBD_EN_MULT_PIN(); // enable multiplexer
      TOSH_SET_SBD_MUXA1_PIN();  
      TOSH_SET_SBD_MUXA0_PIN();  
      atomic {
	measure = Sbd_Voltage_Measure;
	measuretype = Sbd_VsupExtSupply_Measure;
      }
      if ((post startTimer()) == FAIL) {
	atomic measure = Sbd_Idle;
	return FAIL;
      }
      return SUCCESS;
  }

  async command result_t ADCVsupExtSupply.getContinuousData() {
    return FAIL;
  }

  default async event result_t ADCVsupExtSupply.dataReady(uint16_t data) {
    return SUCCESS;
  }

  async command result_t SolarControl.SupplyFromBattery() {
    TOSH_SET_SBD_EN_BAT_PIN();
    atomic { supply = Sbd_Supply_Battery;}
    return SUCCESS;
  }
    
  async command result_t SolarControl.SupplyFromSuperCap() {
    TOSH_CLR_SBD_EN_BAT_PIN();
    atomic { supply = Sbd_Supply_SuperCap;}
    return SUCCESS;
  }

  async command bool SolarControl.isSupplyFromBattery() {
    bool res;
    atomic res = ( supply == Sbd_Supply_Battery);
    return res;
  }

  async command bool SolarControl.isSupplyFromSuperCap() {
    bool res;
    atomic res = ( supply == Sbd_Supply_SuperCap);
    return res;
  }

  async command result_t SolarControl.StartBatteryCharge() {
    TOSH_SET_SBD_SHDN_DC_DC_2_PIN();
    atomic batteryCharging = TRUE;
    return SUCCESS;
  }

  async command result_t SolarControl.StopBatteryCharge() {
    TOSH_CLR_SBD_SHDN_DC_DC_2_PIN();
    atomic batteryCharging = FALSE;
    return SUCCESS;
  }

  async command bool SolarControl.isBatteryCharging() {
    bool b;
    atomic b = batteryCharging;
    return b;
  }

  
}
