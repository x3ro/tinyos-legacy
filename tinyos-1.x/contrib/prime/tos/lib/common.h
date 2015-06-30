#ifndef COMMON_H
#define COMMON_H

// #include "Debuging.h"

#ifdef DEBUG_1
#endif

#include "stdlib.h"

//	Macros
#define min(x, y) ((x)>(y) ? (y) : (x))
#define max(x, y) ((x)>(y) ? (x) : (y))

#define inorder(x, y, z) ((unsigned long)((z)-(x)) > (unsigned long)((z)-(y)))
#define behind(x, y, lookahead) (inorder(x, y, y+lookahead))

#define GetMask(num_of_bits) ((1 << num_of_bits) - 1)
#define GetOffset(v, num_of_bits) (v & (GetMask(num_of_bits)))
#define NoToGroup(no, group_size) (no / group_size)
#define NoToGroupB(no, num_group_bits) (no >> num_group_bits)
#define DBG_HALT(x) {cli(); for(;;){if (x) {TOSH_CLR_YELLOW_LED_PIN(); TOSH_CLR_RED_LED_PIN(); TOSH_CLR_GREEN_LED_PIN();}}}

#define GENERAL_MUTEX 0x1

#define NEWLOCK
#define LOCK_USE_LEDno

#ifdef NEWLOCK

#ifdef LOCK_USE_LED

#define SHOWLED(me) showLeds(me)

#else

#define SHOWLED(me)

#endif

  // new lock behavior

#define MUTEX_LOCKED gcGeneralState & GENERAL_MUTEX
#define MUTEX_LOCK gcGeneralState |= GENERAL_MUTEX
#define MUTEX_UNLOCK  gcGeneralState &= (~GENERAL_MUTEX)


#define MUTEX_ENTER(r) \
  atomic \
    { \
      r = MUTEX_LOCKED; \
      MUTEX_LOCK; \
    }

#define MUTEX_EXIT MUTEX_UNLOCK

#define KNOCK(r, me) \
  { \
    char cKnockOk; \
    MUTEX_ENTER(cKnockOk); \
      /* if (checkAQ() == FAIL) {uprint4(ticPrime, dGoodMe, dFuncID, 0xccee0000); gcNoPrint = 1;} */ \
    if (cKnockOk) \
      { \
        SHOWLED(dGoodMe); \
        return r; \
      } \
    gnGeneralLevel++; \
    dGoodMe = me; \
    SHOWLED(dGoodMe); \
  }

#define VOID_KNOCK(me) \
  { \
    char cKnockOk; \
    MUTEX_ENTER(cKnockOk); \
      /* if (checkAQ() == FAIL) {uprint4(ticPrime, dGoodMe, dFuncID, 0xcc110000); gcNoPrint = 1;} */ \
    if (cKnockOk) \
      { \
        SHOWLED(dGoodMe); \
        return; \
      } \
    gnGeneralLevel++; \
    dGoodMe = me; \
    SHOWLED(dGoodMe); \
  }

#define LEAVE {  SHOWLED(0); gnGeneralLevel--; /* dGoodMe = 0;*/ if (checkAQ() == FAIL) {uprint4(ticPrime, dGoodMe, dFuncID, 0xccdd0000); gcNoPrint = 1;} MUTEX_EXIT; }

  // must remove UART info for release version
#define KNOCK0
#define KNOCKREC0(x) 
#define KNOCKREC(x)
#define KNOCK0FREE 

#endif // NEWLOCK

#endif

