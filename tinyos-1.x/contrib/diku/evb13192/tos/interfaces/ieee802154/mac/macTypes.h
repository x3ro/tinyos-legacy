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

#ifndef _802154_TYPES_H_
#define _802154_TYPES_H_

/*typedef enum 
{
	IEEE802154_SUCCESS = 0x00,
	IEEE802154_PAN_AT_CAP = 0x01,
	IEEE802154_PAN_ACCESS_DENIED = 0x02,
	IEEE802154_PAN_COORD_LEAVE = 0x01,
	IEEE802154_PAN_DEVICE_LEAVE = 0x02,
	IEEE802154_BEACON_LOSS = 0xE0,
	IEEE802154_CHANNEL_ACCESS_FAILURE = 0xE1,
	IEEE802154_DENIED = 0xE2,
	IEEE802154_DISABLE_TRX_FAILURE = 0xE3,
	IEEE802154_FAILED_SECURITY_CHECK = 0xE4,
	IEEE802154_FRAME_TOO_LONG = 0xE5,
	IEEE802154_INVALID_GTS = 0xE6,
	IEEE802154_INVALID_HANDLE = 0xE7,
	IEEE802154_INVALID_PARAMETER = 0xE8,
	IEEE802154_NO_ACK = 0xE9,
	IEEE802154_NO_BEACON = 0xEA,
	IEEE802154_NO_DATA = 0xEB,
	IEEE802154_NO_SHORT_ADDRESS = 0xEC,
	IEEE802154_OUT_OF_CAP = 0xED,
	IEEE802154_PAN_ID_CONFLICT = 0xEE,
	IEEE802154_REALIGNMENT = 0xEF,
	IEEE802154_TRANSACTION_EXPIRED = 0xF0,
	IEEE802154_TRANSACTION_OVERFLOW = 0xF1,
	IEEE802154_TX_ACTIVE = 0xF2,
	IEEE802154_UNAVAILABLE_KEY = 0xF3,
	IEEE802154_UNSUPPORTED_ATTRIBUTE = 0xF4
} Ieee_Status;*/

#define IEEE802154_SUCCESS                      0x00
#define IEEE802154_PAN_AT_CAP                   0x01
#define IEEE802154_PAN_ACCESS_DENIED            0x02
#define IEEE802154_PAN_COORD_LEAVE              0x01
#define IEEE802154_PAN_DEVICE_LEAVE             0x02
#define IEEE802154_BEACON_LOSS                  0xE0
#define IEEE802154_CHANNEL_ACCESS_FAILURE       0xE1
#define IEEE802154_DENIED                       0xE2
#define IEEE802154_DISABLE_TRX_FAILURE          0xE3
#define IEEE802154_FAILED_SECURITY_CHECK        0xE4
#define IEEE802154_FRAME_TOO_LONG               0xE5
#define IEEE802154_INVALID_GTS                  0xE6
#define IEEE802154_INVALID_HANDLE               0xE7
#define IEEE802154_INVALID_PARAMETER            0xE8
#define IEEE802154_NO_ACK                       0xE9
#define IEEE802154_NO_BEACON                    0xEA
#define IEEE802154_NO_DATA                      0xEB
#define IEEE802154_NO_SHORT_ADDRESS             0xEC
#define IEEE802154_OUT_OF_CAP                   0xED
#define IEEE802154_PAN_ID_CONFLICT              0xEE
#define IEEE802154_REALIGNMENT                  0xEF
#define IEEE802154_TRANSACTION_EXPIRED          0xF0
#define IEEE802154_TRANSACTION_OVERFLOW         0xF1
#define IEEE802154_TX_ACTIVE                    0xF2
#define IEEE802154_UNAVAILABLE_KEY              0xF3
#define IEEE802154_UNSUPPORTED_ATTRIBUTE        0xF4

typedef uint8_t Ieee_Status;

// Scan types.
#define IEEE802154_EDScan                       0x00
#define IEEE802154_ActiveScan                   0x01
#define IEEE802154_PassiveScan                  0x02
#define IEEE802154_OrphanScan                   0x03

// Capability information fields.
#define IEEE802154_CapInfoAltPANCoord           0x01
#define IEEE802154_CapInfoDevType               0x02
#define IEEE802154_CapInfoPowerSrc              0x04
#define IEEE802154_CapInfoRecvOnIdle            0x08
#define IEEE802154_CapInfoSecCap                0x40
#define IEEE802154_CapInfoAllocAddr             0x80

// Tx options fields.
#define IEEE802154_TxOptsAck                    0x01
#define IEEE802154_TxOptsGtsTx                  0x02
#define IEEE802154_TxOptsIndirectTx             0x04
#define IEEE802154_TxOptsSecEnTx                0x08

// MAC Sublayer PIB
#define IEEE802154_macAckWaitDuration           0x40
#define IEEE802154_macAssociationPermit         0x41
#define IEEE802154_macAutoRequest               0x42
#define IEEE802154_macBattLifeExt               0x43
#define IEEE802154_macBattLifeExtPeriods        0x44
#define IEEE802154_macBeaconPayload             0x45
#define IEEE802154_macBeaconPayloadLength       0x46
#define IEEE802154_macBeaconOrder               0x47
#define IEEE802154_macBeaconTxTime              0x48
#define IEEE802154_macBSN                       0x49
#define IEEE802154_macCoordExtendedAddress      0x4A
#define IEEE802154_macCoordShortAddress         0x4B
#define IEEE802154_macDSN                       0x4C
#define IEEE802154_macGTSPermit                 0x4D
#define IEEE802154_macMaxCSMABackoffs           0x4E
#define IEEE802154_macMinBE                     0x4F
#define IEEE802154_macPANId                     0x50
#define IEEE802154_macPromiscuousMode           0x51
#define IEEE802154_macRxOnWhenIdle              0x52
#define IEEE802154_macShortAddress              0x53
#define IEEE802154_macSuperframeOrder           0x54
#define IEEE802154_macTransactionPersistenceTime 0x55

// MAC PIB Security Attributes
#define IEEE802154_macACLEntryDescriptorSet     0x70
#define IEEE802154_macACLEntryDescriptorSetSize 0x71
#define IEEE802154_macDefaultSecurity           0x72
#define IEEE802154_macDefaultSecurityMaterialLength 0x73
#define IEEE802154_macDefaultSecurityMaterial   0x74
#define IEEE802154_macDefaultSecuritySuite      0x75
#define IEEE802154_macSecurityMode              0x76

#endif
