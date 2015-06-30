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
// $Id: MagLocalAggRptM.nc,v 1.2 2005/04/15 20:10:06 phoebusc Exp $
/**
 * MagLocalAggRptM serves as the glue code for the application, performing
 * miscellaneous functions such as passing configuration messages
 * between components, lighting the Leds as visual debugging tools,
 * and storing the position of the node.
 *
 * @author Phoebus Chen
 * @modified 8/25/2004 First Implementation
 */

includes MagLocalAggRptConst;
includes MagSNMsgs;
includes MagAggTypes;
includes MagSensorTypes;
includes LocationTypes;


module MagLocalAggRptM {
  provides {
   interface StdControl;
   interface Location;
  }

  uses {
    interface StdControl as CoreCompControl;
    interface Leds;
    interface Timer as FadeTimer;

    interface SenseUpdate;
    interface CompComm;

    interface ConfigAggProcessing;
    interface ConfigTrigger;
    interface ConfigMagProcessing;

    interface ReceiveMsg as ReceiveQueryConfigMsg;
    interface ReceiveMsg as ReceiveMagReportMsg;
    interface SendMsg as SendQueryReportMsg;
    interface SendMsg as SendMagReportMsg;
    interface SendMsg as SendMagLeaderReportMsg;
  }
}



implementation {
  enum {
    //for message sending buffer management
    M_RPT = 0,
    ML_RPT = 1,
    QC_RPT = 2
  };

  // initially hardcoded by moteID address
  location_t myLocation;
 
  uint16_t fadeFireInterval;
  uint8_t resetNumFadeIntervals; //reset value for counter
  uint8_t numFadeIntervals; //counter

  uint16_t l_reportSeqNo, m_reportSeqNo;

  bool pending;
  // used for mag reading reports, mag leader reports, and
  // configuration query reports (one each)
  TOS_Msg msg[3]; 

  //temporary buffers for tasks
  Mag_t myMagRead;
  MagWeightPos_t myMagAgg;



  /** This task turns on our red LED, sends a broadcast report over
   *  the radio with the magnetometer reading value, and also sets a
   *  counter to turn off the LED after a period of time.  This task
   *  is posted by <CODE> SenseUpdate.senseFired() </CODE>.  Drops
   *  message if radio is busy.
   */
  task void strongReadAction() {
    MagReportMsg* message = (MagReportMsg *) msg[M_RPT].data; 

    if (!pending) {
      pending = TRUE;

      message->sourceMoteID = TOS_LOCAL_ADDRESS;
      message->seqNo = m_reportSeqNo;
      message->dataX = myMagRead.val.x;
      message->dataY = myMagRead.val.y;
      message->biasX = myMagRead.bias.x;
      message->biasY = myMagRead.bias.y;
      message->posX = myLocation.pos.x;
      message->posY = myLocation.pos.y;
      
      if (!call SendMagReportMsg.send(TOS_BCAST_ADDR, sizeof(MagReportMsg), &msg[M_RPT])) {
	pending = FALSE;
      }
    }

    m_reportSeqNo++; //overflow OK

    numFadeIntervals = resetNumFadeIntervals;
    call Leds.redOn();
  }


  /** Sends an aggregate report over the radio.  This task is posted
   *  by <CODE> CompComm.aggDataReady() </CODE>.  Drops message if
   *  radio is busy.
   */
  task void sendLeaderReport() {
    MagLeaderReportMsg* message = (MagLeaderReportMsg *) msg[ML_RPT].data;
    
    if (!pending) {
      pending = TRUE;

      message->sourceMoteID = TOS_LOCAL_ADDRESS;
      message->seqNo = l_reportSeqNo;
      message->dupFlag =  myMagAgg.dupFlag;
      message->numReports =  myMagAgg.numReports;
      message->magSum =  myMagAgg.magSum;
      message->posX = myMagAgg.posX;
      message->posY = myMagAgg.posY;

      if (!call SendMagLeaderReportMsg.send(TOS_BCAST_ADDR, sizeof(MagLeaderReportMsg), &msg[ML_RPT])) {
	pending = FALSE;
      }
    }
   
    l_reportSeqNo++; //overflow OK
  }


  /** Reports the <CODE> resetNumFadeIntervals </CODE> and <CODE>
   *  reportThresh </CODE> values of the mote over the UART.  Drops
   *  message if radio is busy.
   */
  task void reportConfig() {
    MagQueryConfigMsg* message = (MagQueryConfigMsg *) msg[QC_RPT].data; 
    
    if (!pending) {
      pending = TRUE;

      message->reportThresh = call ConfigTrigger.getReportThresh();
      message->readFireInterval = call ConfigTrigger.getReadFireInterval();
      message->windowSize = call ConfigMagProcessing.getMovAvgWindowSize();
      message->timeOut = call ConfigAggProcessing.getTimeOut();
      message->staleAge = call ConfigAggProcessing.getStaleAge();

      message->type = QUERYREPORTMSG;
      message->sourceMoteID = TOS_LOCAL_ADDRESS;
      message->resetNumFadeIntervals = resetNumFadeIntervals;
      message->fadeFireInterval = fadeFireInterval;

      if (!call SendQueryReportMsg.send(TOS_BCAST_ADDR, sizeof(MagQueryConfigMsg), &msg[QC_RPT])) {
	pending = FALSE;
      }
    }
  } //task reportConfig()


  /** Restarts the FadeTimer to fire at <CODE> fadeFireInterval
   *  </CODE>.  Posted when a reconfiguration message is sent.
   */
  task void resetTimer() {
    if (call FadeTimer.stop()) {
      call FadeTimer.start(TIMER_REPEAT, fadeFireInterval);
    }
  } //task resetTimers()



  command result_t StdControl.init() {
    myLocation.pos.x = (TOS_LOCAL_ADDRESS >> 4) & 0x0f;
    myLocation.pos.y = (TOS_LOCAL_ADDRESS >> 0) & 0x0f;

    fadeFireInterval = DEFAULT_FADE_FIRE_INTERVAL;
    resetNumFadeIntervals = DEFAULT_NUM_FADE_INTERVALS;
    numFadeIntervals = 0;

    m_reportSeqNo = 0;
    l_reportSeqNo = 0;
    pending = FALSE;

    return rcombine(call CoreCompControl.init(),call Leds.init());
  }


  command result_t StdControl.start() {
    return rcombine(call CoreCompControl.start(),
		    call FadeTimer.start(TIMER_REPEAT, fadeFireInterval));
  }


  command result_t StdControl.stop() {
    return rcombine(call CoreCompControl.stop(), call FadeTimer.stop());
  }


  command location_t Location.getPosition() {
    return myLocation;
  }



  event result_t SendMagReportMsg.sendDone(TOS_MsgPtr m, bool success) {
    pending = FALSE;
    return SUCCESS;
  }


  event result_t SendMagLeaderReportMsg.sendDone(TOS_MsgPtr m, bool success) {
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
    return SUCCESS;
  }


  /** posts <CODE> strongReadAction </CODE> after buffering the
   *  sensing value.
   */
  event result_t SenseUpdate.senseFired(Mag_t value) {
    myMagRead = value;
    post strongReadAction();
    return SUCCESS; //!!! double wiring a problem?
  }


  /** Saves everything and posts a task to send the leader report
   */
  event result_t CompComm.aggDataReady(MagWeightPos_t aggReport) {
    myMagAgg = aggReport;
    post sendLeaderReport();
    return SUCCESS;
  }


  /** Allows the radio to set the number of timer ticks before the
   *  LEDs fade, the reading threshold to trigger the LED to light,
   *  and the fade and read timer fire intervals using an
   *  AM_MAGQUERYCONFIGMSG.
   */
  event TOS_MsgPtr ReceiveMagReportMsg.receive(TOS_MsgPtr m) {
    MagReportMsg* message = (MagReportMsg* ) m->data;
    Mag_t magReport = {
	val: {
	  x: message->dataX,
	  y: message->dataY
	},
	bias: {
	  x: message->biasX,
	  y: message->biasY,
	}
    };
    location_t loc = {
      pos: {
	x: message->posX,
	y: message->posY
      }
    };

    call CompComm.passReports(message->sourceMoteID, magReport, loc);
    return m;
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
      call ConfigTrigger.setReportThresh(message->reportThresh);
      call ConfigTrigger.setReadFireInterval(message->readFireInterval);
      call ConfigMagProcessing.setMovAvgWindowSize(message->windowSize);
      call ConfigAggProcessing.setTimeOut(message->timeOut);
      call ConfigAggProcessing.setStaleAge(message->staleAge);

      resetNumFadeIntervals = message->resetNumFadeIntervals;
      fadeFireInterval = message->fadeFireInterval;
      post resetTimer();
      break;
    }
    return m;
  }
}
