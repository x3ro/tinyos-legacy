/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

#include "MacPib.h"
#include "PhyTypes.h"

module CsmaM
{
	provides
	{
		interface Csma;
	}
	uses
	{	
		interface FrameTx;
		interface LocalTime;
		interface Random;
		interface Superframe;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 3
	#include "Debug.h"

	capTx_t *pendingTx;
	txdata_t myTxData;

	void performIteration();
	uint8_t getBackoffPeriods();
	
	command void Csma.send( capTx_t *capTx )
	{
		// Perform CSMA-CA
		// This can only be performed by one requester at a time..
		// TODO: perhaps ensure unique access
		pendingTx = capTx;
		myTxData.frame = pendingTx->header->frame;
		myTxData.length = pendingTx->header->length;
		myTxData.cca = TRUE;
		if (pendingTx->status != CSMA_DEFERRED){
			// this a new csma request, initialize parameters
			pendingTx->status = CSMA_DEFERRED; //just in case
			pendingTx->NB = 0;
			pendingTx->BE = macMinBE;
			pendingTx->backoffPeriods = getBackoffPeriods();
		} else {
			DBG_STR("Deferred entry",3);
		}
		// TODO: We need to be able to handle backoff periods < 3 slots.
		pendingTx->backoffPeriods = (pendingTx->backoffPeriods < 3)?3 : pendingTx->backoffPeriods;
		//DBG_STRINT("Backoff is:",pendingTx->backoffPeriods,1);
		performIteration();	
	}
	
	void performIteration()
	{
		time_t myNow;
		if (macBeaconEnabled) {
			// check if we need to defer the backoff to the next cap
			// we expect the superframe module to update number of backoffs
			// if the frame does not fit
			if (!call Superframe.fitsInCurCap(pendingTx)) {
				DBG_STR("Transmission does not fit in current CAP!",1);
				// defer transaction to next CAP
				signal Csma.done();
				return;
			}
			
			// pad to next backoff slot boundary inside current CAP
			myTxData.immediateCommence = FALSE;
			myTxData.commenceTime = pendingTx->commenceTime;
		} else {
			// Unslottet CSMA.
			// calculate backoff time
			uint32_t backoffDuration = pendingTx->backoffPeriods * aUnitBackoffPeriod;
			if (backoffDuration > 0) {
				// Calculate commence time.
				myTxData.immediateCommence = FALSE;
				myTxData.commenceTime = call LocalTime.getTime()+backoffDuration;
			} else {
				// commence ASAP
				myTxData.immediateCommence = TRUE;
			}
		}
		
		// Add dsn if needed.
		if (pendingTx->header->addDsn) {
			mhrSeqNumber(myTxData.frame) = macDsn++;
		}

		if (PHY_SUCCESS != call FrameTx.tx(&myTxData)) {
			// TODO: debug output
			pendingTx->header->status = TX_CHANNEL_ACCESS_FAILURE;
			signal Csma.done();
		}
		//myNow = call LocalTime.getTime();
		//DBG_STRINT("CommenceTime:",myTxData.commenceTime,1);
		//DBG_STRINT("Time now is:",myNow,1);
	}
	
	/** Calculates a random backoff period in symbol periods **/
	uint8_t getBackoffPeriods() {
		uint8_t backoff = (1<<pendingTx->BE)-1;
		if ( backoff > 0 ) {
			backoff = (call Random.rand() % (backoff+1));
		}
		return backoff;
	}

	async event void FrameTx.txDone(phy_error_t error)
	{
		if (error == PHY_SUCCESS) {
			pendingTx->header->status = TX_SUCCESS;
		} else if (error == PHY_ACK_FAIL) {
			pendingTx->header->status = TX_NO_ACK;
			pendingTx->header->txRetries--;
		} else {
			// CCA must have failed.
			pendingTx->backoffPeriods = 0;
			pendingTx->NB++;
			pendingTx->BE = (pendingTx->BE+1 > aMaxBE) ? aMaxBE : pendingTx->BE+1;
			if ( pendingTx->NB <= macMaxCSMABackoffs) {				
				// attempt another CSMA iteration
				performIteration();
				return;
			} else {
				// CSMA has failed
				pendingTx->header->status = TX_CHANNEL_ACCESS_FAILURE;
			}
		}
		signal Csma.done();
	}

	default async event void Csma.done()
	{
		DBG_STR("WARNING: Csma.done() not connected!",1);
	}
}
