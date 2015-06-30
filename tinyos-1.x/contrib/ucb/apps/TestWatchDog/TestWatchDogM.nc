// $Id: TestWatchDogM.nc,v 1.2 2003/10/07 21:45:35 idgay Exp $

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
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified: 
 *
 */

/** 
 * Implementation for TestWatchDogM module. 
 **/ 

includes TosTime;

module TestWatchDogM {
    uses {
    	interface Leds;
    	interface StdControl as ATimerControl;
        interface AbsoluteTimer as Atimer;
        interface TimeUtil;
	interface WatchDog;
    }
    provides interface StdControl;
}

implementation {
    tos_time_t  t1;

    /** 
     *  module Initialization.  initlize module variables
     *  and lower level components
     **/

    command result_t StdControl.init() {
    	t1.high32 = 0x0; t1.low32 = 0x400000;
    	call Leds.init();
	call ATimerControl.init();
    	return SUCCESS;
    }
 
    command result_t StdControl.start() {
        result_t retval; 
        tos_time_t tt;
	call ATimerControl.start(); 
	retval = call WatchDog.set(t1);      
        if (!retval) {
            dbg(DBG_USR1, "set watch dog timer failed\n");
            call Leds.redOn();
        } else {
            call Leds.greenOn();
        }
        // start a timer
        tt = call TimeUtil.create(0, 0x80000);
        
        retval = call Atimer.set(tt);        
        //if (!retval) call Leds.yellowOn();

        return retval;
    }


    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
	call WatchDog.cancel();
    	call ATimerControl.stop();
    	return SUCCESS ;
   
    }
    
    event result_t Atimer.fired() {
        int i=0;
        // cancel the watch dog timer now
        //result_t retval = call WatchDog.cancel();
        /*
        if (retval) {
            call Leds.greenToggle();
        } else { call Leds.redToggle(); }
        */
        while (i<4000) { i++ ; } 
        // restart WDT
        //retval = call WatchDog.set(t1);
        /* 
        if (retval) {
            call Leds.greenToggle();
        } else {
            call Leds.redToggle();
        }
        */
        return SUCCESS;
    }
   
}


