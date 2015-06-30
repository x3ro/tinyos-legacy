/*			
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
 * This component implements a SendQueue in conjunction 
 * with buffer management provided by AllocSend.
 *
 *		QueuedASendC	
 *
 * Author:	Barbara Hohlt
 * Project:   	FPS, SchedRoute, QueuedASend	
 *
 * @author  Barbara Hohlt
 * @date    March 2005
 *
 */


configuration QueuedASendC {
  provides interface StdControl;
  provides interface QueuePolicy;
  provides interface AllocSend[uint8_t id];
  provides interface SendMsg as SendMsgR[uint8_t id];
  uses interface SendMsg[uint8_t id];
  uses interface RouteSelect;
}

implementation
{
  
  components QueuedASendM, SendQueueC ; 
  components LedsC; 
  components ASendC;

  StdControl = QueuedASendM.Control;
  QueuePolicy = QueuedASendM;
  AllocSend = ASendC.AllocSend;
  SendMsgR = ASendC.SendMsgR;
  SendMsg = QueuedASendM.SendMsg;
  RouteSelect = ASendC.RouteSelect;

  QueuedASendM.SubControl -> SendQueueC.Control;
  QueuedASendM.SubControl -> ASendC.Control;
  QueuedASendM.SendQueue -> SendQueueC;

  QueuedASendM.Leds -> LedsC; 

  ASendC.SendMsgQ -> QueuedASendM.SendMsgQ; 

}
