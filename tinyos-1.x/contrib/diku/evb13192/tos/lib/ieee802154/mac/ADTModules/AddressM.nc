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

module AddressM
{
	provides 
	{
		interface IeeeAddress;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t IeeeAddress.create( Ieee_Address *primitive )
	{
		result_t res = call BufferMng.claim(sizeof(ieeeAddress_t), (uint8_t**)primitive);
		if (res == SUCCESS) {
			// Initialize primitive to contain no address.
			(*primitive)->mode = 0;
		}
		return res;
	}
	
	command result_t IeeeAddress.destroy( Ieee_Address primitive )
	{
		return call BufferMng.release(sizeof(ieeeAddress_t), (uint8_t*)primitive);
	}

	command result_t IeeeAddress.setAddrMode( Ieee_Address addr, uint8_t mode )
	{
		addr->mode = mode;
		return SUCCESS;
	}
	
	command result_t IeeeAddress.setPanId( Ieee_Address addr, uint16_t panId )
	{
		if (addr->mode) {
			NTOUH16((uint8_t*)&panId, (uint8_t*)&(addr->panId));
			return SUCCESS;
		}
		return FAIL;
	}
	
	command result_t IeeeAddress.setAddress( Ieee_Address addr, uint8_t *address )
	{
		if (addr->mode) {
			if (addr->mode == 3) {
				NTOUH64(address, addr->address);
			} else {
				NTOUH16(address, addr->address);
			} 
			return SUCCESS;
		}
		return FAIL;
	}

	command uint8_t IeeeAddress.getAddrMode( Ieee_Address addr )
	{
		return addr->mode;
	}
	
	command uint16_t IeeeAddress.getPanId( Ieee_Address addr )
	{
		uint16_t ret;
		NTOUH16((uint8_t*)&(addr->panId), (uint8_t*)&ret);
		return ret;
	}
	
	command void IeeeAddress.getAddress( Ieee_Address addr, uint8_t *myAddress )
	{
		if (addr->mode == 3) {
			NTOUH64(addr->address, myAddress);
		} else {
			NTOUH16(addr->address, myAddress);
		}
	}
}
