
#include "tos.h"
#include "PROXIMITY.h"

#define IDLE 0
#define BEACON 1
#define FLASH 2

#define BEACON_RATE 8
#define FLASH_COUNTDOWN 40

#define PROXIMITY_TIMEOUT 120 /* Proximity State times out after 120 clock ticks */

#define PROXIMITY_MSG_TYPE 9

extern const short TOS_LOCAL_ADDRESS;

//your FRAME
#define TOS_FRAME_TYPE PROXIMITY_frame
TOS_FRAME_BEGIN(PROXIMITY_frame) {
  char state;			/* Component counter state */
  char flash_countdown;
  TOS_Msg data; 		/* Message to be sent out */
  char send_pending;		/* Variable to store state of buffer*/
  int proximity_countdown;
  int beacon_countdown;
}TOS_FRAME_END(PROXIMITY_frame);



/* PROXIMITY_INIT:  
   turn on the LEDs
   initialize lower components.
   clock init to once a second
*/
char TOS_COMMAND(PROXIMITY_INIT)(){
  VAR(state) = IDLE;
  VAR(send_pending) = 0;
  VAR(proximity_countdown) = 0;
  VAR(beacon_countdown) = 0;
  /* 
     Uncomment if used with proximity.desc
     Comment out when used with  probrouter_light_wakeup_proximity.desc
  */
  //  TOS_CALL_COMMAND(PROXIMITY_SUB_INIT)();
  //  TOS_CALL_COMMAND(PROXIMITY_SUB_CLOCK_INIT)(255,0x5);
  return 1;
}


/* Clock Event Handler: 
   If BaseStation has signalled, send beacons
*/

void TOS_EVENT(PROXIMITY_CLOCK_EVENT)(){

  if (VAR(state)==IDLE) return;
  
  /*
    If state=FLASH and countdown has expired
    set clock to normal rate
    and go back to BEACON state
  */
  if (VAR(state) == FLASH && --VAR(flash_countdown)==0) {
    TOS_CALL_COMMAND(PROXIMITY_SUB_CLOCK_INIT)(255,0x5);
    VAR(state) = BEACON;
    if ((VAR(flash_countdown)%8) != 0) return; /* Return every 8*4 clock ticks */
  }

  if (--VAR(proximity_countdown)==0) {
    VAR(state) = IDLE; 
    TOS_CALL_COMMAND(PROXIMITY_SUB_CLOCK_INIT)(255,0x5);
    return;
  }
  
  /*
    If in BEACON or FLASH mode send packet every second
  */
  if (--VAR(beacon_countdown)==0 && VAR(send_pending) == 0) {
    VAR(beacon_countdown) = BEACON_RATE;
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
    VAR(send_pending) = 0;
  }
  return 1;
}

/*   AM_msg_handler_9

*/
TOS_MsgPtr TOS_MSG_EVENT(PROXIMITY_BEACON_MSG)(TOS_MsgPtr data){
  if (VAR(state) == BEACON) {
    VAR(state) = FLASH; 
    VAR(flash_countdown) = FLASH_COUNTDOWN;
    TOS_CALL_COMMAND(PROXIMITY_SUB_CLOCK_INIT)(tick8ps);
  }
  return data;
}

/*   AM_msg_handler_10

*/
TOS_MsgPtr TOS_MSG_EVENT(PROXIMITY_STOP_MSG)(TOS_MsgPtr data){  
  VAR(state) = IDLE;
  TOS_CALL_COMMAND(PROXIMITY_SUB_CLOCK_INIT)(255,0x5);
  if (VAR(send_pending) == 0) {
    if (TOS_CALL_COMMAND(PROXIMITY_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(PROXIMITY_STOP_MSG),&VAR(data))) {
      VAR(send_pending) = 1;
    }
  }
  return data;
}

/*   AM_msg_handler_11

*/
TOS_MsgPtr TOS_MSG_EVENT(PROXIMITY_START_MSG)(TOS_MsgPtr data){  
  VAR(state) = BEACON;
  VAR(proximity_countdown) = PROXIMITY_TIMEOUT;
  if (VAR(send_pending) == 0) {
    if (TOS_CALL_COMMAND(PROXIMITY_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(PROXIMITY_START_MSG),&VAR(data))) {
      VAR(send_pending) = 1;
    }
  }
  return data;
}
