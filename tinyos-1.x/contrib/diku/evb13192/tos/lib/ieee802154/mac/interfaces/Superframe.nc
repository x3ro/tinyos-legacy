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

interface Superframe
{
	// For CAP use.
	command bool fitsInCap(txHeader_t *header);
	command bool capActive(superframe_t *superframe);
	command time_t getCapEnd(superframe_t *superframe);
	// For GTS use.
	command bool fitsInGts(cfpTx_t *frame, gtsDescriptor_t *gts);
	command bool fitsInCurGts(cfpTx_t *frame, gtsDescriptor_t *gts);
	command bool cfpExists(superframe_t *superframe);
	command time_t getCfpEnd(superframe_t *superframe);
	// For slotted CSMA-CA use.
	// Checks if the transaction including backoffs will fit in the current
	// CAP. Updates the backoffPeriods property according to the IEEE standard
	command time_t timeoutFitsInCurCap(time_t timeout, superframe_t *sf);
	command bool fitsInCurCap(capTx_t *frame);

	// General.

	// next superframe start
	command time_t getNextStart(superframe_t *superframe);
	command time_t getSlotStartTime(superframe_t *sf, uint8_t slot);
	command uint8_t getCurrentSlot(superframe_t *sf);
	command uint16_t gtsTimeout(superframe_t *sf);
	
	//TODO: Update function - perhaps on another interface?
	command void updateFromSpec( superframe_t *superframe,
	                             msduSuperframeSpec_t *spec,
	                             time_t startTime,
	                             uint8_t beaconBytes ); 
}
