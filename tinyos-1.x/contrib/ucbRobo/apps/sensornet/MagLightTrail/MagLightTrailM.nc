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
 */
// $Id: MagLightTrailM.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**  
 * MagLightTrail is an application used for testing the sensitivity of
 * the magnetometer.  When a magnetic reading on either the X or Y
 * axis exceeds a threshold <CODE> reportThresh </CODE>, the LEDS
 * light up for a period of time <CODE> resetNumFadeIntervals *
 * fadeFireInterval </CODE>.  This is meant for leaving a "light
 * trail" after a COTSBOT with a magnet runs through a sensor network
 * field.
 *
 * @author Phoebus Chen
 * @modified 9/30/2004 Fixed misuse of pending flag
 * @modified 7/28/2004 First Implementation
 */

includes MagMsg;



module MagLightTrailM {
  provides {
   interface StdControl;
  }

  uses {
    interface Leds;

    interface Timer as SenseTimer;
    interface Timer as FadeTimer;

    interface StdControl as MagControl;
    interface MagSensor;
    interface MagAxesSpecific;

    interface ReceiveMsg as ReceiveQueryConfigMsg;
    interface SendMsg as SendQueryReportMsg;
    interface SendMsg as SendMagReportMsg;
  }
    uses command void pulseSetReset();
}



implementation {

  enum {
    DEFAULT_REPORT_THRESH = 600,
    DEFAULT_NUM_FADE_INTERVALS = 2,
    DEFAULT_READ_FIRE_INTERVAL = 50,
    DEFAULT_FADE_FIRE_INTERVAL = 500
  };

  uint16_t reportThresh;
  uint16_t readFireInterval;
  uint16_t fadeFireInterval;
  uint8_t resetNumFadeIntervals; //reset value for counter
  uint8_t numFadeIntervals; //counter
  uint16_t sequenceNo;
  bool pending;
  TOS_Msg msg; // used for mag reading reports
  TOS_Msg msg2; // used for configuration query reports
  Mag_t mag;



  command result_t StdControl.init() {
    MagAxes_t axes = { x:TRUE, y:TRUE };

    reportThresh = DEFAULT_REPORT_THRESH;
    resetNumFadeIntervals = DEFAULT_NUM_FADE_INTERVALS;
    readFireInterval = DEFAULT_READ_FIRE_INTERVAL;
    fadeFireInterval = DEFAULT_FADE_FIRE_INTERVAL;
    numFadeIntervals = 0;
    sequenceNo = 0;
    pending = FALSE;
    call Leds.init();
    call MagControl.init();
    call MagAxesSpecific.enableAxes(axes); //return type void
    return SUCCESS;
  }


  command result_t StdControl.start() {
    return rcombine3(call MagControl.start(),
		     call SenseTimer.start(TIMER_REPEAT, readFireInterval),
		     call FadeTimer.start(TIMER_REPEAT, fadeFireInterval));
  }


  command result_t StdControl.stop() {
    return rcombine(call SenseTimer.stop(), call FadeTimer.stop());
  }


  /** This task is posted when a magnetometer reading exceeds the
   *  threshold <CODE> reportThresh </CODE>.  It turns on our red LED
   *  and send a report over the UART with the magnetometer reading
   *  value.  It also sets a counter to turn off the LED after a
   *  period of time.
   */
  task void strongReadAction() {
    MagReportMsg* message = (MagReportMsg *) msg.data; 

    if (!pending) {
      pending = TRUE;

      message->sourceMoteID = TOS_LOCAL_ADDRESS;
      message->seqNo = sequenceNo;
      message->dataX = mag.val.x;
      message->dataY = mag.val.y;

      if (!call SendMagReportMsg.send(TOS_UART_ADDR, sizeof(MagReportMsg),&msg)) {
	pending = FALSE;
      }
    }

    sequenceNo++; //overflow OK

    numFadeIntervals = resetNumFadeIntervals;
    call Leds.redOn();
  }


  /** Reports the <CODE> resetNumFadeIntervals </CODE> and <CODE> reportThresh </CODE>
   *  values of the mote over the UART.
   */
  task void reportConfig() {
    MagQueryConfigMsg* message = (MagQueryConfigMsg *) msg2.data; 
    if (!pending) {
      pending = TRUE;

      message->type = QUERYREPORTMSG;
      message->sourceMoteID = TOS_LOCAL_ADDRESS;
      message->resetNumFadeIntervals = resetNumFadeIntervals;
      message->reportThresh = reportThresh;
      message->readFireInterval = readFireInterval;
      message->fadeFireInterval = fadeFireInterval;

      if (!call SendQueryReportMsg.send(TOS_UART_ADDR, sizeof(MagQueryConfigMsg), &msg2)) {
	pending = FALSE;
      }
    }
  } //task reportConfig()


  /** Restarts the SenseTimer to fire at <CODE> readFireInterval
   *  </CODE> and the FadeTimer to fire at <CODE> fadeFireInterval
   *  </CODE>.  Posted when a reconfiguration message is sent
   */
  task void resetTimers() {
    if (call SenseTimer.stop()) {
      call SenseTimer.start(TIMER_REPEAT, readFireInterval);
    }
    if (call FadeTimer.stop()) {
      call FadeTimer.start(TIMER_REPEAT, fadeFireInterval);
    }
  } //task resetTimers()


  event result_t SendMagReportMsg.sendDone(TOS_MsgPtr m, bool success) {
    pending = FALSE;
    return SUCCESS;
  }


  event result_t SendQueryReportMsg.sendDone(TOS_MsgPtr m, bool success) {
    pending = FALSE;
    return SUCCESS;
  }


  event result_t FadeTimer.fired() {
    atomic {
      if (numFadeIntervals > 0) { //prevents underflow errors
	numFadeIntervals--;
      }
    }
    if (numFadeIntervals <= 0) {call Leds.redOff();}
    call pulseSetReset(); //should put this elsewhere, but just temporary for testing
    return SUCCESS;
  }


  event result_t SenseTimer.fired() {
    return call MagSensor.read();
  }


  event result_t MagSensor.readDone(Mag_t readMag) {
    if (readMag.val.x > reportThresh || readMag.val.y > reportThresh) {
      mag.val.x = readMag.val.x;
      mag.val.y = readMag.val.y;
      post strongReadAction();
    }
    return SUCCESS;
  }


  /** Allows the radio to set the number of timer ticks before the
   *  LEDs fade, the reading threshold to trigger the LED to light,
   *  and the fade and read timer fire intervals using an
   *  AM_MAGQUERYCONFIGMSG.
   */
  event TOS_MsgPtr ReceiveQueryConfigMsg.receive(TOS_MsgPtr m) {
    MagQueryConfigMsg* message = (MagQueryConfigMsg* ) m->data;
    switch (message->type) {
    case QUERYMSG:
      post reportConfig();
      break;
    case CONFIGMSG:
      resetNumFadeIntervals = message->resetNumFadeIntervals;
      reportThresh = message->reportThresh;
      readFireInterval = message->readFireInterval;
      fadeFireInterval = message->fadeFireInterval;
      post resetTimers();
      break;
    }
    return m;
  }
}
