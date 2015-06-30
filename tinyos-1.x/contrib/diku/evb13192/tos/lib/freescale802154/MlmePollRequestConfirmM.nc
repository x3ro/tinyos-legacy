module MlmePollRequestConfirmM
{
	provides
	{
		interface MlmePollRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmePollRequestConfirm.create( Mlme_PollRequestConfirm *primitive,
	                                                Ieee_Address coordAddr )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		mlmePollReq_t* msg;
		if (res != SUCCESS) {
			return res;
		}
		msg = &((MlmeRequestConfirm_t*)(*primitive))->msg.request.msgData.pollReq;
		(*primitive)->msg.request.msgType = gMlmePollReq_c;
		// Set addressing
		msg->coordAddrMode = coordAddr->mode;
		NTOUHCPY16((uint8_t*)&(coordAddr->panId), msg->coordPanId);
		if (coordAddr->mode == 2) {
			NTOUHCPY16(coordAddr->address, msg->coordAddress);
		} else {
			NTOUHCPY64(coordAddr->address, msg->coordAddress);
		}
		// Disable security by default.
		msg->securityEnable = FALSE;
		return res;
	}
	
	command result_t MlmePollRequestConfirm.destroy( Mlme_PollRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	                           
	command void MlmePollRequestConfirm.setSecurityEnable( Mlme_PollRequestConfirm request )
	{
		mlmePollReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.pollReq;
		msg->securityEnable = TRUE;
	}
	
	command Ieee_Status MlmePollRequestConfirm.getStatus( Mlme_PollRequestConfirm confirm )
	{
		nwkPollCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.pollCnf;
		return msg->status;
	}
}
