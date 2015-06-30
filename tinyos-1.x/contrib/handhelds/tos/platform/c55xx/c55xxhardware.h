// $Id: c55xxhardware.h,v 1.1 2005/07/29 18:29:28 adchristian Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
// @author Joe Polastre <polastre@cs.berkeley.edu>
// @author Cory Sharp <cssharp@eecs.berkeley.edu>
// @author Jamey Hicks <jamey.hicks@hp.com>

#ifndef _H_c55xxhardware_h
#define _H_c55xxhardware_h

#include <hwportdefs.h>

// #include <io.h>
// #include <signal.h>
// #include "msp430regtypes.h"


// CPU memory-mapped register access will cause nesc to issue race condition
// warnings.  Race conditions are a significant conern when accessing CPU
// memory-mapped registers, because they can change even while interrupts
// are disabled.  This means that the standard nesc tools for resolving race
// conditions, atomic statements that disable interrupt handling, do not
// resolve CPU register race conditions.  So, CPU registers access must be
// treated seriously and carefully.

// The macro C55xxREG_NORACE allows individual modules to internally
// redeclare CPU registers as norace, eliminating nesc's race condition
// warnings for their access.  This macro should only be used after the
// specific CPU register use has been verified safe and correct.  Example
// use:
//
//    module MyLowLevelModule
//    {
//      // ...
//    }
//    implementation
//    {
//      C55xxREG_NORACE(TACCTL0);
//      // ...
//    }

#undef norace

#define C55xxREG_NORACE_EXPAND(type,name,addr) \
/* norace static volatile type name = addr */

#define C55xxREG_NORACE3(type,name,addr) \
C55xxREG_NORACE_EXPAND(type,name,addr)

// C55xxREG_NORACE and C55xxREG_NORACE2 presume naming conventions among
// type, name, and addr, which are defined in the local header
// msp430regtypes.h and mspgcc's header io.h and its children.

#define C55xxREG_NORACE2(rename,name) \
C55xxREG_NORACE3(TYPE_##name,rename,name##_)

#define C55xxREG_NORACE(name) \
C55xxREG_NORACE3(TYPE_##name,name,name##_)


// redefine ugly defines from msp-gcc
#ifndef DONT_REDEFINE_SR_FLAGS
#undef C
#undef Z
#undef N
#undef V
#undef GIE
#undef CPUOFF
#undef OSCOFF
#undef SCG0
#undef SCG1
#undef LPM0_bits
#undef LPM1_bits
#undef LPM2_bits
#undef LPM3_bits
#undef LPM4_bits
#define SR_C       0x0001
#define SR_Z       0x0002
#define SR_N       0x0004
#define SR_V       0x0100
#define SR_GIE     0x0008
#define SR_CPUOFF  0x0010
#define SR_OSCOFF  0x0020
#define SR_SCG0    0x0040
#define SR_SCG1    0x0080
#define LPM0_bits           SR_CPUOFF
#define LPM1_bits           SR_SCG0+SR_CPUOFF
#define LPM2_bits           SR_SCG1+SR_CPUOFF
#define LPM3_bits           SR_SCG1+SR_SCG0+SR_CPUOFF
#define LPM4_bits           SR_SCG1+SR_SCG0+SR_OSCOFF+SR_CPUOFF
#endif//DONT_REDEFINE_SR_FLAGS

#ifdef interrupt
#undef interrupt
#endif

#ifdef wakeup
#undef wakeup
#endif

#ifdef signal
#undef signal
#endif

// The signal attribute has opposite meaning in msp430-gcc than in avr-gcc
#define TOSH_SIGNAL(signame) \
void sig_##signame() __attribute__((interrupt (signame), wakeup, spontaneous, C))

// TOSH_INTERRUPT allows nested interrupts
#define TOSH_INTERRUPT(signame) \
void isr_##signame() __attribute__((interrupt (signame), signal, wakeup, spontaneous, C))

inline void TOSH_wait(void)
{
}

#define TOSH_CYCLE_TIME_NS 250

inline void TOSH_wait_250ns(void)
{
  // 4 MHz clock == 1 cycle per 250 ns

}

inline void TOSH_uwait(uint16_t u) 
{ 
} 

#if 0
void __nesc_disable_interrupt()
{
//  DISABLE_INTERRUPTS
}

void __nesc_enable_interrupt()
{
//  ENABLE_INTERRUPTS
}
#endif

bool are_interrupts_enabled()
{
  return _IER1;
}

typedef unsigned long __nesc_atomic_t;

__nesc_atomic_t __nesc_atomic_start(void)
{
  __nesc_atomic_t result = are_interrupts_enabled();
  _IER1 = 0;
  return result;
}

void __nesc_atomic_end( __nesc_atomic_t reenable_interrupts )
{
  _IER1 = reenable_interrupts;
}

//Variable to keep track if Low Power Modes shoud not be used
bool LPMode_disabled = FALSE;

void LPMode_enable()
{
  LPMode_disabled = FALSE;
}

void LPMode_disable()
{
  LPMode_disabled = TRUE;
}

extern volatile unsigned int global_clock;
extern long clock_time;
extern int clock_event;
extern void clock_update(void) __attribute__((C));
extern void c55xx_timer_clock_callback();

extern long timerm_clock_time;
extern int timerm_clock_event;
extern void timerm_clock_callback();

inline void TOSH_sleep()
{
  // The LPM we can go down to depends on the clocks used. We never go
  // below LPM3, so ACLK is always enabled, also TimerB clock source
  // is assumed to be ACLK.
  // We check C55xx's TimerA, USART0/1, ADC12 peripheral modules if they
  // use MCLK or SMCLK and switch to the lowest LPM that keeps 
  // the required clock(s) running. 
  
  extern uint8_t TOSH_sched_full;
  extern volatile uint8_t TOSH_sched_free;
  __nesc_atomic_t fInterruptFlags;
  uint16_t LPMode_bits = 0;
  
  fInterruptFlags = __nesc_atomic_start(); 
  clock_update();
    __nesc_atomic_end(fInterruptFlags);
  if (clock_time <= 0 && clock_event) {
       clock_event = 0;
       c55xx_timer_clock_callback();
  }
  if (timerm_clock_time <= 0 && timerm_clock_event) {
       timerm_clock_event = 0;
       timerm_clock_callback();
  }

  fInterruptFlags = __nesc_atomic_start(); 
  if ((LPMode_disabled) || (TOSH_sched_full != TOSH_sched_free)) {
    __nesc_atomic_end(fInterruptFlags);
    return;
  } else {
  }
  
}

#define SET_FLAG(port, flag) ((port) |= (flag))
#define CLR_FLAG(port, flag) ((port) &= ~(flag))
#define READ_FLAG(port, flag) ((port) & (flag))

// TOSH_ASSIGN_PIN creates functions that are effectively marked as
// "norace".  This means race conditions that result from their use will not
// be detectde by nesc.

#define TOSH_ASSIGN_PIN_HEX(name, port, hex) \
__inline__ void TOSH_SET_##name##_PIN() { _GPIO_IODATA |= (hex); } \
__inline__ void TOSH_CLR_##name##_PIN() { _GPIO_IODATA &= ~(hex); } \
__inline__ void TOSH_TOGGLE_##name##_PIN() { _GPIO_IODATA ^= (hex); } \
__inline__ uint8_t TOSH_READ_##name##_PIN() { return (_GPIO_IODATA & (hex)); } \
__inline__ void TOSH_MAKE_##name##_OUTPUT() { _GPIO_IODIR |= (hex); } \
__inline__ void TOSH_MAKE_##name##_INPUT() { _GPIO_IODIR &= ~(hex); } \
__inline__ void TOSH_SEL_##name##_MODFUNC() { } \
__inline__ void TOSH_SEL_##name##_IOFUNC() { }

#define TOSH_ASSIGN_PIN(name, port, bit) \
TOSH_ASSIGN_PIN_HEX(name,port,(1<<(bit)))

#define TOSH_ASSIGN_INTERRUPT(name, bit) \
TOSH_ASSIGN_INTERRUPT_HEX(name,(1ul<<(bit)))

#define TOSH_ASSIGN_INTERRUPT_HEX(name, hex) \
__inline__ uint8_t TOSH_READ_##name##_PIN() { return (_IFR1 & (hex)); } \
__inline__ void TOSH_ENABLE_##name##_INTERRUPT() { _IER1 |= (hex); } \
__inline__ void TOSH_DISABLE_##name##_INTERRUPT() { _IER1 &= ~(hex); } \
__inline__ void TOSH_CLEAR_##name##_INTERRUPT() { _IFR1 |= (hex); }


void bzero(void *s, size_t n);
enum GF_Mode {GF_OR,GF_AND,GF_COPY,GF_XOR};

#endif//_H_c55xxhardware_h

