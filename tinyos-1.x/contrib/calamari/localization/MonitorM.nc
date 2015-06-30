/*									
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Author: Alec Woo and Fred Jiang
 * 10/2 kamin added snooping on chirp sends, timestamping on chirp
 * sends and chirp receives, storing of sequence numbers, checking for
 * stray ranging pulses, and parameterized the reporting facilities.
 *
 *
 *
 */


//!! MonitorReportCmd = CreateCommand[SystemCommand] (CommandHood, Pair_uint16_t, Void_t, 108, 109);

includes Omnisound;

module MonitorM {
  provides {
    interface StdControl;
  }
	uses {
		interface UltrasonicRangingReceiver as Receiver;
		interface MonitorReportCmd;
		interface Timer;
		interface SendMsg as MonitorSend;
		interface Leds;
		interface SendMsg as ChirpSend;
	}
}

implementation {
	enum {
		NUM_NODES = 25,
		NUM_SAMPLES = 10,
		NUM_STRAYS = 5
	};
	
	typedef struct {
		uint16_t ID;
		uint8_t index;
		uint16_t timestampL[NUM_SAMPLES];
		uint8_t timestampH[NUM_SAMPLES];
		uint8_t seqNo[NUM_SAMPLES];
		uint16_t ranges[NUM_SAMPLES];
	} rangingArray_t; 

	typedef struct {
		uint8_t index;
		uint16_t timestampL[NUM_STRAYS];
		uint8_t timestampH[NUM_STRAYS];
		uint16_t ranges[NUM_STRAYS];
	} strayRangingArray_t; 

	/*monitoring data*/
	TOS_Msg msg;
	uint8_t timerSet = 0;
	uint8_t overflow = 0; //the byte to hold overflow bits from Timer3
	
	bool sendPending = FALSE;
	
	rangingArray_t rangingArray[NUM_NODES];
	strayRangingArray_t strayRangingArray;

	/*reporting data*/
	int8_t currentIndex = 0;
	uint16_t requestType = 0;
	uint16_t requestedIndex = 0;

	command result_t StdControl.init() {
	  //put the timer/cntr in "normal" operation mode
	  outp(0x00,TCCR3A);
	  outp(0x00,TCCR3B);
	  outp(0x00,TCCR3C);
	  //set the prescaler on Timer3 to 1024
	  sbi(TCCR3B,CS32);
	  cbi(TCCR3B,CS31);
	  sbi(TCCR3B,CS30);
	  //enable the overflow interrupt
	  sbi(ETIMSK,TOIE3);
	  return SUCCESS;
	}

	command result_t StdControl.start() {
	  return SUCCESS;
	}

	command result_t StdControl.stop() {
	  return SUCCESS;
	}

	void recordStrayRange(uint16_t distance){
	  //add a stray distance estimate to the strays data structure
	  if (strayRangingArray.index < NUM_STRAYS){
	    strayRangingArray.timestampL[strayRangingArray.index] = (uint16_t)(inp(TCNT3L) & 0xffff);
	    strayRangingArray.timestampL[strayRangingArray.index] |= (uint16_t)((inp(TCNT3H) & 0xffff) << 8);
	    strayRangingArray.timestampH[strayRangingArray.index] = overflow;
	    strayRangingArray.ranges[strayRangingArray.index] = distance;
	    strayRangingArray.index++;
	  }
	}

	bool checkForStray(uint8_t rangingArrayIndex){

	  //see if a usound was already detected after the last radio msg
	  if(rangingArray[rangingArrayIndex].ranges[rangingArray[rangingArrayIndex].index] != 0){
	    return TRUE;
	  }

/* 	  //see if this usound is much much later than the last radio msg */
/* 	  timestamp = (uint16_t)(inp(TCNT3L) & 0&=xffff); */
/* 	  timestamp &= (uint16_t)((inp(TCNT3H) & 0xffff) << 8); */
/* 	  if( ((overflow & 0xffffff) << 16 | timestamp) - */
/* 	      ((rangingArray[rangingArrayIndex].timestampH[rangingArray[rangingArrayIndex].index-1] & 0xffffff) << 16 | */
/* 	       rangingArray[rangingArrayIndex].timestampL[rangingArray[rangingArrayIndex].index-1]) > 500){ */
/* 	    return TRUE; */
/* 	  } */
	  return FALSE;
	}
	
	void recordDistance(uint16_t nodeID, uint16_t distance){
	  uint8_t i;
	  for(i = 0; i < NUM_NODES; i++) {
	    if (rangingArray[i].ID == nodeID) {
	      if (rangingArray[i].index < NUM_SAMPLES){
			  if(checkForStray(i)){
			    recordStrayRange(distance);
			    break;
			  }
			  rangingArray[i].ranges[rangingArray[i].index] = distance;
	      }
	      break;
	    }else if (rangingArray[i].ID == 0){
			rangingArray[i].ID = nodeID;
			rangingArray[i].ranges[rangingArray[i].index] = distance;
			break;
	    }
	  }
	}
	
	void recordRadioChirp(uint16_t nodeID, uint16_t sequenceNumber){
	  uint8_t i;
	  for(i = 0; i < NUM_NODES; i++) {
	    if (rangingArray[i].ID == nodeID) {
	      if (rangingArray[i].index < NUM_SAMPLES){
		rangingArray[i].timestampL[rangingArray[i].index] = (uint16_t)(inp(TCNT3L) & 0xffff);
		rangingArray[i].timestampL[rangingArray[i].index] |= (uint16_t)((inp(TCNT3H) & 0xffff) << 8);
		rangingArray[i].timestampH[rangingArray[i].index] = overflow;
		rangingArray[i].seqNo[rangingArray[i].index] = (uint8_t)sequenceNumber;
		rangingArray[i].index++;
	      }
	      break;
	    }else if (rangingArray[i].ID == 0){
	      rangingArray[i].ID = nodeID;
	      rangingArray[i].timestampL[rangingArray[i].index] = (uint16_t)(inp(TCNT3L) & 0xffff);
	      rangingArray[i].timestampL[rangingArray[i].index] |= (uint16_t)((inp(TCNT3H) & 0xffff) << 8);
	      rangingArray[i].timestampH[rangingArray[i].index] = overflow;
	      rangingArray[i].seqNo[rangingArray[i].index] = (uint8_t)sequenceNumber;
	      rangingArray[i].index++;
	      break;
	    }
	  }
	  
	}
	
	event void Receiver.receiveDone(uint16_t actuator, uint16_t receivedRangingId,
									uint16_t distance) {
	  //add a new distance estimate into the rangingArray (but
	  //first check if it is a stray ultrasound pulse)
	  recordDistance(actuator, distance);
	}
	
	event result_t Receiver.receive(uint16_t actuator, uint16_t receivedRangingId,
					uint16_t sequenceNumber, bool initiateRangingSchedule_) {
	  //timestamp the radio chirp message as it comes in
	  recordRadioChirp(actuator, sequenceNumber);
	  return SUCCESS;
	}	

	event result_t ChirpSend.sendDone(TOS_MsgPtr m, result_t success) {
	  //eavesdrop on outgoing Chirp traffic so that I can store Timestamps
	  ChirpMsg* temp = (ChirpMsg*)&(m->data);
	  recordRadioChirp(TOS_LOCAL_ADDRESS, temp->sequenceNumber);
	  return SUCCESS;
	}

	//the function that handles Timer3 overflow
	TOSH_INTERRUPT(SIG_OVERFLOW3) __attribute((spontaneous)){
	  overflow++;
	}

	/*****************MonitorM Report stuff *******************/
	/*
	/* The paremeter is Pair_uint16_t. The first value is the node
	/* ID, which should be set to 0 for all nodes.  The second is the
	/* type of data desired which should be
	/* 1: ranging data
	/* 2: timestampH and seqNo
	/* 3: timestampL
	/* 4: strays ranging data
	/* 5: strays timestampH
	/* 6: strays timestampL
	/*
	/* obviously, the nodeID doesn't mean anything for the strays 
	/************************************/
	
	task void MonitorReport() {
	  uint8_t msgSize=0;
		char * src;
		char * payloadPtr = &msg.data[8];		
		//make sure that currentIndex is set properly
		if(requestedIndex != 0){
		      currentIndex=requestedIndex-1;
		}

		//set the first few bytes
		*((uint16_t *)(&msg.data[0])) = TOS_LOCAL_ADDRESS;
		*((uint16_t *)(&msg.data[2])) = requestType;
		*((uint16_t *)(&msg.data[4])) = currentIndex+1;
		*((uint16_t *)(&msg.data[6])) = rangingArray[currentIndex].ID;

		// check the timerSet is set to 1
		// Check if you can send over the radio
		if (timerSet && !sendPending){
		  //copy data in depending on the requestType
		  //(if you change these case numbers be sure to change the sendDone event below)
		  switch(requestType){
		  case 1: //10 16bit ranges
		    src = (char *) &(rangingArray[currentIndex].ranges);
		    msgSize=sizeof(uint16_t)*NUM_SAMPLES;
			memcpy(payloadPtr, src, msgSize);
		    break;
		  case 2: //10 8bit timestamps followed by 10 8bit seqNos
		    src = (char *) &(rangingArray[currentIndex].timestampH);
		    msgSize=sizeof(uint8_t)*NUM_SAMPLES*2;
		    memcpy(payloadPtr, src, msgSize);
		    break;
		  case 3: //10 16bit timestamps (low bits)
		    src = (char *) &(rangingArray[currentIndex].timestampL);
		    msgSize=sizeof(uint16_t)*NUM_SAMPLES;
		    memcpy(payloadPtr, src, msgSize);
		    break;
		  case 4: //10 16bit ranges
		    src = (char *) &(strayRangingArray.ranges);
		    msgSize=sizeof(uint16_t)*NUM_SAMPLES;
			memcpy(payloadPtr, src, msgSize);
		    break;
		  case 5: //10 8bit timestamps (high bits)
		    src = (char *) &(strayRangingArray.timestampH);
		    msgSize=sizeof(uint8_t)*NUM_SAMPLES;
		    memcpy(payloadPtr, src, msgSize);
		    break;
		  case 6: //10 16bit timestamps (low bits)
		    src = (char *) &(strayRangingArray.timestampL);
		    msgSize=sizeof(uint16_t)*NUM_SAMPLES;
		    memcpy(payloadPtr, src, msgSize);
		    break;
		  }
		}
		msgSize+=8;
		sendPending = call MonitorSend.send(TOS_BCAST_ADDR, msgSize, &msg);
	}

	event result_t Timer.fired(){
		post MonitorReport();
		return SUCCESS;
	}

	event void MonitorReportCmd.receiveCall ( MonitorReportCmdArgs_t args) {
		call Leds.redToggle();
		if (!timerSet){
 		        requestedIndex=args.x;
 		        requestType=args.y;
			call Timer.start(TIMER_REPEAT, 255);
			timerSet = 1;
		}
		call MonitorReportCmd.dropReturn();
	}

	event void MonitorReportCmd.receiveReturn (nodeID_t node, MonitorReportCmdReturn_t rets) {}
	
	event result_t MonitorSend.sendDone(TOS_MsgPtr msgPtr, result_t success){
	        // advance the pointer to send the next message
		currentIndex++;
		sendPending = 0;
		// check if we have sent all the messages or if the
		// user requested only one node or if the user
		// requested strays data (which fits in one msg)
		if (currentIndex == NUM_NODES || requestedIndex != 0 || requestType>=4) {
		  // if we are done, stop timer and reset reporting state
			call Timer.stop();		
			timerSet = 0;
			currentIndex = 0;
			requestedIndex=0;
			requestType=0;
		}
		return SUCCESS;
	}


}
