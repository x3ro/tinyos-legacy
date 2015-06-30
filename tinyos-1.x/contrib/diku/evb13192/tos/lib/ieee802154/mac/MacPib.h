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

#ifndef _MACPIB_H_
#define _MACPIB_H_
	#include <Ieee802154Adts.h>
	#include <MacConst.h>

	// Everything radio frame related in here is in little endian format.
	// This is done to avoid converting endianness more than necessary.
	// LITTLE ENDIAN
	uint8_t macCoordExtendedAddress[8] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
	uint16_t macCoordShortAddress;
	uint16_t macPanId;
	uint16_t macShortAddress;
	
	// ARCHITECTURE ENDIANNESS
	uint8_t macAckWaitDuration;
	bool macAssociationPermit;
	bool macAutoRequest;
	bool macBattLifeExt;
	uint8_t macBattLifeExtPeriods;
	uint8_t macBeaconPayload[aMaxBeaconPayloadLength];
	uint8_t macBeaconPayloadLength;
	uint8_t macBeaconOrder;
	uint32_t macBeaconTxTime;
	uint8_t macBsn;
	uint8_t macDsn;
	bool macGtsPermit;
	uint8_t macMaxCSMABackoffs;
	uint8_t macMinBE;
	bool macPromiscuousMode;
	bool macRxOnWhenIdle;
	uint8_t macSuperframeOrder;
	uint16_t macTransactionPersistenceTime;
	
	// Implementation specific attributes
	bool macPanCoordinator;
	bool macCoordinator;
	bool macBeaconEnabled;
	
	// Security attributes.
	ieeeAclEntry macAclEntryDescriptorSet[aAclEntryDescriptorSetMaxSize];
	uint8_t macAclEntryDescriptorSetSize;
	bool macDefaultSecurity;
	uint8_t macDefaultSecurityMaterialLength;
	uint8_t macDefaultSecurityMaterial[26];
	uint8_t macDefaultSecuritySuite;
	uint8_t macSecurityMode;
	
	// Symbol rate for current channel (us/symbol)
	uint8_t macInvSymbolRate;
	uint8_t macSymbolsPerByte;
#endif
