// $Id: EnOceanRadioIntM.nc,v 1.2 2005/08/15 14:53:09 hjkoerber Exp $ 

/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
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
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * @author Housam Wattar 
 *         <wattar@hsu-hh.de>
 *	   (+49)40-6541-2638/2627 
 * 
 * $Revision: 1.2 $
 * $Date: 2005/08/15 14:53:09 $ 
 *
 */

/**
 * In this Radio interface module we implemented a simple nonpersistent csma:
 *
 * 1. If there is data to be send wait some random time first (0ms -28 ms)
 * 2. Then sample the rssi value
 * 3. If the rssi is below the noise floor transmit otherwise wait again some random time (0-28 ms)
 *
 */

includes crc8;                                //for EnOcean telegrams
includes crc;
includes chksum;
includes EnOceanMsg;

module EnOceanRadioIntM{
  provides{
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
  uses{
    interface PIC18F4620Interrupt as EnOceanRF_Receive_Interrupt;
    interface StdControl as EnOceanStdControl;
    interface StdControl as TimerControl;
    interface  EnOceanRadioControl;
    interface ADCControl;
    interface ADC as RSSIADC;
    interface Timer as MacBackOffTimer;
    interface Random;
    }
}

implementation{

  void SendTask();
  task void PacketSent();
 
  bool bTxBusy;

  TOS_MsgPtr txBufptr;                        // pointer to transmit buffer
  EnOceanMsg eMsg;                            // define an EnoceanMsg object
 
  norace TOS_MsgPtr pBuf;                     // changed only in interrupt context
  TOS_Msg RxBuf;                              // define a TOS_Msg object

  norace uint16_t usRunningCRC;               // running crc variable, changed only in atomic or interrupt context
  norace uint8_t first_RX_success_flag=0;     // changed only in interrupt conte


  uint16_t usRSSIVal;
  uint16_t sMacDelay;
  uint8_t modeRxRFGain;                       // varibale for status of RxRFGain

  
  command result_t Control.init(){
    call  EnOceanStdControl.init();
  
    atomic {
      bTxBusy = FALSE;

      usRSSIVal = 0;
      sMacDelay = 0;
  
    }
    //  RxBuf.length =0;                         //needed by the first if-clause in the below function EnOceanRF_Receive_Interrupt.fired()

    call ADCControl.bindPort(TOS_ADC_RSSI_PORT,TOSH_ACTUAL_RSSI_PORT);
    call ADCControl.init();
    call Random.init();
    call TimerControl.init();
   return SUCCESS;
  }

  command result_t Control.start(){
    call  EnOceanStdControl.start();
    call  EnOceanRadioControl.RxMode();
    call TimerControl.start();
   return SUCCESS;
  }

  command result_t Control.stop(){
    call  EnOceanStdControl.stop();
    return SUCCESS;
  }

  command result_t Send.send(TOS_MsgPtr pMsg){
    result_t Result = SUCCESS; 

    
    // start atomic
    //   atomic { 
      if (bTxBusy) {
	Result = FAIL;
      }
      else {
	bTxBusy = TRUE;
        txBufptr =pMsg;
	sMacDelay = ((call Random.rand() & 0x07)<<2);// the initinial delay is a random value between 0 and 7 multiplied by four, so we will  wait 28 ms (divided by 1.024) at most                         
	call MacBackOffTimer.start(TIMER_ONE_SHOT, sMacDelay);
      }
    return Result; 
  }
                      
  async event result_t EnOceanRF_Receive_Interrupt.fired(){

    EnOcean_MsgPtr pEnOceanRxMsg; 

    uint16_t *crc_ptr;
    uint8_t i;

    if(asm_ISR_RxRadio == SUCCESS){           // start the assembler receive routine ISR_RxRadio, please refer to the perl script
      pEnOceanRxMsg = (EnOcean_MsgPtr)(((char *)&asm_rxBufptr)+7);
      if(first_RX_success_flag==0){
	pBuf=&RxBuf;
	first_RX_success_flag=1;
      }
	switch(pEnOceanRxMsg->EnOcean_6DT_RFMsg.choice) {
	case AM_EnOcean_6DT:
	  //pBuf->lengthRF = TOSH_6DT_LENGTH;
	  pBuf->addr = pEnOceanRxMsg->EnOcean_6DT_RFMsg.id;
	  pBuf->type = AM_EnOcean_6DT;
	  pBuf->group = TOS_AM_GROUP;
	  pBuf->length = TOSH_6DT_DATA_LENGTH;
	  pBuf->data[0] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.data[0];
	  pBuf->data[1] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.data[1];
	  pBuf->data[2] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.data[2];
	  pBuf->data[3] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.data[3];
	  pBuf->data[4] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.data[4];
	  pBuf->data[5] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.data[5];
          pBuf->data[6] = pEnOceanRxMsg->EnOcean_6DT_RFMsg.status;
	  //packet filtering is done at the upper layers
	  //here is just the crc-calculation done
	  pBuf->crc= blockCRC_8((uint8_t *)pEnOceanRxMsg+1,TOSH_6DT_LENGTH-1);
	  if(pBuf->crc==pEnOceanRxMsg->EnOcean_6DT_RFMsg.crc)
	    pBuf->crc = 1; //crc-check succeeded
	  break;

	case AM_EnOcean_MDA:
	  //pBuf->lengthRF = TOSH_MDA_LENGTH;
	  pBuf->addr = pEnOceanRxMsg->EnOcean_MDA_RFMsg.id;
	  pBuf->type = AM_EnOcean_MDA;
	  pBuf->group = TOS_AM_GROUP;
	  pBuf->length = TOSH_MDA_DATA_LENGTH;
          pBuf->data[0]= pEnOceanRxMsg->EnOcean_MDA_RFMsg.status;
	  //packet filtering is done at the upper layers
	  //here is just the crc-calculation done
	  pBuf->crc= blockCRC_8((uint8_t *)pEnOceanRxMsg+1,TOSH_MDA_LENGTH-1);
	  if(pBuf->crc==pEnOceanRxMsg->EnOcean_MDA_RFMsg.crc)
	    pBuf->crc = 1; //crc-check succeeded
	  break;
	  
	case AM_EnOcean_1BS:
	  pBuf->addr = pEnOceanRxMsg->EnOcean_1BS_RFMsg.id;
	  pBuf->type = AM_EnOcean_1BS;
	  pBuf->group = TOS_AM_GROUP;
	  pBuf->length = TOSH_1BS_DATA_LENGTH;
	  pBuf->data[0] = pEnOceanRxMsg->EnOcean_1BS_RFMsg.data[0];
	  pBuf->data[1] = pEnOceanRxMsg->EnOcean_1BS_RFMsg.data[1];
	  pBuf->data[2] = pEnOceanRxMsg->EnOcean_1BS_RFMsg.data[2];
          pBuf->data[3] = pEnOceanRxMsg->EnOcean_1BS_RFMsg.status;
	  if(pEnOceanRxMsg->EnOcean_1BS_RFMsg.chksum==chksum((uint8_t *)pEnOceanRxMsg+1,TOSH_1BS_LENGTH-1))
	    pBuf->crc = 1; //checksum succeeded
	  break;

	case AM_EnOcean_4BS:
	  pBuf->addr = pEnOceanRxMsg->EnOcean_4BS_RFMsg.id;
	  pBuf->type = AM_EnOcean_4BS;
	  pBuf->group = TOS_AM_GROUP;
	  pBuf->length = TOSH_4BS_DATA_LENGTH;
	  pBuf->data[0] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.data[0];
	  pBuf->data[1] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.data[1];
	  pBuf->data[2] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.data[2];
	  pBuf->data[3] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.data[3];
	  pBuf->data[4] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.data[4];
	  pBuf->data[5] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.data[5];
          pBuf->data[6] = pEnOceanRxMsg->EnOcean_4BS_RFMsg.status;
	  if(pEnOceanRxMsg->EnOcean_4BS_RFMsg.chksum==chksum((uint8_t *)pEnOceanRxMsg+1,TOSH_4BS_LENGTH-1))
	    pBuf->crc = 1; //checksum succeeded
	  break;

	case AM_EnOcean_HRC:
	  pBuf->addr = pEnOceanRxMsg->EnOcean_HRC_RFMsg.id;
	  pBuf->type = AM_EnOcean_HRC;
	  pBuf->group = TOS_AM_GROUP;
	  pBuf->length = TOSH_HRC_DATA_LENGTH;
	  pBuf->data[0] = pEnOceanRxMsg->EnOcean_HRC_RFMsg.data[0];
	  pBuf->data[1] = pEnOceanRxMsg->EnOcean_HRC_RFMsg.data[1];
	  pBuf->data[2] = pEnOceanRxMsg->EnOcean_HRC_RFMsg.data[2];
          pBuf->data[3] = pEnOceanRxMsg->EnOcean_HRC_RFMsg.status;
	  if(pEnOceanRxMsg->EnOcean_HRC_RFMsg.chksum==chksum((uint8_t *)pEnOceanRxMsg+1,TOSH_HRC_LENGTH-1))
	    pBuf->crc = 1; //checksum succeeded
	  break;

	case AM_EnOcean_RPS:
	  pBuf->addr = pEnOceanRxMsg->EnOcean_RPS_RFMsg.id;
	  pBuf->type = AM_EnOcean_RPS;
	  pBuf->group = TOS_AM_GROUP;
	  pBuf->length = TOSH_RPS_DATA_LENGTH;
	  pBuf->data[0] = pEnOceanRxMsg->EnOcean_RPS_RFMsg.data[0];
	  pBuf->data[1] = pEnOceanRxMsg->EnOcean_RPS_RFMsg.data[1];
	  pBuf->data[2] = pEnOceanRxMsg->EnOcean_RPS_RFMsg.data[2];
          pBuf->data[3] = pEnOceanRxMsg->EnOcean_RPS_RFMsg.status;
	  if(pEnOceanRxMsg->EnOcean_RPS_RFMsg.chksum==chksum((uint8_t *)pEnOceanRxMsg+1,TOSH_RPS_LENGTH-1))
	    pBuf->crc = 1; //checksum succeeded
	  break;
	  
	case TOSH_TOS_CHOICE:       
	  pBuf->addr = pEnOceanRxMsg->EnOcean_TOS_RFMsg.addr;	 
	  pBuf->type = pEnOceanRxMsg->EnOcean_TOS_RFMsg.type;
	  pBuf->group = pEnOceanRxMsg->EnOcean_TOS_RFMsg.group;
	  pBuf->length = pEnOceanRxMsg->EnOcean_TOS_RFMsg.length;
	  for(i=0;i<pBuf->length;i++){
	    pBuf->data[i]=pEnOceanRxMsg->EnOcean_TOS_RFMsg.data[i];
	  }
	  //packet filtering is done at the upper layers
	  //here is just the crc-calculation done
	  usRunningCRC =0;
	  for(i=0;i<(pEnOceanRxMsg->EnOcean_TOS_RFMsg.lengthRF)-2;i++){
	    usRunningCRC = crcByte(usRunningCRC,*(((uint8_t *)(pEnOceanRxMsg)+1+i))); //+1 because the lengthRF byte is actually not transmitted thus not part of the calculation
	  }
      
	  crc_ptr=(uint16_t *)((uint8_t *)pEnOceanRxMsg+pEnOceanRxMsg->EnOcean_TOS_RFMsg.lengthRF-1); 
	  if(*crc_ptr==usRunningCRC)
	    pBuf->crc = 1; //crc-check succeeded
          
	  pBuf->strength = ((TOS_MsgPtr )((uint8_t *)(pEnOceanRxMsg)+2))->strength;     
	  break;
	default: 
	  return FAIL;
	  // end of switch/case
	}  
	//}  

      pBuf = signal Receive.receive(pBuf); //signal returns the new receive message pointer
    }  

 
    INTCONbits_RBIF = 0;
    return SUCCESS; //return to isr
}


/**
 * Here we analyze the rrsi samples, i.e. we conduct carrier sense.
 * The noise levels in either RXRFGain modes are actual measurement results. 
 */
async event result_t RSSIADC.dataReady(uint16_t data) {
 atomic {
    usRSSIVal = data;   
 }
 modeRxRFGain= (uint8_t) call EnOceanRadioControl.GetRFGain();
 switch(modeRxRFGain){
 case 0: // i.e. low rxRFGain
   if(usRSSIVal<0xcc){                // 0xcc is noise level in low sensitivity mode
   SendTask();
 }
   else goto Delay;                   // channel is not free thus back off some random time
   break;
 case 1: // i.e. high rxRFGain
 if(usRSSIVal<0x136){                 // 0x0136 is noise level in high sensitivity mode
   SendTask();
 }
 else goto Delay;                     // channel is not free thus back off some random time
   break;
 default:
 Delay:;
      sMacDelay = ((call Random.rand() & 0x07)<<2);// the  delay is a random value between 0 and 15 multiplied by four, so we will  wait 28 ms (divided by 1.024) at most                    
      call MacBackOffTimer.start(TIMER_ONE_SHOT, sMacDelay);
   break;
 }
 return SUCCESS;
}

event result_t MacBackOffTimer.fired(){
  call RSSIADC.getData();             // let's do carrier sense before transmitting
  return SUCCESS;
}

void SendTask(){
  uint8_t i;
  uint16_t *crc_ptr;
  call  EnOceanRadioControl.TxMode();
  TOSH_uwait(90);

  switch(txBufptr->type) {
  case AM_EnOcean_6DT:
    eMsg.EnOcean_6DT_RFMsg.lengthRF = TOSH_6DT_LENGTH;
    eMsg.EnOcean_6DT_RFMsg.choice = txBufptr->type; 
    eMsg.EnOcean_6DT_RFMsg.data[0]= txBufptr->data[0];    
    eMsg.EnOcean_6DT_RFMsg.data[1]= txBufptr->data[1]; 	           
    eMsg.EnOcean_6DT_RFMsg.data[2]= txBufptr->data[2]; 
    eMsg.EnOcean_6DT_RFMsg.data[3]= txBufptr->data[3]; 
    eMsg.EnOcean_6DT_RFMsg.data[4]= txBufptr->data[4]; 
    eMsg.EnOcean_6DT_RFMsg.data[5]= txBufptr->data[5]; 
    eMsg.EnOcean_6DT_RFMsg.id = txBufptr->addr;
    eMsg.EnOcean_6DT_RFMsg.status = txBufptr->data[6];
    eMsg.EnOcean_6DT_RFMsg.crc = blockCRC_8((uint8_t *)&eMsg+1,TOSH_6DT_LENGTH-1);
    
    FSR0_register = (uint16_t)&eMsg;            //typecast 16-bitpointer to int so that address of pMsg fits into FSR0, which consists of 2 bytes namely FSR0L and FSR0H
    break;
  case AM_EnOcean_MDA:
    eMsg.EnOcean_MDA_RFMsg.lengthRF = TOSH_MDA_LENGTH;
    eMsg.EnOcean_MDA_RFMsg.choice = txBufptr->type; 
    eMsg.EnOcean_MDA_RFMsg.id = txBufptr->addr;
    eMsg.EnOcean_MDA_RFMsg.status = txBufptr->data[0];
    eMsg.EnOcean_MDA_RFMsg.crc = blockCRC_8((uint8_t *)&eMsg+1,TOSH_MDA_LENGTH-1);
	  
    FSR0_register = (uint16_t)&eMsg;            //typecast 16-bitpointer to int so that address of pMsg fits into FSR0, which consists of 2 bytes namely FSR0L and FSR0H
    break;
    
  default:        
    usRunningCRC =0;
    eMsg.EnOcean_TOS_RFMsg.lengthRF=(txBufptr->length)+(offsetof(struct EnOcean_TOS_RFMsg ,data)-1) + sizeof(uint16_t);
    eMsg.EnOcean_TOS_RFMsg.choice = TOSH_TOS_CHOICE;
    eMsg.EnOcean_TOS_RFMsg.addr= txBufptr->addr;
    eMsg.EnOcean_TOS_RFMsg.type= txBufptr->type;
    eMsg.EnOcean_TOS_RFMsg.group= txBufptr->group;
    eMsg.EnOcean_TOS_RFMsg.length= txBufptr->length;
    for(i=0;i<txBufptr->length;i++){
      eMsg.EnOcean_TOS_RFMsg.data[i]= txBufptr->data[i];
    }
    
    for(i=1;i<( eMsg.EnOcean_TOS_RFMsg.lengthRF)-1;i++){// i = 1 because the lengthRF byte is actually not transmitted thus not part of the calculation	  
      usRunningCRC = crcByte(usRunningCRC, *((uint8_t *)&eMsg.EnOcean_TOS_RFMsg + i));
    }
    crc_ptr=(uint16_t *)((uint8_t *)&eMsg.EnOcean_TOS_RFMsg + eMsg.EnOcean_TOS_RFMsg.lengthRF-1);
    *crc_ptr= usRunningCRC;	   
    
    FSR0_register = (uint16_t)&eMsg;            //typecast 16-bitpointer to int so that address of pMsg fits into FSR0, which consists of 2 bytes namely FSR0L and FSR0H
    
    // end of switch
  }
  
  asm_TX_SendMessage = 1;                       //start the assembler transmit routine "TX_SendMessage();", please refer to the perl script
  
  post PacketSent();   
  call  EnOceanRadioControl.RxMode();

}



 task void PacketSent() {
   TOS_MsgPtr pMsg;                          //store buffer on stack 
   atomic{
     pMsg = txBufptr;
   }   
   signal Send.sendDone(pMsg,SUCCESS);
   atomic bTxBusy = FALSE;
 }





 default event TOS_MsgPtr  Receive.receive (TOS_MsgPtr ptr){return ptr;}

}



