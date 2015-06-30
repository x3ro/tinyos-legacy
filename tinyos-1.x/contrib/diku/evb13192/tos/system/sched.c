// $Id: sched.c,v 1.1 2005/09/23 13:32:01 janflora Exp $

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
 * Authors:		Jason Hill, Philip Levis, Jan Flora
 * Revision:		$Id: sched.c,v 1.1 2005/09/23 13:32:01 janflora Exp $
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

volatile TOSH_sched_entry_T TOSH_queue[TOSH_MAX_TASKS];
uint8_t TOSH_sched_full;
volatile uint8_t TOSH_sched_free;
// No race conditions on this variable,
// since it is read/written in one instruction.
// (How do you tell NesC that? :-( norace = no good in C.
bool TOSH_run_tasks_allowed = TRUE;

/* These are provided in HPL.td */
void TOSH_wait(void);
void TOSH_sleep(void);

void TOSH_sched_init(void)
{
	int i;
	TOSH_sched_free = 0;
	TOSH_sched_full = 0;
	for (i = 0; i < TOSH_MAX_TASKS; i++)
		TOSH_queue[i].tp = NULL;
}

bool TOS_post(void (*tp) ());

#ifndef NESC_BUILD_BINARY

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
  
	if (TOSH_queue[tmp].tp == NULL) {
		TOSH_sched_free = (tmp + 1) & TOSH_TASK_BITMASK;
		TOSH_queue[tmp].tp = tp;
		__nesc_atomic_end(fInterruptFlags);
		return TRUE;
	} else {	
		__nesc_atomic_end(fInterruptFlags);
		return FALSE;
	}
}

#endif

/*
 * TOSH_schedule_task()
 *
 * Remove the task at the head of the queue and execute it, freeing
 * the queue entry. Return 1 if a task was executed, 0 if the queue
 * is empty.
 */

bool TOSH_run_next_task ()
{
	__nesc_atomic_t fInterruptFlags;
	uint8_t old_full;
	void (*func)(void);
  
	fInterruptFlags = __nesc_atomic_start();
	old_full = TOSH_sched_full;
	func = TOSH_queue[old_full].tp;
	if (func == NULL) {
		__nesc_atomic_end(fInterruptFlags);
		return 0;
	}

	TOSH_queue[old_full].tp = NULL;
	TOSH_sched_full = (old_full + 1) & TOSH_TASK_BITMASK;
	__nesc_atomic_end(fInterruptFlags);
	func();
	return 1;
}

/*
 * TOSH_allow_tasks()
 * 
 * Allows task execution to take place in TOSH_run_task()
 */
void TOSH_allow_tasks()
{
	TOSH_run_tasks_allowed = TRUE;	
}

/*
 * TOSH_disallow_tasks()
 * 
 * Disallows task execution to take place in TOSH_run_task()
 */
void TOSH_disallow_tasks()
{
	TOSH_run_tasks_allowed = FALSE;	
}

void TOSH_run_task()
{
	if (TOSH_run_tasks_allowed) {
		while (TOSH_run_next_task());
	}
	TOSH_sleep();
	TOSH_wait();
}
