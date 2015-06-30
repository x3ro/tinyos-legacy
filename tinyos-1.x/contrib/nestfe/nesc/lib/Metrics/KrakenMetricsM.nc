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
// $Id: KrakenMetricsM.nc,v 1.2 2005/11/17 23:02:38 phoebusc Exp $
/**
 * Reduced functionality from MetricsM.nc to eliminate redundancy of
 * sending constant rate packets (done by DetectionEvent module) and
 * setting the radio power level (can be done through RPC, which is more
 * reliable since disseminated through Drip).
 * 
 * Provides 2 functions:
 * 1) Respond to Ping messages immediately
 * 2) Expose RPC interface to call CC2420Control.GetRFPower
 * 
 * LED (if connected):
 * red - invalid RF power or packet type
 * green - received a request packet
 * yellow - ping response
 * 
 * Notes:
 * - Ping response messages reflect sequence numbers of the request number
 *   so we can keep track of missed packets
 *   
 * @author Phoebus Chen
 * @modified 11/8/2005 Copied and Modified from MetricsM and DetectionEventM
 */

//includes MetricsMsg; // should be included by top level component
//includes Drain;
includes Rpc;

module KrakenMetricsM
{
  provides interface StdControl;
  provides interface RemoteRadioControl @rpc(); //for calling over RPC

  uses {
    interface Leds;
    interface CC2420Control;

    interface ReceiveMsg as ReceiveCmd;
    interface SendMsg as SendReplyMsg;
    interface Send;
  }
}

implementation
{
  TOS_Msg replyBuf;
  bool msgBufBusy;


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


  /* For external calls by rpc. */
  command result_t RemoteRadioControl.SetRFPower(uint8_t power) {
    return call CC2420Control.SetRFPower(power);
  }

  /* For external calls by rpc. */
  command result_t RemoteRadioControl.GetRFPower() {
    return call CC2420Control.GetRFPower();
  }


  /** 
   * IMPLEMENTATION NOTES:
   * - Assumes TOS_BCAST_ADDR sends up the Drain tree (see Drain documentation)
   * - Put code for getting the send buffer in the switch statement
   *   because we don't want SET_RF_POWER to fail if can't get send
   *   buffer
   * - PING or GET_RF_POWER fails silently if it cannot send a message
   *   (no LED toggling)
   */
  event TOS_MsgPtr ReceiveCmd.receive(TOS_MsgPtr msg) {
    MetricsCmdMsg *cmdMsg = (MetricsCmdMsg *)msg->data;
    uint16_t maxLength;
    MetricsReplyMsg *replyMsg;

    call Leds.greenToggle();

    switch (cmdMsg->cmd) {
      case PING:
	replyMsg = call Send.getBuffer(&replyBuf, &maxLength);
	if (msgBufBusy || maxLength < sizeof(MetricsReplyMsg)) {
	  return msg; //Failed attempt to send
	}
	msgBufBusy = TRUE;
	memset(replyMsg, 0, sizeof(MetricsReplyMsg));
    
        replyMsg->tsSend = cmdMsg->tsSend;
        replyMsg->msgType = PING_REPLY;
	replyMsg->nodeID = TOS_LOCAL_ADDRESS;
        replyMsg->data = cmdMsg->data; //copying sequence numbers
        if (call SendReplyMsg.send(TOS_BCAST_ADDR,
				sizeof(MetricsReplyMsg), &replyBuf) == FAIL) {
	  msgBufBusy = FALSE;
	}
	call Leds.yellowToggle();
        break;
      case SET_TRANSMIT_RATE:
	call Leds.redToggle();
        break;
      case GET_TRANSMIT_RATE:
	call Leds.redToggle();
        break;
      case RESET_COUNT:
	call Leds.redToggle();
	break;
      case GET_COUNT:
	call Leds.redToggle();
        break;
      case SET_RF_POWER:
	call Leds.redToggle();
	break;
      case GET_RF_POWER:
	call Leds.redToggle();
	break;
      default:
        break;
    }
    return msg;
  }


  event result_t SendReplyMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == &replyBuf) {
      msgBufBusy = FALSE;
    }
    return SUCCESS;
  }

  // Dummy Handler
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}

