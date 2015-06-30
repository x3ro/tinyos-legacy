/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
 * 	     UC Berkeley
 * Date:     8/20/2002
 *
 */

includes common_structs;
includes Ranging;

//!! RoutingMsgExt {  uint16_t toneTime; }

//!! Neighbor 21 { D2Polynomial_t micCoefficients = { degree:2, coefficients:{0.0, 1.0} }; }

//!! Neighbor 19 { DistanceBuffer_t distanceBuffer = {cq:{DISTANCE_BUFFER_SIZE,DISTANCE_BUFFER_SIZE,DISTANCE_BUFFER_SIZE}, distances:{-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}}; }

//!! Neighbor 20 { RangingData_t rangingData = {distance:0, stdv:32767}; }



module TofEstimateDistanceM
{
	provides
	{
		interface StdControl;
		interface RangingSensor;
	}
	uses
	{
		interface StdControl as Mic;
		interface StdControl as TimerControl;
		interface RoutingReceive as TofChirp;
		interface Timer as Clock1;
		interface TupleStore;
		interface TofListenControl;
		interface Neighbor_micCoefficients;
		interface Neighbor_distanceBuffer;
		interface Neighbor_rangingData;
		interface Leds;
	}
}

implementation
{
	uint8_t  enabled;

	result_t processTof(uint16_t tof, uint16_t address);
	result_t calibrateDistance(uint16_t* distance, Polynomial_t calibCoeffs);
	result_t filterTof(RangingData_t* rangingData, DistanceBuffer_t distanceBuffer);

	command result_t StdControl.init()
	{
		enabled=FALSE;
		call Mic.init();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		enabled==TRUE;
		call Clock1.start(TIMER_ONE_SHOT, 200);
		call TofListenControl.enable();
		return SUCCESS;
	}

	command result_t StdControl.stop()
        {
		enabled=FALSE;
		call TofListenControl.disable();
		return(call Clock1.stop());
	}


	event TOS_MsgPtr TofChirp.receive( TOS_MsgPtr msg )
	{
		TupleMsgHeader_t* head;

		if(enabled==FALSE)
			return FAIL;

		if( (head = (TupleMsgHeader_t*)popFromRoutingMsg( msg, sizeof(TupleMsgHeader_t) )) == 0 )
			return msg;
		
 		if(msg->ext.toneTime>0){
			processTof(msg->ext.toneTime-msg->time, head->address);
		}
		call TofListenControl.disable();
		call Clock1.start(TIMER_ONE_SHOT, 40);
 		return msg;
	}

	event result_t Clock1.fired()
	{	
		call TofListenControl.enable();
		return SUCCESS;
	}

	result_t processTof(uint16_t tof, uint16_t address)
	{
		const Neighbor_t* nn = call TupleStore.getByAddress(address );
		DistanceBuffer_t distanceBuffer = nn->distanceBuffer;
		RangingData_t rangingData = nn->rangingData;
		float newDistance;
		uint16_t temp =tof>>4;
		temp*=9;
		temp>>=6;
		newDistance = (float)temp;
//		newDistance = calibrateDistance(&temp, (Polynomial)nn->sounderCoefficients);
		forcibly_push_front_cqueue(&distanceBuffer.cq);
		distanceBuffer.distances[distanceBuffer.cq.front]=newDistance;

		call Neighbor_distanceBuffer.set(TOS_LOCAL_ADDRESS, &distanceBuffer);
		if(filterTof(&rangingData, distanceBuffer))
		{
			call Neighbor_rangingData.set(TOS_LOCAL_ADDRESS, &rangingData);
			return(signal RangingSensor.rangingDataReady(&rangingData));
		}
		return SUCCESS;

	}

	result_t calibrateDistance(uint16_t* distance, Polynomial_t calibCoeffs)
	{
	}

	result_t filterTof(RangingData_t* rangingData, DistanceBuffer_t distanceBuffer)
	{
		uint16_t lower_bound;
		uint8_t min1Index;
		uint16_t min1;
		uint16_t min2;
		uint16_t i;
		
		return TRUE;

//		if(TOF_FILTER_BUFFER_SIZE<2)
//			return TRUE;

/*		if(currentBufferIndex==0)
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
		*tof=min1<lower_bound ? min2 : min1; // choose the min over lower_bound*/
		return TRUE;
	}


	default event result_t RangingSensor.rangingDataReady(RangingData_t* data)
	{
		return SUCCESS;
	}
	
	event void Neighbor_micCoefficients.updatedFromRemote(uint16_t address){
	}
	event void Neighbor_rangingData.updatedFromRemote(uint16_t address){
	}
	event void Neighbor_distanceBuffer.updatedFromRemote(uint16_t address){
	}
}





