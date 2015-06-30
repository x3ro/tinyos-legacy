/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/**
 * Fibers provide a simple, cooperative threading mechanism for TinyOS.
 * The basic idea is to allow application code to run within a fiber 
 * context, where it may block. Regular TinyOS code (interrupt handlers, 
 * tasks, etc.) run on the default stack. Because of the stack overhead for 
 * each fiber it is important not to have too many fibers; we prefer to
 * support a single fiber (in addition to the default TinyOS context).
 */
#ifdef PLATFORM_PC
// Linux x86
includes setjmp;
#endif
#ifdef PLATFORM_MICA
// AVR
includes setjmpavr;
#endif
includes Fiber;

module FiberM {

  provides interface StdControl;
  provides interface Fiber;

} implementation {

  typedef struct _fiber_internal_t {
    bool running;
    jmp_buf jmpbuf;
    void *(*startfn)(void *arg);
    void *startfnarg;
    uint8_t stack[MAX_STACK_SIZE];
  } fiber_internal_t;

  char test1;
  char test2[10];

  fiber_t *cur_fiber;
  jmp_buf main_jmpbuf;
  fiber_t fibers[MAX_FIBERS];
  fiber_internal_t fibers_internal[MAX_FIBERS];
  int num_fibers;
  fiber_t *run_queue;

  void suspend();
  void schedule();
  task void schedule_task();
  void queue_add(fiber_t **queue, fiber_t *fiber);
  fiber_t *queue_remove(fiber_t **queue);

  command result_t StdControl.init() {
    int i;
    test1 = 0;
    test2[0] = 0;
    dbg(DBG_USR2,"FiberM: StdControl.init\n");
    num_fibers = 0;
    run_queue = NULL;
    for (i = 0; i < MAX_FIBERS; i++) {
      dbg(DBG_USR2,"FiberM: [%d] 0x%lx internal 0x%lx stack 0x%lx stackend 0x%lx\n",
	  i, &fibers[i], &fibers_internal[i], 
	  fibers_internal[i].stack,
	  fibers_internal[i].stack+(MAX_STACK_SIZE));
      fibers[i].queue = NULL;
      fibers[i].next = NULL;
      fibers[i].internal = &fibers_internal[i];
      fibers_internal[i].running = FALSE;
    }
    return SUCCESS;
  }
  command result_t StdControl.start() {
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  // Suspend the current fiber and return to the schedule_task
  void suspend() {
    dbg(DBG_USR2,"FiberM: Suspending current fiber\n");
    longjmp(main_jmpbuf, 0);
  }

  // Schedule the fiber at the head of the run queue.
  // Does not suspend the current fiber (should have been done already)
  void schedule() {
    cur_fiber = queue_remove(&run_queue);
    if (cur_fiber != NULL) {
      dbg(DBG_USR2,"FiberM: Switching to fiber %d\n", cur_fiber->fiber_num);
      longjmp(((fiber_internal_t *)cur_fiber->internal)->jmpbuf, 0);
    } else {
      dbg(DBG_USR2,"FiberM: No fibers to run\n");
      longjmp(main_jmpbuf, 0);
    }
  }

  // When the scheduler goes idle we longjmp back to this task which 
  // will "resume" in the main context (i.e. not in any fiber). 
  // By returning here we effectively re-enter the task processing loop.
  task void schedule_task() {
    dbg(DBG_USR2,"FiberM: schedule_task running\n");
    // Save our context
    if (!setjmp(main_jmpbuf)) {
      // Returning directly - schedule a fiber
      schedule();
    } else {
      // Resuming after the scheduled fiber does a suspend()
      dbg(DBG_USR2, "FiberM: schedule_task resumed\n");
      if (run_queue != NULL) post schedule_task();
      else {
	dbg(DBG_USR2, "FiberM: run_queue empty, not reposting schedule_task\n");
      }
    }
  }

  // Add a fiber to the given queue
  void queue_add(fiber_t **queue, fiber_t *fiber) {
    dbg(DBG_USR2,"FiberM: Adding fiber %d to queue 0x%lx\n", 
	fiber->fiber_num, queue);
    if (*queue == NULL) {
      *queue = fiber;
      fiber->next = NULL;
    } else {
      fiber->next = *queue;
      *queue = fiber;
    }
    fiber->queue = queue;
  }

  // Remove a fiber from the tail of the given queue and return it
  fiber_t *queue_remove(fiber_t **queue) {
    fiber_t *f = *queue, *last = *queue, *previous = NULL;

    while (f != NULL) {
      f = f->next;
      if (last->next != NULL && last->next->next == NULL) previous = last;
      if (f != NULL) last = f;
    }
    if (previous == NULL) {
      *queue = NULL;
    } else {
      previous->next = NULL;
    }

    if (last != NULL) {
      last->next = NULL;
      last->queue = NULL;
      dbg(DBG_USR2,"FiberM: Removing fiber %d from queue 0x%lx\n", 
	  last->fiber_num, queue);
    } else {
      dbg(DBG_USR2,"FiberM: Queue 0x%lx is empty - no remove\n", 
	  queue);
    }
    return last;
  }


  /**
   * Return the current fiber, or NULL if no fiber is currently running.
   */
  command fiber_t* Fiber.curfiber() {
    return cur_fiber;
  }

  /**
   * Return the given fiber, or NULL if no fiber has this ID.
   */
  command fiber_t* Fiber.getfiber(int id) {
    fiber_t *f;
    if (id < 0 || id >= MAX_FIBERS) return NULL;
    f = &fibers[id];
    if (((fiber_internal_t *)f->internal)->running) return f;
    else return NULL;
  }

  /**
   * Start a new fiber with the given initialization function and argument.
   */
  command result_t Fiber.start(void *(*start)(void *arg), void *arg) {
    fiber_t *new_fiber;
    char *sp;

    if (num_fibers >= MAX_FIBERS) {
      dbg(DBG_USR2,"FiberM: Can't create new fiber\n");
      return FAIL;
    }
    dbg(DBG_USR2,"FiberM: starting fiber %d\n", num_fibers);
    new_fiber = &fibers[num_fibers];
    new_fiber->fiber_num = num_fibers;
    new_fiber->next = NULL;
    ((fiber_internal_t *)new_fiber->internal)->startfn = start;
    ((fiber_internal_t *)new_fiber->internal)->startfnarg = arg;
    num_fibers++;
    sp = (char *)((((fiber_internal_t *)new_fiber->internal)->stack)+(MAX_STACK_SIZE-4));
    if ((unsigned)sp & 0x3f) sp = sp - ((unsigned)sp & 0x3f);
    dbg(DBG_USR2,"FiberM: sp 0x%lx\n", sp);

    // Initialize by stashing context here
    if (setjmp(((fiber_internal_t *)new_fiber->internal)->jmpbuf)) {
      // Returning from longjmp for first schedule
      dbg(DBG_USR2,"FiberM: Fiber.start: setjmp returned, cur_fiber %d\n",
	  cur_fiber->fiber_num);
      ((fiber_internal_t *)cur_fiber->internal)->running = TRUE;
      ((fiber_internal_t *)cur_fiber->internal)->startfn(((fiber_internal_t *)cur_fiber->internal)->startfnarg);
      dbg(DBG_USR2,"FiberM: Fiber.start: done with fiber start, cur_fiber %d\n", cur_fiber->fiber_num);
      ((fiber_internal_t *)cur_fiber->internal)->running = FALSE;
      schedule();
      return SUCCESS;
    }

    // Need macros to do this in a platform-independent way
#ifdef PLATFORM_PC
    // Linux x86
    ((fiber_internal_t *)new_fiber->internal)->jmpbuf->__jmpbuf[4] = (int)sp;
#endif
#ifdef PLATFORM_MICA
    // AVR
    *(unsigned int *)(((char *)((fiber_internal_t *)new_fiber->internal)->jmpbuf)+18) = sp;
#endif

    // Add to tail of run queue
    queue_add(&run_queue, new_fiber);

    if (cur_fiber == NULL) {
      dbg(DBG_USR2,"FiberM: Scheduling new fiber\n");
      post schedule_task();
    } else {
      dbg(DBG_USR2,"FiberM: Yielding to new fiber\n");
      call Fiber.yield();
      dbg(DBG_USR2,"FiberM: Fiber %d done yielding in start\n", cur_fiber->fiber_num);
    }
    return SUCCESS;
  }

  /**
   * Yield the current fiber.
   */
  command void Fiber.yield() {
    if (cur_fiber != NULL) {
      dbg(DBG_USR2,"FiberM: Yield called, cur_fiber %d\n", cur_fiber->fiber_num);
      // Add myself to tail of run queue 
      queue_add(&run_queue, cur_fiber);

      if (!setjmp(((fiber_internal_t *)cur_fiber->internal)->jmpbuf)) {
	// Go away and let someone else run
	suspend();
      } else {
	// Resuming after yield
	dbg(DBG_USR2,"FiberM: Fiber.yield: setjmp returned, cur_fiber %d\n", cur_fiber->fiber_num);
      }
    } else {
      dbg(DBG_USR2,"FiberM: Yield called, no cur_fiber\n");
      //schedule();
    }
  }

  /**
   * Cause the current fiber to wait on the given queue and suspend
   * its operation.
   */
  command void Fiber.sleep(fiber_t **queue) {
    dbg(DBG_USR2,"FiberM: Fiber %d sleeping\n", cur_fiber->fiber_num);
    queue_add(queue, cur_fiber);
    if (!setjmp(((fiber_internal_t *)cur_fiber->internal)->jmpbuf)) {
      // Let someone else run
      suspend();
    } else {
      // Resuming after sleep
      dbg(DBG_USR2,"FiberM: Fiber.sleep: fiber %d done sleeping\n", cur_fiber->fiber_num);
    }
  }

  /** 
   * Move a fiber from the head of the given queue to the run queue
   * and post the schedule task.
   */
  command fiber_t* Fiber.wakeup(fiber_t **queue) {
    fiber_t *next_f = queue_remove(queue);
    if (next_f != NULL) {
      dbg(DBG_USR2,"FiberM: Waking up fiber %d\n", next_f->fiber_num);
      queue_add(&run_queue, next_f);
      post schedule_task();
    }
    return next_f;
  }

  /** 
   * Move the given fiber from the given queue to the run queue and
   * post the schedule task.
   */
  command void Fiber.wakeup_one(fiber_t **queue, fiber_t *fiber) {
    bool found = FALSE;
    fiber_t *f = *queue;
    fiber_t *prev_f = NULL;

    dbg(DBG_USR2,"FiberM: wakeup_one for fiber %d\n", fiber->fiber_num);

    while (f != NULL) {
      if (f == fiber) {
	found = TRUE;
	if (prev_f != NULL) prev_f->next = f->next;
	else *queue = f->next;
	f->queue = NULL;
	f->next = NULL;
	break;
      }
      prev_f = f;
      f = f->next;
    }
    if (!found) return;
    queue_add(&run_queue, fiber);
    post schedule_task();
  }

}

