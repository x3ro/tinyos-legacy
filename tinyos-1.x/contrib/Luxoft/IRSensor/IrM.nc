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
 *
 * Authors:		Dmitriy Korovkin
 * Date last modified:  6/25/02
 *
 */

/*  OS component abstraction of the analog infrared sensor and */
/*  associated A/D support.  It provides an asynchronous interface */
/*  to the IR sensor. */

/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

#ifndef EMU_TIMEOUT
  #define EMU_TIMEOUT 1000
#endif
includes sensorboard;
module IrM 
{
  provides 
  {
    interface StdControl;
    interface MicInterrupt;
  }
#ifdef PLATFORM_PC
  uses
  {
    interface Timer;
    interface Random;
  }
#endif
}
implementation {

  task void IrTask();

  /* 
   * StdControl interface functions
   */
  command result_t StdControl.init() 
  {
#ifdef PLATFORM_PC
    call Random.init();
#endif
    return call MicInterrupt.disable();
  }

  command result_t StdControl.start() {
    return call MicInterrupt.enable();
  }

  command result_t StdControl.stop() {
    return call MicInterrupt.disable();
  }

  /*
   * MicInterrupt interface functions
   */
  command result_t MicInterrupt.enable(){
#ifdef PLATFORM_MICA2DOT
    atomic
    {
      cbi(EIMSK, INT0);
     
      sbi(EICRA, ISC01);
      sbi(EICRA, ISC00);
      
      TOSH_MAKE_INT0_INPUT();
      
      sbi(EIMSK, INT0);
      TOSH_wait();
    }
#endif
#ifdef PLATFORM_PC
    call Timer.start(TIMER_ONE_SHOT, EMU_TIMEOUT);
#endif
    return SUCCESS;
  }

  command result_t MicInterrupt.disable(){
#ifdef PLATFORM_MICA2DOT
    cbi(EIMSK, INT0);
#endif
#ifdef PLATFORM_PC
    call Timer.stop();
#endif
    return SUCCESS;
  }

  default event result_t MicInterrupt.toneDetected() 
  {
    return SUCCESS;
  }
 
  task void IrTask()
  {
    signal MicInterrupt.toneDetected();
    call MicInterrupt.enable();
  }
 
#ifdef PLATFORM_MICA2DOT
  TOSH_SIGNAL(SIG_INTERRUPT0) 
  {
    call MicInterrupt.disable();
    TOSH_interrupt_enable();
    post IrTask();
  }
#endif

#ifdef PLATFORM_PC
  event result_t Timer.fired()
  {
    uint16_t data = call Random.rand();
    dbg(DBG_USR1, "IR: Random - %d\n", data);
    if (data > 45000)
      post IrTask();
    else
      call MicInterrupt.enable();
    return SUCCESS;
  }
#endif
}

