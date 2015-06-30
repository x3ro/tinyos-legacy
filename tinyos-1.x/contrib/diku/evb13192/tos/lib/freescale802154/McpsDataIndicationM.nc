module McpsDataIndicationM
{
	provides
	{
		interface McpsDataIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t McpsDataIndication.destroy(Mcps_DataIndication primitive)
	{
		// Using msgType to indicate, if the primitive is used in an sdu.
		if ((primitive->msg.msgType)) {
			return call BufferMng.release(sizeof(mcpsToNwkMessage_t), (uint8_t*)primitive);
		} else {
			return SUCCESS;
		}
	}

	command void McpsDataIndication.getSrcAddress( Mcps_DataIndication indication, Ieee_Address addr )
	{
		mcpsDataInd_t* msg = &((McpsIndication_t*)indication)->msg.msgData.dataInd;
		addr->mode = msg->srcAddrMode;
		NTOUHCPY16(msg->srcPanId, (uint8_t*)&(addr->panId));
		if (addr->mode == 2) {
			NTOUHCPY16(msg->srcAddr, addr->address);
		} else {
			NTOUHCPY64(msg->srcAddr, addr->address);
		}
	}
	
	command void McpsDataIndication.getDstAddress(  Mcps_DataIndication indication, Ieee_Address addr )
	{
		mcpsDataInd_t* msg = &((McpsIndication_t*)indication)->msg.msgData.dataInd;
		addr->mode = msg->dstAddrMode;
		NTOUHCPY16(msg->dstPanId, (uint8_t*)&(addr->panId));
		if (addr->mode == 2) {
			NTOUHCPY16(msg->dstAddr, addr->address);
		} else {
			NTOUHCPY64(msg->dstAddr, addr->address);
		}
	}
	
	command result_t McpsDataIndication.getMsdu( Mcps_DataIndication indication, Ieee_Msdu msdu )
	{
		mcpsDataInd_t* msg = &((McpsIndication_t*)indication)->msg.msgData.dataInd;
		
		// The indication primitive is destroyed together with the msdu structure.
		// We use the Freescale type field in their nwkMessage structure to indicate
		// this.
		indication->msg.msgType = FALSE;
		msdu->buffer = (uint8_t*)indication;
		msdu->bufferLen = sizeof(mcpsToNwkMessage_t);
		msdu->payload = msg->msdu;
		msdu->payloadLen = msg->msduLength;
		msdu->bufferDestroyable = TRUE;
		return SUCCESS;
	}
	
	command uint8_t McpsDataIndication.getMpduLinkQuality( Mcps_DataIndication indication )
	{
		mcpsDataInd_t* msg = &((McpsIndication_t*)indication)->msg.msgData.dataInd;
		return msg->mpduLinkQuality;
	}
	
	command bool McpsDataIndication.getSecurityUse( Mcps_DataIndication indication )
	{
		mcpsDataInd_t* msg = &((McpsIndication_t*)indication)->msg.msgData.dataInd;
		return msg->securityUse;
	}
	
	command uint8_t McpsDataIndication.getAclEntry( Mcps_DataIndication indication )
	{
		mcpsDataInd_t* msg = &((McpsIndication_t*)indication)->msg.msgData.dataInd;
		return msg->aclEntry;
	}
}
