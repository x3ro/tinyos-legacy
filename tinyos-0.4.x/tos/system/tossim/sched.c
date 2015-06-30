/*									tab:4
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
 * Authors:		Jason Hill
 *
 *
 */


#include "tos.h"
#include "dbg.h"
#include "tossim.h"

/* Scheduling data structure

cyclic buffer of size MAX_THREADS
 TOS_sched_full: index of first full slot
 TOS_sched_free: index of first free slot 
 empty if free == full
 overflow if advancing free would make full == free

 Each entry consists of a status field, frame pointer, and thread pointer
*/

#define TOS_Q_FREE 0;
#define TOS_Q_READY 1;
#define TOS_Q_ACTIVE 2;

extern short TOS_LOCAL_ADDRESS;

typedef struct {
  int moteID;
  void (*tp) ();
//  void *fp;
} TOS_sched_entry_T;


#define MAX_THREADS 6
TOS_sched_entry_T TOS_queue[TOSNODES][MAX_THREADS];
volatile char TOS_sched_full[TOSNODES];
volatile char TOS_sched_free[TOSNODES];


#define EMPTY (TOS_sched_full[NODE_NUM] == TOS_sched_free[NODE_NUM]) 
#define ADVANCE(ptr) ptr = (ptr+1 == MAX_THREADS) ? 0 : ptr+1

/*
   TOS_empty

   return NULL is queue is non-empty

*/

int TOS_empty () 
{
	return (EMPTY);
}

/*
   TOS_post (thread_pointer, frame_pointer)

   Post the associated thread to the next free slot
   Error of scheduling queue overflows

*/

static inline char compare_and_swap_double(char * x, char y, char z, void(**a)(), void (*b)(), void (*c)()){

        char prev = inp(SREG) & 0x80;
        cli();

        if(*x == y && *a == b) {
                *x = z;
                *a = c;
                if(prev) sei();
                return 0x1;
        }

        if(prev) sei();
        return 0;
}

char TOS_post (void (*tp) ()) 
{

  //dbg(DBG_SCHED, ("TOS_post: %d %x %x \n", TOS_sched_free, tp, fp));


  char return_val = 2;
  unsigned char tmp;
  char prev;
  char org;
  
  dbg(DBG_SCHED, ("TOS_post: %d 0x%x\n", TOS_sched_free[NODE_NUM], (int)tp));
  
  while(return_val == 2)
  {
        prev = inp(SREG) & 0x80;
  	tmp = TOS_sched_free[NODE_NUM];
	org = tmp;
  	tmp ++;
  	if(tmp == MAX_THREADS) tmp = 0;
  	if(tmp == TOS_sched_full[NODE_NUM]){
		return_val = 0;
	}else{	
		cli();
		if(org == TOS_sched_free[NODE_NUM]){
			TOS_sched_free[NODE_NUM] = tmp;
			TOS_queue[NODE_NUM][(int)org].tp = tp;
			TOS_queue[NODE_NUM][(int)org].moteID = tos_state.current_node;
			return_val = 1;
		}
	        if(prev) sei();
  	}
  }
  return return_val;
/*
  char tmp;
  while(!compare_and_swap_double(&TOS_sched_free,tmp,  (tmp+1 == MAX_THREADS) ? 0 : tmp+1, &(TOS_queue[(int)tmp].tp), 0, tp)) tmp = TOS_sched_free;
*/

}

/*
   TOS_schedule_task()

   If the queue is non-empty, remove the next task and execute it, freeing the
   queue entry.

   return NULL is some task was ready and executed.
   return -1 if empty.

*/

/* Schedule next task, return NULL if some task ready */
int TOS_schedule_task ()
{
  char old_full = TOS_sched_full[NODE_NUM];
  if (EMPTY) {

    dbg(DBG_SCHED, ("TOS_schedule_task: %d empty \n", TOS_sched_full[NODE_NUM]));

    return -1;
  }
    // Prints out no longer used variables
    //dbg(DBG_SCHED, ("TOS_schedule_task: %d %d %x %x \n", 
    //       TOS_sched_full,
    //       TOS_queue[old_full].status,
    //       TOS_queue[old_full].tp,
    //       TOS_queue[old_full].fp));

  ADVANCE(TOS_sched_full[NODE_NUM]);
#ifdef OLDSTUFF
  TOS_queue[NODE_NUM][old_full].status = TOS_Q_ACTIVE;
  TOS_queue[NODE_NUM][old_full].tp(TOS_queue[old_full].fp);
  TOS_queue[NODE_NUM][old_full].status = TOS_Q_FREE;
#endif
  TOS_LOCAL_ADDRESS = (short)(TOS_queue[NODE_NUM][(int)old_full].moteID & 0xffff);
  TOS_queue[NODE_NUM][(int)old_full].tp();
  TOS_queue[NODE_NUM][(int)old_full].tp = 0;
  return 0;
}

