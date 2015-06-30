#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <inttypes.h>
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
	uint8_t j;
  OutMsg.addr = htom16(addr); 
  OutMsg.type = POWER_MSG; 
  OutMsg.length = 1;
	for (j=0;j<DATA_LENGTH;j++)
		OutMsg.data[j]=j;
  OutMsg.data[POWER_CMD] = WRITESETNBOUNCE;
  OutMsg.data[POW_VALUE] = (unsigned char)power & 0xFF; 
    
  printf("Writing: " 
	 "[POWER] dest:%d res:%u\n",
	 (unsigned int)mtoh16(OutMsg.addr), 
	 (unsigned int)( 0xFF & (int)OutMsg.data[POW_VALUE]) );
    
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

  if(argc >= 3) {
    addr=atoi(argv[1]);
    power=atoi(argv[2]);
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











