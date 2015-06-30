includes macTypes;

module MlmeAssociateRequestConfirmM
{
	provides
	{
		interface MlmeAssociateRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeAssociateRequestConfirm.create( Mlme_AssociateRequestConfirm *primitive,
	                                                     Ieee_Address coordAddr )
	{
		mlmeAssociateReq_t* msg;
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		if (res != SUCCESS) {
			return res;
		}
		(*primitive)->msg.request.msgType = gMlmeAssociateReq_c;
		msg = &((MlmeRequestConfirm_t*)*primitive)->msg.request.msgData.associateReq;
		msg->coordAddrMode = coordAddr->mode;
		NTOUHCPY16((uint8_t*)&coordAddr->panId, msg->coordPanId);
		if (coordAddr->mode == 2) {
			NTOUHCPY16(coordAddr->address, msg->coordAddress);
		} else {
			NTOUHCPY64(coordAddr->address, msg->coordAddress);
		}
		// Set security to default false.
		msg->securityEnable = FALSE;
		return res;
	}
	
	command result_t MlmeAssociateRequestConfirm.destroy( Mlme_AssociateRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	
	command void MlmeAssociateRequestConfirm.setLogicalChannel( Mlme_AssociateRequestConfirm request,
	                                                            uint8_t logicalChannel )
	{
		mlmeAssociateReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.associateReq;
		msg->logicalChannel=logicalChannel;
	}
	
	command void MlmeAssociateRequestConfirm.setCapabilityInformation( Mlme_AssociateRequestConfirm request,
	                                                                   uint8_t capabilityInformation )
	{
		mlmeAssociateReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.associateReq;
		msg->capabilityInfo = capabilityInformation;
	}
	                                       
	command void MlmeAssociateRequestConfirm.setSecurityEnable( Mlme_AssociateRequestConfirm request )
	{
		mlmeAssociateReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.associateReq;
		msg->securityEnable = TRUE;
	}

	command uint16_t MlmeAssociateRequestConfirm.getAssocShortAddress( Mlme_AssociateRequestConfirm confirm )
	{
		nwkAssociateCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.associateCnf;
		// TODO: check endianness
		return NTOUH16(((uint16_t*)msg->assocShortAddress)[0]);
	}
	
	command Ieee_Status MlmeAssociateRequestConfirm.getStatus( Mlme_AssociateRequestConfirm confirm )
	{
		nwkAssociateCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.associateCnf;
		return msg->status;
	}
}
