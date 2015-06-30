
/*
      BaseMote is used as server. Pc is used as Client.
    
      Timestamp Name          ID   When Generated
      ------------------------------------------------------------
      pcSendTime     T1   time request sent by client
      moteRecvTime   T2   time request received by server
      moteSendTime   T3   time reply sent by server
      pcRecvTime     T4   time reply received by client

   The roundtrip delay d and local clock offset t are defined as

      d = (T4 - T1) - (T2 - T3)     t = ((T2 - T1) + (T3 - T4)) / 2.    

*/ 

#include "../Common/common.h"

struct SyncMsg
{
    uint16_t commandType;
    uint16_t seqNo;
    /* when commandType = SYNC_REQUEST, moteTime denotes the current estimation of receiver's time 
     * when commandType = SYNC_REPLY,   moteTime denotes actually receiver's time 
     */ 
    uint32_t pcSendTime; 
    uint32_t moteRecvTime; 
    uint32_t moteSendTime;
    uint32_t pcRecvTime; 
             
};

enum {
  AM_SYNCMSG = 33,
  SYNC_REQUEST = 10,
  SYNC_REPLY = 20, 
  QUEUE_SIZE = 6
};

