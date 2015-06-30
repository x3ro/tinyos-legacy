/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

#include <Ieee802154Adts.h>
#include <macTypes.h>

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
		return call BufferMng.claim(sizeof(mlmeScanRequestConfirm_t), (uint8_t**)primitive);
	}
	
	command result_t MlmeScanRequestConfirm.destroy( Mlme_ScanRequestConfirm primitive )
	{
		if (FAIL == call BufferMng.release(sizeof(panDescriptor_t)*Ieee_Num_PAN_Desc, primitive->msg.confirm.resultList)) {
			return FAIL;
		}
		return call BufferMng.release(sizeof(mlmeScanRequestConfirm_t), (uint8_t*)primitive);
	}
	
	command void MlmeScanRequestConfirm.setScanType( Mlme_ScanRequestConfirm request,
	                                                 uint8_t scanType )
	{
		request->msg.request.scanType = scanType;
		if (scanType == IEEE802154_OrphanScan) {
			// Set default scan duration.
			request->msg.request.scanDuration = 5;
		}
	}
	                           
	command void MlmeScanRequestConfirm.setScanChannels( Mlme_ScanRequestConfirm request,
	                                                     uint32_t scanChannels )
	{
		request->msg.request.scanChannels = scanChannels;
	}
	
	command void MlmeScanRequestConfirm.setScanDuration( Mlme_ScanRequestConfirm request,
	                                                     uint8_t scanDuration )
	{
		request->msg.request.scanDuration = scanDuration;
	}

	command Ieee_Status MlmeScanRequestConfirm.getStatus( Mlme_ScanRequestConfirm confirm )
	{
		return confirm->msg.confirm.status;
	}
	
	command uint8_t MlmeScanRequestConfirm.getScanType( Mlme_ScanRequestConfirm confirm )
	{
		return confirm->msg.confirm.scanType;
	}
	
	command	uint32_t MlmeScanRequestConfirm.getUnscannedChannels( Mlme_ScanRequestConfirm confirm )
	{
		return confirm->msg.confirm.unscannedChannels;
	}
	
	command uint8_t MlmeScanRequestConfirm.getResultListSize( Mlme_ScanRequestConfirm confirm )
	{
		return confirm->msg.confirm.resultListLen;
	}
	
	command uint8_t MlmeScanRequestConfirm.getEnergyDetectElement( Mlme_ScanRequestConfirm confirm, uint8_t theIndex )
	{
		return confirm->msg.confirm.resultList[theIndex];
	}
	
	command Ieee_PanDescriptor MlmeScanRequestConfirm.getPanDescriptor( Mlme_ScanRequestConfirm confirm, uint8_t theIndex )
	{
		return &(((Ieee_PanDescriptor)confirm->msg.confirm.resultList)[theIndex]);
	}
}
