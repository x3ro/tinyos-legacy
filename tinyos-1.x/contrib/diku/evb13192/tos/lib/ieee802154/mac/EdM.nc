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
/**
Handles PHY layer ED request/confirm.
Energy detection is repeated until the end of a scan duration.
Allows only one pending request at a time.

**/
#include "PhyTypes.h"

module EdM
{
	provides
	{
		interface Ed;
	}
	uses
	{
		interface PhyEnergyDetect;
		interface AsyncAlarm<time_t> as Alarm;
		interface Debug;
	}
}
implementation
{	
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t maxEnergy;
	bool doneScanning;

	command result_t Ed.perform(time_t duration)
	{
		doneScanning = FALSE;
		maxEnergy = 0;
		call Alarm.armCountdown(duration);
		if (PHY_SUCCESS != call PhyEnergyDetect.ed()) {
			return FAIL;
		}
		return SUCCESS;
	}

	
	async event void PhyEnergyDetect.edDone(phy_error_t error, uint8_t energy)
	{
		if (error == PHY_SUCCESS) {
			if (energy > maxEnergy) maxEnergy = energy;
		}
		if (doneScanning) {
			signal Ed.done(SUCCESS,maxEnergy);
		} else {
			if (PHY_SUCCESS != call PhyEnergyDetect.ed()) {
				signal Ed.done(FAIL,maxEnergy);
			}
		}
	}

	async event result_t Alarm.alarm()
	{
		doneScanning = TRUE;
		return SUCCESS;
	}
	
	default async event void Ed.done(result_t status, uint8_t level)
	{
		DBG_STR("Ed done event not connected!",1);
	}
}
