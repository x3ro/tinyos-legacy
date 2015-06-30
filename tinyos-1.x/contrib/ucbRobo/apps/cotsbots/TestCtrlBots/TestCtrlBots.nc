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
// $Id: TestCtrlBots.nc,v 1.1.1.1 2004/10/15 01:34:08 phoebusc Exp $
/**
 * TestCtrlBots is an application to allow a mote to broadcast a
 * stream of messages to drive a COTSBOT back and forth.  This is for
 * testing the radio communication on a COTSBOT without RobotCmdGUI.
 * 
 * @author Phoebus Chen
 * @modified 7/22/2004 First Implementation
 **/

includes RobotCmdMsg;

configuration TestCtrlBots { 
}

implementation {
  components Main, TestCtrlBotsM, GenericComm as Comm, TimerC, LedsC;

  Main.StdControl -> TestCtrlBotsM;
  Main.StdControl -> Comm.Control;
  Main.StdControl -> TimerC;

  TestCtrlBotsM.Leds -> LedsC;

  TestCtrlBotsM.SendMsg -> Comm.SendMsg[AM_ROBOTCMDMSG];

  TestCtrlBotsM.MsgTimer -> TimerC.Timer[unique("Timer")];

} // end of implementation
