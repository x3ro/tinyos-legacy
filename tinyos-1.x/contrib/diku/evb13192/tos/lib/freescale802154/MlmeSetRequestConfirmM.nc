includes macTypes;
includes Ieee802154Adts;

module MlmeSetRequestConfirmM
{
	provides
	{
		interface MlmeSetRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeSetRequestConfirm.create( Mlme_SetRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->primitive.msg.request.msgType = gMlmeSetReq_c;
		return res;
	}
	
	command result_t MlmeSetRequestConfirm.destroy( Mlme_SetRequestConfirm primitive )
	{
		call BufferMng.release(0, (uint8_t*)((MlmeRequestConfirmGetSet_t*)primitive)->primitive.msg.request.msgData.setReq.pibAttributeValue);
		call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
		return SUCCESS;
	}
	
	command void MlmeSetRequestConfirm.setPibAttribute( Mlme_SetRequestConfirm request,
	                                                    Ieee_PibAttribute pibAttribute )
	{
		mlmeSetReq_t* msg = &((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.request.msgData.setReq;
		fsPibAttribute_t* att = pibAttribute;
		msg->pibAttribute = att->pibAttribute;
		msg->pibAttributeValue = att->pibAttributeValue;
		// Store the pib attribute in request-confirm primitive
		request->pibAttribute = pibAttribute;
		pibAttribute->destroyable = FALSE;
	}
	
	command Ieee_Status MlmeSetRequestConfirm.getStatus( Mlme_SetRequestConfirm confirm )
	{
		nwkSetCnf_t* msg = &((MlmeRequestConfirmGetSet_t*)confirm)->primitive.msg.confirm.msgData.setCnf;
		return msg->status;
	}
	
	command Ieee_PibAttribute MlmeSetRequestConfirm.getPibAttribute( Mlme_SetRequestConfirm confirm )
	{
	//	nwkSetCnf_t* msg = &((MlmeRequestConfirmGetSet_t*)confirm)->primitive.msg.confirm.msgData.setCnf;
		confirm->pibAttribute->destroyable = TRUE;
		return confirm->pibAttribute;
	}
}
