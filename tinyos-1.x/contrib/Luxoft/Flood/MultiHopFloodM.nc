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
 * This module is based on the MultiHopEngineM module 
 * by Matt Welsh, David Culler, Philip Buonadonna
 */
/* 
 * Authors:  Dmitriy Korovkin
 *           LUXOFT Inc.
 * Date:     9/15/2003
 *
 * $Id: MultiHopFloodM.nc,v 1.2 2003/12/26 11:45:21 korovkin Exp $
 */
/*
 * Module implements the controlled flood message passing mechanism. 
 * The main distinction of the module is that it uses broadcast message 
 * passing for message delivery. In order to avoid message loops the 
 * counter is used. Each mote has a counter which it puts to the message
 * header. On each message receive the mote compares it's internal counter
 * with the latter in the message header. In the message header counter is 
 * less than the mote's one message have to be discarded, if equal or less,
 * intercept method should be called in order to decide if message should 
 * be forwarded or not.
 */

includes AM;
includes MultiFlood;
// debug mode to be used for this module
#define DBG_FLOOD DBG_ROUTE

#ifndef MFLOOD_QUEUE_SIZE
#define MFLOOD_QUEUE_SIZE	2
#endif

module MultiHopFloodM
{
  provides 
  {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Send[uint8_t id];
    interface Intercept[uint8_t id];
  }
  uses
  {
    interface ReceiveMsg[uint8_t id];
    interface SendMsg[uint8_t id];
    interface CommControl;
    interface StdControl as CommStdControl;
    interface StdControl as QControl;
  }
}

implementation
{
  /*
   * Internal variables
   */
  enum 
  {
    FWD_QUEUE_SIZE = MFLOOD_QUEUE_SIZE, // Forwarding Queue
  };

  /* Internal storage and scheduling state */
  struct TOS_Msg FwdBuffers[FWD_QUEUE_SIZE]; //Messages buffer
  //Array of buffer pointers returned and resent
  struct TOS_Msg *FwdBufList[FWD_QUEUE_SIZE]; 

  //buffer tail and head
  uint8_t iFwdBufHead, iFwdBufTail;
  uint8_t iBufAvail; //number of available entries in the buffer
  uint16_t count; //internal message counter
  enum 
  { 
    //Threshold of the message counter and maximal counter.
    //It has to represent the fact that counter wraps time to time
    CNT_THRESHOLD = 5
  };
  
  /*
   * Internal functions
   */
  static void initialize() 
  {
    uint8_t i; //just an index variable

    for (i = 0; i < FWD_QUEUE_SIZE; i++) 
      FwdBufList[i] = &FwdBuffers[i];

    iFwdBufHead = 0;
    iFwdBufTail = 0;
    iBufAvail = FWD_QUEUE_SIZE;
    count = 0;
  }

  /*
   * StdControl interface functions
   */
  command result_t StdControl.init() 
  {
    initialize();
    call CommStdControl.init();
    return call QControl.init();
  }

  command result_t StdControl.start() 
  {
    call CommStdControl.start();
    return call QControl.start();
  }

  command result_t StdControl.stop() 
  {
    call QControl.stop();
    return call CommStdControl.stop();
  }
  
  /*
   * Send interface functions
   */
  command result_t Send.send[uint8_t id](TOS_MsgPtr pMsg, uint16_t payloadLen) 
  {
    uint16_t usMFLength = offsetof(TOS_MFloodMsg, data) + payloadLen;
    TOS_MFloodMsg* pMFMsg = (TOS_MFloodMsg*)pMsg->data;

    if (usMFLength > TOSH_DATA_LENGTH) 
      return FAIL;

    count++;
    if (count >= 0xFFFF)
      count = 0;
    pMFMsg->count = count;
    dbg(DBG_FLOOD,"MFlood: out pkt 0x%x\n", pMFMsg->count);
    
    pMsg->addr = TOS_BCAST_ADDR;
    return call SendMsg.send[id](pMsg->addr, usMFLength, pMsg);
  } 

  command void* Send.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) 
  {
    TOS_MFloodMsg *pMFMsg = (TOS_MFloodMsg *)pMsg->data;
    
    *length = TOSH_DATA_LENGTH - offsetof(TOS_MFloodMsg, data);
    return (&pMFMsg->data[0]);
  }

  /*
   * SendMsg interface functions
   */
  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, bool success) 
  {
    if (pMsg == FwdBufList[iFwdBufTail]) 
    { // Msg was from forwarding queue
      iFwdBufTail++; 
      iFwdBufTail %= FWD_QUEUE_SIZE;
      iBufAvail++;
      dbg(DBG_FLOOD, "MFlood: Message %p send DONE\n", pMsg);  
    } 
    else
      signal Send.sendDone[id](pMsg, success);
    return SUCCESS;
  }

  default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, 
    bool success)
  {
    return SUCCESS;
  }

  /*
   * ReceiveMsg interface functions
   */
   
  task void doForward()
  {
    TOS_MsgPtr pMsg = FwdBufList[iFwdBufTail];
    call SendMsg.send[pMsg->type](pMsg->addr, pMsg->length, pMsg);
    dbg(DBG_FLOOD, "MFlood: Sent %p\n", pMsg);  
  }
  
  static TOS_MsgPtr mForward(TOS_MsgPtr pMsg, uint8_t id) 
  {
    TOS_MsgPtr pNewBuf = pMsg;
    
    if (iBufAvail == 0) 
      return pNewBuf;
    
    pNewBuf = FwdBufList[iFwdBufHead];
    FwdBufList[iFwdBufHead] = pMsg;
    pMsg->type = id;
    iFwdBufHead++; 
    iFwdBufHead %= FWD_QUEUE_SIZE;
    iBufAvail--;
    post doForward();
    return pNewBuf;
  }

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) 
  {
    //Pointer to data we are interested in
    TOS_MFloodMsg* pMFMsg = (TOS_MFloodMsg*)pMsg->data;
    //Length of the data we are interested in
    uint16_t payloadLen = pMsg->length - offsetof(TOS_MHopMsg, data);
    /*
     * FIXME!!! The evil hack: if we received this message from 
     * UART host and the our mote id is 0 (we are connected to UART), 
     * then the sequence number may be wrong. Let's set it
     */
    if (pMsg->orig == TOS_UART_ADDR && TOS_LOCAL_ADDRESS == 0)
      pMFMsg->count = count + 1;
    //If we see previous message - do nothing
    if (pMFMsg->count > count || (count - pMFMsg->count) >= CNT_THRESHOLD)
    {
      dbg(DBG_FLOOD, "MFlood: Msg Rcvd, src 0x%02x, count 0x%X\n", 
        pMsg->orig, pMFMsg->count);

      count = pMFMsg->count;
      // Ordinary message requiring forwarding
      if ((signal Intercept.intercept[id](pMsg, &pMFMsg->data[0], 
        payloadLen)) == SUCCESS) 
      {
        pMsg = mForward(pMsg, id);
      }
      else
        pMsg = signal Receive.receive[id](pMsg, &pMFMsg->data[0], payloadLen);
    }
    return pMsg;
  }

  default event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr msg, 
    void* payload, uint16_t payloadLen)
  {
    return FAIL;
  }
  
  default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg, 
    void* payload, uint16_t payloadLen)
  {
    return msg;
  }

  default command result_t SendMsg.send[uint8_t id](uint16_t address, 
    uint8_t length, TOS_MsgPtr msg)
  {
    return FAIL; //because actually we don't send anything
  }
}


//eof
