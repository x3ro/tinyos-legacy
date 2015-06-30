
module MlmeStartRequestConfirmM
{
	provides 
	{
		interface MlmeStartRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeStartRequestConfirm.create( Mlme_StartRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->msg.request.msgType = gMlmeStartReq_c;
		return res;
	}
	
	command result_t MlmeStartRequestConfirm.destroy( Mlme_StartRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	                         
	command void MlmeStartRequestConfirm.setPanId( Mlme_StartRequestConfirm request,
	                                               uint16_t panId )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->panId[0] = panId & 0xFF;
		msg->panId[1] = (panId>>8) & 0xFF;
	}
	                       
	command void MlmeStartRequestConfirm.setLogicalChannel( Mlme_StartRequestConfirm request,
	                                                        uint8_t logicalChannel )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->logicalChannel = logicalChannel;
	}
	                                
	command void MlmeStartRequestConfirm.setBeaconOrder( Mlme_StartRequestConfirm request,
	                                                     uint8_t beaconOrder )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->beaconOrder = beaconOrder;
	}
	                             
	command void MlmeStartRequestConfirm.setSuperframeOrder( Mlme_StartRequestConfirm request,
	                                                         uint8_t superframeOrder )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->superFrameOrder = superframeOrder;
	}
	
	command void MlmeStartRequestConfirm.setPanCoordinator( Mlme_StartRequestConfirm request,
	                                                        bool panCoordinator )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->panCoordinator = panCoordinator;
	}
	                                
	command void MlmeStartRequestConfirm.setBatteryLifeExtension( Mlme_StartRequestConfirm request,
	                                                              bool batteryLifeExtension )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->batteryLifeExt = batteryLifeExtension;
	}
		
	command void MlmeStartRequestConfirm.setCoordRealignment( Mlme_StartRequestConfirm request,
	                                                          bool coordRealignment )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->coordRealignment = coordRealignment;
	}
	
	command void MlmeStartRequestConfirm.setSecurityEnable( Mlme_StartRequestConfirm request,
	                                                        bool securityEnable )
	{
		mlmeStartReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.startReq;
		msg->securityEnable = securityEnable;
	}

	command	Ieee_Status MlmeStartRequestConfirm.getStatus( Mlme_StartRequestConfirm confirm )
	{
		nwkStartCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.startCnf;
		return msg->status;
	}
}
