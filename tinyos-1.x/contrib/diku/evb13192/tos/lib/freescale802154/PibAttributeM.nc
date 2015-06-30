includes Ieee802154Adts;
includes endianconv;

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
		result_t res = call BufferMng.claim(size+2, (uint8_t**)pibAttribute);
		if (res == SUCCESS) {
			(*pibAttribute)->destroyable = TRUE;
		}
		return res;
	}
	
	command result_t IeeePibAttribute.destroy( Ieee_PibAttribute pibAttribute )
	{
		if (pibAttribute->destroyable) {
			return call BufferMng.release(0, (uint8_t*)pibAttribute);
		}
		return FAIL;
	}
	
	command uint8_t IeeePibAttribute.getPibAttributeType( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return att->pibAttribute;
	}
	
	command void IeeePibAttribute.setPibAttributeType( Ieee_PibAttribute pibAttribute,
	                                                   uint8_t pibAttributeType )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = pibAttributeType;
	}
	
	// MAC Sublayer PIB's
	// 0x40
	command void IeeePibAttribute.setMacAckWaitDuration( Ieee_PibAttribute pibAttribute,
	                                                     uint8_t macAckWaitDuration )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibAckWaitDuration_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macAckWaitDuration;
	}
	
	// 0x41
	command void IeeePibAttribute.setMacAssociationPermit( Ieee_PibAttribute pibAttribute,
	                                                       bool macAssociationPermit )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibAssociationPermit_c;
		((bool*)att->pibAttributeValue)[0] = macAssociationPermit;
	}
	// 0x42
	command void IeeePibAttribute.setMacAutoRequest( Ieee_PibAttribute pibAttribute,
	                                                 bool macAutoRequest )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibAutoRequest_c;
		((bool*)att->pibAttributeValue)[0] = macAutoRequest;
	}
	// 0x43
	command void IeeePibAttribute.setMacBattLifeExt( Ieee_PibAttribute pibAttribute,
	                                                 bool macBattLifeExt )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBattLifeExt_c;
		((bool*)att->pibAttributeValue)[0] = macBattLifeExt;
	}
	// 0x44
	command void IeeePibAttribute.setMacBattLifeExtPeriods( Ieee_PibAttribute pibAttribute,
	                                                        uint8_t macBattLifeExtPeriods )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBattLifeExtPeriods_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macBattLifeExtPeriods;
	}
	// 0x45
	command void IeeePibAttribute.setMacBeaconPayload( Ieee_PibAttribute pibAttribute,
	                                                   Ieee_Msdu payload )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBeaconPayload_c;
		// What do we do about endianness here???
  		((char**)att->pibAttributeValue)[0] = payload->payload;
	}
	// 0x46
	command void IeeePibAttribute.setMacBeaconPayloadLength( Ieee_PibAttribute pibAttribute,
	                                                         Ieee_Msdu payload )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBeaconPayloadLength_c;
  		((uint16_t*)att->pibAttributeValue)[0] = NTOUH16(payload->payloadLen);
	}
	// 0x47
	command void IeeePibAttribute.setMacBeaconOrder( Ieee_PibAttribute pibAttribute,
	                                                 uint8_t macBeaconOrder )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBeaconOrder_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macBeaconOrder;
	}
	// 0x48
	command void IeeePibAttribute.setMacBeaconTxTime( Ieee_PibAttribute pibAttribute,
	                                                  uint32_t macBeaconTxTime )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBeaconTxTime_c;
  		((uint32_t*)att->pibAttributeValue)[0] = NTOUH32(macBeaconTxTime);
	}
	// 0x49
	command void IeeePibAttribute.setMacBsn( Ieee_PibAttribute pibAttribute,
	                                         uint8_t macBsn )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibBsn_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macBsn;
	}
	// 0x4A
	command void IeeePibAttribute.setMacCoordExtendedAddress( Ieee_PibAttribute pibAttribute,
	                                                          uint8_t *macCoordExtendedAddress )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibCoordExtendedAddress_c;
		NTOUHCPY64(macCoordExtendedAddress, att->pibAttributeValue);
	}
	// 0x4B
	command void IeeePibAttribute.setMacCoordShortAddress( Ieee_PibAttribute pibAttribute,
	                                                       uint16_t macCoordShortAddress )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibCoordShortAddress_c;
  		((uint16_t*)att->pibAttributeValue)[0] = NTOUH16(macCoordShortAddress);
	}
	// 0x4C
	command void IeeePibAttribute.setMacDsn( Ieee_PibAttribute pibAttribute,
	                                         uint8_t macDsn )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibDsn_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macDsn;
	}
	// 0x4D
	command void IeeePibAttribute.setMacGtsPermit( Ieee_PibAttribute pibAttribute,
	                                               bool macGtsPermit )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibGtsPermit_c;
  		((bool*)att->pibAttributeValue)[0] = macGtsPermit;
	}
	// 0x4E
	command void IeeePibAttribute.setMacMaxCsmaBackoffs( Ieee_PibAttribute pibAttribute,
	                                                     uint8_t macMaxCsmaBackoffs )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibMaxCsmaBackoffs_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macMaxCsmaBackoffs;
	}
	// 0x4F
	command void IeeePibAttribute.setMacMinBe( Ieee_PibAttribute pibAttribute,
	                                           uint8_t macMinBe )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibMinBe_c;
  		((uint8_t*)att->pibAttributeValue)[0] = macMinBe;
	}
	// 0x50
	command void IeeePibAttribute.setMacPanId( Ieee_PibAttribute pibAttribute,
	                                           uint16_t macPanId )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibPanId_c;
  		((uint16_t*)att->pibAttributeValue)[0] = NTOUH16(macPanId);
	}
	// 0x51
	command void IeeePibAttribute.setMacPromiscuousMode( Ieee_PibAttribute pibAttribute,
	                                                     bool macPromiscuousMode )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibPromiscuousMode_c;
  		((bool*)att->pibAttributeValue)[0] = macPromiscuousMode;
	}
	// 0x52
	command void IeeePibAttribute.setMacRxOnWhenIdle( Ieee_PibAttribute pibAttribute,
	                                                  bool macRxOnWhenIdle )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibRxOnWhenIdle_c;
  		((bool*)att->pibAttributeValue)[0] = macRxOnWhenIdle;
	}
	// 0x53
	command void IeeePibAttribute.setMacShortAddress( Ieee_PibAttribute pibAttribute,
	                                                  uint16_t macShortAddress )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibShortAddress_c;
		((uint16_t*)att->pibAttributeValue)[0] = NTOUH16(macShortAddress);
	}
	// 0x54
	command void IeeePibAttribute.setMacSuperframeOrder( Ieee_PibAttribute pibAttribute,
	                                                     uint8_t macSuperframeOrder )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibSuperFrameOrder_c;
		((uint8_t*)att->pibAttributeValue)[0] = macSuperframeOrder;
	}
	// 0x55
	command void IeeePibAttribute.setMacTransactionPersistenceTime( Ieee_PibAttribute pibAttribute,
	                                                                uint16_t macTransactionPersistenceTime )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibTransactionPersistenceTime_c;
		((uint16_t*)att->pibAttributeValue)[0] = NTOUH16(macTransactionPersistenceTime);
	}
	// 0x71
	command void IeeePibAttribute.setMacAclEntryDescriptorSetSize( Ieee_PibAttribute pibAttribute,
	                                                               uint8_t macAclEntryDescriptorSetSize )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibAclEntryDescriptorSetSize_c;
		((uint8_t*)att->pibAttributeValue)[0] = macAclEntryDescriptorSetSize;
	}
	// 0x72
	command void IeeePibAttribute.setMacDefaultSecurity( Ieee_PibAttribute pibAttribute,
	                                                     bool macDefaultSecurity )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibDefaultSecurity_c;
  		((bool*)att->pibAttributeValue)[0] = macDefaultSecurity;
	}
	// 0x73
	command void IeeePibAttribute.setMacDefaultSecurityMaterialLength( Ieee_PibAttribute pibAttribute,
	                                                                   uint8_t macDefaultSecurityMaterialLength )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibDefaultSecurityMaterialLength_c;
		((uint8_t*)att->pibAttributeValue)[0] = macDefaultSecurityMaterialLength;
	}
	// 0x74
	command void IeeePibAttribute.setMacDefaultSecurityMaterial( Ieee_PibAttribute pibAttribute,
	                                                             uint8_t* macDefaultSecurityMaterial )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibDefaultSecurityMaterial_c;
		((uint8_t**)att->pibAttributeValue)[0] = macDefaultSecurityMaterial;
	}
	// 0x75
	command void IeeePibAttribute.setMacDefaultSecuritySuite( Ieee_PibAttribute pibAttribute,
	                                                          uint8_t macDefaultSecuritySuite )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibDefaultSecuritySuite_c;
		((uint8_t*)att->pibAttributeValue)[0] = macDefaultSecuritySuite;
	}
	// 0x76
	command void IeeePibAttribute.setMacSecurityMode( Ieee_PibAttribute pibAttribute,
	                                                  uint8_t macSecurityMode )
	{
		fsPibAttribute_t* att = pibAttribute;
		att->pibAttribute = gMacPibSecurityMode_c;
		((uint8_t*)att->pibAttributeValue)[0] = macSecurityMode;
	}
	

	// MAC Sublayer PIB's
	// 0x40
	command uint8_t IeeePibAttribute.getMacAckWaitDuration( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x41
	command bool IeeePibAttribute.getMacAssociationPermit( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x42
	command bool IeeePibAttribute.getMacAutoRequest( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x43
	command bool IeeePibAttribute.getMacBattLifeExt( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x44
	command uint8_t IeeePibAttribute.getMacBattLifeExtPeriods( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x45
	command void IeeePibAttribute.getMacBeaconPayload( Ieee_PibAttribute pibAttribute,
	                                                   Ieee_Msdu payload )
	{
		fsPibAttribute_t* att = pibAttribute;
		payload->bufferDestroyable = FALSE;
		// Again, what about endianness??
		payload->payload = (char*)att->pibAttributeValue;
	}
	// 0x46
	command void IeeePibAttribute.getMacBeaconPayloadLength( Ieee_PibAttribute pibAttribute,
	                                                         Ieee_Msdu payload )
	{
		fsPibAttribute_t* att = pibAttribute;
		payload->payloadLen = *((uint16_t*)att->pibAttributeValue);
	}
	// 0x47
	command uint8_t IeeePibAttribute.getMacBeaconOrder( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x48
	command uint32_t IeeePibAttribute.getMacBeaconTxTime( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return NTOUH32(*((uint32_t*)att->pibAttributeValue));
	}
	// 0x49
	command uint8_t IeeePibAttribute.getMacBsn( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x4A
	command uint8_t *IeeePibAttribute.getMacCoordExtendedAddress( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return att->pibAttributeValue;
	}
	// 0x4B
	command uint16_t IeeePibAttribute.getMacCoordShortAddress( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return NTOUH16(*((uint16_t*)att->pibAttributeValue));
	}
	// 0x4C
	command uint8_t IeeePibAttribute.getMacDsn( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x4D
	command bool IeeePibAttribute.getMacGtsPermit( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x4E
	command uint8_t IeeePibAttribute.getMacMaxCsmaBackoffs( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x4F
	command uint8_t IeeePibAttribute.getMacMinBe( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x50
	command uint16_t IeeePibAttribute.getMacPanId( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return NTOUH16(*((uint16_t*)att->pibAttributeValue));
	}
	// 0x51
	command bool IeeePibAttribute.getMacPromiscuousMode( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x52
	command bool IeeePibAttribute.getMacRxOnWhenIdle( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x53
	command uint16_t IeeePibAttribute.getMacShortAddress( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return NTOUH16(*((uint16_t*)att->pibAttributeValue));
	}
	// 0x54
	command uint8_t IeeePibAttribute.getMacSuperframeOrder( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x55
	command uint16_t IeeePibAttribute.getMacTransactionPersistenceTime( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return NTOUH16(*((uint16_t*)att->pibAttributeValue));
	}
	// 0x70
	// use this command to edit acl descriptors as well
	command Ieee_AclDescriptor IeeePibAttribute.getMacAclEntryDescriptor( Ieee_PibAttribute pibAttribute, uint8_t index )
	{
		fsPibAttribute_t* att = pibAttribute;
		return (Ieee_AclDescriptor)att->pibAttributeValue;
	}
	// 0x71
	command uint8_t IeeePibAttribute.getMacAclEntryDescriptorSetSize( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x72
	command bool IeeePibAttribute.getMacDefaultSecurity( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((bool*)att->pibAttributeValue);
	}
	// 0x73
	command uint8_t IeeePibAttribute.getMacDefaultSecurityMaterialLength( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x74
	command uint8_t* IeeePibAttribute.getMacDefaultSecurityMaterial( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return (uint8_t*)att->pibAttributeValue;
	}
	// 0x75
	command uint8_t IeeePibAttribute.getMacDefaultSecuritySuite( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
	// 0x76
	command uint8_t IeeePibAttribute.getMacSecurityMode( Ieee_PibAttribute pibAttribute )
	{
		fsPibAttribute_t* att = pibAttribute;
		return *((uint8_t*)att->pibAttributeValue);
	}
}
