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

#include <macTypes.h>
#include <Int64Compare.h>

module TestIeee802154MacM
{
	provides {
		interface StdControl;
	}
	uses {
		
	    interface IeeeMacPibAttribute as IeeePibAttribute;
		interface IeeePanDescriptor;
		interface IeeeMacSdu as IeeeSdu;
		interface IeeeAddress;
	   
		interface McpsDataIndication;
		interface McpsDataRequestConfirm;
		interface McpsPurgeRequestConfirm;
	
		interface MlmeAssociateIndicationResponse; 
		interface MlmeAssociateRequestConfirm;
		interface MlmeDisassociateIndication;
		interface MlmeDisassociateRequestConfirm;
		interface MlmeGetRequestConfirm;
		interface MlmeGtsIndication;
		interface MlmeGtsRequestConfirm;
		interface MlmeScanRequestConfirm;
		interface MlmeSetRequestConfirm;
		interface MlmeStartRequestConfirm;
		interface MlmeSyncLossIndication;
		interface MlmeRxEnableRequestConfirm;
		interface MlmePollRequestConfirm;
		interface MlmeSyncRequest;
		interface MlmeCommStatusIndication;
		interface MlmeBeaconNotifyIndication;
		interface MlmeResetRequestConfirm;
		interface MlmeOrphanIndicationResponse;

		// MCPS
		interface IeeeIndication<Mcps_DataIndication> as McpsIndicationData;   	
		interface IeeeRequestConfirm<Mcps_DataRequestConfirm> as McpsRequestConfirmData;
		interface IeeeRequestConfirm<Mcps_PurgeRequestConfirm> as McpsRequestConfirmPurge;
		// MLME	
		interface IeeeIndicationResponse<Mlme_AssociateIndicationResponse> as MlmeIndicationResponseAssociate;
		interface IeeeRequestConfirm<Mlme_AssociateRequestConfirm> as MlmeRequestConfirmAssociate;
		interface IeeeIndication<Mlme_DisassociateIndication> as MlmeIndicationDisassociate;
		interface IeeeRequestConfirm<Mlme_DisassociateRequestConfirm> as MlmeRequestConfirmDisassociate;
		interface IeeeSyncRequestConfirm<Mlme_GetRequestConfirm> as MlmeRequestConfirmGet;
		interface IeeeIndication<Mlme_GtsIndication> as MlmeIndicationGts;
		interface IeeeRequestConfirm<Mlme_GtsRequestConfirm> as MlmeRequestConfirmGts;
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeSyncRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface IeeeRequestConfirm<Mlme_StartRequestConfirm> as MlmeRequestConfirmStart;
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface IeeeRequestConfirm<Mlme_RxEnableRequestConfirm> as MlmeRequestConfirmRxEnable;
		interface IeeeRequestConfirm<Mlme_PollRequestConfirm> as MlmeRequestConfirmPoll;
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;
		interface IeeeIndication<Mlme_CommStatusIndication> as MlmeIndicationCommStatus;
		interface IeeeIndication<Mlme_BeaconNotifyIndication> as MlmeIndicationBeaconNotify;
		interface IeeeRequestConfirm<Mlme_ResetRequestConfirm> as MlmeRequestConfirmReset;
		interface IeeeIndicationResponse<Mlme_OrphanIndicationResponse> as MlmeIndicationResponseOrphan;
		
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		interface Debug;
		
		//interface BufferManDebug;
	}
}

implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	char* testBuffer = "Hello World!";
	uint8_t testBufferLen = 12;
	Ieee_Msdu rcvMsdu;
	bool iAmCoordinator = FALSE;
	uint8_t assocDeviceAddr[8];
	bool iAmBeaconEnabled = FALSE;
	
	// The selected logical channel is store in here, initialized to 11
	uint8_t logicalChannel = 11;

	// Coordinator info retrieved by scan
	Ieee_Address coordAddr;
	uint16_t superframeSpec;
	void (*nextSetFunc)() = NULL;

	// GTS support.
	bool gtsSend = FALSE;

	// Data transmission support.
	uint8_t txType;
	uint16_t sendToAddr;

	// P2P send sender and recipient info
	uint8_t p2pRcptAddr[8] = {0x00, 0x50, 0xC2, 0x37, 0xB0, 0x01, 0x03, 0x02};
	uint8_t p2pSendAddr[8] = {0x00, 0x50, 0xC2, 0x37, 0xB0, 0x01, 0x03, 0x09};

	// Short address we got
	uint16_t panClientShort;
	uint16_t tos_local_address;  //This node
	
	uint8_t myMsduHandle = 0x01;
	uint8_t purgeHandle;

    // PAN address used when coordinator.
	uint16_t myPanId = 0xFEDE;

	/** Used to keep the commands the user type in */
	char cmd_input[200];
	char * bufpoint;

	/** Store data from the Console.get event here. */
	char console_data;

	void prompt();
	// Scan tasks
	task void ascan();
	task void pscan();
	task void edscan();
	task void orphanscan();

	task void help();
	task void info();
	task void requestSendGts();
	task void sendToDevice();
	task void startpan();
	task void disassociate();
	task void sync();
	task void doPurge();
	
	int strcmp(const char * a, const char * b);
	task void handleGet();
	
	void processScan(Mlme_ScanRequestConfirm scanconfirm);
	void processEdScan(Mlme_ScanRequestConfirm scanconfirm);
	void doScanning(uint8_t type, uint8_t duration, uint32_t channels);
	
	result_t setAttribute(Ieee_PibAttribute attribute);
	result_t getAttribute(Ieee_PibAttribute attribute);
	void setCoordAddrInfo();
	void setBeaconOrder();
	void setSuperframeOrder();
	void setShort(uint16_t myShort);
	void setAssoc(bool allow);
	void setRxOnWhenIdle(bool status);
	void getCoordExtAddr(uint8_t *addr);
	void setAutoRequest(bool autoRequest);
	void macReset();
 
	command result_t StdControl.init()
	{
		/* Set up our command buffer */
		bufpoint = cmd_input;
		*bufpoint = 0;
		tos_local_address = TOS_LOCAL_ADDRESS;
		return SUCCESS;
	}

	command result_t StdControl.start() { 
		prompt();
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return FAIL;
	}
	
	event void MlmeRequestConfirmRxEnable.confirm(Mlme_RxEnableRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeRxEnableRequestConfirm.getStatus(confirm);
		DBG_STRINT("RxEnable.confirm status:",status,1);
		call MlmeRxEnableRequestConfirm.destroy(confirm);
		prompt();
	}
	
	event void McpsIndicationData.indication(Mcps_DataIndication indication)
	{
		Ieee_Msdu msdu;
		char *buffer;
		uint16_t bufLength;
		call IeeeSdu.create(&msdu);
		call McpsDataIndication.getMsdu(indication, msdu);
		buffer = (char*)call IeeeSdu.getPayload(msdu);
		bufLength = call IeeeSdu.getPayloadLen(msdu);
		call ConsoleOut.print("Got 0x");
		call ConsoleOut.printHexword(bufLength);
		call ConsoleOut.print(" bytes of data:\n0x");
		call ConsoleOut.dumpHex(buffer, bufLength, ",0x");
		call ConsoleOut.print("\n");
		prompt();
		call McpsDataIndication.destroy(indication);
		call IeeeSdu.destroy(msdu);
	}
	
	event void McpsRequestConfirmData.confirm( Mcps_DataRequestConfirm confirm )
	{
		uint8_t handle = call McpsDataRequestConfirm.getMsduHandle(confirm);
		Ieee_Status status = call McpsDataRequestConfirm.getStatus(confirm);
		 
		DBG_STRINT("Data confirm for MSDU handle: ",handle,1);
		DBG_STRINT("Data confirm status:",status,1);
		prompt();
		call McpsDataRequestConfirm.destroy(confirm);
	}
	
	event void McpsRequestConfirmPurge.confirm( Mcps_PurgeRequestConfirm confirm )
	{
		// We already know if the purge succeeded.. Just destroy the primitive
		call McpsPurgeRequestConfirm.destroy(confirm);
	}
	
	event void MlmeIndicationSyncLoss.indication( Mlme_SyncLossIndication indication)
	{
		call ConsoleOut.print("Sync lost! Reason: 0x");
		call ConsoleOut.printHex(call MlmeSyncLossIndication.getLossReason(indication));
		call ConsoleOut.print("\n");
		call MlmeSyncLossIndication.destroy(indication);
	}
	
	event void MlmeIndicationBeaconNotify.indication( Mlme_BeaconNotifyIndication indication )
	{
		uint8_t bsn;
		bsn = call MlmeBeaconNotifyIndication.getBsn(indication);
		DBG_STRINT("Got a beacon: ",bsn,1);
		call MlmeBeaconNotifyIndication.destroy(indication);
	}
	
	event void MlmeIndicationCommStatus.indication( Mlme_CommStatusIndication indication )
	{
/*		Ieee_Address srcAddr;
		Ieee_Address dstAddr;
		uint8_t srcMode;
		uint8_t dstMode;

		call MlmeCommStatusIndication.getSrcAddr(indication, srcAddr);
		call MlmeCommStatusIndication.getDstAddr(indication, dstAddr);
		
		srcMode = call IeeeAddress.getAddrMode(srcAddr);
		dstMode = call IeeeAddress.getAddrMode(dstAddr);*/

		call ConsoleOut.print("Got a Comm Status indication..\n");
/*		if (srcMode) {
			call ConsoleOut.print("Source was:\n");
			call ConsoleOut.print("PAN ID: 0x");
			call ConsoleOut.printHexword(call IeeeAddress.getPanId(srcAddr));
			call ConsoleOut.print("\n");
			call ConsoleOut.print("Address: 0x");
			if (srcMode == 2) {
				call ConsoleOut.dumpHex(call IeeeAddress.getAddress(srcAddr), 2, "");
				call ConsoleOut.print("\n");
			} else {
				call ConsoleOut.dumpHex(call IeeeAddress.getAddress(srcAddr), 8, "");
				call ConsoleOut.print("\n");			
			}
		} else {
			call ConsoleOut.print("No source info specified!\n");
		}

		if (dstMode) {
			call ConsoleOut.print("Destination was:\n");
			call ConsoleOut.print("PAN ID: 0x");
			call ConsoleOut.printHexword(call IeeeAddress.getPanId(dstAddr));
			call ConsoleOut.print("\n");
			call ConsoleOut.print("Address: 0x");
			if (dstMode == 2) {
				call ConsoleOut.dumpHex(call IeeeAddress.getAddress(dstAddr), 2, "");
				call ConsoleOut.print("\n");
			} else {
				call ConsoleOut.dumpHex(call IeeeAddress.getAddress(dstAddr), 8, "");
				call ConsoleOut.print("\n");			
			}
		} else {
			call ConsoleOut.print("No destination info specified!\n");
		}*/

		call ConsoleOut.print("Status was: 0x");
		call ConsoleOut.printHex(call MlmeCommStatusIndication.getStatus(indication));
		call ConsoleOut.print("\n");

		prompt();
		
		// Clean up.
		call MlmeCommStatusIndication.destroy(indication);
//		call IeeeAddress.destroy( srcAddr );
//		call IeeeAddress.destroy( dstAddr );
	}
	
	async event void MlmeIndicationResponseAssociate.indication( Mlme_AssociateIndicationResponse indication )
	{
		call MlmeAssociateIndicationResponse.getDeviceAddress(indication, assocDeviceAddr);
		call ConsoleOut.print("Device is at ");
		call ConsoleOut.dumpHex(assocDeviceAddr, 8, "");
		call ConsoleOut.print("\n");

		call MlmeAssociateIndicationResponse.setDeviceAddress(indication,assocDeviceAddr);
		call MlmeAssociateIndicationResponse.setAssocShortAddress(indication,0x0003);
		call MlmeAssociateIndicationResponse.setStatus(indication,0);
		call MlmeIndicationResponseAssociate.response(indication);
		prompt();
	}
	
	async event void MlmeIndicationResponseOrphan.indication( Mlme_OrphanIndicationResponse indication )
	{
		uint8_t orphanedDevice[8];
		call MlmeOrphanIndicationResponse.getOrphanAddress(indication, orphanedDevice);
		DBG_STR("Orphaned device is at:",1);
		DBG_DUMP(orphanedDevice, 8, 1);
		
		// Create response.
		call MlmeOrphanIndicationResponse.setOrphanAddress(indication, orphanedDevice);
		call MlmeOrphanIndicationResponse.setShortAddress(indication, 0x0003);
		call MlmeOrphanIndicationResponse.setAssociatedMember(indication, TRUE);
		call MlmeIndicationResponseOrphan.response(indication);
		prompt();
	}

	event void MlmeIndicationDisassociate.indication( Mlme_DisassociateIndication indication )
	{
		Ieee_Status status;

		status = call MlmeDisassociateIndication.getDisassociateReason(indication);

		if (status == IEEE802154_PAN_COORD_LEAVE) {
			DBG_STR("Disassociated by coordinator!",1);
		} else {
			uint8_t deviceAddress[8];
			call MlmeDisassociateIndication.getDeviceAddress(indication, deviceAddress);
			call ConsoleOut.print("Device at ");
			call ConsoleOut.dumpHex(deviceAddress, 8, "");
			call ConsoleOut.print(" disassociated\n");
		}
		call MlmeDisassociateIndication.destroy(indication);
		
		prompt();
	}

	event void MlmeRequestConfirmAssociate.confirm(Mlme_AssociateRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeAssociateRequestConfirm.getStatus(confirm);
		panClientShort = call MlmeAssociateRequestConfirm.getAssocShortAddress(confirm);
		call ConsoleOut.print("MlmeRequestConfirmAssociate.confirm, check status and address\n");
		call ConsoleOut.print("Short address: 0x");
		call ConsoleOut.printHexword(panClientShort);
		call ConsoleOut.print(", status: 0x");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
		call MlmeAssociateRequestConfirm.destroy(confirm);
		prompt();
	}
	
	event void MlmeRequestConfirmReset.confirm(Mlme_ResetRequestConfirm confirm)
	{
		call MlmeResetRequestConfirm.destroy(confirm);
		prompt();
	}
	
	event void MlmeRequestConfirmDisassociate.confirm(Mlme_DisassociateRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeDisassociateRequestConfirm.getStatus(confirm);
		call MlmeDisassociateRequestConfirm.destroy(confirm);
		DBG_STRINT("MlmeRequestConfirmDisassociate.confirm, status was: ",status,1);
		prompt();
	}
  
  	event void MlmeRequestConfirmGts.confirm(Mlme_GtsRequestConfirm confirm)
  	{
  		Ieee_Status status = call MlmeGtsRequestConfirm.getStatus(confirm);
  		call ConsoleOut.print("MlmeRequestConfirmGts.confirm, status ");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
  		call MlmeGtsRequestConfirm.destroy(confirm);
  		if (!status && gtsSend) {
  			// We send a frame in our gts send slot.
  			post sendToDevice();
  		} else {
  			prompt();
  		}
  	}
  	
  	event void MlmeIndicationGts.indication( Mlme_GtsIndication indication )
  	{
  		call ConsoleOut.print("MlmeRequestConfirmGts.indication\n ");
  		prompt();
  		call MlmeGtsIndication.destroy(indication);
  	}
  	
  	event void MlmeRequestConfirmGet.confirm(Mlme_GetRequestConfirm confirm)
	{
		// We don't do anything here as we handle get requests in sync.
  	}
  	
	event void MlmeRequestConfirmSet.confirm(Mlme_SetRequestConfirm confirm)
	{
		// We don't do anything here as we handle set requests in sync.
	}
  
	event void MlmeRequestConfirmScan.confirm(Mlme_ScanRequestConfirm confirm)
	{
		uint8_t scanType,resultListSize;			
		Ieee_Status status = call MlmeScanRequestConfirm.getStatus(confirm);
/*		call ConsoleOut.print("MlmeRequestConfirmScan.confirm, status ");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");*/
		scanType = call MlmeScanRequestConfirm.getScanType(confirm);
		resultListSize = call MlmeScanRequestConfirm.getResultListSize(confirm);		
			
 		if (scanType == IEEE802154_EDScan) {
			// Energy Detection Scan
 			if (status == IEEE802154_SUCCESS) {
				processEdScan(confirm);
 			}
		} else if (scanType == IEEE802154_PassiveScan || scanType == IEEE802154_ActiveScan) {
			// Active Scan or passive scan
			// Check status
			if (status == IEEE802154_SUCCESS) {
				processScan(confirm);
			} else if (status == IEEE802154_NO_BEACON) {
				DBG_STR("No beacon in scan :-(",1);
			}
		} else if (scanType == IEEE802154_OrphanScan) {
			// Orphan scan mode
			if (status == IEEE802154_SUCCESS) {
				DBG_STR("Found my coordinator :-)",1);
			} else if (status == IEEE802154_NO_BEACON) {
				DBG_STR("Coordinator not found :-(",1);
			}
		}
		call MlmeScanRequestConfirm.destroy(confirm);
		prompt();
	}
	
	event void MlmeRequestConfirmStart.confirm(Mlme_StartRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeStartRequestConfirm.getStatus(confirm);
		call ConsoleOut.print("MLME_START.confirm, status: 0x");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
		call MlmeStartRequestConfirm.destroy(confirm);
		if (!status) iAmCoordinator = TRUE;
		prompt();
	}

	event void MlmeRequestConfirmPoll.confirm(Mlme_PollRequestConfirm confirm)
	{	    
		Ieee_Status status = call MlmePollRequestConfirm.getStatus(confirm);
    
		call ConsoleOut.print("MLME_POLL.confirm status: 0x");
		call ConsoleOut.printHexword(status);
		call ConsoleOut.print("\n");
 		call MlmePollRequestConfirm.destroy(confirm);
		prompt();
	}

	/**************************************************************************/
	/**
	 * Console data event.
	 *
	 * <p>We store the data, post a task.</p>
	 *
	 * @param data The data from the console.
	 * @return SUCCESS always.
	 */
	/**************************************************************************/
	async event result_t ConsoleIn.get(uint8_t data) {
		atomic console_data = data;
		post handleGet();
		return SUCCESS;
	}
	
	/* ********************************************************************** */
	/** Post an activity scan, that is, talk to the MLME layer.
	 *
	 * <p>Scans all channels, as indicated by the 0x07FFFF800 bit mask,
	 * each channel is scanned for approximately 0.5 seconds (indicated
	 * by the 5, note, there is a non linear relation between 0.5 secs
	 * and 5).</p> 
	 */
	/* ********************************************************************** */

	void doScanning(uint8_t type, uint8_t duration, uint32_t channels)
	{
		Mlme_ScanRequestConfirm request;
		// Activity scan, all channels, approximately 0.5 sec on each 
		// create the scan request
		call MlmeScanRequestConfirm.create(&request);
		call MlmeScanRequestConfirm.setScanType(request,type);
		call MlmeScanRequestConfirm.setScanChannels(request,channels);
		call MlmeScanRequestConfirm.setScanDuration(request,duration);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			DBG_STR("Starting scan...",1);
		}
		else
		{
			DBG_STR("Could not start scan...",1);
		}
	}
	
	task void ascan()
	{
		doScanning(IEEE802154_ActiveScan, 6, 0x07FFF800);
	}
	
	task void pscan()
	{
		doScanning(IEEE802154_PassiveScan, 0x0A, 0x00000800);
	}
	
	task void edscan()
	{
		doScanning(IEEE802154_EDScan, 5, 0x07FFF800);
	}
	
	task void orphanscan()
	{
		doScanning(IEEE802154_OrphanScan, 0x0A, 0x07FFF800);
	}
	
	/* ********************************************************************** */
	/** 
	 * Handle the result of a active or passive scan
	 *
 	*/
	/* ********************************************************************** */
	void processScan(Mlme_ScanRequestConfirm scanconfirm)
	{
		uint8_t linkQuality,bestLinkQuality = 0;
		uint8_t i,listSize;
		uint16_t sframeSpec;
		// Warning: we assume the requestbuffer still has the scan confirm msg.
		Ieee_PanDescriptor pd,bestPd = NULL;
		
		listSize = call MlmeScanRequestConfirm.getResultListSize(scanconfirm);
		DBG_STRINT("Examining :",listSize,1);
		for (i = 0; i < listSize; i++) {
			pd = call MlmeScanRequestConfirm.getPanDescriptor(scanconfirm,i);
			sframeSpec = call IeeePanDescriptor.getSuperframeSpec(pd);

			// TODO: change this to be freescale independent
/*			if ( (sframeSpec & gSuperFrameSpecMsbAssocPermit_c) &&
			     (sframeSpec>>8 & gSuperFrameSpecLsbBO_c) == 0x7 ) {*/
			     linkQuality = call IeeePanDescriptor.getLinkQuality(pd);
				// Get the best
				if (linkQuality >= bestLinkQuality) {
					bestLinkQuality = linkQuality;
					bestPd = pd;
				}
//			}
		}

		// TODO: get rid of the pointer assumptions and the freescale stuff
		if (bestPd) {
			//memcpy(panInfo, bestPd, sizeof(panDescriptor_t));
			call ConsoleOut.print("Found a link!\n");
			call IeeeAddress.create(&coordAddr);
			//This is where everything is A-OK.
		} else {
			call ConsoleOut.print("No best link?\n");
			return;
		}
		call IeeePanDescriptor.getCoordAddr(bestPd, coordAddr);
//		call ConsoleOut.print("scan found coordinator:\n");
//		call ConsoleOut.print("Address 0x"); 
		
/*		if (call IeeeAddress.getAddrMode(coordAddr) == 2) {
			
			call ConsoleOut.dumpHex(call IeeeAddress.getAddress(coordAddr), 2, "");
		} else {
			call ConsoleOut.dumpHex(call IeeeAddress.getAddress(coordAddr), 8, "");
		}*/
		
		call ConsoleOut.print("\nPAN ID 0x");
		call ConsoleOut.printHexword(call IeeeAddress.getPanId(coordAddr));
    
//		call ConsoleOut.print("\nLogical Channel 0x");
		logicalChannel = call IeeePanDescriptor.getLogicalChannel(bestPd);
//		call ConsoleOut.printHex(logicalChannel);
    
//		call ConsoleOut.print("\nBeacon Spec 0x");
		superframeSpec = call IeeePanDescriptor.getSuperframeSpec(bestPd);
//		call ConsoleOut.printHexword(superframeSpec);
    
//		call ConsoleOut.print("\nLink Quality 0x"); 
//		call ConsoleOut.printHex(call IeeePanDescriptor.getLinkQuality(bestPd));
//		call ConsoleOut.print("\n");
		
		
		if (iAmBeaconEnabled) {
			// Set PIB attributes according to the selected coordinator
			// and synchronize.
			setCoordAddrInfo();
			setBeaconOrder();
			setSuperframeOrder();
			post sync();
		}
	}
	
	/* ********************************************************************** */
	/** 
	 * Handle the result of the energy detection scan.
	 *
	 * <p>This task does printing outside interrupt context. We should
	 * really store the msg, then examine it here, instead of the
	 * interrupt context. Must think about the memory management of the
	 * interface/802.15.4 layer. </p>
	 */
	/* ********************************************************************** */
	void processEdScan(Mlme_ScanRequestConfirm scanconfirm)
	{
		uint8_t n,minEnergy,listSize;
		// Set the minimum energy to a large value 
		minEnergy = 0xFF;
		// Select default channel 
		logicalChannel = 0;
		
		listSize = call MlmeScanRequestConfirm.getResultListSize(scanconfirm);
      
		// Search for the channel with least energy 
		for(n=0; n<listSize; n++) {
			uint8_t energy = call MlmeScanRequestConfirm.getEnergyDetectElement(scanconfirm, n);
			if(energy < minEnergy) {
				minEnergy = energy;
				logicalChannel = n;
			}
		}
      
		// Channel numbering is 11 to 26 both inclusive 
		logicalChannel += 11;
		
		call ConsoleOut.print("Selected channel ");
		call ConsoleOut.printHex(logicalChannel);
		call ConsoleOut.print("\n"); 
		prompt();
	}
	
	/* ********************************************************************** */
	/**
	 * Associate to a pan.
	 *
	 * <p>Use the value found in ascan to associate to a PAN</p>
	 */
	/* ********************************************************************** */
	task void associate() __attribute__((noinline))
	{
		Mlme_AssociateRequestConfirm request;
		
		call MlmeAssociateRequestConfirm.create(&request, coordAddr);
		call MlmeAssociateRequestConfirm.setLogicalChannel(request, logicalChannel);
		call MlmeAssociateRequestConfirm.setCapabilityInformation(request,IEEE802154_CapInfoAllocAddr);
		
		if (call MlmeRequestConfirmAssociate.request(request))
		{
			DBG_STR("Associating to PAN",1);
		}
		else
		{
			DBG_STR("Could not request association to PAN...",1);
			prompt();
		}
		//call IeeeAddress.destroy(coordAddr);
	}
	
	task void disassociate()
	{
		Mlme_DisassociateRequestConfirm request;
		
		call MlmeDisassociateRequestConfirm.create(&request);
		
		if (iAmCoordinator) {
			call MlmeDisassociateRequestConfirm.setDeviceAddress(request, assocDeviceAddr);
			call MlmeDisassociateRequestConfirm.setDisassociateReason(request,IEEE802154_PAN_COORD_LEAVE);
		} else {
			uint8_t myCoordAddr[8];
			getCoordExtAddr(myCoordAddr);
			call MlmeDisassociateRequestConfirm.setDeviceAddress(request, myCoordAddr);
			call MlmeDisassociateRequestConfirm.setDisassociateReason(request,IEEE802154_PAN_DEVICE_LEAVE);
		}
		call MlmeRequestConfirmDisassociate.request(request);
	}
	
	task void requestSendGts()
	{
		Mlme_GtsRequestConfirm request;
		
		call MlmeGtsRequestConfirm.create(&request);
		call MlmeGtsRequestConfirm.combineGtsCharacteristics(request,1,0,1);
		
		if (call MlmeRequestConfirmGts.request(request))
		{
			call ConsoleOut.print("Requesting guaranteed timeslot... \n");
		}
		else
		{
			call ConsoleOut.print("Could not request guaranteed timeslot... \n");
			prompt();
		}
	}
	
	task void dropGts()
	{
		Mlme_GtsRequestConfirm request;
		
		call MlmeGtsRequestConfirm.create(&request);
		call MlmeGtsRequestConfirm.combineGtsCharacteristics(request,1,0,0);
		
		if (call MlmeRequestConfirmGts.request(request))
		{
			call ConsoleOut.print("Dropping guaranteed timeslot... \n");
		}
		else
		{
			call ConsoleOut.print("Could not drop guaranteed timeslot... \n");
			prompt();
		}
	}
	
	/* ********************************************************************** */
	/**
	 * Testing send.
	 *
	 * !!! JMS: fix msduHandle, msduLength not sizeof(sendbuffer) but something else than 12...
 	 * @param
 	 * @return
	 */
	/* ********************************************************************** */
/*	task void send() {

		Ieee_Address srcAddr;
		Ieee_Address dstAddr;
		Mcps_DataRequestConfirm request;
		Ieee_Msdu myMsdu;

		call IeeeAddress.create( &srcAddr );
		call IeeeAddress.create( &dstAddr );
		call IeeeSdu.create( &myMsdu );

		if (panClientShort == 0xFFFE) {
			call ConsoleOut.print("Sending using extended address\n");
			call IeeeAddress.setAddrMode( srcAddr, 3);
			call IeeeAddress.setAddress( srcAddr, (uint8_t*)aExtendedAddress );
		} else {
			call ConsoleOut.print("Sending using short address\n");
			call IeeeAddress.setAddrMode( srcAddr, 2);
			call IeeeAddress.setAddress( srcAddr, (uint8_t*)&panClientShort );
		}

		call IeeeAddress.setPanId( srcAddr, call IeeeAddress.getPanId( coordAddr ));

		// Create request
		call McpsDataRequestConfirm.create(&request, srcAddr, coordAddr, testBufferLen);    	

		call McpsDataRequestConfirm.getMsdu( request, myMsdu );
		memcpy(call IeeeSdu.getPayload( myMsdu ), testBuffer, testBufferLen);
		call McpsDataRequestConfirm.setMsduHandle( request, 0x42 );
		call McpsDataRequestConfirm.setTxOptions( request, IEEE802154_TxOptsAck );

		call McpsRequestConfirmData.request(request);
	}
	
	
	task void p2psend() {

		Ieee_Address srcAddr;
		Ieee_Address dstAddr;
		Mcps_DataRequestConfirm request;
		Ieee_Msdu myMsdu;

		call IeeeAddress.create( &srcAddr );
		call IeeeAddress.create( &dstAddr );
		call IeeeSdu.create( &myMsdu );

		call ConsoleOut.print("Sending using extended address\n");
		call IeeeAddress.setAddrMode( srcAddr, 3);
		call IeeeAddress.setAddress( srcAddr, p2pSendAddr );
		call IeeeAddress.setPanId( srcAddr, myPanId);
		
		call IeeeAddress.setAddrMode( dstAddr, 3);
		call IeeeAddress.setAddress( dstAddr, p2pRcptAddr );
		call IeeeAddress.setPanId( dstAddr, 0xFFFF);
		
		// Create request
		call McpsDataRequestConfirm.create(&request, srcAddr, dstAddr, testBufferLen);    	

		call McpsDataRequestConfirm.getMsdu( request, myMsdu );
		memcpy(call IeeeSdu.getPayload( myMsdu ), testBuffer, testBufferLen);
		call McpsDataRequestConfirm.setMsduHandle( request, myMsduHandle++ );
		call McpsDataRequestConfirm.setTxOptions( request, IEEE802154_TxOptsAck );

		call McpsRequestConfirmData.request(request);
		
		// clean up
		call IeeeAddress.destroy( srcAddr );
		call IeeeAddress.destroy( dstAddr );
		call IeeeSdu.destroy( myMsdu );
	}*/

	task void doPurge()
	{
		Mcps_PurgeRequestConfirm request;
		
		call McpsPurgeRequestConfirm.create(&request);
		call McpsPurgeRequestConfirm.setMsduHandle(request, purgeHandle);
		
		if (SUCCESS == call McpsRequestConfirmPurge.request(request)) {
			DBG_STRINT("Succesfully purged entry with handle: ", purgeHandle, 1);
		} else {
			DBG_STRINT("Purge failed. No such entry: ", purgeHandle, 1);
		}
		prompt();
	}

	task void sendToDevice()
	{
		Ieee_Address srcAddr;
		Ieee_Address dstAddr;
		Mcps_DataRequestConfirm request;
		Ieee_Msdu myMsdu;
		
		call IeeeAddress.create( &srcAddr );
		call IeeeAddress.create( &dstAddr );
		call IeeeSdu.create( &myMsdu );

		// Fill out destination address..
		// It is assumed that the transmission is intra-pan.
		call IeeeAddress.setAddrMode( dstAddr, 2 );
		call IeeeAddress.setAddress( dstAddr, (uint8_t*)&sendToAddr );
		call IeeeAddress.setPanId( dstAddr, myPanId);

		// Fill out the source address.
		call IeeeAddress.setAddrMode( srcAddr, 2 );
		call IeeeAddress.setAddress( srcAddr, (uint8_t*)&tos_local_address );
		call IeeeAddress.setPanId( srcAddr, myPanId);
    
		// Create request
		call McpsDataRequestConfirm.create(&request, srcAddr, dstAddr, testBufferLen);    	

		call McpsDataRequestConfirm.getMsdu( request, myMsdu );
		memcpy(call IeeeSdu.getPayload( myMsdu ), testBuffer, testBufferLen);
		call McpsDataRequestConfirm.setMsduHandle( request, myMsduHandle );
		call McpsDataRequestConfirm.setTxOptions( request, (0x01 | txType) );

		if (SUCCESS == call McpsRequestConfirmData.request(request)) {
			DBG_STRINT("Data succesfully queued for transmission to device at: ",sendToAddr,1);
			DBG_STRINT("MSDU Handle is: ",myMsduHandle,1);
			myMsduHandle++;
		} else {
			DBG_STR("Transmission failed",1);
		}
		prompt();
		
		// Clean up.
		call IeeeAddress.destroy( srcAddr );
		call IeeeAddress.destroy( dstAddr );
		call IeeeSdu.destroy( myMsdu );
	}
  
	task void poll()
	{
		Mlme_PollRequestConfirm request;

		//create poll request
		call MlmePollRequestConfirm.create( &request, coordAddr );
		//do request
		if (SUCCESS == call MlmeRequestConfirmPoll.request( request )) {
			call ConsoleOut.print("Polled coordinator!\n");
		} else {
			call ConsoleOut.print("Poll failed!\n");
			prompt();
		}
		
    		// Clean up!
    		call IeeeAddress.destroy(coordAddr);
	}

	void setCoordAddrInfo()
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(8,&attribute);
		
		if (call IeeeAddress.getAddrMode(coordAddr) == 2) {
			uint16_t myAddr;
			call IeeeAddress.getAddress(coordAddr, (uint8_t*)&myAddr);
			call IeeePibAttribute.setMacCoordShortAddress(attribute,myAddr);
		} else {
			uint8_t myAddr[8];
			call IeeeAddress.getAddress(coordAddr, myAddr);
			call IeeePibAttribute.setMacCoordExtendedAddress(attribute,myAddr);
		}
		// Set coordinator address
		setAttribute(attribute);
		
		call IeeePibAttribute.create(2,&attribute);
		call IeeePibAttribute.setMacPanId(attribute,call IeeeAddress.getPanId(coordAddr));

		setAttribute(attribute);
	}
	
	void setBeaconOrder()
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacBeaconOrder(attribute,(superframeSpec&0x000F));

		setAttribute(attribute);
	}
	
	void setSuperframeOrder()
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacSuperframeOrder(attribute,(superframeSpec&0x00F0)>>4);
		
		setAttribute(attribute);
	}

	void setAutoRequest(bool autoRequest)
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacAutoRequest(attribute,autoRequest);
		
		setAttribute(attribute);
	}

	void setRxOnWhenIdle(bool status)
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacRxOnWhenIdle(attribute,status);
		
		setAttribute(attribute);
	}

	task void sync()
	{
		Mlme_SyncRequest request;

		//create sync request
		call MlmeSyncRequest.create( &request );
		call MlmeSyncRequest.setLogicalChannel(request, logicalChannel);
		call MlmeSyncRequest.setTrackBeacon(request, TRUE);
		
		//do request
		if (SUCCESS == call MlmeRequestSync.request( request )) {
			call ConsoleOut.print("Beacon tracking requested!\n");
		} else {
			call ConsoleOut.print("Beacon tracking request failed!\n");
		}
		prompt();
	}

	void macReset()
	{
		Mlme_ResetRequestConfirm request;

		call MlmeResetRequestConfirm.create( &request );
		call MlmeResetRequestConfirm.setSetDefaultPib(request, FALSE);
		
		//do request
		call MlmeRequestConfirmReset.request(request);
	}

	task void rxon()
	{
		Mlme_RxEnableRequestConfirm request;
		
		call MlmeRxEnableRequestConfirm.create(&request);
		call MlmeRxEnableRequestConfirm.setRxOnDuration(request,10000);
		call MlmeRequestConfirmRxEnable.request(request);
	}
	
	task void rxoff()
	{
		Mlme_RxEnableRequestConfirm request;
		
		call MlmeRxEnableRequestConfirm.create(&request);
		call MlmeRxEnableRequestConfirm.setRxOnDuration(request,0);
		call MlmeRequestConfirmRxEnable.request(request);
	}
	
	task void setPromiscuous()
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacPromiscuousMode(attribute,TRUE);
		
		setAttribute(attribute);
		prompt();
	}
	
	/* ********************************************************************** */
	/**
	 * Setting the short addres.
	 *
	 * <p>Sets the short address to TOS_LOCAL_ADDRESS, by calling </p>
	 */
	/* ********************************************************************** */
	void setShort(uint16_t myShort)
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(2,&attribute);
		call IeeePibAttribute.setMacShortAddress(attribute,myShort);
		
		setAttribute(attribute);
	}

	task void getshort()
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(2,&attribute);
		call IeeePibAttribute.setPibAttributeType(attribute,IEEE802154_macShortAddress);
		
		getAttribute(attribute);
		
		call ConsoleOut.printHexword(call IeeePibAttribute.getMacShortAddress(attribute));
		call ConsoleOut.print("\n");
		prompt();
	}
	
	void getCoordExtAddr(uint8_t *addr)
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(8,&attribute);
		call IeeePibAttribute.setPibAttributeType(attribute,IEEE802154_macCoordExtendedAddress);
		
		getAttribute(attribute);
		
		memcpy(addr, call IeeePibAttribute.getMacCoordExtendedAddress(attribute), 8);
		call IeeePibAttribute.destroy(attribute);
	}

	/* ********************************************************************** */
	/**
	 * Set the association status
	 *
	 * <p>This PIB setting must be set after starting the PAN.</p>
	 */
	/* ********************************************************************** */
 
	result_t setAttribute(Ieee_PibAttribute attribute)
	{
		Mlme_SetRequestConfirm request;
		Ieee_Status status;
		call MlmeSetRequestConfirm.create(&request);
		call MlmeSetRequestConfirm.setPibAttribute(request,attribute);
		request = call MlmeRequestConfirmSet.request(request);
		
		status = call MlmeSetRequestConfirm.getStatus(request);
		if (SUCCESS != call IeeePibAttribute.destroy(attribute)) {
			DBG_STR("Could not destroy attribute",1);
		}
		call MlmeSetRequestConfirm.destroy(request);
		if (status != IEEE802154_SUCCESS) {
			call ConsoleOut.print("Set operation was unsuccessful!\n");
			return FAIL;
		}
		return SUCCESS;
	}
	
	result_t getAttribute(Ieee_PibAttribute attribute)
	{
		Mlme_GetRequestConfirm request;
		Ieee_Status status;
		
		call MlmeGetRequestConfirm.create(&request);
		call MlmeGetRequestConfirm.setPibAttribute(request,attribute);
	
		request = call MlmeRequestConfirmGet.request(request);
		
		attribute = call MlmeGetRequestConfirm.getPibAttribute(request);
		status = call MlmeGetRequestConfirm.getStatus(request);
		call MlmeGetRequestConfirm.destroy(request);

		if (status != IEEE802154_SUCCESS) {
			call ConsoleOut.print("Get operation was unsuccessful!\n");
			return FAIL;
		}
		return SUCCESS;
	}
 
	void setAssoc(bool allow)
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacAssociationPermit(attribute,allow);
		setAttribute(attribute);
	}
	
	task void getassoc()
	{
		Ieee_PibAttribute attribute;
		
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setPibAttributeType(attribute,IEEE802154_macAssociationPermit);
		
		getAttribute(attribute);
		
		if (call IeeePibAttribute.getMacAssociationPermit(attribute)) {
			DBG_STR("Association permitted!",1);
		} else {
			DBG_STR("Association not permitted!",1);
		}
		prompt();
	}
	
	task void setBsd()
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacAssociationPermit(attribute,TRUE);
		
		setAttribute(attribute);
		prompt();
	}
	
	
	/* ********************************************************************** */
	/**
	 * Starting a PAN
	 *
	 * <p>Starts a PAN - assumes that we have set things like
	 * logicalChannel, etc.</p>
	 *
	 * <p>Note, that the Freescale stack leaves RX on after a PAN
	 * start. This is not standard behaviour.</p>
	 */
	/* ********************************************************************** */
	task void startpan()
	{
		Mlme_StartRequestConfirm request;
		uint8_t beaconOrder;
		uint8_t superframeOrder;
		
		if (iAmBeaconEnabled) {
			beaconOrder = 0x0A;
			superframeOrder = 0x0A;
		} else {
			beaconOrder = 0x0F;
			superframeOrder = 0x0F;
		}
		
		// Set my short address and association permit first.
		setShort(TOS_LOCAL_ADDRESS);
		setAssoc(TRUE);
		setRxOnWhenIdle(TRUE);
		
		call MlmeStartRequestConfirm.create(&request);
		call MlmeStartRequestConfirm.setPanId(request,myPanId);
		call MlmeStartRequestConfirm.setLogicalChannel(request,logicalChannel);
		call MlmeStartRequestConfirm.setBeaconOrder(request,beaconOrder);
		call MlmeStartRequestConfirm.setSuperframeOrder(request,superframeOrder);
		call MlmeStartRequestConfirm.setPanCoordinator(request,TRUE);
		call MlmeStartRequestConfirm.setBatteryLifeExtension(request,FALSE);
		call MlmeStartRequestConfirm.setCoordRealignment(request,FALSE);
		call MlmeStartRequestConfirm.setSecurityEnable(request,FALSE);
		call MlmeRequestConfirmStart.request(request);
	}
  
  	/* ********************************************************************** */
	/**
	 * Print help task.
	 *
	 * <p>Prints help about how to set up as a pan coordinator or as a
	 * slave that joins a PAN</p>
	 */
	/* ********************************************************************** */
	task void help()
	{
		call ConsoleOut.print("Try ls\n");
		call ConsoleOut.print("To become PAN coordinator: setshort -> startpan -> setassoc\n");
		call ConsoleOut.print("To join a PAN network: ascan -> associate -> send \n");
		prompt();
	}

	/* ********************************************************************** */
	/**
	 * Print info task.
	 *
	 * <p>Dumps our mac address and local TOS number </p>
	 */
	/* ********************************************************************** */
	task void info()
	{
		call ConsoleOut.print("Node 0x");
		call ConsoleOut.printHexword(TOS_LOCAL_ADDRESS);
		call ConsoleOut.print(" has MAC extended address 0x");
		call ConsoleOut.dumpHex(aExtendedAddress, 8, "");
		call ConsoleOut.print("\n");
		prompt();
	}

	/* **********************************************************************
	 * Handle stuff from the console
	 * *********************************************************************/
	 // Print a prompt.
	void prompt()
	{
		call ConsoleOut.print("[root@evb13192-");
		call ConsoleOut.printHexword(TOS_LOCAL_ADDRESS);
		call ConsoleOut.print(" /]# ");
	}

	/** Help function, does string compare */
	int strcmp(const char * a, const char * b)
	{
		while (*a && *b && *a == *b) { ++a; ++b; };
		return *a - *b;
	}
	
	/** Help function, does string compare */
	int strcmp2(const char * a, const char * b, uint8_t num)
	{
		uint8_t i = 1;
		while (*a && *b && *a == *b && i < num) { ++a; ++b; ++i; };
		return *a - *b;
	}
  
	int parseArg(const char* from)
	{
		int i = 1000;
		int num = 0;
		while(*from) {
			num = num + (i * (((unsigned int) *from) - 48));	
			i = i / 10;
			from++;
		} 
		return num;
	} 

	/**************************************************************************/
	/**
	 * Handle data from the console.
	 *
	 * <p>Simply dump the data, handle any commands by posting tasks.</p>
	 */
	/**************************************************************************/
	task void handleGet()
	{
		char console_transmit[2];
		atomic console_transmit[0] = console_data;
		console_transmit[1] = 0;
		call ConsoleOut.print(console_transmit); 

		/* Check if enter was pressed */
		if (console_transmit[0] == 10) {
			/* If enter was pressed, "handle" command */
			if (0 == strcmp("ls", cmd_input)) {
				call ConsoleOut.print("ascan  pscan    doze    help  ls    setassoc  startpan  wake requestgts\n");
				call ConsoleOut.print("associate  edscan  info  send  setshort  time  disassoc\n");
				prompt();
			} else if (0 == strcmp("", cmd_input)) {
				prompt();
			} else if (0 == strcmp("associate", cmd_input)) {
				post associate();
			} else if (0 == strcmp("disassociate", cmd_input)) {
				post disassociate();
			} else if (0 == strcmp("ascan", cmd_input)) {
				post ascan();
			} else if (0 == strcmp("beaconenable", cmd_input)) {	
				iAmBeaconEnabled = TRUE;
				prompt();
			} else if (0 == strcmp("pscan", cmd_input)) {
				post pscan();
			} else if (0 == strcmp("orphanscan", cmd_input)) {
				post orphanscan();
			} else if (0 == strcmp("doze", cmd_input)) {
//				post doze();
			} else if (0 == strcmp("edscan", cmd_input)) {
				post edscan();
			} else if (0 == strcmp("help", cmd_input)) {
				post help();
			} else if (0 == strcmp("info", cmd_input)) {
				post info();
			} else if (0 == strcmp("autoRequestOn", cmd_input)) {
				setAutoRequest(TRUE);
				prompt();
			} else if (0 == strcmp("autoRequestOff", cmd_input)) {
				setAutoRequest(FALSE);
				prompt();
			} else if (0 == strcmp("reset", cmd_input)) {
				macReset();
			} else if (0 == strcmp("bufstat", cmd_input)) {
				//call BufferManDebug.printUsageStats();
				prompt();
//			} else if (0 == strcmp("send", cmd_input)) {
//				post send();
//			} else if (0 == strcmp("p2psend", cmd_input)) {
//				post p2psend();
			} else if (0 == strcmp2("sendTo", cmd_input, 6)) {
				sendToAddr = parseArg(&cmd_input[7]);
				txType = 0x04;
				post sendToDevice();
			} else if (0 == strcmp2("purge", cmd_input, 5)) {
				purgeHandle = parseArg(&cmd_input[6]);
				post doPurge();
			} else if (0 == strcmp("getassoc", cmd_input)) {
				post getassoc();
//			} else if (0 == strcmp("setshort", cmd_input)) {
//				post setshort();
			} else if (0 == strcmp("getshort", cmd_input)) {
				post getshort();
			} else if (0 == strcmp("startpan", cmd_input)) {
				post startpan();
			} else if (0 == strcmp("poll", cmd_input)) {
				post poll();
			} else if (0 == strcmp("sync", cmd_input)) {
				post sync();
//			} else if (0 == strcmp("time", cmd_input)) {
//				post getTime();
//			} else if (0 == strcmp("wake", cmd_input)) {
//				post getWake();
//			} else if (0 == strcmp("get", cmd_input)) {
//				post testGet();
			} else if (0 == strcmp2("gtsSendTo", cmd_input, 9)) {
				sendToAddr = parseArg(&cmd_input[10]);
				txType = 0x02;
				gtsSend = TRUE;
				post requestSendGts();
			} else if (0 == strcmp("dropgts", cmd_input)) {
				post dropGts();
			} else if (0 == strcmp("rxon", cmd_input)) {
				post rxon();
			} else if (0 == strcmp("rxoff", cmd_input)) {
				post rxoff();
			} else if (0 == strcmp("promiscuous", cmd_input)) {
				post setPromiscuous();				
			} else {
				call ConsoleOut.print("tosh: ");
				call ConsoleOut.print(cmd_input);
				call ConsoleOut.print(": command not found\n");
				prompt();
			}
			/* Get ready for a new command */
			bufpoint = cmd_input;
			*bufpoint = 0;
		} else {
			/* Store character in buffer */
			if (bufpoint < (cmd_input + sizeof(cmd_input))) {
				*bufpoint = console_transmit[0];
				++bufpoint;
				*bufpoint = 0;
			}
		}
	}
}
