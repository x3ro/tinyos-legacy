// $Id: SurgeM.nc,v 1.4 2004/06/14 05:05:15 jlhill Exp $

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
    interface ADC as Batt;
    interface ADC as Temp;
    interface ADC as Light;
    interface ADCControl;
    interface Timer;
    interface Leds;
    interface StdControl as Sounder;
    interface StdControl as TempStdControl;
    interface StdControl as LightStdControl;
    interface Send;
    interface Receive as Bcast; 
    interface RouteControl;
    command uint16_t GetSendCount();
    command uint16_t GetPower();
    command uint16_t GetPower_check();
    command uint16_t GetPower_send();
    command uint16_t GetPower_receive();
    command uint16_t GetPower_total_sum();
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
  norace uint16_t gPowerData;		// protected by gfSendBusy flag
  norace uint16_t gTemp;		// protected by gfSendBusy flag
  norace uint16_t gLight;		// protected by gfSendBusy flag
  bool gfSendBusy;


  uint32_t timer_rate;
  uint16_t timer_ticks;
  /***********************************************************************
   * Initialization 
   ***********************************************************************/
      
  static void initialize() {

    timer_rate = 184320 - (TOS_LOCAL_ADDRESS << 7);
#ifdef TEN_X
    timer_rate = 18432 - (TOS_LOCAL_ADDRESS << 7);
#endif
    //timer_rate = 1320 - (TOS_LOCAL_ADDRESS << 7);
    //timer_rate = 8320 - (TOS_LOCAL_ADDRESS << 7);
    atomic gfSendBusy = FALSE;
    sleeping = FALSE;
    rebroadcast_adc_packet = FALSE;
    focused = FALSE;
    call TempStdControl.init();
    call LightStdControl.init();
  }

  task void SendData() {
    SurgeMsg *pReading;
    uint16_t Len;
    uint32_t batt;
    dbg(DBG_USR1, "SurgeM: Sending sensor reading\n");
    gPowerData = call GetPower();
      
    if ((pReading = (SurgeMsg *)call Send.getBuffer(&gMsgBuffer,&Len))) {
      pReading->type = SURGE_TYPE_SENSORREADING;
      pReading->parentaddr = call RouteControl.getParent();
      pReading->reading = gPowerData;
      pReading->magx = call GetPower_check();
      pReading->magy = call GetPower_receive();
      pReading->accelx = call GetPower_send();
      pReading->accely = call GetSendCount();
      pReading->light = call GetPower_total_sum();
      pReading->seq_no ++;
      batt = ((uint32_t)(gSensorData)) << 23;
      pReading->seq_no &= 0x7fffff;
      pReading->seq_no += batt;
      pReading->temp = gTemp;
      //pReading->light = gLight;
      gTemp = gLight = 0;
	
      if ((call Send.send(&gMsgBuffer,sizeof(SurgeMsg))) != SUCCESS)
	atomic gfSendBusy = FALSE;
    }

  }

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, timer_rate);
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
      //TOSH_SET_BAT_MON_PIN();
      //TOSH_uwait(250);
      call LightStdControl.start();
      call Light.getData();
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
  
  async event result_t Light.dataReady(uint16_t data) {
	if(gLight == 0){
		gLight = 1;
		call Light.getData();
		return SUCCESS;
	}	
	gLight = data >> 2;	
	call LightStdControl.stop();
        call TempStdControl.start();
	call Temp.getData();
 	return SUCCESS; 
  }

  async event result_t Temp.dataReady(uint16_t data) {
	if(gTemp == 0){
		gTemp = 1;
		call Temp.getData();
		return SUCCESS;
	}	
	gTemp = data >> 2;	
	call TempStdControl.stop();
	call Batt.getData();
 	return SUCCESS; 

  }

	
  async event result_t Batt.dataReady(uint16_t data) {
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
    //call Leds.greenToggle();
    atomic gfSendBusy = FALSE;
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


