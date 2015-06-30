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
// $Id: TestCtrlBotsM.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**
 * TestCtrlBots is for sending a continuous stream of commands to the cotsbot
 * to run forward and backwards at two different speeds.  This is convenient
 * for testing that the communication to the COTSBOT is working when
 * you do not have RobotCmdGUI close at hand. <P>
 * 
 * See documentation for the <CODE> MsgTimer.Fired() </CODE> event for
 * a description of its operation.
 *
 * @author Phoebus Chen
 * @modified 9/30/2004 Fixed pending flag issue
 * @modified 7/22/2004 First implementation
 *
 */

includes MotorBoard;
includes RobotCmdMsg;



module TestCtrlBotsM { 
  provides interface StdControl;
  uses {
    interface Leds;
    interface SendMsg;
    interface Timer as MsgTimer;
  }
}



implementation {

  uint16_t ticks;
  TOS_Msg msg;
  bool pending;
  bool sendSpeedPending;

  enum {
    NO_SPEED = 0,
    REVERSE_SPEED = 1,
    FORWARD_SPEED = 2,
    WAITTIME = 2,
    DEMO_SPEED = 32
  };


  command result_t StdControl.init() {
    ticks = 0;
    pending = FALSE;
    sendSpeedPending = FALSE;
    return call Leds.init();
  }


  command result_t StdControl.start() {
    return call MsgTimer.start(TIMER_REPEAT, 1000);
  }


  command result_t StdControl.stop() {
    return SUCCESS;
  }


  /** Time trigger to send commands to the COTSBOT in succession.
   *  <OL>
   *  <LI> Go Forward and set the forward speed </LI>
   *  <LI> Go Backward and set the reverse speed </LI>
   *  <LI> Stop </LI>
   *  <LI> Repeat </LI>
   *  </OL>
   *  The yellow LED lights in the stop phase.
   */
  event result_t MsgTimer.fired() {
    RobotCmdMsg *message = (RobotCmdMsg *)msg.data;
    call Leds.redToggle();
    ticks++;

    if (!pending) {
      pending = TRUE;

      if (ticks == WAITTIME) {
	message->type = SET_DIRECTION;
	message->data[0] = FORWARD;
	sendSpeedPending = FORWARD;
      } else if (ticks == 2 * WAITTIME) {
	message->type = SET_DIRECTION;
	message->data[0] = REVERSE;      
	sendSpeedPending = REVERSE;
      } else if (ticks == 3 * WAITTIME) { //stop
	call Leds.yellowToggle();
	message->type = SET_SPEED;
	message->data[0] = 0;
	ticks = 0;
      } else {
	return SUCCESS;
      }

      if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(RobotCmdMsg), &msg)) {
	pending = FALSE;
      }
    } //pending

    return SUCCESS;
  }


  /** Called by <CODE> SendMsg.sendDone() </CODE> right after it sends
   *  a message changing the direction of the robot.  This task is
   *  similar to <CODE> sendReverseSpeed </CODE>.
   */
  task void sendForwardSpeed() {
    RobotCmdMsg* message = (RobotCmdMsg *) msg.data;
    if (!pending) {
      pending = TRUE;

      message->type = SET_SPEED;
      message->data[0] = DEMO_SPEED;

      if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(RobotCmdMsg), &msg)) {
	pending = FALSE;
      }
    }
    sendSpeedPending = NO_SPEED;
  }

 
  /** Called by <CODE> SendMsg.sendDone() </CODE> right after it sends
   *  a message changing the direction of the robot.  We need to
   *  increase the speed setting for the motor in reverse because the
   *  motor is weaker in reverse.
   */
  task void sendReverseSpeed() {
    RobotCmdMsg* message = (RobotCmdMsg *) msg.data;

    if (!pending) {
      pending = TRUE;

      message->type = SET_SPEED;
      message->data[0] = 2*DEMO_SPEED;

      if (!call SendMsg.send(TOS_BCAST_ADDR, sizeof(RobotCmdMsg), &msg)) {
	pending = FALSE;
      }
    }
    sendSpeedPending = NO_SPEED;
  }


  /** Will post the task <CODE> setForwardSpeed() </CODE> or the task
   *  <CODE> setReverseSpeed() </CODE> depending on the flag
   *  <CODE> sendSpeedPending </CODE>. 
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr m, bool success) {
    pending = FALSE;
    if (success && sendSpeedPending == REVERSE_SPEED) {
      post sendReverseSpeed();
    } else if (success && sendSpeedPending == FORWARD_SPEED) {
      post sendForwardSpeed();
    }
    return SUCCESS;
  }
  
} // end of implementation

