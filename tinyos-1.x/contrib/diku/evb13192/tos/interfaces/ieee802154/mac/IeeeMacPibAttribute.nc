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

interface IeeeMacPibAttribute
{
	// when calling create, make sure the buffer is large enough for the 
	// entire PIB attribute
/*	command result_t create( char* buffer,
	                         uint8_t bufferLen,
	                         Ieee_PibAttribute *pibAttribute );
	                         
	command char* getBuffer( Ieee_PibAttribute pibAttribute );*/
	
	command result_t create( uint8_t size, Ieee_PibAttribute *pibAttribute );
	command result_t destroy( Ieee_PibAttribute pibAttribute );
	
	command uint8_t getPibAttributeType( Ieee_PibAttribute pibAttribute );
	command void setPibAttributeType( Ieee_PibAttribute pibAttribute,
	                                  uint8_t pibAttributeType );
	
	// MAC Sublayer PIB's
	// 0x40
	command void setMacAckWaitDuration( Ieee_PibAttribute pibAttribute,
	                                    uint8_t ackWaitDuration );
	// 0x41
	command void setMacAssociationPermit( Ieee_PibAttribute pibAttribute,
	                                      bool associationPermit );
	// 0x42
	command void setMacAutoRequest( Ieee_PibAttribute pibAttribute,
	                                bool autoRequest );
	// 0x43
	command void setMacBattLifeExt( Ieee_PibAttribute pibAttribute,
	                                bool battLifeExt );
	// 0x44
	command void setMacBattLifeExtPeriods( Ieee_PibAttribute pibAttribute,
	                                       uint8_t battLifeExtPeriods );
	// 0x45
	command void setMacBeaconPayload( Ieee_PibAttribute pibAttribute,
	                                  Ieee_Msdu payload );
	// 0x46
	command void setMacBeaconPayloadLength( Ieee_PibAttribute pibAttribute,
	                                        Ieee_Msdu payload );
	// 0x47
	command void setMacBeaconOrder( Ieee_PibAttribute pibAttribute,
	                                uint8_t beaconOrder );
	// 0x48
	command void setMacBeaconTxTime( Ieee_PibAttribute pibAttribute,
	                                 uint32_t beaconTxTime );
	// 0x49
	command void setMacBsn( Ieee_PibAttribute pibAttribute,
	                        uint8_t bsn );
	// 0x4A
	command void setMacCoordExtendedAddress( Ieee_PibAttribute pibAttribute,
	                                         uint8_t *coordExtendedAddress );
	// 0x4B
	command void setMacCoordShortAddress( Ieee_PibAttribute pibAttribute,
	                                      uint16_t coordShortAddress );
	// 0x4C
	command void setMacDsn( Ieee_PibAttribute pibAttribute,
	                        uint8_t dsn );
	// 0x4D
	command void setMacGtsPermit( Ieee_PibAttribute pibAttribute,
	                              bool gtsPermit );
	// 0x4E
	command void setMacMaxCsmaBackoffs( Ieee_PibAttribute pibAttribute,
	                                    uint8_t maxCsmaBackoffs );
	// 0x4F
	command void setMacMinBe( Ieee_PibAttribute pibAttribute,
	                          uint8_t minBe );
	// 0x50
	command void setMacPanId( Ieee_PibAttribute pibAttribute,
	                          uint16_t panId );
	// 0x51
	command void setMacPromiscuousMode( Ieee_PibAttribute pibAttribute,
	                                    bool promiscuousMode );
	// 0x52
	command void setMacRxOnWhenIdle( Ieee_PibAttribute pibAttribute,
	                                 bool rxOnWhenIdle );
	// 0x53
	command void setMacShortAddress( Ieee_PibAttribute pibAttribute,
	                                 uint16_t shortAddress );
	// 0x54
	command void setMacSuperframeOrder( Ieee_PibAttribute pibAttribute,
	                                    uint8_t superframeOrder );
	// 0x55
	command void setMacTransactionPersistenceTime( Ieee_PibAttribute pibAttribute,
	                                               uint16_t transactionPersistenceTime );
	// 0x71
	command void setMacAclEntryDescriptorSetSize( Ieee_PibAttribute pibAttribute,
	                                              uint8_t aclEntryDescriptorSetSize );
	// 0x72
	command void setMacDefaultSecurity( Ieee_PibAttribute pibAttribute,
	                                    bool defaultSecurity );
	// 0x73
	command void setMacDefaultSecurityMaterialLength( Ieee_PibAttribute pibAttribute,
	                                                  uint8_t defaultSecurityMaterialLength );
	// 0x74
	command void setMacDefaultSecurityMaterial( Ieee_PibAttribute pibAttribute,
	                                       uint8_t* defaultSecurityMaterial );
	// 0x75
	command void setMacDefaultSecuritySuite( Ieee_PibAttribute pibAttribute,
	                                         uint8_t defaultSecuritySuite );
	// 0x76
	command void setMacSecurityMode( Ieee_PibAttribute pibAttribute,
	                                 uint8_t securityMode );
	

	// MAC Sublayer PIB's
	// 0x40
	command uint8_t getMacAckWaitDuration( Ieee_PibAttribute pibAttribute );
	// 0x41
	command bool getMacAssociationPermit( Ieee_PibAttribute pibAttribute );
	// 0x42
	command bool getMacAutoRequest( Ieee_PibAttribute pibAttribute );
	// 0x43
	command bool getMacBattLifeExt( Ieee_PibAttribute pibAttribute );
	// 0x44
	command uint8_t getMacBattLifeExtPeriods( Ieee_PibAttribute pibAttribute );
	// 0x45
	command void getMacBeaconPayload( Ieee_PibAttribute pibAttribute, Ieee_Msdu payload );
	// 0x46
	command void getMacBeaconPayloadLength( Ieee_PibAttribute pibAttribute, Ieee_Msdu payload );
	// 0x47
	command uint8_t getMacBeaconOrder( Ieee_PibAttribute pibAttribute );
	// 0x48
	command uint32_t getMacBeaconTxTime( Ieee_PibAttribute pibAttribute );
	// 0x49
	command uint8_t getMacBsn( Ieee_PibAttribute pibAttribute );
	// 0x4A
	command uint8_t *getMacCoordExtendedAddress( Ieee_PibAttribute pibAttribute );
	// 0x4B
	command uint16_t getMacCoordShortAddress( Ieee_PibAttribute pibAttribute );
	// 0x4C
	command uint8_t getMacDsn( Ieee_PibAttribute pibAttribute );
	// 0x4D
	command bool getMacGtsPermit( Ieee_PibAttribute pibAttribute );
	// 0x4E
	command uint8_t getMacMaxCsmaBackoffs( Ieee_PibAttribute pibAttribute );
	// 0x4F
	command uint8_t getMacMinBe( Ieee_PibAttribute pibAttribute );
	// 0x50
	command uint16_t getMacPanId( Ieee_PibAttribute pibAttribute );
	// 0x51
	command bool getMacPromiscuousMode( Ieee_PibAttribute pibAttribute );
	// 0x52
	command bool getMacRxOnWhenIdle( Ieee_PibAttribute pibAttribute );
	// 0x53
	command uint16_t getMacShortAddress( Ieee_PibAttribute pibAttribute );
	// 0x54
	command uint8_t getMacSuperframeOrder( Ieee_PibAttribute pibAttribute );
	// 0x55
	command uint16_t getMacTransactionPersistenceTime( Ieee_PibAttribute pibAttribute );
	// 0x70
	// use this command to edit acl descriptors as well
	command Ieee_AclDescriptor getMacAclEntryDescriptor( Ieee_PibAttribute pibAttribute, uint8_t index );	
	// 0x71
	command uint8_t getMacAclEntryDescriptorSetSize( Ieee_PibAttribute pibAttribute );
	// 0x72
	command bool getMacDefaultSecurity( Ieee_PibAttribute pibAttribute );
	// 0x73
	command uint8_t getMacDefaultSecurityMaterialLength( Ieee_PibAttribute pibAttribute );
	// 0x74
	command uint8_t* getMacDefaultSecurityMaterial( Ieee_PibAttribute pibAttribute );
	// 0x75
	command uint8_t getMacDefaultSecuritySuite( Ieee_PibAttribute pibAttribute );
	// 0x76
	command uint8_t getMacSecurityMode( Ieee_PibAttribute pibAttribute );	
}
