// $Id: VoltageM.nc,v 1.4 2005/10/26 19:47:42 jpolastre Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Module for measuring supply voltage (Vcc) on telos. Value returned
 * by dataReady() is in millivolts.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module VoltageM {
  provides {
    interface ADC as Voltage;
    interface StdControl;
  }
  uses {
    interface ADC;
    interface ADCControl;
  }
}

implementation {

  enum {
    ERROR_VOLTAGE = 0xffff,
  };

  enum {
    VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_1_5 = ASSOCIATE_ADC_CHANNEL(
      INTERNAL_VOLTAGE,
      REFERENCE_VREFplus_AVss,
      REFVOLT_LEVEL_1_5),
    VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_2_5 = ASSOCIATE_ADC_CHANNEL(
      INTERNAL_VOLTAGE,
      REFERENCE_VREFplus_AVss,
      REFVOLT_LEVEL_2_5),
  };

  uint8_t state;
  uint16_t voltage;

  enum {
    S_IDLE,
    S_GET_DATA_1_5,
    S_GET_DATA_2_5,
  };

  command result_t StdControl.init() {
    atomic state = S_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call ADCControl.init();
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void signalReady(uint16_t v) {
    atomic state = S_IDLE;
    signal Voltage.dataReady(v);
  }

  task void signalReadyTask() {
    uint32_t tmpVoltage;
    // DVcc = (ADCCounts/4096)*Vref*2
    atomic {
      tmpVoltage = voltage;
      switch(state) {
      case S_GET_DATA_1_5: tmpVoltage *= 3000; break;
      case S_GET_DATA_2_5: tmpVoltage *= 5000; break;
      }
      tmpVoltage >>= 12;
    }
    signalReady(tmpVoltage);
  }

  task void sample() {

    result_t result;
    uint8_t tmpState;
    uint16_t port;

    atomic tmpState = state;

    port = (tmpState == S_GET_DATA_1_5) ?
      VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_1_5 :
      VOLTAGE_ACTUAL_ADC_INTERNAL_VOLTAGE_PORT_2_5;
    
    result = call ADCControl.bindPort(TOS_ADC_VOLTAGE_PORT, port);
    result = rcombine(call ADC.getData(), result);
    
    if (result == FAIL)
      signalReady(ERROR_VOLTAGE);

  }

  async command result_t Voltage.getData() {

    uint8_t tmpState;

    atomic tmpState = state;

    if (tmpState != S_IDLE)
      return FAIL;

    atomic state = S_GET_DATA_1_5;

    if (post sample() == FAIL)
      return FAIL;

    return SUCCESS;

  }
  
  /*
   * Not supported.
   */
  async command result_t Voltage.getContinuousData() {
    return FAIL;
  }

  async event result_t ADC.dataReady(uint16_t data) {

    result_t result;

    if (data == 0xfff) {
      atomic state = S_GET_DATA_2_5;
      result = post sample();
    }
    else {
      atomic voltage = data;
      result = post signalReadyTask();
    }

    if (result == FAIL)
      signalReady(ERROR_VOLTAGE);
      
    return SUCCESS;

  }

}
