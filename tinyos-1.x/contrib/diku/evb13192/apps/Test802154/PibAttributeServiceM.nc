#include <macTypes.h>

module PibAttributeServiceM
{
	provides {
		interface PibAttributeService;
	}
	uses {		
		interface IeeeMacPibAttribute as IeeePibAttribute;
		interface MlmeSetRequestConfirm;
		interface IeeeRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	void (*cbfunc)(Ieee_Status status) = NULL;
	Ieee_Status cbstatus;
	
	task void done();
	
	command result_t PibAttributeService.set(Ieee_PibAttribute attribute, void (*func)(Ieee_Status status) )
	{
		Mlme_SetRequestConfirm request;
		cbfunc = func;
		call MlmeSetRequestConfirm.create(&request);
		call MlmeSetRequestConfirm.setPibAttribute(request,attribute);	
		return call MlmeRequestConfirmSet.request(request);		
	}
	
	event void MlmeRequestConfirmSet.confirm(Mlme_SetRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeSetRequestConfirm.getStatus(confirm);
		Ieee_PibAttribute setAttr = call MlmeSetRequestConfirm.getPibAttribute(confirm);
		uint8_t type = call IeeePibAttribute.getPibAttributeType(setAttr);
		if (status != IEEE802154_SUCCESS) {
			DBG_STR("Set operation was unsuccessful!",1);
			return;
		}
		switch(type) {
			case IEEE802154_macShortAddress:
				DBG_STR("MLME_SET.confirm for macShortAddress",1);
				break;      
			case IEEE802154_macAssociationPermit:
				DBG_STR("MLME_SET.confirm for macAssociationPermit",1);
				break;			
			case IEEE802154_macPromiscuousMode:
				DBG_STR("MLME_SET.confirm for macPromiscuousMode",1);
				break;
			default:
				DBG_STRINT("Unknown PIB set: 0x",type,1);
		};
		call MlmeSetRequestConfirm.destroy(confirm);
		cbstatus = status;
		post done();
	}
	
	task void done()
	{
		cbfunc(cbstatus);
	}
}
