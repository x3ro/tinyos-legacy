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
 *	MultiHop QueuedASend Test Application
 *
 *	A trivial application to demonstrate the use of
 *      QueuedASend for buffer management and forward queueing
 *	in the MultiHopC component.	
 *
 *
 * Author:	Barbara Hohlt
 * Project:	MultiHop QueuedASend	
 *
 **/
includes AM;
includes CQ;
includes MultiHop;

configuration TestMHQASend {

}	
implementation
{
  components Main, TestMHQASendM, MultiHopC, GenericComm;

  Main.StdControl -> TestMHQASendM.Control;
  Main.StdControl -> MultiHopC.StdControl;


  TestMHQASendM.ActiveNotify -> MultiHopC.ActiveNotify;
  TestMHQASendM.Receive -> MultiHopC.Receive[AM_MULTIHOPMSG];

  TestMHQASendM.Send -> MultiHopC.AllocSend[AM_MULTIHOPMSG];
  MultiHopC.ReceiveMsg[AM_MULTIHOPMSG] -> GenericComm.ReceiveMsg[AM_MULTIHOPMSG];

}

