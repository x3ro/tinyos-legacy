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

module McpsDataIndicationM
{
	provides
	{
		interface McpsDataIndication;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
		interface MacAddress;
	}
}
implementation
{	
	command result_t McpsDataIndication.destroy(Mcps_DataIndication primitive)
	{
		if (primitive->destroyable) {
			// We need to destroy the frame, as it was not retrieved!
			// TODO
		}
		return call BufferMng.release(sizeof(mcpsDataIndication_t), (uint8_t*)primitive);
	}

	command void McpsDataIndication.getSrcAddress( Mcps_DataIndication indication, Ieee_Address addr )
	{
		uint8_t *dataFrame = indication->msg.indication.dataFrame;
		call MacAddress.getSrcAddr(dataFrame, addr);
	}
	command void McpsDataIndication.getDstAddress(  Mcps_DataIndication indication, Ieee_Address addr )
	{
		uint8_t *dataFrame = indication->msg.indication.dataFrame;
		call MacAddress.getDstAddr(dataFrame, addr);
	}
	
	command result_t McpsDataIndication.getMsdu( Mcps_DataIndication indication,
	                                             Ieee_Msdu msdu )
	{
		// Frame will be destroy with the msdu structure.
		indication->destroyable = FALSE;
		msdu->bufferLen = indication->msg.indication.dataFrameLen;
		msdu->buffer = indication->msg.indication.dataFrame;
		msdu->payloadLen = msdu->bufferLen - (mhrLengthFrame(msdu->buffer));
		msdu->payload = msduGetPtr(msdu->buffer);
		msdu->bufferDestroyable = TRUE;
		return SUCCESS;
	}
	
	command uint8_t McpsDataIndication.getMpduLinkQuality( Mcps_DataIndication indication )
	{
		return indication->msg.indication.mpduLinkQuality;
	}
	
	command bool McpsDataIndication.getSecurityUse( Mcps_DataIndication indication )
	{
		uint8_t *dataFrame = indication->msg.indication.dataFrame;
		return mhrSecurityEnabled(dataFrame);
	}
	
	command uint8_t McpsDataIndication.getAclEntry( Mcps_DataIndication indication )
	{
		return indication->msg.indication.ACLEntry;
	}
}
