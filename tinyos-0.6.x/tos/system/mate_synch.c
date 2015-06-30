/*									tab:4
 * mate_sync.c - Higher level synchronization utilties -- yielding, etc.
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:   Philip Levis
 * History:   created 4/18/2002
 *
 */

char check_runnable(context_t* context);
void executeContext(context_t* context);
void haltContext(context_t* context);
void resumeContext(context_t* context, context_t* resumed);
void resetContext(context_t* context);
char run(context_t* context);

void resumeContext(context_t* context, context_t* resumed) {
  char result;
  dbg(DBG_USR2, ("VM: Resuming context %hhi on capsule %hhi with instruction %hhi.\n", resumed->which, resumed->code->capsule.type, resumed->pc));
  result = (char)check_runnable(resumed);
  if (result) {
    resumed->state = STATE_RUN;
    run(resumed);
  }
  else {
    resumed->state = STATE_LOCK_WAIT;
    mqueue_enqueue(context, &VAR(readyQueue), resumed);
  }
}

/*
 * Here's where we decide which contexts to resume.
 * There are several options. The first one is the one implemented below.
 *
 * 1) Scan queue depth major -- scan all queue heads, then all queue entries
 *    one behind the head, etc. This prevents a context not on the head of
 *    any queue from being scheduled before contexts on the head of queues.
 *    This still has the problem where a context at the head of an early
 *    queue can be scheduled before contexts ahead of it in other queues.
 *    Requiring that a context be at the head of all of its queues can
 *    cause deadlock during lock yielding at blocking operations. The fairness
 *    issue can be solved by randomizing the queue search order.
 *
 * 2) Scan queue major -- Each queue is scanned completely, in order. This
 *    means that a context not on the head of any queue can be scheduled
 *    before contexts on the heads of queues.
 *
 * 3) Check each context -- Instead of scanning lock queues, just check each
 *    context individually. This saves a lot of overhead, makes scheduling
 *    decisions in terms of the contexts instead of the locks they hold.
 *    Contexts can be given priorities, etc. This starts to look like a more
 *    traditional scheduler.
 */

void schedule(context_t* context) {
  context_t* start;
  context_t* current;
  start = NULL;
  dbg(DBG_USR2, ("VM: (%i) Calling schedule()\n", (int)context->which));
  if (!list_empty(&VAR(readyQueue).queue)) {
    do {
      current = mqueue_dequeue(context, &VAR(readyQueue));
      if (check_runnable(current)) {
	run(current);
      }
      else {
	if (start == NULL) {
	  start = current;
	}
	else if (start == current) {
	    mqueue_enqueue(context, &VAR(readyQueue), current);
	    break;
	  }
	mqueue_enqueue(context, &VAR(readyQueue), current);
      }
    }
    while (!list_empty(&VAR(readyQueue).queue));
  }
}

/*void schedule(context_t* context) {
  int i;
  dbg(DBG_USR1, ("VM: Checking if context %i yield allows other contexts to run.\n", (int)context->which));
  for (i = 0; i < MATE_MAX_PARALLEL; i++) {
    int j;
    for (j = 0; j < MATE_HEAPSIZE; j++) {
      if (i == 0) {
	//dbg(DBG_USR2, ("VM: Lock queue %i: [%hhi]<-[%hhi]<-[%hhi]<-[%hhi]\n", j, (VAR(locks)[j].list[0]? VAR(locks)[j].list[0]->which:0), (VAR(locks)[j].list[1]? VAR(locks)[j].list[1]->which:0), (VAR(locks)[j].list[2]? VAR(locks)[j].list[2]->which:0), (VAR(locks)[j].list[3]? VAR(locks)[j].list[3]->which:0)));
      }
      if (i < VAR(locks)[j].size && 
	  VAR(locks)[j].list[i] &&
	  VAR(locks)[j].list[i]->state != STATE_RUN &&
	  VAR(locks)[j].list[i] != context) {
        dbg(DBG_USR2, ("VM: (%hhi) Resuming context %hhi.\n", context->which, VAR(locks)[j].list[i]->which));
	// This will retake all of the necessary locks
	resumeContext(VAR(locks)[j].list[i]);
      }
    }
  }
  }*/



char yield(context_t* context) {
  unsigned char i;
  dbg(DBG_USR2, ("VM: Context %i yielding.\n", (int)context->which));
  for (i = 0; i < MATE_HEAPSIZE; i++) {
    if (context->relinquishSet & (1 << i)) {
      dbg(DBG_USR2, ("VM: Context %i yielding lock %i\n", (int)context->which, i));
      unlock(context, i);
    }
  }
  context->relinquishSet = 0;
  schedule(context);
  if (context->state == STATE_RUN && !check_runnable(context)) {
    mqueue_enqueue(context, &VAR(readyQueue), context);
  }
  //schedule(context);
  return 1;
}


char run(context_t* context) {
  unsigned char i;
  short neededVars;
  neededVars = (context->acquireSet);
  dbg(DBG_USR2, ("VM: Running context %hhi.\n", context->which));
  for (i = 0; i < MATE_HEAPSIZE; i++) {
    if (neededVars & (1 << i)) {
      if (VAR(locks)[i].holder == context) {
	// do nothing
      }
      else if (VAR(locks)[i].holder == 0) {
	lock(context, i);
      }
      else {
	enter_error_state(context, ERROR_INVALID_RUNNABLE);
	return 0;
      }
    }
  }
  if (context->queue) {
    mqueue_remove(context, context->queue, context);
  }
  context->acquireSet = 0;
  context->state = STATE_RUN;
  executeContext(context);
  return 1;
}

char check_runnable(context_t* context) {
  int i;
  char rval;
  short neededLocks;
  neededLocks = (context->acquireSet);
  dbg(DBG_USR2, ("VM: Checking whether %i runnable.\n", (int)context->which));
  rval = 1;
  for (i = 0; i < MATE_HEAPSIZE; i++) {
    if (neededLocks & (1 << i)) {
      if ((VAR(locks)[i].holder != 0) &&
	  (VAR(locks)[i].holder != context)) {
	dbg(DBG_USR2, ("VM: Checking whether context %i owns lock %i: no\n",  (int)context->which, i));
	context->state = STATE_LOCK_WAIT;
	rval = 0;
      }
      else {
	dbg(DBG_USR2, ("VM: Checking whether context %i owns lock %i: yes\n",  (int)context->which, i));
      }
    }
  }
  return rval;
}

void haltContext(context_t* context) {
  int i;
  dbg(DBG_USR2, ("VM: Halting context %i\n", (int)context->which));
  for (i = MATE_HEAPSIZE - 1; i >= 0; i--) {
    if (context->heldSet & (1 << i)) {
      if (VAR(locks)[i].holder == context) {
	unlock(context, i);
      }
      else {
	enter_error_state(context, ERROR_UNLOCK_INVALID);
      }
    }
  }
  context->heldSet = 0;
  context->relinquishSet = 0;
  context->acquireSet = 0;
  
  schedule(context);
  if (context == &VAR(recvContext)) {
    VAR(recvContextActive) = 0;
  }
  if (context == &VAR(sendContext)) {
    VAR(sendContextActive) = 0;
  }
  context->state = STATE_HALT;
  context->pc = 0;
}

void resetContext(context_t* context) {
  if (context->state != STATE_HALT) {haltContext(context);}
  context->pc        = 0;
  context->stack.sp  = 0;
  context->rstack.sp = 0;
  context->state     = STATE_HALT;
  context->condition = 0;
}
