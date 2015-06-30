#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <inttypes.h>
#include <stdlib.h>

#include "header.h"

int mote;

uint16_t addr;
int in_addr;

TOS_Msg OutMsg = {
  group: LOCAL_GROUP
};
  
void send(void) {
  OutMsg.addr = htom16(addr); 
  OutMsg.type = POWER_MSG; 
  OutMsg.length = 1;
  OutMsg.data[POWER_CMD] = READNSEND;
  //  OutMsg.data[POW_VALUE] = 50;
    
  printf("Sending: [POWER READNSEND] dest:%d\n",
	 (unsigned int)mtoh16(OutMsg.addr));
    
  write(mote, &OutMsg, sizeof(TOS_Msg));
}

int main(int argc, char *argv[])
{
  // open mote device
  mote = open("/dev/mote/0/tos", O_RDWR);
  if (mote < 0) {
    perror("Unable to open mote_tos device");
    exit(1);
  }

  if(argc >= 2) {
    addr=atoi(argv[1]);
    send();
  } else {
    printf("Creating a new power message:\n"
	   "Enter the dest. address (-1 for broadcast):");
    scanf("%u", &in_addr);
    addr=in_addr;
    send();
  }

  return 0;
}











