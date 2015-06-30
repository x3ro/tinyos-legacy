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

//includes adts;
includes macTypes;

interface MlmeStartRequestConfirm
{
/*	command result_t create( char* buffer,
	                         uint8_t bufferLen,
	                         Mlme_StartRequestConfirm *primitive );
	                         
	command char* getBuffer( Mlme_StartRequestConfirm primitive );*/
	
	command result_t create( Mlme_StartRequestConfirm *primitive );
	command result_t destroy( Mlme_StartRequestConfirm primitive );

	command void setPanId( Mlme_StartRequestConfirm request,
	                       uint16_t panId );
	                       
	command void setLogicalChannel( Mlme_StartRequestConfirm request,
	                                uint8_t logicalChannel );
	                                
	command void setBeaconOrder( Mlme_StartRequestConfirm request,
	                             uint8_t beaconOrder );
	                             
	command void setSuperframeOrder( Mlme_StartRequestConfirm request,
	                                 uint8_t superframeOrder );
	
	command void setPanCoordinator( Mlme_StartRequestConfirm request,
	                                bool panCoordinator );
	                                
	command void setBatteryLifeExtension( Mlme_StartRequestConfirm request,
	                                      bool batteryLifeExtension );
		
	command void setCoordRealignment( Mlme_StartRequestConfirm request,
	                                  bool coordRealignment );
	
	command void setSecurityEnable( Mlme_StartRequestConfirm request,
	                               	bool securityEnable );

	command	Ieee_Status getStatus(  Mlme_StartRequestConfirm confirm );
}
