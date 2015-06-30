/*
 * Copyright (c) 2004, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 2/19/04
 */

includes HPLSysClock;

module HPLSysClock16C
{
	provides 
	{
		interface StdControl;
		interface HPLSysClock16;
	}
}

implementation
{
	command result_t StdControl.init()
	{
		outb(TCCR3A, 0x00);
		outb(TCCR3B, 0x00);
		outb(ETIMSK, (inb(ETIMSK)&(1<<OCF1C))|(1<<TOIE3));

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		outb(TCCR3B, HPLSYSCLOCK_PRESCALE & 0x07);

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		outb(TCCR3B, 0x00);

		return SUCCESS;
	}

	inline async command uint16_t HPLSysClock16.getTime()
	{
		return inw(TCNT3L);
	}

	// interrupts are disabled
	TOSH_SIGNAL(SIG_OVERFLOW3)
	{
		signal HPLSysClock16.overflow();
	}

	inline async command bool HPLSysClock16.getOverflowFlag()
	{
		return bit_is_set(ETIFR, TOV3);
	}

	inline async command void HPLSysClock16.setAlarm(uint16_t time)
	{
		outw(OCR3AL, time);
		outb(ETIFR, 1<<OCF3A);
		sbi(ETIMSK, OCIE3A);
	}

	// interrupts are disabled, no cancelling of the alarm
	TOSH_SIGNAL(SIG_OUTPUT_COMPARE3A)
	{
		signal HPLSysClock16.fired();
	}

	inline async command void HPLSysClock16.cancelAlarm()
	{
		cbi(ETIMSK, OCIE3A);
	}
}
