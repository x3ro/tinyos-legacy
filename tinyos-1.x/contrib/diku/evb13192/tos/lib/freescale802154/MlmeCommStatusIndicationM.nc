module MlmeCommStatusIndicationM
{
	provides
	{
		interface MlmeCommStatusIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeCommStatusIndication.destroy(Mlme_CommStatusIndication primitive)
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}

	command void MlmeCommStatusIndication.getSrcAddr( Mlme_CommStatusIndication indication,
	                                                  Ieee_Address addr )
	{
		nwkCommStatusInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.commStatusInd;
		addr->mode = msg->srcAddrMode;
		NTOUHCPY16(msg->panId, (uint8_t*)&(addr->panId));
		if (addr->mode == 2) {
			NTOUHCPY16(msg->srcAddress, addr->address);
		} else {
			NTOUHCPY64(msg->srcAddress, addr->address);
		}
	}
	
	command void MlmeCommStatusIndication.getDstAddr( Mlme_CommStatusIndication indication,
	                                                  Ieee_Address addr )
	{
		nwkCommStatusInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.commStatusInd;
		addr->mode = msg->destAddrMode;
		NTOUHCPY16(msg->panId, (uint8_t*)&(addr->panId));
		if (addr->mode == 2) {
			NTOUHCPY16(msg->destAddress, addr->address);
		} else {
			NTOUHCPY64(msg->destAddress, addr->address);
		}
	}
	
	command Ieee_Status MlmeCommStatusIndication.getStatus( Mlme_CommStatusIndication indication )
	{
		nwkCommStatusInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.commStatusInd;
		return msg->status;
	}
}
