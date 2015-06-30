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

module MlmeStartRequestConfirmM
{
	provides 
	{
		interface MlmeStartRequestConfirm;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{

	command result_t MlmeStartRequestConfirm.create( Mlme_StartRequestConfirm *primitive )
	{
		return call BufferMng.claim(sizeof(mlmeStartRequestConfirm_t), (uint8_t**)primitive);
	}
	
	command result_t MlmeStartRequestConfirm.destroy( Mlme_StartRequestConfirm primitive )
	{
		return call BufferMng.release(sizeof(mlmeStartRequestConfirm_t), (uint8_t*)primitive);
	}
	                         
	command void MlmeStartRequestConfirm.setPanId( Mlme_StartRequestConfirm request,
	                                               uint16_t panId )
	{
		request->msg.request.PANId = panId;
	}
	                       
	command void MlmeStartRequestConfirm.setLogicalChannel( Mlme_StartRequestConfirm request,
	                                                        uint8_t logicalChannel )
	{
		request->msg.request.logicalChannel = logicalChannel;
	}
	                                
	command void MlmeStartRequestConfirm.setBeaconOrder( Mlme_StartRequestConfirm request,
	                                                     uint8_t beaconOrder )
	{
		request->msg.request.beaconOrder = beaconOrder;
	}
	                             
	command void MlmeStartRequestConfirm.setSuperframeOrder( Mlme_StartRequestConfirm request,
	                                                         uint8_t superframeOrder )
	{
		request->msg.request.superframeOrder = superframeOrder;
	}
	
	command void MlmeStartRequestConfirm.setPanCoordinator( Mlme_StartRequestConfirm request,
	                                                        bool panCoordinator )
	{
		request->msg.request.PANCoordinator = panCoordinator;
	}
	                                
	command void MlmeStartRequestConfirm.setBatteryLifeExtension( Mlme_StartRequestConfirm request,
	                                                              bool batteryLifeExtension )
	{
		request->msg.request.battLifeExt = batteryLifeExtension;
	}
		
	command void MlmeStartRequestConfirm.setCoordRealignment( Mlme_StartRequestConfirm request,
	                                                          bool coordRealignment )
	{
		request->msg.request.coordRealign = coordRealignment;
	}
	
	command void MlmeStartRequestConfirm.setSecurityEnable( Mlme_StartRequestConfirm request,
	                                                        bool securityEnable )
	{
		request->msg.request.securityEnable = securityEnable;
	}

	command	Ieee_Status MlmeStartRequestConfirm.getStatus( Mlme_StartRequestConfirm confirm )
	{
		return confirm->msg.confirm.status;
	}
}
