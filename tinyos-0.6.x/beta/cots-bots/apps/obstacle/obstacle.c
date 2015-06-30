/* 
 * Sarah Bergbreiter
 * 11/26/2001
 * COTS-BOTS Project
 *
 * This component is the top level component for an obstacle avoidance
 * program.  It performs different tasks based on whisker events.
 *
 * History:
 * 11/26/2001 - created.
 * 1/11/2001 - added communication between cars (broadcast).
 *           - have not yet gotten them to turn simultaneously however.
 */

#include "tos.h"
#include "dbg.h"
#include "OBSTACLE.h"

// Radio constants
#define SPEED 10
#define DIR 11
#define TURN 12
#define FRONT_COLLIDE 19
#define SIDE_COLLIDE 20

// Delays
#define REVERSE_DELAY 10000
#define SIDE_DELAY 4000

// Speed constants
#define NORMAL 70
#define SLOW 40
#define OFF 0

// Turn constants
#define LEFT 0
#define SLIGHT_LEFT 10
#define STRAIGHT 20
#define SLIGHT_RIGHT 30
#define RIGHT 40

// Direction constants
#define FORWARD 1
#define REVERSE 0

typedef struct{
  int state;
  int src;
} whisker_msg;

// Frame declaration
#define TOS_FRAME_TYPE OBSTACLE_frame
TOS_FRAME_BEGIN(OBSTACLE_frame){
  TOS_Msg msg;
  TOS_Msg whisk_msg;
  char cmd;
  char sending;
  char prev_state;
  char task;
}
TOS_FRAME_END(OBSTACLE_frame);

char TOS_COMMAND(OBSTACLE_INIT)(){
  // Initialize sub-components needed here
  dbg(DBG_BOOT,("Obstacle Avoidance initialized.\n"));
  VAR(prev_state) = 0;
  VAR(cmd) = 0;
  VAR(task) = 0;
  return TOS_CALL_COMMAND(OBSTACLE_SUB_INIT)();
}

char TOS_COMMAND(OBSTACLE_START)(){
  TOS_CALL_COMMAND(OBSTACLE_SETSPEED)(NORMAL);
  TOS_CALL_COMMAND(OBSTACLE_SETDIR)(FORWARD);
  TOS_CALL_COMMAND(OBSTACLE_TURN)(STRAIGHT);
  return 1;
}

void TOS_EVENT(OBSTACLE_SERVO_EVENT)(int servo, unsigned char control) {
  return;
}

TOS_TASK(SEND_WHISKER_MSG) {
  if (!VAR(sending)) { 
    VAR(sending) = 1; 
    VAR(msg).data[0] = VAR(cmd); 
    if (!(TOS_COMMAND(OBSTACLE_SEND_MSG)(TOS_BCAST_ADDR, AM_MSG(OBSTACLE_MSG), &VAR(msg)))) 
      VAR(sending) = 0; 
  } 
}

TOS_TASK(FRONT_COLLISION) {
  int i,j,k;
  if (!(VAR(task))) {
    VAR(task) = 1;
    TOS_CALL_COMMAND(OBSTACLE_TURN)(SLIGHT_RIGHT);
    TOS_CALL_COMMAND(OBSTACLE_SETDIR)(REVERSE);
    for (i = 0; i < REVERSE_DELAY; i++)
      for (j = 0; j < REVERSE_DELAY; j++)
	k = 0;  // use until I find how to use nop
    TOS_CALL_COMMAND(OBSTACLE_SETDIR)(FORWARD);
    TOS_CALL_COMMAND(OBSTACLE_TURN)(STRAIGHT);
    VAR(task) = 0;
  }
}

TOS_TASK(SIDE_COLLISION) {
  // can add wether or not I'm going forward or reverse here later if
  // I decide to add this functionality
  int i,j,k;
  if (!(VAR(task))) {
    VAR(task) = 2;
    TOS_CALL_COMMAND(OBSTACLE_SETSPEED)(SLOW);
    TOS_CALL_COMMAND(OBSTACLE_TURN)(LEFT);
    for (i = 0; i < SIDE_DELAY; i++)
      for (j = 0; j < SIDE_DELAY; j++)
	k = 0;  // use until I find how to use nop
    TOS_CALL_COMMAND(OBSTACLE_SETSPEED)(NORMAL);
    TOS_CALL_COMMAND(OBSTACLE_TURN)(STRAIGHT);
    VAR(task) = 0;
  } 
}
 
TOS_TASK(REAR_COLLISION) {
  //int i;
  if (!(VAR(task))) {
    VAR(task) = 3;
    VAR(task) = 0;
  }
}

char TOS_EVENT(OBSTACLE_WHISKER_EVENT)(unsigned char state) {
  // Find which whisker changed and if it switched on
  char diff = state ^ VAR(prev_state);

  VAR(prev_state) = state;

  if (VAR(task) == 0) {
    if ((0x01 & diff) == 1) {
      if ((state & 0x01) == 1) {
	VAR(cmd) = SIDE_COLLIDE;
	TOS_POST_TASK(SIDE_COLLISION);
	TOS_POST_TASK(SEND_WHISKER_MSG);
	VAR(task) = 0;
      }
    }
    else if ((0x02 & diff) == 2) {
      if ((state & 0x02) == 2) {
	VAR(cmd) = SIDE_COLLIDE;
	TOS_POST_TASK(SIDE_COLLISION);
	TOS_POST_TASK(SEND_WHISKER_MSG);
	VAR(task) = 0;
      }
    }
    else if ((0x04 & diff) == 4) {
      if ((state & 0x04) == 4) {
	VAR(cmd) = FRONT_COLLIDE;
	TOS_POST_TASK(FRONT_COLLISION);
	TOS_POST_TASK(SEND_WHISKER_MSG);
	VAR(task) = 0;
      }
    }
    else if ((state & 0x08) == 8)
      TOS_POST_TASK(REAR_COLLISION);
  }

  return 1;

}

char TOS_EVENT(OBSTACLE_MSG_SEND_DONE)(TOS_MsgPtr sentBuffer) {
    VAR(sending) = 0;
    return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(OBSTACLE_MSG)(TOS_MsgPtr val) {
  // Might want to send confirmation command back at some point
  // Could also add some checking to make sure values are valid
  TOS_CALL_COMMAND(OBSTACLE_TOGGLE_LED)();
  if (val->data[0] == FRONT_COLLIDE) {
    VAR(cmd) = 0;
    TOS_POST_TASK(FRONT_COLLISION);
  }
  if (val->data[0] == SIDE_COLLIDE) {
    VAR(cmd) = 0;
    TOS_POST_TASK(SIDE_COLLISION);
  }
  if (val->data[0] == SPEED) {
    TOS_CALL_COMMAND(OBSTACLE_SETSPEED)(val->data[1]);
  }
  if (val->data[0] == TURN) {
    TOS_CALL_COMMAND(OBSTACLE_TURN)(val->data[1]);
  }
  if (val->data[0] == DIR) {
    TOS_CALL_COMMAND(OBSTACLE_SETDIR)(val->data[1]);
  }

  return val;
}
