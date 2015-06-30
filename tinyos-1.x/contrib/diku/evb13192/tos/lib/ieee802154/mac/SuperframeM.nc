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

/* 
Superframe convenience functions.
*/

#include "mac.h"

module SuperframeM
{
	provides
	{
		interface Superframe;
	}
	uses
	{
		interface LocalTime;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	inline uint16_t requiredBackoffPeriods(time_t duration);
	inline time_t getElapsedSymbols(superframe_t *superframe);
	inline uint32_t getElapsedBackoffs(superframe_t *superframe);
	inline uint32_t getCapBackoffs(superframe_t *superframe);
	void calculateTransactionTime(txHeader_t *txOp);

	command bool Superframe.fitsInCap(txHeader_t *header)
	{
		superframe_t *sf = header->superframe;
		// This is always called before transmission. Just calculate
		// transaction time in here.
		if (!macBeaconEnabled) {
			// Always fits if not beacon enabled.
			return TRUE;
		}
		// TODO: What do we do, when superframe isn't updated yet?
		calculateTransactionTime(header);
		return (header->transactionTime + 
		       sf->beaconLength*aUnitBackoffPeriod)
		       < sf->capLength*sf->slotLength;
	}
	
	command bool Superframe.fitsInGts(cfpTx_t *frame, gtsDescriptor_t *gts)
	{
		//return (frame->header->transactionTime <
	}
	
	command bool Superframe.fitsInCurGts(cfpTx_t *frame, gtsDescriptor_t *gts)
	{
		superframe_t *sf = frame->header->superframe;
		time_t endTime = sf->startTime + (sf->slotLength*(gts->startSlot+gts->duration-1));
		return ((call LocalTime.getTime() + frame->header->transactionTime) < endTime); 
	}
	
	command time_t Superframe.getSlotStartTime(superframe_t *sf, uint8_t slot)
	{
		return sf->startTime + (sf->slotLength*slot);
	}
	
	command uint8_t Superframe.getCurrentSlot(superframe_t *sf)
	{
		return getElapsedSymbols(sf)/sf->slotLength;
	}
	
	command bool Superframe.cfpExists(superframe_t *superframe)
	{
		if (superframe->capLength == aNumSuperframeSlots) {
			return FALSE;
		}
		return TRUE;
	}
	
	command uint16_t Superframe.gtsTimeout(superframe_t *sf)
	{
		uint32_t beaconOrderExp = sf->beaconInterval;
		beaconOrderExp /= aBaseSuperframeDuration;
		if (beaconOrderExp >= 512) {
			return 2;
		} else {
			return 512/beaconOrderExp;
		}
	}
	
	// Checks if a timeout (wait for frame or response) fits inside the current cap.
	// Returns 0 if we just wait in the current cap or returns remaining time otherwise.
	command time_t Superframe.timeoutFitsInCurCap(time_t timeout, superframe_t *sf)
	{
		time_t timeLeft = (sf->capLength*sf->slotLength) - getElapsedSymbols(sf);
		if (timeLeft < timeout) {
			return timeout - timeLeft;
		} else {
			return 0;
		}
	}
	
	// For slotted CSMA-CA use.
	// updates frame backoff
	// when true, frame backoffs are the number of backoff periods since CAP start
	// when false, number of backoff periods are either 0 to indicate recalculation
	// in next CAP or the number of backoff periods to wait in the next CAP
	command bool Superframe.fitsInCurCap(capTx_t *frame)
	{
		superframe_t* sf = frame->header->superframe;
		uint32_t elapsedBackoffs, capBackoffs, countedBackoffs, txBackoffs;
		elapsedBackoffs = getElapsedBackoffs(sf);
		capBackoffs = getCapBackoffs(sf);
		// Remember to add two backoff periods for doing the CCA's.
		txBackoffs = frame->header->transactionTime / aUnitBackoffPeriod + 3;

		// first, check if the backoff fits in the current CAP
		// TODO: I suppose we need to use macBattLifeExtPeriods
		// although the description in 7.5.1.3 does not state this directly
		countedBackoffs = sf->battLifeExt
		                ? macBattLifeExtPeriods + sf->beaconLength
		                : capBackoffs;

		if ( elapsedBackoffs >= countedBackoffs ) {
			// no backoff time left in this CAP at all
			DBG_STR("No backoff time left at all in CAP.",1);
			DBG_STRINT("Elapsed Backoffs:",elapsedBackoffs,1);
			DBG_STRINT("Counted Backoffs:",countedBackoffs,1);
			DBG_STRINT("Counted Backoffs:",capBackoffs,1);
			return FALSE;
		} else if ( elapsedBackoffs+frame->backoffPeriods >= countedBackoffs ) {
			// Count down backoffs in this CAP, continue in next CAP.
			// Don't count the backoffs all the way to zero!
			frame->backoffPeriods -= (countedBackoffs - elapsedBackoffs);
			DBG_STR("Backoff period does not fit in CAP.",1);
			return FALSE;
		} else if ( elapsedBackoffs+frame->backoffPeriods+txBackoffs > countedBackoffs) {
			// cannot fit transaction into this CAP
			// create new backoff in next CAP
			frame->backoffPeriods = 0;
			DBG_STR("Backoff period fits in CAP, but tx does not.",1);
			return FALSE;
		} else {
			// all the checks passed, the backoff+tx fits in this CAP
			// Calculate the commenceTime of the operation.
			//frame->backoffPeriods += elapsedBackoffs;
			frame->commenceTime = (elapsedBackoffs + frame->backoffPeriods)*aUnitBackoffPeriod
			                      + sf->startTime;
			return TRUE;
		}
	}
	
	command bool Superframe.capActive(superframe_t *superframe)
	{
		if (superframe == &deviceSuperframe) {
			return deviceCapActive;
		}
		// Assume coordinator superframe. 
		return coordCapActive;
	}
	
	command time_t Superframe.getCapEnd(superframe_t *superframe)
	{
		time_t capEnd = superframe->slotLength;
		capEnd *= superframe->capLength;
		capEnd += superframe->startTime;
		return capEnd;
	}
	
	command time_t Superframe.getCfpEnd(superframe_t *superframe)
	{
		time_t cfpEnd = superframe->slotLength;
		cfpEnd *= aNumSuperframeSlots;
		cfpEnd += superframe->startTime;
		return cfpEnd;
	}
	
	// General.
	
	command time_t Superframe.getNextStart(superframe_t *superframe)
	{
		time_t bt = superframe->beaconInterval;
		bt += superframe->startTime;
		return bt;
	}
	
	command void Superframe.updateFromSpec( superframe_t *superframe,
	                                        msduSuperframeSpec_t *spec,
	                                        time_t startTime,
	                                        uint8_t beaconBytes )
	{
		superframe->startTime = startTime;
		superframe->slotLength = 1;
		superframe->slotLength <<= spec->SuperframeOrder;
		superframe->slotLength *= aBaseSlotDuration;
		superframe->beaconInterval = 1;
		superframe->beaconInterval <<= spec->BeaconOrder;
		superframe->beaconInterval *= aBaseSuperframeDuration;
		superframe->capLength = spec->FinalCAPSlot+1;
		superframe->battLifeExt = spec->BatteryLifeExtension;
		// TODO: Depends on channel chosen.
		superframe->beaconLength = ((8 + beaconBytes)*2 / aUnitBackoffPeriod) + 1;
	}
	
	
	inline uint16_t requiredBackoffPeriods(time_t duration)
	{
		return (duration / (aUnitBackoffPeriod))+1;
	}
	
	inline time_t getElapsedSymbols(superframe_t *superframe)
	{
		// TODO: handle timer wrapping
		time_t elapsed;
		elapsed = call LocalTime.getTime() - superframe->startTime;
		elapsed += 1; // TODO: add proper penalty
		return elapsed;
	}
	
	inline uint32_t getElapsedBackoffs(superframe_t *superframe)
	{
		return getElapsedSymbols(superframe) / aUnitBackoffPeriod + 1;
	}
	
	inline uint32_t getCapBackoffs(superframe_t *superframe)
	{
		uint32_t backoffs = superframe->capLength*superframe->slotLength;
		backoffs /= aUnitBackoffPeriod;
		return backoffs;
	}
	
	void calculateTransactionTime(txHeader_t *txOp)
	{
		uint8_t ifs = (txOp->length > aMaxSIFSFrameSize) ? aMinLIFSPeriod : aMinSIFSPeriod;
		uint8_t frameByteSize = txOp->length + 8; // Add PHY overhead
		// TODO: TX time per byte depends on channel chosen.
		txOp->transactionTime = frameByteSize*2 + ifs;
	}
}
