#ifndef _DIFF_MSG_H_
#define _DIFF_MSG_H_

#include "attribute.h"
#include "Ext_AM.h"
#include "msg_types.h"
#include "OPPLib/DataStructures.h"

typedef Ext_TOS_Msg DiffMsg;
typedef DiffMsg *DiffMsgPtr;

static inline result_t getMsgType(DiffMsgPtr msg, uint8_t *pType)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  *pType = msg->type; // NOTE: these types are defined in msg_types.h
  return SUCCESS;
}

static inline result_t getSource(DiffMsgPtr msg, uint16_t *pSource)
{
  if (msg == NULL)
  {
    return FAIL;
  }
  if (msg->type != ESS_OPP_DATA)
  {
    return FAIL;
  }

  *pSource = ((DataMessage *)(msg->data))->source; 

  return SUCCESS;
}

static inline result_t getHopsToSrc(DiffMsgPtr msg, uint8_t *pHopsToSrc)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  if (msg->type != ESS_OPP_DATA)
  {
    return FAIL;
  }

  *pHopsToSrc = ((DataMessage *)(msg->data))->hopsToSrc; 

  return SUCCESS;
}

static inline result_t getSink(DiffMsgPtr msg, uint16_t *pSink)
{
  if (msg == NULL)
  {
    return FAIL;
  }
  if (msg->type != ESS_OPP_INTEREST)
  {
    return FAIL;
  }

  *pSink = ((InterestMessage *)(msg->data))->sink; 

  return SUCCESS;
}

static inline result_t getExpiration(DiffMsgPtr msg, 
				     uint16_t *pExpiration)
{
  if (msg == NULL)
  {
    return FAIL;
  }
  if (msg->type != ESS_OPP_INTEREST)
  {
    return FAIL;
  }

  *pExpiration = ((InterestMessage *)(msg->data))->expiration; 

  return SUCCESS;
}

static inline result_t getTTL(DiffMsgPtr msg, uint8_t *pTTL)
{
  if (msg == NULL)
  {
    return FAIL;
  }
  if (msg->type != ESS_OPP_INTEREST)
  {
    return FAIL;
  }

  *pTTL = ((InterestMessage *)(msg->data))->ttl; 

  return SUCCESS;
}

static inline result_t getPrevHop(DiffMsgPtr msg, uint16_t *pPrevHop)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  if (msg->type == ESS_OPP_DATA)
  {
    *pPrevHop = ((DataMessage *)(msg->data))->prevHop; 
  }
  else if (msg->type == ESS_OPP_INTEREST)
  {
    *pPrevHop = ((InterestMessage *)(msg->data))->prevHop; 
  }
  else
  {
    return FAIL;
  }

  return SUCCESS;
}

static inline result_t getSeqNum(DiffMsgPtr msg, uint16_t *pSeqNum)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  if (msg->type == ESS_OPP_DATA)
  {
    *pSeqNum = ((DataMessage *)(msg->data))->seqNum; 
  }
  else if (msg->type == ESS_OPP_INTEREST)
  {
    *pSeqNum = ((InterestMessage *)(msg->data))->seqNum; 
  }
  else
  {
    return FAIL;
  }

  return SUCCESS;
}

static inline result_t getNumAttrs(DiffMsgPtr msg, uint8_t *pNumAttrs)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  if (msg->type == ESS_OPP_DATA)
  {
    *pNumAttrs = ((DataMessage *)(msg->data))->numAttrs; 
  }
  else if (msg->type == ESS_OPP_INTEREST)
  {
    *pNumAttrs = ((InterestMessage *)(msg->data))->numAttrs; 
  }
  else
  {
    return FAIL;
  }

  return SUCCESS;
}

static inline result_t setNumAttrs(DiffMsgPtr msg, uint8_t numAttrs)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  if (msg->type == ESS_OPP_DATA)
  {
    ((DataMessage *)(msg->data))->numAttrs = numAttrs; 
  }
  else if (msg->type == ESS_OPP_INTEREST)
  {
    ((InterestMessage *)(msg->data))->numAttrs = numAttrs; 
  }
  else
  {
    return FAIL;
  }

  return SUCCESS;
}

static inline result_t getAttrs(DiffMsgPtr msg, 
				Attribute **pAttrArray,
				uint8_t *pNumAttrs)
{
  if (msg == NULL)
  {
    return FAIL;
  }

  if (msg->type == ESS_OPP_DATA)
  {
    *pAttrArray = ((DataMessage *)(msg->data))->attributes;
    *pNumAttrs = ((DataMessage *)(msg->data))->numAttrs;
  }
  else if (msg->type == ESS_OPP_INTEREST)
  {
    *pAttrArray = ((InterestMessage *)(msg->data))->attributes;
    *pNumAttrs = ((InterestMessage *)(msg->data))->numAttrs;
  }
  else
  {
    return FAIL;
  }

  return SUCCESS;
}

static inline result_t setAttrArray(DiffMsgPtr msg, Attribute *attrArray,
				    uint8_t numAttrs)
{
  Attribute *pAttr = NULL;

  if (msg == NULL || numAttrs == 0 || numAttrs > MAX_ATT)
  {
    return FAIL;
  }

  if (msg->type == ESS_OPP_DATA)
  {
    pAttr = ((DataMessage *)(msg->data))->attributes;
    ((DataMessage *)(msg->data))->numAttrs = numAttrs;
  }
  else if (msg->type == ESS_OPP_INTEREST)
  {
    pAttr = ((InterestMessage *)(msg->data))->attributes;
    ((InterestMessage *)(msg->data))->numAttrs = numAttrs;
  }

  memcpy((char *)pAttr, (char *)attrArray, numAttrs * sizeof(Attribute));

  return SUCCESS;
}
#endif
