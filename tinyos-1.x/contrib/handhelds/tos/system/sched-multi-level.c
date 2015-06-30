// $Id: sched-multi-level.c,v 1.1 2005/07/29 18:29:31 adchristian Exp $

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
 * Revision:		$Id: sched-multi-level.c,v 1.1 2005/07/29 18:29:31 adchristian Exp $
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
#ifdef TOSH_MAX_TASKS_LOG2
#if TOSH_MAX_TASKS_LOG2 > 8
#error "Maximum of 256 tasks, TOSH_MAX_TASKS_LOG2 must be <= 8"
#endif
  TOSH_MAX_TASKS = 1 << TOSH_MAX_TASKS_LOG2,
#else
  TOSH_MAX_TASKS = 8,
#endif
  TOSH_TASK_BITMASK = (TOSH_MAX_TASKS - 1)
};

#define NUM_RUN_LEVELS 3
volatile TOSH_sched_entry_T TOSH_queue[NUM_RUN_LEVELS][TOSH_MAX_TASKS];
uint8_t TOSH_sched_full[NUM_RUN_LEVELS];
uint8_t TOSH_current_run_level = NUM_RUN_LEVELS;
volatile uint8_t TOSH_sched_free[NUM_RUN_LEVELS];

/* These are provided in HPL.td */
void TOSH_wait(void);
void TOSH_sleep(void);

bool TOS_post_level(void (*tp) (),uint8_t level) __attribute__((spontaneous));


void TOSH_sched_init(void)
{
  int i;
  for (i=0; i < NUM_RUN_LEVELS; i++)
    {
      TOSH_sched_free[i] = 0;
      TOSH_sched_full[i] = 0;
    }
  
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
  return TOS_post_level(tp,1);  
}
//bavery XXX
bool TOS_post_level(void (*tp) (),uint8_t level) __attribute__((spontaneous)) {
  __nesc_atomic_t fInterruptFlags;
  uint8_t tmp;
  
  
  //  dbg(DBG_SCHED, ("TOSH_post: %d 0x%x\n", TOSH_sched_free, (int)tp));
  
  fInterruptFlags = __nesc_atomic_start();

  tmp = TOSH_sched_free[level];
  
  if (TOSH_queue[level][tmp].tp == NULL) {
    TOSH_sched_free[level] = (tmp + 1) & TOSH_TASK_BITMASK;
    TOSH_queue[level][tmp].tp = tp;
    __nesc_atomic_end(fInterruptFlags);

    return TRUE;
  }
  else {	
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
 */

bool TOSH_run_next_task (int levels)
{
  __nesc_atomic_t fInterruptFlags;
  uint8_t old_full = 0;
  void (*func)(void) = NULL;
  uint8_t i;
  
  fInterruptFlags = __nesc_atomic_start();
  for (i=0; i < levels;i++){
    old_full = TOSH_sched_full[i];
    func = TOSH_queue[i][old_full].tp;
    if (func)
      break;
  }
  if (func == NULL)
    {
      TOSH_current_run_level = levels; // either NUM_RUN_LEVELS or cur level +1      
      __nesc_atomic_end(fInterruptFlags);
      return 0;
    }

  // we broke out of the loop w/ a func so i is stil the
  // run level if func != NULL
  TOSH_current_run_level = i;  
  TOSH_queue[i][old_full].tp = NULL;
  TOSH_sched_full[i] = (old_full + 1) & TOSH_TASK_BITMASK;
  __nesc_atomic_end(fInterruptFlags);
  func();

  return 1;
}

void TOSH_run_task() {
  while (TOSH_run_next_task(NUM_RUN_LEVELS)) 
    ;
  TOSH_sleep();
  TOSH_wait();
}
// this should let a low priority task hang out till all the higher priority tasks have been run.
// then it can resume  at most this should increase stack by NUM_RUN_LEVELS-1
void TOSH_yield() {
  int orig_level;  
  
  orig_level = TOSH_current_run_level;  
  while (TOSH_run_next_task(orig_level))
    ;
  
  // after we are done. restore the level
  TOSH_current_run_level = orig_level;  

}

