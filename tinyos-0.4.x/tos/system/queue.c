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


TOS_queue __SCHED_QUEUE__;

#define EMPTY(q) ((q).full == (q).free) 
#define ADVANCE(ptr, SIZE) ptr = (ptr+1 == SIZE) ? 0 : ptr+1

/*
   TOS_empty

   return NULL is queue is non-empty

*/

int TOSQ_empty (TOS_queue *q) 
{
	return (EMPTY(*q));
}

/*
   TOS_post (thread_pointer, frame_pointer)

   Post the associated thread to the next free slot
   Error of scheduling queue overflows

*/

static inline char compare_and_swap_double(char * x, char y, char z, char **a, char *b, char *c){

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

void TOSQ_enqueue (TOS_queue *q, char *el) 
{

  dbg(DBG_SCHED, ("TOSQ_enqueue: %d %x\n", q->free, el));

   char tmp = q->free;
   while(!compare_and_swap_double(&(q->free),tmp,  (tmp+1 == MAX_THREADS) ? 0 : tmp+1, &(q->queue[(int)tmp]), 0, el)) tmp = q->free;
}

/*
   TOS_dequeue()

   If the queue is non-empty, remove the next task and execute it, freeing the
   queue entry.

   return NULL is some task was ready and executed.
   return -1 if empty.

*/

char * TOSQ_dequeue (TOS_queue *q)
{
    int old_full = q->full;
    char * ret;
    if (EMPTY(*q)) {

	dbg(DBG_SCHED, ("TOS_schedule_task: %d empty \n", q->full));

	return (char *)0;
    }

    dbg(DBG_SCHED, ("TOS_schedule_task: %d %d %x %x \n", q->full, q->queue[old_full]));

    ADVANCE(q->full, MAX_THREADS);
    ret = q->queue[old_full];
    q->queue[old_full] = (char *) 0;
    return ret;
}

/* Schedule next task, return NULL if some task ready */

int TOS_schedule_task() {
    void (*tp)();
    tp = TOSQ_dequeue(&__SCHED_QUEUE__);
    if (tp) {
	tp();
	return 0;
    } else {
	return -1;
    }
}
