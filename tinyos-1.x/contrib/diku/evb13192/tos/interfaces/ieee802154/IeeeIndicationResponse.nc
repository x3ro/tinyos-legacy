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

interface IeeeIndicationResponse<Ieee_IndicationResponse>
{
	/** Allows the 802.15.4 layer to request an indication primitive.
		The application may have to fill out some attributes of the 
		indication primitive before passing it to 802.15.4.
		@return Indication primitive passed to 802.15.4.
	**/
	//event Ieee_IndicationResponse prepareIndication( );
	
	/** Signalled whenever the 802.15.4 layer has filled out a 
		primitive and is ready to deliver.
		@param indication Indication primitive.
	**/
	async event void indication( Ieee_IndicationResponse indication );
	
	/** Respond to a previously signalled event. The event primitive
		may be used for response, if no other event handlers are
		wired to the indication event.
		@param response Response primitive.
		@return SUCCESS if the response is accepted by the MAC layer.
	**/
	command result_t response( Ieee_IndicationResponse resp );	
	
	/** Signalled when a response primitive is no longer needed by 802.15.4.
		@param response Response primitive.
	**/
	//event void responseDone( Ieee_IndicationResponse resp );	
}
