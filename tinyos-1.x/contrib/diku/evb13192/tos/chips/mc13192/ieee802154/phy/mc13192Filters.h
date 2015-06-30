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

#ifndef _MC13192_FILTERS_H_
#define _MC13192_FILTERS_H_

	#include "MacPib.h"
	typedef struct
	{
		uint8_t FrameType       : 3;
		uint8_t SecurityEnabled : 1;
		uint8_t FramePending    : 1;
		uint8_t AckRequest      : 1;
		uint8_t IntraPAN        : 1;
		uint8_t Reserved1_2     : 1;
	
		uint8_t Reserved1_1     : 2;
		uint8_t DestAddrMode    : 2;
		uint8_t Reserved2       : 2;
		uint8_t SrcAddrMode     : 2;
	} frameControlHeader_t;

	// 802.15.4 filter parameters.
	//uint8_t filterPanId[2] = {0xDE, 0xFE};
	//uint8_t filterShortAddr[2] = {0x1F, 0x00};
	//uint8_t filterExtAddr[8] = {0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09};
	
	// 802.15.4 filtering global vars.
	frameControlHeader_t *rxFrameControl;
	uint8_t rxDstAddrLength;
	uint8_t *filterValue;
	uint8_t rxSeqNum;

	bool (*filterWord)(uint8_t*);
	char *filterReason;

	bool ackFilter(uint8_t *data);
	bool defaultFilter(uint8_t *data);
	bool seqNumFilter(uint8_t *data);
	bool dstPanFilter(uint8_t *data);
	bool dstAddrFilter(uint8_t *data);
	bool srcPanFilter(uint8_t *data);

	// 802.15.4 filtering functions.
	bool dummyFilter(uint8_t *dummy)
	{
		return TRUE;
	}
	
	bool ackFilter(uint8_t *data)
	{
		rxFrameControl = (frameControlHeader_t*)data;
		if (rxFrameControl->FrameType == 2) {
			filterWord = dummyFilter;
			return TRUE;
		}
		return FALSE;
	}

	bool defaultFilter(uint8_t *data)
	{
		rxFrameControl = (frameControlHeader_t*)data;
		
		// Discard if wrong frameType
		if (rxFrameControl->FrameType > 3) {
			filterReason = "Invalid frame type!";
			return FALSE;
		}
		// Discard if unknown address mode.
		if (rxFrameControl->DestAddrMode == 1 || rxFrameControl->SrcAddrMode == 1) {
			filterReason = "Invalid addressing mode!";
			return FALSE;
		}

		// Preaccept beacons when not associated.
		//if (!(rxFrameControl->FrameType) && filterPanId[0] == 0xFF && filterPanId[1] == 0xFF) {
		if (!(rxFrameControl->FrameType) && macPanId == 0xFFFF) {
			filterWord = dummyFilter;
			return TRUE;
		}
		
		// Calculate address lengths.
		rxDstAddrLength = 0;
		if (rxFrameControl->DestAddrMode) {
			if (rxFrameControl->DestAddrMode == 2) {
				rxDstAddrLength = 2;
			} else {
				rxDstAddrLength = 8;
			}
		}
		filterWord = seqNumFilter;
		return TRUE;
	}

	bool seqNumFilter(uint8_t *data)
	{
		// Not a real filter. Just fetch the sequence number
		// and prepare the right filter.
		rxSeqNum = data[0];
		//filterValue = filterPanId;
		filterValue = (uint8_t*)&macPanId;
		if (rxDstAddrLength) {
			filterWord = dstPanFilter;
		} else {
			filterWord = srcPanFilter;
		}
		return TRUE;
	}

	bool dstPanFilter(uint8_t *data)
	{
		// Read PANId for short address.
		uint8_t *myPan = data-1;
		if ((myPan[0] == filterValue[0] && myPan[1] == filterValue[1]) ||
		    (myPan[0] == 0xFF && myPan[0] == myPan[1])) {
			// Broadcast pan is also accepted.
			if (rxDstAddrLength == 2) {
				//filterValue = filterShortAddr;
				filterValue = (uint8_t*)&macShortAddress;
			} else {
				//filterValue = filterExtAddr;
				filterValue = aExtendedAddress;
			}
			filterWord = dstAddrFilter;
			return TRUE;
		}
		filterReason = "Invalid destination PAN Id!";
		return FALSE;
	}

	bool dstAddrFilter(uint8_t *data)
	{
		uint8_t *myAddr = data-1;
		if (rxDstAddrLength > 2) {
			// We are handling an extended address.
			if ((myAddr[0] == filterValue[0] && myAddr[1] == filterValue[1])) {
				filterValue += 2;
				rxDstAddrLength -= 2;
				return TRUE;
			} else {
				filterReason = "Invalid destination address1!";
				return FALSE;
			} 
		} else {
			// last part.
			// We also accept broadcast address if short address.
			if ((myAddr[0] == filterValue[0] && myAddr[1] == filterValue[1]) ||
			    (rxFrameControl->DestAddrMode == 2 &&
			    (myAddr[0] == 0xFF && myAddr[0] == myAddr[1]))) {
			
				// Filter was passed.
				filterWord = dummyFilter;
				return TRUE;
			} else {
				filterReason = "Invalid destination address2!";
				return FALSE;
			}
		}
	}
	
	bool srcPanFilter(uint8_t *data)
	{
		// Read PANId for short address.
		uint8_t *myPan = data-1;
		if ((myPan[0] == filterValue[0] && myPan[1] == filterValue[1])) {
			filterWord = dummyFilter;
			return TRUE;
		}
		filterReason = "Invalid source PAN Id!";
		return FALSE;
	}


#endif
