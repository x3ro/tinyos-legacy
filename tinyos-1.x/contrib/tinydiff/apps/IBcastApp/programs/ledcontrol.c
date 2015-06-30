#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <ctype.h>
#include <inttypes.h>
#include <stdlib.h>

#include <string.h>
#include "stddef.h"
#include "sys/time.h"
#include "stdint.h"
#include "myAM.h"
#include "ibcast.h"
#include "ledcontrol.h"


int mote;
  
uint8_t ledState;
char scanString[10];
uint8_t ttl = DEFAULT_TTL;

TOS_Msg OutMsg = {
  group: DEFAULT_LOCAL_GROUP
};

  
void send(void) {
  LedControlMsg *ledMsg;
  struct timeval t;

  OutMsg.addr = TOS_BCAST_ADDR; 
  OutMsg.type = LEDSRC_TYPE; 
  OutMsg.group = DEFAULT_LOCAL_GROUP;
  OutMsg.length = sizeof(LedControlMsg);
  ledMsg = (LedControlMsg *)(OutMsg.data);

  gettimeofday(&t, NULL);
  ledMsg->reqId = (uint16_t)(t.tv_sec & 0xFFFF);

  ledMsg->ledState = ledState;
  ledMsg->ttl = ttl;

  if (ledState)
  {
    printf ("Turning ON Leds ");
  }
  else
  {
    printf ("Turning OFF Leds ");
  }
  printf ("with requestId = %d and ttl = %d\n", ledMsg->reqId, ledMsg->ttl);
    
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

  if (argc < 2 || argc > 3) {
    printf ("Usage: %s <on/off> [<ttl>]\n", argv[0]);
    exit(1);
  }
  
  if(argc >= 2) {
    if (strncmp(argv[1], "on", 3) == 0) {
      ledState = 1;
    }
    else if (strncmp(argv[1], "off", 4) == 0) {
      ledState = 0;
    }
    else {
      printf ("Usage: %s <on/off> [<ttl>]\n", argv[0]);
      exit(1);
    }
    if (argc == 3) {
      ttl = atoi(argv[2]);
    }
  }

  send();
    
  return 0;
}











