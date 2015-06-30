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
 *	      Michael Manzo
 *
 */

module TelosRssiM {
 provides interface StdControl;
 uses interface StdControl as TimerControl; // uncommented -mpm
 uses interface SendMsg as SendDataOverviewMsg;
 uses interface SendMsg as SendDataMsg;
 uses interface SendMsg as SendChirpMsg;
 uses interface ReceiveMsg as ReceiveChirpMsg;
 uses interface ReceiveMsg as ReceiveChirpCommandMsg;
 uses interface ReceiveMsg as ReceiveDataRequestMsg;
 //uses interface RadioCoordinator; not necessary on telos -mpm
 //uses interface ADC; not needed on telos -mpm
 //uses interface Clock; not necessary on telos -mpm
 //uses interface CC1000Control; // switched to abstract the CC*Control and replaced throughout -mpm
 //uses interface CC1000Control as CCControl; 
 uses interface CC2420Control as CCControl;
 uses interface Timer; // uncommented -mpm
 uses interface Leds;

// uses interface AllocationReq;
// uses interface WriteData;
// uses interface ReadData;

}
implementation {
  uint32_t timerPeriod; // uncommented -mpm
  uint16_t numberOfChirps; //the number of times a node is told to chirp

  int displayCount;

  uint16_t transmitter; //the node that is currently sending messages
			//used when reporting rssi values of that
			//transmitter, and for resetting msgCnt to
			//zero when a new transmitter starts sending.
			//CHANGE: this will be stored in MsgNum and
			//otherwise not used.
			// the latter seems correct, but he means msgNumbers not MsgNum.  and it's used to keep track of 
			// who's sending when the rssi is being rx.  it's also used to tag the reports when 
			// sending reports as the chirps are received-mpm
  uint16_t receiverAction; //what the receiver should do with Rssi
			   //data (sent originally in chirpCmd message
			   //and forward to receivers in the chirp
			   //itself)
			   // where is it sent now? -mpm
  uint16_t msgNumber; //the number of the current chirp that this node
		      //is sending

 uint8_t state;
 uint8_t chirped; //indicates if this node chirped at all
 uint8_t collected; //indicates if data in rssi has been
		    //collected at all
 uint8_t goToIdle; //indicates if state should go to idle because we are collecting a single data point

 uint8_t rssi[MAX_MSGS][NUM_RSSI_PER_MSG]; 
 uint8_t lqi[MAX_MSGS][NUM_LQI_PER_MSG]; // we have lqi on telos in addition to rssi
 //uint16_t rssi[MAX_RSSI_MSGS][NUM_RSSI_PER_MSG]; //table of rssi
						 //values.  CHANGE:
						 //this will hold each
						 //node in the rows
						 //and a single rssi
						 //value from each of
						 //its messages in the colums
						 // the latter seems to be correct -mpm
 uint8_t msgNumbers[MAX_MSGS]; //the number of the chirp message
				    //that the data in this row of the
				    //rssi table came from CHANGE:
				    //this will hold the number of the
				    //node who's rssi values are in
				    //that row of the RSSI table
				    // the latter definition seems to be correct -mpm
 uint8_t msgCnt; //the number of rssi messages received from this
		 //transmitter so far.  CHANGE: the number of nodes
		 //that RSSI was collected from so far
		 // the latter definition seems correct -mpm
 uint8_t avgCnt; //NEW:this holds the column index in the rssi table.
		 // avgCnt is misnamed since we don't take avgs on telos.  it should be rssiCnt or something -mpm
 uint8_t msgSendingIndex;  //index of the rssi message that is
			   //currently being reported

 // newRssi and newRssiCnt aren't necessary on the telos b/c we just get one rssi per msg,
 // so I've commented them out throughout -mpm
 // uint16_t newRssi[NUM_RSSI_PER_MSG]; //a temporary table that holds
				     //the 10 rssi readings for the
				     //message being received currently
 // uint8_t newRssiCnt; //the number of rssi readings so far taken from
		     //current incoming packet

 TOS_Msg msg;
 ChirpMsg *chirpMsg;
 ChirpCommandMsg *chirpCommandMsg;
 DataMsg* dataMsg;
 DataOverviewMsg *dataOverviewMsg;
 DataRequestMsg *dataRequestMsg;

  command result_t StdControl.init()
  {
    displayCount = 0;
    atomic{
      state=IDLE;
    }
    numberOfChirps=0;
    atomic{
      // newRssiCnt=0; -mpm
      chirped=0;
      collected=0;
      goToIdle=0;
    }
    msgCnt=0;
    avgCnt=0;
    msgSendingIndex=0;
    msgNumber=1;
//    call AllocationReq.request(20); // asked for 20 bytes to log the data -mpm
    call TimerControl.init(); // uncommented, but is this line necessary? -mpm
    return SUCCESS;
  }

/*
  event result_t AllocationReq.requestProcessed(result_t success) {
	if (success == SUCCESS) {
	  call Leds.greenToggle();
	}
	return success;
  }

  event result_t WriteData.writeDone(uint8_t *data, uint32_t numBytesWrite, result_t success) {
	if (success == SUCCESS) {
	  //call Leds.redToggle();
	} else {
	  //call Leds.yellowToggle();
	}
   	return success;
  }

  event result_t ReadData.readDone(uint8_t* buffer, uint32_t numBytesRead, result_t success) {
	if (success == SUCCESS) {
	  call Leds.redToggle();
	  eeprom=buffer;
	} else {
	  call Leds.yellowToggle();
	}
   	return success;
  }
*/

  command result_t StdControl.start()
  {
    //this is for chirp-only nodes    //call Leds.redOff();
    call TimerControl.start(); // uncommented.  is this even necessary, though? -mpm
    atomic{
      state=IDLE;
    }
    numberOfChirps=65535;
    timerPeriod= INITIAL_TIMER_PERIOD; // uncommented and aliased -mpm
    msgNumber=1;
    receiverAction=BCAST_DATA; // this falls under "default" in ReceiveChirpMsg below -mpm
    call Timer.start(TIMER_REPEAT, timerPeriod); // you could only run the tx when you're tx, but why not just run it 
						 // all the time and check whether you're currently transmitting before
 						 // you go and chirp when the timer fires? the latter seems easier -mpm
    //return call Clock.setRate(TOS_I16PS, TOS_S16PS); // commented -mpm
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    //return call Clock.setRate(TOS_I0PS, TOS_S0PS); commented -mpm
    call Timer.stop(); // uncommented -mpm
    call TimerControl.stop(); // uncommented, but is this necessary? -mpm
    //call Leds.redOff();
    return SUCCESS;
  }

/* we don't use this on the telos.  we get the rssi from the tosmsg. -mpm
  async event result_t ADC.dataReady(uint16_t Rssi)
  {
    call Leds.yellowToggle();
    atomic{
      if(newRssiCnt<NUM_RSSI_PER_MSG)
	 newRssi[newRssiCnt++]=Rssi;
    }
    return SUCCESS;
  }
*/

  task void sendNextRSSI()
  {
    uint16_t i;
    if(state!=RETURNING_RSSI_DATA) return;
    if(goToIdle>0) { // this would be set to 1 if we weren't going to transmit all the data for the requested node -mpm
      atomic state=IDLE;
      goToIdle=0;
    }
    if( msgSendingIndex>=msgCnt ) // this stops the sending at the end of msgs that we actually have, namely when we 
				  // get to the last row in rssi that we've actually filled in -mpm
    {
        atomic{
	  state=IDLE;
	}
	return;
    }
    dataMsg=(DataMsg*)(&(msg.data));
    dataMsg->transmitterId=transmitter; // where does transmitter get incremented/changed? in ReceiveChirpMsg only.  
					// this is because it's assumed that the nodes send back their readings 
					// before the next node starts chirping  -mpm
    dataMsg->receiverId=TOS_LOCAL_ADDRESS;
    dataMsg->msgNumber=msgNumbers[msgSendingIndex]; // this is the node that tx the rssi values we're sending.  
						    // It's called msgNumber b/c when we send the rssi back right away 
						    // instead of storing it sending later, this field indicates the 
						    // msgNumber -mpm
    dataMsg->msgIndex=msgSendingIndex; // this is just the number of the DataMsg in rssi that we're currently 
				       // sending out -mpm
    dataMsg->rfPower=call CCControl.GetRFPower();
    for(i=0;i<NUM_RSSI_PER_MSG;i++) 
    {
	//dataMsg->rssi[i]=rssi[msgSendingIndex][i];
	dataMsg->rssi[i]=rssi[msgSendingIndex][i];  // this is for telos -mpm
	dataMsg->lqi[i]=lqi[msgSendingIndex][i]; 
	//dataMsg->rssi[i]=eeprom[i*2];  // this is for telos -mpm
	//dataMsg->lqi[i]=eeprom[i*2+1]; 
    }
    if(call SendDataMsg.send(receiverAction, LEN_DATAMSG,&msg)==SUCCESS){ // why is the dest addr == receiverAction? -mpm
	//call Leds.redToggle();
    	msgSendingIndex++;
    }
  }

  event TOS_MsgPtr ReceiveChirpMsg.receive(TOS_MsgPtr m)
  {
    uint8_t i;
    uint16_t total;
    atomic{
      state=COLLECTING_RSSI_DATA;
    }
    if(collected==1){ // msgCnt can't be reset when collected is set to 1 b/c sendNextRSSI needs to use it.  I think 
		      // avgCnt could be, but whatev.  -mpm
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
	    if(transmitter!=chirpMsg->transmitterId) // if I'm getting chirps from somebody besides 
						     // the currently designated transmitter then we 
						     // start filling in the next row in rssi -mpm
	    {
			transmitter=chirpMsg->transmitterId;
			if( (msgCnt!=0) || ( (msgCnt==0) && (avgCnt !=0) ) ){  // if we've advanced to a higher number 
									       // node or we've received at least one 
									       // message from the first node -mpm
				for(i=avgCnt; i<NUM_RSSI_PER_MSG; i++){  // zero out the rest of the rssi spaces for
									 // the previous node since we've finished 
									 // receiving from that node -mpm 
					rssi[msgCnt][i]=0;
				}
				msgCnt++; // advance to the next node -mpm
			}
			avgCnt=0; 
	    }
	    if(avgCnt>=NUM_RSSI_PER_MSG){ // this would happen if you had more readings than could fit in a single 
					  // DataMsg.  But the code in -mpm
	      msgCnt++;
	      avgCnt=0;
	    }
	    if(msgCnt<MAX_MSGS) // if we haven't received the max number of messages
				     // (remember this is a cap on DataMsgs we will store, 
				     // not nodes, since we can have more than one DataMsg for each node)  -mpm
	    {
	      msgNumbers[msgCnt]=chirpMsg->transmitterId;
	      //if saving to eeprom, store the average
		total=0;
	      /* not needed on telos 
	      atomic{ 
		for(i=0;i<newRssiCnt;i++)
		  {
		    total+=newRssi[i];
		  }
	      } */
	      atomic rssi[msgCnt][avgCnt]=m->strength; // the rssi and lqi are stashed on the tosmsg on telos -mpm
	      atomic lqi[msgCnt][avgCnt]=m->lqi;
	      //call WriteData.write(msgCnt*NUM_RSSI_PER_MSG+avgCnt, m->strength, 1); // logging the data -mpm
              //call WriteData.write(msgCnt*NUM_RSSI_PER_MSG+avgCnt, m->lqi, 1); // logging the data -mpm	
	      avgCnt++;  
	      // atomic rssi[msgCnt][avgCnt++]=total/newRssiCnt; // the avg is only calculated after the next msg is 
							      // received? ugly! is the avg for the last msg received 
							      // lost then?  no, that's taken care of in 
							      // ReceiveDataRequestMsg -mpm
//	      rssi[msgCnt][avgCnt++]=newRssi[8];
	    }
   	    break;
 	}
	default:
	{
	    dataMsg=(DataMsg*)(&(msg.data));
	    dataMsg->transmitterId=chirpMsg->transmitterId;
	    dataMsg->receiverId=TOS_LOCAL_ADDRESS;
	    dataMsg->msgNumber=chirpMsg->msgNumber; 
	    dataMsg->msgIndex=0; // this keeps track on the what is this? -mpm
	    dataMsg->rfPower=call CCControl.GetRFPower();
	    //if sending over radio immediately, send every sample
	    /* not correct for telos
	    for(i=0;i<NUM_RSSI_PER_MSG;i++)
	    {
	      atomic{
		if(i<newRssiCnt)
		  dataMsg->rssi[i]=newRssi[i];
		else
		  dataMsg->rssi[i]=0;
	      }
	    } */
	    dataMsg->rssi[0] = m->strength; // the rssi and lqi are stashed on the tosmsg on telos -mpm
	    dataMsg->lqi[0] = m->strength; // the rssi and lqi are stashed on the tosmsg on telos -mpm	
	    if(call SendDataMsg.send(chirpMsg->receiverAction, LEN_DATAMSG,&msg)==SUCCESS){ // why is the dest addr 
											    // == receiverAction? -mpm	
		//call Leds.redOn();
	    }
	    atomic{
	      state=IDLE;
	    }
   	    break;
	}
      }
      return m;
  }

  event TOS_MsgPtr ReceiveChirpCommandMsg.receive(TOS_MsgPtr m)
  {
    chirpCommandMsg=(ChirpCommandMsg*)(&(m->data));
    numberOfChirps = chirpCommandMsg->numberOfChirps; // this is the number of chirps that this node should tx  -mpm
    
    /* debugging junk -mpm
    if (displayCount == 5) {
      call Leds.set(chirpCommandMsg->transmitterId >> 13);
      displayCount = 0;
    } else {
      call Leds.set(chirpCommandMsg->transmitterId >> (3*displayCount));
      displayCount++;
    } */
    if(chirpCommandMsg->transmitterId==TOS_LOCAL_ADDRESS) {
	if(chirpCommandMsg->startStop==1) { // ugly.  alias this.  1 == start? -mpm
	  atomic{
	    state=CHIRPING;
	  }
	} else {
	  atomic{
	    state=IDLE;
	  }
	  return m;
	}
	//      timerPeriod= chirpCommandMsg->timerPeriod;
	call CCControl.SetRFPower(chirpCommandMsg->rfPower);
	receiverAction= chirpCommandMsg->receiverAction;  // this will be sent to the rx nodes when this node tx -mpm
	if(chirped==0){ 
	  chirped=1;
	  msgNumber=1;
	  //	call Timer.start(TIMER_REPEAT, timerPeriod); // I don't start the timer here.  I just run it all the time 							       // and check before I send on each Timer.fired event -mpm
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
    return m;
  }

/* not needed on telos
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
*/

  event TOS_MsgPtr ReceiveDataRequestMsg.receive(TOS_MsgPtr m)
  {
    uint8_t i;
    dataRequestMsg = (DataRequestMsg*)(&(m->data));
    if(dataRequestMsg->startStop==1){ // again, ugly.  alias this.  1 == start?
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
		      // we have to worry about this b/c we don't calculate the avg until the next message is rx -mpm
      for(i=avgCnt; i<NUM_RSSI_PER_MSG; i++){ 
	rssi[msgCnt][i]=0;
      } 
      atomic{
	msgCnt++; 
	collected=1;
	chirped=0;
      }
    }

    call CCControl.SetRFPower(MAX_RF_POWER);
    dataMsg=(DataMsg*)(&(msg.data)); 
    dataMsg->transmitterId=transmitter; // why are you setting transmitter to this? 
					// it should be the node id for the transmitter of the first data set 
					// we're going to send, no? is this field ignored by the matlab script?
					// or are you interested in the last node that transmitted to this node?
					// that makes sense if the nodes report after receiving from one node. 
					// in any case, DataMsg and DataOverviewMsg share the trasmitterId and 
					// receiverId fields -mpm
    dataMsg->receiverId=TOS_LOCAL_ADDRESS;
   
    switch(dataRequestMsg->typeOfData)
    {
 	case OVERVIEW:
	{
	  dataOverviewMsg=(DataOverviewMsg*)(&(msg.data));
 	  dataOverviewMsg->msgCnt=msgCnt;
	  dataOverviewMsg->rfPower=call CCControl.GetRFPower();
	  // why is the dest addr == receiverAction? -mpm
	  if(call SendDataOverviewMsg.send(dataRequestMsg->receiverAction, LEN_DATAOVERVIEWMSG, &msg)==SUCCESS){
		//call Leds.redOn();
	  }
	  atomic{
	    state=IDLE;
	  }
	  break;
	}
	case SOME_RSSI:
	{
	  msgSendingIndex=dataRequestMsg->msgIndex; // when we send the data, this is the row in rssi 
						    // (not the node id of the transmitter, but the
						    // but the received message number). Setting goToIdle stops
						    // the data reporting after one row of rssi -mpm 
						    // this is used when we missed a packet on the pc? -mpm
	  receiverAction=dataRequestMsg->receiverAction; // why is this being set? -mpm
	  //call ReadData.read(0,eeprom,20);
	  post sendNextRSSI();
	  atomic{
	    goToIdle=1;  // ugly! alias this  -mpm
	  }
	  
	  break;
	}
	case ALL_RSSI:
	{
	  msgSendingIndex=dataRequestMsg->msgIndex; // we start reporting at this and report the data in rssi
						    // after that.  why would you want to do that? don't you just want
						    // to send all data or just the data from a single node? -mpm
	  //	  timerPeriod=dataRequestMsg->timerPeriod; // why not let this get set? -mpm
	  receiverAction=dataRequestMsg->receiverAction; 
		/* why is this set here? receiverAction is sent on the chirps and can cause the non-delayed reporting of 
		data or storage in ram at that point.  and the value of receiverAction sent on the chirps is set by the 
		value received on ChirpCommandMsg.  Setting it here does nothing because all chirps must be initiated by
		a request to chirp, which will set the receiverAction. -mpm */
//	  call Timer.start(TIMER_REPEAT, timerPeriod); // we are always running the timer so we don't need to do this -mpm
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
    return SUCCESS;
  }

  event result_t SendDataMsg.sendDone(TOS_MsgPtr m, result_t success)
  {
    return SUCCESS;
  }

  event result_t SendDataOverviewMsg.sendDone(TOS_MsgPtr m, result_t success)
  {
    return SUCCESS;
  }

  task void chirp()
  {
//	uint8_t power= call CCControl.GetRFPower();
	if(state!=CHIRPING) {
	  return;
	}
//        call CCControl.SetRFPower(0x01);
	if( msgNumber>numberOfChirps){ // if the node has chirped the number of times it was requested to chirp -mpm 
	  atomic{
	    state=IDLE;
	    }
	}
	else{
		chirpMsg = (ChirpMsg*)(&(msg.data));
		chirpMsg->transmitterId=TOS_LOCAL_ADDRESS;
		chirpMsg->receiverAction=receiverAction;
		chirpMsg->msgNumber=msgNumber++;
		chirpMsg->rfPower=call CCControl.GetRFPower();
		if(call SendChirpMsg.send(TOS_BCAST_ADDR, LEN_CHIRPMSG, &msg)==SUCCESS){          
		  //call Leds.redToggle();
		} else {
		  //call Leds.yellowToggle();
		}
//        call CCControl.SetRFPower(power);
	}
  }

//  async event result_t Clock.fire() // switched to Timer -mpm 
  event result_t Timer.fired()
  {
     if(state==RETURNING_RSSI_DATA) {    
        post sendNextRSSI();
     }
     else if(state==CHIRPING) {  
	post chirp();
     }
     else{ 
//	call Timer.stop(); 
     }
     return SUCCESS;
  }

}








