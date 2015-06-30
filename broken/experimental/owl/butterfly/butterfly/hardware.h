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
/*
 *
 * Authors:             Jason Hill, Philip Levis, Nelson Lee, David Gay
 *
 *
 */

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#include <avrhardware.h>
#include <stdio.h>

#undef ADC

TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);

TOSH_ASSIGN_PIN(I2C_BUS1_SCL, E, 4);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, E, 5);

#define UCR UCSRB
#define USR UCSRA

enum
{
	TOSH_ACTUAL_VOLTAGE_PORT = 30
};
enum
{
	TOS_ADC_VOLTAGE_PORT = 7
};

/**
 * (Busy) wait <code>usec</code> microseconds
 */
void inline TOSH_uwait(int u_sec)
{
  /* In most cases (constant arg), the test is elided at compile-time */
  if (u_sec >= 4)
    {
      u_sec >>= 2;
      /* loop takes 4 cycles, aka 4us */
      asm volatile (
"1:	sbiw	%0,1\n"
"	brne	1b" : "+w" (u_sec));
    }
}

/**
 * (Busy) wait <code>msec</code>  milliseconds
 */
void inline TOSH_mwait(int m_sec)
{
  while (m_sec--)
    TOSH_uwait(992);
}

enum {
  TOSH_ADC_PORTMAPSIZE = 3
};

#endif //TOSH_HARDWARE_H
