#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#include "header.h"

int mote;
  
uint16_t addr;
int in_addr;
int type;

int dtype;
int x, y;
long orgSeqNum;
int hopsToSrc;
int data;
int sender;

TOS_Msg msg = {
  group: DEFAULT_LOCAL_GROUP
};


void send(void) {
	uint8_t j;
  DataMessage* dmsg;

  msg.addr = htom16(addr); 
  msg.type = DATA_MSG; 

  dmsg=(DataMessage*)(msg.data);
	for (j=sizeof(DataMessage); j<DATA_LENGTH; j++)
		msg.data[j]=j;

  dmsg->type=(unsigned char)dtype;
  dmsg->x=(unsigned char)x;
  dmsg->y=(unsigned char)y;

  dmsg->hopsToSrc=(unsigned char)hopsToSrc;
  dmsg->data=(unsigned char)data;

  dmsg->orgSeqNum=htom16(orgSeqNum);
  
  dmsg->sender=htom16(sender);

  printf("Sending: [DATA] dest:%d (%d, %d) type:%d data:%d orgSeqNum:%u hopsToSrc:%d  sender:%u\n", 
	 mtoh16(msg.addr), (int)dmsg->x, (int)dmsg->y, 
	 (int)dmsg->type, (int)dmsg->data, 
	 mtoh16(dmsg->orgSeqNum), (unsigned int)dmsg->hopsToSrc, 
	 mtoh16(dmsg->sender));
    
  write(mote, &msg, sizeof(TOS_Msg));
}

int main(int argc, char *argv[])
{
  // open mote device
  mote = open("/dev/mote/0/tos", O_RDWR);
  if (mote < 0) {
    perror("Unable to open mote_tos device");
    exit(1);
  }

  if(argc >= 9) {
    addr=atoi(argv[1]);
    x=atoi(argv[2]);
    y=atoi(argv[3]);
    dtype=atoi(argv[4]);
    data=atoi(argv[5]);
    orgSeqNum=atoi(argv[6]);
    hopsToSrc=atoi(argv[7]);
    sender=atoi(argv[8]);

    send();
  } else {
    printf("Creating a new da message:\n"
	   "Enter the dest. address (-1 for broadcast): ");
    scanf("%u", &in_addr);
    addr=in_addr;

    printf("Enter x,y: ");
    scanf("%u, %u", &x, &y);

    printf("Enter the diffusion type:");
    scanf("%u", &dtype);

    printf("Enter the data: ");
    scanf("%u", &data);

    printf("Enter the orgSeqNum: ");
    scanf("%lu", &orgSeqNum);

    printf("Enter the hopsToSrc: ");
    scanf("%u", &hopsToSrc);

    printf("Enter the sender: ");
    scanf("%u", &sender);

    send();
  }

  return 0;
}











