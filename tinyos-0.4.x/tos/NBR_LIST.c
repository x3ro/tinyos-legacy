/*									tab:4
 * NBR_LIST.c
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
#include "NBR_LIST.h"

/* Refresh NeighborList every 2 secs */
#define NBR_LIST_REFRESH_RATE 0x1f

#define MAXNBRS 8
#define NBRMASK 7

//your FRAME
#define TOS_FRAME_TYPE NBR_LIST_frame
TOS_FRAME_BEGIN(NBR_LIST_frame) {
  short nbrlist[MAXNBRS];	/* list of neighbors */
  unsigned char endptr;			/* revolvng ptr to insert into nbrlist */  
  unsigned char startptr;
  unsigned char free_counter;
}
TOS_FRAME_END(NBR_LIST_frame);

TOS_TASK(Update_NbrList) {
  VAR(nbrlist)[VAR(endptr)] = 0;
  VAR(endptr) = (VAR(endptr)+1) & NBRMASK;
  return;
}

char TOS_COMMAND(NBR_LIST_INIT)(){
  int i;
  CLR_RED_LED_PIN();
 /* initialize lower components 
    when used standalone.
 */
  //  TOS_CALL_COMMAND(NBR_LIST_SUB_INIT)();

  for (i=0; i<MAXNBRS; i++) VAR(nbrlist)[i] = 0;
  VAR(startptr) = 0;
  VAR(endptr) = 0;

  VAR(free_counter)=0;

  printf("NBR_LIST initialized\n");
  return 1;
}

/*
char TOS_COMMAND(NBR_LIST_LOOKUP)(short nbr) {
  int i;
  for (i = 0; i< MAXNBRS; i++) {
    if (VAR(nbrlist)[i] == nbr) return 1;
  }
  return 0;
}
*/

void TOS_COMMAND(NBR_LIST_INSERT)(short nbr) {
  int i;
  VAR(nbrlist)[VAR(startptr)] = nbr;
  for (i=0; i<MAXNBRS; i++)
    if (i!=VAR(startptr) && VAR(nbrlist)[i]==nbr) VAR(nbrlist)[i]=0;

  if (VAR(startptr)==VAR(endptr)) VAR(endptr) = (VAR(endptr)+1) & NBRMASK;
  VAR(startptr) = (VAR(startptr)+1) & NBRMASK;
}

char TOS_COMMAND(NBR_LIST_GET_COUNT)() {
  unsigned char i;
  char sum;
  sum=0;
  for (i=0; i<MAXNBRS; i++)
    if (VAR(nbrlist)[i] != 0) sum++;
  
  return sum;
}

/* Clock Event Handler: 
   signaled at end of each clock interval.

 */
void TOS_EVENT(NBR_LIST_CLOCK_EVENT)(){
  VAR(free_counter)++;
  if ((VAR(free_counter) & NBR_LIST_REFRESH_RATE)==0) TOS_POST_TASK(Update_NbrList);
}
