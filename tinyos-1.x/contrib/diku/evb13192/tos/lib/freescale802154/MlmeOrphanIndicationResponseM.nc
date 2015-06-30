module MlmeOrphanIndicationResponseM
{
	provides
	{
		interface MlmeOrphanIndicationResponse;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{	
	command void MlmeOrphanIndicationResponse.getOrphanAddress( Mlme_OrphanIndicationResponse indication,
	                                                            uint8_t *addr )
	{
		nwkOrphanInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.orphanInd;
		NTOUHCPY64(msg->orphanAddress, addr);
	}
	
	command bool MlmeOrphanIndicationResponse.getSecurityUse( Mlme_OrphanIndicationResponse indication )
	{
		nwkOrphanInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.orphanInd;
		return msg->securityUse;
	}
	
	command uint8_t MlmeOrphanIndicationResponse.getAclEntry( Mlme_OrphanIndicationResponse indication )
	{
		nwkOrphanInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.orphanInd;
		return msg->AclEntry;
	}

	command void MlmeOrphanIndicationResponse.setOrphanAddress( Mlme_OrphanIndicationResponse response,
	                                                            uint8_t *orphanAddress )
	{
		mlmeOrphanRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.orphanRes;
		NTOUHCPY64(orphanAddress, msg->orphanAddress);
		// Here we use the freescale msgType field to indicate, whether
		// the security property has been set on the response.
		if (!(response->msg.response.msgType)) {
			// Security false by default.
			msg->securityEnable = FALSE;
		}
	}
	                                                            
	command result_t MlmeOrphanIndicationResponse.setShortAddress( Mlme_OrphanIndicationResponse response,
	                                                               uint16_t shortAddress )
	{
		mlmeOrphanRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.orphanRes;
		NTOUHCPY16((uint8_t*)&shortAddress, msg->shortAddress);
		return SUCCESS;
	}
	
	command void MlmeOrphanIndicationResponse.setAssociatedMember( Mlme_OrphanIndicationResponse response,
	                                                               bool associatedMember )
	{
		mlmeOrphanRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.orphanRes;
		msg->associatedMember = associatedMember;
	}
	
	command void MlmeOrphanIndicationResponse.setSecurityEnable( Mlme_OrphanIndicationResponse response )
	{
		mlmeOrphanRes_t* msg = &((MlmeIndicationResponse_t*)response)->msg.response.msgData.orphanRes;
		response->msg.response.msgType = TRUE;
		msg->securityEnable = TRUE;
	}
}
