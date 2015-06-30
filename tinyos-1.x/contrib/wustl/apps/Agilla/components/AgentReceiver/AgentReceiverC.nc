// $Id: AgentReceiverC.nc,v 1.7 2006/05/18 19:58:40 chien-liang Exp $

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

includes AM;
includes Agilla;
includes MigrationMsgs;

/**
 * Wires up all of the components used for receiving
 * an agent.
 *
 * @author Chien-Liang Fok
 * @version 1.3
 */
configuration AgentReceiverC {
  provides {
    interface StdControl;
    interface AgentReceiverI;    
  }
}
implementation {
  components ReceiverCoordinatorM;
  components ReceiveStateM, ReceiveCodeM, ReceiveHeapM;
  components ReceiveOpStackM, ReceiveRxnM;
  components MessageBufferM;
  components AgentMgrC, CodeMgrC, HeapMgrC, OpStackC, RxnMgrProxy;
  components TimerC, NetworkInterfaceProxy as Comm;
  
  components LedsC; // debug

  AgentReceiverI = ReceiverCoordinatorM;
  StdControl = ReceiverCoordinatorM;
  StdControl = TimerC;
  StdControl = MessageBufferM;
  
  // Wire up the MessageBufferI interface
  ReceiveStateM.MessageBufferI -> MessageBufferM;
  ReceiveCodeM.MessageBufferI -> MessageBufferM;
  ReceiveOpStackM.MessageBufferI -> MessageBufferM;
  ReceiveHeapM.MessageBufferI -> MessageBufferM;
  ReceiveRxnM.MessageBufferI -> MessageBufferM;
  
  ReceiverCoordinatorM.AgentMgrI -> AgentMgrC;
  ReceiverCoordinatorM.RecvTimeout0 -> TimerC.Timer[unique("Timer")];
  ReceiverCoordinatorM.RecvTimeout1 -> TimerC.Timer[unique("Timer")];
  ReceiverCoordinatorM.RecvTimeout2 -> TimerC.Timer[unique("Timer")];  
  ReceiverCoordinatorM.Leds -> LedsC;

  ReceiveStateM.CoordinatorI -> ReceiverCoordinatorM;
  ReceiveStateM.AgentMgrI -> AgentMgrC;
  ReceiveStateM.Rcv_State -> Comm.ReceiveMsg[AM_AGILLASTATEMSG];
  ReceiveStateM.Send_State_Ack -> Comm.SendMsg[AM_AGILLAACKSTATEMSG];
  ReceiveStateM.Leds -> LedsC;
  
  ReceiveCodeM.CoordinatorI -> ReceiverCoordinatorM;  
  ReceiveCodeM.CodeMgrI -> CodeMgrC;
  ReceiveCodeM.Rcv_Code -> Comm.ReceiveMsg[AM_AGILLACODEMSG];
  ReceiveCodeM.Send_Code_Ack -> Comm.SendMsg[AM_AGILLAACKCODEMSG];

  ReceiveHeapM.CoordinatorI -> ReceiverCoordinatorM;
  ReceiveHeapM.HeapMgrI -> HeapMgrC;
  ReceiveHeapM.Rcv_Heap -> Comm.ReceiveMsg[AM_AGILLAHEAPMSG];
  ReceiveHeapM.Send_Heap_Ack -> Comm.SendMsg[AM_AGILLAACKHEAPMSG];
  
  ReceiveOpStackM.CoordinatorI -> ReceiverCoordinatorM;  
  ReceiveOpStackM.OpStackI -> OpStackC;
  ReceiveOpStackM.Rcv_OpStack -> Comm.ReceiveMsg[AM_AGILLAOPSTACKMSG];
  ReceiveOpStackM.Send_OpStack_Ack -> Comm.SendMsg[AM_AGILLAACKOPSTACKMSG];
  
  ReceiveRxnM.CoordinatorI -> ReceiverCoordinatorM;
  ReceiveRxnM.RxnMgrI -> RxnMgrProxy;
  ReceiveRxnM.Rcv_Rxn -> Comm.ReceiveMsg[AM_AGILLARXNMSG];
  ReceiveRxnM.Send_Rxn_Ack -> Comm.SendMsg[AM_AGILLAACKRXNMSG];  
}
