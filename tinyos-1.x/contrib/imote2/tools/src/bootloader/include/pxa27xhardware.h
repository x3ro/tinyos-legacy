// $Id: pxa27xhardware.h,v 1.1 2006/10/10 22:33:24 lnachman Exp $

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
 * 
 */
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


/*
 *
 * Authors:   Philip Buonadonna
 *
 * Edits:	Josh Herbach
 * Revised: 09/02/2005
 */

#ifndef PXA27X_HARDWARE_H
#define PXA27X_HARDWARE_H


#include <arm_defs.h>
#include <pxa27x_registers.h>
#include <types.h>

#define TOSH_ASSIGN_PIN(name, port, regbit) \
static inline void TOSH_SET_##name##_PIN() {_GPSR(regbit) |= _GPIO_bit(regbit);} \
static inline void TOSH_CLR_##name##_PIN() {_GPCR(regbit) |= _GPIO_bit(regbit);} \
static inline char TOSH_READ_##name##_PIN() {return ((_GPLR(regbit) & _GPIO_bit(regbit)) != 0);} \
static inline void TOSH_MAKE_##name##_OUTPUT() {_GPIO_setaltfn(regbit,0);_GPDR(regbit) |= _GPIO_bit(regbit);} \
static inline void TOSH_MAKE_##name##_INPUT() {_GPIO_setaltfn(regbit,0);_GPDR(regbit) &= ~(_GPIO_bit(regbit));}

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, regbit) \
static inline void TOSH_SET_##name##_PIN() {_GPSR(regbit) |= _GPIO_bit(regbit);} \
static inline void TOSH_CLR_##name##_PIN() {_GPCR(regbit) |= _GPIO_bit(regbit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() {_GPDR(regbit) |= _GPIO_bit(regbit);} 

// We need slightly different defs than SIGNAL, INTERRUPT
#define TOSH_SIGNAL(signame)					\
void signame() __attribute__ ((signal, spontaneous, C))

#define TOSH_INTERRUPT(signame)				\
void signame() __attribute__ ((interrupt, spontaneous, C))

// GPIO Interrupt Defines
#define TOSH_RISING_EDGE (1)
#define TOSH_FALLING_EDGE (2)
#define TOSH_BOTH_EDGE (3)

typedef uint32_t __nesc_atomic_t;

void TOSH_wait();

/**
 * (Busy) wait <code>usec</code> microseconds
 */
inline void TOSH_uwait(uint16_t usec);

inline uint32_t _pxa27x_clzui(uint32_t i);

//NOTE...at the moment, these functions will ONLY disable the IRQ...FIQ is left alone
inline __nesc_atomic_t __nesc_atomic_start(void);

inline void __nesc_atomic_end(__nesc_atomic_t oldState);

inline void __nesc_enable_interrupt();

inline void __nesc_atomic_sleep();

#endif //PXA27X_HARDWARE_H
