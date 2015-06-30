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
 *   FILE: BLESS_TEST.c
 * AUTHOR: Phil Levis <pal@cs.berkeley.edu>
 *  DESCR: Beaconless routing protocol test program
 *
 * This program is a simple test of the BLESS protocol, to show how it
 * can be used. Every 5 seconds, BLESS_TEST_CLOCK is called, which
 * causes a message filled with 0xdeadbeef to be sent out.
 */

#include "tos.h"
#include "NAMING_TEST.h"
#include "dbg.h"

char TOS_COMMAND(NAMING_TEST_INIT)() {
   
  TOS_CALL_COMMAND(NAMING_TEST_CLOCK_INIT)(160, 0x07);
  return 1;
}

char TOS_COMMAND(NAMING_TEST_START)() {
  return 1;
}

void TOS_EVENT(NAMING_TEST_CLOCK)() {
  char data[26] = {0xde, 0xad, 0xbe, 0xef,
                   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef, 
		   0xde, 0xad, 0xbe, 0xef,
		   0xaa, 0xff};
  
  dbg(DBG_USR1, ("NAMING clock ticked!\n"));
  
  if (TOS_CALL_COMMAND(NAMING_ACTIVE)()) {
    TOS_CALL_COMMAND(NAMING_TEST_SEND)(data, (char)26);
  }
}

void TOS_EVENT(NAMING_TEST_RECEIVE)(char* data, char dataLen) {
  int i;
  dbg(DBG_USR1, ("Received naming packet!\n"));
  for (i = 0; i < dataLen; i++) {
    dbg(DBG_USR1, ("%2.0x ", data[i]));
  }
}
