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
/*
 * Authors:		Jason Hill, David Gay, Philip Levis, Nelson Lee
 *                      Su Ping (added Clock.init and Clock.getRate)
 * Date last modified:  6/25/02
 *
 *
 */



/**
 * The hardware clock interface. 
 **/
includes Clock;

interface Clock {

  /**
   *  Set the clock rate.  For the specific meanings of interval
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
   *  interval      scale         result		clcokRate(index)
   *  TOS_I4096PS   TOS_S4096PS   4096 ticks/sec	12
   *  TOS_I2048PS   TOS_S2048PS   2048 ticks/sec	11
   *  TOS_I1024PS   TOS_S1024PS   1024 ticks/sec	10
   *  TOS_I512PS    TOS_S512PS     512 ticks/sec	9
   *  TOS_I256PS    TOS_S256PS     256 ticks/sec	8
   *  TOS_I128PS    TOS_S128PS     128 ticks/sec	7
   *  TOS_I64PS     TOS_S64PS       64 ticks/sec	6
   *  TOS_I32PS     TOS_S32PS       32 ticks/sec	5
   *  TOS_I16PS     TOS_S16PS       16 ticks/seca	4
   *  TOS_I8PS      TOS_S8PS         8 ticks/sec	3
   *  TOS_I4PS      TOS_S4PS         4 ticks/sec	2
   *  TOS_I2PS      TOS_S2PS         2 ticks/sec	1
   *  TOS_I1PS      TOS_S1PS         1 tick/sec		0
   *  TOS_I0PS      TOS_S0PS         0 ticks/sec 	stopped
   * </pre>
   **/
  command result_t setRate(char interval, char scale);
  command uint8_t getRate();
  command result_t set(char clockRate);
  command result_t init();
  /**
   *  An event sent when the clock goes off.
   **/
  event result_t fire();
}










