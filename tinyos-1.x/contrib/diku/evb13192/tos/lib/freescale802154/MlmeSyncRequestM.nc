module MlmeSyncRequestM
{
	provides
	{
		interface MlmeSyncRequest;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeSyncRequest.create( Mlme_SyncRequest *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->msg.request.msgType = gMlmeSyncReq_c;
		return res;
	}
	
	command void MlmeSyncRequest.setLogicalChannel( Mlme_SyncRequest request,
	                                                       uint8_t logicalChannel )
	{
		mlmeSyncReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.syncReq;
		msg->logicalChannel = logicalChannel;
	}

	command void MlmeSyncRequest.setTrackBeacon( Mlme_SyncRequest request,
	                                                    bool trackBeacon )
	{
		mlmeSyncReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.syncReq;
		msg->trackBeacon = trackBeacon;
	}
	
}
