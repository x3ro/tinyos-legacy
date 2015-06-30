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

#include <MacPib.h>
#include <Ieee802154Adts.h>
#include <endianconv.h>

module PibAttributeM {
	provides {
		interface IeeeMacPibAttribute as IeeePibAttribute;
	}
	uses
	{
		interface IeeeBufferManagement as BufferMng;
	}
}
implementation
{
	command result_t IeeePibAttribute.create( uint8_t size, Ieee_PibAttribute *pibAttribute )
	{
		result_t res = call BufferMng.claim(size+3, (uint8_t**)pibAttribute);
		if (res == SUCCESS) {
			(*pibAttribute)->destroyable = TRUE;
			(*pibAttribute)->size = size+3;
		}
		return res;
	}
	
	command result_t IeeePibAttribute.destroy( Ieee_PibAttribute pibAttribute )
	{
		if (pibAttribute->destroyable) {
			return call BufferMng.release(pibAttribute->size, (uint8_t*)pibAttribute);
		}
		return FAIL;
	}
	
	command uint8_t IeeePibAttribute.getPibAttributeType( Ieee_PibAttribute pibAttribute )
	{
		return pibAttribute->attribute;
	}
	
	command void IeeePibAttribute.setPibAttributeType( Ieee_PibAttribute pibAttribute,
	                                                   uint8_t pibAttributeType )
	{
		pibAttribute->attribute = pibAttributeType;
	}
	
	// MAC Sublayer PIB's
	// 0x40
	command void IeeePibAttribute.setMacAckWaitDuration( Ieee_PibAttribute pibAttribute,
	                                                     uint8_t ackWaitDuration )
	{
		pibAttribute->attribute = IEEE802154_macAckWaitDuration;
  		((uint8_t*)pibAttribute->value)[0] = ackWaitDuration;
	}
	
	// 0x41
	command void IeeePibAttribute.setMacAssociationPermit( Ieee_PibAttribute pibAttribute,
	                                                       bool associationPermit )
	{
		pibAttribute->attribute = IEEE802154_macAssociationPermit;
		((bool*)pibAttribute->value)[0] = associationPermit;
	}
	// 0x42
	command void IeeePibAttribute.setMacAutoRequest( Ieee_PibAttribute pibAttribute,
	                                                 bool autoRequest )
	{
		pibAttribute->attribute = IEEE802154_macAutoRequest;
		((bool*)pibAttribute->value)[0] = autoRequest;
	}
	// 0x43
	command void IeeePibAttribute.setMacBattLifeExt( Ieee_PibAttribute pibAttribute,
	                                                 bool battLifeExt )
	{
		pibAttribute->attribute = IEEE802154_macBattLifeExt;
		((bool*)pibAttribute->value)[0] = battLifeExt;
	}
	// 0x44
	command void IeeePibAttribute.setMacBattLifeExtPeriods( Ieee_PibAttribute pibAttribute,
	                                                        uint8_t battLifeExtPeriods )
	{
		pibAttribute->attribute = IEEE802154_macBattLifeExtPeriods;
  		((uint8_t*)pibAttribute->value)[0] = battLifeExtPeriods;
	}
	// 0x45
	command void IeeePibAttribute.setMacBeaconPayload( Ieee_PibAttribute pibAttribute,
	                                                   Ieee_Msdu payload )
	{
		pibAttribute->attribute = IEEE802154_macBeaconPayload;
  		((uint8_t**)pibAttribute->value)[0] = payload->payload;
	}
	// 0x46
	command void IeeePibAttribute.setMacBeaconPayloadLength( Ieee_PibAttribute pibAttribute,
	                                                         Ieee_Msdu payload )
	{
		pibAttribute->attribute = IEEE802154_macBeaconPayloadLength;
  		((uint16_t*)pibAttribute->value)[0] = payload->payloadLen;
	}
	// 0x47
	command void IeeePibAttribute.setMacBeaconOrder( Ieee_PibAttribute pibAttribute,
	                                                 uint8_t beaconOrder )
	{
		pibAttribute->attribute = IEEE802154_macBeaconOrder;
  		((uint8_t*)pibAttribute->value)[0] = beaconOrder;
	}
	// 0x48
	command void IeeePibAttribute.setMacBeaconTxTime( Ieee_PibAttribute pibAttribute,
	                                                  uint32_t beaconTxTime )
	{
		pibAttribute->attribute = IEEE802154_macBeaconTxTime;
  		((uint32_t*)pibAttribute->value)[0] = beaconTxTime;
	}
	// 0x49
	command void IeeePibAttribute.setMacBsn( Ieee_PibAttribute pibAttribute,
	                                         uint8_t bsn )
	{
		pibAttribute->attribute = IEEE802154_macBSN;
  		((uint8_t*)pibAttribute->value)[0] = bsn;
	}
	// 0x4A
	command void IeeePibAttribute.setMacCoordExtendedAddress( Ieee_PibAttribute pibAttribute,
	                                                          uint8_t *coordExtendedAddress )
	{
		pibAttribute->attribute = IEEE802154_macCoordExtendedAddress;
		memcpy(pibAttribute->value, coordExtendedAddress, 8);
	}
	// 0x4B
	command void IeeePibAttribute.setMacCoordShortAddress( Ieee_PibAttribute pibAttribute,
	                                                       uint16_t coordShortAddress )
	{
		pibAttribute->attribute = IEEE802154_macCoordShortAddress;
  		((uint16_t*)pibAttribute->value)[0] = coordShortAddress;
	}
	// 0x4C
	command void IeeePibAttribute.setMacDsn( Ieee_PibAttribute pibAttribute,
	                                         uint8_t dsn )
	{
		pibAttribute->attribute = IEEE802154_macDSN;
  		((uint8_t*)pibAttribute->value)[0] = dsn;
	}
	// 0x4D
	command void IeeePibAttribute.setMacGtsPermit( Ieee_PibAttribute pibAttribute,
	                                               bool gtsPermit )
	{
		pibAttribute->attribute = IEEE802154_macGTSPermit;
  		((bool*)pibAttribute->value)[0] = gtsPermit;
	}
	// 0x4E
	command void IeeePibAttribute.setMacMaxCsmaBackoffs( Ieee_PibAttribute pibAttribute,
	                                                     uint8_t maxCsmaBackoffs )
	{
		pibAttribute->attribute = IEEE802154_macMaxCSMABackoffs;
  		((uint8_t*)pibAttribute->value)[0] = maxCsmaBackoffs;
	}
	// 0x4F
	command void IeeePibAttribute.setMacMinBe( Ieee_PibAttribute pibAttribute,
	                                           uint8_t minBe )
	{
		pibAttribute->attribute = IEEE802154_macMinBE;
  		((uint8_t*)pibAttribute->value)[0] = minBe;
	}
	// 0x50
	command void IeeePibAttribute.setMacPanId( Ieee_PibAttribute pibAttribute,
	                                           uint16_t panId )
	{
		pibAttribute->attribute = IEEE802154_macPANId;
  		((uint16_t*)pibAttribute->value)[0] = panId;
	}
	// 0x51
	command void IeeePibAttribute.setMacPromiscuousMode( Ieee_PibAttribute pibAttribute,
	                                                     bool promiscuousMode )
	{
		pibAttribute->attribute = IEEE802154_macPromiscuousMode;
  		((bool*)pibAttribute->value)[0] = promiscuousMode;
	}
	// 0x52
	command void IeeePibAttribute.setMacRxOnWhenIdle( Ieee_PibAttribute pibAttribute,
	                                                  bool rxOnWhenIdle )
	{
		pibAttribute->attribute = IEEE802154_macRxOnWhenIdle;
  		((bool*)pibAttribute->value)[0] = rxOnWhenIdle;
	}
	// 0x53
	command void IeeePibAttribute.setMacShortAddress( Ieee_PibAttribute pibAttribute,
	                                                  uint16_t shortAddress )
	{
		pibAttribute->attribute = IEEE802154_macShortAddress;
		((uint16_t*)pibAttribute->value)[0] = shortAddress;
	}
	// 0x54
	command void IeeePibAttribute.setMacSuperframeOrder( Ieee_PibAttribute pibAttribute,
	                                                     uint8_t superframeOrder )
	{
		pibAttribute->attribute = IEEE802154_macSuperframeOrder;
		((uint8_t*)pibAttribute->value)[0] = superframeOrder;
	}
	// 0x55
	command void IeeePibAttribute.setMacTransactionPersistenceTime( Ieee_PibAttribute pibAttribute,
	                                                                uint16_t transactionPersistenceTime )
	{
		pibAttribute->attribute = IEEE802154_macTransactionPersistenceTime;
		((uint16_t*)pibAttribute->value)[0] = transactionPersistenceTime;
	}
	
	// 0x71
	command void IeeePibAttribute.setMacAclEntryDescriptorSetSize( Ieee_PibAttribute pibAttribute,
	                                                               uint8_t aclEntryDescriptorSetSize )
	{
		pibAttribute->attribute = IEEE802154_macACLEntryDescriptorSetSize;
		((uint8_t*)pibAttribute->value)[0] = aclEntryDescriptorSetSize;
	}
	// 0x72
	command void IeeePibAttribute.setMacDefaultSecurity( Ieee_PibAttribute pibAttribute,
	                                                     bool defaultSecurity )
	{
		pibAttribute->attribute = IEEE802154_macDefaultSecurity;
  		((bool*)pibAttribute->value)[0] = defaultSecurity;
	}
	// 0x73
	command void IeeePibAttribute.setMacDefaultSecurityMaterialLength( Ieee_PibAttribute pibAttribute,
	                                                                   uint8_t defaultSecurityMaterialLength )
	{
		pibAttribute->attribute = IEEE802154_macDefaultSecurityMaterialLength;
		((uint8_t*)pibAttribute->value)[0] = defaultSecurityMaterialLength;
	}
	// 0x74
	command void IeeePibAttribute.setMacDefaultSecurityMaterial( Ieee_PibAttribute pibAttribute,
	                                                             uint8_t* defaultSecurityMaterial )
	{
		pibAttribute->attribute = IEEE802154_macDefaultSecurityMaterial;
		((uint8_t**)pibAttribute->value)[0] = defaultSecurityMaterial;
	}
	// 0x75
	command void IeeePibAttribute.setMacDefaultSecuritySuite( Ieee_PibAttribute pibAttribute,
	                                                          uint8_t defaultSecuritySuite )
	{
		pibAttribute->attribute = IEEE802154_macDefaultSecuritySuite;
		((uint8_t*)pibAttribute->value)[0] = defaultSecuritySuite;
	}
	// 0x76
	command void IeeePibAttribute.setMacSecurityMode( Ieee_PibAttribute pibAttribute,
	                                                  uint8_t securityMode )
	{
		pibAttribute->attribute = IEEE802154_macSecurityMode;
		((uint8_t*)pibAttribute->value)[0] = securityMode;
	}
	

	// MAC Sublayer PIB's
	// 0x40
	command uint8_t IeeePibAttribute.getMacAckWaitDuration( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x41
	command bool IeeePibAttribute.getMacAssociationPermit( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x42
	command bool IeeePibAttribute.getMacAutoRequest( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x43
	command bool IeeePibAttribute.getMacBattLifeExt( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x44
	command uint8_t IeeePibAttribute.getMacBattLifeExtPeriods( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x45
	command void IeeePibAttribute.getMacBeaconPayload( Ieee_PibAttribute pibAttribute,
	                                                   Ieee_Msdu payload )
	{
		payload->payload = (uint8_t*)pibAttribute->value;
		payload->bufferDestroyable = FALSE;
	}
	// 0x46
	command void IeeePibAttribute.getMacBeaconPayloadLength( Ieee_PibAttribute pibAttribute,
	                                                         Ieee_Msdu payload )
	{
		payload->payloadLen = *((uint8_t*)pibAttribute->value);
	}
	// 0x47
	command uint8_t IeeePibAttribute.getMacBeaconOrder( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x48
	command uint32_t IeeePibAttribute.getMacBeaconTxTime( Ieee_PibAttribute pibAttribute )
	{
		return *((uint32_t*)pibAttribute->value);
	}
	// 0x49
	command uint8_t IeeePibAttribute.getMacBsn( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x4A
	command uint8_t *IeeePibAttribute.getMacCoordExtendedAddress( Ieee_PibAttribute pibAttribute )
	{
		return pibAttribute->value;
	}
	// 0x4B
	command uint16_t IeeePibAttribute.getMacCoordShortAddress( Ieee_PibAttribute pibAttribute )
	{
		return *((uint16_t*)pibAttribute->value);
	}
	// 0x4C
	command uint8_t IeeePibAttribute.getMacDsn( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x4D
	command bool IeeePibAttribute.getMacGtsPermit( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x4E
	command uint8_t IeeePibAttribute.getMacMaxCsmaBackoffs( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x4F
	command uint8_t IeeePibAttribute.getMacMinBe( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x50
	command uint16_t IeeePibAttribute.getMacPanId( Ieee_PibAttribute pibAttribute )
	{
		return *((uint16_t*)pibAttribute->value);
	}
	// 0x51
	command bool IeeePibAttribute.getMacPromiscuousMode( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x52
	command bool IeeePibAttribute.getMacRxOnWhenIdle( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x53
	command uint16_t IeeePibAttribute.getMacShortAddress( Ieee_PibAttribute pibAttribute )
	{
		return *((uint16_t*)pibAttribute->value);
	}
	// 0x54
	command uint8_t IeeePibAttribute.getMacSuperframeOrder( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x55
	command uint16_t IeeePibAttribute.getMacTransactionPersistenceTime( Ieee_PibAttribute pibAttribute )
	{
		return *((uint16_t*)pibAttribute->value);
	}
	// 0x70
	// use this command to edit acl descriptors as well
	command Ieee_AclDescriptor IeeePibAttribute.getMacAclEntryDescriptor( Ieee_PibAttribute pibAttribute, uint8_t index )
	{
		return (Ieee_AclDescriptor)pibAttribute->value;
	}
	// 0x71
	command uint8_t IeeePibAttribute.getMacAclEntryDescriptorSetSize( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x72
	command bool IeeePibAttribute.getMacDefaultSecurity( Ieee_PibAttribute pibAttribute )
	{
		return *((bool*)pibAttribute->value);
	}
	// 0x73
	command uint8_t IeeePibAttribute.getMacDefaultSecurityMaterialLength( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x74
	command uint8_t* IeeePibAttribute.getMacDefaultSecurityMaterial( Ieee_PibAttribute pibAttribute )
	{
		return (uint8_t*)pibAttribute->value;
	}
	// 0x75
	command uint8_t IeeePibAttribute.getMacDefaultSecuritySuite( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
	// 0x76
	command uint8_t IeeePibAttribute.getMacSecurityMode( Ieee_PibAttribute pibAttribute )
	{
		return *((uint8_t*)pibAttribute->value);
	}
}
