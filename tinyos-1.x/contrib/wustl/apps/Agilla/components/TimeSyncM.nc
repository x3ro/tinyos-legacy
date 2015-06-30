// $Id: TimeSyncM.nc,v 1.5 2006/05/18 19:58:40 chien-liang Exp $

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

includes TimeSync;

/**
 * Wires up all of the components used for synchronizing the time.
 *
 * @author Chien-Liang Fok
 */
module TimeSyncM
{
  provides interface StdControl;  
  uses 
  {
    interface AddressMgrI;
    interface Time;
    interface TimeSet;
    interface MessageBufferI;
    interface Timer;
    interface SendMsg as SendTime;
    interface ReceiveMsg as ReceiveTime;
    interface Leds;
  }
}
implementation 
{
  
  command result_t StdControl.init() 
  {
    tos_time_t t;
    t.high32 = 0;
    t.low32 = 0;
    call TimeSet.set(t);
    call Leds.init();  // reset time to be 0
    return SUCCESS;
  }
  
  command result_t StdControl.start() 
  {
    call Timer.start(TIMER_REPEAT, 1024*10);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() 
  {
    return SUCCESS;
  }
  
  /**
   * Send the time to the base station.
   */
  task void sendTime() 
  {
    TOS_MsgPtr msg = call MessageBufferI.getMsg();
    if (msg != NULL)
    {
      AgillaTimeSyncMsg* timeMsg = (AgillaTimeSyncMsg *)msg->data;
      timeMsg->time = call Time.get();
      
      if (!call SendTime.send(TOS_UART_ADDR, sizeof(AgillaTimeSyncMsg), msg))
      {
        call MessageBufferI.freeMsg(msg);
      }
    }
  }
  
  event result_t Timer.fired()
  {
    if (call AddressMgrI.isGW())
    {
      #if DEBUG_TIMESYNC
        dbg(DBG_USR1, "TimeSyncM: Timer.fired(): Sending time sync message\n");    
      #endif    
      post sendTime();      
    } else
    {
      #if DEBUG_TIMESYNC
        dbg(DBG_USR1, "TimeSyncM: Timer.fired(): NOT sending time sync message\n");    
      #endif        
    }
    return SUCCESS;
  }
  
  event TOS_MsgPtr ReceiveTime.receive(TOS_MsgPtr m)
  {
    AgillaTimeSyncMsg* timeMsg = (AgillaTimeSyncMsg *)m->data;
    call TimeSet.set(timeMsg->time);
    //call Leds.yellowToggle();
    return m;
  }
  
  event result_t SendTime.sendDone(TOS_MsgPtr m, result_t success)
  {
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }
}
