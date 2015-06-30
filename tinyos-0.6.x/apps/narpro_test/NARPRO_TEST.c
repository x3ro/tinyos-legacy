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
 * Authors:	Phil Levis
 *              Nelson Lee
 *    Date:     July 24 2001
 *              June 6 2002
 *
 */

/*
 *   FILE: NARPRO_TEST.c
 * AUTHOR: Nelson Lee
 *  DESCR: Beaconless routing protocol test program
 *
 * This program is a simple test of the NARPRO protocol, to show how it
 * can be used. Every 5 seconds, NARPRO_TEST_CLOCK is called, which
 * causes a message filled with 0xdeadbeef to be sent out.
 */

#include "tos.h"
#include "NARPRO_TEST.h"
#include "dbg.h"

char TOS_COMMAND(NARPRO_TEST_INIT)() {
   
  TOS_CALL_COMMAND(NARPRO_TEST_CLOCK_INIT)(32, 0x07);
  return 1;
}

char TOS_COMMAND(NARPRO_TEST_START)() {
  return 1;
}

void TOS_EVENT(NARPRO_TEST_CLOCK)() {
  char data[26] = {0xde, 0xad, 0xbe, 0xef,
                   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef,
		   0xde, 0xad, 0xbe, 0xef, 
		   0xde, 0xad, 0xbe, 0xef,
		   0xaa, 0xff};
  
  dbg(DBG_USR1, ("NARPRO clock ticked!\n"));
  TOS_CALL_COMMAND(NARPRO_TEST_SEND)(data, (char)26);
  //TOS_CALL_COMMAND(NARPRO_TEST_RED_LED_TOGGLE)();

  //if (TOS_CALL_COMMAND(NARPRO_ACTIVE)()) {
  //TOS_CALL_COMMAND(NARPRO_TEST_LED3_ON)();
  //}
  //else {
  //TOS_CALL_COMMAND(NARPRO_TEST_YELLOW_LED_OFF)();
    //}
}








