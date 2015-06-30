/*                                                                      tab:4
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
 * Authors:             Deepak Ganesan
 * Comments: TIMER_HEAP provides fine-grained timer support for applications.
 * Change the maximum number of tasks in sched.c to a larger number, such as 20
 * Further documentation about working is provided in: /nest/doc/timer_heap.ps
 *
 */

#include "tos.h"
#include "TIMER_HEAP.h"
#include "dbg.h"

#define HEAP_SIZE 15
#define PARENT(i) (((i) - 1) / 2)
#define CHILD1(i) ((i) * 2 + 1)
#define CHILD2(i) ((i) * 2 + 2)
#define TIME(i) (VAR(heap)[i]->abstime)

#define CLOCK_INTERVAL 15625*4

#define TOS_FRAME_TYPE TIMER_HEAP_frame
TOS_FRAME_BEGIN(TIMER_HEAP_frame)
{
  Timer *heap[HEAP_SIZE];
  Timer *st; /* saved timer */
  uint8_t num_timers;
  uint8_t heap_size;
  uint32_t clock,counter;
  uint8_t heap_p,check_p,fire_p, check_m;
  int test,test1;
  uint8_t mutex;
}
TOS_FRAME_END(TIMER_HEAP_frame);

/* Clear mutex */
static inline void v() {VAR(mutex)=0;}
/* Test and set mutex (need to rewrite in assembly)*/
static inline uint8_t p() {
  cli();
  if (VAR(mutex)) {sei();return 0;} 
  else {VAR(mutex)=1;sei();return 1;}
}


TOS_TASK(CHECK_TIMER_TASK) {
  check_timer();
  VAR(check_p)=0;
}

TOS_TASK(TIMER_FIRE_TASK) {
  timer_fire();
  VAR(fire_p)=0;
}


TOS_TASK(ADD_TIMER_ABSOLUTE_TASK) {
  int pos;

  pos = VAR(num_timers);
  while (pos > 0 && VAR(st)->abstime < TIME(PARENT(pos))) {
    VAR(heap)[pos] = VAR(heap)[PARENT(pos)];
    setHeapPos(VAR(heap)[pos],pos);
    pos = PARENT(pos);
  }
  VAR(heap)[pos] = VAR(st);
  setHeapPos(VAR(heap)[pos],pos);
  VAR(num_timers)++;
  VAR(st)=NULL;

  if (!VAR(check_p)) {
    TOS_POST_TASK(CHECK_TIMER_TASK);
    VAR(check_p)=1;
  }
  VAR(heap_p)=0;
}

/* check_timer() is called after all operations on heap have completed
   in each task. This is so that interrupts dont fire while heap re-organization
   is in progress
*/

TOS_TASK(RESET_HEAP_TASK) {

  /* Consistency Check: Check if timer exists in heap. Is this check necc?? */
  if (VAR(st) != VAR(heap)[getHeapPos(VAR(st))]) return;

  reset_heap(VAR(st));

  if (isPeriodic(VAR(st)) && !getDeleteFlag(VAR(st))) {
    VAR(st)->abstime += VAR(st)->periodic_offset;
    TOS_POST_TASK(ADD_TIMER_ABSOLUTE_TASK);
  } else {
    setFree(VAR(st)); /* Free the timer to be reused by app */
    resetDeleteFlag(VAR(st));
    VAR(heap_p)=0;
    VAR(st)=NULL;

    /* check heap */
    if (!VAR(check_p)) {
      TOS_POST_TASK(CHECK_TIMER_TASK);
      VAR(check_p)=1;
    }
  }
}


char TOS_COMMAND(TIMER_INIT)(void) {
  dbg(DBG_PROG, ("Timer Initialized\n"));
  VAR(num_timers) = 0;
  VAR(heap_size) = 0;

  v();

  clock_init();
  //  CLR_GREEN_LED_PIN();

  //  TOS_CALL_COMMAND(TIMER_SUB_CLOCK_INIT)(tick8ps);
  return 1;
}

char TOS_COMMAND(ADD_TIMER_RELATIVE)(Timer *t, uint32_t trel) {
  if (VAR(heap_p) || !isFree(t)) return 0;
  //  TOS_CALL_COMMAND(GET_TIME)(&VAR(clock));
  clock_get_time();
  t->abstime = VAR(clock) + trel;

  return (TOS_COMMAND(ADD_TIMER_ABSOLUTE)(t));
}

char TOS_COMMAND(ADD_TIMER_ABSOLUTE)(Timer *t) {
  uint8_t ret=0;
  
  /* Insert the Timer *into the heap. */
  dbg(DBG_PROG, ("ADD_TIMER %l\n", t->abstime));

  /* CRITICAL SECTION: Lock while operation on state variables */
  if (!p()) return 0;
   if (VAR(heap_p) || !isFree(t)) {
    ret=0;
    if (!VAR(check_p)) {
      TOS_POST_TASK(CHECK_TIMER_TASK);
      VAR(check_p)=1;
    }
  } else {
    ret=1;
    VAR(heap_p) = 1;
    setUsed(t);
    VAR(st) = t;
    TOS_POST_TASK(ADD_TIMER_ABSOLUTE_TASK);
  }
  v();
  /* END CRITICAL SECTION */

  dbg(DBG_PROG, ("ADD_TIMER %l at position:%d\n", t->abstime,pos));
  return ret;
}

void timer_fire() {
  Timer *t;
  void (*f) ();

  /* Remove the first timer from the heap, remembering its
   * function and argument. */
  t = VAR(heap)[0];

  f = t->f;

  VAR(st) = t;

  TOS_POST_TASK(RESET_HEAP_TASK);

  /* Run the function. */
  f();
}


char TOS_COMMAND(DELETE_TIMER)(Timer *t) {
  uint8_t ret=0;

  /* CRITICAL SECTION: Lock while operation on state variables */
  if (!p()) return 0;
  /* reject request if either
        reset pending
	the passed timer does not exist on the heap
	the passed timer has been fucked with by the app
  */
  if (VAR(heap_p) || isFree(t) || (t!= VAR(heap)[getHeapPos(t)])) {
    ret=0;
    if (!VAR(check_p)) {
      TOS_POST_TASK(CHECK_TIMER_TASK);
      VAR(check_p)=1;
    }
  } else {
    ret=1;
    VAR(heap_p) = 1;
    VAR(st) = t;
    setDeleteFlag(t);
    TOS_POST_TASK(RESET_HEAP_TASK);
  }
  v();
  /* END CRITICAL SECTION */

  return ret;
}

/*  void heap_dump() { */
/*    int i; */
/*    udb_byte(0xff); */
/*    for (i=0; i<VAR(num_timers); i++) { */
/*      udb_byte(getDbg(VAR(heap)[i])); */
/*      udb_byte(getHeapPos(VAR(heap)[i])); */
/*    } */
/*  } */

void reset_heap(Timer *t) {
    int pos, min;

    /* Free the timer, saving its heap position. */
    pos = getHeapPos(t);
    
    if (pos != VAR(num_timers) - 1) {
        /* Replace the timer with the last timer in the heap and
         * restore the heap, propagating the timer either up or
         * down, depending on which way it violates the heap
         * property to insert the last timer in place of the
         * deleted timer. */
        if (pos > 0 && TIME(VAR(num_timers) - 1) < TIME(PARENT(pos))) {
            do {
                VAR(heap)[pos] = VAR(heap)[PARENT(pos)];
                setHeapPos(VAR(heap)[pos],pos);
                pos = PARENT(pos);
            } while (pos > 0 && TIME(VAR(num_timers) - 1) < TIME(PARENT(pos)));
            VAR(heap)[pos] = VAR(heap)[VAR(num_timers) - 1];
            setHeapPos(VAR(heap)[pos],pos);
        } else {
            while (CHILD2(pos) < VAR(num_timers)) {
                min = VAR(num_timers) - 1;
                if (TIME(CHILD1(pos)) < TIME(min))
                    min = CHILD1(pos);
                if (TIME(CHILD2(pos)) < TIME(min))
                    min = CHILD2(pos);
                VAR(heap)[pos] = VAR(heap)[min];
                setHeapPos(VAR(heap)[pos],pos);
                pos = min;
            }
            if (pos != VAR(num_timers) - 1) {
                VAR(heap)[pos] = VAR(heap)[VAR(num_timers) - 1];
                setHeapPos(VAR(heap)[pos],pos);
            }
        }
    }
    VAR(num_timers)--;
}

/********************
If interrupt is during protected op, 
   exit (assume that fn that initiated the protected op, 
         will post the check task)
else,
   if a check task is not pending, 
      add check task 
      set check pending flag
      exit
   endif
endif
********************/
/*
void TOS_EVENT(TIMER_SUB_CLOCK_FIRE_EVENT)() {
  if (!VAR(check_p)) {
    TOS_POST_TASK(CHECK_TIMER_TASK);
    VAR(check_p)=1;
  }
}
*/
/******************
Compare Current value of Clock with Timeout of top of heap.
If less than CLOCK granularity, set timeout for delta on 
timer compareb (OCIE1B)
******************/
void check_timer() {
  int32_t temp;

  if (VAR(num_timers)==0) return;

  //  TOS_CALL_COMMAND(GET_TIME)(&VAR(clock));
  clock_get_time();
  temp = (int32_t)(VAR(heap)[0]->abstime - VAR(clock));
  if (temp > (int32_t)CLOCK_INTERVAL) return;
  else {
    if (temp < 0) {
      /* CRITICAL SECTION: Lock while operation on state variables */
      if (!p()) return;
      if (!VAR(heap_p) && !VAR(fire_p)) {
	TOS_POST_TASK(TIMER_FIRE_TASK);
	VAR(fire_p)=1;
	VAR(heap_p)=1;
      }
      v();
      /* END CRITICAL SECTION */
    } else {
      outp((temp >> 8)&0xFF, OCR_ITC_16BH);
      outp(temp & 0xFF, OCR_ITC_16BL);    
      sbi(TIMSK, OCIE_ITC_16B);      // enable timer1b interupt for remaining delta
    }
  }
}

TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE1B, (void)) {
  cbi(TIMSK, OCIE1B);      // disable timer1b interupt
  if (p()) {
    if (!VAR(heap_p) && !VAR(fire_p)) {
      TOS_POST_TASK(TIMER_FIRE_TASK);
      VAR(fire_p)=1;
      VAR(heap_p)=1;
    }
    v();
  }
}


void clock_init()
{
    cbi(TIMSK, OCIE_ITC_16A);    // Disable CNT1 output compare interrupt
    cbi(TIMSK, OCIE_ITC_16B);    // Disable CNT1 output compare interrupt
    cbi(TIMSK, TICIE_ITC_16);    // Disable CNT1 input capture interrupt
    cbi(TIMSK, TOIE_ITC_16);     // Disable CNT1 overflow interrupt

    outp(0x01, TCCR_ITC_16B);    // Prescaling the timer clk
    //    outp(0x0A, TCCR_ITC_16B);    // Prescaling the timer clk/8
    outp(0x00, TCCR_ITC_16A);

    __outw(0, OCR_ITC_16BL);    

    // set comp registers
    outp(((uint16_t)CLOCK_INTERVAL >> 8)&0xFF, OCR_ITC_16AH);
    outp((uint16_t)CLOCK_INTERVAL & 0xFF, OCR_ITC_16AL);

    __outw(0, TCNT_ITC_16L); 
    sbi(TIMSK, OCIE_ITC_16A);      // enable timer1 interupt
    sei();
}

TOS_INTERRUPT_HANDLER(SIG_OUTPUT_COMPARE1A, (void))
{
  // Count the elapsed ticks
  VAR(counter) += __inw_atomic(OCR_ITC_16AL);

  if (!VAR(check_p)) {
    TOS_POST_TASK(CHECK_TIMER_TASK);
    VAR(check_p)=1;
  }
}

void clock_get_time()
{
  VAR(clock) = VAR(counter);
  cli();
  /* get clock value */
  VAR(clock) += __inw(TCNT_ITC_16L);
  /* if the interrupt is pending, adjust clock forward */
  if (inp(TIFR) & OCF_ITC_16A) VAR(clock) += __inw(OCR_ITC_16AL);
  sei();
}
