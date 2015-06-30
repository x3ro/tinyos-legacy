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

// This file contains MAC frame specifications and macros.
#ifndef _MAC_FRAME_H_
#define _MAC_FRAME_H_
// MHR is at frame start. Nothing to be done.
#define mhrGetPtr(frame) frame

#define msduGetPtr(frame) ((uint8_t*)frame)+mhrLengthFrame(mhrGetPtr(frame))


// Length of the entire MHR using address mode.
#define mhrLength(dstAddrMode, srcAddrMode, intraPAN) mhrFrameControlLength + mhrSequenceNumberLength + mhrDstAddrModeLength(dstAddrMode) + mhrSrcAddrModeLength(srcAddrMode,intraPAN)
// Length of the entire MHR using frame pointer.
#define mhrLengthFrame(frame) mhrLength(mhrDestAddrMode(frame),mhrSrcAddrMode(frame),mhrIntraPAN(frame))


// Frame Control macros.
#define mhrFrameControlLength 2
#define mhrFrameControlOffset 0
typedef struct
{
	uint8_t FrameType       : 3;
	uint8_t SecurityEnabled : 1;
	uint8_t FramePending    : 1;
	uint8_t AckRequest      : 1;
	uint8_t IntraPAN        : 1;
	uint8_t Reserved1_2     : 1;
	
	uint8_t Reserved1_1     : 2;
	uint8_t DestAddrMode    : 2;
	uint8_t Reserved2       : 2;
	uint8_t SrcAddrMode     : 2;
} mhrFrameControl_t;

#define mhrGetFrameControlPtr(frame) ((mhrFrameControl_t*)((uint8_t*)mhrGetPtr(frame) + mhrFrameControlOffset))

#define mhrFrameType(frame)       mhrGetFrameControlPtr(frame)->FrameType
#define mhrSecurityEnabled(frame) mhrGetFrameControlPtr(frame)->SecurityEnabled
#define mhrFramePending(frame)    mhrGetFrameControlPtr(frame)->FramePending
#define mhrAckRequest(frame)      mhrGetFrameControlPtr(frame)->AckRequest
#define mhrIntraPAN(frame)        mhrGetFrameControlPtr(frame)->IntraPAN
#define mhrDestAddrMode(frame)    mhrGetFrameControlPtr(frame)->DestAddrMode
#define mhrSrcAddrMode(frame)     mhrGetFrameControlPtr(frame)->SrcAddrMode



// Sequence number macros.
#define mhrSequenceNumberLength 1
#define mhrSequenceNumberOffset mhrFrameControlOffset + mhrFrameControlLength

#define mhrSeqNumber(frame) (*((uint8_t*)mhrGetPtr(frame) + mhrSequenceNumberOffset))


// Address fields macros.
// This is ugly but fast. There are 9 ways to construct
// the addressing fields section of a frame. Luckily we
// only need structures for 8 of them and the macros makes
// it transparent to the users :-)

#define mhrAddressingOffset mhrSequenceNumberOffset + mhrSequenceNumberLength

// These small cryptic macros produces the number of
// addressing bits, given an addressing mode.
// We exploit, that 3 is the only odd mode. And that
// the other modes are equal to their address lengths.

#define mhrDstPANLength(mode)                (mode?2:0)
#define mhrSrcPANLength(mode, intraPAN)      ((!intraPAN&&mode)?2:0)
#define mhrAddrLength(mode)                  (((mode)&1)?8:(mode))
#define mhrDstAddrModeLength(mode)           mhrDstPANLength(mode) + mhrAddrLength(mode)
#define mhrSrcAddrModeLength(mode, intraPAN) mhrSrcPANLength(mode, intraPAN) + mhrAddrLength(mode)

// Macros for determining the lengths of the addressing parts,
// using a frame.
#define mhrDestPANIdLength(frame) mhrDstPANLength(mhrDestAddrMode(frame))
#define mhrDestAddrLength(frame)  (mhrAddrLength(mhrDestAddrMode(frame)))
#define mhrSrcPANIdLength(frame)  mhrSrcPANLength(mhrSrcAddrMode(frame), mhrIntraPAN(frame))
#define mhrSrcAddrLength(frame)   mhrAddrLength(mhrSrcAddrMode(frame))

// These macros are not safe. If the given addressing part is not
// present in the given frame, the macro will return a pointer anyway.
// Use the macros above to check, if the addressing part is present.
// All addresses will be uint8_t pointers.
#define mhrDestPANId(frame) (((uint8_t*)mhrGetPtr(frame)) + mhrAddressingOffset)
#define mhrDestAddr(frame)  (mhrDestPANId(frame) + mhrDestPANIdLength(frame))
#define mhrSrcPANId(frame)  (mhrDestAddr(frame) + mhrDestAddrLength(frame))
#define mhrSrcAddr(frame)   (mhrSrcPANId(frame) + mhrSrcPANIdLength(frame))



// Below here are the different types of MSDUs, and macros used to
// access them without all the fuzz.

// Beacon frame msdu

// Superframe specifier field.
#define msduSuperframeSpecLength 2
#define msduSuperframeOffset 0
typedef struct
{
	uint8_t BeaconOrder          :4;
	uint8_t SuperframeOrder      :4;
	
	uint8_t FinalCAPSlot         :4;
	uint8_t BatteryLifeExtension :1;
	uint8_t Reserved             :1;
	uint8_t PANCoordinator       :1;
	uint8_t AssociationPermit    :1;

} msduSuperframeSpec_t;

#define msduGetSuperframeSpecPtr(frame) ((uint8_t*)msduGetPtr(frame)+msduSuperframeOffset)
#define msduGetSuperframeSpec(frame)    ((msduSuperframeSpec_t*)msduGetSuperframeSpecPtr(frame))

#define msduBeaconOrder(frame)          msduGetSuperframeSpec(frame)->BeaconOrder
#define msduSuperframeOrder(frame)      msduGetSuperframeSpec(frame)->SuperframeOrder
#define msduFinalCAPSlot(frame)         msduGetSuperframeSpec(frame)->FinalCAPSlot
#define msduBatteryLifeExtension(frame) msduGetSuperframeSpec(frame)->BatteryLifeExtension
#define msduPANCoordinator(frame)       msduGetSuperframeSpec(frame)->PANCoordinator
#define msduAssociationPermit(frame)    msduGetSuperframeSpec(frame)->AssociationPermit

// GTS specifier field
#define msduGTSSpecLength 1
#define msduGTSSpecOffset msduSuperframeOffset + msduSuperframeSpecLength
typedef struct
{
	uint8_t GTSDescriptorCount :3;
	uint8_t Reserved           :4;
	uint8_t GTSPermit          :1;
} msduGTSSpec_t;

#define msduGetGTSSpec(frame)         ((msduGTSSpec_t*)((uint8_t*)msduGetPtr(frame)+msduGTSSpecOffset))

#define msduGTSDescriptorCount(frame) msduGetGTSSpec(frame)->GTSDescriptorCount
#define msduGTSPermit(frame)          msduGetGTSSpec(frame)->GTSPermit

// GTS directions field
#define msduGTSDirectionsLength(frame) (msduGTSDescriptorCount(frame)?1:0)
#define msduGTSDirectionsOffset msduGTSSpecOffset + msduGTSSpecLength
typedef struct
{
	uint8_t GTSDirectionMask :7;
	uint8_t Reserved         :1;
} msduGTSDirections_t;

#define msduGetGTSDirections(frame) ((msduGTSDirections_t*)((uint8_t*)msduGetPtr(frame)+msduGTSDirectionsOffset))

#define msduGTSDirectionMask(frame) msduGetGTSDirections(frame)->GTSDirectionMask

// GTS list field
#define msduGTSListLength(frame) msduGTSDescriptorCount(frame)*3
#define msduGTSListOffset(frame) msduGTSDirectionsOffset + msduGTSDirectionsLength(frame)
typedef struct
{
	uint16_t DeviceShortAddress :16;
	uint8_t GTSStartingSlot     :4;
	uint8_t GTSLength           :4;
} msduGTSList_t;

#define msduGTSList(frame) ((msduGTSList_t*)((uint8_t*)msduGetPtr(frame)+msduGTSListOffset(frame)))

// Pending adresses
#define msduPendingAddrSpecLength(frame) 1
#define msduPendingAddrSpecOffset(frame) msduGTSListOffset(frame)+msduGTSListLength(frame)
typedef struct
{
	uint8_t NumShortAddrsPending :3;
	uint8_t Reserved1            :1;
	uint8_t NumExtAddrsPending   :3;
	uint8_t Reserved2            :1;
} msduPendingAddrSpec_t;

#define msduPendingAddrSpec(frame) ((msduPendingAddrSpec_t*)((uint8_t*)msduGetPtr(frame)+msduPendingAddrSpecOffset(frame)))

#define msduNumShortAddrsPending(frame) msduPendingAddrSpec(frame)->NumShortAddrsPending
#define msduNumExtAddrsPending(frame)   msduPendingAddrSpec(frame)->NumExtAddrsPending

#define msduPendingAddrList(frame) ((uint8_t*)msduPendingAddrSpec(frame)+1)
#define msduBeaconPayload(frame)   (msduPendingAddrList(frame)+2*msduNumShortAddrsPending(frame)+8*msduNumExtAddrsPending(frame))

// MAC command frames
#define msduCommandFrameIdentLength 1
#define msduCommandFrameIdentOffset 0
#define msduCommandFrameIdent(frame) (*((uint8_t*)msduGetPtr(frame)))

// Association request
#define msduAssocRequestLength 1
#define msduAssocRequestOffset msduCommandFrameIdentOffset+msduCommandFrameIdentLength
typedef struct
{
	uint8_t AltPANCoordinator  :1;
	uint8_t DeviceType         :1;
	uint8_t PowerSource        :1;
	uint8_t RecvOnWhenIdle     :1;
	uint8_t Reserved           :2;
	uint8_t SecurityCapability :1;
	uint8_t AllocateAddress    :1;
} msduAssocCapabilityInfo_t;

#define msduAssocCapabilityInfo(frame) ((msduAssocCapabilityInfo_t*)((uint8_t*)msduGetPtr(frame)+msduAssocRequestOffset))

#define msduAltPANCoordinator(frame)  msduAssocCapabilityInfo(frame)->AltPANCoordinator
#define msduDeviceType(frame)         msduAssocCapabilityInfo(frame)->DeviceType
#define msduPowerSource(frame)        msduAssocCapabilityInfo(frame)->PowerSource
#define msduRecvOnWhenIdle(frame)     msduAssocCapabilityInfo(frame)->RecvOnWhenIdle
#define msduSecurityCapability(frame) msduAssocCapabilityInfo(frame)->SecurityCapability
#define msduAllocateAddress(frame)    msduAssocCapabilityInfo(frame)->AllocateAddress

// Association response
#define msduAssocResponseShortAddrLength 2
#define msduAssocResponseShortAddrOffset msduCommandFrameIdentOffset+msduCommandFrameIdentLength
#define msduAssocResponseShortAddr(frame) ((uint8_t*)msduGetPtr(frame)+msduAssocResponseShortAddrOffset)

#define msduAssocResponseStatusOffset msduAssocResponseShortAddrOffset+msduAssocResponseShortAddrLength
#define msduAssocResponseStatus(frame) (*((uint8_t*)msduGetPtr(frame)+msduAssocResponseStatusOffset))

// Disassociation notification
#define msduDisassocReasonLength 1
#define msduDisassocReasonOffset msduCommandFrameIdentOffset+msduCommandFrameIdentLength
#define msduDisassocReason(frame) (*((uint8_t*)msduGetPtr(frame)+msduDisassocReasonOffset))

// Coordinator realignment
#define msduCoordRealignPANIdLength  2
#define msduCoordRealignPANIdOffset  msduCommandFrameIdentOffset+msduCommandFrameIdentLength
#define msduCoordRealignPANId(frame) ((uint8_t*)msduGetPtr(frame)+msduCoordRealignPANIdOffset)

#define msduCoordRealignCoordShortAddrLength  2
#define msduCoordRealignCoordShortAddrOffset  msduCoordRealignPANIdOffset+msduCoordRealignPANIdLength
#define msduCoordRealignCoordShortAddr(frame) ((uint8_t*)msduGetPtr(frame)+msduCoordRealignCoordShortAddrOffset)

#define msduCoordRealignLogicalChannelLength  1
#define msduCoordRealignLogicalChannelOffset  msduCoordRealignCoordShortAddrOffset+msduCoordRealignCoordShortAddrLength
#define msduCoordRealignLogicalChannel(frame) (*((uint8_t*)msduGetPtr(frame)+msduCoordRealignLogicalChannelOffset))

#define msduCoordRealignShortAddrLength  2
#define msduCoordRealignShortAddrOffset  msduCoordRealignLogicalChannelOffset+msduCoordRealignLogicalChannelLength
#define msduCoordRealignShortAddr(frame) ((uint8_t*)msduGetPtr(frame)+msduCoordRealignShortAddrOffset)

// GTS Request
typedef struct
{
	uint8_t GTSLength      :4;
	uint8_t GTSDirection   :1;
	uint8_t CharType       :1;
	uint8_t Reserved       :2;
} msduGtsCharacteristics_t;

#define msduGtsRequestGtsCharacteristicsLength  1
#define msduGtsRequestGtsCharacteristicsOffset  msduCommandFrameIdentOffset+msduCommandFrameIdentLength
#define msduGtsRequestGtsCharacteristics(frame) ((msduGtsCharacteristics_t*)((uint8_t*)msduGetPtr(frame)+msduGtsRequestGtsCharacteristicsOffset))
//#define msduGtsRequestGtsCharacteristics(frame) ((uint8_t*)msduGetPtr(frame)+msduGtsRequestGtsCharacteristicsOffset)

#endif
