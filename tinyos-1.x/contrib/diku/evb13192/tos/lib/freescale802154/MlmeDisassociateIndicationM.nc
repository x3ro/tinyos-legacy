module MlmeDisassociateIndicationM
{
	provides
	{
		interface MlmeDisassociateIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t MlmeDisassociateIndication.destroy(Mlme_DisassociateIndication primitive)
	{
		call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	
	command void MlmeDisassociateIndication.getDeviceAddress( Mlme_DisassociateIndication indication,
	                                                          uint8_t *deviceAddr )
	{
		nwkDisassociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.disassociateInd;
		NTOUHCPY64(msg->deviceAddress, deviceAddr);
	}
	
	command Ieee_Status MlmeDisassociateIndication.getDisassociateReason( Mlme_DisassociateIndication indication )
	{
		nwkDisassociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.disassociateInd;
		return msg->disassociateReason;
	}
	
	command bool MlmeDisassociateIndication.getSecurityUse( Mlme_DisassociateIndication indication )
	{
		nwkDisassociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.disassociateInd;
		return msg->securityUse;
	}
	
	command uint8_t MlmeDisassociateIndication.getAclEntry( Mlme_DisassociateIndication indication )
	{
		nwkDisassociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.disassociateInd;
		return msg->aclEntry;
	}
	
}
