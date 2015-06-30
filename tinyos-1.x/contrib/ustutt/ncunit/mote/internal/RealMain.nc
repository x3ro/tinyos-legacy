// $Id: RealMain.nc,v 1.1 2007/02/20 12:33:07 lachenmann Exp $

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
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  $Id: RealMain.nc,v 1.1 2007/02/20 12:33:07 lachenmann Exp $
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


module RealMain {
  uses {
    command result_t hardwareInit();
    interface StdControl;
    interface Pot;
	interface TestStarter;
	interface StdControl as TimerControl;
	interface Timer;
  }
}
implementation
{
#ifndef TEST_TIMER_INTERVAL
#define TEST_TIMER_INTERVAL 10240
#endif

#include <avr/pgmspace.h>

  //somehow needed to store test case number in program memory (workaround)
  static const prog_uchar dummy = 1;

  event result_t Timer.fired() {
	call TestStarter.startTest();
	return SUCCESS;
  }

  static void testStart(char* message) __attribute__((noinline)) {
	asm volatile ("nop"::);
  }

  static void testEnd() __attribute__((noinline)) {
	asm volatile ("nop"::);
  }

  event void TestStarter.testCaseStart(char* message) {
	testStart(message);
  }

  event void TestStarter.testCaseEnd() {
	testEnd();
  }

  int main() __attribute__ ((C, spontaneous)) {
    call hardwareInit();
    call Pot.init(10);
    TOSH_sched_init();
	PRG_RDB(&dummy);
    
    call StdControl.init();
	call TimerControl.init();
    call StdControl.start();
	call TimerControl.start();
    __nesc_enable_interrupt();

	call Timer.start(TIMER_ONE_SHOT, TEST_TIMER_INTERVAL);

    while(1) {
       TOSH_run_task();
    }
  }
}
