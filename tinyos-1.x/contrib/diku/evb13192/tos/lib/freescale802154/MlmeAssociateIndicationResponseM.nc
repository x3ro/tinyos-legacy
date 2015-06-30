module MlmeAssociateIndicationResponseM
{
	provides
	{
		interface MlmeAssociateIndicationResponse;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{		
	command void MlmeAssociateIndicationResponse.getDeviceAddress( Mlme_AssociateIndicationResponse indication,
	                                                               uint8_t *deviceAddr )
	{
		nwkAssociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.associateInd;
		NTOUHCPY64(msg->deviceAddress, deviceAddr);
	}
	
	command uint8_t MlmeAssociateIndicationResponse.getCapabilityInformation( Mlme_AssociateIndicationResponse indication )
	{
		nwkAssociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.associateInd;
		return msg->capabilityInfo;
	}
	
	command bool MlmeAssociateIndicationResponse.getSecurityUse( Mlme_AssociateIndicationResponse indication )
	{
		nwkAssociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.associateInd;
		return msg->securityUse;
	}
	
	command uint8_t MlmeAssociateIndicationResponse.getAclEntry( Mlme_AssociateIndicationResponse indication )
	{
		nwkAssociateInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.associateInd;
		return msg->AclEntry;
	}

	command void MlmeAssociateIndicationResponse.setDeviceAddress( Mlme_AssociateIndicationResponse response,
	                                                               uint8_t *deviceAddress )
	{
		mlmeAssociateRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.associateRes;
		NTOUHCPY64(deviceAddress, msg->deviceAddress);
		if (!(response->msg.response.msgType)) {
			// Security false by default.
			msg->securityEnable = FALSE;
		}
	}
	
	command result_t MlmeAssociateIndicationResponse.setAssocShortAddress( Mlme_AssociateIndicationResponse response,
	                                                                       uint16_t assocShortAddress )
	{
		mlmeAssociateRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.associateRes;
		NTOUHCPY16((uint8_t*)&assocShortAddress, msg->assocShortAddress);
		return SUCCESS;
	}
	
	command result_t MlmeAssociateIndicationResponse.setStatus( Mlme_AssociateIndicationResponse response,
	                                                            Ieee_Status status )
	{
		mlmeAssociateRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.associateRes;
		msg->status = status;
		return SUCCESS;
	}
	
	command result_t MlmeAssociateIndicationResponse.setSecurityEnable( Mlme_AssociateIndicationResponse response )
	{
		mlmeAssociateRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.associateRes;
		response->msg.response.msgType = TRUE;
		msg->securityEnable = TRUE;
		return SUCCESS;
	}
}
