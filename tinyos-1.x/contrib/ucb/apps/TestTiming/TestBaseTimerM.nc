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

/* Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  
 *
 * Expected results: red Led toggles every second 
 *
 */

/** 
 * Implementation for TestBaseTimerM module. 
 **/ 


includes TosTime;
includes SendTime;

module TestBaseTimerM {
    uses {
        interface SendMsg as SendTime;
	interface StdControl as CommControl;
        interface Time;
        interface TimeSet;
        interface TimeUtil;
        interface Leds;
        interface AbsoluteTimer as BaseTimer;
        interface StdControl as TimeControl;
    }
    provides interface StdControl;
}

implementation {

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;
    bool state ; 

    uint16_t receiverTimeStamp, currentTime;
    tos_time_t t0, t1;

    task void PCdebugTime();

    task void debugTime() {
        struct SendTime *pdata;
        tos_time_t t;
        
        if (!sendPending) {         
            pdata = (struct SendTime *)pmsg->data;
            pdata->source_addr = TOS_LOCAL_ADDRESS;

            t = call Time.get();
            dbg(DBG_USR1, "debugTime: t=\%x, \%x\n", t.high32, t.low32);

            pdata->timeH = t.high32;
            pdata->timeL = t.low32;
            pdata-> time = t1.high32;
            pdata->receiver_settime = t1.low32;
            // send the msg now
            //sendPending = call SendTime.send(TOS_UART_ADDR, sizeof(struct SendTime), pmsg);
        }
        t1 = call TimeUtil.add(t1, t0);
        call BaseTimer.set(t1);
    }


    /** 
     *  module Initialization.  initlize module variables
     *  and lower level components
     **/

    command result_t StdControl.init(){
        sendPending = FALSE;
        pmsg = &buffer;

        t1.high32 = 0x0; t1.low32 = 0x108000;
        t0.high32 = 0x0; t0.low32 = 0x100000;		
        call Leds.init();
        call TimeControl.init();
        call CommControl.init();
        return SUCCESS;
    }
 
    command result_t StdControl.start() {
        tos_time_t tt;
        call TimeControl.start(); // make sure we set the clock
	call CommControl.start() ;
        
        tt = call TimeUtil.create(0,0);
        call TimeSet.set(tt);
        dbg(DBG_USR1,"Test: set base timer to=\%x, \%x\n", t1.high32, t1.low32);
	call BaseTimer.set(t1);
        //post PCdebugTime();
        
        return SUCCESS;
    }

    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
        call TimeControl.stop();
        return call CommControl.stop() ;    
    }


    event result_t SendTime.sendDone(TOS_MsgPtr msg, result_t success) {
        sendPending = FALSE;
        call Leds.yellowToggle();
        return SUCCESS;
    }

    task void PCdebugTime() {
        tos_time_t tt;
        tt = call Time.get();
        dbg(DBG_USR1,"Test: tt=\%x, \%x\n", tt.high32, tt.low32); 
        call BaseTimer.set(call TimeUtil.add(tt, t0));
    }


    event result_t BaseTimer.fired() {
        call Leds.redToggle();
        dbg(DBG_USR1, "Test: base timer expired\n");
        //t1 = call TimeUtil.add(t1, t0);
        //call BaseTimer.set(t1);
        post PCdebugTime();
        //post debugTime();
        return SUCCESS;
    }
}
