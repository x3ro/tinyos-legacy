#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <inttypes.h>
#include <stdlib.h>

#include "header.h"

void reliasend(int mote, TOS_Msg *m)
{
  char inp[1];

  do {
    inp[0]='\0';
    while(!getchar());

    printf("===========>Sending... ");    
    write(mote, m, sizeof(TOS_Msg));
    sleep(1);
    printf("Done.");

    printf("[type r to resend, c to continue]:");
    fflush(stdout);
    read(fileno(stdin), inp, 1);
    
    if(tolower(inp[0]) == 'r') {
      continue;
    } else if (tolower(inp[0]) == 'c') {
      break;
    } else {
      printf("[type r to resend, c to continue]:");
      fflush(stdout);
    }
      
  } while(1);

  printf("\n");
}


int main()
{
  int mote;

  TOS_Msg OutMsg = {
    group: LOCAL_GROUP
  };

  // open mote device
  mote = open("/dev/mote/0/tos", O_RDWR);
  if (mote < 0) {
    perror("Unable to open mote_tos device");
    exit(1);
  }

  while (1) {
    int x1, y1, x2, y2;
    int type;
    int interval;
    int expiration;
    int sender;
	int range;
    uint16_t addr;
    int in_addr;

    InterestMessage imsg;

    printf("Creating a new interest (Ctrl-C to exit) :\n");

    printf("Enter the region (lower left and upper right: x1,y1,x2,y2):");
    scanf("%u, %u, %u, %u", &x1, &y1, &x2, &y2);
    
    printf("Enter the type:");
    scanf("%u", &type);

    printf("Enter the interval:");
    scanf("%u", &interval);

    printf("Enter the expiration:");
    scanf("%u", &expiration);

	printf("Enter the range:");
	scanf("%u", &range);
	
    printf("Enter the send address:");    
    scanf("%u", &sender);


    printf("Enter the dest. address (-1 for broadcast == exploratory):");
    scanf("%u", &in_addr);
    addr=in_addr;

    OutMsg.addr = htom16(addr);
    OutMsg.type = INTEREST_MSG;
    OutMsg.length = sizeof(InterestMessage);
    
    imsg.type = type;
    imsg.x1 = x1; 
    imsg.y1 = y1; 
    imsg.x2 = x2; 
    imsg.y2 = y2; 
    imsg.interval = interval; 
    imsg.expiration = expiration; 
    imsg.sender = htom16(sender); 
	imsg.range=range;
	imsg.ttl=range;

    printf("Sending the following interest:\n"
		"[INTEREST] dest:%d type:%d (%d,%d)-(%d,%d)"\
		" interval:%d expiration:%d range:%d sender:%d\n",
	   (unsigned int)mtoh16(OutMsg.addr), (int)imsg.type, 
	   (int)imsg.x1, (int)imsg.y1, (int)imsg.x2, (int)imsg.y2,
	   (unsigned int)imsg.interval, (unsigned int)imsg.expiration, 
	   (unsigned int)imsg.range,(unsigned int)mtoh16(imsg.sender));

    *(InterestMessage*)OutMsg.data = imsg;

    reliasend(mote, &OutMsg);


  }

  return 0;
}




