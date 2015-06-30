#include <macTypes.h>

module SynchronizeM
{
	provides
	{
		interface StdControl;
		interface Synchronize;
	}
	uses {		
	    interface IeeeMacPibAttribute as IeeePibAttribute;
		interface IeeePanDescriptor;
		interface IeeeAddress;
	   
		interface MlmeBeaconNotifyIndication;
		interface MlmeSyncLossIndication;
		interface MlmeSyncRequest;

		// MLME	
		interface IeeeIndication<Mlme_BeaconNotifyIndication> as MlmeIndicationBeaconNotify;		
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;
	
		interface PibAttributeService;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t beacons = 0;
	
	Ieee_PanDescriptor syncPanInfo;
	Ieee_Address syncCoordAddr;
	
	task void setPanId();
	void setCoordShortAddress(Ieee_Status status);
	void setBeaconOrder(Ieee_Status status);
	void setSuperframeOrder(Ieee_Status status);
	void setAutoRequest(Ieee_Status status);
	void sync(Ieee_Status status);
	
	command result_t StdControl.init()
	{
		call IeeeAddress.create(&syncCoordAddr);
		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
	
	command void Synchronize.track(Ieee_PanDescriptor panInfo)
	{
		syncPanInfo = panInfo;		
		call IeeePanDescriptor.getCoordAddr(syncPanInfo,syncCoordAddr);
		post setPanId();
	}
	
	task void setPanId()
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(2,&attribute);
		call IeeePibAttribute.setMacPanId(attribute,call IeeeAddress.getPanId(syncCoordAddr));
		call PibAttributeService.set(attribute,setCoordShortAddress);
	}
	
	void setCoordShortAddress(Ieee_Status status)
	{
		Ieee_PibAttribute attribute; 
		uint16_t addr;
		
		DBG_STR("WARNING: SynchronizeM, assuming short coordinator address",1);
		addr = *((uint16_t*)call IeeeAddress.getAddress(syncCoordAddr));
		call IeeePibAttribute.create(2,&attribute);
		call IeeePibAttribute.setMacCoordShortAddress(attribute,addr);
		call PibAttributeService.set(attribute,setBeaconOrder);
	}	

	void setBeaconOrder(Ieee_Status status)
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacBeaconOrder(attribute,8); // TODO: read from spec
		call PibAttributeService.set(attribute,setSuperframeOrder);
	}
	
	void setSuperframeOrder(Ieee_Status status)
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacSuperframeOrder(attribute,8); // TODO: read from spec
		call PibAttributeService.set(attribute,setAutoRequest);
	}
	
	void setAutoRequest(Ieee_Status status)
	{
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacAutoRequest(attribute,FALSE);
		call PibAttributeService.set(attribute,sync);
	}
	
	void sync(Ieee_Status status)
	{
		Mlme_SyncRequest syncrequest;
		
		//create sync request
		call MlmeSyncRequest.create( &syncrequest );
		call MlmeSyncRequest.setLogicalChannel(syncrequest, call IeeePanDescriptor.getLogicalChannel(syncPanInfo));
		call MlmeSyncRequest.setTrackBeacon(syncrequest, TRUE);
		
		//do request
		if (SUCCESS != call MlmeRequestSync.request( syncrequest )) {
			DBG_STR("Beacon tracking request failed!",1);
		}
	}

	event void MlmeIndicationBeaconNotify.indication(Mlme_BeaconNotifyIndication indication)
	{
		//DBG_STRINT("MlmeIndicationBeaconNotify.indication #",beacons,1);
		beacons++;
		call MlmeBeaconNotifyIndication.destroy(indication);
	}	

	event void MlmeIndicationSyncLoss.indication( Mlme_SyncLossIndication indication)
	{
		uint8_t lossreason = call MlmeSyncLossIndication.getLossReason(indication);
		DBG_STRINT("Sync lost! Reason: 0x",lossreason,1);
		call MlmeSyncLossIndication.destroy(indication);
	}
}
