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

module MacPibDatabaseM
{
	provides
	{
		interface StdControl;
		interface PibDatabase;
	}
	uses
	{
		interface CapRx as PibChange;
		interface Random;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	void reset()
	{
		call Random.init();
		// Everything radio frame related in here is in little endian format.
		macAckWaitDuration = 54;
		macAssociationPermit = FALSE;
		macAutoRequest = TRUE;
		macBattLifeExt = FALSE;
		macBattLifeExtPeriods = 6;
		macBeaconPayloadLength = 0;
		macBeaconOrder = 15;
		macBeaconTxTime = 0;
		macBsn = call Random.rand();
		macCoordShortAddress = 0xffff;
		macDsn = call Random.rand();
		macGtsPermit = TRUE;
		macMaxCSMABackoffs = 4;
		macMinBE = 3;
		macPanId = 0xffff;
		macPromiscuousMode = FALSE;
		macRxOnWhenIdle = FALSE;
		macShortAddress = 0xffff;
		macSuperframeOrder = 15;
		macTransactionPersistenceTime = 0x01f4;
	
		// Implementation specific attributes
		macPanCoordinator = FALSE;
		macCoordinator = FALSE;
		macBeaconEnabled = FALSE;
	
		// Security attributes.
		macAclEntryDescriptorSetSize = 0;
		macDefaultSecurity = FALSE;
		macDefaultSecurityMaterialLength = 15;
		macDefaultSecuritySuite = 0;
		macSecurityMode = 0;
	}
	
	command result_t StdControl.init()
	{
		reset();
		return SUCCESS;
	}
	
	command result_t StdControl.start() {
		return SUCCESS;
	}
	
	command result_t StdControl.stop() {
		return SUCCESS;
	}

	command void PibDatabase.reset()
	{
		reset();
	}

	command bool PibDatabase.isPanCoordinator(Ieee_Address coordAddr)
	{
		if (coordAddr->panId != macPanId) {
			return FALSE;
		}
		if (coordAddr->mode == 2) {
			if ((uint16_t)*(coordAddr->address) == macCoordShortAddress) {
				return TRUE;
			}
		} else {
			uint8_t i;
			for (i=0;i<8;i++) {
				if (coordAddr->address[i] != macCoordExtendedAddress[i]) {
					return FALSE;
				}
			}
			return TRUE;
		}
		return FALSE;
	}

	// This function is mainly for use by the mlme_get functionality.
	// It assumes 8 or more bytes in target buffer.
	command Ieee_Status PibDatabase.get(uint8_t *target, uint8_t identifier)
	{
		// Using if instead of switch, because of the crappy Metrowerks compiler!!
		// Might want to change this for other architectures.
		if (identifier == IEEE802154_macAckWaitDuration) {
			*((uint8_t*)target) = macAckWaitDuration;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macAssociationPermit) {
			*((bool*)target) = macAssociationPermit;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macAutoRequest) {
			*((bool*)target) = macAutoRequest;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBattLifeExt) {
			*((bool*)target) = macBattLifeExt;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBattLifeExtPeriods) {
			*((bool*)target) = macBattLifeExtPeriods;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBeaconPayload) {
			target = macBeaconPayload;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBeaconPayloadLength) {
			*((uint8_t*)target) = macBeaconPayloadLength;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBeaconOrder) {
			*((uint8_t*)target) = macBeaconOrder;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBeaconTxTime) {
			*((uint32_t*)target) = macBeaconTxTime;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBSN) {
			*((uint8_t*)target) = macBsn;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macCoordExtendedAddress) {
			// This attribute is stored in little endian!
			NTOUH64(macCoordExtendedAddress, target);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macCoordShortAddress) {
			// This attribute is stored in little endian!
			NTOUH16((uint8_t*)&macCoordShortAddress, target);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDSN) {
			*((uint8_t*)target) = macDsn;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macGTSPermit) {
			*((bool*)target) = macGtsPermit;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macMaxCSMABackoffs) {
			*((uint8_t*)target) = macMaxCSMABackoffs;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macMinBE) {
			*((uint8_t*)target) = macMinBE;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macPANId) {
			// This attribute is stored in little endian!
			NTOUH16((uint8_t*)&macPanId, target);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macPromiscuousMode) {
			*((bool*)target) = macPromiscuousMode;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macRxOnWhenIdle) {
			*((bool*)target) = macRxOnWhenIdle;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macShortAddress) {
			// This attribute is stored in little endian!
			NTOUH16((uint8_t*)&macShortAddress, target);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macSuperframeOrder) {
			*((uint8_t*)target) = macSuperframeOrder;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macTransactionPersistenceTime) {
			*((uint16_t*)target) = macTransactionPersistenceTime;
			return IEEE802154_SUCCESS;
		}
		// Security attributes.
		if (identifier == IEEE802154_macACLEntryDescriptorSet) {
			target = (uint8_t*)macAclEntryDescriptorSet;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macACLEntryDescriptorSetSize) {
			*((uint8_t*)target) = macAclEntryDescriptorSetSize;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecurity) {
			*((bool*)target) = macDefaultSecurity;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecurityMaterialLength) {
			*((uint8_t*)target) = macDefaultSecurityMaterialLength;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecurityMaterial) {
			target = macDefaultSecurityMaterial;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecuritySuite) {
			*((uint8_t*)target) = macDefaultSecuritySuite;
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macSecurityMode) {
			*((uint8_t*)target) = macSecurityMode;
			return IEEE802154_SUCCESS;
		}
		return IEEE802154_UNSUPPORTED_ATTRIBUTE;
	}
	
	command Ieee_Status PibDatabase.set(uint8_t *source, uint8_t identifier)
	{
		// Using if instead of switch, because of the crappy Metrowerks compiler!!
		// Might want to change this for other architectures.
		if (identifier == IEEE802154_macAckWaitDuration) {
			uint8_t value = *((uint8_t*)source);
			if (value == 54 || value == 120) {
				macAckWaitDuration = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macAssociationPermit) {
			macAssociationPermit = *((bool*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macAutoRequest) {
			macAutoRequest = *((bool*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBattLifeExt) {
			macBattLifeExt = *((bool*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBattLifeExtPeriods) {
			uint8_t value = *((uint8_t*)source);
			if (value == 6 || value == 8) {
				macBattLifeExtPeriods = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macBeaconPayload) {
			memcpy(macBeaconPayload, source, macBeaconPayloadLength);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macBeaconPayloadLength) {
			uint8_t value = *((uint8_t*)source);
			if (value <= aMaxBeaconPayloadLength) {
				macBeaconPayloadLength = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macBeaconOrder) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 15) {
				macBeaconOrder = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macBeaconTxTime) {
			uint32_t value = *((uint32_t*)source);
			if (value <= 0xFFFFFF) {
				macBeaconTxTime = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macBSN) {
			macBsn = *((uint8_t*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macCoordExtendedAddress) {
			NTOUH64(source, macCoordExtendedAddress);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macCoordShortAddress) {
			NTOUH16(source, (uint8_t*)&macCoordShortAddress);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDSN) {
			macDsn = *((uint8_t*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macGTSPermit) {
			macGtsPermit = *((bool*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macMaxCSMABackoffs) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 5) {
				macMaxCSMABackoffs = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macMinBE) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 3) {
				macMinBE = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macPANId) {
			NTOUH16(source, (uint8_t*)&macPanId);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macPromiscuousMode) {
			macPromiscuousMode = *((bool*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macRxOnWhenIdle) {
			macRxOnWhenIdle = *((bool*)source);
			if (macRxOnWhenIdle) {
				call PibChange.rxOn();
			} else {
				call PibChange.rxOff();
			}
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macShortAddress) {
			NTOUH16(source, (uint8_t*)&macShortAddress);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macSuperframeOrder) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 15) {
				macSuperframeOrder = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macTransactionPersistenceTime) {
			macTransactionPersistenceTime = *((uint16_t*)source);
			return IEEE802154_SUCCESS;
		}
		// Security attributes.
		if (identifier == IEEE802154_macACLEntryDescriptorSet) {
			memcpy((uint8_t*)macAclEntryDescriptorSet, source, macAclEntryDescriptorSetSize);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macACLEntryDescriptorSetSize) {
			macAclEntryDescriptorSetSize = *((uint8_t*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecurity) {
			macDefaultSecurity = *((bool*)source);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecurityMaterialLength) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 0x1A) {
				macDefaultSecurityMaterialLength = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macDefaultSecurityMaterial) {
			memcpy(macDefaultSecurityMaterial, source, macDefaultSecurityMaterialLength);
			return IEEE802154_SUCCESS;
		}
		if (identifier == IEEE802154_macDefaultSecuritySuite) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 7) {
				macDefaultSecuritySuite = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		if (identifier == IEEE802154_macSecurityMode) {
			uint8_t value = *((uint8_t*)source);
			if (value <= 2) {
				macSecurityMode = value;
				return IEEE802154_SUCCESS;
			}
			return IEEE802154_INVALID_PARAMETER;
		}
		return IEEE802154_UNSUPPORTED_ATTRIBUTE;
	}
}
