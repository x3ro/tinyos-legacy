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

/**
 * Temperature Sensor on Extension Board
 *
 * @author Henri Dubois-Ferriere
 * @author Maxime Muller 
 *
 */
 
includes sensorboard;

module ExTempM {
  provides {
    interface StdControl;
    interface ADC;
  }

  uses {
    interface ADCControl;
    interface ADC as ExTempADC;
    interface Timer;
  }
}

implementation {
    enum {
	ADC_ENABLE_DELAY = 1  // 1ms delay to enable ADC channel; 
    };

  command result_t StdControl.init()
  {
    TOSH_CLR_EX_TEMPE_PIN();
    TOSH_MAKE_EX_TEMPE_OUTPUT();

    TOSH_MAKE_EX_TEMP_INPUT();
    TOSH_SEL_EX_TEMP_MODFUNC();

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
      result_t ok1, ok2;
      ok1 = call ADCControl.init();
      ok2 = call ADCControl.bindPort(TOSH_ADC_EX_TEMP_PORT, TOSH_ACTUAL_ADC_EX_TEMP_PORT);
      return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop()
  {
      TOSH_CLR_EX_TEMPE_PIN();
      return SUCCESS;
  }
  
  task void EnableTimer() {
  	call Timer.start(TIMER_ONE_SHOT,ADC_ENABLE_DELAY);
  }
  
  // power-up temperature sensor and launch timer for ADC conversion
   async command result_t ADC.getData() {
      TOSH_SET_EX_TEMPE_PIN();
      if(!post EnableTimer())
      		return FAIL;

      return SUCCESS;
  }

  async command result_t ADC.getContinuousData() {
      TOSH_SET_EX_TEMPE_PIN();
      return call ExTempADC.getContinuousData();
  }


  event result_t Timer.fired() {
      return call ExTempADC.getData();  
  }

  // signal new data asynchronously and power down
  async event result_t ExTempADC.dataReady(uint16_t data) {
  	  signal ADC.dataReady(data);

      TOSH_CLR_EX_TEMPE_PIN();
      return SUCCESS;
  }         
}
