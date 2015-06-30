
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "myAM.h"
#include "Ext_AM.h"
#include "msg_types.h"
#include "BeaconPacket.h"
#include "NeighborStore.h"
#include "attribute.h"
#include "OnePhasePull.h"
#include "OPPLib/DataStructures.h"
#include "NeighborBeacon.h"

#define MOTE_DEV "/dev/mote/0/tos"

#define SELECT_TIMEOUT 1// one second

#define MY_ID 1
#define MY_INITIAL_LOAD 1

#define TOS_BCAST_ADDR 0xffff

#define MAX_NUM_INTEREST_RECORDS 1
// the default expiration time minus the leeway we want to have while
// retransmitting interests...
#define EXPL_INT_PERIOD (DFLT_INTEREST_EXP_TIME - INTEREST_XMIT_MARGIN)
#define MAX_TTL TTL
// adjustment for the fields in the Ext_TOS_Msg that we have added...
// TODO: XXX: set this to 2 once we move fully to the Ext_TOS_Msg 
#define LENGTH_ADJUSTMENT 2

//typedef uint8_t STATUS; // would like to use an enum, but SUCCESS and FAIL have
                        // already been enum'd without giving that enum a type
typedef enum 
{
  FAIL = 0,
  SUCCESS = 1
} STATUS;
typedef STATUS result_t;

typedef enum
{
  FALSE = 0,
  TRUE = 1
} bool;

uint16_t myId = MY_ID;
uint16_t myLoadIndex = MY_INITIAL_LOAD;
char *myProgName = NULL;
uint16_t myDiffSeqNum = 0;
// TODO: change to myBeaconSeqNum
uint16_t mySeq = 0;

typedef struct InterestRecord 
{
  int expPeriod;
  struct timeval lastExplIntTime;

  // numAttrs is the field that indicates whether or not there's an
  // interest... if it's 0, it's an empty spot because there can be no
  // interest with 0 attributes
  int numAttrs; 

  Attribute attributes[MAX_ATT];
} InterestRecord;

InterestRecord interestRecords[MAX_NUM_INTEREST_RECORDS];
bool printMineOnly = 0;

//------------- BEGIN ported from NeighborBeaconM port --------------

typedef struct ExportedLossData
{
  uint32_t lossBitmap;// 31 bits are used in this bitmap... the highest
                      // bit is used to indicate if the window is full or
                      // not; this is done to avoid the need for a
                      // bitCount
  uint16_t endSeq;
  uint8_t incarnation;
} ExportedLossData; // packed to save space...

typedef struct LossData 
{
  uint16_t neighborId;
  uint8_t numSilentPeriods;
  ExportedLossData exportedLossData;
  uint16_t inLoss;
  uint16_t outLoss;
} LossData; 

LossData neighborCache[MAX_NUM_NEIGHBORS];
NeighborIterator iterator;
uint8_t alpha = DEFAULT_ALPHA; // expressed in percentage => 2bits of decimal
uint8_t myIncarnation;
uint16_t beaconInterval = BEACON_INTERVAL;
uint8_t lossCalcIntervalCount = 0;
struct timeval lastBeaconSendTime;

//------------- END ported from NeighborBeaconM port --------------

static void dbg(const char *format, ...);

//------------ BEGIN Function Prototypes ---------------

void printUsage(void);
void printAttributes(Attribute *array, 
                     uint8_t num);
void printInterestPacket(Ext_TOS_MsgPtr extTosMsg);
void printDataPacket(Ext_TOS_MsgPtr extTosMsg);
void printBeaconPacket(Ext_TOS_MsgPtr extTosMsg);
void printTestPacket(Ext_TOS_MsgPtr extTosMsg);
void printUnknownPacket(Ext_TOS_MsgPtr extTosMsg);
STATUS initDataStructures(void);
STATUS handleInterestTimers(struct timeval currTime, 
                            int tosFd);
STATUS sendInterestMsg(InterestRecord *record, 
                       int tosFd);
//------------------------------------------------------
uint8_t bitmapSize(uint32_t bitmap);
char *intToBitmap(uint32_t num);
int findNeighborCacheEntry(uint16_t id);
uint8_t getNumNeighbors(void);
uint16_t getNextNeighbor(NeighborIterator *iterator);
int findFreeNeighborCacheEntry(void);
STATUS getExportedLossData(uint16_t id, 
                           ExportedLossData *exportedLossData);
STATUS setExportedLossData(uint16_t id, 
                           ExportedLossData *exportedLossData);
STATUS getInLoss(uint16_t id,
                 uint16_t *inLoss);
STATUS setInLoss(uint16_t id,
                 uint16_t inLoss);
STATUS getOutLoss(uint16_t id,
                 uint16_t *outLoss);
STATUS setOutLoss(uint16_t id,
                 uint16_t outLoss);
void calculateLossRate(uint16_t id);
void updateNeighborSeq(uint16_t id, uint16_t seq, uint8_t incarnation);
void processSavedMsg(Ext_TOS_Msg *savedMsg);
STATUS sendBeacon(struct timeval currTime,
                  int tosFd);
void ageNeighbors(void);
void calculateAllLossRates(void);

//------------- END Function Prototypes -----------------


/* what should diffsink do for now:
 * - periodically send out the following interest out 
 *   - with "CLASS IS INTEREST", "ESS_LOAD_KEY IS 1", 
 *     "ESS_CLUSTERHEAD_KEY EQ <MYID>" and "CLASS EQ DATA" to get back all 
 *     data from motes that have chosen this clusterhead (with of course 
 *     new sequence numbers each time)
 *   - print out packets with "ESS_CLUSTERHEAD_KEY IS <MYID>" in human readable 
 *     form
 *   - be as extendable a code as possible with a few hours of impl. time
 *   - support for Neighborlist functionality....
 *
 * what can be done after May 12:
 *   - eliminate duplicates (on a per source basis) using a data cache
 *   - join the pub/sub bus to export this streaming data
 *   - think of tracking loss rate of data per source (not 1+1=2 because the 
 *     sequence number stream is not increasing in increments of 1) 
 */
int main(int argc, 
         char * argv[]) 
{
  char dev[255]=MOTE_DEV;
  int tosFd = -1;
  int status = 0;
  fd_set readFds;
  Ext_TOS_Msg msg;	
  struct timeval selectPeriod;
  struct timeval currTime;
  int retVal = 0;
  // for getopt
  extern char *optarg;
  extern int optind, opterr, optopt;
  int optChar = 0;
  bool myIdFound = 0;

  myProgName = argv[0];

  //---------- BEGIN command line option processing ----------
  while (optChar != -1)
  {
    optChar = getopt(argc, argv, "mi:");
    switch (optChar)
    {
      // -m: to enable "print mine only"
    case 'm':
      printf("%s: print mine only enabled\n", 
	     myProgName);
      printMineOnly = 1; 
      break;

    case 'i':
      if (optarg != NULL)
      {
	myId = atoi(optarg);
	myIdFound = 1;
      }
      break;
  
    case '?':
      printUsage();
      exit(1);

    case -1:
      break;
    }
  }
  if (! myIdFound)
  {
    printUsage();
    exit(1);
  }

  printf("My ID is %d and I'm printing out %s\n", 
	 myId,
	 printMineOnly ? "only my stuff" : "everything");

  //---------- END command line option processing ----------

  if (FAIL == initDataStructures())
  {
    fprintf(stderr, 
            "%s: initialization failed!\n", 
            myProgName);
    exit(1);
  }

  FD_ZERO(&readFds);

  tosFd = open(dev, 
               O_RDWR);

  if (tosFd < 0) 
  {
    fprintf(stderr, "failed to open %s\n", dev);
    exit(1);
  }

  while (1) 
  {

    // Set fd in fd_set
    FD_ZERO(&readFds);
    FD_SET(tosFd, 
           &readFds);

    selectPeriod.tv_sec = SELECT_TIMEOUT;
    selectPeriod.tv_usec = 0;

    retVal = select(tosFd + 1, 
                    &readFds, 
                    NULL, 
                    NULL, 
                    &selectPeriod);

    if (retVal < 0)
    {
      perror("select failed");
      exit(1);
    }

    // If there's dat from socket, read and process it
    if (FD_ISSET(tosFd, 
                 &readFds))
    {
      status = read(tosFd, 
                    &msg, 
                    sizeof(msg));

      // applying reverse adjustment...
      msg.length -= LENGTH_ADJUSTMENT;

      if (status == sizeof(msg)) 
      {
        if (msg.type == ESS_OPP_INTEREST)
        {
          printInterestPacket(&msg);
        }
        else if (msg.type == ESS_OPP_DATA)
        {
          printDataPacket(&msg);
        }
        else if (msg.type == MSG_NEIGHBOR_BEACON)
        {
          processSavedMsg(&msg);
          printBeaconPacket(&msg);
        }
        else if (msg.type == MSG_NEIGHBOR_TEST)
        {
          printTestPacket(&msg);
        }
        else
        {
          printUnknownPacket(&msg);
        }
      }
      else 
      {
        perror("read failed");
        exit(1);
      }

      fflush(NULL);
    }

    gettimeofday(&currTime, NULL);

    if (currTime.tv_sec - lastBeaconSendTime.tv_sec >= BEACON_INTERVAL / 1000)
    {
      // this contains code from Timer.fired...
      if (FAIL == sendBeacon(currTime, 
                            tosFd))
      {
        fprintf(stderr,
                "%s: couldn't send beacon... bailing out\n", 
                myProgName);
      }

      lossCalcIntervalCount++;
      if (lossCalcIntervalCount == LOSS_CALC_INTERVAL)
      {
        lossCalcIntervalCount = 0;
        calculateAllLossRates();
      }

      ageNeighbors();
      lastBeaconSendTime = currTime;
    }

    if (FAIL == handleInterestTimers(currTime, 
                                     tosFd))
    {
      // TODO: remove exit
      exit(1);
    }
  }

  return 0;
}

void printUsage(void)
{
  printf("usage: %s -i <my-id> [-m]\n", myProgName);
}

void printAttributes(Attribute *array, 
                     uint8_t num)
{
  uint8_t i = 0;

  printf("-------attributes-------\n");
  for (i = 0; i < num; i++)
  {
    printf("#%d: key: %d op: %d value: %d\n", 
	   i,
           array[i].key,
	   array[i].op, 
           array[i].value);
  }
  printf("------------------------\n");
}

void printInterestPacket(Ext_TOS_MsgPtr extTosMsg)
{
  InterestMessage *intMsg;

  intMsg = (InterestMessage *)extTosMsg->data;
  printf("INTEREST: sink: %d dest: %d seq: %d prev: %d ttl: %d exp: %d len: %d\n",
	  intMsg->sink, 
          extTosMsg->addr,
          intMsg->seqNum, 
          intMsg->prevHop, 
	  intMsg->ttl, 
          intMsg->expiration,
          extTosMsg->length);
  printAttributes(intMsg->attributes, 
                  intMsg->numAttrs);
  
  printf("\n");
}

void printDataPacket(Ext_TOS_MsgPtr extTosMsg)
{
  DataMessage *dataMsg;
  int numAttrs;
  int i;
  bool mine = FALSE;


  dataMsg = (DataMessage *)extTosMsg->data;

  if (extTosMsg->addr == myId)
  {
    mine = TRUE;
  }
  else if (TOS_BCAST_ADDR == extTosMsg->addr)
  // this shouldn't really happen since all data in OPP is unicast towards
  // the sink
  {
    printf("Recieved broadcast data message! shouldn't happen!!\n");

    // print out only if it's for me if the printMineOnly flag is set...
    numAttrs = dataMsg->numAttrs;
    if (numAttrs < 0 || numAttrs > MAX_ATT)
    {
      numAttrs = MAX_ATT;
    }
    for (i = 0; i < dataMsg->numAttrs; i++)
    {
      if (ESS_CLUSTERHEAD_KEY == dataMsg->attributes[i].key &&
          IS == dataMsg->attributes[i].op)
      {
        if (dataMsg->attributes[i].value == myId)
        {
          mine = TRUE;
        }
        else
        {
          mine = FALSE;
        }
      }
    }
  }

  if (TRUE == printMineOnly && 
      FALSE == mine)
  {
    return;
  }
  printf("DATA: src: %d dest: %d seq: %d prev: %d hops2src: %d len: %d\n",
	  dataMsg->source, 
          extTosMsg->addr,
          dataMsg->seqNum, 
          dataMsg->prevHop, 
	  dataMsg->hopsToSrc,
          extTosMsg->length);

  printAttributes(dataMsg->attributes, 
                  dataMsg->numAttrs);
  
  printf("\n");
}

void printBeaconPacket(Ext_TOS_MsgPtr extTosMsg)
{
  BeaconPacket *beacon;
  int i;

  beacon = (BeaconPacket *)extTosMsg->data;
  printf ("BEACON: src: %d dest: %d seq: %d numRecords: %d len: %d", 
          extTosMsg->saddr, 
          extTosMsg->addr,
          beacon->seq, 
          beacon->numRecords,
          extTosMsg->length);
  
  for (i = 0; i < beacon->numRecords; i++)
  {
    uint16_t id;
    uint16_t loss;

    memcpy((char *)&id, 
           &beacon->data[4 * i], 
           2);

    memcpy((char *)&loss, 
           &beacon->data[4 * i + 2], 
           2);

    printf ("\n\tneighbor: %d loss: %d", 
            id, 
            loss);
  }

  printf("\n\n");
}

void printTestPacket(Ext_TOS_MsgPtr extTosMsg)
{
  uint8_t i;
  uint16_t id;

  printf ("TEST: src: %d numRecords: %d\n\t", 
          extTosMsg->saddr, 
          extTosMsg->data[0]);
  
  if (extTosMsg->data[0] > MAX_NUM_NEIGHBORS)
  {
    extTosMsg->data[0] = MAX_NUM_NEIGHBORS;
  }

  for (i = 0; i < extTosMsg->data[0]; i++)
  {
    memcpy((char *)&id, 
           &extTosMsg->data[2 * i + 1], 
           2);

    printf ("%d  ", 
            id);
  }

  printf("\n");
}

void printUnknownPacket(Ext_TOS_MsgPtr extTosMsg)
{
  printf("UNKNOWN: src: %d dest: %d type: %d length: %d\n",
	  extTosMsg->saddr, 
          extTosMsg->addr, 
          extTosMsg->type, 
	  extTosMsg->length);
}

STATUS initDataStructures(void)
{
  struct timeval currTime;
  int numAttrs = 0;

  if (0 > gettimeofday(&currTime, 
                       NULL))
  {
    perror("gettimeofday failed");
    return FAIL;
  }
  
  //--------- BEGIN initialization of NeighborBeaconM stuff---------
  // as though it's now time to send a beacon...
  lastBeaconSendTime.tv_sec = currTime.tv_sec - BEACON_INTERVAL;
  lastBeaconSendTime.tv_usec = currTime.tv_usec;
  lossCalcIntervalCount = 0;
  mySeq = 0;
  beaconInterval = BEACON_INTERVAL;
  alpha = DEFAULT_ALPHA;
  iterator = 0;
  myIncarnation = 0;
  
  memset((char *)neighborCache, 0, sizeof(neighborCache));
  //--------- END initialization of NeighborBeaconM stuff---------

  //--------- BEGIN initialization of interestRecords ---------

  // for now, statically configure interest (there's only one)
  // shabby but good for a placeholder..

  memset((char *)interestRecords, 
         0,
         sizeof(InterestRecord) * MAX_NUM_INTEREST_RECORDS);

  interestRecords[0].expPeriod = EXPL_INT_PERIOD;
  // as though we sent an expl. interest one interest period ago
  interestRecords[0].lastExplIntTime.tv_sec = currTime.tv_sec - 
                                                 EXPL_INT_PERIOD;
  interestRecords[0].lastExplIntTime.tv_usec = 0;

  numAttrs = 0;
  interestRecords[0].attributes[numAttrs].key = CLASS;
  interestRecords[0].attributes[numAttrs].op = IS;
  interestRecords[0].attributes[numAttrs].value = INTEREST;

  numAttrs++;

  if (numAttrs >= MAX_ATT)
  {
    fprintf(stderr, 
            "%s: the max. number of attributes is too less!\n", 
            myProgName);
    return FAIL;
  }
  interestRecords[0].attributes[numAttrs].key = ESS_CLUSTERHEAD_KEY;
  interestRecords[0].attributes[numAttrs].op = EQ;
  interestRecords[0].attributes[numAttrs].value = myId;
  numAttrs++;

  /*
  if (numAttrs >= MAX_ATT)
  {
    fprintf(stderr, 
            "%s: the max. number of attributes is too less!\n", 
            myProgName);
    return FAIL;
  }
  interestRecords[0].attributes[numAttrs].key = TEMP;
  interestRecords[0].attributes[numAttrs].op = EQ_ANY;
  interestRecords[0].attributes[numAttrs].value = 40;
  numAttrs++;
  */

  if (numAttrs >= MAX_ATT)
  {
    fprintf(stderr,
            "%s: the max. number of attributes is too less!\n", 
            myProgName);
    return FAIL;
  }
  interestRecords[0].attributes[numAttrs].key = ESS_LOAD_KEY;
  interestRecords[0].attributes[numAttrs].op = IS;
  interestRecords[0].attributes[numAttrs].value = myLoadIndex;
  numAttrs++;


  interestRecords[0].numAttrs = numAttrs;

  //------- END initialization of interestRecords ---------

  return SUCCESS;
}

STATUS handleInterestTimers(struct timeval currTime, 
                            int tosFd)
{
  int i = 0;
  long diff = 0;

  for (i = 0; i < MAX_NUM_INTEREST_RECORDS; i++)
  {
    if (0 == interestRecords[i].numAttrs)
    {
      // it's an empty slot, so just skip to the next one...
      continue;
    }
    diff = currTime.tv_sec - interestRecords[i].lastExplIntTime.tv_sec; 
    if (diff >= interestRecords[i].expPeriod)
    {
      dbg("Trying to send expl. interest...\n");
      dbg("currTime = %ld, lastExplIntTime = %ld, diff = %ld\n",
          currTime.tv_sec, 
          interestRecords[i].lastExplIntTime.tv_sec, 
          diff);
      if (FAIL == sendInterestMsg(&(interestRecords[i]), tosFd))
      {
        fprintf(stderr, "%s: write to TOS interface failed!\n", myProgName);
        return FAIL;
      }
      // gotta send out an interest...
      interestRecords[i].lastExplIntTime = currTime;
    }
  }
  return SUCCESS;
}


STATUS sendInterestMsg(InterestRecord *record, 
                       int tosFd)
{
  Ext_TOS_Msg extTosMsg;
  InterestMessage *intMsg;
  int numWritten = 0;

  extTosMsg.addr = TOS_BCAST_ADDR;
  extTosMsg.type = ESS_OPP_INTEREST;
  extTosMsg.group = OPP_LOCAL_GROUP;
  extTosMsg.length = sizeof(InterestMessage); // LENGTH_ADJUSTMENT added later
  extTosMsg.saddr = MY_ID;

  intMsg = (InterestMessage *)extTosMsg.data;

  intMsg->seqNum = myDiffSeqNum++;
  intMsg->sink = myId;
  intMsg->prevHop = myId;
  intMsg->ttl = MAX_TTL;
  intMsg->expiration = DFLT_INTEREST_EXP_TIME;
  intMsg->numAttrs = record->numAttrs;
  memcpy((char *)intMsg->attributes,
         (char *)record->attributes,
         MAX_ATT * sizeof(Attribute));

  dbg("Sending INTEREST: myId = %d\n", myId);
  printInterestPacket(&extTosMsg);

  // we are doing this here just to make sure we print out the right value of
  // length...
  extTosMsg.length += LENGTH_ADJUSTMENT;

  numWritten = write(tosFd,
                     (char *)&extTosMsg,
                     sizeof(Ext_TOS_Msg));

  if (numWritten < sizeof(Ext_TOS_Msg))
  {
    if (numWritten < 0)
    {
      perror("write failed");
    }
    else
    {
      fprintf(stderr,
              "%s: write to TOS interface failed!\n",
              myProgName);
    }
    return FAIL;
  }

  return SUCCESS;
}

//------------ BEGIN ported from NeighborBeaconM.nc -------------

// calculate total number of valid bits in the bitmap;
// NOTE: the highest order bit is used to indicate whether or not the
// bitmap is "full"... if it is 0 (meaning the bitmap is not full), the
// bitmap is as long as position of the highest order bit set.  
// NOTE: The maximum size of the bitmap is therefore 31 and not 32
uint8_t bitmapSize(uint32_t bitmap)
{
  uint8_t i;

  if (bitmap == 0)
  {
    return 0; // watch out for this case
  }

  if (bitmap & MS_BIT) // highest bit set
  {
    return BITMAP_SIZE; // read note above
  }
  else // the highest order bit is not set
  {
    // find the position of the highest one and return it
    bitmap <<= 1;
    for (i = 1; i < BITMAP_SIZE; i++)
    {
      if (bitmap & MS_BIT)
      {
        return (BITMAP_SIZE + 1 - i);
      }
      bitmap <<= 1;
    }
  }
  return 0; // should never come here...
}


char *intToBitmap(uint32_t num)
{
  int i;
  static char numStr[33];

  for (i = 0; i < 32; i++)
  {
    if (num & MS_BIT)
    {
      numStr[i] = '1';
    }
    else
    {
      numStr[i] = '0';
    }
    num <<= 1;
  }
  numStr[32] = 0;

  return numStr;
}

// return 0..MAX_NUM_NEIGHBORS - 1 if found, -1 if not
int findNeighborCacheEntry(uint16_t id)
{
  int i = 0;

  for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
  {
    if (neighborCache[i].neighborId == id)
    {
      return i;
    }
  }
  return -1;
}

uint8_t getNumNeighbors(void)
{
  int i = 0;
  int numNeighbors = 0;

  numNeighbors = 0;
  for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
  {
    if (NULL_NODE_ID != neighborCache[i].neighborId)
    {
      numNeighbors++;
    }
  }

  return numNeighbors;
  
}

uint16_t getNextNeighbor(NeighborIterator *iterator)
{
  uint8_t i = 0;

  // sanity checks...
  if (iterator == NULL)
  {
    return 0;
  }

  // remember: iterator is a uint..
  if (*iterator >= MAX_NUM_NEIGHBORS)
  {
    *iterator = 0;
  }

  for (i = *iterator; i < MAX_NUM_NEIGHBORS; i++)
  {
    if (neighborCache[i].neighborId != NULL_NEIGHBOR_ID) 
    {
      // set the iterator to the next position...
      *iterator = ((i + 1) >= MAX_NUM_NEIGHBORS ? 0 : (i + 1));
      return neighborCache[i].neighborId;
    }
  }
  // Could not find non-zero neighbor until end of list... let's search
  // before the *iterator position
  // This code implements wrap-around. 
  for (i = 0; i < *iterator; i++)
  {
    if (neighborCache[i].neighborId != NULL_NEIGHBOR_ID) 
    {
      // set the iterator to the next position...
      *iterator = ((i + 1) >= MAX_NUM_NEIGHBORS ? 0 : (i + 1));
      return neighborCache[i].neighborId;
    }
  }

  // This corresponds to there being no neighbor records...
  return 0;
}


// return 0..MAX_NUM_NEIGHBORS - 1 if available, -1 if not
int findFreeNeighborCacheEntry(void)
{
  int i = 0;

  for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
  {
    if (NULL_NODE_ID == neighborCache[i].neighborId)
    {
      return i;
    }
  }

  return -1;
}

STATUS getExportedLossData(uint16_t id, 
                           ExportedLossData *exportedLossData)
{
  int i = 0;

  i = findNeighborCacheEntry(id);

  if (i >= 0)
  {
    *exportedLossData = neighborCache[i].exportedLossData;
    return SUCCESS;
  }

  return FAIL;
}


STATUS setExportedLossData(uint16_t id, 
                           ExportedLossData *exportedLossData)
{
  int i = 0;

  i = findNeighborCacheEntry(id);

  if (i >= 0)
  {
    neighborCache[i].exportedLossData = *exportedLossData;
    return SUCCESS;
  }

  // not found, try to allocate a new entry
  i = findFreeNeighborCacheEntry();
  if (i < 0)
  {
    return FAIL;
  }

  memset((char *)&(neighborCache[i]), 0, sizeof(LossData));
  neighborCache[i].neighborId = id;
  neighborCache[i].exportedLossData = *exportedLossData;
  return SUCCESS;
}

STATUS getInLoss(uint16_t id,
                 uint16_t *inLoss)
{
  int i = 0;

  i = findNeighborCacheEntry(id);

  if (i >= 0)
  {
    *inLoss = neighborCache[i].inLoss;
    return SUCCESS;
  }
  return FAIL;
}

STATUS setInLoss(uint16_t id,
                 uint16_t inLoss)
{
  int i = 0;

  i = findNeighborCacheEntry(id);

  if (i >= 0)
  {
    neighborCache[i].inLoss = inLoss;
    return SUCCESS;
  }
  return FAIL;
}

STATUS getOutLoss(uint16_t id,
                 uint16_t *outLoss)
{
  int i = 0;

  i = findNeighborCacheEntry(id);

  if (i >= 0)
  {
    *outLoss = neighborCache[i].outLoss;
    return SUCCESS;
  }
  return FAIL;
}

STATUS setOutLoss(uint16_t id,
                 uint16_t outLoss)
{
  int i = 0;

  i = findNeighborCacheEntry(id);

  if (i >= 0)
  {
    neighborCache[i].outLoss = outLoss;
    return SUCCESS;
  }
  return FAIL;
}

void calculateLossRate(uint16_t id)
{
  result_t retVal;
  uint8_t i;
  uint8_t count;
  uint8_t numBits;
  uint16_t loss;
  uint16_t currLoss; 
  uint32_t bitmap;
  ExportedLossData exportedData;

  count = 0;

  if (id == 0)
  {
    // dbg();
    return;
  }

  retVal = getExportedLossData(id, &exportedData);

  if (retVal == FAIL)
  {
    dbg("calculateLossRate: getNeighborBlob failed!\n");
    return;
  }
  
  // NOTE: the way the bitmap is used is thus: the highest bit indicates
  // if the window is "full" or not. 1 indicates that the bitmap window
  // is full -- meaning 31 bits.  0 indicates that the window is not yet
  // full and its length is given by the position of the highest 1
  bitmap = exportedData.lossBitmap;
  for (i = 0, numBits = 0; i < BITMAP_SIZE + 1; i++)
  {
    if (bitmap & 0x01)
    {
      count++;
      numBits = i + 1; // to count the highest 1 position
    }
    bitmap >>= 1; // right-shift by 1
  }
  if (numBits > BITMAP_SIZE)
  {
    numBits = BITMAP_SIZE; // due to the way the bitmap is used.
    count--; // to not count the "full" bit
  }
  if (numBits == 0) // sanity check
  {
    return;
  }

  currLoss = (uint16_t)(1000 - (((uint32_t)count * (uint32_t)1000) / 
                        (uint32_t)numBits));

  if (SUCCESS == getInLoss(id, &loss))
  {
    int16_t oldLoss;

    oldLoss = loss;
    loss = (uint16_t) (((uint32_t)currLoss * (uint32_t)alpha) / (uint32_t)100 + 
                        ((((uint32_t)loss) * (uint32_t)(100 - alpha)) / 
                        (uint32_t)100)); 
    dbg("calcLoss: neighbor: %d, count: %d, numBits: %d, "
        "currLoss: %d, oldLoss: %d, loss: %d\n", id, count, numBits,
        currLoss, oldLoss, loss);
  }
  else
  {
    dbg("calculateLossRate: getNeighborMetric16 for "
        "NS_16BIT_IN_LOSS failed!\n");
    loss = currLoss;
  }

  setInLoss(id, loss);

  // important: reset bitmap
  exportedData.lossBitmap = 0;

  retVal = setExportedLossData(id, &exportedData);

  if (retVal == FAIL)
  {
    dbg("calculateLossRate: setNeighborBlob failed!\n");
    return;
  }
}

void updateNeighborSeq(uint16_t id, uint16_t seq, uint8_t incarnation)
{
  uint8_t i;
  uint16_t diff;
  uint8_t bitmapFull;
  ExportedLossData exportedData;
  
  // Find matching cache entry
  for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
  {
    if (neighborCache[i].neighborId == id)
    {
      break;
    }
  }

  // coundn't find one..
  if (i == MAX_NUM_NEIGHBORS)
  {
    // is one free?
    dbg("updateNeighbor: neighbor %d NOT found in cache\n", id);
    for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (neighborCache[i].neighborId == 0)
      {

        // to keep the table here and the table in the NeighborStore
        // consistent...
        exportedData.lossBitmap = 0x01;
        exportedData.endSeq = seq;
        exportedData.incarnation = incarnation;

        dbg("updateNeighbor: writing info about node %d to "
            "store\n", id);

        // memset takes care of wiping out any old data
        memset((char *)&neighborCache[i], 0, sizeof(LossData));
        neighborCache[i].neighborId = id;
        neighborCache[i].numSilentPeriods = 0;
        neighborCache[i].exportedLossData = exportedData;

        return;
      }
    }
  }
  // none free, so bail out
  if (i == MAX_NUM_NEIGHBORS)
  {
    return;
  }

  // now, note that i points to a valid record for this neighbor
  exportedData = neighborCache[i].exportedLossData;

  dbg("updateNeighbor: getNeighborBlob: bmp = %s, endSeq = %d"
      " inc = %d\n", intToBitmap(exportedData.lossBitmap), 
      exportedData.endSeq, exportedData.incarnation);

  // is the seq number more recent? 
  if (SEQ_GT(seq, exportedData.endSeq) || 
      (incarnation > exportedData.incarnation) ||
      SEQ_ABS_DIFF(seq, exportedData.endSeq) >= SEQ_GAP_TOLERANCE)
  {
    if (incarnation > exportedData.incarnation)
    {
      // flush bitmap
      neighborCache[i].numSilentPeriods = 0;

      exportedData.incarnation = incarnation;
      exportedData.lossBitmap = 0x01;
      exportedData.endSeq = seq;

      neighborCache[i].exportedLossData = exportedData;

      return;
    }

    // reset idle count
    neighborCache[i].numSilentPeriods = 0;

    diff = SEQ_ABS_DIFF(seq, exportedData.endSeq);

    if (diff > MIN(SEQ_GAP_TOLERANCE, BITMAP_SIZE))
    // this means that it is a (1) reboot  (2) or a long loss of
    // connectivity.. if it was the former, there is no loss penalty...
    // if it's the latter, ageing anyway would have taken care of it...
    // so be a little lax. 
    {
      exportedData.lossBitmap = 0; // flush the bitmap, effectively
      exportedData.endSeq = seq;

      dbg("updateNeighbor: diff (%d) > SEQ_GAP_INTERVAL!! "
          "resetting\n", diff);
    }
    // usual case...
    else if (SEQ_GT(seq, exportedData.endSeq))
    {
      // update lossBitmap
      bitmapFull = 0;

      if (bitmapSize(exportedData.lossBitmap) + diff  >= BITMAP_SIZE)
      {
        dbg("updateNeighbor: bitmap overflowed! bitmapSize = %d; diff = %d\n", bitmapSize(exportedData.lossBitmap), diff);
        bitmapFull = 1;
      }
      exportedData.lossBitmap = exportedData.lossBitmap << diff | 0x01;
      if (bitmapFull)
      {
        exportedData.lossBitmap |= MS_BIT;
      }
      exportedData.endSeq = seq;
    }
    // the other case that remains is if the seqNum rolled back
    // by less than SEQ_GAP_TOLERANCE... if so, we can't say if it's an
    // old beacon or a reboot... so, we just have to wait till the seq
    // num catches up... and we'll ignore it => a certain penalty is
    // paid through ageing, although it shouldn't be too much

  }

  neighborCache[i].exportedLossData = exportedData;

  dbg("updateNeighbor: setNeighborBlob: bmp = %s, endSeq = %d"
      " inc = %d\n", intToBitmap(exportedData.lossBitmap), exportedData.endSeq,
      exportedData.incarnation);
  return;
}


// savedMsg is just to preserve the code... and the name itself doesn't mean
// much
void processSavedMsg(Ext_TOS_Msg *savedMsg)
{
  BeaconPacket *beacon;
  uint8_t itemCount;
  uint8_t dataOffset;
  uint16_t neighborId;
  uint16_t reportedLoss;
  result_t retVal;

  beacon = (BeaconPacket *)savedMsg->data;

  if (beacon->source == 0)
  {
    return;
  }
  
  dbg("processSavedMsg: received msg from %d (%d); seq = %d; "
      "numRecords = %d\n", 
      beacon->source, savedMsg->saddr, beacon->seq, beacon->numRecords);

  updateNeighborSeq(beacon->source, beacon->seq, beacon->incarnation);
  
  dataOffset = sizeof(BeaconPacket);
  itemCount = 0;
  while ((itemCount < beacon->numRecords) && 
          // sanity check to see if we are going to fall off 
          // the data part of Ext_TOS_Msg
          // 2 bytes for neighborId and 2 for metric
          (dataOffset + 4 < savedMsg->length))
  {
    // 2 bytes for neighborId and 2 for metric
    // memcpy below is crucial
    memcpy((char *)&neighborId, &beacon->data[itemCount * 4], 2);
    memcpy((char *)&reportedLoss, &beacon->data[itemCount * 4 + 2], 2);

    dbg("                 nId = %d loss = %d\n", 
        neighborId, reportedLoss);
    
    // we care only about what that neighbor says about us 
    if (neighborId == myId)
    {
      retVal = setOutLoss(beacon->source, reportedLoss);
      if (retVal == FAIL)
      {
        dbg("processSavedMsg: setNeighborMetric16 FAILED for "
            "neighbor %d\n", beacon->source);
      }
    }

    dataOffset += 4;
    itemCount++;
  }
}


STATUS sendBeacon(struct timeval currTime,
                  int tosFd)
{
  Ext_TOS_Msg sendBuffer;
  Ext_TOS_MsgPtr msgPtr;
  BeaconPacket *beacon;
  uint8_t offset;
  uint16_t id;
  uint16_t loss;
  uint8_t numNeighbors;
  int retVal = 0;

#ifdef NB_TESTING
  // TODO: XXX REMOVE!!! random drops to aid testing.
  if (((call Random.rand()) & 0x0000000f) > 8) 
  // roughly 1/2 probability of drop
  {
    // effectively not send a beacon...
    dbg("sendBeacon: not sending beacon %d\n", mySeq);
    mySeq++;
    return SUCCESS;
  }
#endif

  msgPtr = &sendBuffer;
  beacon = (BeaconPacket *)(msgPtr->data);
  msgPtr->saddr = myId;
  msgPtr->addr = TOS_BCAST_ADDR; // broadcast
  msgPtr->group = NB_AM_GROUP;
  msgPtr->length = NB_MAX_PKT_SIZE; 
  // LENGTH_ADJUSTMENT needs to be added... which is done later, but before
  // sending the packet..
  msgPtr->type = MSG_NEIGHBOR_BEACON;
  // type will be set as in the configuration file...

  beacon->source = myId;
  beacon->seq = mySeq++;
  beacon->incarnation = myIncarnation;
  beacon->numRecords = 0;
  
  dbg("sendBeacon: sending: myId = %d (%d), seq = %d\n", 
      beacon->source, msgPtr->saddr, mySeq);
  numNeighbors = getNumNeighbors();
  offset = 0;
  while (sizeof(BeaconPacket) + offset + 4 < NB_MAX_PKT_SIZE &&
          // this would make sure we don't add a neighbor more than once
          beacon->numRecords < numNeighbors)
  {
    id = getNextNeighbor(&iterator);
    if (id == 0)
    {
      // meaning there are no neighbors!!
      dbg("sendBeacon: no neighbors\n");
      break;
    }

    if (FAIL == getInLoss(id, &loss))
    {
      // shouldn't happen... since there was a preceding call to
      // getNextNeighbor...
      dbg("sendBeacon: getNeighborMetric16 failed!\n");
      break;
    }

    // TODO: the real safe way of making sure that there are no duplicate
    // neighbor records in the beacon packet is to check if the records
    // so far don't already include the neighbor returned by
    // getNextNeighbor();

    // memcpy below is very important
    dbg("            nId = %d, loss = %d\n", id, loss);
    memcpy(&beacon->data[offset], (char *)&id, 2);
    memcpy(&beacon->data[offset + 2], (char *)&loss, 2);
    offset += 4;
    beacon->numRecords++;
  }


  //if (FAIL == call Enqueue.enqueue((TOS_MsgPtr)msgPtr))
  printBeaconPacket(msgPtr);

  // adding length adjustment now, so that the packet is printed out correctly
  msgPtr->length += LENGTH_ADJUSTMENT; 

  retVal = write(tosFd, (char *)msgPtr, sizeof(Ext_TOS_Msg));
  if (retVal < sizeof(Ext_TOS_Msg))
  {
    return FAIL;
  }
  
  dbg("sendBeacon: send succeeded\n");
  return SUCCESS;
}

void ageNeighbors(void)
{
  uint8_t i;
  uint16_t loss = 0;

  // increment numSilentPeriods
  for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
  {
    if (neighborCache[i].neighborId == 0)
    {
      continue;
    }

    // increment number of silent periods for all... this will be reset
    // upon packet arrival 
    neighborCache[i].numSilentPeriods++;

    loss = neighborCache[i].inLoss;

    // if loss value is the limit... remove neighbor... the below code
    // would mean one time period of delay between hitting LOSS_MAX and
    // removing of the neighbor from cache and from store.
    if (loss >= LOSS_MAX)
    {
      // simple invalidation
      dbg("ageNeighbors: removing neighbor = %d\n",
          neighborCache[i].neighborId);
      memset((char *)&neighborCache[i], 0, sizeof(struct LossData));
      continue;
    }

    // if the neighbor hasn't responded in the last so many time periods
    // the ">" below is important... because if numSilentPeriods is 2, it
    // guarantees that there's only 1 period where nothing was heard.
    if (neighborCache[i].numSilentPeriods > AGE_SILENT_PERIOD_THRESHOLD)
    {
      // increment loss rate
      loss += AGE_LOSS_INCREMENT;
      if (loss > LOSS_MAX)
      {
        loss = LOSS_MAX;
      }
      dbg("ageNeighbors: incrementing loss for %d; new loss = %d\n",
          neighborCache[i].neighborId, loss);
      // write it to store...
      neighborCache[i].inLoss = loss;
    }
  }
}

void calculateAllLossRates(void)
{
  int i;
  
  for (i = 0; i < MAX_NUM_NEIGHBORS; i++)
  {
    if ((neighborCache[i].neighborId != 0) &&
        (neighborCache[i].numSilentPeriods <= LOSS_CALC_INTERVAL))
    // the second condition is to make sure that we have at least some
    // new packets and are not calculating the loss on previous data that
    // we've already used to calculate loss rate
    {
      {
        ExportedLossData data;

        data = neighborCache[i].exportedLossData;
        dbg("calcLoss: neighbor: %d bmp: %s, endseq: %d, inc: %d\n",
            neighborCache[i].neighborId, intToBitmap(data.lossBitmap), 
            data.endSeq, data.incarnation);

      }

      // TODO: this has a loop through all neighbor cache entries as well, so
      // to speak... so watch out!
      calculateLossRate(neighborCache[i].neighborId);

      {
        uint16_t in, out;

        getInLoss(neighborCache[i].neighborId, &in);
        getOutLoss(neighborCache[i].neighborId, &out);
        dbg("          inLoss: %d, outLoss: %d\n",
            in, out);
      }
    }
  }
}

//------------ END ported from NeighborBeaconM.nc -------------

#ifdef DEBUG
static void dbg(const char *format, ...) 
{ 
  va_list args;
  va_start(args, format); 
  vfprintf(stdout, format, args);
  va_end(args);
}
#else
static void dbg(const char *format, ...) 
{ 
}
#endif
