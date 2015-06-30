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
		interface MacAddress;
	}
}
implementation
{
	command result_t McpsDataRequestConfirm.create( Mcps_DataRequestConfirm *primitive,
	                                                Ieee_Address srcAddress, 
	                                                Ieee_Address dstAddress,
	                                                uint8_t msduLength )
	{
		uint8_t *dataFrame;
		bool intraPAN = (srcAddress->panId == dstAddress->panId);
		uint8_t frameSize = mhrFrameControlLength
		                    + mhrSequenceNumberLength
		                    + mhrSrcAddrModeLength(srcAddress->mode, intraPAN)
		                    + mhrDstAddrModeLength(dstAddress->mode)
		                    + msduLength;
		if (FAIL == call BufferMng.claim(sizeof(mcpsDataRequestConfirm_t), (uint8_t**)primitive)) {
			return FAIL;
		}
		if (FAIL == call BufferMng.claim(frameSize, &((*primitive)->msg.request.dataFrame))) {
			call BufferMng.release(sizeof(mcpsDataRequestConfirm_t), (uint8_t*)(*primitive));
			return FAIL;
		}
		
		// Set addressing modes in dataframe.
		dataFrame = (*primitive)->msg.request.dataFrame;
		mhrIntraPAN(dataFrame) = intraPAN;
		
		call MacAddress.setDstAddr(dataFrame, dstAddress);
		call MacAddress.setSrcAddr(dataFrame, dstAddress);

		mhrFrameType(dataFrame) = macDataFrame;
		
		// Set frame length.
		(*primitive)->msg.request.dataFrameLen = frameSize;
		
		return SUCCESS;
	}
	
	command result_t McpsDataRequestConfirm.destroy( Mcps_DataRequestConfirm primitive )
	{
		// MAC layer is responsible for destroying the dataFrame	
		return call BufferMng.release(sizeof(mcpsDataRequestConfirm_t), (uint8_t*)primitive);
	}
	
	command result_t McpsDataRequestConfirm.getMsdu( Mcps_DataRequestConfirm request,
	                                                 Ieee_Msdu msdu )
	{
		uint8_t *dataFrame = request->msg.request.dataFrame;
		msdu->bufferLen = request->msg.request.dataFrameLen;
		msdu->buffer = dataFrame;
		msdu->payloadLen = (msdu->bufferLen - mhrLengthFrame(dataFrame));
		msdu->payload = msduGetPtr(dataFrame);
		msdu->bufferDestroyable = FALSE;
		return SUCCESS;
	}
	
	command void McpsDataRequestConfirm.setMsduHandle( Mcps_DataRequestConfirm request,
	                                                   uint8_t msduHandle )
	{
		request->msg.request.msduHandle = msduHandle;
	}
	
	command void McpsDataRequestConfirm.setTxOptions( Mcps_DataRequestConfirm request,
	                                                  uint8_t txOptions )
	{
		uint8_t *dataFrame;
		request->msg.request.txOptions = txOptions;
		// Also, set appropriate values in the dataFrame;
		dataFrame = request->msg.request.dataFrame;
		// Set acknowledged transmission.
		mhrAckRequest(dataFrame) = ((txOptions & 0x01)?1:0);
		// Set security enabled.
		mhrSecurityEnabled(dataFrame) = ((txOptions & 0x08)?1:0);
	}
	
	command uint8_t McpsDataRequestConfirm.getMsduHandle(Mcps_DataRequestConfirm confirm)
	{
		return confirm->msg.confirm.msduHandle;
	}
	
	command Ieee_Status McpsDataRequestConfirm.getStatus(Mcps_DataRequestConfirm confirm)
	{
		return confirm->msg.confirm.status;
	}
}
