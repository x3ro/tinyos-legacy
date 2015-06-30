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

module ScanServiceM
{
	provides
	{
		interface ScanService;
		interface Reset;
	}
	uses
	{
		interface PhyAttributes;
		interface RxFrame as BeaconFrame;
		interface RxFrame as CoordRealignFrame;
		interface FrameTx;
		interface FrameRx;
		interface AsyncAlarm<time_t> as Alarm;
		interface Ed;
		
		interface Debug;
	}

}
implementation
{
	#define DBG_LEVEL 3
	#include "Debug.h"
	
	bool (*rxFilter)(uint8_t*);
	void (*entryPoint)() = NULL;
	uint32_t scanTimeout; // This is the timeout in symbols.
	uint8_t curChannel = 0;
	uint32_t channelsToScan = 0;
	uint32_t scannedChannels;
	uint32_t phySupportedChannels;
	bool isScanning = FALSE;

	txdata_t scanData;

	void initScan();
	void scanTransmit();
	void scanReceive();
	void scanEnergy();
	
	task void enableRx();
	task void doScan();

	command void Reset.reset()
	{
		isScanning = FALSE;
	}

	async event uint8_t *BeaconFrame.received(rxdata_t *data)
	{
		if (isScanning) {
			signal ScanService.beaconResult(curChannel, data);
		}
		return data->frame;
	}

	async event uint8_t *CoordRealignFrame.received(rxdata_t *data)
	{
		if (isScanning) {
			uint32_t tmp = 1;
			call Alarm.stop();
			signal ScanService.orphanResult();
			scannedChannels |= tmp<<curChannel;
			// Make sure that our scan will end here.
			curChannel = 27;
			post doScan();
		}
		
		// Here we handle the realignment frame
		// We make sure that the coordinator that replies is set to be the
		// coordinator of the device.
		macPanId = *((uint16_t*)msduCoordRealignPANId(data->frame));
		macCoordShortAddress = *((uint16_t*)msduCoordRealignCoordShortAddr(data->frame));
		macShortAddress = *((uint16_t*)msduCoordRealignShortAddr(data->frame));
		memcpy(macCoordExtendedAddress, mhrSrcAddr(data->frame), 8);
		// Set the channel.
		if (SUCCESS != call PhyAttributes.setChannel(msduCoordRealignLogicalChannel(data->frame))) {
			DBG_STR("WARNING: Coordinator realignment, could not change radio channel!",1);
		}

		return data->frame;
	}

	command result_t ScanService.activeScan(uint8_t *txFrame, uint8_t length, uint32_t duration,
	                                        uint32_t channelMap, bool (*rxFilterFunc)(uint8_t*))
	{
		scanData.frame = txFrame;
		scanData.length = length;
		scanData.cca = FALSE;
		scanData.immediateCommence = TRUE;
		
		// Set the receive filter.
		if (SUCCESS != call PhyAttributes.setFilter(rxFilterFunc)) {
			DBG_STR("Warning: Scan, could not set receive filter!",1);
		}
		
		channelsToScan = channelMap;
		scanTimeout = duration;
		entryPoint = scanTransmit;
		initScan();
	}
	
	command result_t ScanService.passiveScan(uint32_t duration, uint32_t channelMap,
	                                         bool (*rxFilterFunc)(uint8_t*))
	{
		// Set the receive filter.
		if (SUCCESS != call PhyAttributes.setFilter(rxFilterFunc)) {
			DBG_STR("Warning: Scan, could not set receive filter!",1);
		}
	
		channelsToScan = channelMap;
		scanTimeout = duration;
		entryPoint = scanReceive;

		initScan();
	}
	
	command result_t ScanService.edScan(uint32_t duration, uint32_t channelMap)
	{
		channelsToScan = channelMap;
		scanTimeout = duration;
		entryPoint = scanEnergy;

		initScan();
	}
	
	void initScan()
	{
		curChannel = 0;
		scannedChannels = 0;
		phySupportedChannels = call PhyAttributes.getSupportedChannels();
		isScanning = TRUE;
		post doScan();
	}
	
	task void doScan()
	{
		uint32_t channel = 1;

		channel = channel << curChannel;
		while(!(channelsToScan & phySupportedChannels & channel) && curChannel < 27) {
			channel = channel << 1;
			curChannel++;
		}
		if (curChannel >= 27) {
			// We are done scanning.
			uint32_t unscanned = ~scannedChannels & channelsToScan;
			isScanning = FALSE;
			// shut off trx.
			call FrameRx.trxOff(TRUE);
			call PhyAttributes.clearFilter();
			signal ScanService.scanDone(unscanned);
			return;
		}

		// We found the next channel. Now set it in the Phy.
		if (SUCCESS != call PhyAttributes.setChannel(curChannel)) {
			DBG_STR("WARNING: Scan, could not change radio channel!",1);
			DBG_INT(curChannel,1);
		}
		entryPoint();
	}
	
	void scanTransmit()
	{
		mhrSeqNumber(scanData.frame) = macDsn++;
		if (PHY_SUCCESS != call FrameTx.tx(&scanData)) {
			DBG_STR("FATAL: Scan, Could not send scan data!",1);
		}
	}
	
	void scanReceive()
	{
		if (PHY_SUCCESS != call FrameRx.rxOnNow()) {
			DBG_STR("Warning: Scan, could not enable receiver!",1);
		}
		call Alarm.armCountdown(scanTimeout);
	}

	void scanEnergy()
	{
		if (SUCCESS != call Ed.perform(scanTimeout)) {
			DBG_STR("FATAL: Scan, could not perform ed scan!",1);
		}
	}

	async event void FrameTx.txDone(phy_error_t error)
	{
		if (error != PHY_SUCCESS) {
			DBG_STR("WARNING: Scan, frame not send!",1);
		}
		// The rest is just like a passive scan.
		scanReceive();
	}

	async event result_t Alarm.alarm()
	{
		uint32_t tmp = 1;
		scannedChannels |= tmp<<curChannel;
		curChannel++;
		post doScan();
		return SUCCESS;
	}

	async event void Ed.done(result_t status, uint8_t level)
	{
		uint32_t tmp = 1;
		if (status == SUCCESS) {
			signal ScanService.edResult(curChannel, level);
			scannedChannels |= tmp<<curChannel;
		}
		curChannel++;
		post doScan();
	}
}
