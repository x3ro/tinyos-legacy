/*									tab:4
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
 * Copyright (c) 2002, Vanderbilt University
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
 */

/*
 * Miklos Maroti: corrected and modified the constants for the ATmega103.
 * If scale is 1, then the actual interval is (interval+1).
 */

#ifndef __CLOCK_H
#define __CLOCK_H

// Usage is Clock.setRate(TOS_InPS, TOS_SnPS)
enum 
{
	TOS_I1000PS = 32,	TOS_S1000PS = 1,
	TOS_I100PS  = 41,	TOS_S100PS  = 2,
	TOS_I10PS   = 102,	TOS_S10PS   = 3,
	TOS_I4096PS = 7,	TOS_S4096PS = 1,
	TOS_I2048PS = 15,	TOS_S2048PS = 1,
	TOS_I1024PS = 31,	TOS_S1024PS = 1,
	TOS_I512PS  = 63,	TOS_S512PS  = 1,
	TOS_I256PS  = 127,	TOS_S256PS  = 1,
	TOS_I128PS  = 255,	TOS_S128PS  = 1,
	TOS_I64PS   = 64,	TOS_S64PS   = 2,
	TOS_I32PS   = 128,	TOS_S32PS   = 2,
	TOS_I16PS   = 64,	TOS_S16PS   = 3,
	TOS_I8PS    = 128,	TOS_S8PS    = 3,
	TOS_I4PS    = 128,	TOS_S4PS    = 4,
	TOS_I2PS    = 128,	TOS_S2PS    = 5,
	TOS_I1PS    = 128,	TOS_S1PS    = 6,
	TOS_I0PS    = 0,	TOS_S0PS    = 0,
};

#ifndef CLOCK_TYPE
#define CLOCK_TYPE			CLOCK_TYPE_NORMAL
#endif

/*
 * CLOCK_TYPE     : Selects the characteristics of the Clock component.
 * CLOCK_JIFFY    : The resolution of the clock in ticks per second
 * CLOCK_RATE_MIN : The minimum representable interrupt rate in jiffies
 * CLOCK_RATE_MAX : The maximum representable interrupt rate in jiffies
 */

#define CLOCK_TYPE_NORMAL	1
#define CLOCK_TYPE_LOWRES	2

#if CLOCK_TYPE == CLOCK_TYPE_NORMAL && defined(__AVR_ATmega103__)
enum
{
	CLOCK_JIFFY = 32768u,
	CLOCK_RATE_MIN = 2,
	CLOCK_RATE_MAX = 65280u,
};
#elif CLOCK_TYPE == CLOCK_TYPE_LOWRES && defined(__AVR_ATmega103__)
enum
{
	CLOCK_JIFFY = 4096,
	CLOCK_RATE_MIN = 1,
	CLOCK_RATE_MAX = 32640,
};
#elif CLOCK_TYPE == CLOCK_TYPE_NORMAL && defined(__AVR_ATmega128__)
enum
{
	CLOCK_JIFFY = 32768u,
	CLOCK_RATE_MIN = 2,
	CLOCK_RATE_MAX = 65280u,
};
#elif CLOCK_TYPE == CLOCK_TYPE_LOWRES && defined(__AVR_ATmega128__)
enum
{
	CLOCK_JIFFY = 4096,
	CLOCK_RATE_MIN = 1,
	CLOCK_RATE_MAX = 32768,
};
#endif

#endif//__CLOCK_H
