#include <macTypes.h>

module ScanTestM
{
	provides
	{
		interface BeaconScan; // active and passive scan
		// TODO: edscan and orphanscan
	}
	uses
	{
		interface IeeeAddress;
		interface IeeePanDescriptor;

		interface MlmeScanRequestConfirm;
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t scantype;
	panDescriptor_t tmpPan;
	Ieee_PanDescriptor panInfo = &tmpPan;
	
	void handleBeaconScan(Mlme_ScanRequestConfirm confirm);
	task void startScan();
	
	command void BeaconScan.activeScan()
	{
		scantype = IEEE802154_ActiveScan;
		post startScan();
	}
	
	command void BeaconScan.passiveScan()
	{
		scantype = IEEE802154_PassiveScan;
		post startScan();
	}
	
	event void MlmeRequestConfirmScan.confirm(Mlme_ScanRequestConfirm confirm)
	{
		uint8_t status,scanType,resultListSize;			
		status = call MlmeScanRequestConfirm.getStatus(confirm);
		DBG_STRINT("MlmeRequestConfirmScan.confirm, status ",status,1);
		scanType = call MlmeScanRequestConfirm.getScanType(confirm);
		resultListSize = call MlmeScanRequestConfirm.getResultListSize(confirm);
		switch(scanType) {		
			case IEEE802154_EDScan: {				
				DBG_STR("ED scan not yet supported!",1);
				break;
			}
			case IEEE802154_PassiveScan:
			case IEEE802154_ActiveScan: {
				if (status == IEEE802154_SUCCESS) {
					handleBeaconScan(confirm);
				} else if (status == IEEE802154_NO_BEACON) {
					DBG_STR("No beacon in scan!",1);
				} else {
					DBG_STRINT("Unknown scan result ",status,1);
				}
				break;
			}
			case IEEE802154_OrphanScan: {
				DBG_STR("Orphan scan not implemented yet!",1);
				break;
  			}
    		default: {
				DBG_STRINT("MLME_SCAN.confirm on unknown scan type: ",scanType,1);
			}
	   	};
      	call MlmeScanRequestConfirm.destroy(confirm);
	}
	
	task void startScan() {
		Mlme_ScanRequestConfirm request;
		call MlmeScanRequestConfirm.create(&request);
		call MlmeScanRequestConfirm.setScanType(request,scantype);
		call MlmeScanRequestConfirm.setScanChannels(request,0x00001000); // only channel 12
		call MlmeScanRequestConfirm.setScanDuration(request,8);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			DBG_STR("Starting scan...",1);
		} else {
			DBG_STR("Could not start scan...",1);
			call MlmeScanRequestConfirm.destroy(request);
		}
	}

	void handleBeaconScan(Mlme_ScanRequestConfirm confirm)
	{
		uint8_t linkQuality,bestLinkQuality = 0;
		uint8_t i,listSize;
		uint16_t sframeSpec,temp;
		Ieee_Address coordAddr;
		Ieee_PanDescriptor pd,bestPd = NULL;
		
		listSize = call MlmeScanRequestConfirm.getResultListSize(confirm);
		DBG_STRINT("Number of results: ",listSize,1);
		for (i = 0; i < listSize; i++) {
			pd = call MlmeScanRequestConfirm.getPanDescriptor(confirm,i);
			sframeSpec = call IeeePanDescriptor.getSuperframeSpec(pd);

		     linkQuality = call IeeePanDescriptor.getLinkQuality(pd);
			// Get the best
			if (linkQuality >= bestLinkQuality) {
				bestLinkQuality = linkQuality;
				bestPd = pd;
			}
		}

		
		if (bestPd) {
			// TODO: get rid of the pointer assumptions and the freescale stuff
			// when copying pan Info
			memcpy(panInfo, bestPd, sizeof(panDescriptor_t));
			DBG_STR("Found a link!",1);
		} else {
			DBG_STR("No best link?",1);
			signal BeaconScan.done(FAIL, NULL);
			return;
		}
		
		call IeeeAddress.create(&coordAddr);
		call IeeePanDescriptor.getCoordAddr(bestPd, coordAddr);
		DBG_STR("scan found coordinator:",1);
		
		if (call IeeeAddress.getAddrMode(coordAddr) == 2) {
			DBG_STRINT("Address 0x",*((uint16_t*)call IeeeAddress.getAddress(coordAddr)),1);
		} else {
			DBG_STRINT("Address 0x",*((uint64_t*)call IeeeAddress.getAddress(coordAddr)),1);
		}
		temp = call IeeeAddress.getPanId(coordAddr);
		DBG_STRINT("PAN ID 0x",temp,1);
		temp = call IeeePanDescriptor.getLogicalChannel(bestPd);
		DBG_STRINT("Logical Channel 0x",temp,1);
		temp = call IeeePanDescriptor.getSuperframeSpec(bestPd);
		DBG_STRINT("Beacon Spec 0x",temp,1);    
		temp = call IeeePanDescriptor.getLinkQuality(bestPd);
		DBG_STRINT("Link Quality 0x",temp,1);
		
		signal BeaconScan.done(SUCCESS, panInfo);
	}
}
