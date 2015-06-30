#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <inttypes.h>
#include <stdlib.h>

#include "header.h"

void reliasend(int mote, TOS_Msg *m, int *argc)
{
  char inp[1];

  do {
	if (*argc!=10) {
		inp[0]='\0';
		while(!getchar());
	}

    printf("===========>Sending... ");    
    if ((write(mote, (TOS_Msg *)m, sizeof(TOS_Msg)))<0) {
		perror("writing to mote:");
	}	
//    sleep(1);
    printf("Done.");

	if (*argc==10)
		break;
	
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


int main(int argc, char *argv[])
{
  int mote;

  TOS_Msg OutMsg = {
    group: DEFAULT_LOCAL_GROUP
  };

  // open mote device
  mote = open("/dev/mote/0/tos", O_RDWR);
  if (mote < 0) {
    perror("Unable to open mote_tos device");
    exit(1);
  }

  while (1) {
    int x1=0, y1=0, x2=100, y2=100;
    int type=3;
	int codeId=0;
	int minRange=2;
	int maxRange=10;	
    int interval=0;
    int expiration=(maxRange-minRange)+1;
    int sender=40;
    uint16_t addr;
    int in_addr=-1;
	int j;

    InterestMessage imsg;

	switch (argc) {
		case 13:
			x1=atoi(argv[1]);
			y1=atoi(argv[2]);
			x2=atoi(argv[3]);
			y2=atoi(argv[4]);
			type=atoi(argv[5]);
			codeId=atoi(argv[6]);
			minRange=atoi(argv[7]);
			maxRange=atoi(argv[8]);	
			interval=atoi(argv[9]);
			expiration=atoi(argv[10]);
			sender=atoi(argv[11]);
			addr=atoi(argv[12]);
			in_addr=1;
		break;
/*
		default:
    		printf("Creating a new interest (Ctrl-C to exit) :\n");

			printf("Enter the region "\
			"(lower left and upper right: x1,y1,x2,y2):");
		    scanf("%u, %u, %u, %u", &x1, &y1, &x2, &y2);
    
		    printf("Enter the type:");
		    scanf("%u", &type);

    		printf("Enter the interval:");
		    scanf("%u", &interval);

		    printf("Enter the expiration:");
		    scanf("%u", &expiration);

		    printf("Enter the send address:");    
		    scanf("%u", &sender);

		    printf("Enter the dest. address "\
			"(-1 for broadcast == exploratory):");
		    scanf("%u", &in_addr);
		    addr=in_addr;
		break;
*/
	}

	addr=in_addr;
    OutMsg.addr = htom16(addr);
    OutMsg.type = INTEREST_MSG;
//    OutMsg.length = sizeof(InterestMessage);
    
    imsg.type = type;
    imsg.x1 = x1; 
    imsg.y1 = y1; 
    imsg.x2 = x2; 
    imsg.y2 = y2; 
	imsg.codeId=codeId;
	imsg.minRange=htom16(minRange);
	imsg.maxRange=htom16(maxRange);
    imsg.interval = interval; 
    imsg.expiration = expiration; 
    imsg.sender = htom16(sender); 

    printf("Sending the following interest:\n"
	   "[INTEREST] dest:%d type:%d (%d,%d)-(%d,%d) codeId:%d minRange:%d"\
		" maxRange %d interval:%d expiration:%d sender:%d\n",
	   (unsigned int)mtoh16(OutMsg.addr), (int)imsg.type, 
	   (int)imsg.x1, (int)imsg.y1, (int)imsg.x2, (int)imsg.y2,
		(int)imsg.codeId, (unsigned int)(imsg.minRange),
		(unsigned int)(imsg.maxRange),
	   (unsigned int)imsg.interval, (unsigned int)imsg.expiration, 
	   (unsigned int)mtoh16(imsg.sender));

    *(InterestMessage*)OutMsg.data = imsg;

	for (j=sizeof(InterestMessage); j<DATA_LENGTH; j++) {
		OutMsg.data[j]=j;
	}	

    reliasend(mote, &OutMsg, &argc);
	if (argc==10)
		break;


  }

  return 0;
}




