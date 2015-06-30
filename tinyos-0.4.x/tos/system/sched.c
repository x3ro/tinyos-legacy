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

typedef struct {
//  int status;
  void (*tp) ();
//  void *fp;
} TOS_sched_entry_T;


#define MAX_THREADS 6

#define TOS_FRAME_TYPE SCHED_frame
TOS_FRAME_BEGIN(SCHED_frame) {
  TOS_sched_entry_T TOS_queue[MAX_THREADS];
  volatile char TOS_sched_full;
  volatile char TOS_sched_free;
}
TOS_FRAME_END(SCHED_frame);


#define EMPTY (VAR(TOS_sched_full) == VAR(TOS_sched_free)) 
#define ADVANCE(ptr) ptr = (ptr+1 == MAX_THREADS) ? 0 : ptr+1

/*
   TOS_empty

   return NULL is queue is non-empty

*/

void TOS_sched_init() {
  VAR(TOS_sched_free) = 0;
  VAR(TOS_sched_full) = 0;
}

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

  //dbg(DBG_SCHED, ("TOS_post: %d %x %x \n", VAR(TOS_sched_free), tp, fp));


  char return_val = 2;
  unsigned char tmp;
  char prev;
  char org;
  
  dbg(DBG_SCHED, ("TOS_post: %d 0x%x\n", VAR(TOS_sched_free), (int)tp));
  
  while(return_val == 2)  {
    prev = inp(SREG) & 0x80; // Determine whether interrupts are enabled
    tmp = VAR(TOS_sched_free);
    org = tmp;
    tmp ++;

    if(tmp == MAX_THREADS) tmp = 0;

    if(tmp == VAR(TOS_sched_full)){
      return_val = 0;
    }
    else{	
      cli(); // Disable interrupts

      if(org == VAR(TOS_sched_free)){
	VAR(TOS_sched_free) = tmp;
	VAR(TOS_queue)[(int)org].tp = tp;
	return_val = 1;
      }
      
      if(prev) {
	sei(); // If interrupts were enabled on entry, re-enable
      }
      
    }
  }
  return return_val;
/*
  char tmp;
  while(!compare_and_swap_double(&VAR(TOS_sched_free),tmp,  (tmp+1 == MAX_THREADS) ? 0 : tmp+1, &(VAR(TOS_queue)[(int)tmp].tp), 0, tp)) tmp = VAR(TOS_sched_free);
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
  int old_full = VAR(TOS_sched_full);
  if (EMPTY) {

    dbg(DBG_SCHED, ("TOS_schedule_task: %d empty \n", VAR(TOS_sched_full)));

    return -1;
  }
    // Prints out no longer used variables
    //dbg(DBG_SCHED, ("TOS_schedule_task: %d %d %x %x \n", 
    //       VAR(TOS_sched_full),
    //       VAR(TOS_queue)[old_full].status,
    //       VAR(TOS_queue)[old_full].tp,
    //       VAR(TOS_queue)[old_full].fp));

  ADVANCE(VAR(TOS_sched_full));
#ifdef OLDSTUFF
  VAR(TOS_queue)[old_full].status = TOS_Q_ACTIVE;
  VAR(TOS_queue)[old_full].tp(VAR(TOS_queue)[old_full].fp);
  VAR(TOS_queue)[old_full].status = TOS_Q_FREE;
#endif
  VAR(TOS_queue)[old_full].tp();
  VAR(TOS_queue)[old_full].tp = 0;
  return 0;
}

