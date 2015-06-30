includes Ieee802154Adts;
includes macTypes;

module MlmeScanRequestConfirmM
{
	provides 
	{
		interface MlmeScanRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeScanRequestConfirm.create( Mlme_ScanRequestConfirm *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(mlmeMessage_t), (uint8_t**)primitive);
		(*primitive)->msg.request.msgType = gMlmeScanReq_c;
		return res;
	}
	
	command result_t MlmeScanRequestConfirm.destroy( Mlme_ScanRequestConfirm primitive )
	{
		call BufferMng.release(0, (uint8_t*)primitive->msg.confirm.msgData.scanCnf.resList.pEnergyDetectList);
		call BufferMng.release(sizeof(nwkMessage_t), (uint8_t*)primitive);
		return SUCCESS;
	}
	
	command void MlmeScanRequestConfirm.setScanType( Mlme_ScanRequestConfirm request,
	                                                 uint8_t scanType )
	{
		mlmeScanReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.scanReq;
		msg->scanType = scanType;
	}
	                           
	command void MlmeScanRequestConfirm.setScanChannels( Mlme_ScanRequestConfirm request,
	                                                     uint32_t scanChannels )
	{
		uint8_t i;
		mlmeScanReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.scanReq;
		for (i=0;i<4;i++) {
			msg->scanChannels[i] = (scanChannels >> (i*8)) & 0xFF;
		}
	}
	
	command void MlmeScanRequestConfirm.setScanDuration( Mlme_ScanRequestConfirm request,
	                                                     uint8_t scanDuration )
	{
		mlmeScanReq_t* msg = &((MlmeRequestConfirm_t*)request)->msg.request.msgData.scanReq;
		msg->scanDuration = scanDuration;
	}

	command Ieee_Status MlmeScanRequestConfirm.getStatus( Mlme_ScanRequestConfirm confirm )
	{
		nwkScanCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.scanCnf;
		return msg->status;
	}
	
	command uint8_t MlmeScanRequestConfirm.getScanType( Mlme_ScanRequestConfirm confirm )
	{
		nwkScanCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.scanCnf;
		return msg->scanType;
	}
	
	command	uint32_t MlmeScanRequestConfirm.getUnscannedChannels( Mlme_ScanRequestConfirm confirm )
	{
		uint32_t tmp;
		nwkScanCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.scanCnf;
		tmp = msg->unscannedChannels[3];
		tmp = (tmp << 8) + msg->unscannedChannels[2];
		tmp = (tmp << 8) + msg->unscannedChannels[1];
		tmp = (tmp << 8) + msg->unscannedChannels[0];
		return tmp;
	}
	
	command uint8_t MlmeScanRequestConfirm.getResultListSize( Mlme_ScanRequestConfirm confirm )
	{
		nwkScanCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.scanCnf;
		return msg->resultListSize;
	}
	
	command uint8_t MlmeScanRequestConfirm.getEnergyDetectElement( Mlme_ScanRequestConfirm confirm, uint8_t theIndex )
	{
		nwkScanCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.scanCnf;
		return msg->resList.pEnergyDetectList[theIndex];
	}
	
	command Ieee_PanDescriptor MlmeScanRequestConfirm.getPanDescriptor( Mlme_ScanRequestConfirm confirm, uint8_t theIndex )
	{
		nwkScanCnf_t* msg = &((MlmeRequestConfirm_t*)confirm)->msg.confirm.msgData.scanCnf;
		return &((Ieee_PanDescriptor)msg->resList.pPanDescriptorList)[theIndex];
	}
}
