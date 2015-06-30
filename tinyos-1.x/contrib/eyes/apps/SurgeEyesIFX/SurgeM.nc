// $Id: SurgeM.nc,v 1.6 2005/03/01 14:28:45 klueska Exp $

/*                                  tab:4
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
    interface Send;
    interface TDA5250Config;
    interface RouteControl;
    interface Random;
  }
}

implementation {

  enum {
    TIMER_GETADC_COUNT = 1,            // Timer ticks for ADC
    TIMER_CHIRP_COUNT = 10,            // Timer on/off chirp count
  };

  bool sleeping;            // application command state
  bool focused;

  TOS_Msg gMsgBuffer;
  norace uint16_t gSensorData;      // protected by gfSendBusy flag
  uint32_t seqno;
  bool initTimer;
  bool gfSendBusy;


  int timer_rate;
  int timer_ticks;
  /***********************************************************************
   * Initialization
   ***********************************************************************/

  static void initialize() {
    timer_rate = 1000;
    atomic gfSendBusy = FALSE;
    sleeping = FALSE;
    seqno = 0;
    initTimer = TRUE;
    focused = FALSE;
  }

  task void SendData() {
    SurgeMsg *pReading;
    uint16_t Len;
    dbg(DBG_USR1, "SurgeM: Sending sensor reading\n");

    if ((pReading = (SurgeMsg *)call Send.getBuffer(&gMsgBuffer,&Len)) != NULL) {
      pReading->type = SURGE_TYPE_SENSORREADING;
      pReading->parentaddr = call RouteControl.getParent();
      pReading->reading = gSensorData;
      pReading->seq_no = seqno++;

      call Leds.redOn();
      if ((call Send.send(&gMsgBuffer,sizeof(SurgeMsg))) != SUCCESS)
        atomic gfSendBusy = FALSE;
    }
  }

  command result_t StdControl.init() {
    initialize();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    uint16_t randomtimer;
    randomtimer = (call Random.rand() & 0xfff) + 1;
    return call Timer.start(TIMER_ONE_SHOT, randomtimer);
  }

  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  event result_t Timer.fired() {
    uint16_t randomtimer;
    randomtimer = (call Random.rand() % 1000) + 1000;
    dbg(DBG_USR1, "SurgeM: Timer fired\n");
    timer_ticks++;
    if (timer_ticks % TIMER_GETADC_COUNT == 0) {
      call ADC.getData();
    }
    return call Timer.start(TIMER_ONE_SHOT, randomtimer);
  }

  async event result_t ADC.dataReady(uint16_t data) {
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
    call Leds.redOff();    
    call Leds.greenToggle();
    atomic gfSendBusy = FALSE;
    return SUCCESS;
  }
  
  event result_t TDA5250Config.ready(){
    call TDA5250Config.SetRFPower(10);
    call TDA5250Config.UseLowTxPower();
    call TDA5250Config.LowLNAGain();
    return SUCCESS;
  }


}


