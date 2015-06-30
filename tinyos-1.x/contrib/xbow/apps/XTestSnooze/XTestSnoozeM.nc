/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University
 * of California.  All rights reserved.
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
 * Authors:             Joe Polastre
 * 
 * $Id: XTestSnoozeM.nc,v 1.1 2003/06/02 14:27:00 asbroad Exp $
 *
 * IMPORTANT!!!!!!!!!!!!
 * NOTE: The Snooze component will ONLY work on the Mica platform with
 * nodes that have the diode bypass to the battery.  If you do not know what
 * this is, check http://webs.cs.berkeley.edu/tos/hardware/diode_html.html
 * That page also has information for how to install the diode.
 */

/**
 * Implementation of the TestSnooze application
 */

includes XTestSnoozeHdr;

module XTestSnoozeM {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface Leds;
    interface Snooze;
    interface StdControl as GenericCommCtl;
    interface SendMsg as Send;
    interface ReceiveMsg as RcvMsg;
  
  }
}
implementation {
  #define GO_TO_SLEEP_CNT 5
  uint16_t dest;  
  uint16_t seqno;
  TOS_Msg msg;
  TOS_MsgPtr i2c_msg;

  /**
   * When the mote awakens, it must perform functions to begin processing again
   **/
  void processing()
  {
     call Leds.redOn();
  }

  /**
   * Invokes the Snooze.snooze() command to put the mote to sleep
   **/
  void sleep()
  {
    call Snooze.snooze(32*4);
  }

  /**
   * Event handled when the Snooze component triggers the application
   * that it has woken up
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Snooze.wakeup() {
    processing();
    return SUCCESS;
  }

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    result_t r2;
//    TOS_LOCAL_ADDRESS  = 3;              //delete if not jtagging
    dest = TOS_BCAST_ADDR;
    i2c_msg = &(msg);    
	r2 = call GenericCommCtl.init();
    call Leds.init();
    seqno = 0;
    processing();
    return r2;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Clock.setRate(TOS_I1PS, TOS_S1PS);
  }

  command result_t StdControl.stop() {
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }

/*-------------------------------------------------------------------------------------------  
 *sleep_task:go to sleep
 *-------------------------------------------------------------------------------------------*/
task void sleep_task(){
   sleep();
}
/*-------------------------------------------------------------------------------------------  
 * Clock.fire: just toggle yellow led to show that we're alive
 *-------------------------------------------------------------------------------------------*/
  event result_t Clock.fire()
  {
    call Leds.yellowToggle();
    seqno++;
    if (seqno == GO_TO_SLEEP_CNT){
        seqno = 0;
	    post sleep_task();
    }          
    return SUCCESS;
  }

/*-------------------------------------------------------------------------------------------  
 * Send.sendDone: 
 *   -xmit is complete
 *   -turn of green led
 *   -post task to sleep
 *-------------------------------------------------------------------------------------------*/
    event result_t Send.sendDone(TOS_MsgPtr m, result_t success){
	  	call Leds.greenOff();
	    post sleep_task(); //allow radio to return else hi current during sleep !
	    return SUCCESS;
    }
/*-------------------------------------------------------------------------------------------  
 *  RcvMsg : msg received
 *  - respond to cmd for sleep
 *  - turn on green led
 *-------------------------------------------------------------------------------------------*/
   event TOS_MsgPtr RcvMsg.receive(TOS_MsgPtr m) {
    call Leds.greenOn();
    call Send.send(dest,DATA_LENGTH,i2c_msg);
    return m;
  }

 }
