module MlmeDisassociateRequestConfirmM
{
	provides
	{
		interface MlmeDisassociateRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	
	command result_t MlmeDisassociateRequestConfirm.create( Mlme_DisassociateRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		if (res != SUCCESS) {
			return res;
		}
		(*primitive)->msg.request.msgType = gMlmeDisassociateReq_c;
		// Security off by default.
		(*primitive)->msg.request.msgData.disassociateReq.securityEnable = FALSE;
		return res;
	}
	
	command result_t MlmeDisassociateRequestConfirm.destroy( Mlme_DisassociateRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	
	command void MlmeDisassociateRequestConfirm.setDeviceAddress( Mlme_DisassociateRequestConfirm request,
	                                                              uint8_t *deviceAddress )
	{
		mlmeDisassociateReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.disassociateReq;
		//memcpy(msg->deviceAddress, &deviceAddress, 8);
		NTOUHCPY64(deviceAddress, msg->deviceAddress);
	}
	
	command void MlmeDisassociateRequestConfirm.setDisassociateReason( Mlme_DisassociateRequestConfirm request,
	                                                                   Ieee_Status disassociateReason )
	{
		mlmeDisassociateReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.disassociateReq;
		msg->disassociateReason = disassociateReason;
	}
	
	command void MlmeDisassociateRequestConfirm.setSecurityEnable( Mlme_DisassociateRequestConfirm request )
	{
		mlmeDisassociateReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.disassociateReq;
		msg->securityEnable = TRUE;
	}

	command Ieee_Status MlmeDisassociateRequestConfirm.getStatus( Mlme_DisassociateRequestConfirm confirm )
	{
		nwkDisassociateCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.disassociateCnf;
		return msg->status;
	}
}
