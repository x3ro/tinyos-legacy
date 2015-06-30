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
 * Date last modified: 12/07/03
 */

#ifndef __HPLSYSCLOCK_H
#define __HPLSYSCLOCK_H

/*
HPLSYSCLOCK_SECOND:
	The number of clock ticks per second.

HPLSYSCLOCK_CHECK_TIME:	
	The maximum time (number of clock ticks) required to perform one 
	particular check in system/HPLSysClock32M.nc. This should not 
	be defined if the platform provides a native HPLSysClock32 
	implementation. This value should be computed with the 
	TestHPLSysTime16C application.

HPLSYSCLOCK_SETALARM_TIME:
	The maximum time (number of clock ticks) required to call the
	HPLSysClock32.setAlarm command. This value should be computed
	with the TestHPLSysTime32C application.
*/

enum
{
#ifndef HPLSYSCLOCK_DEFSCALE
#define HPLSYSCLOCK_DEFSCALE	1	// default prescaling
#endif
	HPLSYSCLOCK_PRESCALE = HPLSYSCLOCK_DEFSCALE,

#if defined(PLATFORM_MICA2)
#if HPLSYSCLOCK_DEFSCALE == 1
	HPLSYSCLOCK_SECOND = 7372800ul,	// no prescaling
	HPLSYSCLOCK_CHECK_TIME = 30,	// exact value 26
	HPLSYSCLOCK_SETALARM_TIME = 33,	// exact value 29
#elif HPLSYSCLOCK_DEFSCALE == 2
	HPLSYSCLOCK_SECOND = 921600ul,	// prescaling 1/8
	HPLSYSCLOCK_CHECK_TIME = 5,	// exact value 4
	HPLSYSCLOCK_SETALARM_TIME = 5,	// exact value 4
#elif HPLSYSCLOCK_DEFSCALE == 3
	HPLSYSCLOCK_SECOND = 115200ul,	// prescaling 1/64
	HPLSYSCLOCK_CHECK_TIME = 2,	// exact value 1
	HPLSYSCLOCK_SETALARM_TIME = 2,	// exact value 1
#endif

#elif defined(PLATFORM_MICA2DOT)	// calculated from the MICA2 values
#if HPLSYSCLOCK_DEFSCALE == 1
	HPLSYSCLOCK_SECOND = 4000000ul,
	HPLSYSCLOCK_CHECK_TIME = 30,
	HPLSYSCLOCK_SETALARM_TIME = 33,
#elif HPLSYSCLOCK_DEFSCALE == 2
	HPLSYSCLOCK_SECOND = 500000ul,
	HPLSYSCLOCK_CHECK_TIME = 5,
	HPLSYSCLOCK_SETALARM_TIME = 5,
#elif HPLSYSCLOCK_DEFSCALE == 3
	HPLSYSCLOCK_SECOND = 62500ul,
	HPLSYSCLOCK_CHECK_TIME = 2,
	HPLSYSCLOCK_SETALARM_TIME = 2,
#endif

#endif
};

#endif//__HPLSYSCLOCK_H
