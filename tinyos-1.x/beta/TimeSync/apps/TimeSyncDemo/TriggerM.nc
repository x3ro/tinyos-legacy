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
 * Date last modified:  9/19/02
 *
 * This is a test program. It broadcast a SEND_TIME message without 
 * any data every 10 seconds.
 *
 */
includes SendTime;
module TriggerM {
    provides interface StdControl;
    uses {
	interface SendMsg as Send;
	interface StdControl as CommControl;
	interface Timer as Timer1;
        interface Leds;
    }
}
implementation
{

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending;

    uint16_t t;
    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t StdControl.init() {
        sendPending = FALSE;
 
        pmsg = &buffer;
        call Leds.init();
	call CommControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {

	call CommControl.start() ;
        call Timer1.start(TIMER_REPEAT, 10000);
   //     call Leds.redToggle();
    }

    command result_t StdControl.stop() {
	return call CommControl.stop() ;
    }

    void task sendTrigger() {

        struct TestTime * pdata = (struct TestTime *)pmsg->data;
        if (!sendPending) {
            pdata->source_addr = TOS_LOCAL_ADDRESS;
	    // send the msg now
	    sendPending = call Send.send(TOS_BCAST_ADDR, sizeof(struct TestTime), pmsg);
            call Leds.yellowToggle();
        }
    }


    event result_t Timer1.fired() {
        call Leds.yellowToggle();
        post sendTrigger();
	return SUCCESS ;
    }
   
    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        //if (msg == &buffer) {
            call Leds.redToggle();
            sendPending = FALSE;
        //}
        return SUCCESS;
    } 


}
