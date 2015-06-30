/*									tab:4
 *
 *
 * "Copyright (c) 2002 Sam Madden and The Regents of the University 
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
 * Author:  Sam Madden (madden@cs.berkeley.edu)
 *
 *
 */
/* Test program for TINY_ALLOC.
   Does the following:
   
   - allocates three handles, toggling yellow led after each
   - writes "Sam was here" in #2
   - locks #2
   - frees #1
   - compacts , toggling red led
   - verifies #2, setting green led to verification status
   - unlocks #2
   - compacts
   - verifies #2, setting green led
   - repeatedly compacts
*/

#include "tos.h"
#include "alloc.h"
#include "TINY_ALLOC_TEST.h"
#include "dbg.h"



#define TOS_FRAME_TYPE TINY_ALLOC_TEST_frame
TOS_FRAME_BEGIN(TINY_ALLOC_TEST_frame) {
  char didFirst;
  Handle first;
  char didSecond;
  Handle second;
  char didThird;
  Handle third;
  char compacted;
  char didRealloc;
}
TOS_FRAME_END(TINY_ALLOC_TEST_frame);


char TOS_COMMAND(TINY_ALLOC_TEST_INIT)() {
  VAR(didFirst) = 0;
  VAR(didSecond) = 0;
  VAR(didThird) = 0;
  VAR(didRealloc) = 0;
  VAR(compacted) = 0;
  printf("inited\n");
#ifdef FULLPC
  CLOCK_EVENT_EVENT();
#else
  TOS_CALL_COMMAND(CLOCK_INIT)(tick1ps);
#endif
  return 0;
}

void TOS_EVENT(CLOCK_EVENT)() {
  printf("started\n");
  if (!VAR(didFirst)) {
    TOS_CALL_COMMAND(ALLOC)(&VAR(first), 10);
  } else if (!VAR(didSecond)) {
    TOS_CALL_COMMAND(ALLOC)(&VAR(second), 20);
  } else if (!VAR(didThird)) {
    strcpy(*VAR(second),"Sam was here.");
    //    TOS_CALL_COMMAND(LOCK)(&VAR(second));
    TOS_CALL_COMMAND(FREE)(VAR(first));
    TOS_CALL_COMMAND(ALLOC)(&VAR(third), 30);
  } else if (!VAR(didRealloc)) {
    TOS_CALL_COMMAND(REALLOC)(VAR(second), 40);
  } else {
    printf("Compacting\n");
    TOS_CALL_COMMAND(COMPACT)();
  }
}

char TOS_COMMAND(TINY_ALLOC_TEST_START)() {
  return 0;
}

void TOS_EVENT(COMPLETE)(Handle *handle, char complete) {
  printf("Something completed\n");
  if (complete) {
    if (handle == &VAR(first)) {
      TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
      TOS_CALL_COMMAND(ALLOC_DEBUG)();
      VAR(didFirst) = 1;
    } else if (handle == &VAR(second)) {
      if (VAR(didSecond)) {
	printf("realloced, SECOND = %s\n", *VAR(second));
	VAR(didRealloc) = 1;
	TOS_CALL_COMMAND(ALLOC_DEBUG)();
      } else {

	TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
	TOS_CALL_COMMAND(ALLOC_DEBUG)();
	VAR(didSecond) = 1;
      }
    } else if (handle == &VAR(third)) {
      TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
      TOS_CALL_COMMAND(ALLOC_DEBUG)();
      VAR(didThird) = 1;
    } else 
      printf("Unknown handle returned.\n");
  } else printf ("Failed to alloc.\n");
  #ifdef FULLPC
  CLOCK_EVENT_EVENT();
  #endif
}

void TOS_EVENT(REALLOC_COMPLETE)(Handle h, char complete) {
  if (h == VAR(first))   TOS_SIGNAL_EVENT(COMPLETE)(&VAR(first), complete);
  if (h == VAR(second))   TOS_SIGNAL_EVENT(COMPLETE)(&VAR(second), complete);
  if (h == VAR(third))   TOS_SIGNAL_EVENT(COMPLETE)(&VAR(third), complete);
}

void TOS_EVENT(COMPACT_COMPLETE)() {
  TOS_CALL_COMMAND(RED_LED_TOGGLE)();
   printf("Compact complete\n");
   printf("Second = %s\n",*VAR(second));
   if (strcmp(*VAR(second), "Sam was here.") == 0) {
      TOS_CALL_COMMAND(GREEN_LED_ON)();
   } else
     TOS_CALL_COMMAND(GREEN_LED_OFF)();

   TOS_CALL_COMMAND(ALLOC_DEBUG)();
   //   TOS_CALL_COMMAND(UNLOCK)(&VAR(second));
   #ifdef FULLPC
   TOS_CALL_COMMAND(COMPACT)();
   #endif
 }
