// $Id: CC2420TimeStampingM.nc,v 1.1.1.1 2007/11/05 19:11:29 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "AM.h"

/**
 * Supports SP by timestamping received and transmitted packets.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module CC2420TimeStampingM
{
  provides
  {
    interface TimeStamping<T32khz, uint32_t>;
  }
  uses
  {
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface LocalTime<T32khz>;
    interface HPLCC2420RAM;
    interface ResourceCmdAsync as CmdWriteTimeStamp;
  }
}
implementation
{
  // the offset of the time-stamp field in the message, 
  // or -1 if no stamp is necessariy.
  norace int8_t sendStampOffset = -1;
  norace TOS_MsgPtr ptosMsg;
  norace TOS_MsgPtr timestampMsgBuf;
  
  enum{
    TX_FIFO_MSG_START = 10,
    SEND_TIME_CORRECTION = 1,
  };

  async event void CmdWriteTimeStamp.granted( uint8_t rh ) {
    call HPLCC2420RAM.write(rh, TX_FIFO_MSG_START + sendStampOffset, sizeof(uint32_t), (void*)timestampMsgBuf->data + sendStampOffset);
    sendStampOffset = -1;   
    call CmdWriteTimeStamp.release();
  }

  async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
  {
    uint32_t send_time;

    atomic send_time = call LocalTime.get() - SEND_TIME_CORRECTION;
    
    if ((ptosMsg != NULL) && (ptosMsg != msgBuff))
      return;
    
    if( sendStampOffset < 0 )
      return;

    *(uint32_t*)((void*)msgBuff->data + sendStampOffset) = send_time;

    timestampMsgBuf = msgBuff;

    call CmdWriteTimeStamp.urgentRequest( RESOURCE_NONE );
  }

  async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
  {
  }

  command uint32_t TimeStamping.getReceiveStamp(TOS_Msg* msg)  {
    return msg->time;
  }

  command void TimeStamping.cancel() {
    sendStampOffset = -1;
  }

  //this needs to be called right after SendMsg.send() returned success, so 
  //the code in addStamp() method runs before a task in the radio stack is 
  //posted that writes to fifo -> which triggers coordinator event 
  
  //if a msg is already being served by the radio, (sendStampOffset is 
  //defined), timestamping returns fail
  
  command result_t TimeStamping.addStampAll(int8_t offset)
  {
    if ((0 <= offset) && (offset <= TOSH_DATA_LENGTH-4)) {
      atomic sendStampOffset = offset;
      ptosMsg = NULL;
      return SUCCESS;
    }
    return FAIL;
  }

  command result_t TimeStamping.addStamp(TOS_MsgPtr msg, int8_t offset)
  {
    if ((0 <= offset) && (offset <= TOSH_DATA_LENGTH-4)) {
      atomic sendStampOffset = offset;
      ptosMsg = msg;
      return SUCCESS;
    }
    return FAIL;
  }

  command uint32_t TimeStamping.getStampMsg(TOS_MsgPtr msg, int8_t offset) {
    return *(uint32_t*)((void*)msg->data + offset);
  }

  async event result_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t length, uint8_t* buffer){
    return SUCCESS;
  }
    
  async event result_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t length, uint8_t* buffer){
    return SUCCESS;
  }

  /** Never fired for CC2420 Radio **/
  async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
  async event void RadioSendCoordinator.blockTimer() { }
  
  async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
  async event void RadioReceiveCoordinator.blockTimer() { }

}
