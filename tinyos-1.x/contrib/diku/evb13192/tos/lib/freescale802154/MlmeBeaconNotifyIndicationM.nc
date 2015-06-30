module MlmeBeaconNotifyIndicationM
{
	provides
	{
		interface MlmeBeaconNotifyIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeBeaconNotifyIndication.destroy(Mlme_BeaconNotifyIndication primitive)
	{
		call BufferMng.release(0, (uint8_t*)primitive->msg.indication.msgData.beaconNotifyInd.pBufferRoot);
		call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
		return SUCCESS;
	}
		
	command uint8_t MlmeBeaconNotifyIndication.getBsn( Mlme_BeaconNotifyIndication indication )
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		return msg->bsn;
	}
	
	command void MlmeBeaconNotifyIndication.getPanDescriptor( Mlme_BeaconNotifyIndication indication,
	                                                          Ieee_PanDescriptor panDesc )
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		panDesc = msg->pPanDescriptor;
	}
	
	command uint8_t MlmeBeaconNotifyIndication.getShortAddrCount( Mlme_BeaconNotifyIndication indication )
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		return msg->pendAddrSpec >> 5;
	}
	
	command uint16_t MlmeBeaconNotifyIndication.getShortAddr( Mlme_BeaconNotifyIndication indication, uint8_t index )
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		// short adresses appear first in the list
		return NTOUH16( ((uint16_t*)msg->pAddrList)[index] );
	}
	
	command uint8_t MlmeBeaconNotifyIndication.getLongAddrCount(Mlme_BeaconNotifyIndication indication)
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		return (msg->pendAddrSpec >> 1) & 7;
	}
	
	command void MlmeBeaconNotifyIndication.getLongAddr( Mlme_BeaconNotifyIndication indication,
	                                                     uint8_t index, uint8_t *addr )
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		// skip the short address bytes first
		NTOUHCPY64( (msg->pAddrList + 2*(msg->pendAddrSpec >> 5) + 8*index), addr );
	}
	
	command void MlmeBeaconNotifyIndication.getSdu(Mlme_BeaconNotifyIndication indication, Ieee_Msdu msdu)
	{
		nwkBeaconNotifyInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.beaconNotifyInd;
		// TODO
		msdu->bufferDestroyable = FALSE;
		msdu->payload = msg->pSdu;
		msdu->payloadLen = msg->sduLength;
	}
}
