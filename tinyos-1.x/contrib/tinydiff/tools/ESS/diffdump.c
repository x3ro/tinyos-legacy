
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

#include "myAM.h"
#include "Ext_AM.h"
#include "msg_types.h"
#include "BeaconPacket.h"
#include "NeighborStore.h"
#include "attribute.h"
#include "OnePhasePull.h"
#include "OPPLib/DataStructures.h"

#define MOTE_DEV "/dev/mote/0/tos"
#define MY_ID 1

typedef enum
{
  FALSE = 0,
  TRUE = 1
} bool;

uint16_t myId = MY_ID;
bool printMineOnly = 0;
char *myProgName = NULL;

void printAttributes(Attribute *array, uint8_t num)
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
  printf("INTEREST: sink: %d dest: %d seq: %d prev: %d ttl: %d exp: %d\n", 
	  intMsg->sink, 
          extTosMsg->addr,
          intMsg->seqNum, 
          intMsg->prevHop, 
	  intMsg->ttl, 
          intMsg->expiration);
  printAttributes(intMsg->attributes, intMsg->numAttrs);
  
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


void printUsage(void)
{
  printf("usage: %s -i <my-id> [-m]\n", myProgName);
}

int main(int argc, char * argv[]) 
{
  int fd;
  char dev[255]=MOTE_DEV;

  // for getopt
  extern char *optarg;
  extern int optind, opterr, optopt;
  int optChar = 0;
  bool myIdFound = 0;

  Ext_TOS_Msg msg;	

  myProgName = argv[0];

  //---------- BEGIN command line option processing ----------
  while (optChar != -1)
  {
    optChar = getopt(argc, argv, "mi:");
    switch (optChar)
    {
      // -m: to enable "print mine only"
    case 'm':
      printf("%s: print-mine-only enabled\n", 
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
  

  fd = open(dev, O_RDWR);
  if (fd<0) {
    printf("failed to open %s\n", dev);
    exit(1);
  }

  while (1) {

    int status = read(fd, &msg, sizeof(msg));

    if (status == sizeof(msg)) {
      if (msg.type == ESS_OPP_INTEREST)
      {
	printInterestPacket(&msg);
      }
      else if (msg.type == ESS_OPP_DATA)
      {
	printDataPacket(&msg);
      }
    }
    else {
      perror("read failed");
      exit(1);
    }

    fflush(NULL);
  }

  return 0;
}
