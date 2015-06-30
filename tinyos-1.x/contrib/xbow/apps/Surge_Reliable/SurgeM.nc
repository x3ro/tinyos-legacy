// $Id: SurgeM.nc,v 1.5 2004/03/17 23:47:13 gtolle Exp $

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
    interface Timer as TempTimer;
    interface Timer;
    interface Leds;
    interface StdControl as AccelCtl;
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface StdControl as Sounder;
    interface StdControl as TempStdControl;
    interface StdControl as LightStdControl;
    interface Send;
    interface Receive as Bcast; 
    interface RouteControl;
    interface AttrUse;
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
  norace uint16_t gAccelx;		// protected by gfSendBusy flag
  norace uint16_t gAccely;		// protected by gfSendBusy flag
  norace uint16_t gLight;		// protected by gfSendBusy flag
  bool gfSendBusy;


  uint32_t timer_rate;
  uint16_t timer_ticks;
  /***********************************************************************
   * Initialization 
   ***********************************************************************/
      
  static void initialize() {
#ifndef PLATFORM_PC
    outp(0x00, DDRF);
#endif
    timer_rate = INITIAL_TIMER_RATE - (TOS_LOCAL_ADDRESS << 3);
    atomic gfSendBusy = FALSE;
    sleeping = FALSE;
    rebroadcast_adc_packet = FALSE;
    focused = FALSE;
    call TempStdControl.init();
    call LightStdControl.init();
  }

  task void SendData() {
    SurgeMsg *pReading;
    uint16_t magx, magy;
    uint16_t Len;
    uint32_t batt;
    uint16_t error_no;
    dbg(DBG_USR1, "SurgeM: Sending sensor reading\n");
      
    if (pReading = (SurgeMsg *)call Send.getBuffer(&gMsgBuffer,&Len)) {
      pReading->type = SURGE_TYPE_SENSORREADING;
      pReading->parentaddr = call RouteControl.getParent();
      pReading->reading = gPowerData;
      pReading->seq_no ++;
	batt = ((uint32_t)(gSensorData)) << 23;
	pReading->seq_no &= 0x7fffff;
	pReading->seq_no += batt;
      pReading->temp = gTemp;
      pReading->light = gLight;
      pReading->accelx = gAccelx >> 2;
      pReading->accely = gAccely >> 2;
	call AttrUse.getAttrValue("mag_x", &magx, &error_no);
	call AttrUse.getAttrValue("mag_y", &magy, &error_no);
      pReading->magx = magy;
      pReading->magy = magx;
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
    call Timer.start(TIMER_REPEAT, timer_rate);

    call AttrUse.startAttr((call AttrUse.getAttr("mag_x"))->id);
    call AttrUse.startAttr((call AttrUse.getAttr("mag_y"))->id);
    
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
      call AccelCtl.start();
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
	call TempTimer.start(TIMER_ONE_SHOT, 10);
 	return SUCCESS; 
  }
  event result_t TempTimer.fired() {
	call Temp.getData();
  }

	

  async event result_t Temp.dataReady(uint16_t data) {
	if(gTemp == 0){
		gTemp = 1;
		call Temp.getData();
		return SUCCESS;
	}	
	gTemp = data >> 2;	
	call TempStdControl.stop();
	call AccelX.getData();
 	return SUCCESS; 

  }
  async event result_t AccelX.dataReady(uint16_t data) {
	gAccelx = data;	
	call AccelY.getData();
 	return SUCCESS; 
  }
  async event result_t AccelY.dataReady(uint16_t data) {
	gAccely = data;	
	call Batt.getData();
 	return SUCCESS; 
  }

	
  async event result_t Batt.dataReady(uint16_t data) {
    //SurgeMsg *pReading;
    //uint16_t Len;
    //TOSH_CLR_BAT_MON_PIN();
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

  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo)  {
	return SUCCESS;
  }

  event result_t AttrUse.startAttrDone(uint8_t id)
 {
	return SUCCESS;
  }

}


