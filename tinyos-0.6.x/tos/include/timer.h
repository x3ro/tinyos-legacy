/* timer.h
 * includes all timer-related definitions
*/

#ifndef _TIMER_H_
#define _TIMER_H_

typedef struct _Timer {
  uint8_t heap_pos;
  uint8_t flags;    /* | | | | | |free|del */
  uint32_t abstime;
  uint32_t periodic_offset;
  void (*f) ();
}Timer;

/* Accessor functions for the software timers */
/* Always call for initialization */
static inline void initTimer(Timer *t) {t->flags = 0x02;}
/* Set a timer to be aperiodic */
static inline void setAperiodic(Timer *t) {t->periodic_offset = 0;}
/* Set periodic timer with periodicity "period" */
static inline void setPeriodic(Timer *t, uint32_t period) {t->periodic_offset = period;}
/* is the timer still in the heap or free */
static inline uint8_t isFree(Timer *t) {return (((t->flags & 0x02)>>1)&0x01);}
static inline void setDbg(Timer *t,uint8_t dbg) {t->flags &= 0x0f;t->flags |= ((dbg<<4)&0xf0);}
static inline uint8_t getDbg(Timer *t) {return ((t->flags & 0xf0)>>4);}

/* only used by TIMER_HEAP. DO NOT CALL THE functions ELSEWHERE !!! */
static inline uint8_t isPeriodic(Timer *t) {return (t->periodic_offset > 0);}
static inline uint8_t getDeleteFlag(Timer *t) {return (t->flags & 0x01);}
static inline void setDeleteFlag(Timer *t) {t->flags |= 0x01;}
static inline void resetDeleteFlag(Timer *t) {t->flags &= 0xfe;}
static inline uint8_t getHeapPos(Timer *t) {return(t->heap_pos);}
static inline void setHeapPos(Timer *t,uint8_t pos) {t->heap_pos = pos;}
static inline void setFree(Timer *t) {t->flags |= 0x02;}
static inline void setUsed(Timer *t) {t->flags &= 0xfd;}

/* These values need to be multiplied by 8 if CLC is used as a prescaler
 * which is what is happening when TIMER_HEAP needs to work with the
 * new stack
*/

/*
#define timer1ps 500000
#define timer2ps 250000
#define timer4ps 125000
#define timer8ps  62500
#define timer16ps 31250
*/


#define timer1ps 4000000
#define timer2ps 2000000
#define timer4ps 1000000
#define timer8ps  500000
#define timer16ps 250000     

// definitions for the 16-bit timer
#define itc16_tick_disable 16383,0
#define itc16_tick20000ps 25,1
#define itc16_tick15625ps 32,1
#define itc16_tick10000ps 50,1
#define itc16_tick1000ps 500,1
#define itc16_tick100ps 5000,1
#define itc16_tick10ps 12500,4
#define itc16_tick4096ps 122,1
#define itc16_tick2048ps 244,1
#define itc16_tick1024ps 488,1
#define itc16_tick512ps 977,1
#define itc16_tick256ps 1953,1
#define itc16_tick128ps 3096,1
#define itc16_tick64ps 7813,1
#define itc16_tick32ps 15625,1
#define itc16_tick16ps 15625,2
#define itc16_tick8ps 15625,4
#define itc16_tick4ps 15625,8
#define itc16_tick2ps 15625,16
#define itc16_tick1ps 15625,32


// definitions for the 8-bit external timer
#define etc8_tick1000ps 33,1
#define etc8_tick100ps 41,2
#define etc8_tick10ps 102,3
#define etc8_tick4096ps 1,2
#define etc8_tick2048ps 2,2
#define etc8_tick1024ps 1,3
#define etc8_tick512ps 2,3
#define etc8_tick256ps 4,3
#define etc8_tick128ps 8,3
#define etc8_tick64ps 16,3
#define etc8_tick32ps 32,3
#define etc8_tick16ps 64,3
#define etc8_tick8ps 128,3
#define etc8_tick4ps 128,4
#define etc8_tick2ps 128,5
#define etc8_tick1ps 128,6     

#endif
