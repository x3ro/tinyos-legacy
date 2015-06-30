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

/* Authors:   Kamin Whitehouse
 *
 */

module ChipconRSSIM {
 provides interface StdControl;
// uses interface StdControl as TimerControl;
 uses interface SendMsg as SendDataOverviewMsg;
 uses interface SendMsg as SendDataMsg;
 uses interface SendMsg as SendChirpMsg;
 uses interface ReceiveMsg as ReceiveChirpMsg;
 uses interface ReceiveMsg as ReceiveChirpCommandMsg;
 uses interface ReceiveMsg as ReceiveDataRequestMsg;
 uses interface RadioCoordinator;
 uses interface ADC;
 uses interface Clock;
 uses interface CC1000Control;
// ouses interface Timer;
 uses interface Leds;
}
implementation {
  // uint32_t timerPeriod;
  uint16_t numberOfChirps; //the number of times a node is told to chirp

  uint16_t transmitter; //the node that is currently sending messages
			//used when reporting rssi values of that
			//transmitter, and for resetting msgCnt to
			//zero when a new transmitter starts sending.
			//CHANGE: this will be stored in MsgNum and
			//otherwise not used.
  uint16_t receiverAction; //what the receiver should do with Rssi
			   //data (sent originally in chirpCmd message
			   //and forward to receivers in the chirp
			   //itself)
  uint16_t msgNumber; //the number of the current chirp that this node
		      //is sending

 uint8_t state;
 uint8_t chirped; //indicates if this node chirped at all
 uint8_t collected; //indicates if data in rssi has been
		    //collected at all
 uint8_t goToIdle; //indicates if state should go to idle because we are collecting a single data point

 uint16_t rssi[MAX_RSSI_MSGS][NUM_RSSI_PER_MSG]; //table of rssi
						 //values.  CHANGE:
						 //this will hold each
						 //node in the rows
						 //and a single rssi
						 //value from each of
						 //its messages in the colums
 uint8_t msgNumbers[MAX_RSSI_MSGS]; //the number of the chirp message
				    //that the data in this row of the
				    //rssi table came from CHANGE:
				    //this will hold the number of the
				    //node who's rssi values are in
				    //that row of the RSSI table
 uint8_t msgCnt; //the number of rssi messages received from this
		 //transmitter so far.  CHANGE: the number of nodes
		 //that RSSI was collected from so far
 uint8_t avgCnt; //NEW:this holds the column index in the rssi table.
 uint8_t msgSendingIndex;  //index of the rssi message that is
			   //currently being reported

 uint16_t newRssi[NUM_RSSI_PER_MSG]; //a temporary table that holds
				     //the 10 rssi readings for the
				     //message being received currently
 uint8_t newRssiCnt; //the number of rssi readings so far taken from
		     //current incoming packet

 TOS_Msg msg;
 ChirpMsg *chirpMsg;
 ChirpCommandMsg *chirpCommandMsg;
 DataMsg* dataMsg;
 DataOverviewMsg *dataOverviewMsg;
 DataRequestMsg *dataRequestMsg;

  command result_t StdControl.init()
  {
    atomic{
      state=IDLE;
    }
    numberOfChirps=0;
    atomic{
      newRssiCnt=0;
      chirped=0;
      collected=0;
      goToIdle=0;
    }
    msgCnt=0;
    avgCnt=0;
    msgSendingIndex=0;
    msgNumber=1;
//    call TimerControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    //this is for chirp-only nodes
    call Leds.redOff();
/*    call TimerControl.start();*/
    atomic{
      state=IDLE;
    }
    numberOfChirps=65535;
    //    timerPeriod= 200;
    msgNumber=1;
    receiverAction=BCAST_DATA;
/*    call Timer.start(TIMER_REPEAT, timerPeriod);*/
    return call Clock.setRate(TOS_I16PS, TOS_S16PS);
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
//    call Timer.stop();
//    call TimerControl.stop();
    call Leds.redOff();
    return SUCCESS;
  }

  async event result_t ADC.dataReady(uint16_t Rssi)
  {
    call Leds.yellowToggle();
    atomic{
      if(newRssiCnt<NUM_RSSI_PER_MSG)
	 newRssi[newRssiCnt++]=Rssi;
    }
    return SUCCESS;
  }

  task void sendNextRSSI()
  {
    uint16_t i;
    if(state!=RETURNING_RSSI_DATA) return;
    if(goToIdle>0) {
      atomic state=IDLE;
      goToIdle=0;
    }
    if( msgSendingIndex>=msgCnt )
    {
        atomic{
	  state=IDLE;
	}
	return;
    }
    dataMsg=(DataMsg*)(&(msg.data));
    dataMsg->transmitterId=transmitter;
    dataMsg->receiverId=TOS_LOCAL_ADDRESS;
    dataMsg->msgNumber=msgNumbers[msgSendingIndex];
    dataMsg->msgIndex=msgSendingIndex;
    dataMsg->rfPower=call CC1000Control.GetRFPower();
    for(i=0;i<NUM_RSSI_PER_MSG;i++)
    {
	dataMsg->rssi[i]=rssi[msgSendingIndex][i];
    }
    if(call SendDataMsg.send(receiverAction, LEN_DATAMSG,&msg)==SUCCESS){
	call Leds.redOn();
    	msgSendingIndex++;
    }
  }

  event TOS_MsgPtr ReceiveChirpMsg.receive(TOS_MsgPtr m)
  {
    uint8_t i;
    uint16_t total;
    call Leds.redOn();
    atomic{
      state=COLLECTING_RSSI_DATA;
    }
    if(collected==1){
      atomic{
	collected=0;
	msgCnt=0;
	avgCnt=0;
      }
    }
  
    chirpMsg=(ChirpMsg*)(&(m->data));
    switch(chirpMsg->receiverAction)
    {
	case SIGNAL_RANGING_INTERRUPT: break;
	case STORE_TO_EEPROM:
	{
	    if(transmitter!=chirpMsg->transmitterId)
	    {
			transmitter=chirpMsg->transmitterId;
			if( (msgCnt!=0) || ( (msgCnt==0) && (avgCnt !=0) ) ){
				for(i=avgCnt; i<NUM_RSSI_PER_MSG; i++){
					rssi[msgCnt][i]=0;
				}
				msgCnt++;
			}
			avgCnt=0;
		}
	    if(avgCnt>=NUM_RSSI_PER_MSG){
	      msgCnt++;
	      avgCnt=0;
	    }
	    if(msgCnt<MAX_RSSI_MSGS)
	    {
	      msgNumbers[msgCnt]=chirpMsg->transmitterId;
	      //if saving to eeprom, store the average
		total=0;
	      atomic{
		for(i=0;i<newRssiCnt;i++)
		  {
		    total+=newRssi[i];
		  }
	      }
	      atomic rssi[msgCnt][avgCnt++]=total/newRssiCnt;
//	      rssi[msgCnt][avgCnt++]=newRssi[8];
	    }
   	    break;
 	}
	default:
	{
	    call Leds.greenToggle();
	    dataMsg=(DataMsg*)(&(msg.data));
	    dataMsg->transmitterId=chirpMsg->transmitterId;
	    dataMsg->receiverId=TOS_LOCAL_ADDRESS;
	    dataMsg->msgNumber=chirpMsg->msgNumber;
	    dataMsg->msgIndex=0;
	    dataMsg->rfPower=call CC1000Control.GetRFPower();
	    //if sending over radio immediately, send every sample
	    for(i=0;i<NUM_RSSI_PER_MSG;i++)
	    {
	      atomic{
		if(i<newRssiCnt)
		  dataMsg->rssi[i]=newRssi[i];
		else
		  dataMsg->rssi[i]=0;
	      }
	    }
	    if(call SendDataMsg.send(chirpMsg->receiverAction, LEN_DATAMSG,&msg)==SUCCESS){ 	call Leds.redOn();}
	    atomic{
	      state=IDLE;
	    }
   	    break;
	}
      }
      call Leds.redOff();
      return m;
  }

  event TOS_MsgPtr ReceiveChirpCommandMsg.receive(TOS_MsgPtr m)
  {
    call Leds.redOn();
    chirpCommandMsg=(ChirpCommandMsg*)(&(m->data));
    numberOfChirps = chirpCommandMsg->numberOfChirps;
    
    if(chirpCommandMsg->transmitterId==TOS_LOCAL_ADDRESS)
      {
	if(chirpCommandMsg->startStop==1) {
	  atomic{
	    state=CHIRPING;
	  }
	  }
	else{
	  atomic{
	    state=IDLE;
	  }
	  call Leds.redOff();
	  return m;
	}
	//      timerPeriod= chirpCommandMsg->timerPeriod;
	call CC1000Control.SetRFPower(chirpCommandMsg->rfPower);
	receiverAction= chirpCommandMsg->receiverAction;
	if(chirped==0){
	  chirped=1;
	  msgNumber=1;
	  //	call Timer.start(TIMER_REPEAT, timerPeriod);
	  call Leds.greenToggle();
	}
      }
    else
      {
	/*        atomic{
		  state=COLLECTING_RSSI_DATA;
		  }
		  transmitter=chirpCommandMsg->transmitterId;
		  for(i=avgCnt; i<NUM_RSSI_PER_MSG; i++){
		  rssi[msgCnt][i]=0;
		  }
		  msgCnt++;
		  avgCnt=0;*/
      }
    call Leds.redOff();
    return m;
  }

  async event void RadioCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff)
  {
    newRssiCnt=0;
  }

  async event void RadioCoordinator.blockTimer(){}

  async event void RadioCoordinator.byte(TOS_MsgPtr m, uint8_t byteCount)
  {
    if(newRssiCnt<NUM_RSSI_PER_MSG)
	call ADC.getData();
  }

  event TOS_MsgPtr ReceiveDataRequestMsg.receive(TOS_MsgPtr m)
  {
    uint8_t i;
    dataRequestMsg = (DataRequestMsg*)(&(m->data));
    if(dataRequestMsg->startStop==1){
      atomic{
	state=RETURNING_RSSI_DATA;
      }
    }
    else {
      atomic{
	state=IDLE;
      }
      return m;
    }

    if(collected==0){ //make sure that the last row is collected and that its data is not old
      for(i=avgCnt; i<NUM_RSSI_PER_MSG; i++){
	rssi[msgCnt][i]=0;
      }
      atomic{
		  msgCnt++;
		  collected=1;
		  chirped=0;
      }
    }

    call CC1000Control.SetRFPower(255);
    dataMsg=(DataMsg*)(&(msg.data));
    dataMsg->transmitterId=transmitter;
    dataMsg->receiverId=TOS_LOCAL_ADDRESS;
   
    switch(dataRequestMsg->typeOfData)
    {
 	case OVERVIEW:
	{
	  dataOverviewMsg=(DataOverviewMsg*)(&(msg.data));
 	  dataOverviewMsg->msgCnt=msgCnt;
	  dataOverviewMsg->rfPower=call CC1000Control.GetRFPower();
	  if(call SendDataOverviewMsg.send(dataRequestMsg->receiverAction, LEN_DATAOVERVIEWMSG, &msg)==SUCCESS){	call Leds.redOn();}
	  atomic{
	    state=IDLE;
	  }
	  break;
	}
	case SOME_RSSI:
	{
	  msgSendingIndex=dataRequestMsg->msgIndex;
	  receiverAction=dataRequestMsg->receiverAction;
	  post sendNextRSSI();
	  atomic{
	    goToIdle=1;
	  }
	  
	  break;
	}
	case ALL_RSSI:
	{
	  msgSendingIndex=dataRequestMsg->msgIndex;
	  //	  timerPeriod=dataRequestMsg->timerPeriod;
	  receiverAction=dataRequestMsg->receiverAction;
//	  call Timer.start(TIMER_REPEAT, timerPeriod);
	  break;
	}
	default:
	{
	}
    }
    return m;
  }

  event result_t SendChirpMsg.sendDone(TOS_MsgPtr m, result_t success)
  {
    call Leds.redOff();
    return SUCCESS;
  }

  event result_t SendDataMsg.sendDone(TOS_MsgPtr m, result_t success)
  {
    call Leds.redOff();
    return SUCCESS;
  }

  event result_t SendDataOverviewMsg.sendDone(TOS_MsgPtr m, result_t success)
  {
    call Leds.redOff();
    return SUCCESS;
  }

  task void chirp()
  {
//	uint8_t power= call CC1000Control.GetRFPower();
	if(state!=CHIRPING) return;
//        call CC1000Control.SetRFPower(0x01);
	if( msgNumber>numberOfChirps){
	  atomic{
	    state=IDLE;
	    }
	}
	else{
		chirpMsg = (ChirpMsg*)(&(msg.data));
		chirpMsg->transmitterId=TOS_LOCAL_ADDRESS;
		chirpMsg->receiverAction=receiverAction;
		chirpMsg->msgNumber=msgNumber++;
		chirpMsg->rfPower=call CC1000Control.GetRFPower();
		if(call SendChirpMsg.send(TOS_BCAST_ADDR, LEN_CHIRPMSG, &msg)==SUCCESS){          call Leds.redOn();}
//        call CC1000Control.SetRFPower(power);
	}
  }

  async event result_t Clock.fire()
//  event result_t Timer.fired()
  {
    call Leds.yellowToggle();
     if(state==RETURNING_RSSI_DATA) {    
        post sendNextRSSI();
     }
     else if(state==CHIRPING) {  
	post chirp();
     }
     else{ 
//	call Timer.stop(); 
	call Leds.redOff();
     }
     return SUCCESS;
  }


}








