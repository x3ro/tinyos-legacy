// $Id: SurgeM.nc,v 1.1 2004/03/17 03:48:19 gtolle Exp $

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
    interface ADC as Light;
    interface ADCControl;
    interface Timer;
    interface Timer as ChirpTimer;
    interface Timer as SendTimer;
    interface Random;
    interface Leds;
    interface StdControl as Sounder;
    interface StdControl as TempStdControl;
    interface StdControl as LightStdControl;
    interface Send;
    interface Receive as Bcast; 
    interface RouteControl;
    interface AbsoluteTimer;
    interface CC1000Control;
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

  bool useBeep;
  bool chirping;

  TOS_Msg gMsgBuffer;
  norace uint16_t gSensorData;		// protected by gfSendBusy flag
  norace uint16_t gPowerData;		// protected by gfSendBusy flag
  norace uint16_t gTemp;		// protected by gfSendBusy flag
  norace uint16_t gLight;		// protected by gfSendBusy flag
  norace uint32_t gTime;
  norace uint32_t gSampleTime;
  bool gfSendBusy;


  uint32_t timer_rate;
  uint16_t timer_ticks;

  uint8_t mySlot;
  uint8_t numSlots;
  uint8_t goodRounds;
  uint8_t goodRound;
  uint8_t easyMode;

  uint16_t sendLight;
  bool myTurn;
  uint8_t darkThreshhold;

  /***********************************************************************
   * Initialization 
   ***********************************************************************/
      
  static void initialize() {
//      timer_rate = INITIAL_TIMER_RATE - (TOS_LOCAL_ADDRESS << 3);
      timer_rate = INITIAL_SLOT_LENGTH;
      atomic {
	  numSlots = INITIAL_NUM_SLOTS;
	  mySlot = 0;
	  goodRounds = 0;
	  goodRound = FALSE;
	  myTurn = FALSE;
	  darkThreshhold = 0xb0;
      }
      atomic gfSendBusy = FALSE;
      sleeping = FALSE;
      rebroadcast_adc_packet = FALSE;
      focused = FALSE;
      useBeep = FALSE;
      easyMode = TRUE;
      call LightStdControl.init();
  }

  task void SendData() {
    SurgeDemoMsg *pReading;
    uint16_t Len;
    dbg(DBG_USR1, "SurgeM: Sending sensor reading\n");
      
    if (pReading = (SurgeDemoMsg *)call Send.getBuffer(&gMsgBuffer,&Len)) {
      pReading->type = SURGE_TYPE_SENSORREADING;
      pReading->seq_no ++;
      pReading->light = gLight;
      pReading->depth = mySlot;
      atomic {
	  pReading->goodRound = goodRound;
	  pReading->goodRounds = goodRounds;
	  goodRound = FALSE;
	  goodRounds = 0;
      }
/*
      pReading->time = gTime;
      pReading->sampletime = gSampleTime;
*/
      gTemp = gLight = 0;

      if ((call Send.send(&gMsgBuffer,sizeof(SurgeDemoMsg))) != SUCCESS)
	atomic gfSendBusy = FALSE;
    }
  }

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {

      call LightStdControl.start();

      if (TOS_LOCAL_ADDRESS != 0) {
//	  call Timer.start(TIMER_REPEAT, timer_rate);
	  call AbsoluteTimer.setRepeat(timer_rate, 0);
      }
      return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  event result_t SendTimer.fired() {
      if (!gfSendBusy) {
	  gfSendBusy = TRUE;	
	  post SendData();
      }
      return SUCCESS;
  }

  event result_t Timer.fired() {
      call Light.getData();
      return SUCCESS;
  }

  event result_t ChirpTimer.fired() {
      if (chirping == FALSE) {
	  chirping = TRUE;
	  call Sounder.start();
	  call ChirpTimer.start(TIMER_ONE_SHOT, 64);
      } else {
	  call Sounder.stop();
	  chirping = FALSE;
      }
      return SUCCESS;
  }

  event result_t AbsoluteTimer.fired() {
      return SUCCESS;
  }

  event result_t AbsoluteTimer.firedRepeat(tos_time_t t) {
      dbg(DBG_USR1, "@%lld SurgeM: Timer fired at TIME:%d\n",
	  tos_state.tos_time/3784, t.low32);
      timer_ticks++;

      call Leds.yellowToggle();

      call Timer.start(TIMER_ONE_SHOT, 144);

      if ((t.low32 - (mySlot * timer_rate)) 
	  % (numSlots * timer_rate) < 32) {
	  // it's my turn to sample

	  dbg(DBG_USR1, "SurgeM: Taking sensor reading\n");
	  atomic { 
	      myTurn = TRUE;
	  }
	  
	  //TOSH_SET_BAT_MON_PIN();
	  //TOSH_uwait(250);
//	  call LightStdControl.start();
	  atomic gSampleTime = t.low32;

	  call Leds.redOn();

	  if (useBeep) {
	      call Sounder.start();
	  }

	  // If we're the focused node, chirp
	  if (focused && timer_ticks % TIMER_CHIRP_COUNT == 0) {
	      call Sounder.start();
	  }

	  // If we're the focused node, chirp
	  if (focused && timer_ticks % TIMER_CHIRP_COUNT == 1) {
	      call Sounder.stop();
	  }

      } else if ((t.low32 - ((mySlot+1) * timer_rate)) 
		 % (numSlots * timer_rate) < 32) {
	  // it's my turn to send
	  call Leds.redOff();

	  call Sounder.stop();

	  atomic {
	      myTurn = FALSE;
	      gTime = t.low32;
	      if (goodRound == TRUE) {
		  call ChirpTimer.start(TIMER_ONE_SHOT, 144); 
	      }
	      call SendTimer.start(TIMER_ONE_SHOT,
				   call Random.rand() % timer_rate);
	  }	  
	  
	  mySlot = call RouteControl.getDepth();
      }

      return SUCCESS;
  }
  
  async event result_t Light.dataReady(uint16_t data) {
      uint16_t myLight;

      atomic {
	  myLight = data >> 2;
	  if (myTurn) {
	      gLight = myLight;
	  }

	  if (myLight < darkThreshhold && myTurn) {
	      goodRounds++;
	      
	      if (goodRounds >= numSlots || easyMode == TRUE) {
		  goodRound = TRUE;
	      }
	  } else if (myLight > darkThreshhold && !myTurn) {
	      goodRounds++;
	  }
      }

      return SUCCESS; 
  }

  event result_t Send.sendDone(TOS_MsgPtr pMsg, result_t success) {
    dbg(DBG_USR2, "SurgeM: output complete 0x%x\n", success);
    //call Leds.greenToggle();
    atomic gfSendBusy = FALSE;
    call Sounder.stop();

    return SUCCESS;
  }


  /* Command interpreter for broadcasts
   *
   */

  event TOS_MsgPtr Bcast.receive(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLen) {
    SurgeCmdMsg *pCmdMsg = (SurgeCmdMsg *)payload;

    dbg(DBG_USR2, "SurgeM: Bcast  type 0x%02x\n", pCmdMsg->type);

    if (TOS_LOCAL_ADDRESS == 0)
	return pMsg;

    switch (pCmdMsg->type) {

    case SURGE_TYPE_RADIOPOWER:
#ifndef PLATFORM_PC
	call CC1000Control.SetRFPower((uint8_t)pCmdMsg->value);
#endif
	break;

    case SURGE_TYPE_DARKTHRESHHOLD:
	darkThreshhold = pCmdMsg->value;
	break;

    case SURGE_TYPE_SETRATE:
	timer_rate = pCmdMsg->value;
	dbg(DBG_USR2, "SurgeM: set rate %d\n", timer_rate);
	call AbsoluteTimer.cancel();
	call AbsoluteTimer.setRepeat(timer_rate, 0);
	break;
	
    case SURGE_TYPE_BEEP:
	useBeep = TRUE;
	break;
	
    case SURGE_TYPE_BEEPOFF:
	useBeep = FALSE;
	break;

    case SURGE_TYPE_EASYMODE:
	easyMode = TRUE;
	break;
	
    case SURGE_TYPE_HARDMODE:
	easyMode = FALSE;
	break;
    }

    return pMsg;
  }
}



