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
// $Id: MagMHopRptM.nc,v 1.2 2005/04/15 20:10:06 phoebusc Exp $
/**  
 * MagMHopRpt is a simple application that performs event detection on
 * a magnetometer and multihops it back to a base station.
 * !!!EXPLANATION OF EVENT DETECTION ALGORITHM HERE
 * ??? DO WE STILL WANT UART BACKCHANNEL?  I CAN PUT IT BACK IN
 * The Multihop Routing Algorithm Used is Alec Woo's MintRoute, with
 * the default settings.
 *
 * @author Phoebus Chen
 * @modified 12/1/2004 Created by copying from MagLightTrail
 */

includes MagSNMhopMsgs;
includes MagMHopRptConst;



module MagMHopRptM {
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

    interface Receive as ReceiveQueryConfig;
    interface Send as SendQueryReport;
    interface Send as SendMagReport;
    interface SendMsg as SendMagDebugMsg; //for testing
    interface RouteControl; //for testing

  }
    uses command void pulseSetReset();
}



implementation {

  //Configurable parameters
  uint32_t reportThresh;
  uint16_t readFireInterval;
  uint16_t fadeFireInterval;
  uint8_t resetNumFadeIntervals; //reset value for counter
  uint8_t numFadeIntervals; //counter
  uint8_t windowSize;
  uint16_t reportInterval;

  uint16_t sequenceNo;
  bool pending;
  TOS_Msg msg; // used for mag reading reports
  TOS_Msg msg2; // used for configuration query reports
  TOS_Msg msg3; // used for debug messages
  Mag_t mag;

  //!!!SONG, YOUR DATA STRUCTURES HERE.
  uint32_t dMagV[MAX_WINDOW_SIZE];
  uint8_t  dMagP;
  uint16_t prevMagX;
  uint16_t prevMagY;
  uint16_t lastDetectionTime;
  uint16_t magReadCount;
  
  uint8_t counter; //temporary for testing



  command result_t StdControl.init() {
    uint8_t p;
    
    MagAxes_t axes = { x:TRUE, y:TRUE };

    reportThresh = DEFAULT_REPORT_THRESH; 
    resetNumFadeIntervals = DEFAULT_NUM_FADE_INTERVALS;
    readFireInterval = DEFAULT_READ_FIRE_INTERVAL;
    fadeFireInterval = DEFAULT_FADE_FIRE_INTERVAL;
    windowSize = DEFAULT_WINDOW_SIZE;
    reportInterval = DEFAULT_REPORT_INTERVAL; // Song's addition
    numFadeIntervals = 0;
    sequenceNo = 0;
    magReadCount = 0;
    atomic pending = FALSE;

    // Song's initialization
    for (p=0;p<windowSize;p++) 
      dMagV[p] = 0;
    dMagP = 0;
    prevMagX = 0;
    prevMagY = 0;
    lastDetectionTime = magReadCount;

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



/*   /\* For debugging purposes only. *\/ */
/*   task void debugAction() { */
/*     MagDebugMsg* message = (MagDebugMsg *) msg3.data; */
/*     uint16_t cnt; */
/*     bool sendYes = FALSE; */

/*     uint16_t p; */
/*     uint32_t dMagSum; */
/*     dbg(DBG_USR1, "MagMHopRptM: Sending debug report\n"); */

/*     atomic { if (!pending) { pending = TRUE; sendYes = TRUE;} } */
/*     if (sendYes) { */
/*       for (p=0,dMagSum=0; p<windowSize; p++) */
/* 	dMagSum += dMagV[p]; */
/*       message->dMagV[0] = dMagSum; */
/*       message->dMagV[1] = magReadCount; */
/* /\* 	for (cnt = 0; cnt < 4; cnt++) { *\/ */
/* /\* 	  message->dMagV[cnt] = dMagV[cnt]; *\/ */
/* /\* 	} *\/ */
/* 	message->dMagP = dMagP; */
/* 	message->prevMagX = prevMagX; */
/* 	message->prevMagY = prevMagY; */
/* 	message->dataX = mag.val.x; */
/* 	message->dataY = mag.val.y; */
/* 	message->lastDetectionTime = lastDetectionTime; */

/* 	if ((call SendMagDebugMsg.send(TOS_UART_ADDR, sizeof(MagDebugMsg),&msg3)) != SUCCESS) { */
/* 	  atomic pending = FALSE; */
/* 	} */
/*     } //if sendYes */
/*   } */


  /** Reports the <CODE> numFadeIntervals </CODE> and <CODE> reportThresh </CODE>
   *  values of the mote over the UART.
   */
  task void reportConfig() {
    MagQueryRptMhopMsg* message;
    uint16_t Len;
    bool sendYes = FALSE;

    dbg(DBG_USR1, "MagMHopRptM: Sending configuration settings\n");

    atomic { if (!pending) { pending = TRUE; sendYes = TRUE;} }
    if (sendYes) {
      if (message = (MagQueryRptMhopMsg *) call SendQueryReport.getBuffer(&msg2,&Len)) {
	message->sourceMoteID = TOS_LOCAL_ADDRESS;
	message->numFadeIntervals = resetNumFadeIntervals;
	message->reportThresh = reportThresh;
	message->readFireInterval = readFireInterval;
	message->fadeFireInterval = fadeFireInterval;
	message->windowSize = windowSize;
	message->reportInterval = reportInterval;
	if ((call SendQueryReport.send(&msg2, sizeof(MagQueryRptMhopMsg))) != SUCCESS) {
	  atomic pending = FALSE;
	}
      } else {
	atomic pending = FALSE;
      }
    } //if sendYes

  } //task reportConfig()


  /** This task is posted whenever <CODE> calcEventDetect() </CODE>
   *  decides that we have a magnetic event detection.  It turns on
   *  our red LED and send a report over the UART with the
   *  magnetometer reading value.  It also sets a counter to turn off
   *  the LED after a period of time.
   */
  task void eventDetectAction() {
    MagReportMhopMsg* message;
    uint16_t Len, p;
    uint32_t dMagSum;
    bool sendYes = FALSE;

    dbg(DBG_USR1, "MagMHopRptM: Sending sensor reading\n");

    atomic { if (!pending) { pending = TRUE; sendYes = TRUE;} }
    if (sendYes) {
      if (message = (MagReportMhopMsg *) call SendMagReport.getBuffer(&msg,&Len)) {
	message->sourceMoteID = TOS_LOCAL_ADDRESS;
	message->seqNo = sequenceNo;
	for (p=0,dMagSum=0; p<windowSize; p++)
	  dMagSum += dMagV[p];
	message->dataX = prevMagX;
	message->dataY = prevMagY;
	message->dMagSum = dMagSum;
	message->magReadCount = magReadCount;
	message->treeDepth = call RouteControl.getDepth(); 
	if ((call SendMagReport.send(&msg, sizeof(MagReportMhopMsg))) != SUCCESS) {
	  atomic pending = FALSE;
	  numFadeIntervals = resetNumFadeIntervals;
	  call Leds.redOn();
	}
      } else {
	atomic pending = FALSE;
      }
    } //if sendYes

    sequenceNo++; //overflow OK

    numFadeIntervals = resetNumFadeIntervals;
    call Leds.redOn();
  } //task eventDetectAction()


/** This task is used to compute whether to report a magnetic event
 *  detection. !!!SONG, YOU'RE COMMENTS HERE.
   */
  task void calcEventDetect() {
    //!!! SONG, YOU'RE CODE HERE.  CREATE DATA STRUCTURES ABOVE
    // the variable reportThresh is the report threshold
    // the variable ??? is the number of entries to keep differences of
    //if an event is detected:   post eventDetectAction();

    uint32_t dX,dY;
    uint32_t dMag,dMagSum,p;

    //    post debugAction();     //testing

    // compute magnitude
    dX = (uint32_t) abs(prevMagX - mag.val.x);
    dY = (uint32_t) abs(prevMagY - mag.val.y);
    dMag = sqrt(dX*dX + dY*dY);		// WILL SQRT(.) WORK?
    //    dMag = dX*dX + dY*dY;
    
    // store
    dMagV[dMagP] = dMag;
    prevMagX = mag.val.x;
    prevMagY = mag.val.y;

    // compute accumulative sum
    for (p=0,dMagSum=0; p<windowSize; p++)
      dMagSum += dMagV[p];

    // threshold test: detection on a rising edge
    //!!! May miss on wrap around for seqNo... fix later
    if (dMagSum>reportThresh && magReadCount>lastDetectionTime+reportInterval) {
      lastDetectionTime = magReadCount;
      post eventDetectAction();
    }

    // update dMagP
    dMagP += 1;
    if (dMagP>=windowSize)
      dMagP = 0;

    magReadCount++;

/*     //temporary code, for testing */
/*     counter++; */
/*     if (counter == 0) { */
/*       //      post reportConfig(); */
/*       post eventDetectAction(); */
/*     } */
  } //task calcEventDetect()


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


  event result_t SendMagReport.sendDone(TOS_MsgPtr m, bool success) {
    atomic pending = FALSE;
    return SUCCESS;
  }


  event result_t SendQueryReport.sendDone(TOS_MsgPtr m, bool success) {
    atomic pending = FALSE;
    return SUCCESS;
  }

  event result_t SendMagDebugMsg.sendDone(TOS_MsgPtr m, bool success) {
    atomic pending = FALSE;
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
    mag.val.x = readMag.val.x;
    mag.val.y = readMag.val.y;
    post calcEventDetect();
    return SUCCESS;
  }


  /** Allows the radio to set the number of timer ticks before the
   *  LEDs fade, the reading threshold to trigger the LED to light,
   *  the size of the window used for event detections, and the fade
   *  and read timer fire intervals using an AM_MAGQUERYCONFIGBCASTMSG.  
   */  
  event TOS_MsgPtr ReceiveQueryConfig.receive(TOS_MsgPtr m, void *payload, uint16_t payloadLen) {
    MagQueryConfigBcastMsg* message = (MagQueryConfigBcastMsg* ) payload;

    if ((message->targetMoteID == TOS_LOCAL_ADDRESS) || 
	(message->targetMoteID == TOS_BCAST_ADDR)) {
      switch (message->type) {
      case QUERYMSG:
	post reportConfig();
	break;
      case CONFIGMSG:
	resetNumFadeIntervals = message->numFadeIntervals;
	reportThresh = message->reportThresh;
	readFireInterval = message->readFireInterval;
	fadeFireInterval = message->fadeFireInterval;
	windowSize = message->windowSize;
	reportInterval = message->reportInterval;
	post resetTimers();
	break;
      }
    } // if message->targetMoteID
    return m;
  }
}
