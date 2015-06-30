#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>

#include "header.h"

int mote;
  
int power;
uint16_t addr;
int in_addr;

TOS_Msg OutMsg = {
  group: DEFAULT_LOCAL_GROUP
};
  
void send(void) {
  OutMsg.addr = htom16(TOS_BCAST_ADDR); 
  OutMsg.type = ID_RESET; 
  ((struct id*)(OutMsg.data))->id=htom16(addr);
    
  printf("Writing: " 
	 "soft reset");
    
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
    printf("Enter the power:");
    scanf("%u", &power);
    send();
  }

  return 0;
}











