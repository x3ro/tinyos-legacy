// $Id: SurgeM.nc,v 1.1.1.1 2007/07/06 03:44:07 ahngang Exp $

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

includes Surge;
includes SurgeCmd;

/*
 *  Data gather application
 */

module SurgeM {
  provides {
    interface StdControl;
  }
  uses {
    interface ADC;
    interface Timer;
    interface Leds;
    interface StdControl as Sounder;
    interface Send;
    interface Receive as Bcast; 
    interface RouteControl;
    interface Query;
  }
}

implementation {

  enum {
    TIMER_GETADC_COUNT = 1,            // Timer ticks for ADC 
    TIMER_CHIRP_COUNT = 10,            // Timer on/off chirp count
  };

  bool sleeping;			// application command state
  bool focused;
  bool rebroadcast_adc_packet;

  TOS_Msg gMsgBuffer;
  norace uint16_t gSensorData;		// protected by gfSendBusy flag
  bool gfSendBusy;

  int timer_rate;
  int timer_ticks;

  bool sendQuery;

  /***********************************************************************
   * Initialization 
   ***********************************************************************/
      
  static void initialize() {
    timer_rate = INITIAL_TIMER_RATE;
    atomic gfSendBusy = FALSE;
    sleeping = FALSE;
    rebroadcast_adc_packet = FALSE;
    focused = FALSE;
    sendQuery = TRUE;
  }

  task void SendData() {
    SurgeMsg *pReading;
    uint16_t Len;
    dbg(DBG_USR1, "SurgeM: Sending sensor reading\n");

    if ((pReading = (SurgeMsg *)call Send.getBuffer(&gMsgBuffer,&Len))) {
      pReading->type = SURGE_TYPE_SENSORREADING;
      pReading->parentaddr = call RouteControl.getParent();
      pReading->reading = gSensorData;

      if ((call Send.send(&gMsgBuffer,sizeof(SurgeMsg))) != SUCCESS)
	atomic gfSendBusy = FALSE;
    }
  }

  command result_t StdControl.init() {
    call Leds.init();
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (TOS_LOCAL_ADDRESS == 0) {
      call Query.StartSendQuery(sendQuery, timer_rate);
      // Send a query if sendQuery == TRUE.
      // The query is broadcasted using maximum power level (255) and
      // is not flooded (i.e., is not forwarded by sensor nodes).
    }
    else {
    //if (TOS_LOCAL_ADDRESS == 8 || TOS_LOCAL_ADDRESS == 21 || 
    //    TOS_LOCAL_ADDRESS == 22 || TOS_LOCAL_ADDRESS == 20 || 
    //    TOS_LOCAL_ADDRESS == 15 || TOS_LOCAL_ADDRESS == 29 || 
    //    TOS_LOCAL_ADDRESS == 24 || TOS_LOCAL_ADDRESS == 32 || 
    //    TOS_LOCAL_ADDRESS == 26 || TOS_LOCAL_ADDRESS == 18 || 
    //    TOS_LOCAL_ADDRESS == 3 || TOS_LOCAL_ADDRESS == 35)  {
        call Timer.start(TIMER_REPEAT, timer_rate);
        // If this node does not receive a query,
        // this node operates with this timer.
    //}
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/
  
  event result_t Timer.fired() {
    dbg(DBG_USR1, "SurgeM: Timer fired\n");
    timer_ticks++;
    if (timer_ticks % TIMER_GETADC_COUNT == 0) {
      call ADC.getData();
    }
    // If we're the focused node, chirp
    if (focused && timer_ticks % TIMER_CHIRP_COUNT == 0) {
      call Sounder.start();
    }
    // If we're the focused node, chirp
    if (focused && timer_ticks % TIMER_CHIRP_COUNT == 1) {
      call Sounder.stop();
    }
    return SUCCESS;
  }

  async event result_t ADC.dataReady(uint16_t data) {
    //SurgeMsg *pReading;
    //uint16_t Len;
    dbg(DBG_USR1, "SurgeM: Got ADC reading: 0x%x\n", data);
    atomic {
      if (!gfSendBusy) {
	gfSendBusy = TRUE;	
	gSensorData = data;
	post SendData();
      }
    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr pMsg, result_t success) {
    dbg(DBG_USR2, "SurgeM: output complete 0x%x\n", success);
    atomic gfSendBusy = FALSE;
    return SUCCESS;
  }

  static void HandleStartSendData(uint16_t rate) {
    dbg(DBG_USR3, "SurgeM: QueryRecvd rate=%i\n", rate);
    call Timer.stop();
    //if (TOS_LOCAL_ADDRESS == 8 || TOS_LOCAL_ADDRESS == 21 ||
    //    TOS_LOCAL_ADDRESS == 22 || TOS_LOCAL_ADDRESS == 20 ||
    //    TOS_LOCAL_ADDRESS == 15 || TOS_LOCAL_ADDRESS == 29 ||
    //    TOS_LOCAL_ADDRESS == 24 || TOS_LOCAL_ADDRESS == 32 ||
    //    TOS_LOCAL_ADDRESS == 26 || TOS_LOCAL_ADDRESS == 18 ||
    //    TOS_LOCAL_ADDRESS == 3 || TOS_LOCAL_ADDRESS == 35)  {
      call Timer.start(TIMER_REPEAT, timer_rate);
      // This node recieved a query. 
      // This node will operate using this Timer.
    //}
  }

  event result_t Query.StartSendData(uint16_t rate) {
    HandleStartSendData(rate);
    return SUCCESS;
  }

  /* Command interpreter for broadcasts
   *
   */

  event TOS_MsgPtr Bcast.receive(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLen) {
    SurgeCmdMsg *pCmdMsg = (SurgeCmdMsg *)payload;

    dbg(DBG_USR2, "SurgeM: Bcast  type 0x%02x\n", pCmdMsg->type);

    if (pCmdMsg->type == SURGE_TYPE_SETRATE) {       // Set timer rate
      timer_rate = pCmdMsg->args.newrate;
      dbg(DBG_USR2, "SurgeM: set rate %d\n", timer_rate);
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, timer_rate);

    } else if (pCmdMsg->type == SURGE_TYPE_SLEEP) {
      // Go to sleep - ignore everything until a SURGE_TYPE_WAKEUP
      dbg(DBG_USR2, "SurgeM: sleep\n");
      sleeping = TRUE;
      call Timer.stop();
      call Leds.greenOff();
      call Leds.yellowOff();

    } else if (pCmdMsg->type == SURGE_TYPE_WAKEUP) {
      dbg(DBG_USR2, "SurgeM: wakeup\n");

      // Wake up from sleep state
      if (sleeping) {
	initialize();
        call Timer.start(TIMER_REPEAT, timer_rate);
	sleeping = FALSE;
      }

    } else if (pCmdMsg->type == SURGE_TYPE_FOCUS) {
      dbg(DBG_USR2, "SurgeM: focus %d\n", pCmdMsg->args.focusaddr);
      // Cause just one node to chirp and increase its sample rate;
      // all other nodes stop sending samples (for demo)
      if (pCmdMsg->args.focusaddr == TOS_LOCAL_ADDRESS) {
	// OK, we're focusing on me
	focused = TRUE;
	call Sounder.init();
	call Timer.stop();
	call Timer.start(TIMER_REPEAT, FOCUS_TIMER_RATE);
      } else {
	// Focusing on someone else
	call Timer.stop();
	call Timer.start(TIMER_REPEAT, FOCUS_NOTME_TIMER_RATE);
      }

    } else if (pCmdMsg->type == SURGE_TYPE_UNFOCUS) {
      // Return to normal after focus command
      dbg(DBG_USR2, "SurgeM: unfocus\n");
      focused = FALSE;
      call Sounder.stop();
      call Timer.stop();
      call Timer.start(TIMER_REPEAT, timer_rate);
    }
    return pMsg;
  }

}


