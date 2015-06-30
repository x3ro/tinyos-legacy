#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <inttypes.h>
#include <stdlib.h>

#include "header.h"

const int MAX_POW = 35,
  MIN_POW = 5,
  ATTEMPTS = 10, GOOD_LIMIT = 5,
  DELAY_SEC = 1, DELAY_USEC = 0;
  
const char* motedev="/dev/mote/0/tos";

int mote, zero_pow, good_pow;

int check_connect(TOS_Msg* OutMsg, int pow, int trys, int limit) {
  int stats=0;
  int i;
  fd_set rfds;
  struct timeval tv;
  int retval;
  TOS_Msg inMsg;


  OutMsg->data[POWER_CMD] = SETNBOUNCE;
  OutMsg->data[POW_VALUE] = (unsigned char)pow & 0xFF; 

  printf("\nSending: [POWER] dest:%d pow:%u: ",
	 (unsigned int)OutMsg->addr, 
	 (unsigned int)( 0xFF & (int)OutMsg->data[POW_VALUE]) );

  for(i=0; i< trys; i++) {
    
    write(mote, OutMsg, sizeof(TOS_Msg));

    FD_ZERO(&rfds);
    FD_SET(mote, &rfds);
    tv.tv_sec = DELAY_SEC;
    tv.tv_usec = DELAY_USEC;
    retval=select(mote+1, &rfds, NULL, NULL, &tv);
    if(retval) {
      read(mote, &inMsg, sizeof(inMsg));
      // insert a check for correct message here
      if(inMsg.type==POWER_MSG
	 && inMsg.addr==OutMsg->addr
	 && inMsg.data[POW_VALUE]==OutMsg->data[POW_VALUE]) {
	//printf("Received correct reply!\n");
	printf("+");
	stats++;
	if(stats > limit) {
	  break;
	}
      } else {
	//printf("Received wrong message\n");
	printf("-");
      }
    } else {
      //printf("Did not receive anything\n");
      printf(".");
    }

    fflush(stdout);
  }

  return stats;
}


void rel_write(TOS_Msg* outMsgPtr,  int pow) {
  TOS_Msg inMsg = {type :0};

  outMsgPtr->data[POWER_CMD] = WRITESETNBOUNCE;
  outMsgPtr->data[POW_VALUE] = (unsigned char)pow & 0xFF; 

  printf("Writing: [POWER] dest:%d pow:%u: ",
	 (unsigned int)outMsgPtr->addr, 
	 (unsigned int)( 0xFF & (int)outMsgPtr->data[POW_VALUE]) );

  do {
    fd_set rfds;
    struct timeval tv;
    int retval;

    printf(".");
    write(mote, outMsgPtr, sizeof(TOS_Msg));

    FD_ZERO(&rfds);
    FD_SET(mote, &rfds);
    tv.tv_sec = DELAY_SEC;
    tv.tv_usec = DELAY_USEC;
    retval=select(mote+1, &rfds, NULL, NULL, &tv);
    if(retval) {
      read(mote, &inMsg, sizeof(inMsg));
      // insert a check for correct message here
    }
  }while (inMsg.type != POWER_MSG
	  || inMsg.group != LOCAL_GROUP
	  || inMsg.addr != outMsgPtr->addr
	  || inMsg.data[POW_VALUE] != outMsgPtr->data[POW_VALUE]);

  printf("+\nWrite succeeded!\n");
}


void check_eeprom(TOS_Msg* outMsgPtr,  int pow) {
  TOS_Msg inMsg = {type :0};

  outMsgPtr->data[POWER_CMD] = READNSEND;
  outMsgPtr->data[POW_VALUE] = 0xc4; // not 255, not 0...anything else

  printf("Quering: [POWER] dest:%d : ",
	 (unsigned int)outMsgPtr->addr);

  for(;;) {
    fd_set rfds;
    struct timeval tv;
    int retval;

    write(mote, outMsgPtr, sizeof(TOS_Msg));

    tv.tv_sec = DELAY_SEC;
    tv.tv_usec = DELAY_USEC;


    // Loop until we get a response of time expires
    do {

      FD_ZERO(&rfds);
      FD_SET(mote, &rfds);
      retval=select(mote+1, &rfds, NULL, NULL, &tv);

      if(retval == 0) {
	break;
      } else {
	read(mote, &inMsg, sizeof(inMsg));
      }

    } while( inMsg.type != POWER_MSG
	     || inMsg.group != LOCAL_GROUP );

    if(retval) {
      read(mote, &inMsg, sizeof(inMsg));
      // insert a check for correct message here
      if (inMsg.addr == outMsgPtr->addr
	  && inMsg.data[POW_VALUE] == pow) {
	break;
      }
      else {
	printf("-");
      }

    } else {
      printf(".");
    }
    fflush(stdout);
  }

  printf("+\nCheck succeeded!\n");
}


int main(int argc, char *argv[])
{
  char buff[100];

  int pow;
  uint16_t addr;
  int in_addr;

  int rec;

  TOS_Msg OutMsg = { group: LOCAL_GROUP , type: POWER_MSG };

  // attempt to open mote device
  mote = open(motedev, O_RDWR);
  if (mote < 0) {
    printf("Unable to open device '%s'", motedev);
    exit(1);
  }

  if(argc >= 2) {
    addr=atoi(argv[1]);
  } else {    
    printf("Enter the mote dest. address (DO NOT use -1):");
    scanf("%u", &in_addr);
    addr=in_addr;
  }

  OutMsg.addr = addr; 
  OutMsg.length = 2; 


  printf("\nMove the mote OUTSIDE of the desired maximum range.\n"
	 "Check if the mote's potentiometer is fixed.\n"
	 "Press Enter to continue...");
  fgets(buff, 100, stdin);
  for(pow = MAX_POW; pow >= MIN_POW; pow--) {
    rec=check_connect(&OutMsg, pow, ATTEMPTS, 0); 
    if(rec == 0)
      break;
  }

  if( pow <= MIN_POW && rec!=0 ) { 
    printf("\nUnable to find an appropriate range!\n The lowest power is not low enough.\n"); 
    return 1;
  }

  zero_pow = pow;
  printf("\n------- ZERO_POWER: %d ---------\n", zero_pow); 

  printf("\nMove the mote into the GOOD range.\n"
	 "Press Enter to continue...");
  fgets(buff, 100, stdin);

  rec=check_connect(&OutMsg, zero_pow, ATTEMPTS, GOOD_LIMIT-1); 
  for(pow = zero_pow-1; pow >= MIN_POW && rec >= GOOD_LIMIT; pow--) {
    rec=check_connect(&OutMsg, pow, ATTEMPTS, GOOD_LIMIT-1); 
  }

  if( pow < MIN_POW 
      || pow == zero_pow-1 ) { 
    printf("\nUnable to find an appropriate range!\n "); 
    return 1;
  }

  good_pow = pow+2; 
  printf("\n------- GOOD_POWER: %d ---------\n", good_pow); 

  //_reliably_ write into the motes eeprom
  rel_write(&OutMsg, good_pow);

  printf("\nChecking resistance storage of the GOOD resistance\n"
	 "Reset the mote (drain capacitance if necessary).\n"
	 "Press Enter to continue...");
  fgets(buff, 100, stdin);

  check_eeprom(&OutMsg, good_pow);

  printf("\n---- Calibration of the mote completed sucessfully! -----\n\n");

  close(mote);
  return 0;
}










