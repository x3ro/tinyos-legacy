/*
 * Sarah Bergbreiter
 * 6/21/2001
 * COTS-BOTS Project
 *
 * The MZ component provides standard interfaces such as set speed, turn
 * and set direction to the Mini-Z robot platform.
 *
 * History:
 * 6/21/2001 - created.
 *
 */

#include "tos.h"
#include "dbg.h"
#include "MZ.h"

char TOS_COMMAND(MZ_INIT)(void){
  // initialize motor and solenoid
  dbg(DBG_BOOT,("Mini-Z initialized.\n"));
  return TOS_CALL_COMMAND(MZ_MOTOR_INIT)();
}

char TOS_COMMAND(MZ_SETSPEED)(unsigned char speed){
  // Set the motor speed
  TOS_CALL_COMMAND(MZ_MOTOR_SETSPEED)(speed);
  return 1;
}

char TOS_COMMAND(MZ_SETDIR)(char direction){
  // Set the motor direction
  TOS_CALL_COMMAND(MZ_MOTOR_SETDIR)(direction);
  return 1;
}

char TOS_COMMAND(MZ_TURN)(char turn){
  // Set the turn direction.
  TOS_CALL_COMMAND(MZ_SERVO_SET_DIRECTION)(turn);
  return 1;
}
