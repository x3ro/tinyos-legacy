/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Author: Peter Volgyesi
 * Date last modified: 6/2/2003 6:08PM
 */

module PeaceKeeperM
{
	provides 
	{
		interface StdControl;
		interface PeaceKeeper;
	}
	uses
	{
		interface Leds;
		interface StdControl as TimerControl;
		interface Timer;
	}
}

implementation
{
	#define WATCHDOG_INTERVAL_MS	1000
	#define DMZ_PATTERN		0x55
	#define STACK_PATTERN		0x66
	#define DMZ_SIZE	64				// Number of bytes in the DMZ
	
	#define BLINK_INTERVAL_MS	200		// Blinking rate = 5Hz
	#define BLINK_ON		1
	#define BLINK_OFF		0
	
	uint8_t *startOfDMZ;
	uint8_t *startOfStack;
	
	void emergency(uint8_t blinkRed, uint8_t blinkGreen, uint8_t blinkYellow);
	
	/**
	 * Initializes the patterns on the stack and in the DMZ.
	 * It will allocate the DMZ right after the data segment (.bss). The size of the DMZ determines
	 * the area remained for the the stack
	 *
	 */
	command result_t StdControl.init()
	{
		extern uint8_t __bss_end;
		volatile uint8_t *sp;
		
		startOfDMZ = &__bss_end;
		startOfStack = startOfDMZ + DMZ_SIZE;
		
		asm volatile (
			"\n"
			"in	%A0, __SP_L__"	"\n\t"
			"in	%B0, __SP_H__"	"\n\t"
			: "=e" (sp)
			:
		);
		
		if ( ((uint16_t)sp) < ((uint16_t)startOfStack) ) {
			emergency(BLINK_ON, BLINK_ON, BLINK_ON);
		}
		
		memset(startOfDMZ, DMZ_PATTERN, DMZ_SIZE);
		memset(startOfStack, STACK_PATTERN, sp - startOfStack);
		
		call Leds.init();
		call TimerControl.init();
		return SUCCESS;
	}
	
	/**
	 * Starts up the scan watchdog. This watchdog will initate checks with a given frequency.
	 */
	command result_t StdControl.start()
	{
		call Timer.start(TIMER_REPEAT, WATCHDOG_INTERVAL_MS); 
		return SUCCESS;
	}

	/**
	 * Stops the watchdog described above.
	 */	
	command result_t StdControl.stop()
	{
		call Timer.stop();
		return SUCCESS;
	}
	
	/**
	 * Get the maximum size of the stack (ever).
	 * It will scan the end of the SRAM and will try to find the first "dirty byte".
	 */
	command uint16_t PeaceKeeper.getMaxStack()
	{
		extern	uint8_t __stack;
		uint8_t	*ptr;
		
		
		for (ptr = startOfStack; ptr != (&__stack); ptr++) {
			if ((*ptr) != STACK_PATTERN) {
				break;
			}
		}
			
		return ((&__stack) - ptr);
	}
	
	/**
	 * Get the size of the free stack.
	 * It will scan the end of the SRAM and will try to find the first "dirty byte".
	 */
	command uint16_t PeaceKeeper.getUnusedStack()
	{
		extern	uint8_t __stack;
		uint16_t max_stack;
		
		max_stack = call PeaceKeeper.getMaxStack();
			
		return (((&__stack) - startOfStack) - max_stack);
	}

	
	/**
	 * Initates a new stack (DMZ) scan manually. If the check fails the MOTE will be suspended.
	 * In the suspended state the red LED is blinking plus
	 *       - the green LED is blinking if the stack has entered the DMZ
	 *       - the yellow LED is blinking if normal data access destroyed the DMZ pattern
	 * Otherwise it returns with SUCCESS
	 */
	command result_t PeaceKeeper.checkStack()
	{
		uint8_t *ptr;
		char end_ok = 0;
		
		for (ptr = (startOfStack-1); ptr != (startOfDMZ-1); ptr--) {
			if ((*ptr) != DMZ_PATTERN) {
				emergency(BLINK_ON, 
					end_ok ? BLINK_OFF : BLINK_ON, 
					end_ok ? BLINK_ON : BLINK_OFF);
			}
			else {
				end_ok = 1;
			}
		}
		
		return SUCCESS;
	}
	
	/**
	 * The Watchdog
	 */
	event result_t Timer.fired()
	{
		call PeaceKeeper.checkStack();
		return SUCCESS;
	}

	/**
	 * Emergency function: suspends the MOTE and blinks the specified LEDS
	 */
	void emergency(uint8_t blinkRed, uint8_t blinkGreen, uint8_t blinkYellow)
	{
		uint16_t cnt;
		uint8_t  ms;
		uint16_t delay_count;
		
#ifdef PLATFORM_MICA2
		delay_count = 2000;
#else
		delay_count = 1000;
#endif

		ms = BLINK_INTERVAL_MS;
		
		TOSH_interrupt_disable();
		
		for (;;) {
			if (blinkRed) {
				call Leds.redToggle();
			}
			if (blinkGreen) {
				call Leds.greenToggle();
			}
			if (blinkYellow) {
				call Leds.yellowToggle();
			}
			
			asm volatile (
				"\n"
				"L_delay1%=:"		"\n\t"
				"mov	%A0, %A2"		"\n\t"
				"mov	%B0, %B2"		"\n\t"
				"L_delay2%=:"		"\n\t"
				"sbiw	%A0, 1"		"\n\t"
				"brne L_delay2%="	"\n\t"
				"dec	%1"		"\n\t"
				"brne L_delay1%="	"\n\t"
				: "=&w" (cnt)
				: "r" (ms), "r" (delay_count)
			);
		}
		
	}
	
	/** 
	 * The stack scanning task
	 */
	task void scanner()
	{
		// TODO: implement the scanning in a task
	}
}
