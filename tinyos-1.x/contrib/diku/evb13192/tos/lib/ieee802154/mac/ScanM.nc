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

#include "MacConst.h"
#include "Ieee802154Adts.h"
#include "endianconv.h"

module ScanM
{
	provides
	{
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface StdControl;
	}
	uses
	{
		interface ScanService;
		interface IeeeBufferManagement as BufferMng;
		interface MacAddress;
		
		interface Debug;
	}

}
implementation
{
	#define DBG_LEVEL 3
	#include "Debug.h"
	
	// Orphan notification is inited with extended addr upon initialization.
	uint8_t beaconRequestFrame[8] = {0x03, 0x08, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x07};
	uint8_t orphanNotifyFrame[16] = {0x43, 0xC8, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
	                                 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06};

	Mlme_ScanRequestConfirm scanPrimitive;
	uint8_t *scanResult;
	uint8_t scanResultSize;
	bool coordinatorFound;

	uint8_t scanType;
	uint32_t channelsToScan = 0;
	
	bool apScanFilter(uint8_t *frame);
	bool orphanScanFilter(uint8_t *frame);
	task void scanConfirm();
	
	command result_t StdControl.init()
	{
		//NTOUH64(aExtendedAddress, mhrSrcAddr(orphanNotifyFrame));
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		// Init orphan notification frame.
		memcpy((mhrSrcAddr(orphanNotifyFrame)), aExtendedAddress, 8);
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
	
	event void ScanService.scanDone(uint32_t unscannedChannelsMap)
	{
		DBG_STR("Done scanning!!! :-)",3);
		DBG_STR("The following channels were NOT scanned:",3);
		DBG_INT(unscannedChannelsMap,3);
		scanPrimitive->msg.confirm.unscannedChannels = unscannedChannelsMap;
		scanPrimitive->msg.confirm.resultListLen = scanResultSize;
		if (scanType != IEEE802154_OrphanScan) {
			scanPrimitive->msg.confirm.resultList = scanResult;
			if (scanResultSize == 0) {
				scanPrimitive->msg.confirm.status = IEEE802154_NO_BEACON;
			} else {
				scanPrimitive->msg.confirm.status = IEEE802154_SUCCESS;
			}
		} else {
			scanPrimitive->msg.confirm.resultList = NULL;
			if (coordinatorFound) {
				scanPrimitive->msg.confirm.status = IEEE802154_SUCCESS;
			} else {
				scanPrimitive->msg.confirm.status = IEEE802154_NO_BEACON;
			}
		}
		post scanConfirm();
	}
	
	event void ScanService.beaconResult(uint8_t logicalChannel, rxdata_t *data)
	{
		if (scanType == IEEE802154_ActiveScan || scanType == IEEE802154_PassiveScan) {
			// Register information in PAN Descriptor list.
			panDescriptor_t *newEntry;
			uint8_t i;
			ieeeAddress_t source;
			
			// Get source address.
			call MacAddress.getSrcAddr(data->frame, &source);
			
			// Check that we have not heard from this coordinator before.
			for (i=0;i<scanResultSize;i++) {
				panDescriptor_t *prevEntry = (panDescriptor_t*)(scanResult + (i*sizeof(panDescriptor_t)));
				// Only consider entries on same channel.
				if (prevEntry->logicalChannel == logicalChannel && prevEntry->coordAddrMode == source.mode) {
					bool uniqueBeacon = FALSE;
					uint8_t *prevAddr = prevEntry->coordAddress;
					uint8_t j;
					if (prevEntry->coordAddrMode == 2) {
						if (*((uint16_t*)source.address) != *((uint16_t*)prevAddr)) {
							uniqueBeacon = TRUE;
						}
					} else {
						for (j=0;j<8;j++) {
							if (source.address[j] != prevAddr[j]) {
								uniqueBeacon = TRUE;
								break;
							}
						}
					}
					
					if (!uniqueBeacon) {
						// Check pan id.
						if (source.panId == prevEntry->coordPanId) {
							return;
						}
					}
				}
			}
			
			newEntry = (panDescriptor_t*)(scanResult + (scanResultSize*sizeof(panDescriptor_t)));
			
			memcpy(newEntry, &source, sizeof(ieeeAddress_t));
			newEntry->logicalChannel = logicalChannel;
			NTOUH16(msduGetSuperframeSpecPtr(data->frame), (uint8_t*)&(newEntry->superFrameSpec));
			newEntry->gtsPermit = msduGTSPermit(data->frame);
			newEntry->linkQuality = data->linkQuality;
			newEntry->timeStamp = data->recvTime;
			newEntry->securityUse = mhrSecurityEnabled(data->frame);
			newEntry->ACLEntry = 0x08; // TODO: Support security at some point.
			newEntry->securityFailure = FALSE;
			
			scanResultSize++;
			// TODO: Handle when result list full!
		}
	}
	
	event void ScanService.orphanResult()
	{
		if (scanType == IEEE802154_OrphanScan) {
			coordinatorFound = TRUE;
		}
	}
	
	event void ScanService.edResult(uint8_t logicalChannel, uint8_t maxLevel)
	{
		scanResult[logicalChannel] = maxLevel;
		scanResultSize++;
	}

	command result_t MlmeRequestConfirmScan.request(Mlme_ScanRequestConfirm request)
	{
		mlmeScanRequestMsg_t *req = &(request->msg.request);
		uint8_t resultMemSize = 0;
		uint32_t scanTimeout; // This is the timeout in symbols.

		scanPrimitive = request;
		// TODO: Suspend beacon transmission while scanning! Only scan related PHY data
		//     is accepted during a scan.
		
		// If any parameters in primitive are not supported or out of range,
		// signal confirm with status INVALID_PARAMETER.
		if (req->scanDuration > 14 || req->scanType > IEEE802154_OrphanScan) {
			request->msg.confirm.status = IEEE802154_INVALID_PARAMETER;
			return FAIL;
		}

		scanType = req->scanType;
		channelsToScan = req->scanChannels;
		// Set scan timeout.
/*		if (scanType == IEEE802154_OrphanScan) {
			scanTimeout = aResponseWaitTime;
		} else {*/
			scanTimeout = 1;
			scanTimeout = aBaseSuperframeDuration*((scanTimeout<<req->scanDuration)+1);
		//}

		scanResultSize = 0;
		// Init result list.
		if (scanType == IEEE802154_ActiveScan || scanType == IEEE802154_PassiveScan) {
			resultMemSize = sizeof(panDescriptor_t)*Ieee_Num_PAN_Desc;
		} else if (scanType == IEEE802154_EDScan) {
			resultMemSize = 27;
		}
		if (resultMemSize) {
			if (SUCCESS != call BufferMng.claim(resultMemSize, &scanResult)) {
				DBG_STR("FATAL: Scan, could not claim memory for scanResult",1);
			}
		}
		
		if (scanType == IEEE802154_EDScan) {
			call ScanService.edScan(scanTimeout, channelsToScan);
		} else if (scanType == IEEE802154_ActiveScan) {
			call ScanService.activeScan(beaconRequestFrame, 8, scanTimeout, channelsToScan, apScanFilter);
		} else if (scanType == IEEE802154_OrphanScan) {
			coordinatorFound = FALSE;
			call ScanService.activeScan(orphanNotifyFrame, 16, scanTimeout, channelsToScan, orphanScanFilter);
		} else if (scanType == IEEE802154_PassiveScan) {
			call ScanService.passiveScan(scanTimeout, channelsToScan, apScanFilter);
		}

		DBG_STR("MlmeRequestConfirmScan.request",1);
		return SUCCESS;
	}

	// Scan rx filter functions
	bool apScanFilter(uint8_t *frame)
	{
		uint8_t frameType = mhrFrameType(frame);
		if (frameType == macBeaconFrame) {
			return TRUE;
		}
		return FALSE;
	}
	
	bool orphanScanFilter(uint8_t *frame)
	{
		uint8_t frameType = mhrFrameType(frame);
		if (frameType == macCommandFrame) {
			uint8_t commandType = msduCommandFrameIdent(frame);
			if (commandType == macCommandCoordRealign) {
				return TRUE;
			}
		}
		return FALSE;
	}
	
	task void scanConfirm()
	{
		signal MlmeRequestConfirmScan.confirm(scanPrimitive);
	}
	
	default event void MlmeRequestConfirmScan.confirm(Mlme_ScanRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmScan.confirm",1);
	}
}
