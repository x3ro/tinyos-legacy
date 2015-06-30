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

module TestHumidityM {
    provides interface StdControl;
    uses {
        interface Leds;
	interface Timer;
        interface SplitControl as ADCControl;
	interface StdControl as CommControl;
        interface ADC as Humidity;
        interface ADC as Temperature;
        interface ADCError as HumidityError;
        interface ADCError as TemperatureError;
	interface SendMsg as Send;
    }
}
implementation {
  // declare module static variables here
  
  TOS_Msg msg_buf;
  TOS_MsgPtr msg;
  uint16_t HumData;
  uint16_t TempData;

  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    msg = &msg_buf;
    call ADCControl.init();
    call CommControl.init();
    call Leds.init();
    return SUCCESS;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    call HumidityError.enable();
    call TemperatureError.enable();
    call CommControl.start();
    call Timer.start(TIMER_REPEAT, 2000);
    return SUCCESS;
  }

  /**
   * Stop this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    call ADCControl.stop();
    call Timer.stop();
    return SUCCESS;
  }

  event result_t ADCControl.initDone() {
    return SUCCESS;
  }

  event result_t ADCControl.stopDone() {
    return SUCCESS;
  }

  event result_t Timer.fired() {
    // sample
    call Leds.redOn();
    call ADCControl.start();
    return SUCCESS;
  }

  event result_t ADCControl.startDone() {
    short* sdata = (short*)(msg_buf.data);

    sdata[0] = 0xff;
    sdata[1] = 0xff;
    sdata[2] = 0xff;
    sdata[3] = 0xff;
    sdata[4] = 0xff;
    sdata[5] = 0xff;
    sdata[6] = 0xff;

    call Humidity.getData();
    return SUCCESS;
  }

  event result_t HumidityError.error(uint8_t token)
  {
    short* sdata = (short*)(msg_buf.data);
    sdata[1] = 0;
    call Temperature.getData();
    return SUCCESS;
  }
  
  async event result_t Humidity.dataReady(uint16_t data)
  {
    short* sdata = (short*)(msg_buf.data);
    sdata[1] = data;
    HumData = (uint16_t) data;
//    call Leds.greenOn();
    call Temperature.getData();
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token)
  {
    short* sdata = (short*)(msg_buf.data); 
    sdata[0] = TOS_LOCAL_ADDRESS;
    sdata[2] = 0;
    msg->data[6] = 0x99;
    call ADCControl.stop();
    call Send.send(TOS_BCAST_ADDR, 7, msg);
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data)
  {
    short* sdata = (short*)(msg_buf.data); 

    call Leds.greenOff();

    sdata[0] = TOS_LOCAL_ADDRESS;
    sdata[2] = data;
    TempData = (uint16_t) data;

    {
      float fTemp, fHumidity;
      fTemp = -38.4 + 0.0098 * (float)TempData;
      fHumidity = -4.0 + 0.0405 * HumData - 0.0000028 * HumData * HumData;
      fHumidity = (fTemp - 25.0)*(0.01 + 0.00008 * HumData) + fHumidity;
      fTemp = 10*fTemp;

      sdata[1] = (uint16_t) fTemp;
      sdata[2] = (uint16_t) fHumidity;
    }

    msg->data[6] = 0x99;
    call ADCControl.stop();
    call Send.send(TOS_BCAST_ADDR, 7, msg);
    return SUCCESS;
  }
   
  event result_t Send.sendDone(TOS_MsgPtr sent_msgptr, result_t success){ 
    call Leds.redOff();
    return SUCCESS;
  }

}
