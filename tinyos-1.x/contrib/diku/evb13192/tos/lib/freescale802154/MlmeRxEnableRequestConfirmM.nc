module MlmeRxEnableRequestConfirmM
{
	provides
	{
		interface MlmeRxEnableRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeRxEnableRequestConfirm.create( Mlme_RxEnableRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->msg.request.msgType = gMlmeRxEnableReq_c;
		return res;
	}
	
	command result_t MlmeRxEnableRequestConfirm.destroy( Mlme_RxEnableRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
	}
	
	command void MlmeRxEnableRequestConfirm.setDeferPermit( Mlme_RxEnableRequestConfirm request,
	                                                        bool deferPermit )
	{
		mlmeRxEnableReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.rxEnableReq;
		msg->deferPermit = deferPermit;
	}
	
	command void MlmeRxEnableRequestConfirm.setRxOnTime( Mlme_RxEnableRequestConfirm request,
	                                                     uint32_t rxOnTime )
	{
		mlmeRxEnableReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.rxEnableReq;
		((uint32_t*)msg->rxOnTime)[0] = NTOUH16(rxOnTime);
	}
	
	command void MlmeRxEnableRequestConfirm.setRxOnDuration( Mlme_RxEnableRequestConfirm request,
	                                                         uint32_t rxOnDuration )
	{
		mlmeRxEnableReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.rxEnableReq;
		((uint32_t*)msg->rxOnDuration)[0] = NTOUH32(rxOnDuration);
	}
	
	command Ieee_Status MlmeRxEnableRequestConfirm.getStatus( Mlme_RxEnableRequestConfirm confirm )
	{
		nwkRxEnableCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.rxEnableCnf;
		return msg->status;
	}
}
