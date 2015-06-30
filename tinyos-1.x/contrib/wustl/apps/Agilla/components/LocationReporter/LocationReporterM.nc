// $Id: LocationReporterM.nc,v 1.15 2006/05/26 02:58:20 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2006, Washington University in Saint Louis
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
  * Sends the location of an agent.
  *
  * @author Sangeeta Bhattacharya
  * @author Chien-Liang Fok
  */
 module LocationReporterM
 {
   provides
   {
     interface StdControl;
     interface LocationReporterI;
   }
   uses
   {
     interface Time;
     interface AgentMgrI;
     interface LocationMgrI;
     interface NeighborListI;
     interface AddressMgrI;
     interface MessageBufferI;
     interface AgentReceiverI;

     //interface LocationSenderI as SendLocation;
     interface SendMsg as SendLocation;
     interface ReceiveMsg as ReceiveLocation;

     #if ENABLE_EXP_LOGGING
      interface ExpLoggerI;
     #endif

     interface Leds;
   }
}
implementation
{

  /**************************************************************/
  /*                    Variable declarations                   */
  /**************************************************************/

  uint16_t _serial;

  /**************************************************************/
  /*                     StdControl                             */
  /**************************************************************/

  command result_t StdControl.init()
  {
    _serial=0;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }


  /**************************************************************/
  /*                        Helper methods                     */
  /**************************************************************/


  /**
   * Figures out what the next hop should be towards the base station and
   * sends the message to that node.  If this node is the gateway, the message
   * is forwarded to the UART.
   *
   * If clustering is used, then msg is sent to clusterhead, if this node is
   * not a cluster head. If this node is a clusterhead, msg is sent to GW
   *
   * "bounce" determines if the msg should be just forwarded to the GW.
   */
  inline result_t sendMsg(TOS_MsgPtr msg, bool bounce)
  {

    if (call AddressMgrI.isGW())
    {
      #if DEBUG_LOCATION_DIRECTORY
        dbg(DBG_USR1, "LocationReporterM: sendMsg(): Sent agent location to BS\n");
      #endif

      #if ENABLE_EXP_LOGGING
        if(TRUE)
        {
          struct AgillaLocMsg *sMsg = (struct AgillaLocMsg *)msg->data;
          call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_LOCAL_ADDRESS, 
            SENDING_AGENT_LOCATION, sMsg->seq, sMsg->dest, sMsg->loc);
        }
      #endif
      
      return call SendLocation.send(TOS_UART_ADDR, sizeof(AgillaLocMsg), msg);
    } else
    {
      uint16_t onehop_dest;      
      
      #if ENABLE_EXP_LOGGING
        struct AgillaLocMsg *sMsg = (struct AgillaLocMsg *)msg->data;
      #endif

      // Get the one-hop neighbor that is closest to the gateway.
      // If there is no known gateway, abort.
      if (call NeighborListI.getGW(&onehop_dest) == NO_GW)
      {
        dbg(DBG_USR1, "LocationReporterM: sendMsg(): ERROR: No neighbor closer to a gateway.\n");
        return FAIL;
      }

      #if ENABLE_EXP_LOGGING        
        call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_LOCAL_ADDRESS, SENDING_AGENT_LOCATION, sMsg->seq, sMsg->dest, sMsg->loc);        
      #endif

      return call SendLocation.send(onehop_dest, sizeof(AgillaLocMsg), msg);
    }
  } // sendMsg()


  /**
   * Sends a location update message.
   */
  inline void doSend(AgillaAgentID* aID, bool died)
  {
    AgillaAgentContext* context = call AgentMgrI.getContext(aID);
    TOS_MsgPtr msg = call MessageBufferI.getMsg();

    if (msg != NULL && context != NULL)
    {
      struct AgillaLocMsg *sMsg = (struct AgillaLocMsg *)msg->data;

      // fill the location update message
      sMsg->agent_id = context->id;
      sMsg->agent_type = context->desc.value;
      sMsg->seq = _serial++;
      sMsg->dest = TOS_UART_ADDR;
      sMsg->src = TOS_LOCAL_ADDRESS;
      if (!died)
      {
        call LocationMgrI.getLocation(TOS_LOCAL_ADDRESS, &(sMsg->loc));
        sMsg->timestamp = call Time.get();
      } else
      {
        // An AgillaLocMsg with the src, loc, and timestamp all
        // set to 0 indicates that the agent has died.
        //sMsg->src = 0;
        sMsg->loc.x = 0;
        sMsg->loc.y = 0;
        sMsg->timestamp.high32 = 0;
        sMsg->timestamp.low32 = 0;
        //sMsg->dest = 0;
      }
      if (!sendMsg(msg, FALSE))
        call MessageBufferI.freeMsg(msg);
    }
  } // doSend()



  /**************************************************************/
  /*                  Command and event handlers                */
  /**************************************************************/

  /**
   * This event is signaled whenever a new agent has arrived.
   *
   * @param context The context of the agent that just arrived.
   */
  event void AgentReceiverI.receivedAgent(AgillaAgentContext* context, uint16_t dest) {
    if (dest == TOS_LOCAL_ADDRESS) call LocationReporterI.updateLocation(context);
  }

  /**
   * Called when a location update message should be sent.
   *
   * @param context The agent whose location is being updated.
   */
  command result_t LocationReporterI.updateLocation(AgillaAgentContext* context)
  {
    #if DEBUG_LOCATION_DIRECTORY || DEBUG_CLUSTERING
      dbg(DBG_USR1, "LocationReporterM: receivedAgent(): Sending location update for agent %i...\n", context->id.id);
    #endif
    doSend(&context->id, FALSE);
    return SUCCESS;
  } // LocationReporterI.updateLocation()

  command result_t LocationReporterI.agentDied(AgillaAgentID* aid)
  {
    doSend(aid, TRUE);
    return SUCCESS;
  }

  command result_t LocationReporterI.agentChangedDesc(AgillaAgentID* aid)
  {
    doSend(aid, FALSE);
    return SUCCESS;
  }
  
  /**
   * Bounces a location update message off this node.    
   */
  event TOS_MsgPtr ReceiveLocation.receive(TOS_MsgPtr m) {
    TOS_MsgPtr msg = call MessageBufferI.getMsg();    
    if (msg != NULL) {
      *msg = *m;
      if (!sendMsg(msg, TRUE)) call MessageBufferI.freeMsg(msg);
    }
    return m;
  }

  event result_t SendLocation.sendDone(TOS_MsgPtr m, result_t success)
  {
    #if ENABLE_EXP_LOGGING
      if(success)
      {
        struct AgillaLocMsg *sMsg = (struct AgillaLocMsg *)m->data;
        call ExpLoggerI.sendTraceQid(sMsg->agent_id.id, TOS_LOCAL_ADDRESS, AGENT_LOCATION_SENT, sMsg->seq, sMsg->dest, sMsg->loc);
      }
    #endif
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }


}
