/*									tab:4
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
 * Authors:		Su Ping, ported to nesC by Sam Madden
 * Date last modified:  6/25/02
 */
/*
Expected Behavior:

Time:              Event:                 Timer:
100 ms             RED light on           0    It toggles every 100ms forever
200 ms             Green Light On         3
1s                 Yellow Light On        1
2s                 Y off, G off           1,2
3s                 Y on                   1
4s                 Y off, G on            1,2
5s                 Y on                   1
6s                 Y off, G off           1,2
7s                 Y on                   1
8s                 Y off                  1
9s                 Y on                   1
10s                Y off                  1
10.5s              R on                   0
11s                R off                  0
11.5s              R on                   0
11.6s              R off                  0
11.7s              R on                   0
11.8s              R off                  0
...
(Timer 0 repeats every 100ms forever)

 *
 */


/** 
 * Implementation for LogicTimeTestM module. 
 **/ 
includes AM;
includes TimeSyncMsg;
module LogicTimeTestM {
	uses {
	  interface Leds;
	  interface StdControl as CommControl;
	  interface SendMsg as Send;
          interface AbsoluteTimer;
          interface LogicTime;
	}
	provides interface StdControl;
}

implementation {
    void sendTime();

    TOS_Msg buffer;
    TOS_MsgPtr pmsg;
    bool sendPending; 

	uint32_t myTime;
/** 
 *  module Initialization. Turn all the LEDs off and initlize module variables
 **/

  command result_t StdControl.init(){
    myTime = 0;
    sendPending = FALSE;
    pmsg = &buffer;
	call CommControl.init();
	call Leds.init();
    call AbsoluteTimer.init();
   
    return SUCCESS;
  }
 /**
  * start 4 timers: a one shot timer fires at 100 ms ater it is started, 
  * a repeat timer, which fires every 1000 ms
  * another repeat timer, which fires every 2000 ms
  * and 1 single-shot timer at 200 ms
  * @return Always return <code>SUCCESS</code>
  **/ 
  command result_t StdControl.start() {
    int i;
    call CommControl.start();
	call Leds.yellowToggle();
    for (i=0; i++; i<20); // delay 
	sendTime();
	call LogicTime.set(0x563412);
	
	sendTime();
	myTime = 0x60000 ;
	call AbsoluteTimer.start(myTime);
	call Leds.yellowToggle();
    
    
    return SUCCESS;
  }

/** 
 *  Stop all timers
 *  @return Always return <code>SUCCESS</code>
 **/
  command result_t StdControl.stop() {
	call CommControl.stop();
    return SUCCESS;
  }

    void sendTime() {
	    
        struct TimeSyncMsg * pdata = (struct TimeSyncMsg *)pmsg->data;
	    
	    //sender = pdata->source_addr;
	    pdata->source_addr = TOS_LOCAL_ADDRESS;
	    pdata->type = TIME_RESPONSE;
        pdata->timeH = call LogicTime.get();
        pdata->timeL = call LogicTime.currentTime();
	    // send the msg now
	    sendPending = call Send.send(TOS_BCAST_ADDR, sizeof(struct TimeSyncMsg), pmsg);
        call Leds.redToggle();
    }


    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
        if (success) {
            //call Leds.redToggle();
            sendPending = FALSE;
        }
        return SUCCESS;
    } 
/** 
 *  Timer expired Event Handler 
 *  Toggle red LED . 
 *  @return Alway return <code>SUCCESS</code>
 **/

 /* event result_t AbsoluteTimer.expired() {
    call Leds.greenToggle();
	
    call LogicTime.set(600000);
	sendTime();
    call AbsoluteTimer.start(800000);

    return SUCCESS;
	
}
*/

  event result_t AbsoluteTimer.expired() {
    sendTime();
    call Leds.greenToggle();
	myTime+=0x40000;
    //call LogicTime.set(800000);
	//sendTime();
    call AbsoluteTimer.start(myTime);

    return SUCCESS;
  }
	

  
}
