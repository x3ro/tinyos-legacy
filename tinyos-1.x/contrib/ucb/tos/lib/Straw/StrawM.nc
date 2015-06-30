/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/* Authors:   Kamin Whitehouse
 *
 */

//$Id: StrawM.nc,v 1.1 2005/10/25 06:05:27 kaminw Exp $

includes Drain;

module StrawM
{
  provides {
    interface StdControl;
    interface Straw[uint8_t id];
    command result_t read(uint8_t strawID, uint32_t start, uint32_t size) @rpc();
  }
  uses {
    interface Timer;
    interface Send;
    interface SendMsg;
  }
}
implementation
{

  TOS_Msg dataMsg;
  TOS_MsgPtr dataMsgPtr;
  uint8_t m_strawID;
  uint32_t m_start;
  uint32_t m_initialStart;
  uint32_t m_size;
  uint16_t sendPeriod;
  uint16_t returnAddress;
  uint8_t buffer[STRAW_BUFFER_SIZE];
  bool isReading;
  bool sendingResponse;
  uint16_t msgDataSize;

  command result_t StdControl.init() {
    StrawMsg *strawMsg = (StrawMsg*)call Send.getBuffer(dataMsgPtr, &msgDataSize);
    msgDataSize = MIN(STRAW_BUFFER_SIZE, msgDataSize);
    dataMsgPtr = &dataMsg;
    sendPeriod = 500;
    returnAddress = 0xfffe;
    isReading = FALSE;
    sendingResponse = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }
  
  command result_t read(uint8_t strawID, uint32_t start, uint32_t size){
    m_strawID = strawID;
    m_initialStart = start;
    m_start = m_initialStart;
    m_size = size;
    return call Timer.start(TIMER_REPEAT, sendPeriod);
}

  event result_t Timer.fired() {
    if( isReading == FALSE){
      if( m_start - m_initialStart >= m_size) {
	call Timer.stop();
      }
      else if(signal Straw.read[m_strawID](m_start, MIN(msgDataSize, m_size), buffer) ){
	  isReading = TRUE;
      }
    }
    return SUCCESS;
  }

  command result_t Straw.readDone[uint8_t strawID](result_t success){
    if (strawID != m_strawID)
      return FAIL;
    if( isReading == TRUE && success == SUCCESS){
      uint16_t length;
      StrawMsg *strawMsg = (StrawMsg*)call Send.getBuffer(dataMsgPtr, &length);
      strawMsg->startIndex = m_start;
      memcpy(strawMsg->data, buffer, msgDataSize);
      m_start += msgDataSize;
      isReading = FALSE;
      if (sendingResponse == FALSE && call SendMsg.send(returnAddress,
				    sizeof(StrawMsg),
				    dataMsgPtr) ){
        sendingResponse=TRUE;
      }
    }
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }
  event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
    dataMsgPtr = pMsg;
    sendingResponse = FALSE;
    return SUCCESS;
  }

  default event result_t Straw.read[uint8_t id](uint32_t aStart, uint32_t aSize, uint8_t* aBffr) {
    return FAIL;
  }
}

