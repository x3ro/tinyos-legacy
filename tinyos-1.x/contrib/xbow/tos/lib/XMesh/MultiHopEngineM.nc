// $Id: MultiHopEngineM.nc,v 1.3 2005/01/14 01:25:22 jdprabhu Exp $

/*
 * Copyright (c) 2005 Crossbow Technology, Inc.
 *
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute, this software and
 * documentation is granted, provided the following conditions are met:
 * 
 * 1. The above copyright notice and these conditions, along with the
 * following disclaimers, appear in all copies of the software.
 * 
 * 2. When the use, copying, modification or distribution is for COMMERCIAL
 * purposes (i.e., any use other than academic research), then the software
 * (including all modifications of the software) may be used ONLY with
 * hardware manufactured by and purchased from Crossbow Technology, unless
 * you obtain separate written permission from, and pay appropriate fees
 * to, Crossbow. For example, no right to copy and use the software on
 * non-Crossbow hardware, if the use is commercial in nature, is permitted
 * under this license. 
 *
 * 3. When the use, copying, modification or distribution is for
 * NON-COMMERCIAL PURPOSES (i.e., academic research use only), the software
 * may be used, whether or not with Crossbow hardware, without any fee to
 * Crossbow. 
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE
 * TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
 * EVEN IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM
 * ALL WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY
 * LICENSOR HAS ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS. 
 * 
 */


includes AM;
includes MultiHop;

#ifndef MHOP_QUEUE_SIZE
#define MHOP_QUEUE_SIZE	16
#endif

module MultiHopEngineM {
  provides {
    interface StdControl;
    interface Receive[uint8_t id];
    interface Send[uint8_t id];
    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
    interface Receive as ReceiveDataMsg[uint8_t id];
    interface RouteControl;
	command   TOS_MsgPtr SendDownStreamMsg(TOS_MsgPtr pMsg);
    
  }

  uses {
    event void MultiHopForward(TOS_MsgPtr pMsg);  
    interface ReceiveMsg[uint8_t id];
    interface SendMsg[uint8_t id];
    interface RouteControl as RouteSelectCntl;
    interface RouteSelect;
    interface StdControl as SubControl;
    interface CommControl;
    interface StdControl as CommStdControl;
    interface ReceiveMsg as ReceiveDownstreamMsg[uint8_t id];
    interface RadioPower;
    interface Timer;
    command void set_power_mode(uint8_t mode);
  }
}

implementation {

  enum {
    FWD_QUEUE_SIZE = MHOP_QUEUE_SIZE, 
    EMPTY = 0xff
  };


  


  
  struct TOS_Msg FwdBuffers[FWD_QUEUE_SIZE];
  struct TOS_Msg *FwdBufList[FWD_QUEUE_SIZE];
  uint8_t FwdBufBusy[FWD_QUEUE_SIZE];

  uint8_t iFwdBufHead, iFwdBufTail;

  int timer_rate,timer_ticks;
  
  


  static void initialize() {
    int n;

    for (n=0; n < FWD_QUEUE_SIZE; n++) {
      FwdBufList[n] = &FwdBuffers[n];
      FwdBufBusy[n] = 0;
    } 

    iFwdBufHead = iFwdBufTail = 0;
  }

  command result_t StdControl.init() {
    initialize();
    call CommStdControl.init();
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    call CommStdControl.start();
    call SubControl.start();
    return call CommControl.setPromiscuous(TRUE);
  }

  command result_t StdControl.stop() {
    call SubControl.stop();
    
    return call CommStdControl.stop();
  }


  

  command result_t Send.send[uint8_t id](TOS_MsgPtr pMsg, uint16_t PayloadLen) {

    uint16_t usMHLength = offsetof(TOS_MHopMsg,data) + PayloadLen;

    if (usMHLength > TOSH_DATA_LENGTH) {
      return FAIL;
    }

    

    call RouteSelect.initializeFields(pMsg,id);

    if (call RouteSelect.selectRoute(pMsg,id, 0, 1) != SUCCESS) {
      return FAIL;
    }

    
    
    if (call SendMsg.send[id](pMsg->addr, usMHLength, pMsg) != SUCCESS) {
      return FAIL;
    }

    return SUCCESS;
    
  } 

  command void *Send.getBuffer[uint8_t id](TOS_MsgPtr pMsg, uint16_t* length) {
    
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
    
    *length = TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg,data);

    return (&pMHMsg->data[0]);

  }

  
  
    int8_t get_buff(uint8_t down){
    int8_t n;
    uint8_t val = 1;
    if(down == 1) val = 2;
    for (n=0; n < FWD_QUEUE_SIZE; n++) {
	uint8_t done = 0;
        atomic{
		if(FwdBufBusy[n] == 0){
			FwdBufBusy[n] = val;
			done = 1;
		}
        }
	if(done == 1) return n;
      
    } 
    return -1;
  }

  
  
    int8_t is_ours(TOS_MsgPtr ptr){
    int8_t n;
    for (n=0; n < FWD_QUEUE_SIZE; n++) {
       if(FwdBufList[n] == ptr){
		return n;
       }
    } 
    return -1;
  }
 

  
   uint16_t seconds;

   event result_t Timer.fired() {
       if(seconds & 0x8000){
               seconds &= 0x7fff;
               call RadioPower.SetListeningMode(0);
               call RadioPower.SetTransmitMode(0);
 	       call set_power_mode(1);
               TOSH_CLR_YELLOW_LED_PIN();
       }

       if(seconds > 0){
               seconds --;
               call Timer.start(TIMER_ONE_SHOT, 1000);
       }else{
               call RadioPower.SetListeningMode(1);
               call RadioPower.SetTransmitMode(1);
 	       call set_power_mode(0);
               TOSH_SET_YELLOW_LED_PIN();
       }

       return SUCCESS;
   }

     void ReceivePowerMsg(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLen) {
       uint8_t command_type = ((char*)payload)[0];
       if(command_type == 1){
               seconds = ((char*)payload)[1];
               seconds |= 0x8000;
               call Timer.start(TIMER_ONE_SHOT, 2000);
       }else if(command_type == 0){
               seconds = 0;
               call Timer.start(TIMER_ONE_SHOT, 1000);
       }


   }

  
  
   static TOS_MsgPtr mForward(TOS_MsgPtr pMsg, uint8_t id, uint8_t direction) {

    TOS_MsgPtr	pNewBuf = pMsg;
    TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
    int8_t buf = get_buff(direction);
  	  
	signal MultiHopForward(pMsg);

    if(pMsg->type == 248 ||	pMsg->type == 249) {
  	  ReceivePowerMsg(pMsg, pMHMsg->data, sizeof(pMHMsg->data));
    }
    
    if (buf == -1) return pNewBuf;                           

    if(direction == 0){                                      
    	if ((call RouteSelect.selectRoute(pMsg,id, 0, 0)) != SUCCESS) {
      		FwdBufBusy[buf] = 0;                             
      		return pNewBuf;
    	}
    }else{                                                   
    	if ((call RouteSelect.selectDescendantRoute(pMsg,id, 0, 0)) != SUCCESS) {
      		FwdBufBusy[buf] = 0;                             
      		return pNewBuf;
	    }
    }
 
    
    
    if (call SendMsg.send[id](pMsg->addr,pMsg->length,pMsg) == SUCCESS) {
      pNewBuf = FwdBufList[buf];
      FwdBufList[buf] = pMsg;
    }else{
      FwdBufBusy[buf] = 0;                                   
    }
    
    return pNewBuf;
    
  }

  
   command TOS_MsgPtr SendDownStreamMsg(TOS_MsgPtr pMsg){
       TOS_MsgPtr pTmp;
	   uint16_t PayloadLen = pMsg->length - offsetof(TOS_MHopMsg,data);
       uint8_t id = pMsg->type;
       pTmp = mForward(pMsg,id, 1);
       return pTmp;
   }

  
    event TOS_MsgPtr ReceiveDownstreamMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
       TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)pMsg->data;
       uint16_t PayloadLen = pMsg->length - offsetof(TOS_MHopMsg,data);
       if(pMHMsg->originaddr == TOS_LOCAL_ADDRESS){
           if(pMsg->type == 248 || pMsg->type == 249) {
              ReceivePowerMsg(pMsg, pMHMsg->data, sizeof(pMHMsg->data));
           }
           pMsg = signal ReceiveDataMsg.receive[id](pMsg, pMHMsg->data, sizeof(pMHMsg->data));
           signal Snoop.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen);
       
	   }else if (pMsg->addr == TOS_LOCAL_ADDRESS || pMsg->addr == TOS_BCAST_ADDR){
           pMsg = mForward(pMsg,id, 1);
       } else {
           
           signal Snoop.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen);
       }
       return pMsg;
   }

  event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr pMsg) {
    TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)pMsg->data;
    uint16_t		PayloadLen = pMsg->length - offsetof(TOS_MHopMsg,data);

      
	
    if (pMsg->addr == TOS_LOCAL_ADDRESS) { 
      if ((signal Intercept.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen)) == SUCCESS) {
        pMsg = mForward(pMsg,id, 0);
      }
    }
    else {
      
      signal Snoop.intercept[id](pMsg,&pMHMsg->data[0],PayloadLen);
    }

    return pMsg;
  }
  uint8_t fail_count;


  
  event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    
    
	uint8_t downstream = 0;
    int8_t buf = is_ours(pMsg);
    
   	if (buf != -1) { 
  	  if(FwdBufBusy[buf] == 2) downstream = 1;
    }
    
    if(pMsg->ack == 0 && pMsg->addr != TOS_BCAST_ADDR && pMsg->addr != TOS_UART_ADDR && fail_count < 8){
         if(fail_count == 6) call RouteSelect.forwardFailed();

	     if(downstream){
    	 	call RouteSelect.selectDescendantRoute(pMsg,id, 1, 0);
	     }else{
    	 	call RouteSelect.selectRoute(pMsg,id, 1, 0);
	     }
		 if (call SendMsg.send[id](pMsg->addr,pMsg->length,pMsg) == SUCCESS) {
	 	 fail_count ++;
		 return SUCCESS;
	 }
	
     } else if(pMsg->ack == 0 && pMsg->addr != TOS_BCAST_ADDR && pMsg->addr != TOS_UART_ADDR && downstream){
    	 call RouteSelect.selectDescendantRoute(pMsg,id, 1, 0);
         if (call SendMsg.send[id](TOS_BCAST_ADDR,pMsg->length,pMsg) == SUCCESS) {
               return SUCCESS;
         }
     }
     fail_count = 0;
     if (buf != -1) { 
      FwdBufBusy[buf] = 0;
     } else {
      signal Send.sendDone[id](pMsg, success);
     } 
    return SUCCESS;
  }

  command uint16_t RouteControl.getParent() {
    return call RouteSelectCntl.getParent();
  }

  command uint8_t RouteControl.getQuality() {
    return call RouteSelectCntl.getQuality();
  }

  command uint8_t RouteControl.getDepth() {
    return call RouteSelectCntl.getDepth();
  }

  command uint8_t RouteControl.getOccupancy() {
    uint16_t uiOutstanding = (uint16_t)iFwdBufTail - (uint16_t)iFwdBufHead;
    uiOutstanding %= FWD_QUEUE_SIZE;
    return (uint8_t)uiOutstanding;
  }

  command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
    TOS_MHopMsg	 *pMHMsg = (TOS_MHopMsg *)msg->data;
    return pMHMsg->sourceaddr;
  }

  command result_t RouteControl.setUpdateInterval(uint16_t Interval) {
    return call RouteSelectCntl.setUpdateInterval(Interval);
  }

  command result_t RouteControl.manualUpdate() {
    return call RouteSelectCntl.manualUpdate();
  }

  default event void  MultiHopForward(TOS_MsgPtr pMsg){
 }


  default event TOS_MsgPtr ReceiveDataMsg.receive[uint8_t id](TOS_MsgPtr pMsg, void* payload, uint16_t payloadLen) {
     return pMsg;
  }

  default event result_t Send.sendDone[uint8_t id](TOS_MsgPtr pMsg, result_t success) {
    return SUCCESS;
  }

  default event result_t Intercept.intercept[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
							 uint16_t payloadLen) {
    return SUCCESS;
  }

  default event result_t Snoop.intercept[uint8_t id](TOS_MsgPtr pMsg, void* payload, 
                                                     uint16_t payloadLen) {
    return SUCCESS;
  }

}
