// $Id: AgentSenderC.nc,v 1.6 2006/05/18 19:58:40 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.  
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */

includes Agilla;
includes MigrationMsgs;

/**
 * Wires up all of the components used for sending
 * an agent to a remote node.
 *
 * @author Chien-Liang Fok
 */
configuration AgentSenderC {
  provides {
    interface AgentSenderI;
    interface StdControl;
  }
}

implementation {
  components SenderCoordinatorM;
  components SendStateM, SendCodeM, SendOpStackM, SendHeapM, SendRxnM;
  components TimerC, NetworkInterfaceProxy as Comm;
  components QueueProxy, ErrorMgrProxy, MessageBufferM;
  components CodeMgrC, HeapMgrC, OpStackC, RxnMgrProxy;
  components LedsC;
  components NoLeds;
  //components NeighborListProxy;
  
  AgentSenderI = SenderCoordinatorM;
  StdControl = SenderCoordinatorM;
 
  StdControl = SendStateM;
  StdControl = SendCodeM;
  StdControl = SendOpStackM;
  StdControl = SendHeapM;
  StdControl = SendRxnM;
  StdControl = MessageBufferM;
  
  StdControl = TimerC;
  StdControl = RxnMgrProxy;
  //StdControl = NeighborListProxy;
  
  SenderCoordinatorM.SendState   -> SendStateM;
  SenderCoordinatorM.SendCode    -> SendCodeM;
  SenderCoordinatorM.SendOpStack -> SendOpStackM;
  SenderCoordinatorM.SendHeap    -> SendHeapM;
  SenderCoordinatorM.SendRxn     -> SendRxnM;

  SenderCoordinatorM.Retry_Timer -> TimerC.Timer[unique("Timer")];
  
  SenderCoordinatorM.HeapMgrI -> HeapMgrC;
  SenderCoordinatorM.OpStackI -> OpStackC;
  SenderCoordinatorM.RxnMgrI -> RxnMgrProxy;
  SenderCoordinatorM.ErrorMgrI -> ErrorMgrProxy;
  
  // Wire up the Leds interface;
  SenderCoordinatorM.Leds -> NoLeds;
  SendCodeM.Leds -> LedsC;
 
  // Wire up the MessageBufferI interface
  SendStateM.MessageBufferI -> MessageBufferM;
  SendCodeM.MessageBufferI -> MessageBufferM;
  SendOpStackM.MessageBufferI -> MessageBufferM;
  SendHeapM.MessageBufferI -> MessageBufferM;
  SendRxnM.MessageBufferI -> MessageBufferM;  

  // Wire up the Send message interfaces
  SendStateM.Send_State     -> Comm.SendMsg[AM_AGILLASTATEMSG];  
  SendCodeM.Send_Code       -> Comm.SendMsg[AM_AGILLACODEMSG];
  SendOpStackM.Send_OpStack -> Comm.SendMsg[AM_AGILLAOPSTACKMSG];
  SendHeapM.Send_Heap       -> Comm.SendMsg[AM_AGILLAHEAPMSG];
  SendRxnM.Send_Rxn         -> Comm.SendMsg[AM_AGILLARXNMSG];

  // Wire up the ReceiveMsg interfaces
  SendStateM.Rcv_Ack   -> Comm.ReceiveMsg[AM_AGILLAACKSTATEMSG];
  SendCodeM.Rcv_Ack    -> Comm.ReceiveMsg[AM_AGILLAACKCODEMSG];
  SendOpStackM.Rcv_Ack -> Comm.ReceiveMsg[AM_AGILLAACKOPSTACKMSG];
  SendHeapM.Rcv_Ack    -> Comm.ReceiveMsg[AM_AGILLAACKHEAPMSG];
  SendRxnM.Rcv_Ack     -> Comm.ReceiveMsg[AM_AGILLAACKRXNMSG];

  // Wire up the Ack Timer interfaces  

  SendStateM.Ack_Timer   -> TimerC.Timer[SEND_ACK_TIMER];
  SendCodeM.Ack_Timer    -> TimerC.Timer[SEND_ACK_TIMER];
  SendOpStackM.Ack_Timer -> TimerC.Timer[SEND_ACK_TIMER];
  SendHeapM.Ack_Timer    -> TimerC.Timer[SEND_ACK_TIMER];
  SendRxnM.Ack_Timer     -> TimerC.Timer[SEND_ACK_TIMER];
  
  /*SendStateM.Ack_Timer   -> TimerC.Timer[unique("Timer")];
  SendCodeM.Ack_Timer    -> TimerC.Timer[unique("Timer")];
  SendOpStackM.Ack_Timer -> TimerC.Timer[unique("Timer")];
  SendHeapM.Ack_Timer    -> TimerC.Timer[unique("Timer")];
  SendRxnM.Ack_Timer     -> TimerC.Timer[unique("Timer")];*/

  
  // Wire up the Error interfaces
  SendStateM.Error   -> ErrorMgrProxy;
  SendCodeM.Error    -> ErrorMgrProxy;
  SendOpStackM.Error -> ErrorMgrProxy;
  SendHeapM.Error    -> ErrorMgrProxy;
  SendRxnM.Error     -> ErrorMgrProxy;

  // Component-specific interfaces
  SendStateM.HeapMgrI -> HeapMgrC;
  SendStateM.RxnMgrI  -> RxnMgrProxy;  
  SendStateM.Leds -> LedsC;  
  
  SendCodeM.CodeMgrI -> CodeMgrC;
  SendHeapM.HeapMgrI -> HeapMgrC;
  
  SendOpStackM.OpStackI -> OpStackC;
  
  SendRxnM.RxnMgrI -> RxnMgrProxy;
}
