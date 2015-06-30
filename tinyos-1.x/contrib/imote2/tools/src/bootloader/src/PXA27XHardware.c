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

#include <pxa27xhardware.h>

void TOSH_wait()
{
  asm volatile("nop");
  asm volatile("nop");
}

/**
 * (Busy) wait <code>usec</code> microseconds
 */
inline void TOSH_uwait(uint16_t usec)
{
  uint32_t start,mark = usec;

  //in order to avoid having to reset OSCR0, we need to look at time differences
  
  start = OSCR0;
  mark <<= 2;
  mark *= 13;
  mark >>= 2;

  //OSCR0-start should work correctly due to nice properties of underflow
  while ( (OSCR0 - start) < mark);
}

inline uint32_t _pxa27x_clzui(uint32_t i) {
  uint32_t count;
  asm volatile ("clz %0,%1"
		: "=r" (count)
		: "r" (i)
		);
  return count;
}


//NOTE...at the moment, these functions will ONLY disable the IRQ...FIQ is left alone
inline __nesc_atomic_t __nesc_atomic_start(void)
{
  uint32_t result = 0;
  uint32_t temp = 0;

  asm volatile (
		"mrs %0,CPSR\n\t"
		"orr %1,%2,%4\n\t"
		"msr CPSR_cf,%3"
		: "=r" (result) , "=r" (temp)
		: "0" (result) , "1" (temp) , "i" (ARM_CPSR_INT_MASK)
		);
  return result;
}

inline void __nesc_atomic_end (__nesc_atomic_t oldState)
{
  uint32_t  statusReg = 0;
  //make sure that we only mess with the INT bit
  oldState &= ARM_CPSR_INT_MASK;
  asm volatile (
		"mrs %0,CPSR\n\t"
		"bic %0, %1, %2\n\t"
		"orr %0, %1, %3\n\t"
		"msr CPSR_c, %1"
		: "=r" (statusReg)
		: "0" (statusReg),"i" (ARM_CPSR_INT_MASK), "r" (oldState)
		);

  return;
}

inline void __nesc_enable_interrupt() 
{

  uint32_t statusReg = 0;

  asm volatile (
	       "mrs %0,CPSR\n\t"
	       "bic %0,%1,#0xc0\n\t"
	       "msr CPSR_c, %1"
	       : "=r" (statusReg)
	       : "0" (statusReg)
	       );
  return;
}

inline void __nesc_atomic_sleep()
{
  /* 
   * Atomically enable interrupts and sleep , 
   * LN : FOR NOW SLEEP IS DISABLED will be adding this functionality shortly
   */
  __nesc_enable_interrupt();
  return;
}
