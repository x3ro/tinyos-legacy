/*
 * Copyright (c) 2009 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @author Ricardo Simon Carbajo <carbajor {tcd.ie}>
 * @date   February 13 2009 
 * Computer Science
 * Trinity College Dublin
 */

 
/****************************************************************/
/* TinyHop:														*/
/* An end-to-end on-demand reliable ad hoc routing protocol		*/
/* for Wireless Sensor Networks intended for P2P communication	*/
/* See: http://portal.acm.org/citation.cfm?id=1435467.1435469   */
/*--------------------------------------------------------------*/
/* This version has been tested with TinyOS 2.1.0 and 2.1.1     */
/****************************************************************/


#include "AM.h"
#include "TinyHop.h"

configuration TinyHop {
  
  provides {
    interface SplitControl as RadioControl;
    interface Receive;
	interface AMSend as Send;
    interface Receive as Snoop;
    interface AMPacket;
  }

}

implementation {

  components HoppingEngineM, MainC, ActiveMessageC, LedsC, RandomC,
			 new AMSenderC(AM_TOS_HOPPINGMSG), 
			 new AMReceiverC(AM_TOS_HOPPINGMSG),
			 new AMSnooperC(AM_TOS_HOPPINGMSG);

  RadioControl = HoppingEngineM.SplitControl;
  Receive = HoppingEngineM.Receive;
  Send = HoppingEngineM.Send;
  Snoop = HoppingEngineM.Snoop;
  AMPacket = AMSenderC.AMPacket;

  MainC.SoftwareInit -> HoppingEngineM;
  HoppingEngineM.RadioControl -> ActiveMessageC;
  HoppingEngineM.Leds  -> LedsC;  
  HoppingEngineM.SendMsg -> AMSenderC.AMSend;
  HoppingEngineM.ReceiveMsg -> AMReceiverC.Receive; 
  HoppingEngineM.SnoopMsg -> AMSnooperC; 

  HoppingEngineM.Packet -> AMSenderC.Packet; 
  HoppingEngineM.AMPacket -> AMSenderC.AMPacket; 

  HoppingEngineM.Random -> RandomC;

  components new QueueC(message_t, SEND_QUEUE_SIZE) as SendQueueP;
  HoppingEngineM.SendQueue -> SendQueueP;

  components new QueueC(message_t, ACK_QUEUE_SIZE) as AckQueueP;
  HoppingEngineM.AckQueue -> AckQueueP;

  components new QueueC(message_t, ACK_NEW_QUEUE_SIZE) as AckNewQueueP;
  HoppingEngineM.AckNewQueue -> AckNewQueueP;

  components new TimerMilliC() as RetxmitTimerP;
  HoppingEngineM.RetxmitTimer -> RetxmitTimerP;

  components new TimerMilliC() as RetxmitTimerAckNewP;
  HoppingEngineM.RetxmitTimerAckNew -> RetxmitTimerAckNewP;

  components new TimerMilliC() as RetxmitTimerDiscoverAckRouteP;
  HoppingEngineM.RetxmitTimerDiscoverAckRoute -> RetxmitTimerDiscoverAckRouteP;

  components new TimerMilliC() as WaitingToPostTaskP;
  HoppingEngineM.WaitingToPostTask -> WaitingToPostTaskP;

  #if defined(REAL_DEPLOYMENT)		
    //Component and Interface used to assign Transmission Power to each message
    components CC2420PacketC;
    HoppingEngineM.CC2420Packet -> CC2420PacketC.CC2420Packet;
  #endif
}


