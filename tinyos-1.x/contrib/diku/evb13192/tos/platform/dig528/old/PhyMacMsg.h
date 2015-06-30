/************************************************************************************
* This is the header file for the memory and message module.
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
*   $Workfile: PhyMacMsg.h $
************************************************************************************/

#ifndef _PHY_MAC_MSG_H_
#define _PHY_MAC_MSG_H_

#include "MacPhy.h"
#include "NwkMacInterface.h"

/************************************************************************************
*************************************************************************************
* Public macros
*************************************************************************************
************************************************************************************/

  // Used for calculating size of blocks in pool #0
typedef union {
  nwkMessage_t    nwkMessage;
  panDescriptor_t panDescriptor;
} block1sizeOrigin_t;

  // Number of pools
#define gMmNumPools_c 3

  // Number of blocks that must at least be left over 
  // if upper layers allocates msgs through MM_Alloc
//#define gExternBufferAllocLimit_c 1

  // The block sizes will be rounded up to multipla of largest
  // data integer type (a pointer or uint16_t for HCS08).
  // Extra space for list headers will be added automagically.
  // The block sizes must be in ascending order. If fewer than
  // 4 pools are used, then gMmPoolSize*_c, and gMmBlockSize*_c
  // for the unused pools must be defined to the value 0.

  // TBD: Currently many "small" messages uses union in deciding message size even if
  //      the message is smaller. Not a big problem, but could be improve and that
  //      may affect necessary sizes of messages!
#define gMmPoolSize0_c  (gTotalSmallMsgs_d)
#define gMmBlockSize0_c (sizeof(block1sizeOrigin_t)) // ~22 bytes

#define gMmPoolSize1_c  (gTotalBigMsgs_d - gBigMsgsMacOnly_d)
#define gMmBlockSize1_c gMaxPacketBufferSize_c

  // Pool[2] is private to the MAC.
#define gMmPoolSize2_c  gBigMsgsMacOnly_d
// BUGBUG : Buffer max size is based on the size of txPacket_t and rxPacket_t (whichever is larger)
// BUGBUG : You HAVE to make sure that NWK-MLME data struct is SMALLER than this. Consider adding
// getMax(gMaxPacketBufferSize_c,sizeof(nwkToMcpsMessage_t)+aMaxMacFrameSize-1).
#define gMmBlockSize2_c gMaxPacketBufferSize_c

#define gMmPoolSize3_c  0
#define gMmBlockSize3_c 0


  // Make sure that all blocks are aligned correctly (  Round up: (((a + (s-1)) / s) * s), s=4 -> (((a+3) >> 2) << 2)  )
#define mMmBlockSize0_c ((((gMmBlockSize0_c) + (sizeof(uint8_t *) - 1)) / sizeof(uint8_t *)) * sizeof(uint8_t *))
#define mMmBlockSize1_c ((((gMmBlockSize1_c) + (sizeof(uint8_t *) - 1)) / sizeof(uint8_t *)) * sizeof(uint8_t *))
#define mMmBlockSize2_c ((((gMmBlockSize2_c) + (sizeof(uint8_t *) - 1)) / sizeof(uint8_t *)) * sizeof(uint8_t *))
#define mMmBlockSize3_c ((((gMmBlockSize3_c) + (sizeof(uint8_t *) - 1)) / sizeof(uint8_t *)) * sizeof(uint8_t *))

  // The total number of bytes in each pool including list headers
#define mMmPoolByteSize0_c ((gMmPoolSize0_c) * (mMmBlockSize0_c + sizeof(listHeader_t)))
#define mMmPoolByteSize1_c ((gMmPoolSize1_c) * (mMmBlockSize1_c + sizeof(listHeader_t)))
#define mMmPoolByteSize2_c ((gMmPoolSize2_c) * (mMmBlockSize2_c + sizeof(listHeader_t)))
#define mMmPoolByteSize3_c ((gMmPoolSize3_c) * (mMmBlockSize3_c + sizeof(listHeader_t)))

  // Total number of bytes in all pools together
#define mMmTotalPoolSize_c (mMmPoolByteSize0_c + mMmPoolByteSize1_c + mMmPoolByteSize2_c + mMmPoolByteSize3_c)



#if gMmNumPools_c == 1
#define mMmBlockSizeLargest_c gMmBlockSize0_c // Size of largest block
#define mMmLargestPoolIdx_c 0 // Index of pool that contains the largest blocks
#endif // gMmNumPools_c == 1

#if gMmNumPools_c == 2
#define mMmBlockSizeLargest_c gMmBlockSize1_c // Size of largest block
#define mMmLargestPoolIdx_c 1 // Index of pool that contains the largest blocks
#endif // gMmNumPools_c == 2

#if gMmNumPools_c == 3
#define mMmBlockSizeLargest_c gMmBlockSize2_c // Size of largest block
#define mMmLargestPoolIdx_c 2 // Index of pool that contains the largest blocks
#endif // gMmNumPools_c == 3

#if gMmNumPools_c == 4
#define mMmBlockSizeLargest_c gMmBlockSize3_c // Size of largest block
#define mMmLargestPoolIdx_c 3 // Index of pool that contains the largest blocks
#endif // gMmNumPools_c == 4


  // Remove when removed in hwdrv_win.c
#define PmMsg_Init() //MM_Init(maMmHeap, MM_GetRequiredHeapSize())

  // Allocate a message of a certain type
#define MSG_AllocType(type) MM_Alloc(sizeof(type))

  // Allocate a message of a certain size
#define MSG_Alloc(size) MM_Alloc(size)

  // Free a message
#define MSG_Free(msg) MM_Free(msg)

  // Sending a message is equal to calling a Service Access Point function
  // If the sap argument is e.g. MLME, then a function called MLME_SapHandler
  // must exist that takes a message pointer as argument.
#define MSG_Send(sap, msg)  (sap##_SapHandler((void *)(msg)))

  // Put a message in a queue.
#define MSG_Queue(anchor, element) List_AddTail((anchor), (element))

  // Put a message in a queue at the head. 
#define MSG_QueueHead(anchor, element) List_AddHead((anchor), (element))

  // Get a message from a queue. Returns NULL if no messages in queue.
#define MSG_DeQueue(anchor) List_RemoveHead(anchor)

  // Check if a message is pending in a queue. Returns
  // TRUE if any pending messages, and FALSE otherwise.
#define MSG_Pending(anchor) ((anchor)->pHead != 0)

#define MSG_InitQueue(anchor) List_ClearAnchor(anchor)

  // Need to change this in the target implementation.
extern uint8_t maMmHeap[];

#ifdef MM_DEBUG

  // Override previous defines
#undef MSG_AllocType
#define MSG_AllocType(type) MM_AllocDebug(sizeof(type), __FILE__, (uint16_t)(__LINE__))

#undef MSG_Alloc
#define MSG_Alloc(size) MM_AllocDebug(size, __FILE__, (uint16_t)(__LINE__))

#undef MSG_Send
#define MSG_Send(sap, msg) (sap##_SapHandlerDebug((void *)(msg), __FILE__, (uint16_t)(__LINE__)))

  // Not public functions any longer
#define MM_Alloc(size) MM_AllocDebug(size, __FILE__, (uint16_t)(__LINE__))
#define MM_AllocFast() MM_AllocFastDebug(__FILE__, (uint16_t)(__LINE__))

#undef MSG_Queue
#define MSG_Queue(anchor, element) { List_AddTail((anchor), (element)); (((listHeader_t *)(element))-1)->queueInfo = "Queued in " #anchor ; }

#endif // MM_DEBUG

/************************************************************************************
*************************************************************************************
* Public type definitions
*************************************************************************************
************************************************************************************/

  // This struct is used privately but must be declared
  // here in order for the anchor_t struct to work.
  // The struct is used in memory blocks for linking them
  // in single chained lists. The struct is embedded in
  // list elements, and transparent to the users. 
typedef struct listHeader_tag {
  struct listHeader_tag *pNext;
#ifdef MM_ALLOC_SEND_DEBUG
  uint8_t *Owner;
#endif /*MM_ALLOC_SEND_DEBUG*/
#ifdef MM_DEBUG
  uint8_t *fileName;
  uint16_t lineNumber;
  uint8_t *queueInfo;
#endif // MM_DEBUG
} listHeader_t;

  // List anchor with head and tail elements. Used 
  // for both memory pools and message queues.
typedef struct anchor_tag {
  listHeader_t *pHead;
  listHeader_t *pTail;
#ifdef MM_DEBUG
  uint8_t numElements;
#endif // MM_DEBUG
} anchor_t;


#ifdef MM_DEBUG


typedef struct block0_tag {
  listHeader_t  listHeader;
  uint8_t       data[mMmBlockSize0_c];
} block0_t;

#if gMmNumPools_c > 1
typedef struct block1_tag {
  listHeader_t  listHeader;
  uint8_t       data[mMmBlockSize1_c];
} block1_t;
#endif // gMmNumPools_c > 1

#if gMmNumPools_c > 2
typedef struct block2_tag {
  listHeader_t  listHeader;
  uint8_t       data[mMmBlockSize2_c];
} block2_t;
#endif // gMmNumPools_c > 2

#if gMmNumPools_c > 3
typedef struct block3_tag {
  listHeader_t  listHeader;
  uint8_t       data[mMmBlockSize3_c];
} block3_t;
#endif // gMmNumPools_c > 3

typedef struct macHeap_tag {
  block0_t block0[gMmPoolSize0_c];
#if gMmNumPools_c > 1
  block1_t block1[gMmPoolSize1_c];
#if gMmNumPools_c > 2
  block2_t block2[gMmPoolSize2_c];
#if gMmNumPools_c > 3
  block3_t block3[gMmPoolSize3_c];
#endif // gMmNumPools_c > 3
#endif // gMmNumPools_c > 2
#endif // gMmNumPools_c > 1
} macHeap_t;

#endif // MM_DEBUG

typedef enum {
  gMmEnablePrivatePool_c  = 0,
  gMmDisablePrivatePool_c = mMmBlockSizeLargest_c
} privatePoolState_t;

/************************************************************************************
*************************************************************************************
* Public prototypes
*************************************************************************************
************************************************************************************/
extern void MM_Init(uint8_t *, uint16_t);

#ifndef MM_DEBUG
extern void *MM_Alloc(uint8_t size);
extern void *MM_AllocFast(void);
#else
extern void *MM_AllocDebug(uint8_t size, uint8_t *fileName, uint16_t lineNumber);
extern void *MM_AllocFastDebug(uint8_t *fileName, uint16_t lineNumber);

extern void    MEM_MLME_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t MLME_NWK_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern void    MLME_MEM_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t MCPS_NWK_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t NWK_MLME_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t NWK_MCPS_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t MEM_ASP_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t ASP_APP_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);
extern uint8_t APP_ASP_SapHandlerDebug(void *pMsg, uint8_t *fileName, uint16_t lineNumber);

#endif // MM_DEBUG

extern void  MM_Free(void *pBlock);
extern uint16_t MM_GetRequiredHeapSize(void);

extern void MM_SetPrivatePool(privatePoolState_t privatePoolState);

extern void  List_ClearAnchor(anchor_t *pAnchor);
extern void  List_AddTail(anchor_t *pAnchor, void *pBlock);
extern void  List_AddHead(anchor_t *pAnchor, void *pBlock);
extern void *List_RemoveHead(anchor_t *pAnchor);
void List_Remove(anchor_t *pAnchor, void *pPrevBlock, void *pBlock);
void *List_GetFirst(anchor_t *pAnchor);
void *List_GetNext(void *pBlock);


/*#ifdef MM_ALLOC_SEND_DEBUG
#define MM_Alloc(Owner, NumBytes) MM_AllocDebug(uint8_t *Owner, uint8_t NumBytes)
  MM_Allocate(NumBytes); \
  (listHeader_t *)(((listHeader_t *)pBlock)-1)->Owner = #Owner;
  
#else
  #define MM_Alloc(Owner, NumBytes) MM_Allocate(NumBytes);
#endif*/


#endif /* _PHY_MAC_MSG_H_ */
