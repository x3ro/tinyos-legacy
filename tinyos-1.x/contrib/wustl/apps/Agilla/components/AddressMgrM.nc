// $Id: AddressMgrM.nc,v 1.11 2006/05/18 19:58:40 chien-liang Exp $

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

/**
 * Manages address information, e.g., determines if a mote is a base
 * station and what the mote's original address is.
 *
 * @author Chien-Liang Fok <liangfok@wustl.edu>
 */
module AddressMgrM {
  provides {
    interface StdControl;
    interface AddressMgrI;
  }
  uses {
    interface ReceiveMsg as ReceiveSetBSMsg;
    interface Timer as BSTimer; // for base station heartbeat
    
    interface ReceiveMsg as ReceiveAddress;
    interface SendMsg as SendAddress;
    interface ReceiveMsg as ReceiveAddressAck;
    interface SendMsg as SendAddressAck;
    
    interface LEDBlinkerI;
  }
}

// This is the period of the base station timer.  If a heartbeat
// is not received in two periods, the mote assumes it is no longer
// the base station.
#define BS_TIMEOUT 7000

implementation {  
  /**
   * Remembers the original address of this node.
   */
  uint16_t origAddr;
  
  /**
   * Whether this node is a base station.
   */
  bool isGW;
  
  /**
   * A message buffer for sending address acknowledgements.
   */
  TOS_Msg msg;
  
  /**
   * Whether this mote has received a base station heartbeat.
   */
  bool recvBS;
  
  command result_t StdControl.init() 
  {
    origAddr = TOS_LOCAL_ADDRESS;
    recvBS = isGW = FALSE;     
    return SUCCESS;
  }
  
  command result_t StdControl.start() 
  {
    call BSTimer.start(TIMER_REPEAT, BS_TIMEOUT);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() 
  {
    return SUCCESS;
  }
  
  /**
   * Checks whether this mote has received a base station heartbeat
   * in the past BSTimer period.  If not, set this mote to be a 
   * non-basestation.
   */
  event result_t BSTimer.fired() 
  {
    if (recvBS)
      recvBS = FALSE;
    else if (isGW) 
    {
      #if DEBUG_ADDRESS_MGR
        dbg(DBG_USR1, "AddressMgrM: isGW = FALSE.\n");
      #endif
      isGW = FALSE;
    }    
    return SUCCESS;
  }
  
  /**
   * Returns TRUE if this mote is a base station.  In TOSSIM,
   * the base station is always mote 0.  Since TOSSIM is not 
   * real-time, the mote 0 is hard-coded to be the base station
   * when running in simulation mode.
   */
  command result_t AddressMgrI.isGW() 
  {
//    #ifdef PACKET_SIM_H_INCLUDED
//      return TOS_LOCAL_ADDRESS == 0;
//    #else  
      return isGW;
//    #endif
  }
  
  /**
   * Returns TRUE if the specified address is the one
   * that this mote was programmed as.
   */  
  command result_t AddressMgrI.isOrigAddress(uint16_t addr) {
    return addr == origAddr;
  }
  
  /**
   * The base station periodically sends the gateway mote a heartbeat
   * informing it that it is a gateway.
   */
  event TOS_MsgPtr ReceiveSetBSMsg.receive(TOS_MsgPtr m) {  
    isGW = TRUE;
    recvBS = TRUE; 
    #if DEBUG_ADDRESS_MGR
      dbg(DBG_USR1, "AddressMgrM: isGW = TRUE.\n");
    #endif    
    return m;
  }
  
  /**
   * This method allows a user to change the address of a mote.
   */
  event TOS_MsgPtr ReceiveAddress.receive(TOS_MsgPtr m) {
    AgillaAddressMsg* addrMsg = (AgillaAddressMsg*)m->data;

    // If the address change message is destined for me, change my address
    if (addrMsg->oldAddr == origAddr) {      
      AgillaAddressAckMsg* addrAckMsg = (AgillaAddressAckMsg*)msg.data;
      addrAckMsg->success = 1;
      addrAckMsg->oldAddr = origAddr;
      addrAckMsg->newAddr = addrMsg->newAddr;
      
      #if DEBUG_ADDRESS_MGR
        dbg(DBG_USR1, "AddressMgrM: Changing address of mote %i to %i.\n", 
          TOS_LOCAL_ADDRESS, addrMsg->newAddr);
      #endif
      
      atomic {
        TOS_LOCAL_ADDRESS = addrMsg->newAddr;
      }
            
      // Send an acknowledgement
      if (isGW)
        call SendAddressAck.send(TOS_UART_ADDR, sizeof(AgillaAddressAckMsg), &msg);
      else
        call SendAddressAck.send(TOS_BCAST_ADDR, sizeof(AgillaAddressAckMsg), &msg);
      
      // Blink the LEDs to acknowledge the change in address
      call LEDBlinkerI.blink((uint8_t)GREEN|YELLOW, 3, 128);
    }
    
    // Otherwise, if I am the base station, send it to the appropriate mote
    // (This assumes all motes are in reality a single hop away)
    else if (addrMsg->fromPC && isGW) { 
      addrMsg->fromPC = 0;
      msg = *m;      
      call SendAddress.send(TOS_BCAST_ADDR, sizeof(AgillaAddressMsg), &msg);            
    }
    
    return m;
  }  
  
  /**
   * Signalled when the blinking is done and blink(...) can be called again.
   */
  event result_t LEDBlinkerI.blinkDone() {  
    return SUCCESS;
  }    

  /**
   * Relays the address ack message over the UART if this node is a base station.
   */
  event TOS_MsgPtr ReceiveAddressAck.receive(TOS_MsgPtr m) {
    if (isGW) {
      msg = *m;
      call SendAddressAck.send(TOS_UART_ADDR, sizeof(AgillaAddressAckMsg), &msg);
    }
    return m;
  }    

  event result_t SendAddressAck.sendDone(TOS_MsgPtr m, result_t success) {
    return SUCCESS;
  }   

  event result_t SendAddress.sendDone(TOS_MsgPtr m, result_t success) {
    return SUCCESS;
  }       
}
