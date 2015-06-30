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

module TestPressureM {
    provides interface StdControl;
    uses {
        interface Leds;
	interface Timer;
        interface SplitControl as ADCControl;
	interface StdControl as CommControl;
        interface ADC as Pressure;
        interface ADC as Temperature;
        interface ADCError as PressureError;
        interface ADCError as TemperatureError;
	interface Calibration;
	interface SendMsg as Send;
    }
}
implementation {
  // declare module static variables here
  
  TOS_Msg msg_buf;
  TOS_MsgPtr msg;

  char count;

  uint16_t calibration[6];

  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    call ADCControl.init();
    call CommControl.init();
    call Leds.init();
    return SUCCESS;
  }

  event result_t ADCControl.initDone() {
    return SUCCESS;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    call PressureError.enable();
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
    count = 0;

    {
    short* sdata = (short*)(msg_buf.data);
    sdata[0] = 0xff;
    sdata[1] = 0xff;
    sdata[2] = 0xff;
    sdata[3] = 0xff;
    sdata[4] = 0xff;
    sdata[5] = 0xff;
    sdata[6] = 0xff;
    sdata[7] = 0xff;
    sdata[8] = 0xff;
    sdata[9] = 0xff;
    sdata[10] = 0xff;
    sdata[11] = 0xff;
    sdata[12] = 0xff;
    sdata[13] = 0xff;
    }

    call Calibration.getData();
    return SUCCESS;
  }

  event result_t Calibration.dataReady(char word, uint16_t value) {

    // make sure we get all the calibration bytes
    count++;

    calibration[word-1] = value;

    if (count == 4) {
      call Pressure.getData();
    }

    return SUCCESS;
  }

  event result_t PressureError.error(uint8_t token) {
    short* sdata = (short*)(msg_buf.data);
    sdata[1] = 0;

    call Temperature.getData();
    return SUCCESS;
  }
  
  async event result_t Pressure.dataReady(uint16_t data)
  {
    short* sdata = (short*)(msg_buf.data);
    sdata[1] = data;

    call Leds.greenOn();

    call Temperature.getData();
    return SUCCESS;
  }

  event result_t TemperatureError.error(uint8_t token)
  {
    char i;
    short* sdata = (short*)(msg_buf.data); 
    sdata[0] = TOS_LOCAL_ADDRESS;
    sdata[2] = 0;

    call ADCControl.stop();

    for (i = 0; i < 4; i++)
      sdata[(int)(3+i)] = calibration[(int)i];

    msg = &msg_buf;

    msg->data[14] = 0x99;
    call Send.send(TOS_BCAST_ADDR, 15, msg);
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data)
  {
    char i;
    short* sdata = (short*)(msg_buf.data); 
    sdata[0] = TOS_LOCAL_ADDRESS;
    sdata[2] = data;

    call ADCControl.stop();

    call Leds.yellowOn();

    for (i = 0; i < 4; i++)
      sdata[(int)(3+i)] = calibration[(int)i];

    msg = &msg_buf;

    msg->data[14] = 0x99;

    {
      short* sdata = (short*)(msg_buf.data); 
      uint16_t C1, C2, C3, C4, C5, C6, PressureData;
      
      float UT1,dT,Temp;
      float OFF,SENS,X,Press;

      PressureData = sdata[1];
      

      C1 = calibration[0] >> 1;
      C2 = ((calibration[2] &  0x3f) << 6) |  (calibration[3] &  0x3f);
      C3 = calibration[3]  >> 6;
      C4 = calibration[2]  >> 6;
      C5 = ((calibration[0] &  1) << 10) |  (calibration[1] >>  6); 
      C6 = calibration[1] &  0x3f;     

      //temperature   
      UT1=8*(float)C5+20224;
      dT = (float)data-UT1;
      Temp = 200.0 + dT*((float)C6+50.0)/1024.0;

      //pressure
      OFF = (float)C2*4 + (((float)C4-512.0)*dT)/1024;
      SENS = (float)C1 + ((float)C3*dT)/1024 + 24576;
      X = (SENS*((float)PressureData-7168.0))/16384 - OFF;
      Press = X/32.0 + 250.0;      

      sdata[0] = TOS_LOCAL_ADDRESS;
      sdata[1] = (short) Temp;
      sdata[2] = (short) Press;
      sdata[3] = 0xffff;
    }

    call Send.send(TOS_BCAST_ADDR, 15, msg);
    return SUCCESS;
  }
   
  event result_t Send.sendDone(TOS_MsgPtr sent_msgptr, result_t success){ 
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
    return SUCCESS;
  }

}
