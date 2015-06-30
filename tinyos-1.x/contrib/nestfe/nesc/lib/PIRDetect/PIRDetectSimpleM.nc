/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: PIRDetectSimpleM.nc,v 1.7 2005/07/08 04:11:09 phoebusc Exp $
/**
 *
 * 
 * @author Phoebus Chen, Mike Manzo
 * @modified 6/2/2005 Initial Port of UVA Detection Code
 */

includes Registry;

#define PIRINITTIME 500
#define PIRSAMPLEPERIOD 102
#define MOTIONTHRESHOLD 3000

module PIRDetectSimpleM
{
  provides interface StdControl;

  uses interface Attribute<uint16_t> as MotionThreshold @registry("MotionThreshold");
  uses interface Attribute<uint16_t> as PIRDetection @registry("PIRDetection");
  uses interface Attribute<uint16_t> as PIRRawData @registry("PIRRawData");
    
  uses {
    interface Timer as InitTimer;
    interface Timer as SampleTimer;
    interface StdControl as PIRControl;
    interface ADC as PIRADC;
    interface PIR;
    interface Leds;    
  }
}

implementation
{
  uint16_t dataVal;
  uint16_t motionThreshold;


  command result_t StdControl.init() {
    motionThreshold = MOTIONTHRESHOLD;
    atomic { dataVal = 0; }
    call Leds.init();
    return call PIRControl.init();
  }


  command result_t StdControl.start() {
    //////////Registry Code Start//////////
    call PIRDetection.set(0);
    call PIRRawData.set(0);
    //    if (call MotionThreshold.valid() == FALSE) {
      call MotionThreshold.set(motionThreshold);
    //    }
    //////////Registry Code Stop//////////

    call PIRControl.start();
    call InitTimer.start(TIMER_ONE_SHOT,PIRINITTIME);
    return SUCCESS;
  }


  command result_t StdControl.stop() {
    call SampleTimer.stop();
    call PIR.PIROff();
    call PIRControl.stop();   
    return SUCCESS;
  }


  //Not much processing here
  task void processing() {
    atomic {
      if (dataVal > motionThreshold) {
	call PIRDetection.set(100);
      } else {
	call PIRDetection.set(0);
      }
      call PIRRawData.set(dataVal);
    }
    call Leds.yellowToggle();
  }



  event result_t InitTimer.fired() {
    call PIR.PIROn();
    call SampleTimer.start(TIMER_REPEAT,PIRSAMPLEPERIOD);
    return SUCCESS;
  }


  async event result_t PIRADC.dataReady(uint16_t val) {
    atomic{dataVal = val;}
    post processing();
    return SUCCESS;
  }


  event result_t SampleTimer.fired() {
    return call PIRADC.getData();
  }


  //////////Registry Code Start//////////
  event void MotionThreshold.updated(uint16_t val) {
    motionThreshold = val;
  }

  event void PIRDetection.updated(uint16_t val) {
  //Do nothing
  }

  event void PIRRawData.updated(uint16_t val) {
  //Do nothing
  }
  //////////Registry Code Stop//////////



////////////////////////////// PIR control code ////////////////////////////// 
// !!! Need to add PIR control code from registry

  event void PIR.readDetectDone(uint8_t val) {
    //    atomic detect_pot = val;
    //    post detect_report_task();
  }

  event void PIR.readQuadDone(uint8_t val) {
    //    atomic quad_pot = val;
    //    post quad_report_task();
  }

  event void PIR.adjustDetectDone(bool result) { }
  event void PIR.adjustQuadDone(bool result) { }

  event void PIR.firedPIR() {
    //    atomic mask = IOSWITCH1_INT_PIR;
    //    post interrupt_report_task();
  }

  //  event void PIR
}
