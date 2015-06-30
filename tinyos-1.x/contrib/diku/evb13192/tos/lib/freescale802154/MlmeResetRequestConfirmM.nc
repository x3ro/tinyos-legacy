module MlmeResetRequestConfirmM
{
	provides
	{
		interface MlmeResetRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeResetRequestConfirm.create( Mlme_ResetRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->msg.request.msgType = gMlmeResetReq_c;
		return res;
	}
	
	command result_t MlmeResetRequestConfirm.destroy( Mlme_ResetRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	
	command void MlmeResetRequestConfirm.setSetDefaultPib( Mlme_ResetRequestConfirm request,
	                                                       bool setDefaultPib )
	{
		mlmeResetReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.resetReq;
		msg->setDefaultPib = setDefaultPib;
	}
	                               
	command	Ieee_Status MlmeResetRequestConfirm.getStatus( Mlme_ResetRequestConfirm confirm )
	{
		nwkResetCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.resetCnf;
		return msg->status;
	}	
}
