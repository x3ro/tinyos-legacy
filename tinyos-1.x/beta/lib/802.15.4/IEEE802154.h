// $Id: IEEE802154.h,v 1.3 2004/03/09 01:10:33 jpolastre Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:	        Joe Polastre
 *
 */

/**
 * @author Joe Polastre
 */

#ifndef _IEEE802154_H
#define _IEEE802154_H

/****************************************************
 * IEEE 802.15.4 Enumerations
 */

// MCPS enumerations

// DATA.confirm
typedef enum { ASUCCESS = 0x00,
               PAN_AT_CAP = 0x01,
               PAN_ACCESS_DENIED = 0x02,
               PAN_COORD_LEAVE = 0x01,
               PAN_DEVICE_LEAVE = 0x02,
               BEACON_LOSS = 0xE0,
               CHANNEL_ACCESS_FAILURE = 0xE1,
               DENIED = 0xE2,
               DISABLE_TRX_FAILURE = 0xE3,
               FAILED_SECURITY_CHECK = 0xE4,
               FRAME_TOO_LONG = 0xE5,
               INVALID_GTS = 0xE6,
               INVALID_HANDLE = 0xE7,
               INVALID_PARAMETER = 0xE8,
               NO_ACK = 0xE9,
               NO_BEACON = 0xEA,
               NO_DATA = 0xEB,
               NO_SHORT_ADDRESS = 0xEC,
               OUT_OF_CAP = 0xED,
               PAN_ID_CONFLICT = 0xEE,
               REALIGNMENT = 0xEF,
               TRANSACTION_EXPIRED = 0xF0,
               TRANSACTION_OVERFLOW = 0xF1,
               TX_ACTIVE = 0xF2,
               UNAVAILABLE_KEY = 0xF3,
               UNSUPPORTED_ATTRIBUTE = 0xF4
             } IEEE_status;

typedef enum { ASSOCIATION_REQUEST = 0x01,
               ASSOCIATION_RESPONSE = 0x02,
               DISASSOCIATION_NOTIFICATION = 0x03,
               DATA_REQUEST = 0x04,
               PAN_ID_CONFLICT_NOTIFICATION = 0x05,
               ORPHAN_NOTIFICATION = 0x06,
               BEACON_REQUEST = 0x07,
               COORDINATOR_REALIGNMENT = 0x08,
               GTS_REQUEST = 0x09
             } IEEE_MAC_COMMAND_FRAME;

typedef struct PANDescriptor_t {
  uint8_t CoordAddrMode;
  uint16_t CoordPANId;
  uint8_t* CoordAddress;
  uint8_t LogicalChannel;
  uint8_t SuperframeSpec;
  bool GTSPermit;
  uint8_t LinkQuality;
  uint32_t TimeStamp;
  bool SecurityUse;
  uint8_t ACLEntry;
  bool SecurityFailure;
} PANDescriptor_t;

/**************************************************** 
 * IEEE 802.15.4 Attribute Structures (PIB)
 */
// MAC ACL Descriptor Set
typedef struct IEEE802154_ACL_Descriptor_Set_t {
  uint64_t ACLExtendedAddress;
  uint16_t ACLShortAddress;
  uint16_t ACLPANId;
  uint8_t ACLSecurityMaterialLength;
  uint8_t* ACLSecurityMaterial;
  uint8_t ACLSecuritySuite;
} IEEE802154_ACL_Descriptor_Set_t;

// PHY and MAC PIB elements
typedef struct IEEE802154_PIB_t {
  // PHY Sublayer PIB
  // 0x00
  uint8_t phyCurrentChannel;
  // 0x01
  uint32_t phyChannelsSupported;
  // 0x02
  uint8_t phyTransmitPower;
  // 0x03
  uint8_t phyCCAMode;

  // MAC Sublayer PIB
  // 0x40
  uint8_t macAckWaitDuration;
  // 0x41
  bool macAssociationPermit;
  // 0x42
  bool macAutoRequest;
  // 0x43
  bool macBattLifeExt;
  // 0x44
  uint8_t macBattLifeExtPeriods;
  // 0x45
  uint8_t* macBeaconPayload;
  // 0x46
  uint16_t macBeaconPayloadLength;
  // 0x47
  uint8_t macBeaconOrder;
  // 0x48
  uint32_t macBeaconTxTime;
  // 0x49
  uint8_t macBSN;
  // 0x4A
  uint64_t macCoordExtendedAddress;
  // 0x4B
  uint16_t macCoordShortAddress;
  // 0x4C
  uint8_t macDSN;
  // 0x4D
  bool macGTSPermit;
  // 0x4E
  uint8_t macMaxCSMABackoffs;
  // 0x4F
  uint8_t macMinBE;
  // 0x50
  uint16_t macPANId;
  // 0x51
  bool macPromiscuousMode;
  // 0x52
  bool macRxOnWhenIdle;
  // 0x53
  uint16_t macShortAddress;
  // 0x54
  uint8_t macSuperframeOrder;
  // 0x55
  uint16_t macTransactionPersistenceTime;

  // MAC PIB Security Attributes
  // 0x70
  IEEE802154_ACL_Descriptor_Set_t* macACLEntryDescriptorSet;
  // 0x71
  uint8_t macACLEntryDescriptorSetSize;
  // 0x72
  bool macDefaultSecurity;
  // 0x73
  uint8_t macDefaultSecurityMaterialLength;
  // 0x74
  uint8_t* macDefaultSecurityMaterial;
  // 0x75
  uint8_t macDefaultSecuritySuite;
  // 0x76
  uint8_t macSecurityMode;
} IEEE802154_PIB_t;

/**************************************************** 
 * #defines for attribute identifiers
 */
// PHY Sublayer PIB
#define IEEE802154_phyCurrentChannel            0x00
#define IEEE802154_phyChannelsSupported         0x01
#define IEEE802154_phyTransmitPower             0x02
#define IEEE802154_phyCCAMode                   0x03

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

/**************************************************** 
 * #defines for PHY sublayer constants
 */
#define IEEE802154_aMaxPHYPacketSize            127
#define IEEE802154_aTurnaroundTime              12

/**************************************************** 
 * #defines for MAC sublayer constants
 */
#define IEEE802154_aBaseSlotDuration            60
#define IEEE802154_aNumSuperframeSlots          16
#define IEEE802154_aBaseSuperframeDuration      IEEE802154_aBaseSlotDuration * IEEE802154_aNumSuperframeSlots
#define IEEE802154_aExtendedAddress
#define IEEE802154_aMaxBE                       5
#define IEEE802154_aMaxBeaconOverhead           75
#define IEEE802154_aMaxBeaconPayloadLength      IEEE802154_aMaxPHYPacketSize - IEEE802154_aMaxBeaconOverhead
#define IEEE802154_aGTSDescPersistenceTime      4
#define IEEE802154_aMaxFrameOverhead            25
#define IEEE802154_aMaxFrameResponseTime        1220
#define IEEE802154_aMaxFrameRetries             3
#define IEEE802154_aMaxLostBeacons              4
#define IEEE802154_aMaxMACFrameSize             IEEE802154_aMaxPHYPacketSize - aMaxFrameOverhead
#define IEEE802154_aMaxSIFSFrameSize            18
#define IEEE802154_aMinCAPLength                440
#define IEEE802154_aMinLIFSPeriod               40
#define IEEE802154_aMinSIFSPeriod               12
#define IEEE802154_aResponseWaitTime            32 * IEEE802154_aBaseSuperframeDuration
#define IEEE802154_aUnitBackoffPeriod           20

#endif /* _IEEE802154_H */
