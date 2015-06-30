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

interface IeeeSyncRequestConfirm<Ieee_RequestConfirm>
{
	/** Dispatch an 802.15.4 request. Note that the buffer for the 
		request	primitive is reused for the confirm primitive.
		This is a special version of the request confirm interface
		that makes it possible to return the confirm primitive as
		return value from the request call. This is very useful for
		the get and set functionality, as the confirm is ready right
		away.
		@param request Request primitive.
		@return SUCCESS if the request is accepted.
	**/
	command Ieee_RequestConfirm request( Ieee_RequestConfirm request );
	
	/** Confirm event for a previously issued request.
		Not all requests result in a filled out  confirm primitive,
		but the confirm event is signalled once for every 
		accepted request using the original request primitve
		pointer.
		Note that the confirm event can be ignored if the return value
		from the request call is used.
		@confirm Confirm primitive. Always uses same buffer as 
		the original request primitive pointer.
	**/
	event void confirm( Ieee_RequestConfirm confirm );
}
