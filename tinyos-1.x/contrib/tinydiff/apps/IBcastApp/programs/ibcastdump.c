
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <inttypes.h>
#include <stdlib.h>

#include "ibcast.h"
#include "ibcast_hdr.h"
#include "myAM.h"
#include "ledcontrol.h"

#define MOTE_DEV "/dev/mote/0/tos"

void printIBcast(TOS_MsgPtr tosMsg)
{
  struct bcastmsg *bMsg = NULL;
  typedef char TypeString[20];
  TypeString typeArray[3] = { "analog", "wind-gust", "rain-switch" };

  bMsg = (struct bcastmsg *)tosMsg->data;
  printf ("[DATA] src: %4d type = %-11s seq-num: %5d ttl: %3d uid: %2d \n", \
	  bMsg->source, typeArray[bMsg->type], bMsg->seq, bMsg->ttl, 
	  bMsg->uid);
}


int main(int argc, char * argv[]) 
{
  int fd;
  int i;
  uint8_t j;
  char dev[255]=MOTE_DEV;

  TOS_Msg msg;	

  // Optional: use a different tos device than 0.
  switch (argc) {
    case 2:
      j=strtol(argv[1], (char **)NULL, 10);
      sprintf(dev, "/dev/mote/%d/tos", j);
    break;
  }

  fd = open(dev, O_RDWR);
  if (fd<0) {
    printf("failed to open %s\n", dev);
    exit(1);
  }

  while (1) {

    int status = read(fd, &msg, sizeof(msg));

    if (status == sizeof(msg)) {

      switch (msg.type) {

      case JR_DATA_1:
      case JR_DATA_2:

	printIBcast(&msg);
	break;

      case LEDSRC_TYPE:

	{

	LedControlMsg *ledMsg = (LedControlMsg *)msg.data;

	printf ("[LEDSRC] src: %5d reqId: %5d ttl: %2d ledState: %3s\n",
		ledMsg->source, ledMsg->reqId, ledMsg->ttl, 
		((ledMsg->ledState == 0) ? "off" : "on"));
	}

	break;

      case POT_TYPE:

	printf("[POWER] grp:%d dest:%d pow:%u\n", 
	       (unsigned int)msg.group, 
	       (unsigned int)msg.addr, 
	       (unsigned int) ( 0xFF &	(int)msg.data[1]));
	break;

      default:

	break;
	// code below not used...
	
	printf("[????] addr: %d grp:%d msg.type==%d ", 
		(unsigned int)msg.addr,
		(unsigned int)msg.group,(unsigned int)msg.type );

	for(i=0; i<DATA_LENGTH ; i++) {
		printf("%d ", (unsigned int)msg.data[i]);
	}
	printf("\n");


      }
    }
    else {
      perror("read failed");
    }

    fflush(NULL);
  }

  return 0;
}
