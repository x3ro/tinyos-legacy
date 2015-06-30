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

#ifndef _IEEE802154ADTS_H_
#define _IEEE802154ADTS_H_

#include <macTypes.h>

typedef struct {
	uint8_t extendedAddress[8];
	uint16_t shortAddress;
	uint16_t panId;
	uint8_t securityMaterialLength;
	uint8_t securityMaterial[26];
	uint8_t securitySuite;
} ieeeAclEntry;

typedef struct {
	uint8_t mode;
	uint16_t panId;
	uint8_t address[8];
} ieeeAddress_t;

typedef struct {
	bool destroyable;
	uint8_t size;
	uint8_t attribute;
	uint8_t value[1]; // this structure should be large enough for the largest pib
} ieeePibAttribute_t;

// The msdu consists of a pointer to the actual payload, 
// and a pointer to the buffer containing it, possibly a MAC frame.
typedef struct {
	uint8_t payloadLen;
	uint8_t *payload; // payload starts here
	uint8_t bufferLen;
	uint8_t *buffer;
	bool bufferDestroyable;
} msdu_t;

typedef struct {
	uint8_t coordAddrMode;
	uint16_t coordPanId;
	uint8_t coordAddress[8];
	uint8_t logicalChannel;
	uint16_t superFrameSpec;
	bool gtsPermit;
	uint8_t linkQuality;
	uint32_t timeStamp;
	bool securityUse;
	uint8_t ACLEntry;
	bool securityFailure;
} panDescriptor_t;


/**********************/
/*       MCPS         */
/**********************/

// message primitives
typedef struct {
	uint8_t msduHandle;
	uint8_t txOptions;
	uint8_t *dataFrame;
	uint8_t dataFrameLen;
} mcpsDataRequestMsg_t;

typedef struct {
	uint8_t msduHandle;
	Ieee_Status status;
} mcpsDataConfirmMsg_t;

typedef struct {
	uint8_t msduHandle;
} mcpsPurgeRequestMsg_t;

typedef struct {
	uint8_t msduHandle;
	Ieee_Status status;
} mcpsPurgeConfirmMsg_t;

typedef struct {
	uint8_t *dataFrame;
	uint8_t dataFrameLen;
	uint8_t mpduLinkQuality;
	uint8_t ACLEntry;
} mcpsDataIndicationMsg_t;

// Combined message primitives.
typedef struct {
	uint8_t type;
	union {
		mcpsDataRequestMsg_t request;
		mcpsDataConfirmMsg_t confirm;
	} msg;
} mcpsDataRequestConfirm_t;

typedef struct {
	uint8_t type;
	union {
		mcpsPurgeRequestMsg_t request;
		mcpsPurgeConfirmMsg_t confirm;
	} msg;
} mcpsPurgeRequestConfirm_t;

typedef struct {
	bool destroyable;
	union {
		mcpsDataIndicationMsg_t indication;
	} msg;
} mcpsDataIndication_t;

// ADTS.
// request-confirms
typedef mcpsDataRequestConfirm_t* Mcps_DataRequestConfirm;
typedef mcpsPurgeRequestConfirm_t* Mcps_PurgeRequestConfirm;

// indication-responses
typedef mcpsDataIndication_t* Mcps_DataIndication;


/**********************/
/*       MLME         */
/**********************/

// message primitives

typedef struct {
	uint8_t *assocRequestFrame;
	uint8_t frameLength;
	uint8_t logicalChannel;
	//uint16_t coordPANId;
} mlmeAssociateRequestMsg_t;

typedef struct {
	uint16_t assocShortAddr;
	Ieee_Status status;
} mlmeAssociateConfirmMsg_t;

typedef struct {
	uint8_t *assocIndicationFrame;
	uint8_t ACLEntry;
} mlmeAssociateIndicationMsg_t;

typedef struct {
	uint8_t *assocResponseFrame;
} mlmeAssociateResponseMsg_t;

typedef struct {
	uint8_t *disassocNotificationFrame;
	uint8_t frameLength;
} mlmeDisassociateRequestMsg_t;

typedef struct {
	Ieee_Status status;
} mlmeDisassociateConfirmMsg_t;

typedef struct {
	uint8_t *disassocNotificationFrame;
	uint8_t ACLEntry;
} mlmeDisassociateIndicationMsg_t;

// Note that lazy decoding in used for
// beacon notify indications.
typedef struct {
	uint8_t *beaconFrame;
	uint8_t frameLength;
	uint8_t logicalChannel;
	uint8_t linkQuality;
	uint32_t timeStamp;
	uint8_t ACLEntry;
	bool securityFailure;
} mlmeBeaconNotifyIndicationMsg_t;

typedef struct {
	ieeePibAttribute_t *pibAttribute;
} mlmeGetRequestMsg_t;

typedef struct {
	ieeePibAttribute_t *pibAttribute;
	Ieee_Status status;
} mlmeGetConfirmMsg_t;

typedef struct {
	uint8_t gtsType;
	uint8_t gtsDirection;
	uint8_t *GTSRequestFrame;
} mlmeGTSRequestMsg_t;

typedef struct {
	uint8_t gtsType;
	uint8_t gtsDirection;
	uint8_t *GTSRequestFrame;
	Ieee_Status status;
} mlmeGTSConfirmMsg_t;

typedef struct {
	uint16_t address;
	uint8_t gtsCharacteristics;
	bool securityUse;
	uint8_t ACLEntry;
} mlmeGTSIndicationMsg_t;

typedef struct {
	uint8_t *orphanNotificationFrame;
	uint8_t ACLEntry;
} mlmeOrphanIndicationMsg_t;

typedef struct {
	uint8_t *coordRealignFrame;
	bool associatedMember;
} mlmeOrphanResponseMsg_t;

typedef struct {
	bool setDefaultPib;
} mlmeResetRequestMsg_t;

typedef struct {
	Ieee_Status status;
} mlmeResetConfirmMsg_t;

typedef struct {
	bool deferPermit;
	uint32_t rxOnTime;
	uint32_t rxOnDuration;
} mlmeRxEnableRequestMsg_t;

typedef struct {
	Ieee_Status status;
} mlmeRxEnableConfirmMsg_t;

typedef struct {
	uint8_t scanType;
	uint32_t scanChannels;
	uint8_t scanDuration;
} mlmeScanRequestMsg_t;

typedef struct {
	uint8_t scanType;
	Ieee_Status status;
	uint32_t unscannedChannels;
	uint8_t resultListLen;
	uint8_t *resultList;
} mlmeScanConfirmMsg_t;

typedef struct {
	uint8_t *responseFrame;
	uint8_t frameLength;
	Ieee_Status status;
} mlmeCommStatusIndicationMsg_t;

typedef struct {
	ieeePibAttribute_t *pibAttribute;
} mlmeSetRequestMsg_t;

typedef struct {
	ieeePibAttribute_t *pibAttribute;
	Ieee_Status status;
} mlmeSetConfirmMsg_t;

typedef struct {
	uint16_t PANId;
	uint8_t logicalChannel;
	uint8_t beaconOrder;
	uint8_t superframeOrder;
	bool PANCoordinator;
	bool battLifeExt;
	bool coordRealign;
	bool securityEnable;
} mlmeStartRequestMsg_t;

typedef struct {
	Ieee_Status status;
} mlmeStartConfirmMsg_t;

typedef struct {
	uint8_t logicalChannel;
	bool trackBeacon;
} mlmeSyncRequestMsg_t;

typedef struct {
	Ieee_Status lossReason;
} mlmeSyncLossIndicationMsg_t;

// Poll request results in a data request
// MAC command frame.
typedef struct {
	ieeeAddress_t coordAddr;
	bool useSecurity;
} mlmePollRequestMsg_t;

typedef struct {
	Ieee_Status status;
} mlmePollConfirmMsg_t;

// Combined message primitives.
typedef struct {
	uint8_t type;
	union {
		mlmeAssociateRequestMsg_t request;
		mlmeAssociateConfirmMsg_t confirm;
	} msg;
} mlmeAssociateRequestConfirm_t;

typedef struct {
	uint8_t type;
	bool inited;
	union {
		mlmeAssociateIndicationMsg_t indication;
		mlmeAssociateResponseMsg_t response;
	} msg;
} mlmeAssociateIndicationResponse_t;

typedef struct {
	uint8_t type;
	union {
		mlmeDisassociateRequestMsg_t request;
		mlmeDisassociateConfirmMsg_t confirm;
	} msg;
} mlmeDisassociateRequestConfirm_t;

typedef struct {
	uint8_t type;
	union {
		mlmeDisassociateIndicationMsg_t indication;
	} msg;
} mlmeDisassociateIndication_t;

typedef struct {
	union {
		mlmeBeaconNotifyIndicationMsg_t indication;
	} msg;
} mlmeBeaconNotifyIndication_t;

typedef struct {
	union {
		mlmeGetRequestMsg_t request;
		mlmeGetConfirmMsg_t confirm;
	} msg;
} mlmeGetRequestConfirm_t;

typedef struct {
	union {
		mlmeGTSRequestMsg_t request;
		mlmeGTSConfirmMsg_t confirm;
	} msg;
} mlmeGTSRequestConfirm_t;

typedef struct {
	union {
		mlmeGTSIndicationMsg_t indication;
	} msg;
} mlmeGTSIndication_t;

typedef struct {
	bool inited;
	union {
		mlmeOrphanIndicationMsg_t indication;
		mlmeOrphanResponseMsg_t response;
	} msg;
} mlmeOrphanIndicationResponse_t;

typedef struct {
	union {
		mlmeResetRequestMsg_t request;
		mlmeResetConfirmMsg_t confirm;
	} msg;
} mlmeResetRequestConfirm_t;

typedef struct {
	union {
		mlmeRxEnableRequestMsg_t request;
		mlmeRxEnableConfirmMsg_t confirm;
	} msg;
} mlmeRxEnableRequestConfirm_t;

typedef struct {
	union {
		mlmeScanRequestMsg_t request;
		mlmeScanConfirmMsg_t confirm;
	} msg;
} mlmeScanRequestConfirm_t;

typedef struct {
	uint8_t type;
	union {
		mlmeCommStatusIndicationMsg_t indication;
	} msg;
} mlmeCommStatusIndication_t;

typedef struct {
	union {
		mlmeSetRequestMsg_t request;
		mlmeSetConfirmMsg_t confirm;
	} msg;
} mlmeSetRequestConfirm_t;

typedef struct {
	uint8_t type;
	union {
		mlmeStartRequestMsg_t request;
		mlmeStartConfirmMsg_t confirm;
	} msg;
} mlmeStartRequestConfirm_t;

typedef struct {
	union {
		mlmeSyncRequestMsg_t request;
	} msg;
} mlmeSyncRequest_t;

typedef struct {
	union {
		mlmeSyncLossIndicationMsg_t indication;
	} msg;
} mlmeSyncLossIndication_t;

typedef struct {
	uint8_t type;
	union {
		mlmePollRequestMsg_t request;
		mlmePollConfirmMsg_t confirm;
	} msg;
} mlmePollRequestConfirm_t;

// ADTS.
// request-confirms
typedef mlmeAssociateRequestConfirm_t* Mlme_AssociateRequestConfirm;
typedef mlmeDisassociateRequestConfirm_t* Mlme_DisassociateRequestConfirm;
typedef mlmeGetRequestConfirm_t* Mlme_GetRequestConfirm;
typedef mlmeGTSRequestConfirm_t* Mlme_GtsRequestConfirm;
typedef mlmeResetRequestConfirm_t* Mlme_ResetRequestConfirm;
typedef mlmeRxEnableRequestConfirm_t* Mlme_RxEnableRequestConfirm;
typedef mlmeScanRequestConfirm_t* Mlme_ScanRequestConfirm;
typedef mlmeSetRequestConfirm_t* Mlme_SetRequestConfirm;
typedef mlmeStartRequestConfirm_t* Mlme_StartRequestConfirm;
typedef mlmeSyncRequest_t* Mlme_SyncRequest;
typedef mlmePollRequestConfirm_t* Mlme_PollRequestConfirm;

// indication-responses
typedef mlmeAssociateIndicationResponse_t* Mlme_AssociateIndicationResponse;
typedef mlmeDisassociateIndication_t* Mlme_DisassociateIndication;
typedef mlmeBeaconNotifyIndication_t* Mlme_BeaconNotifyIndication;
typedef mlmeGTSIndication_t* Mlme_GtsIndication;
typedef mlmeOrphanIndicationResponse_t* Mlme_OrphanIndicationResponse;
typedef mlmeCommStatusIndication_t* Mlme_CommStatusIndication;
typedef mlmeSyncLossIndication_t* Mlme_SyncLossIndication;

// OTHER PRIMITIVES
typedef msdu_t* Ieee_Msdu;
// struct types
typedef panDescriptor_t* Ieee_PanDescriptor;
typedef ieeePibAttribute_t* Ieee_PibAttribute;
typedef uint8_t Ieee_AclDescriptor;
typedef ieeeAddress_t* Ieee_Address;

// primitive type defines.
#define MLME_Associate_Confirm            0x00
#define MLME_Associate_Indication         0x01
#define MLME_Disassociate_Confirm         0x02
#define MLME_Disassociate_Indication      0x03
#define MLME_Comm_Status_Indication       0x04
/*#define MCPS_Data_RequestConfirm          0x00
#define MCPS_Purge_RequestConfirm         0x01
#define MLME_Associate_RequestConfirm     0x02
#define MLME_Disassociate_RequestConfirm  0x03
#define MLME_Get_RequestConfirm           0x04
#define MLME_Gts_RequestConfirm           0x05
#define MLME_Reset_RequestConfirm         0x06
#define MLME_RxEnable_RequestConfirm      0x07
#define MLME_Scan_RequestConfirm          0x08
#define MLME_Set_RequestConfirm           0x09
#define MLME_Start_RequestConfirm         0x0A
#define MLME_Poll_RequestConfirm          0x0B*/

//#else
//#warning Ieee802154Adts.h included more than once!
#endif
