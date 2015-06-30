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
  OutMsg.addr = htom16(TOS_BCAST_ADDR); 
  OutMsg.type = ID_MSG; 
  ((struct id*)(OutMsg.data))->id=htom16(addr);

  printf("Writing: " 
	 "[ID] Boradcasting ID:%d\n",
	 addr);
    
  write(mote, &OutMsg, sizeof(TOS_Msg));
}

int main(int argc, char *argv[])
{
  // open mote device
  mote = open("/dev/mote/0/tos", O_RDWR);
  if (mote < 0) {
    perror("Unable to open mote device");
    exit(1);
  }

  if(argc >= 2) {
    addr=atoi(argv[1]);
  } else {
    printf("Creating a new ID message:\n"
	   "Enter ID to assign:");
    scanf("%u", &in_addr);
    addr=in_addr;
  }

  send();
    
  return 0;
}











