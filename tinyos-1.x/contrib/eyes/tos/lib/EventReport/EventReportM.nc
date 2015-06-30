/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2006/03/22 11:56:31 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
includes AM;
module EventReportM 
{
  provides interface EventReport;
  provides async event void sendUartStarted(TOS_MsgPtr msg);
  uses {
    interface SendMsg;
    interface ReceiveMsg;
    interface LocalTime;
    interface Timer;
    interface Leds;
  }
}
implementation {
  enum {
    QUEUESIZE = 5,
    ACK_TIMEOUT = 200, // in ms
    RETRY_TIMER = 50,
  };
  
  TOS_Msg msgTxBuf[QUEUESIZE];
  uint8_t txBufIndex;
  uint8_t entries;
  uint16_t seqNum;
  norace uint16_t ackSeqNumExpected;
  bool busy;

  void task SendTask();
  
  command result_t EventReport.send(uint8_t eventID, uint32_t time, 
      uint16_t subscriberID, uint16_t subscriptionID)
  {
    eventreport_t *report;
    uint8_t i;
    
    seqNum++; // increase seqnum even if msg is not sent
    if (entries < QUEUESIZE){
      report = (eventreport_t*) msgTxBuf[txBufIndex].data;
      txBufIndex = (txBufIndex+1) % QUEUESIZE;
      entries++;
    } else
      return FAIL;
    report->sourceID = TOS_LOCAL_ADDRESS;
    report->seqNum = seqNum;
    report->eventID = eventID;
    report->delta = time;
    report->subscriberID = subscriberID;
    report->subscriptionID = subscriptionID;
    post SendTask();
    return SUCCESS;
  }
 
  TOS_MsgPtr getNextMsg()
  {
    if (entries == 0)
      return 0;
    else {
      int i = txBufIndex - entries;
      if (i < 0)
        i = QUEUESIZE + i;
      return &msgTxBuf[i];
    }
  }
  
  void task SendTask()
  {
    TOS_MsgPtr msgPtr;
    eventreport_t *report;
    if (busy)
      return;
    if ((msgPtr = getNextMsg()) != 0){
      report = (eventreport_t*) msgPtr->data;
      if (call SendMsg.send(TOS_UART_ADDR, sizeof(eventreport_t), msgPtr) == SUCCESS)
        busy = TRUE;
      else
        post SendTask();
    }
  }

  async event void sendUartStarted(TOS_MsgPtr msg)
  {
    eventreport_t *report = (eventreport_t *) msg->data;
    report->delta = call LocalTime.read() - report->delta;
    ackSeqNumExpected = report->seqNum;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success)
  {
    call Leds.redToggle();
    call Timer.start(TIMER_ONE_SHOT, ACK_TIMEOUT);
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    // resend, we did not receive an ACK in time
    eventreport_t *report;
    TOS_MsgPtr msgPtr = getNextMsg();
    report = (eventreport_t*) msgPtr->data;
    if (call SendMsg.send(TOS_UART_ADDR, sizeof(eventreport_t), msgPtr) != SUCCESS)
      call Timer.start(TIMER_ONE_SHOT, RETRY_TIMER);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m)
  {
    eventreport_t *report = (eventreport_t *) m->data;
    if (report->seqNum == ackSeqNumExpected){
      call Timer.stop();
      busy = FALSE;
      entries--;
      if (entries)
        post SendTask();
    }
    return m;
  }
}
