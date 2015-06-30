/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

#ifdef PLATFORM_PC

/* Global information for TOSSIM. */

uint16_t BASE_IDS[] = {0};

bool __isBase() {
  int i = sizeof(BASE_IDS)/sizeof(uint16_t) - 1;
  for (; i >= 0; i--) {
    if (TOS_LOCAL_ADDRESS == BASE_IDS[i])
      return TRUE;
  }
  return FALSE;
}

uint16_t __gFinishedNodes = 0;

void __receivePage(uint16_t pageId) {
   char ftime[128];
   printTime(ftime, 128);
   dbg(DBG_USR1, "Received whole PAGE %d at %s\n", pageId, ftime);
}
 
void __finish() {  // Received all pages.
   char ftime[128];
   printTime(ftime, 128);
   dbg(DBG_USR1, "FINISHED at %s #%d\n", ftime, __gFinishedNodes);
   if (++__gFinishedNodes == tos_state.num_nodes) {
     exit(0);
   }
}

#endif

