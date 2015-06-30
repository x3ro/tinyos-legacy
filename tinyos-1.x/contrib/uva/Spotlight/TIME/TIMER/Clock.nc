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
 * Authors:		Jason Hill, David Gay, Philip Levis, Nelson Lee, 
 *			Miklos Maroti
 * Date last modified:  1/12/03
 */

/*
 * The hardware clock interface. 
 **/
includes Clock;

interface Clock 
{
	/**
	 * Sets the clock rate.  For the specific meanings of interval
	 * and scale, refer to the processor data sheet. For the mica and rene:
	 * <p>
	 * <pre>
	 *     Clock scale
	 *         0 - off
	 *         1 - 32768 ticks/second
	 *         2 - 4096 ticks/second
	 *         3 - 1024 ticks/second
	 *         4 - 512 ticks/second
	 *         5 - 256 ticks/second
	 *         6 - 128 ticks/second
	 *         7 - 32 ticks/second
	 * </pre>
	 * <p>
	 *
	 * Interval is how many ticks per clock firing.
	 * For example, setRate(160,7) will result in an event every 160/32
	 * seconds.
	 *
	 * See also: <code>Clock.h</code> for predefined macros:
	 *
	 * <p>
	 * <pre>
	 *  interval      scale         result
	 *  TOS_I1000PS   TOS_S1000PS   1000 ticks/sec
	 *  TOS_I100PS    TOS_S100PS     100 ticks/sec
	 *  TOS_I10PS     TOS_S10PS       10 ticks/sec
	 *  TOS_I4096PS   TOS_S4096PS   4096 ticks/sec
	 *  TOS_I2048PS   TOS_S2048PS   2048 ticks/sec
	 *  TOS_I1024PS   TOS_S1024PS   1024 ticks/sec
	 *  TOS_I512PS    TOS_S512PS     512 ticks/sec
	 *  TOS_I256PS    TOS_S256PS     256 ticks/sec
	 *  TOS_I128PS    TOS_S128PS     128 ticks/sec
	 *  TOS_I64PS     TOS_S64PS       64 ticks/sec
	 *  TOS_I32PS     TOS_S32PS       32 ticks/sec
	 *  TOS_I16PS     TOS_S16PS       16 ticks/sec
	 *  TOS_I8PS      TOS_S8PS         8 ticks/sec
	 *  TOS_I4PS      TOS_S4PS         4 ticks/sec
	 *  TOS_I2PS      TOS_S2PS         2 ticks/sec
	 *  TOS_I1PS      TOS_S1PS         1 tick/sec
	 *  TOS_I0PS      TOS_S0PS         0 ticks/sec (clock off)
	 * </pre>
	 **/
	async command result_t setRate(uint8_t interval, uint8_t scale);

	/**
	 * Sets the clock rate in jiffies.
	 * @param jiffies The requested rate of the clock interrupt in jiffies
	 *		(1/CLOCK_JIFFY secs, usually 1/32768 secs, see Clock.h).
	 *		The actual rate can be different from <code>jiffies</code>,
	 *		because of hardware limitations, but it is always less.
	 *		Setting the rate to <code>0</code> tunrs off the clock.
	 * @return Always return SUCCESS
	 * @author miklos.maroti@vanderbilt.edu
	 */
	async command result_t setRate2(uint16_t jiffies);

	/**
	 * Returns the current rate of the clock.
	 * @return The current rate in jiffies (1/CLOCK_JIFFY secs).
	 *		The actual rate is always less than the requested rate.
	 *		If the clock is stopped then it returns <code>0</code>.
	 * @author miklos.maroti@vanderbilt.edu
	 */
	async command uint16_t getRate2();

	/**
	 * An event sent when the clock goes off.
	 **/
	async event result_t fire();
}
