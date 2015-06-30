// $Id: sched.c,v 1.2 2003/10/04 00:14:05 cssharp Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, Philip Levis
 * Revision:		$Id: sched.c,v 1.2 2003/10/04 00:14:05 cssharp Exp $
 * Modifications:       Removed unecessary code, cleanup.(5/30/02)
 *
 *                      Moved from non-blocking list to simple
 *                      critical section.  Changed task queue to
 *                      length 8 (more efficient). (3/10/02)
 */




/*
 * Scheduling data structures
 *
 * There is a list of size MAX_TASKS, stored as an cyclic array buffer.
 * TOSH_sched_full is the index of first used slot (head of list).
 * TOSH_sched_free is the index of first free slot (after tail of list).
 * If free equals full, the list is empty.
 * The list keeps at least one empty slot; one cannot add a task if
 * advancing free would make it equal to full.
 *
 * Each entry consists of a task function pointer.
 *
 */

typedef struct {
  void (*tp) ();
} TOSH_sched_entry_T;

enum {
  TOSH_MAX_TASKS = 32,
  TOSH_TASK_BITMASK = (TOSH_MAX_TASKS - 1)
};

TOSH_sched_entry_T TOSH_queue[TOSH_MAX_TASKS];
volatile uint8_t TOSH_sched_full;
volatile uint8_t TOSH_sched_free;

/* These are provided in HPL.td */
void TOSH_wait(void);
void TOSH_sleep(void);

void TOSH_sched_init(void)
{
  TOSH_sched_free = 0;
  TOSH_sched_full = 0;
}

bool TOS_empty(void) 
{
  return TOSH_sched_full == TOSH_sched_free;
}

/*
 * TOS_post (thread_pointer)
 *  
 * Put the task pointer into the next free slot.
 * Return 1 if successful, 0 if there is no free slot.
 *
 * This function uses a critical section to protect TOSH_sched_free.
 * As tasks can be posted in both interrupt and non-interrupt context,
 * this is necessary.
 */

bool TOS_post(void (*tp) ()) __attribute__((spontaneous)) {
  __nesc_atomic_t fInterruptFlags;
  uint8_t tmp;

  //  dbg(DBG_SCHED, ("TOSH_post: %d 0x%x\n", TOSH_sched_free, (int)tp));
  
  fInterruptFlags = __nesc_atomic_start();

  tmp = TOSH_sched_free;
  TOSH_sched_free++;
  TOSH_sched_free &= TOSH_TASK_BITMASK;
  
  if (TOSH_sched_free != TOSH_sched_full) {
    __nesc_atomic_end(fInterruptFlags);

    TOSH_queue[tmp].tp = tp;
    return TRUE;
  }
  else {	
    TOSH_sched_free = tmp;
    __nesc_atomic_end(fInterruptFlags);

    return FALSE;
  }
}

/*
 * TOSH_schedule_task()
 *
 * Remove the task at the head of the queue and execute it, freeing
 * the queue entry. Return 1 if a task was executed, 0 if the queue
 * is empty.
 *
 * This function does not need a critical section because it is only
 * run in non-interrupt context; therefore, TOSH_sched_full does not
 * need to be protected. It is possible for an interrupt to post a
 * task after this function determines the queue to be empty; this can
 * result in a latency in executing the task, as the system might go
 * to sleep and not wake up until the next interrupt.
 */

bool TOSH_run_next_task () {
  __nesc_atomic_t fInterruptFlags;
  uint8_t old_full;
  void (*func)(void);
  
  if (TOSH_sched_full == TOSH_sched_free) {
    //  dbg(DBG_SCHED, "TOSH_schedule_task: %d empty \n", TOSH_sched_full);
    return 0;
  }
  else {

    fInterruptFlags = __nesc_atomic_start();
    old_full = TOSH_sched_full;
    TOSH_sched_full++;
    TOSH_sched_full &= TOSH_TASK_BITMASK;
    func = TOSH_queue[(int)old_full].tp;
    TOSH_queue[(int)old_full].tp = 0;
    __nesc_atomic_end(fInterruptFlags);
    func();
    return 1;
  }
}

void TOSH_run_task() {
  while (TOSH_run_next_task()) 
    ;
  TOSH_sleep();
  TOSH_wait();
}
