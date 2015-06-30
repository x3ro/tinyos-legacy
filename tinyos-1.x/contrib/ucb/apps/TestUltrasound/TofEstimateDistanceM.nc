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

/* 
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
 * 	     UC Berkeley
 * Date:     8/20/2002
 *
 */

includes Ranging;
includes TofRanging;

//the module that estimates distance when it hears a chirp
module TofEstimateDistanceM
{
	provides
	{
		interface StdControl;
		interface Ranging;
	}
	uses
	{
		interface MicInterrupt;
		interface StdControl as TimerControl;
		interface StdControl as CommControl;
		interface StdControl as AttrControl;
		interface AttrRegister as USoundRxrCalibration;
		interface AttrUse as Attributes;
		interface ReceiveMsg as TofChirp;
		interface SendMsg as TofData;
		interface Timer as Clock1;
		interface TofListenControl;
		interface Leds;
	}
}
implementation
{
	TOS_Msg tosMsg;
	struct TofRangingDataMsg *distanceData;
	struct CalibrationCoefficients* micCoefficients;
	uint8_t enabled;
	uint16_t mostRecentToneTime;
	uint16_t mostRecentReceiverAction;
	uint16_t tofFilterBuffer[TOF_FILTER_BUFFER_SIZE];
	uint8_t  currentBufferIndex;
	uint8_t  currentFilterTransmitter;

	result_t processTof(uint16_t tof, uint16_t receiverAction);
	result_t filterTof(uint16_t *tof, uint16_t transmitterId);
	result_t calibrateDistance();

	command result_t StdControl.init()
	{
		call Leds.redOn();
		call TimerControl.init();
		call CommControl.init();
		call AttrControl.init();
		enabled=FALSE;
		mostRecentToneTime=0;
		mostRecentReceiverAction=0;
		currentBufferIndex=0;
		memset((char*)&tosMsg, 0, sizeof(tosMsg));
		distanceData=(struct TofRangingDataMsg*)&tosMsg.data;
		micCoefficients = (struct CalibrationCoefficients*)&(distanceData->micOffset);
		micCoefficients->a=0;
		micCoefficients->b=1;
		if (call USoundRxrCalibration.registerAttr("TofMcCfs", UINT8, 1) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call AttrControl.start();
		call TimerControl.start();
		call CommControl.start();
		enabled=TRUE;
		call Clock1.start(TIMER_ONE_SHOT, 200);
//		call TofListenControl.enable();
		return SUCCESS;
	}

	command result_t StdControl.stop()
        {
		enabled=FALSE;
		call TofListenControl.disable();
		return(call Clock1.stop());
	}

	event result_t USoundRxrCalibration.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		((struct CalibrationCoefficients*)resultBuf)->a = micCoefficients->a;
		((struct CalibrationCoefficients*)resultBuf)->b = micCoefficients->b;
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t USoundRxrCalibration.setAttr(char *name, char *attrVal)
	{
		micCoefficients->a = ((struct CalibrationCoefficients*)attrVal)->a;
		micCoefficients->b = ((struct CalibrationCoefficients*)attrVal)->b;
		return SUCCESS;
	}

	event TOS_MsgPtr TofChirp.receive(TOS_MsgPtr chirpMsg)
	{
//		SchemaErrorNo errorNo;
		
		call Leds.greenToggle();

		if(enabled==FALSE)
			return FAIL;
		
		distanceData->transmitterId=((struct TofChirpMsg*)chirpMsg->data)->transmitterId;
		distanceData->sounderOffset=((struct TofChirpMsg*)chirpMsg->data)->sounderOffset;
		distanceData->sounderScale=((struct TofChirpMsg*)chirpMsg->data)->sounderScale;
		distanceData->receiverId = TOS_LOCAL_ADDRESS;

		mostRecentToneTime = chirpMsg->toneTime;
		mostRecentReceiverAction = ((struct TofChirpMsg*)chirpMsg->data)->receiverAction;

 		return chirpMsg;
	}

	event result_t Clock1.fired()
	{	
		call Leds.redOff();
		call TofListenControl.enable();
		return SUCCESS;
	}

	result_t processTof(uint16_t tof, uint16_t receiverAction)
	{
		if(filterTof(&tof, distanceData->transmitterId))
		{
			//distance = time*.0083 - 7
			distanceData->distance=tof>>5;
			distanceData->distance*=17;
			distanceData->distance>>=6;
			if (distanceData->distance>7) distanceData->distance-=7;

//			calibrateDistance();

			if(receiverAction==SIGNAL_RANGING_INTERRUPT){
				return(signal Ranging.rangingDataReady((RangingData*)&distanceData));
			}
			else{ 
				return(call TofData.send(receiverAction, LEN_TOFRANGINGDATAMSG, &tosMsg));
			}

		}
		return SUCCESS;
	}

	result_t filterTof(uint16_t *tof, uint16_t transmitterId)
	{
		uint16_t lower_bound;
		uint8_t min1Index;
		uint16_t min1;
		uint16_t min2;
		uint16_t i;
		
		if(TOF_FILTER_BUFFER_SIZE<2)
			return TRUE;

		if(currentBufferIndex==0)
			currentFilterTransmitter =transmitterId;
		else if(currentFilterTransmitter!=transmitterId)
			return FAIL;

		tofFilterBuffer[currentBufferIndex] = *tof;
		currentBufferIndex+=1;

		if(currentBufferIndex<TOF_FILTER_BUFFER_SIZE)
			return FALSE;

		//first, filter the readings: choose the min unless it is too far from the second min.  this accounts for up to one false positive
		min1=65535;//max value for a unsigned short
		for(i=0;i<TOF_FILTER_BUFFER_SIZE;i++){
			if(tofFilterBuffer[i]<min1){
				min1Index=i;
				min1=tofFilterBuffer[i];
			}
		}
  
		min2=65535;//max value for a unsigned short
		for(i=0;i<TOF_FILTER_BUFFER_SIZE;i++){
			if( (tofFilterBuffer[i]<min2) && (i!=min1Index) ){
				min2=tofFilterBuffer[i];
			}
		}
  
		lower_bound = (min2>>4)*13-3776; //effectively, lowerBound=.8125*min2-3776
		*tof=min1<lower_bound ? min2 : min1; // choose the min over lower_bound
		return TRUE;
	}

	result_t calibrateDistance()
	{
//		distanceData->distance=distanceData->distance*distanceData->sounderScale + distanceData->distance*distanceData->micScale + distanceData->sounderOffset + distanceData->micOffset;
	}

	event result_t TofData.sendDone(TOS_MsgPtr msg, result_t success) 
	{
		return SUCCESS;
	}
  
	event result_t Attributes.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo)
	{
		return SUCCESS;
	}

	default event result_t Ranging.rangingDataReady(RangingData* data)
	{
		return SUCCESS;
	}
	
	event result_t MicInterrupt.toneDetected()
	  {
		uint16_t time =   __inw_atomic(TCNT1L);
		if(mostRecentToneTime>0){
			call Leds.yellowToggle();
			processTof(time-mostRecentToneTime, mostRecentReceiverAction);
			mostRecentToneTime=0;
		}
		return SUCCESS;
	  }

}





