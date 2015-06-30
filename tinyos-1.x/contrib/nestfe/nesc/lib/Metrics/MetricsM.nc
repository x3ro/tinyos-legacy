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
// $Id: MetricsM.nc,v 1.2 2005/11/17 23:02:38 phoebusc Exp $
/**
 * Provides 3 functions:
 * 1) Respond to Ping messages immediately
 * 2) Report back at a constant rate
 * 3) Allow tuning of RF power
 * 
 * LED:
 * red - invalid RF power
 * green - received a request packet
 * yellow - ping response or constant rate packet sent
 * 
 * Notes:
 * - Ping response messages reflect sequence numbers of the request number
 *   so we can keep track of missed packets
 * - Constant Rate transmit packets have an increasing sequence number 
 *   counter for tracking missed packets
 * - Stop transmitting by sending a transmit rate (period) of 0
 *   
 * @author Sukun Kim
 * @author Phoebus Chen
 * @modified 10/31/2005 Copied PingPong over for modification
 */

//includes MetricsMsg; // should be included by top level component
module MetricsM
{
  provides interface StdControl;

  uses {
    interface Leds;
    interface Timer;
    interface CC2420Control;

    interface ReceiveMsg as ReceiveCmd;
    interface SendMsg as SendReply;
  }
}

implementation
{
  TOS_Msg replyBffr;
  TOS_Msg reportBffr;
  MetricsReplyMsg *replyMsg = (MetricsReplyMsg *)replyBffr.data;
  MetricsReplyMsg *reportMsg = (MetricsReplyMsg *)reportBffr.data;

  uint16_t counter = 0;
  uint16_t myPeriod = 0;



  command result_t StdControl.init() {
    call Leds.init();
    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }



  void startTimer( uint16_t period ) {
    myPeriod = period;
    if( period == 0 ) {
      call Timer.stop();
    } else {
      call Timer.start( TIMER_REPEAT, period );
    }
  }


  /* No checking if radio is busy before filling buffer 
   * since fire at constant rate.
   */
  event result_t Timer.fired() {
    counter++;
    reportMsg->msgType = CONST_REPORT_REPLY;
    reportMsg->nodeID = TOS_LOCAL_ADDRESS;
    reportMsg->data = counter;
    call SendReply.send(TOS_BCAST_ADDR, sizeof(MetricsReplyMsg), &reportBffr);
    call Leds.yellowToggle();
    return SUCCESS;
  }


  event TOS_MsgPtr ReceiveCmd.receive(TOS_MsgPtr msg) {
    MetricsCmdMsg *cmdMsg = (MetricsCmdMsg *)msg->data;
    call Leds.greenToggle();
    switch (cmdMsg->cmd) {
      case PING:
        replyMsg->tsSend = cmdMsg->tsSend;
        replyMsg->msgType = PING_REPLY;
	replyMsg->nodeID = TOS_LOCAL_ADDRESS;
        replyMsg->data = cmdMsg->data; //copying sequence numbers
        call SendReply.send(TOS_BCAST_ADDR, sizeof(MetricsReplyMsg), &replyBffr);
	call Leds.yellowToggle();
        break;
      case SET_TRANSMIT_RATE:
	startTimer(cmdMsg->data);
        break;
      case GET_TRANSMIT_RATE:
        replyMsg->tsSend = cmdMsg->tsSend;
        replyMsg->msgType = TRANS_RATE_REPLY;
	replyMsg->nodeID = TOS_LOCAL_ADDRESS;
        replyMsg->data = myPeriod;
        call SendReply.send(TOS_BCAST_ADDR, sizeof(MetricsReplyMsg), &replyBffr);
        break;
      case RESET_COUNT:
	counter = 0;
	break;
      case GET_COUNT:
        replyMsg->tsSend = cmdMsg->tsSend;
        replyMsg->msgType = COUNT_REPLY;
	replyMsg->nodeID = TOS_LOCAL_ADDRESS;
        replyMsg->data = counter;
        call SendReply.send(TOS_BCAST_ADDR, sizeof(MetricsReplyMsg), &replyBffr);
        break;
      case SET_RF_POWER:
	if ((cmdMsg->data >= MIN_RF_POWER) && (cmdMsg->data <= MAX_RF_POWER)) {
	  call CC2420Control.SetRFPower((uint8_t) cmdMsg->data);
	} else {
	  call Leds.redToggle();
	}
	break;
      case GET_RF_POWER:
        replyMsg->tsSend = cmdMsg->tsSend;
        replyMsg->msgType = RF_POWER_REPLY;
	replyMsg->nodeID = TOS_LOCAL_ADDRESS;
        replyMsg->data = (uint16_t) (call CC2420Control.GetRFPower());
        call SendReply.send(TOS_BCAST_ADDR, sizeof(MetricsReplyMsg), &replyBffr);
	break;
      default:
        break;
    }
    return msg;
  }


  event result_t SendReply.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}

