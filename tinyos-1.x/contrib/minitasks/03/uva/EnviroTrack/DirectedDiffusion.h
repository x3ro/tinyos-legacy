
#ifndef __DD_H__
#define __DD_H__

#include "SystemParameters.h"

enum{
AM_DD_MSG = 7,
SENTINEL8Bit = 0xff,
SENTINEL16Bit = 0xffff,
DD_RANDOM_JITTER = 3,

//Jun08
DEF_DD_COMR = 150,
DEF_DD_SPARSE_DENSE_DIST = 20,



//DATALOAD_SIZE = 10,
DATALOAD_STR = 20,
DD_PAYLOAD_SIZE = 29,

MAX_NBR_LIST= 5,
MAX_INTERESTS= 5,
MAX_DATA_CACHE_LIST= 5,


// pursuer side
LONGPERIOD =0xffff,
SHORTPERIOD =151,
// To accomodate the worst interest propagation,
// The current hop is also 2, counting the circle perimeter.
MAX_PERIOD_HOPS = 2*4, 
IS_PURSUER = 1,
NOT_PURSUER = 0,

// non-pursuer interest
FORWARD_TIMEOUT = 30,
MAX_INTEREST_AGE = 301,

// source
//SRC_SEND_PERIOD = 30,

NULL_EVENTSIGNATURE = 0,
EVENTSIGNATURE= 0xdddd,

INTEREST_TYPE =0,
DATA_TYPE = 1, 

//buffered data
MAX_BUFFER_DATA_ITEMS= 5,
//RE_TRANSMIT_INTERVAL= 3,
BUFFER_DATA_TIMEOUT =4,
SAVED_TYPE = 0,
MAX_HISTORY_OF_BUFFER_DATA = 40,
END_TYPE  = 1  
};    

/*
SendOneInterestByBct
ForwardDataPacket
DataSrcSendData
ForwardOneInterestByBct

CopyPublishedData
GetInterestEntry
AddOneInterestNeighbor
GetNextCorrespondedInterestIndex
AddOneInterestEntry
printInterest

SendOneBufferDataItem

*/

//typedef uint16_t RoutingAddress_t;

typedef struct{
    
    uint16_t    interestSeq;			// sequence number
    
    uint16_t    prevHop;				// tos address
    uint16_t    dataSink;				// tos address
    
    uint8_t     hopsLeft;				// hops left
    uint8_t     hopsPassed; 			// hops passed
    
	// Jun08
    uint16_t    preHopX;			// sequence number    
    uint16_t    preHopY;				// tos address
    short		commR;
    short		maxSparseDis;
    uint8_t	nothing[12];

    
} interestLoad;


typedef struct{

    uint16_t           dataSink;				// tos address
    uint16_t           interestSeq;			// sequence number
    uint8_t   hopsLeft;
    uint8_t   hopsPassed;             // Former is hopsleft
    uint16_t  age;
    // Jun08
    //uint16_t	forward;
    short	forward;    
    
    uint8_t   nbrListIndex;
    uint16_t  nbrList[MAX_NBR_LIST];   // List of neighbors currently seen.
    uint8_t   nbrHops[MAX_NBR_LIST];

} interestEntry;

typedef struct{
  //uint16_t shDataX;				
  //uint16_t shDataY;				
  char dataStr[DATALOAD_STR];  
} DataPublished;

//typedef char DATACON[DATALOAD_STR];

typedef struct{
  
  DataPublished stDataPub;  
    
  uint16_t dataSeq;				// sequence number
  uint16_t dataSrc;				// data source
  uint16_t dataSink;				// sink
  uint16_t prevHop;				// The sender address of the packet
  
//  uint16_t shNextHop;				// The receiver address of the packet
  //char stDataPub[DATALOAD_STR]; 
  //DATACON stDataPub;
} dataLoad;

typedef struct{
  uint16_t shEventSignature;		
  uint16_t shDataSrc;
  uint16_t shDataSeq;
  uint16_t shDataSink;
} DataCacheEntry;

typedef struct{
    
//  uint8_t cType;  
  short cTimer; 
  uint8_t cHistory; 

  uint8_t  interestIndex;
  uint8_t  nextHopIndex;
  
  uint16_t dataSeq;				// sequence number
  uint16_t dataSrc;				// data source
     
  DataPublished stDataPub;
  
} bufferDataEntry;


# include "AM.h"

int8_t* DDinitRoutingMsg( TOS_MsgPtr msg, uint8_t length )
{
  if( length <= DD_PAYLOAD_SIZE )
  {
    msg->length = length;
    return msg->data;
  }
  return 0;
}

int8_t* DDpushToRoutingMsg( TOS_MsgPtr msg, uint8_t length )
{
  if( msg->length + length <= DD_PAYLOAD_SIZE )
  {
    int8_t* head = msg->data + msg->length;
    msg->length += length;
    return head;
  }
  return 0;
}

int8_t* DDpopFromRoutingMsg( TOS_MsgPtr msg, uint8_t length )
{
  if( length <= DD_PAYLOAD_SIZE )
  {
    msg->length -= length;
    return msg->data + msg->length;
  }
  return 0;
}


#endif

