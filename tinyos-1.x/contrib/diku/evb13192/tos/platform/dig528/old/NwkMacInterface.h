/************************************************************************************
* This is a global header file for the MAC/NWK interface.
*
* Author(s): BPPED1
*
* (c) Copyright 2004, Freescale, Inc.  All rights reserved.
*
* Freescale Confidential Proprietary
* Digianswer Confidential
*
* No part of this document must be reproduced in any form - including copied,
* transcribed, printed or by any electronic means - without specific written
* permission from Freescale.
*
* Last Inspected:
* Last Tested:
*
* Source Safe revision history (Do not edit manually) 
*   $Date: 2005/10/12 15:01:42 $
*   $Author: janflora $
*   $Revision: 1.1 $
*   $Workfile: NwkMacInterface.h $
************************************************************************************/

#ifndef _NWK_MAC_INTERFACE_H_
#define _NWK_MAC_INTERFACE_H_


/************************************************************************************
*************************************************************************************
* Public type definitions
*************************************************************************************
************************************************************************************/

//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// General constants used in MAC primitives
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------

  // Address modes used by mlmeAssociateReq_t, mlmePollReq_t, mcpsDataReq_t, 
  // nwkCommStatusInd_t, mcpsDataInd_t, and panDescriptor_t
enum {
  gAddrModeNone_c  = 0,
  gAddrModeShort_c = 2,
  gAddrModeLong_c  = 3
};

  // Logical channel used by mlmeAssociateReq_t, mlmeStartReq_t
  // mlmeSyncReq_t, and panDescriptor_t.
enum {
  gLogicalChannel11_c = 11,
  gLogicalChannel12_c = 12,
  gLogicalChannel13_c = 13,
  gLogicalChannel14_c = 14,
  gLogicalChannel15_c = 15,
  gLogicalChannel16_c = 16,
  gLogicalChannel17_c = 17,
  gLogicalChannel18_c = 18,
  gLogicalChannel19_c = 19,
  gLogicalChannel20_c = 20,
  gLogicalChannel21_c = 21,
  gLogicalChannel22_c = 22,
  gLogicalChannel23_c = 23,
  gLogicalChannel24_c = 24,
  gLogicalChannel25_c = 25,
  gLogicalChannel26_c = 26
};

  // Used for the parameters securityUse, and 
  // securityEnable in relevant primitives.
enum {
  gSecurityDisabled_c = 0,
  gSecurityEnabled_c  = 1
};

  // The capability info is an array of 8 bits. The following constants are
  // the bits that can be set or examined in the capability info field.
enum {
  gCapInfoAltPanCoord_c = 1<<0, // Unit has the capability of becoming a PAN coordinator
  gCapInfoDeviceFfd_c   = 1<<1, // Unit is an FFD.
  gCapInfoPowerMains_c  = 1<<2, // Unit is mains-powered, and not battery-powered.
  gCapInfoRxWhenIdle_c  = 1<<3, // Receiver is on when unit is idle.
  gCapInfoSecurity_c    = 1<<6, // Unit can send/receive secured MAC frames.
  gCapInfoAllocAddr_c   = 1<<7  // Ask coordinator to allocate short address during association.
};

  // Scan Modes
enum {
  gScanModeED_c       = 0,
  gScanModeActive_c   = 1,
  gScanModePassive_c  = 2,
  gScanModeOrphan_c   = 3
};

  // Superframe specification bit fields
enum {
  gSuperFrameSpecLsbBO_c            = 0x0F,
  gSuperFrameSpecLsbSO_c            = 0xF0,
  gSuperFrameSpecMsbFinalCapSlot_c  = 0x0F,
  gSuperFrameSpecMsbBattlifeExt_c   = 0x10,
  gSuperFrameSpecMsbReserved_c      = 0x20,
  gSuperFrameSpecMsbPanCoord_c      = 0x40,
  gSuperFrameSpecMsbAssocPermit_c   = 0x80
};

  // TX option bit fields
enum {
  gTxOptsAck_c      = 1<<0,
  gTxOptsGts_c      = 1<<1,
  gTxOptsIndirect_c = 1<<2,
  gTxOptsSecurity_c = 1<<3
};

  // GTS Characteristics field masks
enum {
  gGtsLength_c    = 0x0F, // Number of superframe slots requested for the GTS
  gGtsDirection_c = 0x10, // Clr: Transmit slot only, Set: Receive slot only.
  gGtsType_c      = 0x20, // Clr: Deallocate GTS slot, Set: Allocate GTS slot.
};

  // Security Suites
enum {
  // Security suite 0 - no security operations are performed.
  gSecSuiteNoSecurity_c   = 0x00,
  // Security suite 1-7 - various levels of security.
  gSecSuiteAesCtr_c       = 0x01,
  gSecSuiteAesCcm128_c    = 0x02,
  gSecSuiteAesCcm64_c     = 0x03,
  gSecSuiteAesCcm32_c     = 0x04,
  gSecSuiteAesCbcMac128_c = 0x05,
  gSecSuiteAesCbcMac64_c  = 0x06,
  gSecSuiteAesCbcMac32_c  = 0x07,
  // The value 0x08 signifies that no security suite is used
  gSecSuiteNone_c         = 0x08
};

  // MAC PIB attributes
enum {
    // Vendor specific attributes
  gMacRole_c                              = 0x20,
  gMacLogicalChannel_c                    = 0x21,
  gMacPanCoordinator_c                    = 0x22,
    // General MAC PIB attributes
  gMacPibAckWaitDuration_c                = 0x40,
  gMacPibAssociationPermit_c              = 0x41,
  gMacPibAutoRequest_c                    = 0x42,
  gMacPibBattLifeExt_c                    = 0x43,
  gMacPibBattLifeExtPeriods_c             = 0x44,
  gMacPibBeaconPayload_c                  = 0x45,
  gMacPibBeaconPayloadLength_c            = 0x46,
  gMacPibBeaconOrder_c                    = 0x47,
  gMacPibBeaconTxTime_c                   = 0x48,
  gMacPibBsn_c                            = 0x49,
  gMacPibCoordExtendedAddress_c           = 0x4A,
  gMacPibCoordShortAddress_c              = 0x4B,
  gMacPibDsn_c                            = 0x4C,
  gMacPibGtsPermit_c                      = 0x4D,
  gMacPibMaxCsmaBackoffs_c                = 0x4E,
  gMacPibMinBe_c                          = 0x4F,
  gMacPibPanId_c                          = 0x50,
  gMacPibPromiscuousMode_c                = 0x51,
  gMacPibRxOnWhenIdle_c                   = 0x52,
  gMacPibShortAddress_c                   = 0x53,
  gMacPibSuperFrameOrder_c                = 0x54,
  gMacPibTransactionPersistenceTime_c     = 0x55,
    // Security specific MAC PIB attributes
  gMacAclEntryDescriptorSet_c             = 0x70,
  gMacPibAclEntryDescriptorSetSize_c      = 0x71,
  gMacPibDefaultSecurity_c                = 0x72,
  gMacPibDefaultSecurityMaterialLength_c  = 0x73,
  gMacPibDefaultSecurityMaterial_c        = 0x74,
  gMacPibDefaultSecuritySuite_c           = 0x75,
  gMacPibSecurityMode_c                   = 0x76,
    // Vendor specific. Used for selecting current entry in ACL descriptor table.
  gMacPibAclEntryCurrent_c                = 0x77,
    // The following attributes are mapped to elements in mpPIBaclEntryDescriptorSet[gMacAclEntryCurrent_c]
  gMacPibAclEntryExtAddress_c             = 0x78,
  gMacPibAclEntryShortAddress_c           = 0x79,
  gMacPibAclEntryPanId_c                  = 0x7A,
  gMacPibAclEntrySecurityMaterialLength_c = 0x7B,
  gMacPibAclEntrySecurityMaterial_c       = 0x7C,
  gMacPibAclEntrySecuritySuite_c          = 0x7D,
};
typedef uint8_t macPibAttribute_t;

  // MAC error codes
enum {
  gSuccess_c              = 0x00,
  gPanAtCapacity_c        = 0x01,
  gPanAccessDenied_c      = 0x02,
  gBeaconLoss_c           = 0xE0,
  gChannelAccessFailure_c = 0xE1,
  gDenied_c               = 0xE2,
  gDisableTrxFailure_c    = 0xE3,
  gFailedSecurityCheck_c  = 0xE4,
  gFrameTooLong_c         = 0xE5,
  gInvalidGts_c           = 0xE6,
  gInvalidHandle_c        = 0xE7,
  gInvalidParameter_c     = 0xE8,
  gNoAck_c                = 0xE9,
  gNoBeacon_c             = 0xEA,
  gNoData_c               = 0xEB,
  gNoShortAddress_c       = 0xEC,
  gOutOfCap_c             = 0xED,
  gPanIdConflict_c        = 0xEE,
  gRealignment_c          = 0xEF,
  gTransactionExpired_c   = 0xF0,
  gTransactionOverflow_c  = 0xF1,
  gTxActive_c             = 0xF2,
  gUnavailableKey_c       = 0xF3,
  gUnsupportedAttribute_c = 0xF4
};


//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// Primitives in the MLME to NWK direction 
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
enum {
  gNwkAssociateInd_c,
  gNwkAssociateCnf_c,
  gNwkDisassociateInd_c,
  gNwkDisassociateCnf_c,
  gNwkBeaconNotifyInd_c,
  gNwkGetCnf_c,
  gNwkGtsInd_c,
  gNwkGtsCnf_c,
  gNwkOrphanInd_c,
  gNwkResetCnf_c,
  gNwkRxEnableCnf_c,
  gNwkScanCnf_c,
  gNwkCommStatusInd_c,
  gNwkSetCnf_c,
  gNwkStartCnf_c,
  gNwkSyncLossInd_c,
  gNwkPollCnf_c,
  gNwkErrorCnf_c,
  gNwkBeaconStartInd_c,
  gNwkNeuRFonStartCnf_c,
  gNwkNeuRFonScanCnf_c,
  gNwkMaxPrimitives_c
};
typedef uint8_t primMlmeToNwk_t;

  // PAN descriptor. Used in Scan Confirm,
  // and Beacon Notfiy Indication.
typedef struct panDescriptor_tag {
  uint8_t  coordAddress[8];
  uint8_t  coordPanId[2];
  uint8_t  coordAddrMode;
  uint8_t  logicalChannel;
  bool_t   securityUse;
  uint8_t  aclEntry;
  bool_t   securityFailure;
  uint8_t  superFrameSpec[2];
  bool_t   gtsPermit;
  uint8_t  linkQuality;
  uint8_t  timeStamp[3];
} panDescriptor_t;


  // Type: gNwkAssociateInd_c
typedef struct nwkAssociateInd_tag {
  uint8_t  deviceAddress[8];
  bool_t   securityUse;
  uint8_t  AclEntry;
  uint8_t  capabilityInfo;
} nwkAssociateInd_t;

  // Type: gNwkAssociateCnf_c
typedef struct nwkAssociateCnf_tag {
  uint8_t  assocShortAddress[2];
  uint8_t  status;
} nwkAssociateCnf_t;

  // Type: gNwkDisassociateInd_c
typedef struct nwkDisassociateInd_tag {
  uint8_t  deviceAddress[8];
  bool_t   securityUse;
  uint8_t  aclEntry;
  uint8_t  disassociateReason;
} nwkDisassociateInd_t;

  // Type: gNwkDisassociateCnf_c
typedef struct nwkDisassociateCnf_tag {
  uint8_t  status;
} nwkDisassociateCnf_t;

  // Type: gNwkBeaconNotifyInd_c,
typedef struct nwkBeaconNotifyInd_tag {
  uint8_t  bsn;
  uint8_t  pendAddrSpec;
  uint8_t  sduLength;
  uint8_t  *pAddrList;   // Points to address list in buffer
  panDescriptor_t *pPanDescriptor;  // Points to pan descripter in buffer
  uint8_t  *pSdu;        // Points to beacon payload in buffer
  void     *pBufferRoot; // Upper layer must free this buffer before freeing the indication message,
                         // E.g. MSG_Free(pBeaconInd->pBufferRoot); MSG_Free(pBeaconInd);
} nwkBeaconNotifyInd_t;

  // Type: gNwkGetCnf_c - not used,
typedef struct nwkGetCnf_tag {
  uint8_t  status;
  uint8_t  pibAttribute;
  uint8_t  *pibAttributeValue;
} nwkGetCnf_t;

  // Type: gNwkGtsInd_c,
typedef struct nwkGtsInd_tag {
  uint8_t  devAddress[2];
  bool_t   securityUse;
  uint8_t  AclEntry;
  uint8_t  gtsCharacteristics;
} nwkGtsInd_t;

  // Type: gNwkGtsCnf_c,
typedef struct nwkGtsCnf_tag {
  uint8_t  status;
  uint8_t  gtsCharacteristics;
} nwkGtsCnf_t;

  // Type: gNwkOrphanInd_c,
typedef struct nwkOrphanInd_tag {
  uint8_t  orphanAddress[8];
  bool_t   securityUse;
  uint8_t  AclEntry;
} nwkOrphanInd_t;

  // Type: gNwkResetCnf_c - not used,
typedef struct nwkResetCnf_tag {
  uint8_t  status;
} nwkResetCnf_t;

  // Type: gNwkRxEnableCnf_c,
typedef struct nwkRxEnableCnf_tag {
  uint8_t  status;
} nwkRxEnableCnf_t;

  // Type: gNwkScanCnf_c,
typedef struct nwkScanCnf_tag {
  uint8_t  status;
  uint8_t  scanType;
  uint8_t  resultListSize;
  uint8_t  unscannedChannels[4];
  union {  
    uint8_t *pEnergyDetectList;          // pointer to 16 byte static buffer
    panDescriptor_t *pPanDescriptorList; // Array of pan descriptors [5] - this one must be freed by MM_Free();
  } resList;
} nwkScanCnf_t;

  // Type: gNwkCommStatusInd_c,
typedef struct nwkCommStatusInd_tag {
  uint8_t  srcAddress[8];
  uint8_t  panId[2];
  uint8_t  srcAddrMode;
  uint8_t  destAddress[8];
  uint8_t  destAddrMode;
  uint8_t  status;
} nwkCommStatusInd_t;

  // Type: gNwkSetCnf_c - not used, 
typedef struct nwkSetCnf_tag {
  uint8_t  status;
  uint8_t  pibAttribute;
} nwkSetCnf_t;

  // Type: gNwkStartCnf_c,
typedef struct nwkStartCnf_tag {
  uint8_t  status;
} nwkStartCnf_t;

  // Type: gNwkSyncLossInd_c,
typedef struct nwkSyncLossInd_tag {
  uint8_t  lossReason;
} nwkSyncLossInd_t;

  // Type: gNwkPollCnf_c,
typedef struct nwkPollCnf_tag {
  uint8_t  status;
} nwkPollCnf_t;

  // Type: gNwkErrorCnf_c,
typedef struct nwkErrorCnf_tag {
  uint8_t  status;
} nwkErrorCnf_t;

  // MLME to NWK message
typedef struct nwkMessage_tag {
  primMlmeToNwk_t msgType;
  union {
    nwkAssociateInd_t     associateInd;
    nwkAssociateCnf_t     associateCnf;
    nwkDisassociateInd_t  disassociateInd;
    nwkDisassociateCnf_t  disassociateCnf;
    nwkBeaconNotifyInd_t  beaconNotifyInd;
    nwkGetCnf_t           getCnf;         // Not used
    nwkGtsInd_t           gtsInd;
    nwkGtsCnf_t           gtsCnf;
    nwkOrphanInd_t        orphanInd;
    nwkResetCnf_t         resetCnf;       // Not used
    nwkRxEnableCnf_t      rxEnableCnf;
    nwkScanCnf_t          scanCnf;
    nwkCommStatusInd_t    commStatusInd;
    nwkSetCnf_t           setCnf;         // Not used
    nwkStartCnf_t         startCnf;
    nwkSyncLossInd_t      syncLossInd;
    nwkPollCnf_t          pollCnf;
    nwkErrorCnf_t         errorCnf;       // Test framework primitive.
  } msgData;
} nwkMessage_t;



//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// Primitives in the MCPS to NWK direction 
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------

  // Primitives in the MAC to NWK direction. All should be included no matter which
  // features are implemented as the primitives are used to interface to Nwk.
enum {
  gMcpsDataCnf_c,
  gMcpsDataInd_c,
  gMcpsPurgeCnf_c,
  gMcpsPromInd_c,  // Promiscuous mode "packet received indication"
  gMcpsToNwkMaxPrimitives_c
};
typedef uint8_t primMcpsToNwk_t;

  // Type: gMcpsDataCnf_c,
typedef struct mcpsDataCnf_tag {
  uint8_t  msduHandle;
  uint8_t  status;
} mcpsDataCnf_t;

  // Type: gMcpsDataInd_c,
typedef struct mcpsDataInd_tag {
  uint8_t  dstAddr[8];    // First 0/2/8 bytes is the address as defined by dstAddrMode
  uint8_t  dstPanId[2];   // 16 bit word converted to little endian byte array
  uint8_t  dstAddrMode;
  uint8_t  srcAddr[8];    // First 0/2/8 bytes is the address as defined by srcAddrMode
  uint8_t  srcPanId[2];   // 16 bit word converted to little endian byte array
  uint8_t  srcAddrMode;
  uint8_t  msduLength;    // 0-102 (101?)
  uint8_t  mpduLinkQuality;
  bool_t   securityUse; 
  uint8_t  aclEntry;
  uint8_t  msdu[1];       // Place holder. Data will start at the address of this byte
} mcpsDataInd_t;

  // Type: gMcpsPurgeCnf_c,
typedef struct mcpsPurgeCnf_tag {
  uint8_t  msduHandle;
  uint8_t  status;
} mcpsPurgeCnf_t;

  // Type: gMcpsPromInd_c
typedef struct mcpsPromInd_tag {
  uint8_t  mpduLinkQuality;
  uint8_t  msduLength;    // 5-121 (shortest frame is ACK frame. Longest frame is max length MAC frame)
  uint8_t  msdu[1];       // Place holder. Data will start at the address of this byte
} mcpsPromInd_t;

  // MCPS to NWK message
typedef struct mcpsToNwkMessage_tag {
  primMcpsToNwk_t msgType;
  union {
    mcpsDataCnf_t   dataCnf;
    mcpsDataInd_t   dataInd;
    mcpsPurgeCnf_t  purgeCnf;
    mcpsPromInd_t   promInd;
  } msgData;
} mcpsToNwkMessage_t;


//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// Primitives in the NWK to MLME direction 
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------

  // Primitives in the NWK to MAC direction. These must
  // always exist even if the feature is not supported.
  // The NWK layer may have a copy of these enums, and
  // does not know if we disable some of them here.
enum {
  gMlmeAssociateReq_c,
  gMlmeAssociateRes_c,
  gMlmeDisassociateReq_c,
  gMlmeGetReq_c,
  gMlmeGtsReq_c,
  gMlmeOrphanRes_c,
  gMlmeResetReq_c,
  gMlmeRxEnableReq_c,
  gMlmeScanReq_c,
  gMlmeSetReq_c,
  gMlmeStartReq_c,
  gMlmeSyncReq_c,
  gMlmePollReq_c,
  gMlmeNeuRFonStartReq_c,
  gMlmeNeuRFonScanReq_c,
  gMlmeInternalPanConflictDetected_c,
  gMlmeMaxPrimitives_c
};
typedef uint8_t primNwkToMlme_t;

  // Type: gMlmeAssociateReq_c
typedef struct mlmeAssociateReq_tag {
  uint8_t  coordAddress[8];
  uint8_t  coordPanId[2];
  uint8_t  coordAddrMode;
  uint8_t  logicalChannel;
  bool_t   securityEnable;
  uint8_t  capabilityInfo;
} mlmeAssociateReq_t;

  // Type: gMlmeAssociateRes_c
typedef struct mlmeAssociateRes_tag {
  uint8_t  deviceAddress[8];
  uint8_t  assocShortAddress[2];
  bool_t   securityEnable;
  uint8_t  status;
} mlmeAssociateRes_t;

#if gNewDisassociateReq_d
  // Type: gMlmeDisassociateReq_c, new version w. addr mode.
typedef struct mlmeDisassociateReq_tag {
  uint8_t  dstAddress[8];
  bool_t   securityEnable;
  uint8_t  disassociateReason;
  uint8_t  dstAddrMode; // Also placed at this position (base+10) in other primitives.
} mlmeDisassociateReq_t;
#else
  // Type: gMlmeDisassociateReq_c
typedef struct mlmeDisassociateReq_tag {
  uint8_t  deviceAddress[8];
  bool_t   securityEnable;
  uint8_t  disassociateReason;
} mlmeDisassociateReq_t;
#endif // gNewDisassociateReq_d

  // Type: gMlmeGetReq_c,
  // Note: Only macBeaconPayloadLength number of
  // bytes is returnd if getting macBeaconPayload.
typedef struct mlmeGetReq_tag {
  uint8_t  pibAttribute;
  uint8_t  *pibAttributeValue;  // Not in spec. 
} mlmeGetReq_t;

  // Type: gMlmeGtsReq_c,
typedef struct mlmeGtsReq_tag {
  bool_t   securityEnable;
  uint8_t  gtsCharacteristics;
} mlmeGtsReq_t;

  // Type: gMlmeOrphanRes_c,
typedef struct mlmeOrphanRes_tag {
  uint8_t  orphanAddress[8];
  uint8_t  shortAddress[2];
  bool_t   securityEnable;
  bool_t   associatedMember;
} mlmeOrphanRes_t;

  // Type: gMlmeResetReq_c,
typedef struct mlmeResetReq_tag {
  bool_t   setDefaultPib;
} mlmeResetReq_t;

  // Type: gMlmeRxEnableReq_c,
typedef struct mlmeRxEnableReq_tag {
  bool_t   deferPermit;
  uint8_t  rxOnTime[3];
  uint8_t  rxOnDuration[3];
} mlmeRxEnableReq_t;

  // Type: gMlmeScanReq_c,
typedef struct mlmeScanReq_tag {
  uint8_t  scanType;
  uint8_t  scanChannels[4];
  uint8_t  scanDuration;
} mlmeScanReq_t;

  // Type: gMlmeSetReq_c,
  // Note: macBeaconPayloadLength must have been
  // set before setting macBeaconPayload.
typedef struct mlmeSetReq_tag {
  uint8_t   pibAttribute;
  uint8_t   *pibAttributeValue;
} mlmeSetReq_t;

  // Type: gMlmeStartReq_c,
typedef struct mlmeStartReq_tag {
  uint8_t  panId[2];
  uint8_t  logicalChannel;
  uint8_t  beaconOrder;
  uint8_t  superFrameOrder;
  bool_t   panCoordinator;
  bool_t   batteryLifeExt;
  bool_t   coordRealignment;
  bool_t   securityEnable;
} mlmeStartReq_t;

  // Type: gMlmeSyncReq_c,
typedef struct mlmeSyncReq_tag {
  uint8_t  logicalChannel;
  bool_t   trackBeacon;
} mlmeSyncReq_t;

  // Type: gMlmePollReq_c,
typedef struct mlmePollReq_tag {
  uint8_t  coordAddress[8];
  uint8_t  coordPanId[2];
  uint8_t  coordAddrMode;
  bool_t   securityEnable;
} mlmePollReq_t;

  // NWK to MLME message
typedef struct mlmeMessage_tag {
  primNwkToMlme_t msgType;
  union {
    mlmeAssociateReq_t    associateReq;
    mlmeAssociateRes_t    associateRes;
    mlmeDisassociateReq_t disassociateReq;
    mlmeGetReq_t          getReq;
    mlmeGtsReq_t          gtsReq;
    mlmeOrphanRes_t       orphanRes;
    mlmeResetReq_t        resetReq;
    mlmeRxEnableReq_t     rxEnableReq;
    mlmeScanReq_t         scanReq;
    mlmeSetReq_t          setReq;
    mlmeStartReq_t        startReq;
    mlmeSyncReq_t         syncReq;
    mlmePollReq_t         pollReq;
  } msgData;
} mlmeMessage_t;


//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// Primitives in the NWK to MCPS direction 
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------

  // Primitives in the NWK to MAC direction. All should be included no matter which
  // features are implemented as the primitives are used to interface to Nwk.
enum {
  gMcpsDataReq_c,
  gMcpsPurgeReq_c,
  gMcpsNeuRFonDataReq_c,
  gNwkToMcpsMaxPrimitives_c
};
typedef uint8_t primNwkToMcps_t;

  // Type: gMcpsDataReq_c,
typedef struct mcpsDataReq_tag {
  uint8_t  dstAddr[8];  // First 0/2/8 bytes is the address as defined by dstAddrMode
  uint8_t  dstPanId[2]; // 16 bit word converted to little endian byte array
  uint8_t  dstAddrMode;
  uint8_t  srcAddr[8];  // First 0/2/8 bytes is the address as defined by srcAddrMode
  uint8_t  srcPanId[2]; // 16 bit word converted to little endian byte array
  uint8_t  srcAddrMode;
  uint8_t  msduLength;  // 0-102
  uint8_t  msduHandle; 
  uint8_t  txOptions;
  uint8_t  msdu[1];     // Place holder. Data will start at the address of this byte
} mcpsDataReq_t;

  // Type: gMcpsPurgeReq_c,
typedef struct mcpsPurgeReq_tag {
  uint8_t  msduHandle;
} mcpsPurgeReq_t;

  // NWK to MCPS message
typedef struct nwkToMcpsMessage_tag {
  primNwkToMcps_t msgType;
  union {
    mcpsDataReq_t         dataReq;
    mcpsPurgeReq_t        purgeReq;
  } msgData;
} nwkToMcpsMessage_t;


/************************************************************************************
*************************************************************************************
* Public functions
*************************************************************************************
************************************************************************************/

  // MAC main function. Must be called by the NWK loop until it returns FALSE. The 
  // function will examine the MAC input queues, and handle incoming/outgoing
  // MAC/MCPS messages.
bool_t Mlme_Main(void);

  // MAC Message/Memory interface functions.
void *MM_Alloc(uint8_t size);
void MM_Free(void *pBlock);

  // NWK to MLME/MCPS service access points. pMsg must be allocated by MSG_Alloc(size)
  // unless the primitive in question is Get/Set/Reset-Request.
uint8_t NWK_MLME_SapHandler(mlmeMessage_t *pMsg);
uint8_t NWK_MCPS_SapHandler(nwkToMcpsMessage_t *pMsg);

  // MLME/MCPS to NWK service access points. pMsg must be allocated by MSG_Free(pMsg).
uint8_t MLME_NWK_SapHandler(nwkMessage_t *pMsg);
uint8_t MCPS_NWK_SapHandler(mcpsToNwkMessage_t *pMsg);

void Init_802_15_4(void);

#endif /* _NWK_MAC_INTERFACE_H_ */
