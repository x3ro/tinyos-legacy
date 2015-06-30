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
 * Date last modified: 6/2/2003 6:03PM
 */

interface PeaceKeeper
{	
	/**
	 * Get the maximum size of the stack (ever).
	 * It will scan the end of the SRAM and will try to find the first "dirty byte".
	 */
	command uint16_t getMaxStack();
	
	/**
	 * Get the size of the free stack.
	 * It will scan the end of the SRAM and will try to find the first "dirty byte".
	 */
	command uint16_t getUnusedStack();

	/**
	 * Initates a new stack (DMZ) scan manually. If the check fails the MOTE will be suspended.
	 * In the suspended state the red LED is blinking plus
	 *       - the green LED is blinking if the stack has entered the DMZ
	 *       - the yellow LED is blinking if normal data access destroyed the DMZ pattern
	 * Otherwise it returns with SUCCESS
	 */
	command result_t checkStack();
}
