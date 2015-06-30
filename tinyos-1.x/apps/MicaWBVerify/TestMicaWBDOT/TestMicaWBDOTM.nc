/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:  Joe Polastre
 *
 */

includes GDI2SoftMsg;

module TestMicaWBDOTM {
    provides interface StdControl;
    uses {
        interface Leds;
	interface Timer;

        interface SplitControl as HamamatsuControl;
        interface SplitControl as HumidityControl;
        interface SplitControl as PressureControl;
        interface SplitControl as TaosControl;

        interface ADC as HamamatsuCh1;
        interface ADC as HamamatsuCh2;
        interface ADC as Humidity;
        interface ADC as HumidityTemp;
        interface ADC as Pressure;
        interface ADC as PressureTemp;
        interface ADC as TaosCh0;
        interface ADC as TaosCh1;

	interface SendMsg as Send;
    }
}
implementation {
  // declare module static variables here
  
  TOS_Msg msg_buf;
  TOS_MsgPtr msg;

  GDI2Soft_WS_Msg* datastruct;

  uint8_t state;

  enum {
    HAMAMATSU_MASK = 0x01,
    HUMIDITY_MASK = 0x02,
    PRESSURE_MASK = 0x04,
    TAOS_MASK = 0x08,
    TOTAL_MASK = 0x0F
  };

  task void sendMsg() {
    call Leds.yellowOn();
    call Leds.redOff();
    call Send.send(TOS_BCAST_ADDR, sizeof(GDI2Soft_WS_Msg), msg);
  }

  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    msg = &msg_buf;
    datastruct = (GDI2Soft_WS_Msg*)msg_buf.data;
    call HamamatsuControl.init();
    call HumidityControl.init();
    call PressureControl.init();
    call TaosControl.init();
    call Leds.init();
    return SUCCESS;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    state = 0;
    datastruct->source = TOS_LOCAL_ADDRESS;
    call Timer.start(TIMER_REPEAT, 5000);
    return SUCCESS;
  }

  /**
   * Stop this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    // sample
    call Leds.redOn();
    state = 0;
    call HamamatsuControl.start();
    call HumidityControl.start();
    call PressureControl.start();
    call TaosControl.start();
    return SUCCESS;
  }

  event result_t HamamatsuControl.startDone() {
    call HamamatsuCh1.getData();
    return SUCCESS;
  }

  event result_t HumidityControl.startDone() {
    call Humidity.getData();
    return SUCCESS;
  }

  event result_t PressureControl.startDone() {
    call Pressure.getData();
    return SUCCESS;
  }

  event result_t TaosControl.startDone() {
    call TaosCh0.getData();
    return SUCCESS;
  }

  event result_t HamamatsuCh1.dataReady(uint16_t data) {
    datastruct->hamamatsu_top = data;
    return call HamamatsuCh2.getData();
  }
 
  event result_t HamamatsuCh2.dataReady(uint16_t data) {
    datastruct->hamamatsu_bottom = data;
    call HamamatsuControl.stop();
    atomic state |= HAMAMATSU_MASK;
    if (state == TOTAL_MASK)
      post sendMsg();
    return SUCCESS;
  }

  event result_t Humidity.dataReady(uint16_t data) {
    datastruct->humidity = data;
    return call HumidityTemp.getData();
  }

  event result_t HumidityTemp.dataReady(uint16_t data) {
    datastruct->humidity_temp = data;
    call HumidityControl.stop();
    atomic state |= HUMIDITY_MASK;
    if (state == TOTAL_MASK) 
      post sendMsg();
    return SUCCESS;
  }

  event result_t Pressure.dataReady(uint16_t data) {
    datastruct->pressure = data;
    return call PressureTemp.getData();
  }

  event result_t PressureTemp.dataReady(uint16_t data) {
    datastruct->pressure_temp = data;
    call PressureControl.stop();
    atomic state |= PRESSURE_MASK;
    if (state == TOTAL_MASK) 
      post sendMsg();
    return SUCCESS;
  }

  event result_t TaosCh0.dataReady(uint16_t data) {
    datastruct->taos_ch0_top = (data & 0x0FF);
    datastruct->taos_ch0_bottom = ((data >> 8) & 0x0FF);
    return call TaosCh1.getData();
  }

  event result_t TaosCh1.dataReady(uint16_t data) {
    datastruct->taos_ch1_top = (data & 0x0FF);
    datastruct->taos_ch1_bottom = ((data >> 8) & 0x0FF);
    call TaosControl.stop();
    atomic state |= TAOS_MASK;
    if (state == TOTAL_MASK)
      post sendMsg();
    return SUCCESS;
  }
  
  event result_t HamamatsuControl.initDone() {
    return SUCCESS;
  }

  event result_t HamamatsuControl.stopDone() {
    return SUCCESS;
  }

  event result_t HumidityControl.initDone() {
    return SUCCESS;
  }

  event result_t HumidityControl.stopDone() {
    return SUCCESS;
  }

  event result_t PressureControl.initDone() {
    return SUCCESS;
  }

  event result_t PressureControl.stopDone() {
    return SUCCESS;
  }

  event result_t TaosControl.initDone() {
    return SUCCESS;
  }

  event result_t TaosControl.stopDone() {
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr sent_msgptr, result_t success){
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
    return SUCCESS;
  }
}
