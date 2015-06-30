/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */
/*
 *
 * Authors:             Jason Hill, Philip Levis, Nelson Lee
 *
 * Ported to 8051 by Martin Leopold, Sidsel Jensen & Anders Egeskov Petersen, 
 *                   Dept of Computer Science, University of Copenhagen
 * Date last modified: Nov 2005
 *
 */

#ifndef TOSH_AVRHARDWARE_H
#define TOSH_AVRHARDWARE_H

#include <8051.h>

#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() { port |= 1<<bit;} \
static inline void TOSH_CLR_##name##_PIN() { port &= ~(1<<bit);} \
static inline char TOSH_READ_##name##_PIN() { return 0x01 & ( port >>bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() { port##_DIR &= ~(1<<bit);} \
static inline void TOSH_MAKE_##name##_INPUT() { port##_DIR |= (1<<bit);} 

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {port |= 1<<bit;} \
static inline void TOSH_CLR_##name##_PIN() {port &= ~(1<<bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() {##port##_DIR 1<<bit;}

#define TOSH_ALIAS_OUTPUT_ONLY_PIN(alias, connector)\
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {} \

#define TOSH_ALIAS_PIN(alias, connector) \
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline char TOSH_READ_##alias##_PIN() {return TOSH_READ_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {TOSH_MAKE_##connector##_OUTPUT();} \
static inline void TOSH_MAKE_##alias##_INPUT()  {TOSH_MAKE_##connector##_INPUT();} 

// We need slightly different defs than SIGNAL, INTERRUPT
// See gcc manual for explenation of gcc-attributes
// See nesC Language Reference Manual for nesc attributes
//
// signal: Interrupts will be disabled inside function.
// interrupt: Sets up interrupt vector, but doesn't disable interrupts
// spontaneous: nesc attribute to indicate that there are "inisible" calls to this
//              function i.e. interrupts


#include <avr/signal.h>

#define TOSH_SIGNAL(signame)					\
void signame() __attribute__ ((signal, spontaneous, C))

#define TOSH_INTERRUPT(signame)				\
void signame() __attribute__ ((interrupt, spontaneous, C))

//#define TOSH_INTERRUPT(signame)				\
//void SIG_signame() interrupt signame

// atomic statement runtime support
typedef uint8_t __nesc_atomic_t;

inline void __nesc_disable_interrupt() {
  EA=0;
}

inline void __nesc_enable_interrupt() {
  EA=1;
}
    

inline __nesc_atomic_t __nesc_atomic_start(void) __attribute__((spontaneous)) {
  __nesc_atomic_t tmp = EA;
  EA = 0; 
  return tmp;
}

inline void __nesc_atomic_end(__nesc_atomic_t oldSreg) __attribute__((spontaneous)) {
  EA = oldSreg;
}

/* Assign LEDS to PINS */
TOSH_ASSIGN_PIN(RED_LED, P1, 0);
TOSH_ASSIGN_PIN(GREEN_LED, P1, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, P0, 7);


extern uint8_t idlemode;
extern uint8_t adcmode;

//
// See comment in RealMain.nc for a description of how these functions
// interact with the TOSH_sleep function.
//
// These are declared as macros, as the atomic-keyword isn't working
// when this file is processed :-(. A nicer solution would be to have
// these as inline functions, and the idlemode/adcmode variables
// declared extern in this file also.
//
#define TOSH_ENTER_IDLE_MODE() do { atomic { idlemode++; MCUCR &= ~BV(SE); } } while(0);
#define TOSH_LEAVE_IDLE_MODE() do { atomic { idlemode--; MCUCR &= ~BV(SE); } } while(0);
#define TOSH_ENTER_ADC_MODE()  do { atomic { adcmode++;  MCUCR &= ~BV(SE); } } while(0);
#define TOSH_LEAVE_ADC_MODE()  do { atomic { adcmode--;  MCUCR &= ~BV(SE); } } while(0);

#endif //TOSH_AVRHARDWARE_H
