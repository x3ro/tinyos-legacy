/*
 * Sarah Bergbreiter
 * 6/21/2001
 * COTS-BOTS project
 *
 * This component provides instructions to whatever platform is being used
 * to perform figure 8's alternating forward and reverse.  This is only 
 * an open-loop program, so the figure 8's are not guaranteed to be timed
 * correctly and the speed/turn-time will in fact need to be changed
 * for each platform, battery condition, etc.
 *
 * History:
 * 6/21/2001 - created.
 * 11/24/2001 - modified to send back servo data wirelessly (this can be
 *              removed with no loss of functionality).
 *
 */

#include "tos.h"
#include "dbg.h"
#include "FIGURE8.h"

// Speed constants
#define SPEED1 70
#define OFF 0

// Turn constants (far left=0, far right=40)
#define LEFT 10
#define STRAIGHT 20
#define RIGHT 30

// Direction constants
#define FORWARD 1
#define REVERSE 0

typedef struct{
  int src;
  int servo;
  int control;
} servo_msg;

// Frame declaration
#define TOS_FRAME_TYPE FIGURE8_frame
TOS_FRAME_BEGIN(FIGURE8_frame){
  int ticks;
  TOS_Msg msg;
  char sending;
}
TOS_FRAME_END(FIGURE8_frame);

char TOS_COMMAND(FIGURE8_INIT)(){
  // Initialize sub-components needed here
  dbg(DBG_BOOT,("Figure8 initialized.\n"));
  VAR(ticks) = 0;
  return TOS_CALL_COMMAND(FIGURE8_SUB_INIT)();
}

char TOS_COMMAND(FIGURE8_START)(){
  // Start clock
  return TOS_CALL_COMMAND(FIGURE8_SUB_CLOCK_INIT)(tick1ps);
}

void TOS_EVENT(FIGURE8_CLOCK_EVENT)(){
  // case statement for turning
  VAR(ticks)++;
  switch (VAR(ticks)){
  case 2:
    TOS_CALL_COMMAND(FIGURE8_SETSPEED)(SPEED1);
    TOS_CALL_COMMAND(FIGURE8_SETDIR)(FORWARD);
    TOS_CALL_COMMAND(FIGURE8_TURN)(STRAIGHT);
    break;
  case 4:
    TOS_CALL_COMMAND(FIGURE8_TURN)(RIGHT);
    break;
  case 8:
    TOS_CALL_COMMAND(FIGURE8_TURN)(STRAIGHT);
    break;
  case 12:
    TOS_CALL_COMMAND(FIGURE8_TURN)(LEFT);
    break;
  case 16:
    TOS_CALL_COMMAND(FIGURE8_TURN)(STRAIGHT);
    break;
  case 18:
    TOS_CALL_COMMAND(FIGURE8_SETDIR)(REVERSE);
    break;
  case 21:
    TOS_CALL_COMMAND(FIGURE8_TURN)(LEFT);
    break;
  case 26:
    TOS_CALL_COMMAND(FIGURE8_TURN)(STRAIGHT);
    break;
  case 30:
    TOS_CALL_COMMAND(FIGURE8_TURN)(RIGHT);
    break;
  case 34:
    TOS_CALL_COMMAND(FIGURE8_TURN)(STRAIGHT);
    break;
  case 36:
    TOS_CALL_COMMAND(FIGURE8_SETDIR)(FORWARD);
    VAR(ticks) = 2;
    break;
  }
}

void TOS_EVENT(FIGURE8_SERVO_EVENT)(int servo, unsigned char control) {
  servo_msg* message = (servo_msg*)VAR(msg).data;
  if (!VAR(sending)) {
    VAR(sending) = 1;
    message->src = TOS_LOCAL_ADDRESS;
    message->servo = servo;
    message->control = control;
    if (TOS_COMMAND(FIGURE8_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(FIGURE8_SERVO), &VAR(msg)))
      return;
    else
      VAR(sending) = 0;
  }
  return;
}

char TOS_EVENT(FIGURE8_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer) {
  VAR(sending) = 0;
  return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(FIGURE8_SERVO)(TOS_MsgPtr val) {
  return val;
}
