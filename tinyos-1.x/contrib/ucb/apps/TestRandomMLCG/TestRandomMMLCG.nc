/*
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

/**
 * Implementation for TestRandomMLCG application.  Send a random number and
 * toggle the red LED when a Timer fires.
 *
 * @author hohltb@cs.berkeley.edu
 **/
module TestRandomMMLCG {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Random32 as Random;
    interface SendMsg;
    interface Leds;
  }
}
implementation {
	
   typedef struct FPSrand {
    uint16_t mote_id;
    uint32_t random_slot; 
    uint32_t random_number; 
   } __attribute__ ((packed)) FPSrand;

   TOS_Msg msgRand;
   FPSrand *msgPtr; 
   uint16_t counter;
   uint32_t r;

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call Random.initSeed((uint16_t) 0); /* start with seed = 1 */
    call Leds.init(); 
    memset(msgRand.data,0,TOSH_DATA_LENGTH);
    msgPtr = (FPSrand *) msgRand.data;
    msgPtr->mote_id = TOS_LOCAL_ADDRESS;
    counter = 0;

    return SUCCESS;
  }


  /**
   * Start things up. This starts the Timer component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    // Start a repeating timer that fires every 100ms
    return call Timer.start(TIMER_REPEAT, 100);
  }

  /**
   * Halt execution of the application.
   * This stops the Timer component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  task void sendRand() {
     msgPtr->random_number = r; 
     msgPtr->random_slot = r % 240; 
     if (call SendMsg.send(TOS_BCAST_ADDR,sizeof(FPSrand),&msgRand) )
      call Leds.redOn();
     dbg(DBG_USR1,"RandomMLCG send %u %u %lu\n",r%240, counter, r);

     return;
  }
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success)
  {
    call Leds.redOff();
    return SUCCESS;
  }

  /**
   * Send a random number and toggle the red LED in response to 
   * the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired()
  {
    counter++;
    r = call Random.rand32();
    dbg(DBG_USR1,"RandomMLCG %u %u %lu\n",r%240, counter, r);
    if (counter == 10000) {
	call Timer.stop();
        post sendRand();
    }
    return SUCCESS;
  }
}


