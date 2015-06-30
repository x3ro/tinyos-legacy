/*									tab:4
 *
 *
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
/** 
 *
 *	QueuedASend Test Application
 *
 *	A trivial application to demonstrate the use of
 *      QueuedASend. Note, since there is no MultiHop
 *	component in the configuration, QueuedASend will 
 *	simply broadcast the messages sent.	
 *
 *	Alternatively, QueuedASend may be wired to a
 *	MultiHop component.
 *
 * Author:	Barbara Hohlt
 * Project:	QueuedASend	
 *
 **/
includes AM;
includes CQ;
includes SingleHop;

configuration TestQASend {

}	
implementation
{
  components Main, GenericComm, TestQASendM, QueuedASendC, SimpleTime;

  Main.StdControl -> TestQASendM.Control;
  Main.StdControl -> GenericComm.Control;
  Main.StdControl -> QueuedASendC.StdControl;
  Main.StdControl -> SimpleTime.StdControl;

  TestQASendM.Send -> QueuedASendC.AllocSend[AM_MULTIHOPMSG];
  QueuedASendC.SendMsg ->GenericComm.SendMsg;
  TestQASendM.Timer0 -> SimpleTime.Timer[unique("Timer")];

}
