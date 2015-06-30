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
/*
 *
 *	Buffer Management and QueuedASend 
 *
 * Author:	Barbara Hohlt
 * Project:   	Buffer Manager, QueuedASend
 *
 * This component illustrates how to use buffer management
 * and forwarding queuing using QueuedASend. 
 *
 */

includes MultiHop;

configuration MultiHopC {
  provides {
    interface StdControl;
    interface AllocSend[uint8_t id];
    interface ActiveNotify;
    interface Receive[uint8_t id];
    interface RouteControl;
  }
    uses interface ReceiveMsg[uint8_t id];
}

implementation
{
  
  components GenericComm, SchedulePolicyC, MultiHopEngineM ;
  components RouteSelectDummy as MultiHopRouteSelect;
  components SwapListC, QueuedASendC;

  StdControl = MultiHopEngineM;
  Receive = MultiHopEngineM;
  AllocSend = QueuedASendC;
  RouteControl = MultiHopEngineM;
  ActiveNotify = SchedulePolicyC;

  ReceiveMsg = MultiHopEngineM;
  

  MultiHopEngineM.SubControl -> QueuedASendC.StdControl;
  MultiHopEngineM.SubControl -> MultiHopRouteSelect.Control;
  MultiHopEngineM.SubControl -> GenericComm.Control;
  MultiHopEngineM.RouteSelectCntl -> MultiHopRouteSelect.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopRouteSelect.RouteSelect;
  MultiHopEngineM.SubControl -> SchedulePolicyC.Control;
  MultiHopEngineM.SubControl -> SwapListC.Control;
  MultiHopEngineM.FreeList -> SwapListC.FreeList;
  
  QueuedASendC.RouteSelect -> MultiHopRouteSelect.RouteSelect;
  QueuedASendC.SendMsg -> GenericComm.SendMsg;
  MultiHopEngineM.SendMsgQ -> QueuedASendC.SendMsgR;

//  MultiHopEngineM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_MULTIHOPMSG];

}
