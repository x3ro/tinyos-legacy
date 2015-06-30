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

// The MAC constants are defined in here.
// Notice that these makes use of the PHY constants.

#ifndef _MACCONSTANTS_H_
#define _MACCONSTANTS_H_
// This should be inited by the device!
// Should be little endian!
uint8_t aExtendedAddress[8] = {0x00,0x00,0x00,0x00,0x37,0xC2,0x50,0x00};

#define aBaseSlotDuration          60
#define aBaseSuperframeDuration    aBaseSlotDuration*aNumSuperframeSlots
#define aMaxBE                     5
#define aMaxBeaconOverhead         75
#define aMaxBeaconPayloadLength    aMaxPHYPacketSize-aMaxBeaconOverhead
#define aGTSDescPersistenceTime    4
#define aMaxFrameOverhead          25
#define aMaxFrameResponseTime      1220
#define aMaxFrameRetries           3
#define aMaxLostBeacons            4
#define aMaxMACFrameSize           aMaxPHYPacketSize-aMaxFrameOverhead
#define aMaxSIFSFrameSize          18
#define aMinCAPLength              440
#define aMinLIFSPeriod             40
#define aMinSIFSPeriod             12
#define aNumSuperframeSlots        16
#define aResponseWaitTime          32*aBaseSuperframeDuration
#define aUnitBackoffPeriod         20

// Broadcast address defines.
#define aBcastPANId                0xFFFF
#define aBcastShortAddr            0xFFFF
#define aNoShortAddr               0xFEFF

// Frame type constants.
#define macBeaconFrame             0
#define macDataFrame               1
#define macAcknowledgementFrame    2
#define macCommandFrame            3

// MAC command frame type constants.
#define macCommandAssocReq         0x01
#define maccommandAssocResp        0x02
#define macCommandDisassocNot      0x03
#define macCommandDataReq          0x04
#define macCommandPanIdConf        0x05
#define macCommandOrphanNot        0x06
#define macCommandBeaconReq        0x07
#define macCommandCoordRealign     0x08
#define macCommandGtsReq           0x09

#endif
