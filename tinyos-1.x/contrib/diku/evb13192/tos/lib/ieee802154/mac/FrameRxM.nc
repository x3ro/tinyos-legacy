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

/**
Handles PHY data indications.
**/
#include "macFrame.h"
#include <Int64Compare.h>

module FrameRxM
{
	provides
	{
		interface StdControl;
		interface RxFrame as DataFrame;
		interface RxFrame as BeaconFrame;
		interface RxFrame as ScanBeaconFrame;
		interface RxFrame as AssocReqFrame;
		interface RxFrame as AssocRespFrame;
		interface RxFrame as DisassocNotFrame;
		interface RxFrame as DataReqFrame;
		interface RxFrame as PanIdConfFrame;
		interface RxFrame as OrphanNotFrame;
		interface RxFrame as BeaconReqFrame;
		interface RxFrame as CoordRealignFrame;
		interface RxFrame as GtsReqFrame;
		interface FrameRx;
		interface PollEvents;
		interface Reset;
	}
	uses
	{
		interface PhyReceive;
		interface PhyControl;
		interface IeeeBufferManagement as BufferMng;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"

	bool isPolling = FALSE;

	command void Reset.reset()
	{
		isPolling = FALSE;
	}

	command result_t StdControl.init()
	{
		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		uint8_t *newBuffer;
		if (SUCCESS != call BufferMng.claim(126, &newBuffer)) {
			return FAIL;
		}
		call PhyReceive.initRxBuffer(newBuffer);
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	command phy_error_t FrameRx.rxOn(uint32_t commenceTime)
	{
		phyIsReceiving = TRUE;
		return call PhyReceive.rxOn(commenceTime, FALSE);
	}
	
	command phy_error_t FrameRx.rxOnNow()
	{
		phyIsReceiving = TRUE;
		return call PhyReceive.rxOn(0,TRUE);
	}

	command result_t FrameRx.trxOff(bool force)
	{
		phyIsReceiving = FALSE;
		return call PhyControl.trxOff(force);
	}

	command void PollEvents.waitForPolledFrame()
	{
		isPolling = TRUE;
	}

	command void PollEvents.pollTimedOut()
	{
		isPolling = FALSE;
	}

	async event uint8_t *PhyReceive.dataReady(rxdata_t *data)
	{
		uint8_t *newBuffer = NULL;
		uint8_t frameType = mhrFrameType(data->frame);
		
		DBG_STR("Frame type is:",3);
		DBG_INT(frameType,3);

		DBG_STR("Data is:",3);
		DBG_DUMP(data->frame, data->length,3);

		// Beacon frames are most time critical, as they also mark
		// the start of the CAP.
		if (frameType == macBeaconFrame) {
			if (macBeaconEnabled) {
				// Discard if PAN ID does not match.
				if (*((uint16_t*)(mhrSrcPANId(data->frame))) != macPanId ) {
					return data->frame;
				}
				if (macPanCoordinator) {
					if (msduPANCoordinator(data->frame)) {
						// TODO: Signal PAN conflict detected.
					}
					return data->frame;
				} else {
					// Only accept beacons from my coordinator!
					if (mhrSrcAddrMode(data->frame) == 3) {
						if (int64Compare(mhrSrcAddr(data->frame), macCoordExtendedAddress)) {
							// Beacon from my coordinator!
							return signal BeaconFrame.received(data);
						}
					} else {
						// Assume mode 2.
						if (	*((uint16_t*)(mhrSrcAddr(data->frame))) == macCoordShortAddress) {
							// Beacon from my coordinator!
							return signal BeaconFrame.received(data);
						}
					}
					// No match. This is a PAN conflict if the beacon came from
					// a PAN coordinator.
					if (msduPANCoordinator(data->frame)) {
						// TODO: Signal PAN conflict detected.
					}
					return data->frame;
				}
			} else {
				// Just allow beacons through.
				// They are only interesting for a passive or active scan.
				return signal ScanBeaconFrame.received(data);
			}
		}

		if (frameType == macDataFrame) {
			// Check if we were polling.
			if (isPolling) {
				isPolling = FALSE;
				// If payload length is 0, no data was available.
				if (0 == (data->length - (mhrLengthFrame(data->frame)))) {
					signal PollEvents.noDataAvailable();
					return data->frame;
				} else {
					signal PollEvents.gotPolledFrame();
				}
			}
			newBuffer = signal DataFrame.received(data);
			DBG_STR("We have a DATA frame",3);
		}

		// Process MAC command frames.		
		if (frameType == macCommandFrame) {
			uint8_t commandType = msduCommandFrameIdent(data->frame);
			DBG_STR("We have a command frame",3);
			
			if (isPolling) {
				isPolling = FALSE;
				signal PollEvents.gotPolledFrame();
			}
			
			if (commandType == macCommandAssocReq) {
				newBuffer = signal AssocReqFrame.received(data);
			}
			if (commandType == maccommandAssocResp) {
				newBuffer = signal AssocRespFrame.received(data);
			}
			if (commandType == macCommandDisassocNot) {
				newBuffer = signal DisassocNotFrame.received(data);
			}
			if (commandType == macCommandDataReq) {
				newBuffer = signal DataReqFrame.received(data);
			}
			if (commandType == macCommandPanIdConf) {
				newBuffer = signal PanIdConfFrame.received(data);
			}
			if (commandType == macCommandOrphanNot) {
				newBuffer = signal OrphanNotFrame.received(data);
			}
			if (commandType == macCommandBeaconReq) {
				newBuffer = signal BeaconReqFrame.received(data);
			}
			if (commandType == macCommandCoordRealign) {
				newBuffer = signal CoordRealignFrame.received(data);
			}
			if (commandType == macCommandGtsReq) {
				newBuffer = signal GtsReqFrame.received(data);
			}
		}
		// Return new receive buffer to the radio.
		if (newBuffer == NULL) {
			// Unhandled frame.
			newBuffer = data->frame;
		}
		return newBuffer;
	}

	// Default events.
	default async event uint8_t *DataFrame.received(rxdata_t *data)
	{
		DBG_STR("DataFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *BeaconFrame.received(rxdata_t *data)
	{
		DBG_STR("BeaconFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *AssocReqFrame.received(rxdata_t *data)
	{
		DBG_STR("AssocReqFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *AssocRespFrame.received(rxdata_t *data)
	{
		DBG_STR("AssocRespFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *DisassocNotFrame.received(rxdata_t *data)
	{
		DBG_STR("DisassocNotFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *DataReqFrame.received(rxdata_t *data)
	{
		DBG_STR("DataReqFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *PanIdConfFrame.received(rxdata_t *data)
	{
		DBG_STR("PanIdConfFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *OrphanNotFrame.received(rxdata_t *data)
	{
		DBG_STR("OrphanNotFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *BeaconReqFrame.received(rxdata_t *data)
	{
		DBG_STR("BeaconReqFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *CoordRealignFrame.received(rxdata_t *data)
	{
		DBG_STR("CoordRealignFrame received not connected!",1);
		return data->frame;
	}
	
	default async event uint8_t *GtsReqFrame.received(rxdata_t *data)
	{
		DBG_STR("GtsReqFrame received not connected!",1);
		return data->frame;
	}
	
}
