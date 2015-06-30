#ifndef _IEEE802154ADTS_H_
#define _IEEE802154ADTS_H_


/** The 802.15.4 provider is supposed to fill in this template file with
	the appropriate type definitions TODO: and buffer size declarations
	All types in this header file are abstract data types with interfaces defining
	the operations allowed from the application sitting on top of the 802.15.4 MAC **/

typedef <type> Ieee_Sdu; //service data unit
typedef <type> Ieee_PanDescriptor;
typedef <type> Ieee_PibAttribute;
typedef <type> Ieee_AclDescriptor;

/** Communication primitive types **/

typedef <type> Mcps_DataRequestConfirm;
typedef <type> Mcps_PurgeRequestConfirm;

typedef <type> Mlme_AssociateRequestConfirm;
typedef <type> Mlme_DisassociateRequestConfirm;
typedef <type> Mlme_GetRequestConfirm; // NOT DONE YET
typedef <type> Mlme_GtsRequestConfirm;
typedef <type> Mlme_PollRequestConfirm;
typedef <type> Mlme_ResetRequestConfirm;
typedef <type> Mlme_RxEnableRequestConfirm;
typedef <type> Mlme_ScanRequestConfirm;
typedef <type> Mlme_SetRequestConfirm; // NOT DONE YET
typedef <type> Mlme_StartRequestConfirm;
typedef <type> Mlme_SyncRequestConfirm;

typedef <type> Mcps_DataIndicationResponse;
typedef <type> Mlme_AssociateIndicationResponse;
typedef <type> Mlme_BeaconNotifyIndicationResponse;
typedef <type> Mlme_CommStatusIndicationResponse;
typedef <type> Mlme_DisassociateIndicationResponse;
typedef <type> Mlme_GtsIndicationResponse;
typedef <type> Mlme_OrphanIndicationResponse;
typedef <type> Mlme_SyncLossIndicationResponse;

#endif
