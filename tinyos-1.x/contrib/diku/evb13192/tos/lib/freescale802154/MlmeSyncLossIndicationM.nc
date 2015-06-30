module MlmeSyncLossIndicationM
{
	provides
	{
		interface MlmeSyncLossIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeSyncLossIndication.destroy(Mlme_SyncLossIndication primitive)
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);		
	}
	
	command	Ieee_Status MlmeSyncLossIndication.getLossReason( Mlme_SyncLossIndication indication )
	{
		nwkSyncLossInd_t* msg = &((MlmeIndicationResponse_t*)indication)->msg.indication.msgData.syncLossInd;
		return msg->lossReason;
	}
}
