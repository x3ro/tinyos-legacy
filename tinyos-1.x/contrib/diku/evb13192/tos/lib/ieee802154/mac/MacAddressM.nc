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

#include "macFrame.h"
#include "Ieee802154Adts.h"

module MacAddressM
{
	provides
	{
		interface MacAddress;
	}
	uses
	{		
		interface Debug;
	}

}
implementation
{
	#define DBG_LEVEL 3
	#include "Debug.h"
	
	command void MacAddress.getSrcAddr(uint8_t *frame, ieeeAddress_t *myAddress)
	{
		myAddress->mode = mhrSrcAddrMode(frame);
		if (myAddress->mode == 0) return;
		if (mhrIntraPAN(frame)) {
			myAddress->panId = *((uint16_t*)mhrDestPANId(frame));
		} else {
			myAddress->panId = *((uint16_t*)mhrSrcPANId(frame));
		}
		memcpy(myAddress->address, mhrSrcAddr(frame), 8);
	}
	
	command void MacAddress.getDstAddr(uint8_t *frame, ieeeAddress_t *myAddress)
	{
		myAddress->mode = mhrDestAddrMode(frame);
		if (myAddress->mode == 0) return;
		
		myAddress->panId = *((uint16_t*)mhrDestPANId(frame));
		memcpy(myAddress->address, mhrDestAddr(frame), 8);
	}
	
	command void MacAddress.setSrcAddr(uint8_t *frame, ieeeAddress_t *myAddress)
	{
		mhrSrcAddrMode(frame) = myAddress->mode;
		if (myAddress->mode == 0) return;
		
		if (!mhrIntraPAN(frame)) {
			*((uint16_t*)mhrSrcPANId(frame)) = myAddress->panId;
		}
		if (myAddress->mode == 3) {
			memcpy(mhrSrcAddr(frame), myAddress->address, 8);
		} else {
			memcpy(mhrSrcAddr(frame), myAddress->address, 2);
		}
	}
	
	command void MacAddress.setDstAddr(uint8_t *frame, ieeeAddress_t *myAddress)
	{
		mhrDestAddrMode(frame) = myAddress->mode;
		if (myAddress->mode == 0) return;

		*((uint16_t*)mhrDestPANId(frame)) = myAddress->panId;
		if (myAddress->mode == 3) {
			memcpy(mhrDestAddr(frame), myAddress->address, 8);
		} else {
			memcpy(mhrDestAddr(frame), myAddress->address, 2);
		}
	}
	
	command void MacAddress.setDstCoordinator(uint8_t *frame)
	{
		*((uint16_t*)mhrDestPANId(frame)) = macPanId;
		if (macCoordShortAddress == 0xFFFF || macCoordShortAddress == 0xFEFF) {
			mhrDestAddrMode(frame) = 3;
			memcpy(mhrDestAddr(frame), macCoordExtendedAddress, 8);
		} else {
			mhrDestAddrMode(frame) = 2;
			memcpy(mhrDestAddr(frame), &(macCoordShortAddress), 2);
		}
	}
	
	command void MacAddress.setSrcLocal(uint8_t *frame, bool preferExt)
	{		
		if (!mhrIntraPAN(frame)) {
			*((uint16_t*)mhrSrcPANId(frame)) = macPanId;
		}
		if (preferExt || macShortAddress == 0xFFFF || macShortAddress == 0xFEFF) {
			// Use extended addressing.
			mhrSrcAddrMode(frame) = 3;
			memcpy(mhrSrcAddr(frame), aExtendedAddress, 8);
		} else {
			// Use short addressing.
			mhrSrcAddrMode(frame) = 2;
			memcpy(mhrSrcAddr(frame), &(macShortAddress), 2);
		}
	}
}
