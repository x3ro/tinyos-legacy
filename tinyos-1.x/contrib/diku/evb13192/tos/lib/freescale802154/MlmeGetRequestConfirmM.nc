module MlmeGetRequestConfirmM
{
	provides
	{
		interface MlmeGetRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeGetRequestConfirm.create( Mlme_GetRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->primitive.msg.request.msgType = gMlmeGetReq_c;
		return res;
	}
	
	command result_t MlmeGetRequestConfirm.destroy( Mlme_GetRequestConfirm primitive )
	{
		call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
		return SUCCESS;
	}
	
	command void MlmeGetRequestConfirm.setPibAttribute( Mlme_GetRequestConfirm request,
	                                                    Ieee_PibAttribute pibAttribute )
	{
		mlmeGetReq_t* msg = &((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.request.msgData.getReq;
		msg->pibAttribute = pibAttribute->pibAttribute;
		// This is only a pointer to the preallocated memory area.
		msg->pibAttributeValue = pibAttribute->pibAttributeValue;
		// Store the pib attribute in request-confirm primitive
		request->pibAttribute = pibAttribute;
		pibAttribute->destroyable = FALSE;
	}
	                              
	command Ieee_Status MlmeGetRequestConfirm.getStatus( Mlme_GetRequestConfirm confirm )
	{
		nwkGetCnf_t* msg = &((MlmeRequestConfirmGetSet_t*)confirm)->primitive.msg.confirm.msgData.getCnf;
		return msg->status;
	}
	
	command	Ieee_PibAttribute MlmeGetRequestConfirm.getPibAttribute( Mlme_GetRequestConfirm confirm )
	{
		//nwkGetCnf_t *msg = &((MlmeRequestConfirmGetSet_t*)confirm)->primitive.msg.confirm.msgData.getCnf;
		confirm->pibAttribute->destroyable = TRUE;
		return confirm->pibAttribute;
	}
}
