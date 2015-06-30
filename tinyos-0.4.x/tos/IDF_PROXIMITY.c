
#include "tos.h"
#include "IDF_PROXIMITY.h"

#define IDLE 0
#define BEACON_WAIT 1
#define BEACON 2

#define BEACON_WAIT_MASK 0x0f

/* Heartbeat Rate (4secs) */
#define HEARTBEAT_RATE 64

/* Rate of sending Proximity Beacons (4secs)*/
#define BEACON_RATE 64

/* Rate of flashing (1/4 sec) */
#define FLASH_RATE 4
#define BASE_FLASH_RATE 16
#define FLASH_UPDATE_RATE 32

/* Flash timeout = 10 secs */
#define FLASH_COUNTDOWN 160

/* Proximity State times out after 2 mins */
#define PROXIMITY_TIMEOUT 19200

#define COMMAND_START_PROXIMITY  5
#define COMMAND_STOP_PROXIMITY   6


extern short TOS_LOCAL_ADDRESS;

typedef struct {
  short src;
}proximity_msg;

//your FRAME
#define TOS_FRAME_TYPE PROXIMITY_frame
TOS_FRAME_BEGIN(PROXIMITY_frame) {
  char state;			/* Component counter state */
  unsigned char flash_countdown;
  TOS_Msg data; 		/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
  unsigned int free_counter;
  unsigned char led_state;
  unsigned char beacon_random;
  unsigned char flash_rate;
}TOS_FRAME_END(PROXIMITY_frame);

TOS_TASK(Clear_Heartbeat){
  int i;
  for (i=0; i<10000; i++);
  SET_RED_LED_PIN();
  return;
}

/* PROXIMITY_INIT:  
   turn on the LEDs
   initialize lower components.
   clock init to once a second
*/
char TOS_COMMAND(PROXIMITY_INIT)(){
  VAR(state) = IDLE;
  VAR(send_pending) = 0;
  VAR(beacon_random) = 0;

  VAR(free_counter) = 0;
  VAR(led_state)=0;

  VAR(flash_rate)=0;

  // Initialize RED Led for heartbeat
  SET_RED_LED_PIN();

   TOS_CALL_COMMAND(PROXIMITY_SUB_INIT)();

  return 1;
}


/* Clock Event Handler: 
   If BaseStation has signalled, send beacons
*/

void TOS_EVENT(PROXIMITY_CLOCK_EVENT)(){
  int n=0;

  VAR(free_counter)++;
  if (VAR(state)==IDLE) {
    //function in regular heartbeat mode
    /* 
    if ((VAR(free_counter)%HEARTBEAT_RATE) == 0) {
      // Heart Beat      
      CLR_RED_LED_PIN();
      TOS_POST_TASK(Clear_Heartbeat);
    }
    */
    return;
  }

  /* Wait for a random interval (beacon_countdown) before
     going into BEACON mode. This desynchronizes proximity 
     transmissions
  */
  if (VAR(state)==BEACON_WAIT) {
    if ((--VAR(beacon_random))==0)
      VAR(state)=BEACON;
    else return;
  }
  /*
    If state=FLASH and countdown has expired
    and go back to BEACON state
  */
  if (VAR(free_counter)%FLASH_UPDATE_RATE) {
    n = TOS_CALL_COMMAND(PROXIMITY_SUB_GET_NBR_COUNT)();
    if (n == 0) VAR(flash_rate) = 0;
    else VAR(flash_rate) = BASE_FLASH_RATE/n;
  }
  
  /* If BEACON mode, blink every flash_rate(th) of a sec */
  if (VAR(flash_rate)==0) SET_RED_LED_PIN();
  else {
    if ((++VAR(led_state))%VAR(flash_rate)) CLR_RED_LED_PIN();
    else SET_RED_LED_PIN();
  }
  /*
    If in BEACON mode send packet every 32 ticks
  */
  if (((VAR(free_counter)%BEACON_RATE)==0) && VAR(send_pending) == 0) {
    //    CLR_YELLOW_LED_PIN();
    ((proximity_msg *) &(VAR(data).data[0]))->src = TOS_LOCAL_ADDRESS;
    if (TOS_CALL_COMMAND(PROXIMITY_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(PROXIMITY_BEACON_MSG),&VAR(data))) {
      VAR(send_pending) = 1;
    }
  }
}


/*   
     PROXIMITY_SUB_MSG_SEND_DONE event handler:
*/
char TOS_EVENT(PROXIMITY_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
  if(&VAR(data) == msg){ 
    //    SET_YELLOW_LED_PIN();
    VAR(send_pending) = 0;
  }
  return 1;
}

/*   AM_msg_handler_9

*/
TOS_MsgPtr TOS_MSG_EVENT(PROXIMITY_BEACON_MSG)(TOS_MsgPtr data){
  TOS_CALL_COMMAND(PROXIMITY_SUB_ADD_NBR)(((proximity_msg *) &(data->data[0]))->src);
  return data;
}

char TOS_COMMAND(PROXIMITY_SET_MODE)(char mode){
  if (mode==COMMAND_START_PROXIMITY) {
    if (VAR(state)==IDLE) {
      VAR(state)=BEACON_WAIT;
      VAR(beacon_random) = TOS_CALL_COMMAND(PROXIMITY_SUB_RANDOM)() & BEACON_WAIT_MASK;
    }
  }else{
    SET_RED_LED_PIN();
    VAR(state) = IDLE;
  }

  return 1;
}
