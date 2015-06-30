/*									tab:2
 *
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
 * Authors:		Phil Levis
 *    Date:     Jul 24 2001
 *
 */

/*
 *   FILE: RADIO_TEST.c
 * AUTHOR: Phil Levis <pal@cs.berkeley.edu>
 *  DESCR: Beaconless routing protocol test program
 *
 * This program is a simple test of the BLESS protocol, to show how it
 * can be used. Every 5 seconds, RADIO_TEST_CLOCK is called, which
 * causes a message filled with 0xdeadbeef to be sent out.
 */

#include "tos.h"
#include "RADIO_TEST.h"
#include "dbg.h"

extern short TOS_LOCAL_ADDRESS;
char counter = 0;
char TOS_COMMAND(RADIO_TEST_INIT)() {
   
  TOS_CALL_COMMAND(RADIO_TEST_CLOCK_INIT)(0, 0x02);
  return 1;
}

char TOS_COMMAND(RADIO_TEST_START)() {
  return 1;
}

void TOS_EVENT(RADIO_TEST_CLOCK)() {
  char data[23] = {0xde, 0xad, 0xbe, 0xef,
                   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef, 
		   0xde, 0xad, 0xbb};
  
  dbg(DBG_USR1, ("BLESS clock in mote %hi ticked!\n", TOS_LOCAL_ADDRESS));
  
  //if ((counter ^ TOS_LOCAL_ADDRESS) & 0x1) {
      TOS_CALL_COMMAND(RADIO_TEST_SEND)(data, (char)26);
      //}
      //if (TOS_LOCAL_ADDRESS == 0) {
      //  counter++;
      //}
  
  TOS_CALL_COMMAND(RADIO_TEST_LED1_TOGGLE)();

  if (TOS_CALL_COMMAND(BLESS_LOUD_ACTIVE)()) {
	TOS_CALL_COMMAND(RADIO_TEST_LED3_ON)();
  }
  else {
	TOS_CALL_COMMAND(RADIO_TEST_LED3_OFF)();
  }
}
