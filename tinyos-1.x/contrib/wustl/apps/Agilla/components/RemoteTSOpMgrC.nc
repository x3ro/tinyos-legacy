// $Id: RemoteTSOpMgrC.nc,v 1.6 2006/05/18 19:58:40 chien-liang Exp $

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

/**
 * Handles remote tuple space requests.
 *
 * @author Chien-Liang Fok
 */
configuration RemoteTSOpMgrC {
  provides interface RemoteTSOpMgrI;
}
implementation {
  components Main, RemoteTSOpMgrM;
  components NetworkInterfaceProxy as Comm, TupleUtilC, TupleSpaceProxy;
  components TimerC, RandomLFSR, NeighborListProxy, AddressMgrC;
  components ErrorMgrProxy, MessageBufferM;
  components LocationMgrC;
  components LedsC;
  

  Main.StdControl -> RemoteTSOpMgrM;
  Main.StdControl -> TupleSpaceProxy;
  Main.StdControl -> MessageBufferM;
  Main.StdControl -> TimerC;
  
  RemoteTSOpMgrI = RemoteTSOpMgrM;
  
  RemoteTSOpMgrM.Rcv_Req -> Comm.ReceiveMsg[AM_AGILLATSREQMSG];
  RemoteTSOpMgrM.Rcv_Res -> Comm.ReceiveMsg[AM_AGILLATSRESMSG];
  RemoteTSOpMgrM.Rcv_GRes -> Comm.ReceiveMsg[AM_AGILLATSGRESMSG];
  
  RemoteTSOpMgrM.Send_Req -> Comm.SendMsg[AM_AGILLATSREQMSG];    // for forwarding to BS
  RemoteTSOpMgrM.Send_Res -> Comm.SendMsg[AM_AGILLATSRESMSG];
  RemoteTSOpMgrM.Send_GRes -> Comm.SendMsg[AM_AGILLATSGRESMSG];
  
  RemoteTSOpMgrM.Timeout -> TimerC.Timer[unique("Timer")];  
  
  RemoteTSOpMgrM.BackoffTimer -> TimerC.Timer[unique("Timer")];
  RemoteTSOpMgrM.Random -> RandomLFSR;
  
  RemoteTSOpMgrM.AddressMgrI-> AddressMgrC;  
  RemoteTSOpMgrM.NeighborListI -> NeighborListProxy;
  RemoteTSOpMgrM.TupleSpaceI -> TupleSpaceProxy;
  RemoteTSOpMgrM.TupleUtilI -> TupleUtilC;  
  RemoteTSOpMgrM.ErrorMgrI -> ErrorMgrProxy;  
  RemoteTSOpMgrM.MessageBufferI -> MessageBufferM;
  RemoteTSOpMgrM.LocationMgrI -> LocationMgrC;
  
  RemoteTSOpMgrM.Leds -> LedsC;
}
