module MlmeGtsIndicationM
{
	provides
	{
		interface MlmeGtsIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeGtsIndication.destroy(Mlme_GtsIndication primitive)
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	
	command uint16_t MlmeGtsIndication.getDevAddress( Mlme_GtsIndication indication )
	{
		nwkGtsInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.gtsInd;
		return NTOUH16(((uint16_t*)msg->devAddress)[0]);
	}
	
	command uint8_t MlmeGtsIndication.getGtsCharacteristics( Mlme_GtsIndication indication )
	{
		nwkGtsInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.gtsInd;
		return msg->gtsCharacteristics;
	}
	
	command bool MlmeGtsIndication.getSecurityUse( Mlme_GtsIndication indication )
	{
		nwkGtsInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.gtsInd;
		return msg->securityUse;
	}
	
	command uint8_t MlmeGtsIndication.getAclEntry( Mlme_GtsIndication indication )
	{
		nwkGtsInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.gtsInd;
		return msg->AclEntry;
	}
}
