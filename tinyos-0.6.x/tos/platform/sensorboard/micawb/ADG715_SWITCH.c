/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:	        Joe Polastre
 *
 *
 */

#include "tos.h"
#include "ADG715_SWITCH.h"
#include "dbg.h"

#define GET_SWITCH     10
#define SET_SWITCH     11
#define SET_SWITCH_ALL 12
#define SET_SWITCH_GET 13
#define IDLE           99

#define TOS_FRAME_TYPE ADG715_SWITCH_obj_frame
TOS_FRAME_BEGIN(ADG715_SWITCH_obj_frame) {
        char sw_state; /* current state of the switch */
	char state;    /* current state of the i2c request */
        char addr;     /* destination address */
	char position;
	char value;
}
TOS_FRAME_END(ADG715_SWITCH_obj_frame);

char TOS_COMMAND(ADG715_INIT)()
{
  VAR(state) = IDLE;
  TOS_CALL_COMMAND(ADG715_SUB_INIT)();
  return 1;
}

char TOS_COMMAND(ADG715_SET_SWITCH)(char addr, char position, char value)
{
  if (VAR(state) == IDLE)
  {
      VAR(state) = SET_SWITCH_GET;
      VAR(addr) = addr;
      VAR(value) = value;
      VAR(position) = position;
      return TOS_CALL_COMMAND(ADG715_READ_PACKET)(addr, 1, 0x01);
  }
  return 0;
}

char TOS_COMMAND(ADG715_SET_SWITCH_ALL)(char addr, char value)
{
  if (VAR(state) == IDLE)
  {
    VAR(state) = SET_SWITCH_ALL;
    VAR(sw_state) = value;
    VAR(addr) = addr;

    return TOS_CALL_COMMAND(ADG715_WRITE_PACKET)(VAR(addr), 1, (char*)(&VAR(sw_state)), 0x01);
  }
  return 0;
}

char TOS_COMMAND(ADG715_GET_SWITCH)(char addr)
{
  if (VAR(state) == IDLE)
  {
    VAR(state) = GET_SWITCH;
    VAR(addr) = addr;
    return TOS_CALL_COMMAND(ADG715_READ_PACKET)(addr, 1, 0x01);
  }
  return 0;
}

char TOS_EVENT(ADG715_READ_PACKET_DONE)(char length, char* data)
{
  char value = VAR(value);
  if (VAR(state) == GET_SWITCH)
  {
    if (length != 1)
    {
      VAR(state) = IDLE;
      TOS_SIGNAL_EVENT(ADG715_GET_SWITCH_DONE)(0);
      return 1;
    }
    else {
      VAR(state) = IDLE;
      TOS_SIGNAL_EVENT(ADG715_GET_SWITCH_DONE)(data[0]);
      return 1;
    }
  }
  if (VAR(state) == SET_SWITCH_GET)
  {
    if (length != 1)
    {
      VAR(state) = IDLE;
      TOS_SIGNAL_EVENT(ADG715_SET_SWITCH_DONE)(0);
      return 1;
    }

    VAR(sw_state) = data[0];

    if (VAR(position) == 1) {
      VAR(sw_state) = VAR(sw_state) & 0xFE;
      VAR(sw_state) = VAR(sw_state) | value;
    }
    if (VAR(position) == 2) {
      VAR(sw_state) = VAR(sw_state) & 0xFD;
      VAR(sw_state) = VAR(sw_state) | (value << 1);
    }
    if (VAR(position) == 3) {
      VAR(sw_state) = VAR(sw_state) & 0xFB;
      VAR(sw_state) = VAR(sw_state) | (value << 2);
    }
    if (VAR(position) == 4) {
      VAR(sw_state) = VAR(sw_state) & 0xF7;
      VAR(sw_state) = VAR(sw_state) | (value << 3);
    }
    if (VAR(position) == 5) {
      VAR(sw_state) = VAR(sw_state) & 0xEF;
      VAR(sw_state) = VAR(sw_state) | (value << 4);
    }
    if (VAR(position) == 6) {
      VAR(sw_state) = VAR(sw_state) & 0xDF;
      VAR(sw_state) = VAR(sw_state) | (value << 5);
    }
    if (VAR(position) == 7) {
      VAR(sw_state) = VAR(sw_state) & 0xBF;
      VAR(sw_state) = VAR(sw_state) | (value << 6);
    }
    if (VAR(position) == 7) {
      VAR(sw_state) = VAR(sw_state) & 0x7F;
      VAR(sw_state) = VAR(sw_state) | (value << 7);
    }
    data[0] = VAR(sw_state);
    VAR(state) = SET_SWITCH;
    dbg(DBG_USR1, ("%i\n", data[0]));
    TOS_CALL_COMMAND(ADG715_WRITE_PACKET)(VAR(addr), 1, &VAR(sw_state), 0x01);
    return 1;
  } 
  return 1;
}

char TOS_EVENT(ADG715_WRITE_PACKET_DONE)(char success)
{
  if (VAR(state) == SET_SWITCH)
  {
    TOS_SIGNAL_EVENT(ADG715_SET_SWITCH_DONE)(success);
    VAR(state) = IDLE;
  }
  else if (VAR(state) == SET_SWITCH_ALL) {
      //    TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
    TOS_SIGNAL_EVENT(ADG715_SET_SWITCH_ALL_DONE)(success);
    VAR(state) = IDLE;
  }
  return 1;
}
