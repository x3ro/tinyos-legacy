/* NOTICE: Changed by Mads Bondo Dydensborg, <madsdyd@diku.dk>, Jan 2005. */

/************************************************************************************
* Header file for interface between MAC and PHY layer.
* The functionality declared in this file all resides in the PHY layer of ZigBee
*
* Author(s): Thomas O. Jensen
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
* Source Safe revision history (Do not edit manually)
*  $Date: 2005/10/12 15:01:42 $
*  $Author: janflora $
*  $Revision: 1.1 $
*  $Workfile: MacPhy.h $
************************************************************************************/

#ifndef _MACPHY_H_
#define _MACPHY_H_

/************************************************************************************
*************************************************************************************
* Includes
*************************************************************************************
************************************************************************************/

// Include target dependent information
#include "DigiType.h"

/************************************************************************************
*************************************************************************************
* Public macros
*************************************************************************************
************************************************************************************/

  // Get the offset from the beginning of a structure to the member variable
#define GetRelAddr(strct, member) ((uint8_t)(&(((strct *)(void *)0)->member))) 

/************************************************************************************
*************************************************************************************
* New types and defines! Everybody must change to these!
*************************************************************************************
************************************************************************************/

typedef uint32_t zbClock24_t;
typedef uint16_t zbClock16_t;

#define gMaxRxTxDataLength_c (125) // Max length of MPDU/PSDU without CRC

/* Desciption of data packet format in transmitting direction:
Please note that the packet formatted message does not�include the Preamble sequence,
Start of frame delimiter and the CRC (FCS) because these fields are read and
processed by the ABEL hardware.

Name	        Size	  Range	          Notes
Frame length  1	      (9-127 (Why     Note that this is the length used in the PHY
      	              is p42 min 8?)  packet to be sent over the air. It does not
                                      specify the length of this message.
Link quality	1	      0x00-0xff	      
Header length 1                       Length of header in bytes
Header type   1                       Enum for variations of header types
Frame control	2	      Bitmap	
Sequence	    1	      0x00-0xff
number
DstPANId	    0/2		
DstAddr	      0/2/8		
SrcPANId	    0/2		
SrcAddr	      0/2/8		
Frame counter	0/4		                  For security. Running increment
Key seq.	    0/1		                  For security.
counter
Msdu	        0-102		                May be encrypted
Integrity 	  0/4/8/16		            May be encrypted
code

The Frame control field contains the following bits:
Name	            Index Size	Range	  Notes
Frame type	      0-2	  3	    0x0-0x3	Beacon, Data, Acknowledgement, MAC command
Security enabled	3	    1		          From TxOptions
Frame pending	    4	    1		          Controlled by MEM/MCPS/MLME
Ack. req.	        5	    1		          From TxOptions
Intra PAN	        6	    1		
DstAddrMode	      10-11	2	    0x0-0x3	
SrcAddrMode	      14-15	2	    0x0-0x3	                                             */
#ifdef I_AM_A_SNIFFER
typedef struct rxPacket_tag{
  uint8_t frameLength;
  uint8_t linkQuality;
  uint8_t headerLength;
  uint8_t timeStampAbelMSB0;
  uint8_t timeStampAbelLSB1;
  uint8_t timeStampAbelLSB0;
  uint8_t timeStampMCU;
  uint8_t rxData[gMaxRxTxDataLength_c];
  zbClock24_t timeStamp;
} rxPacket_t;
#else
typedef struct rxPacket_tag{
  uint8_t frameLength;
  uint8_t linkQuality;
  uint8_t headerLength;
  uint8_t rxData[gMaxRxTxDataLength_c];
  zbClock24_t timeStamp;    // BUGBUG : Used to be dummyForRxDataOverflow[2]. Used for TimeStamp as temp hack
} rxPacket_t;                // BUGBUG : But take care: PHY layer will use this field as dummy rx storage!
#endif /* I_AM_A_SNIFFER */

#define gRxDataIndexOffset_c (GetRelAddr(rxPacket_t, rxData))

/* Desciption of data packet format in transmitting direction:
Please note that the packet formatted message does not include the Preamble sequence,
Start of frame delimiter and the CRC (FCS) because these fields are added by the ABEL
hardware.
Also, please note that this message includes the msduHandle, and the txInfo fields.
These are included for internal bookkeeping and are not transmitted over the
air. The msduHandle is valid for data packets only.
Length of entire packet is frameLength + 1 ("+1" includes length, MsduHandle
and Message type info fields - excludes CRC field)

Name	        Size	  Range	          Notes
Frame length  1	      (9-127 (Why     Note that this is the length used in the PHY
      	              is p42 min 8?)  packet to be sent over the air. It does not
                                      specify the length of this message.
MsduHandle	  1		                    
txInfo 	      1		                    Direct/Indirect/GTS, Allow pending frame modify
Frame control	2	      Bitmap	
Sequence	    1	      0x00-0xff	      Controlled by MCPS/MLME modules!
number
DstPANId	    0/2		
DstAddr	      0/2/8		
SrcPANId	    0/2		
SrcAddr	      0/2/8		
Frame counter	0/4		                  For security. Running increment
Key seq.	    0/1		                  For security. Set by network
counter
msdu	        0-102		                May be encrypted
Integrity     0/4/8/16		            May be encrypted
code

The Frame control field is identical to  the one defined for rx...
*/

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// If you add/change the Tx packet struct please note that you HAVE to update:         //
//                                                                                     //
//    (1) Make sure inline McpsConversion does not corrupt payload                     //
//    (2) Update the ackFrame_t structure                                              //
//    (3) Update the beaconRequestFrame_t structure                                    //
//    (4) Update the orphanNotificationFrame_t structure                               //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////
typedef struct txPacket_tag{
  uint8_t frameLength; // Length of MPDU/PSDU (length of txData + 2 for CRC)
  uint8_t txInfo; // Direct/indirect/GTS infom; allow frame pending changes in MEM; etc.
  struct {
    uint8_t csmaCaNb;   // The number of csma-ca attemps.
    uint8_t csmaCaBe;   // The csma-ca backoff exponent.
    uint8_t txCount;    // The number of tx attempts.
  } csmaAndTx;
  uint16_t expireTime;  // Only used for coordinator capability 
  uint8_t msduHandle;   // Valid for data packets only
  uint8_t txData[gMaxRxTxDataLength_c];
} txPacket_t;

void validateWaitLength(uint8_t cmpValue);

#define EXIT_IF_RXINDEX_NOT_REACHED(cmpValue) {\
  uint8_t cmpLength = gRxDataIndexOffset_c + (cmpValue);\
  if(cmpLength > gPhyMacDataRxIndex) {\
    validateWaitLength(cmpValue);\
    return;\
  }\
}

  // For accessing fixed location fields in (MPDU/SPDU) rx/txData in rx/txPacket_t:
#define gFrameControlLsbPos_c   (GetRelAddr(hdrGenericHeaderType_t, frameControlLsb)) // Position in rx/txData in rx/txPacket_t
#define gFrameControlMsbPos_c   (GetRelAddr(hdrGenericHeaderType_t, frameControlMsb)) // Position in rx/txData in rx/txPacket_t
#define gSeqNumberPos_c         (GetRelAddr(hdrGenericHeaderType_t, seqNr)) // Position in rx/txData in rx/txPacket_t
#define gAddrFieldsStartPos_c   (GetRelAddr(hdrGenericHeaderType_t, addrFieldsStart)) // Position in rx/txData in rx/txPacket_t

  // Maximum buffer sizes to be used:
#define gMaxRxPacketBufferSize_c (sizeof(rxPacket_t))
#define gMaxTxPacketBufferSize_c (sizeof(txPacket_t))
#define gMaxPacketBufferSize_c (getMax(gMaxRxPacketBufferSize_c, gMaxTxPacketBufferSize_c))

  // For accessing txInfo info:
#define gTxInfoCommandFrameFlag_c               ((uint8_t)(1 << 0))
#define gTxInfoDataReqFlag_c                    ((uint8_t)(1 << 1))
#define gTxInfoIndirectFlag_c                   ((uint8_t)(1 << 2))
#define gTxInfoConfirmFlag_c                    ((uint8_t)(1 << 3)) // If set then a data indication will be sent after the frame has completed.
                                                                    // The flag is handled entirely by the MEM.
#define gTxInfoGtsFlag_c                        ((uint8_t)(1 << 4))
#define gTxInfoHiPriDataFlag_c                  ((uint8_t)(1 << 5)) // If set then this marks a high priority data frame that should be placed 
                                                                    // first in the direct queue.
#define gTxInfoFramePendingModifyAllowFlag_c    ((uint8_t)(1 << 7))

  // Difference between Frame length (in rx/txPacket_t) and total packet legth over
  // the air is Preamble sequence, Start of frame delimiter and the Frame length
  // fields
#define gFrameLengthToTotalPhyLengthDiff_c (6)

#define gMacDataAndCommandThreshold_c 128

  // Events to be used in the status field of the action_t.
  // Valid only for the SeqActionCompleteInd and SeqActionFailInd primitives.
  // NOT used in the SeqActionStartInd!!
enum {
  gSeqMemAcUndefined_c = gMacDataAndCommandThreshold_c, // Dummy: Only used for error handling. 
                              // Enum must start with 128, because data frames uses the Id field
                              // as the length field (frame lengths are always less than 128). 
                              // MLME to MEM id's are located in the range from 128 to 255.
                              // Values from 0 to 127 denotes a MAC frame of that size.
                              // This is taken advantage of in the MEM input handler.
  gSeqMemAcSuccess_c,
  gSeqMemAcRxTimeout_c,       // Rx ended with timeout
  gSeqMemAcRxPollNoTxData_c,
  gSeqMemAcTxPollNoRxData_c,
  gSeqMemAcTxChannelBusy_c,// CCA response (for TX too)
  gSeqMemAcTxAckMissing_c, // Tx data completed without acknowledge
  gSeqMemStatusLastEntry_c // THIS MUST BE THE LAST ENTRY IN THE ENUMERATION
};
typedef uint8_t seqMemStatus_t;
  // Must NOT overlap other MEM event opcodes (gMlmeMemScanEdReq_c > gSeqMemStatusLastEntry_c)
enum {
  gMlmeMemScanEdReq_c = 180,  // The four Scan-related opcodes MUST follow each other
  gMlmeMemScanActiveReq_c,    // in the following order: energy, active, passive, orphan.
  gMlmeMemScanPassiveReq_c,
  gMlmeMemScanOrphanReq_c,
  gMlmeMemScanAbortReq_c,
  gMlmeMemStartReq_c,
  gMlmeMemTimerReq_c,
  gMlmeMemRxOnWhenIdleChanged_c,
  gMlmeMemSyncReq_c,
  gMlmeMemRxEnableReq_c,
  gMemCmdIdLastEntry // MUST BE THE LAST ENTRY
};
  // This is internal MEM events. Add-on to the memSeqStatus_t and gMemEventId_t 
  // structures.
  // Must NOT overlap other MEM event opcodes (gMemIntNoEvent_c > gMemCmdIdLastEntry)
enum {
  gMemIntNoEvent_c = 200, // A dummy event used for event buffering.
  gSeqMemActionFail_c, 
  gSeqMemActionFinish_c,
  gSeqMemDataInd_c,
  gMcpsDirectDataOrPollReq_c,
  gMemLwrAbortAll,
  gMemLwrTrigDataStateMachine_c,
  gMemCtrlDataStateMachineDone_c,
  gMemLwrTrigBeaconStateMachine_c,
  gMemLwrBeaconStateMachineDone_c,
  gMemCtrlAbortAllDone_c,
  gMemCtrlEdScanDone_c,
  gMemCtrlScanDone_c,
  gMemCtrlTimeout_c,
  gMemCtrlRxEnableDone_c,
  gMemIntLastEntry_c
};
typedef uint8_t memEventId_t;

  // Note: This enum contains all possible "timer related" status values. The timer
  // is currently only used during association. More status values can be added as
  // needed (currently only a single value is used although two are defined!)
enum {
  gTimerSuccess_c = 0,
  gTimerFailure_c
};



  // A header type with the generic information
typedef struct hdrGenericHeaderType_tag {
  uint8_t frameControlLsb;
  uint8_t frameControlMsb;
  uint8_t seqNr;
  uint8_t addrFieldsStart;
} hdrGenericHeaderType_t;

/* MBD: How silly is it to define the same symbols _twice_ in the same header file?
typedef uint32_t zbClock24_t;
typedef uint16_t zbClock16_t;
*/

//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------
// New types and defines block end...
//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------

#define CHANNELS_SUPPORTED_31_24 (0x07)
#define CHANNELS_SUPPORTED_23_16 (0xFF)
#define CHANNELS_SUPPORTED_15_8  (0xF8)
#define CHANNELS_SUPPORTED_7_0   (0x00)

typedef enum ePhyEnums_tag {
  cBusy,
  cBusy_Rx,
  cBusy_Tx,
  cForce_Trx_Off,
  cIdle,
  cInvalid_Parameter,
  cRx_On,
  cSuccess,
  cTrx_Off,
  cTx_On,
  cUnsupported_Attribute,

    // New enums
  cCcaTx,
  cCcaCcaTx,
  cRxED,
  cRxCCA,
  cBusy_Wait,
  cMaxPhyEnums
} ePhyEnums_t;



#define gMacMinHeaderLengthAck_c  (5) /* Smallest packet (ACK) excluding FCS */
#define gMacMinHeaderLength_c     (9) /* Smallest packet (ACK) excluding FCS */

/************************************************************************************
*************************************************************************************
* Public prototypes
*************************************************************************************
************************************************************************************/


/************************************************************************************
*************************************************************************************
* Private prototypes
*************************************************************************************
************************************************************************************/


/************************************************************************************
*************************************************************************************
* Private type definitions
*************************************************************************************
************************************************************************************/
/************************************************************************************
*************************************************************************************
* Private macros
*************************************************************************************
************************************************************************************/

/************************************************************************************
*************************************************************************************
* Public memory declarations
*************************************************************************************
************************************************************************************/
extern uint8_t gPhyMacDataRxIndex;
extern uint8_t gPhyMacDataTxIndex;
extern rxPacket_t *gpPhyRxData;
extern uint8_t *gpPhyTxPacket;

  // gRxTimeStamp holds the timestamp (16bit of the last received packet) 
extern zbClock16_t gRxTimeStamp;
extern zbClock24_t gRxTimeStamp24;
extern bool_t gStopAsyncRx;
extern bool_t gBeaconWithBadSrcDetected;

/************************************************************************************
*************************************************************************************
* Private memory declarations
*************************************************************************************
************************************************************************************/

/************************************************************************************
*************************************************************************************
* Public functions
*************************************************************************************
************************************************************************************/
// Mac-Phy Interface functions
void PhyPlmeSetCurrentChannelRequest(uint8_t channel);
void PhyPlmeEdRequest(void);
void PhyPlmeCcaRequest(void);
void PhyPlmeWaitRequest(void);
void PhyPlmeRxRequest(void);
void PhyPlmeTxRequest(void);
void PhyPlmeForceTrxOffRequest(void);
void PhyPdDataRequest(txPacket_t *pTxData);

// Phy-Mac Interface functions
void PhyPlmeCcaConfirm(bool_t channelInUse);
void PhyPlmeEdConfirm(uint8_t energyLevel);
void PhyPlmeRxTimeoutIndication(void);
void PhyPlmeSyncLossIndication(void);
void PhyPlmeB2BIndication(void);
void PhyPdDataConfirm(void);
void PhyPdDataIndication(void);


void macRxFilterProcess(uint8_t *macRxIndex);
void ReStartRx(void);
void RxTimeout(void);
void PollForRx(void);
void RestartRxOrTimeout(void);
void InitializePhy(void);
void InitializeMac(void);
void PhySyncSetEventTrigger(uint16_t startTime);
void PhySyncSetEventTimeout(zbClock24_t *pEndTime);
void LowLevelReadClockSync(zbClock24_t *pRetClk);
void LowLevelReadClockASync(zbClock24_t *pRetClk);

extern void (*gIsrFastAction)(void);
extern void (*gIsrPendingFastAction)(void);
extern void (*gIsrAsyncTailFunction)(void);
extern void (*gIsrSuperFastAction)(void);
extern void DummyFastIsr(void);
extern void IrqStreamingRxFirst(void);
extern void IrqAsyncRxFilterEntry(void);
extern void InitRxPointers(void);
extern void InitRxFastAction(void);

bool_t IsCurrentActionExtRx(void);
bool_t IsCurrentActionAutoRx(void);


/************************************************************************************
*************************************************************************************
* Private functions
*************************************************************************************
************************************************************************************/

/***********************************************************************************/

#endif
