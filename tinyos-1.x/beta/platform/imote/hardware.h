/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
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

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#define CFG_ZLL
#define OS_BLUEOS
#define REL_LIB_OBJ_ONLY
#define CFG_ULS_SUPPORT

#include "imotelib/motelib.h"

#if 0
typedef uint32_t uint32;
#endif

// These headers are prepended to data packets to be sent over the network.
// Applications need to make sure there is enough space in BRAM before their
// data.

// Sized below are set to uin32 for now to avoid alignment issues
typedef struct tiMoteHeader {
  uint32 source;
  uint32 dest;
  uint32 seq; 
  uint32 channel;  // hack to avoid another mux for now
} tiMoteHeader;

#define INVALID_NODE 0xFFFFF

#define LOWER_LEVEL_HEADER_SIZE (64)
#define IMOTE_HEADER_SIZE (sizeof(tiMoteHeader)) 



#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {TM_SetPio(bit);} \
static inline void TOSH_CLR_##name##_PIN() {TM_ResetPio(bit);} \
static inline char TOSH_READ_##name##_PIN() {return (TM_ReadPio(bit));} \
static inline void TOSH_MAKE_##name##_OUTPUT() {TM_SetPioAsOutput(bit);} \
static inline void TOSH_MAKE_##name##_INPUT() {TM_SetPioAsInput(bit);}

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {TM_SetPio(bit);} \
static inline void TOSH_CLR_##name##_PIN() {TM_ResetPio(bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() {TM_SetPioAsOutput(bit);} 



// We need slightly different defs than SIGNAL, INTERRUPT
#define TOSH_SIGNAL(signame)					\
void signame() __attribute__ ((signal, spontaneous, C))

#define TOSH_INTERRUPT(signame)				\
void signame() __attribute__ ((interrupt, spontaneous, C))

/* Watchdog Prescaler
 */
enum {
  TOSH_period16 = 0x00, // 47ms
  TOSH_period32 = 0x01, // 94ms
  TOSH_period64 = 0x02, // 0.19s
  TOSH_period128 = 0x03, // 0.38s
  TOSH_period256 = 0x04, // 0.75s
  TOSH_period512 = 0x05, // 1.5s
  TOSH_period1024 = 0x06, // 3.0s
  TOSH_period2048 = 0x07 // 6.0s
};

void TOSH_wait()
{
  asm volatile("nop");
  asm volatile("nop");
}

void TOSH_sleep()
{
  // not currently supported
}

/**
 * (Busy) wait <code>usec</code> microseconds
 */
inline void TOSH_uwait(uint16_t usec)
{
  /* In most cases (constant arg), the test is elided at compile-time */
  if (usec)
    /* loop takes 4 cycles, aka 1us */
    asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+r" (usec));
}


// atomic statement runtime support
typedef uint32 __nesc_atomic_t;

inline __nesc_atomic_t __nesc_atomic_start(void) __attribute__((spontaneous))
{
  uint32 result = 0;
  uint32 temp = 0;

  asm volatile (
		"mrs %0,CPSR\n\t"
		"orr %1,%2,%4\n\t"
		"msr CPSR_cf,%3"
		: "=r" (result) , "=r" (temp)
		: "0" (result) , "1" (temp) , "i" (TM_CPU_INT_MASK)
		);

  return result;
}

inline void __nesc_atomic_end(__nesc_atomic_t oldState) __attribute__((spontaneous))
{
  uint32  statusReg = 0;
  asm volatile (
		"mrs %0,CPSR\n\t"
		"bic %0, %1, %2\n\t"
		"orr %0, %1, %3\n\t"
		"msr CPSR_c, %1"
		: "=r" (statusReg)
		: "0" (statusReg),"i" (TM_CPU_INT_MASK), "r" (oldState)
		);

  return;
}

inline void __nesc_enable_interrupt() {

  uint32 statusReg = 0;

  asm volatile (
	       "mrs %0,CPSR\n\t"
	       "bic %0,%1,#0xc0"
	       "msr CPSR_c, %1"
	       : "=r" (statusReg)
	       : "0" (statusReg)
	       );
  return;
}


// I2C uses wired-AND pull down GPIO.
// On TC2000P-4 only GPIO 0-3 are pull down
// These are hard-coded in I2CBusM.nc to get around macro expansion problem
#define I2C_BUS1_SCL_GPIO 0
#define I2C_BUS1_SDA_GPIO 1

TOSH_ASSIGN_PIN(I2C_BUS1_SCL, A, I2C_BUS1_SCL_GPIO);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, A, I2C_BUS1_SDA_GPIO);

TOSH_ASSIGN_OUTPUT_ONLY_PIN(YELLOW_LED, A, 4);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(GREEN_LED, A, 6);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(RED_LED, A, 5);

// Before initial prototype is release, GPIO's are overloaded
// After alpha release, LED functionality will be provided over the I2C bus
// Remove these assignments before release.

TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED0, A, 0);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED1, A, 1);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED2, A, 2);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED3, A, 3);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED4, A, 4);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED5, A, 5);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED6, A, 6);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(LED7, A, 7);

void TOSH_SET_PIN_DIRECTIONS(void)
{

  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();

// Change I/O 0 and 1 to input for I2C testing
  TOSH_MAKE_I2C_BUS1_SCL_INPUT();
  TOSH_MAKE_I2C_BUS1_SDA_INPUT();

  TOSH_MAKE_LED2_OUTPUT();
  TOSH_MAKE_LED3_OUTPUT();
  TOSH_MAKE_LED4_OUTPUT();
  TOSH_MAKE_LED5_OUTPUT();
  TOSH_MAKE_LED6_OUTPUT();
  TOSH_MAKE_LED7_OUTPUT();

  TOSH_CLR_RED_LED_PIN();
  TOSH_CLR_YELLOW_LED_PIN();
  TOSH_CLR_GREEN_LED_PIN();

  TOSH_CLR_LED2_PIN();
  TOSH_CLR_LED3_PIN();
  TOSH_CLR_LED4_PIN();
  TOSH_CLR_LED5_PIN();
  TOSH_CLR_LED6_PIN();
  TOSH_CLR_LED7_PIN();

}


#endif //TOSH_HARDWARE_H
