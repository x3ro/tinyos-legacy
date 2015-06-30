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
		// TODO: I'm sure the buffer should be deallocated here!!!
		call BufferMng.release(primitive->msg.indication.frameLength,primitive->msg.indication.beaconFrame);
		//call BufferMng.release(0, (uint8_t*)primitive->msg.indication.msgData.beaconNotifyInd.pBufferRoot);
		call BufferMng.release(sizeof(mlmeBeaconNotifyIndicationMsg_t), (uint8_t*)primitive);
		return SUCCESS;
	}
		
	command uint8_t MlmeBeaconNotifyIndication.getBsn( Mlme_BeaconNotifyIndication indication )
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		return mhrSeqNumber(frame);
	}
	
	command void MlmeBeaconNotifyIndication.getPanDescriptor( Mlme_BeaconNotifyIndication indication,
	                                                          Ieee_PanDescriptor panDesc )
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		mlmeBeaconNotifyIndicationMsg_t *beaconInd = &(indication->msg.indication);
		// Fill out the PAN Descriptor.
		// Set address
		if (mhrSrcAddrLength(frame) == 2) {
			NTOUH16(mhrSrcAddr(frame), panDesc->coordAddress);
		} else {
			NTOUH64(mhrSrcAddr(frame), panDesc->coordAddress);
		}
		NTOUH16(mhrSrcPANId(frame), &((uint8_t)panDesc->coordPanId));
		panDesc->coordAddrMode = mhrSrcAddrMode(frame);
		panDesc->logicalChannel = beaconInd->logicalChannel;
		NTOUH16(msduGetSuperframeSpecPtr(frame), &((uint8_t)panDesc->superFrameSpec));
		panDesc->gtsPermit = msduGTSPermit(frame);
		panDesc->linkQuality = beaconInd->linkQuality;
		panDesc->timeStamp = beaconInd->timeStamp;
		panDesc->securityUse = mhrSecurityEnabled(frame);
		panDesc->ACLEntry = beaconInd->ACLEntry;
		panDesc->securityFailure = beaconInd->securityFailure;
	}
	
	command uint8_t MlmeBeaconNotifyIndication.getShortAddrCount( Mlme_BeaconNotifyIndication indication )
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		return msduNumShortAddrsPending(frame);
	}
	
	command uint16_t MlmeBeaconNotifyIndication.getShortAddr( Mlme_BeaconNotifyIndication indication, uint8_t index )
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		uint16_t ret;
		// short adresses appear first in the list
		NTOUH16( (msduPendingAddrList(frame) + 2*index), &((uint8_t)ret) );
		return ret;
	}
	
	command uint8_t MlmeBeaconNotifyIndication.getLongAddrCount(Mlme_BeaconNotifyIndication indication)
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		return msduNumExtAddrsPending(frame);
	}
	
	command void MlmeBeaconNotifyIndication.getLongAddr( Mlme_BeaconNotifyIndication indication,
	                                                     uint8_t index, uint8_t *addr )
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		// skip the short address bytes first
		NTOUH64( (msduPendingAddrList(frame) + 2*(msduNumShortAddrsPending(frame)) + 8*index), addr );
	}
	
	command void MlmeBeaconNotifyIndication.getSdu(Mlme_BeaconNotifyIndication indication,
	                                               Ieee_Msdu msdu)
	{
		uint8_t *frame = indication->msg.indication.beaconFrame;
		msdu->bufferLen = indication->msg.indication.frameLength;
		msdu->buffer = indication->msg.indication.beaconFrame;
		msdu->payloadLen = (msdu->bufferLen - mhrLengthFrame(frame));
		msdu->payload = msduBeaconPayload(frame);
		msdu->bufferDestroyable = FALSE;
	}
}
