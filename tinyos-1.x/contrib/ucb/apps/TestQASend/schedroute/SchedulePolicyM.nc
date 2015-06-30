/*									tab:4
 *
 *
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
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
/*
 *		SchedulePolicy	
 *
 * Author:	Barbara Hohlt
 * Project:    	Buffer Management 
 *
 *
 * This module is an example managing a simple fifo sendQueue 
 * using CircleQueues.
 *
 */

module SchedulePolicyM {
 
  
  provides {
    interface StdControl as Control;
    interface ActiveNotify;
  }

  uses {

    interface StdControl as SubControl;
    interface QueuePolicy;
    interface Timer as Timer0;
  }
}
implementation {

enum {
  APPLICATION_NOTIFY = 1024 
};


  command result_t Control.init() {

    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Initialized.\n");

    call SubControl.init();

    return SUCCESS;
  }
  
  command result_t Control.start() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Started.\n");

	call SubControl.start();
	call Timer0.start(TIMER_REPEAT,APPLICATION_NOTIFY);

	return SUCCESS;
  }
  
  command result_t Control.stop() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Stopped.\n");
 	call Timer0.stop();
	call SubControl.stop();
	return SUCCESS; 
  }

  /* Notifies the application that it is time to send a message */
  event result_t Timer0.fired()
  {
        dbg(DBG_ROUTE, "MultiHopSend: Timer fired.\n");
        signal ActiveNotify.activated();
	return SUCCESS;
  }

  event void QueuePolicy.next() {
    call QueuePolicy.forward();  /* Naive store-and-forward policy ! */
    return;
  }
}
