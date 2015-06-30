/*									tab:4
 *
 * Authors: Deepak Ganesan
 * Date   : 04/20/01
 *
 * DESCRIPTION 
 * -----------
 * This component provides software timers using the single clock so that
 * each included component can use its own timer at a desired resolution.
 * A component can request a timer that is an integral multiple of TICKPS
 * (see below) between 1 & 15.
 * For example: TICKPS is currently 4 ticks per second.
 *              A component can request say 10 TICKPS, in which case a timer
 *              that runs at 4/10 = 0.4 ticks per second would be created.
 * To increase the resolution of the timer, change TICKPS
 */

#include "tos.h"
#include "dbg.h"
#include "TIMERS.h"

#define DBG(act) TOS_CALL_COMMAND(TIMERS_LEDS)(led_ ## act)

#define TICKPS tick8ps

#define fflush(stdout);

#define TOS_FRAME_TYPE TIMERS_OBJ
TOS_FRAME_BEGIN(TIMERS_OBJ) {
  unsigned char reg;
  unsigned char timer_interval[4];
  unsigned char timer_current[4];
}
TOS_FRAME_END(TIMERS_OBJ);

void TOS_EVENT(TIMERS_NULL_FUNC)(short i){} /* Signal data event to upper comp */

char TOS_COMMAND(TIMERS_INIT)(){
  unsigned char i;
  dbg(DBG_CLOCK, ("Timers initialized\n"));
    
    VAR(reg) = 0;
    for (i=0; i<4; i++) {
      VAR(timer_interval[i])=0;
      VAR(timer_current[i])=0;
    }

    TOS_CALL_COMMAND(TIMERS_SUB_INIT)(TICKPS);
    return 1;
}

char TOS_COMMAND(TIMERS_REGISTER)(char port, char interval) {
  VAR(reg) |= (0x80 >> port);
  VAR(timer_interval[port/2]) |= (interval << (!(port%2) * 4));
  VAR(timer_current[port/2]) |= (interval << (!(port%2) * 4));
  dbg(DBG_CLOCK, ("Timer Interval = %x\n",VAR(timer_interval[port/2])));
  dbg(DBG_CLOCK, ("Reg = %x\n",VAR(reg)));
  return port;
}

char TOS_COMMAND(TIMERS_DEREGISTER)(char port) {
  unsigned char i;
  VAR(reg) &= (~(0x80 >> port));
  if (port%2) i=0xf0; else i=0x0f;
  VAR(timer_interval[port/2]) &= i;
  VAR(timer_current[port/2]) &= i;
  dbg(DBG_CLOCK, ("Timer Interval = %x\n",VAR(timer_interval[port/2])));
  dbg(DBG_CLOCK, ("Reg = %x\n",VAR(reg)));
  return port;
}

void TOS_EVENT(TIMERS_CLOCK_EVENT)() {
  unsigned char r = VAR(reg);
  unsigned char i;

  dbg(DBG_CLOCK, ("TIMERS Event\n"));
  if((r & 0x80) && !(VAR(timer_current[0]) & 0xf0)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_0)(0);
    VAR(timer_current[0]) |= (VAR(timer_interval[0]) & 0xf0); 
    dbg(DBG_CLOCK, ("Firing Port 0\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[0]) & 0x0f)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_1)(1); 
    VAR(timer_current[0]) |= (VAR(timer_interval[0]) & 0x0f); 
    dbg(DBG_CLOCK, ("Firing Port 1\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[1]) & 0xf0)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_2)(2); 
    VAR(timer_current[1]) |= (VAR(timer_interval[1]) & 0xf0); 
    dbg(DBG_CLOCK, ("Firing Port 2\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[1]) & 0x0f)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_3)(3); 
    VAR(timer_current[1]) |= (VAR(timer_interval[1]) & 0x0f); 
    dbg(DBG_CLOCK, ("Firing Port 3\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[2]) & 0xf0)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_4)(4); 
    VAR(timer_current[2]) |= (VAR(timer_interval[2]) & 0xf0); 
    dbg(DBG_CLOCK, ("Firing Port 4\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[2]) & 0x0f)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_5)(5); 
    VAR(timer_current[2]) |= (VAR(timer_interval[2]) & 0x0f); 
    dbg(DBG_CLOCK, ("Firing Port 5\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[3]) & 0xf0)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_6)(6); 
    VAR(timer_current[3]) |= (VAR(timer_interval[3]) & 0xf0); 
    dbg(DBG_CLOCK, ("Firing Port 6\n"));
  }
  if(((r <<= 1) & 0x80) && !(VAR(timer_current[3]) & 0x0f)){
    TOS_SIGNAL_EVENT(TIMERS_FIRE_EVENT_PORT_7)(7); 
    VAR(timer_current[3]) |= (VAR(timer_interval[3]) & 0x0f); 
    dbg(DBG_CLOCK, ("Firing Port 7\n"));
  }

  // Decrement all registered current timers by 1
  r = VAR(reg);
  for (i=0; i<4; i++) {
    VAR(timer_current[i]) -= (((r & 0x80) >> 3) + ((r & 0x40) >> 6));
    r <<= 2;
  }
}

