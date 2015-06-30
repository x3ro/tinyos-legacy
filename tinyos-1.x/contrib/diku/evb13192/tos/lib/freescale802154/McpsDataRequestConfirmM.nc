includes macTypes;

module McpsDataRequestConfirmM
{
	provides
	{
		interface McpsDataRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t McpsDataRequestConfirm.create( Mcps_DataRequestConfirm *primitive,
	                                                Ieee_Address srcAddress, 
	                                                Ieee_Address dstAddress,
	                                                uint8_t msduLength )
	{
		mcpsDataReq_t *request;
		result_t res = call BufferMng.claim((sizeof(nwkToMcpsMessage_t)-1)+msduLength, (uint8_t**)primitive);
		if (res != SUCCESS) {
			return res;
		}
		request = &((McpsRequestConfirm_t*)*primitive)->msg.request.msgData.dataReq;
		(*primitive)->msg.request.msgType = gMcpsDataReq_c;
		
		// Set source address info.
		request->srcAddrMode = srcAddress->mode;
		NTOUHCPY16((uint8_t*)&(srcAddress->panId), request->srcPanId);
		if (srcAddress->mode == 2) {
			NTOUHCPY16(srcAddress->address, request->srcAddr);
		} else {
			NTOUHCPY64(srcAddress->address, request->srcAddr);
		}
		
		// Set destination address info.
		request->dstAddrMode = dstAddress->mode;
		NTOUHCPY16((uint8_t*)&(dstAddress->panId), request->dstPanId);
		if (dstAddress->mode == 2) {
			NTOUHCPY16(dstAddress->address, request->dstAddr);
		} else {
			NTOUHCPY64(dstAddress->address, request->dstAddr);
		}
		
		request->msduLength = msduLength;
		return res;
	}
	
	command result_t McpsDataRequestConfirm.destroy( Mcps_DataRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(mcpsToNwkMessage_t), (uint8_t*)primitive);
	}

	command result_t McpsDataRequestConfirm.getMsdu( Mcps_DataRequestConfirm request, Ieee_Msdu msdu )
	{
		mcpsDataReq_t* msg = &((McpsRequestConfirm_t*)request)->msg.request.msgData.dataReq;
		msdu->bufferDestroyable = FALSE;
		msdu->payload = msg->msdu;
		msdu->payloadLen = msg->msduLength;
		return SUCCESS;
	}

	command void McpsDataRequestConfirm.setMsduHandle( Mcps_DataRequestConfirm request, uint8_t msduHandle )
	{
		mcpsDataReq_t* msg = &((McpsRequestConfirm_t*)request)->msg.request.msgData.dataReq;
		msg->msduHandle = msduHandle;
	}
                      
	command void McpsDataRequestConfirm.setTxOptions( Mcps_DataRequestConfirm request,
	                                                  uint8_t txOptions )
	{
		mcpsDataReq_t* msg = &((McpsRequestConfirm_t*)request)->msg.request.msgData.dataReq;
		msg->txOptions = txOptions;
	}
	
	command uint8_t McpsDataRequestConfirm.getMsduHandle(Mcps_DataRequestConfirm confirm)
	{
		mcpsDataCnf_t* msg = &((McpsRequestConfirm_t*)confirm)->msg.confirm.msgData.dataCnf;
		return msg->msduHandle;
	}
	
	command Ieee_Status McpsDataRequestConfirm.getStatus(Mcps_DataRequestConfirm confirm)
	{
		mcpsDataCnf_t* msg = &((McpsRequestConfirm_t*)confirm)->msg.confirm.msgData.dataCnf;
		return msg->status;
	}
}
