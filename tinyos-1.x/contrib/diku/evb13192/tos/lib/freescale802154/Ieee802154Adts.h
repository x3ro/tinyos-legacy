#ifndef _IEEE802154ADTS_H_
#define _IEEE802154ADTS_H_
//#include "NwkMacInterface.h"
typedef struct fsPibAttribute {
	bool destroyable;
	uint8_t pibAttribute;
	uint8_t pibAttributeValue[1];
} fsPibAttribute_t;


// The fsSdu consists of a pointer to the actual payload, 
// and a pointer to the buffer containing it, typically a confirm/indication primitive.
typedef struct {
	uint8_t payloadLen;
	uint8_t *payload; // payload starts here
	uint8_t bufferLen;
	uint8_t *buffer;
	bool bufferDestroyable;
} fsSdu_t;

typedef struct {
	uint8_t mode;
	uint16_t panId;
	uint8_t address[8];
} ieeeAddress_t;

enum
{
	REQUEST,
	CONFIRM
};
typedef uint8_t RequestConfirmEnum;

enum
{
	INDICATION,
	RESPONSE
};
typedef uint8_t IndicationResponseEnum;

/// MLME messages
typedef struct MlmeRequestConfirm_s
{
	//RequestConfirmEnum msgType;
	union
	{
		nwkMessage_t confirm;
		mlmeMessage_t request;
	} msg;
} MlmeRequestConfirm_t;

// Special get/set types (with buffer)
typedef struct
{
	fsPibAttribute_t *pibAttribute;
	MlmeRequestConfirm_t primitive;
} MlmeRequestConfirmGetSet_t;

typedef struct MlmeIndicationResponse_s
{
	//IndicationResponseEnum msgType;
	union
	{
		nwkMessage_t indication;
		mlmeMessage_t response;
	} msg;
} MlmeIndicationResponse_t;

// request-confirms
typedef MlmeRequestConfirm_t* Mlme_AssociateRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_DisassociateRequestConfirm;
typedef MlmeRequestConfirmGetSet_t* Mlme_GetRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_GtsRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_PollRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_ResetRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_RxEnableRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_ScanRequestConfirm;
typedef MlmeRequestConfirmGetSet_t* Mlme_SetRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_StartRequestConfirm;
typedef MlmeRequestConfirm_t* Mlme_SyncRequest;

// indication-responses
typedef MlmeIndicationResponse_t* Mlme_AssociateIndicationResponse;
typedef MlmeIndicationResponse_t* Mlme_BeaconNotifyIndication;
typedef MlmeIndicationResponse_t* Mlme_CommStatusIndication;
typedef MlmeIndicationResponse_t* Mlme_DisassociateIndication;
typedef MlmeIndicationResponse_t* Mlme_GtsIndication;
typedef MlmeIndicationResponse_t* Mlme_OrphanIndicationResponse;
typedef MlmeIndicationResponse_t* Mlme_SyncLossIndication;

/// MCPS messages
typedef struct McpsRequestConfirm_s
{
	//RequestConfirmEnum msgType;
	union
	{
		mcpsToNwkMessage_t confirm;
		nwkToMcpsMessage_t request;
	} msg;
	//uint8_t dummy[3]; // placeholder to make sure the sdu pointer hack will work
} McpsRequestConfirm_t;

typedef struct McpsIndication_s
{
	mcpsToNwkMessage_t msg;
	//uint8_t dummy[3]; // placeholder to make sure the sdu pointer hack will work
} McpsIndication_t;

// request-confirms
typedef McpsRequestConfirm_t* Mcps_DataRequestConfirm;
typedef McpsRequestConfirm_t* Mcps_PurgeRequestConfirm;

// indication-responses
typedef McpsIndication_t* Mcps_DataIndication;


// OTHER PRIMITIVES
typedef fsSdu_t* Ieee_Msdu;
// struct types
typedef panDescriptor_t* Ieee_PanDescriptor;
typedef fsPibAttribute_t* Ieee_PibAttribute;
typedef uint8_t Ieee_AclDescriptor;
typedef ieeeAddress_t* Ieee_Address;
#endif
