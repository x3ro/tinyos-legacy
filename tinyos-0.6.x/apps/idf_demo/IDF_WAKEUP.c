/*									tab:4
 * WAKEUP.c
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:   Deepak Ganesan
 * History:   created 07/08/2001
 *
 *
 */

#include "tos.h"
#include "IDF_WAKEUP.h"
#include "dbg.h"

#define ALIVE 100
#define SHUTDOWN_NETWORK 101

// Set to 20 minutes at 16 ticks per sec
#define ALIVE_COUNTDOWN 19200
#define MAX_WAKEUP_NETWORK 20
#define SHUTDOWN_TIMEOUT 80

//your FRAME
#define TOS_FRAME_TYPE WAKEUP_frame
TOS_FRAME_BEGIN(WAKEUP_frame) {
  char state;			/* Component state */
  unsigned int counter;                 /* ttl */
}
TOS_FRAME_END(WAKEUP_frame);

/* WAKEUP_INIT:  
   turn on the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
char TOS_COMMAND(WAKEUP_INIT)(){
  /*
    The rene has been awakened by a wakeup signal
    Goto ALIVE state
  */
  
  VAR(state) = ALIVE;
  VAR(counter) = ALIVE_COUNTDOWN;

  dbg(DBG_BOOT, ("WAKEUP initialized\n"));
  return 1;
}

/* Clock Event Handler: 
   signaled at end of each clock interval.

 */

void TOS_EVENT(WAKEUP_CLOCK_EVENT)(){
  /*
    If state = ALIVE and counter has expired,
    Shutdown
  */
  if (VAR(state)==ALIVE && --VAR(counter)==0) {
    VAR(state)=SHUTDOWN_NETWORK;
    TOS_CALL_COMMAND(WAKEUP_SET_WATCHDOG)(period2048);
  }
}

/* 
     Command to Shutdown Rene recvd
*/
void TOS_COMMAND(SHUTDOWN)(){
  TOS_CALL_COMMAND(WAKEUP_SET_WATCHDOG)(period2048);  
}

/*
  Promiscous mode: intended for one of the other component handlers
  Notifies Wakeup Component that activity is taking place
*/
TOS_MsgPtr TOS_MSG_EVENT(PROMISCUOUS_MODE_MSG)(TOS_MsgPtr data){
  /*
    Packets are floating around. Mote resets ALIVE_COUNTDOWN and sets
    state to ALIVE
  */
  VAR(state) = ALIVE;
  VAR(counter) = ALIVE_COUNTDOWN;
  return data;
}
