
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

 
includes BASE;
 
module BaseM {
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer;
    interface SendMsg as TxSyncMsg;
    interface SendMsg as TxReportMsg;    
    interface SendMsg as TxConfigMsg; 
    interface SendMsg as TxReportAckMsg;
    
    interface ReceiveMsg as RcvSyncMsg;  
    interface ReceiveMsg as RcvReportMsg;
    interface ReceiveMsg as RcvConfigMsg;    
    interface ReceiveMsg as RcvReportAckMsg;
    
    interface UARTTimeSync;
    interface GlobalTime;
  }
}
implementation {

  enum {
    TXFLAG_BUSY = 0x1,
    TXFLAG_TOKEN = 0x2
  };
  
  TOS_Msg    gTxBuf;
  TOS_MsgPtr gpTxMsg;
  uint8_t    gfTxFlags;
  
  TOS_Msg SyncBuf;
  TOS_MsgPtr pSyncBuf;  
  uint8_t    pSyncBufFlags;
          
  int seqNo = 0;
  
  /* incoming buffer */
  TOS_Msg gRxBufPool[QUEUE_SIZE]; 
  TOS_MsgPtr gRxBufPoolTbl[QUEUE_SIZE];
  uint8_t gRxHeadIndex,gRxTailIndex;

  TOS_MsgPtr MessageFiltering(TOS_MsgPtr msg);
  result_t SendTimeSyncMsg( uint32_t timeStamp);
      
  command result_t StdControl.init() {
    uint8_t i;
    // Initialize Leds
    call Leds.init();   

    for (i = 0; i < QUEUE_SIZE; i++) {
      gRxBufPool[i].length = 0;
      gRxBufPoolTbl[i] = &gRxBufPool[i];
    }
    gRxHeadIndex = 0;
    gRxTailIndex = 0;
    	 
    gTxBuf.length = 0;
    gpTxMsg = &gTxBuf;
    gfTxFlags = 0;
 
    SyncBuf.length = 0;   
    pSyncBuf = &SyncBuf;
    pSyncBufFlags = 0;
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // Set up timer to repeat every 5 seconds
    call Timer.start(TIMER_REPEAT, 300);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    // Stop the timer
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {             
    return SUCCESS;
  }
  
  event result_t TxSyncMsg.sendDone(TOS_MsgPtr msg, result_t success) {    
    msg->length = 0;    
    return SUCCESS;
  }

  event result_t TxReportMsg.sendDone(TOS_MsgPtr msg, result_t success) {    
    msg->length = 0;   
    gfTxFlags = 0;              
    return SUCCESS;
  }

  event result_t TxConfigMsg.sendDone(TOS_MsgPtr msg, result_t success) {    
    msg->length = 0;   
    gfTxFlags = 0;              
    return SUCCESS;
  }

  event result_t TxReportAckMsg.sendDone(TOS_MsgPtr msg, result_t success) { 
    msg->length = 0;   
    gfTxFlags = 0;              
    return SUCCESS;
  }  
    

  task void UARTRcvdTask() {
    result_t Result;
        
    dbg (DBG_USR1, "TOSBase forwarding UART packet to Radio\n");
    gpTxMsg->group = TOS_AM_GROUP;
             
    switch(gpTxMsg->type){    
    case AM_REPORTMSG :
      Result = call TxReportMsg.send(TOS_BCAST_ADDR,gpTxMsg->length,gpTxMsg);
      break;
    case AM_CONFIGMSG :
      Result = call TxConfigMsg.send(TOS_BCAST_ADDR,gpTxMsg->length,gpTxMsg);
      break;
    case AM_REPORTACKMSG :
      Result =call TxReportAckMsg.send(TOS_BCAST_ADDR,gpTxMsg->length,gpTxMsg);
      break;      
    default: Result = FAIL;      
    }
    
    if (Result != SUCCESS) {
      atomic gfTxFlags = 0;
    } else {
      call Leds.redToggle(); 
    }  
  }

  task void RadioRcvdTask() {
    TOS_MsgPtr pMsg;
    result_t   Result;
    
    call Leds.yellowToggle();
        
    dbg (DBG_USR1, "TOSBase forwarding Radio packet to UART\n");
    atomic {
      pMsg = gRxBufPoolTbl[gRxTailIndex];
      gRxTailIndex++; gRxTailIndex %= QUEUE_SIZE;
    }

    switch(pMsg->type){    
    case AM_SYNCMSG :
      Result = call TxSyncMsg.send(TOS_UART_ADDR,pMsg->length,pMsg);  
      break;
    case AM_REPORTMSG :
      Result = call TxReportMsg.send(TOS_UART_ADDR,pMsg->length,pMsg);
      break;     
    default: Result = FAIL;      
    }
    if (Result != SUCCESS) {
      pMsg->length = 0;
    } else {
      call Leds.greenToggle();
    }
  }
    
      
  event TOS_MsgPtr RcvSyncMsg.receive(TOS_MsgPtr msg){ 
    return msg;         	                          
  }    
    
  event TOS_MsgPtr RcvReportMsg.receive(TOS_MsgPtr Msg){
  

    TOS_MsgPtr pBuf = NULL;
    
    struct ReportMsg * ReportMsgPtr = (struct ReportMsg *) Msg->data;  
                
    switch(ReportMsgPtr->type){
    
    case REPORT_REPLY :

      atomic {
	pBuf = gRxBufPoolTbl[gRxHeadIndex];
	if (pBuf->length == 0) {
	  gRxBufPoolTbl[gRxHeadIndex] = Msg;
	  gRxHeadIndex++; gRxHeadIndex %= QUEUE_SIZE;
	}else {
	  pBuf = NULL;
	}
      }
      
      if (pBuf) {
	post RadioRcvdTask();
      } else {// buffer is full;
	pBuf = Msg;
      }
               
      break;
    default: break;
    }          

    return pBuf;      
  }

  event TOS_MsgPtr RcvConfigMsg.receive(TOS_MsgPtr Msg) {

    TOS_MsgPtr pBuf = NULL;
      
    atomic {
      if (gfTxFlags & TXFLAG_BUSY) {
	pBuf = NULL;
      }
      else {
	pBuf = gpTxMsg;
	gfTxFlags |= (TXFLAG_BUSY);
	gpTxMsg = Msg;
      }
    }

    if (pBuf) {	  
      post UARTRcvdTask();
    }else {
      pBuf = Msg; 	      
    } 
	    
    return pBuf;            
  }

  event TOS_MsgPtr RcvReportAckMsg.receive(TOS_MsgPtr Msg) {

    TOS_MsgPtr pBuf = NULL;
      
    atomic {
      if (gfTxFlags & TXFLAG_BUSY) {
	pBuf = NULL;
      }
      else {
	pBuf = gpTxMsg;
	gfTxFlags |= (TXFLAG_BUSY);
	gpTxMsg = Msg;
      }
    }

    if (pBuf) {	  
      post UARTRcvdTask();
    }else {
      pBuf = Msg; 	      
    } 
	    
    return pBuf;            
  }

  
  /* additional functions to support new base code */
     
  result_t SendTimeSyncMsg( uint32_t timeStamp){

    struct SyncMsg * SyncMsgPtr = (struct SyncMsg *) pSyncBuf->data;  
    TOS_MsgPtr pBuf;  

    SyncMsgPtr->commandType = SYNC_REPLY;
    SyncMsgPtr->seqNo = seqNo++;    

    SyncMsgPtr->moteRecvTime = timeStamp;

    SyncMsgPtr->moteRecvTime = call GlobalTime.jiffy2ms(SyncMsgPtr->moteRecvTime);

    /* to do adjustment */
    SyncMsgPtr->moteSendTime = SyncMsgPtr->moteRecvTime;       
    pSyncBuf->crc = TRUE;
    pSyncBuf->group = TOS_AM_GROUP;
    pSyncBuf->type = AM_SYNCMSG;
    pSyncBuf->length = sizeof(struct SyncMsg);
    
    atomic {
      pBuf = gRxBufPoolTbl[gRxHeadIndex];
      if (pBuf->length == 0) {
	gRxBufPoolTbl[gRxHeadIndex] = pSyncBuf;
	gRxHeadIndex++; gRxHeadIndex %= QUEUE_SIZE;
      }else {
	pBuf = NULL;
      }
    }
      
    if (pBuf) {
      post RadioRcvdTask();
    } else {// buffer is full;
      pBuf = pSyncBuf;
    }
      
    pSyncBuf = pBuf;
      
    return SUCCESS;                 	          	   
  }

  event void UARTTimeSync.syncDone(uint32_t timeStamp){
    SendTimeSyncMsg(timeStamp);
  }
    
}


