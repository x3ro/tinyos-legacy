module MlmeGtsRequestConfirmM
{
	provides
	{
		interface MlmeGtsRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeGtsRequestConfirm.create( Mlme_GtsRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		if (res != SUCCESS) {
			return res;
		}
		(*primitive)->msg.request.msgType = gMlmeGtsReq_c;
		(*primitive)->msg.request.msgData.gtsReq.securityEnable = FALSE;
		return res;
	}
	
	command result_t MlmeGtsRequestConfirm.destroy( Mlme_GtsRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
		
	command void MlmeGtsRequestConfirm.setGtsCharacteristics( Mlme_GtsRequestConfirm request,
	                                                          uint8_t gtsCharacteristics )
	{
		mlmeGtsReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.gtsReq;
		msg->gtsCharacteristics = gtsCharacteristics;
	}
	
	command void MlmeGtsRequestConfirm.combineGtsCharacteristics( Mlme_GtsRequestConfirm request,
	                                                              uint8_t length,
	                                                              uint8_t direction,
	                                                              uint8_t type )
	{
		mlmeGtsReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.gtsReq;
		msg->gtsCharacteristics = (length & 7) << 5
		                        | (direction & 1) << 4
		                        | (type & 1) << 3;
	}
	
	command void MlmeGtsRequestConfirm.setSecurityEnable( Mlme_GtsRequestConfirm request )
	{
		request->msg.request.msgData.gtsReq.securityEnable = TRUE;
	}
	                                
	command uint8_t MlmeGtsRequestConfirm.getGtsCharacteristics( Mlme_GtsRequestConfirm confirm )
	{
		nwkGtsCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.gtsCnf;
		return msg->gtsCharacteristics;
	}
	
	command Ieee_Status MlmeGtsRequestConfirm.getStatus( Mlme_GtsRequestConfirm confirm )
	{
		nwkGtsCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.gtsCnf;
		return msg->status;
	}
}
