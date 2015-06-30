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
// $Id: MarkSeqM.nc,v 1.1 2005/11/09 02:31:55 phoebusc Exp $
/**
 * Telos "Remote Control" Mote
 *
 * Button Triggered radio messages
 * 1) "Reset Button Event"
 *    - radio message sent on bootup (ex. from hitting reset)
 * 2) Single Click User Button Event
 *    - sent with a delay of DCLICK_PERIOD
 * 3) Double Click User Button Event
 *    - sent if clicks separated by less than DCLICK_PERIOD
 *    - message includes delay between clicks
 * - All messages share a single sequence number counter (obviously,
 *   reset to 0 on mote reset)
 * 
 * LED Toggling:
 * Red - Double Click
 * Green - Single Click
 * Yellow - Send Sucess (not really necessary)
 *
 * NOTE: we call Timer and SendMsg from UserButton.fired(), which is
 * asynchronous, because we want to minimize the delay between a
 * button press and a message sent over the radio.
 *
 * @author Mike Manzo, Phoebus Chen
 * @modified 10/31/2005 copied initial version by Mike Manzo
 */

includes MarkSeqMsg;
module MarkSeqM {
  provides {
    interface StdControl;
  }
  uses {
    interface SendMsg;
    interface MSP430Event as UserButton;
    interface Leds;
    interface Timer;
    interface LocalTime; // in 1/32 binary milliseconds
  }
}



implementation {
  TOS_Msg sendMsg;
  TOS_Msg sendMsg2;
  uint16_t seqNo;
  uint32_t oldClickTime;
  bool recentClick;


  command result_t StdControl.init() {
    seqNo = 0;
    recentClick = FALSE;
    call Leds.init();
    return SUCCESS;
  }
  /**
   * Notifies base station that mote has been reset.
   */
  command result_t StdControl.start() {
    MarkSeqMsg *markseqmsg = (MarkSeqMsg *) sendMsg.data;
    markseqmsg->type = RESET_TYPE;
    markseqmsg->seqNo = seqNo;
    markseqmsg->delay = 0; // field not used
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(MarkSeqMsg), &sendMsg);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }



  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (success) {
      call Leds.yellowToggle();
    }
    return success;
  }


  /**
   * markseqmsg->delay is only valid if the time interval between clicks
   * is less than 2^27 seconds
   */
  async event void UserButton.fired() {
    bool myRecentClick;
    uint32_t clickTime;
    MarkSeqMsg *markseqmsg = (MarkSeqMsg *) sendMsg.data;

    atomic { 
      myRecentClick = recentClick;
      recentClick = !recentClick;
    }
    clickTime = call LocalTime.read();
    if (!myRecentClick) {
      call Timer.start(TIMER_ONE_SHOT, DCLICK_PERIOD);
    } else { // Handle Double Click Event
      atomic{
	seqNo++;
	markseqmsg->seqNo = seqNo;
      }
      markseqmsg->type = DOUBLE_CLICK_TYPE;
      markseqmsg->delay = (clickTime - oldClickTime) >> 5;
      // >> 5   converts jiffy to binary ms
      call SendMsg.send(TOS_BCAST_ADDR, sizeof(MarkSeqMsg), &sendMsg);
      call Leds.redToggle();
    }
    oldClickTime = clickTime;
  }


  /**
   * If Timer fires and there has not been another button click,
   * then this is a single click event.
   */
  event result_t Timer.fired() {
    bool myRecentClick;
    MarkSeqMsg *markseqmsg = (MarkSeqMsg *) sendMsg2.data;

    atomic {
      myRecentClick = recentClick;
      recentClick = FALSE;
    }
    if (myRecentClick) {
      atomic{
	seqNo++;
	markseqmsg->seqNo = seqNo;
      }
      markseqmsg->type = SINGLE_CLICK_TYPE;
      markseqmsg->delay = DCLICK_PERIOD; // assumes timer is accurate
      call SendMsg.send(TOS_BCAST_ADDR, sizeof(MarkSeqMsg), &sendMsg2);
      call Leds.greenToggle();
    }
    return SUCCESS;
  }
}
