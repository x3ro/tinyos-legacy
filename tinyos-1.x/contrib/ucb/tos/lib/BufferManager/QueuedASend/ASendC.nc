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
 * This component manages a free list of buffers using 
 * AllocSend. It also receives messages from the routing layer.
 * Both application and routing layer messages are then sent 
 * to a send queue.
 *
 *		ASenC with FreeList
 *
 * Author:	Barbara Hohlt
 * Project:   	FPS, SchedRoute, QueuedASend	
 *
 *
 * @author  Barbara Hohlt
 * @date    March 2005
 */


configuration ASendC {
  provides interface StdControl as Control;
  provides interface AllocSend[uint8_t id];
  provides interface SendMsg as SendMsgR[uint8_t id];
  uses interface SendMsg as SendMsgQ; 
  uses interface RouteSelect;
}

implementation
{
  
  components ASendM, FreeAListC; 

  Control = ASendM.Control;
  AllocSend = ASendM.AllocSend;
  SendMsgR = ASendM.SendMsgR;
  SendMsgQ = ASendM.SendMsgQ;
  RouteSelect = ASendM.RouteSelect;

  ASendM.SubControl -> FreeAListC.Control;
  ASendM.FreeList -> FreeAListC.FreeList;
}
