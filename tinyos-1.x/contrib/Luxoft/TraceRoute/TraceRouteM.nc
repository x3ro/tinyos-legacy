/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Dmitriy Korovkin
 *           LUXOFT Inc.
 * Date:     9/15/2003
 *
 */
/*
 * Module implements the route tracing mechanism. The route gathering
 * mechanism is to be initiated by calling the appropriate command. Next
 * the host sends a special message over the lower networking layers 
 * (implementing message routing). Each host that receives this message
 * that is destined not to it has to add it's address to the end of the 
 * message and send it to the next node. If the node receives this message
 * and this message is destined to it then this host has to send this message
 * back to the originator and send the other message that will gather
 * routing information back from destination to source. 
 * The host initiated the route information gathering process receives two 
 * messages: first containing the forward routing path and other containing
 * backward routing information.
 * The main distinction of the module is that it uses the underlying 
 * routing mechanism.
 */

includes PiggyBack;
includes AM;
includes TraceFunctions;

// debug mode to be used for this module
#define DBG_TRACEROUTE DBG_ROUTE

module TraceRouteM
{
  provides 
  {
    interface StdControl;
    interface PiggyBack[uint8_t id];
  }
  uses 
  {
    interface StdControl as SubControl;
    interface Send[uint8_t id];
    interface Receive[uint8_t id];
    interface Intercept[uint8_t id];
  }
}
implementation
{
  /*
   * Internal variables 
   */
  TOS_Msg buffer; //message buffer used for sending/receiving
  TOS_MsgPtr pBuf; //pointer to the buffer we shall put back
  uint8_t msgType; // "global" message type
  uint8_t sendingBack; //if the sending bakward routing information is running
  uint16_t rtSrc; // source of the routing collect message
  uint16_t cnt; //internal counter

  /*
   * Internal functions
   */
  /*
   * Function fills in the message with the routing information
   * param: msg - message pointer
   * param: id - message type
   * param: dir - direction (may be DIR_FORWARD or DIR_BACKWARD)
   * param: dest - destination node address
   * return: data length
   */
  static uint16_t initRouteMsg(TOS_MsgPtr msg, uint8_t id, uint8_t dir, 
    uint16_t dest)
  {
    uint16_t len; //available 
    // pointer to the PiggyBack message
    PiggyMsg* pPMsg = (PiggyMsg*)call Send.getBuffer[id](msg, &len);
    uint16_t localAddress; //local address variable
    
    atomic
    {
      localAddress = TOS_LOCAL_ADDRESS;
    }
    //Here let's fill the message fields
    memset(pPMsg->addresses, 0, restLen(len));
    pPMsg->flags = dir;
    pPMsg->idx = 0;
    pPMsg->source = localAddress;
    pPMsg->destination = dest;
    atomic
    {
      if (dir == DIR_FORWARD)
      {
        cnt++;
        if (cnt >= 0xFFFF)
          cnt = 0;
      }
      pPMsg->cnt = cnt;
    }
    //Here let's set up the address
    msg->addr = pPMsg->destination;
    return len;
  }

  /*
   * Task used to send two route collecting packets back
   */
  task void SendBackTask()
  {
    uint16_t len; //data length
    if (sendingBack > 1)
      return;
    else if (sendingBack == 0) //we have just started the process
    {
      call Send.getBuffer[msgType](pBuf, &len);
      sendingBack = 2;
      dbg(DBG_TRACEROUTE, "TRCRT: Sending trace message BACK %p\n", pBuf);
      call Send.send[msgType](pBuf, len);
    }
    else if (sendingBack == 1)
    {
      PiggyMsg* pPMsg = (PiggyMsg*)call Send.getBuffer[msgType](pBuf, 
        &len);
      len = initRouteMsg(pBuf, msgType, DIR_BACKWARD, rtSrc);
      addMe(pBuf, len, pPMsg);
      dbg(DBG_TRACEROUTE, "TRCRT: Sending BACKTRACE message %p\n", pBuf);
      call Send.send[msgType](pBuf, len);
    }
  }

  /*
   * Function initiates the process of gathering backward tracing information
   * param: msg - pointer to the message we shall send back
   * param: id - message type
   * param: dest - the node we are collecting routing information to
   * 
   * return: pointer to the message should be used then
   */
  TOS_MsgPtr backTrace(TOS_MsgPtr msg, uint8_t id, uint16_t dest)
  {
    TOS_MsgPtr tmp; //just a temporary pointer (nothing more)

    if (sendingBack != 0)
    {
      dbg(DBG_TRACEROUTE, "TRCRT: process BUSY!!\n");
      return msg;
    }
    atomic
    {
      tmp = pBuf;
      pBuf = msg;
      rtSrc = dest;
      msgType = id;
    }
    dbg(DBG_TRACEROUTE, "TRCRT: message sent back to originator %p\n", pBuf);
    post SendBackTask();
    return tmp;
  }
  
  /*
   * StdControl interface functions
   */
  command result_t StdControl.init()
  {
    result_t result; // function call result

    pBuf = &buffer;
    sendingBack = 0;
    cnt = 0;
    result = call SubControl.init();
    return result;
  }

  command result_t StdControl.start()
  {
    result_t result; // function call result
    result = call SubControl.start();
    return result;
  }

  command result_t StdControl.stop()
  {
    result_t result; // function call result
    result = call SubControl.stop();
    return result;
  }
  
  /*
   * PiggyRoute interface functions
   */
  command result_t PiggyBack.gather[uint8_t id](TOS_MsgPtr msg, uint16_t dest)
  {
    uint16_t len; //message length itself
    result_t result; //Function call result
    PiggyMsg* pPMsg = (PiggyMsg*)call Send.getBuffer[id](msg, &len);
    
    len = initRouteMsg(msg, id, DIR_FORWARD, dest);
    addMe(msg, len, pPMsg); //Add myself into the beginning of the message
    //And now, let's send up the message
    dbg(DBG_TRACEROUTE, "TRCRT: Routing collection started %p\n", msg);
    result = call Send.send[id](msg, len);
    return result;
  }

  command TOS_MsgPtr PiggyBack.gatherBack[uint8_t id](TOS_MsgPtr msg, 
    uint16_t dest)
  {
    return backTrace(msg, id, dest);
  }

  default event result_t PiggyBack.getBack[uint8_t id](TOS_MsgPtr msg, 
    void* payload, uint16_t payloadLen) 
  {
    return SUCCESS;
  }

  default event TOS_MsgPtr PiggyBack.routeReady[uint8_t id](TOS_MsgPtr msg, 
    void* payload, uint16_t payloadLen)
  {
    return msg;
  }

  /*
   * Intercept interface functions
   */
  event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    uint8_t i; //just index variable (nothing more)
    PiggyMsg* pPMsg = (PiggyMsg*)payload; 
    uint16_t localAddress; //local address variable
    
    atomic
    {
      localAddress = TOS_LOCAL_ADDRESS;
    }

    //Let's remember the number of the request here
    atomic
    {
      cnt = pPMsg->cnt;
    }
    
    if (pPMsg->destination == localAddress ||
      pPMsg->source == localAddress)
      return FAIL;
      
    dbg(DBG_TRACEROUTE, "TRCRT: Got message %p %d: %d -> %d %s\n",
     msg, pPMsg->cnt, pPMsg->source, pPMsg->destination, 
     ((pPMsg->flags & DIR_MASK) == DIR_FORWARD)? "forward": "backward");

    addMe(msg, payloadLen, payload);
    dbg(DBG_TRACEROUTE, "TRCRT: passed hosts:\n");
    for (i = 0; i < pPMsg->idx; i++)
      dbg(DBG_TRACEROUTE, "%d\n", pPMsg->addresses[i]);

    /* All said, node added itself to the list of passed nodes and
       may relay on the forwarding provided by routing mechanism.
     */
    return SUCCESS;
  }

  /*
   * Send interface functions
   */
  event result_t Send.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success)
  {
    bool sendAgain = FALSE; //if we should send anothe packet
    if (success != SUCCESS)
    {
      dbg(DBG_TRACEROUTE, "TRCRT: Message sending FAILED\n");
      atomic
      {
        sendingBack = 0;
      }
      return success;
    }
    atomic
    {
      if (msg == pBuf)
      {
        if (sendingBack == 2)
        {
          dbg(DBG_TRACEROUTE, "TRCRT: Trace message sent BACK %p\n", msg);
          sendingBack = 1;
          msgType = id;
          sendAgain = TRUE;
        }
        else if (sendingBack == 1)
        {
          dbg(DBG_TRACEROUTE, "TRCRT: BACKTRACE message sent %p\n", msg);
          sendingBack = 0;
        }
      }
    }
    if (sendAgain)
      post SendBackTask();

    return SUCCESS;
  }
  
  /*
   * Receive interface functions
   */
  event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    TOS_MsgPtr tmp = msg; //just a temporary pointer (nothing more)
    PiggyMsg* pPMsg = (PiggyMsg*)payload;
    uint16_t localAddress; //local address variable
    
    atomic
    {
      localAddress = TOS_LOCAL_ADDRESS;
    }
    
    /* Ok, once this method is called THIS node is the message addressee
       so all we have to do is to determine if the node is the source or
       the destination of the routing collecting message.
     */
    
    dbg(DBG_TRACEROUTE, "TRCRT: Got message %p %d: %d -> %d %s\n",
     msg, pPMsg->cnt, pPMsg->source, pPMsg->destination, 
     ((pPMsg->flags & DIR_MASK) == DIR_FORWARD)? "forward": "backward");

    if (pPMsg->destination == localAddress && 
      (pPMsg->flags & DIR_MASK) == DIR_BACKWARD || 
      pPMsg->source == localAddress)
    {
      addMe(msg, payloadLen, payload);
      //Here we see that this node got back a message with routing path
      tmp = signal PiggyBack.routeReady[id](msg, payload, payloadLen);
      if (!tmp)
        tmp = msg;
      if ((pPMsg->flags & DIR_MASK) == DIR_BACKWARD)
      {
        uint8_t i; //just index variable (nothing more)
        dbg(DBG_TRACEROUTE, "TRCRT: backward tracing:\n");
	      for (i = 0; i < pPMsg->idx; i++)
	        dbg(DBG_TRACEROUTE, "%d\n", pPMsg->addresses[i]);
      }
      else
      {
        uint8_t i; //just index variable (nothing more)
        dbg(DBG_TRACEROUTE, "TRCRT: forward tracing\n");
	      for (i = 0; i < pPMsg->idx; i++)
	        dbg(DBG_TRACEROUTE, "%d\n", pPMsg->addresses[i]);
      }
    }
    else if (pPMsg->destination == localAddress && 
      (pPMsg->flags & DIR_MASK) == DIR_FORWARD)
    {
      //Here we see this node is the destination of the routing message
      //We have to send back this message and initiate the backward routing
      //information collection process
      addMe(msg, payloadLen, payload);
      pPMsg->flags |= MSG_FILLED;
      if (signal PiggyBack.getBack[id](msg, pPMsg, payloadLen) == FAIL)
      {
        dbg(DBG_TRACEROUTE, "TRCRT: We should not send something back\n");
        return msg;
      }
      tmp = backTrace(msg, id, pPMsg->source);
    }
    return tmp;
  }
  
  /*
   * Send interface default funxctions
   */
  default command result_t Send.send[uint8_t id](TOS_MsgPtr msg, uint16_t length)
  {
    return FAIL; //Sure, we didn't send anything
  }
  
  default command void* Send.getBuffer[uint8_t id](TOS_MsgPtr msg, uint16_t* length)
  {
    //FIXME: better ideas?
    *length = TOSH_DATA_LENGTH;
    return msg->data;
  }
}


//eof
