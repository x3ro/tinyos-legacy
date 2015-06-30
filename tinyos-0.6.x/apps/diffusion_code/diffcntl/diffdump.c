#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <inttypes.h>
#include <stdlib.h>

#define MOTE_DEV "/dev/mote/0/tos"

#include "header.h"

int main(int argc, char *argv[]) 
{
  int fd;
  int i;
	uint8_t j;
	char dev[255]="/dev/mote/0/tos";

  TOS_Msg msg;  

	switch (argc) {
		case 2:
			j=atoi(argv[1]);
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

      /*
      printf("[---] addr: %d grp:%d msg.type==%d ", 
	     (unsigned int)mtoh16(msg.addr), (unsigned int)msg.group,(unsigned int)msg.type );

      for(i=0; i<DATA_LENGTH ; i++) {
	printf("%d ", (unsigned int)msg.data[i]);
      }
      printf("\n");
      */

			if (msg.type == (char)INTEREST_MSG) {
				InterestMessage *imsg;
				imsg = (InterestMessage*)msg.data;

				printf("[INTEREST] dest:%d type:%d (%d,%d)-(%d,%d)"\
				" codeId:%d minRange:%d maxRange: %d"\
				" interval:%d expiration:%d sender:%d\n",
	       		(unsigned int)mtoh16(msg.addr), (int)imsg->type, 
	       		(int)imsg->x1, (int)imsg->y1, (int)imsg->x2, (int)imsg->y2,
				(int)imsg->codeId, (unsigned int)(imsg->minRange),
				(unsigned int)(imsg->maxRange),
	     		(unsigned int)imsg->interval, (unsigned int)imsg->expiration, 
	      		(unsigned int)mtoh16(imsg->sender));

			} else if (msg.type == (char)DATA_MSG ) {

				DataMessage *dmsg;
				dmsg = (DataMessage*)msg.data;

				printf("[DATA] dest:%d (%d, %d) type:%d"\
				 	" codeId:%d minRange:%d maxRange:%d data:%d"\
					" orgSeqNum:%u hopsToSrc:%d  sender:%d\n", 
				mtoh16(msg.addr), (int)dmsg->x, (int)dmsg->y, 
				(int)dmsg->type, (int)dmsg->codeId,
				(unsigned int)(dmsg->minRange),
				(unsigned int)(dmsg->maxRange), (int)dmsg->data, 
				mtoh32(dmsg->orgSeqNum), (unsigned int)dmsg->hopsToSrc, 
				mtoh16(dmsg->sender));

			} else if(msg.type == (char)POWER_MSG) {
				printf("[POWER] grp:%d dest:%d pow:%u\n",
				(unsigned int)msg.group,
				(unsigned int)mtoh16(msg.addr), 
				(unsigned int) ( 0xFF &  (int)msg.data[1]));
			} else if( msg.type == (char)ID_MSG ) {
				printf("[ID] grp:%d id:%d\n",
				(unsigned int)msg.group,
				mtoh16( ((struct id*)(&msg.data))->id ));
			} else {
				printf("[????] addr: %d grp:%d msg.type==%d ", 
				(unsigned int)mtoh16(msg.addr),
				(unsigned int)msg.group,(unsigned int)msg.type );

				for(i=0; i<DATA_LENGTH ; i++) {
					printf("%d ", (unsigned int)msg.data[i]);
				}
				printf("\n");
			}	
		}	
		else 
			perror("read failed");
		fflush(stdout);
	}

  return 0;
}
