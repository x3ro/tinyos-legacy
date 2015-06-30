module McpsPurgeRequestConfirmM
{
	provides
	{
		interface McpsPurgeRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{	
	command result_t McpsPurgeRequestConfirm.create( Mcps_PurgeRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(nwkToMcpsMessage_t), (uint8_t**)primitive);
		(*primitive)->msg.request.msgType = gMcpsPurgeReq_c;
		return res;
	}
	
	command result_t McpsPurgeRequestConfirm.destroy( Mcps_PurgeRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(mcpsToNwkMessage_t), (uint8_t*)primitive);
	}
	
	command void McpsPurgeRequestConfirm.setMsduHandle( Mcps_PurgeRequestConfirm request,
	                                                    uint8_t msduHandle )
	{
		mcpsPurgeReq_t* msg = &((McpsRequestConfirm_t*)request)->msg.request.msgData.purgeReq;
		msg->msduHandle = msduHandle;
	}
	
	
	command uint8_t McpsPurgeRequestConfirm.getMsduHandle( Mcps_PurgeRequestConfirm confirm )
	{
		mcpsPurgeCnf_t* msg = &((McpsRequestConfirm_t*)confirm)->msg.confirm.msgData.purgeCnf;
		return msg->msduHandle;
	}
	
	command	Ieee_Status McpsPurgeRequestConfirm.getStatus( Mcps_PurgeRequestConfirm confirm )
	{
		mcpsPurgeCnf_t* msg = &((McpsRequestConfirm_t*)confirm)->msg.confirm.msgData.purgeCnf;
		return msg->status;
	}
}
