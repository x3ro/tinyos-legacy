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
/** 
 *
 *	Test Application using SlackerQueues
 *
 *	A trivial application to demonstrate the use of
 *	SlackerQueues for buffer management abd forward queueing
 *	in the MultiHop component.  
 *
 *	Every 3200 ms the MultiHop component sends an ActiveNotify event 
 *	indicating the application can send one message. 
 * 
 *	If sampling sensor data, the idea is to send 
 *	the ith - 1 sample when the ActiveNotify event is
 *	received and then take the next sample.
 *
 *
 * Author:	Barbara Hohlt
 * Project:	FPS
 *
 **/
module TestSlackerQueuesM {

  provides interface StdControl as Control;
  uses {
	interface Send; 
	interface Receive;
	interface ActiveNotify;
	//interface StdControl as ADCControl;
	//interface ADC;
  }
}
implementation
{
  TOS_Msg msg1;
  int counter;
  enum {
    MAX_CHIRPS = 100
  };

  command result_t Control.init() {

    //call ADCControl.init();
    return SUCCESS; 
  }
 
  command result_t Control.start() {
    counter = 0;
    return SUCCESS; 
  } 

  command result_t Control.stop() {
    return SUCCESS;
  } 

  task void doProcessing() {

    uint16_t dlen;
    uint8_t *dataPtr;
    uint16_t i;
    FPSmsg *message = (FPSmsg *) msg1.data;

    dbg(DBG_ROUTE,"Slackers:doProcessing().\n");

/* some dummy code */
    dataPtr = call Send.getBuffer(&msg1,&dlen);
    for(i=0;i<dlen;i++)
    {
	/* fill data buffer with data ! */
    }
/* end dummy code */

    /* puts message on sendQueue and sends */
    message->seqno = counter;
    call Send.send(&msg1,0);

   // call ADC.getData();

    return;
  }


  /* message sent */
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {

    if (msg != &msg1)
        return SUCCESS;
    if (success == FAIL)
        return FAIL;

    // get ith data sample
    // call ADC.getData();
    
    dbg(DBG_ROUTE, "Slackers: Send done for message at 0x%x.\n", msg);
    counter++;
    return SUCCESS;
  }

 /* OK to do processing
  */
 event void ActiveNotify.activated() {

    //call ADCControl.start();

    // send ith - 1 sample
    if (counter < MAX_CHIRPS)
    {
    	post doProcessing();
    }
    return;
  }

  /* Called when we are the end-point destination */
  event TOS_MsgPtr Receive.receive(TOS_MsgPtr msg, void* payload, 
		uint16_t payloadLen) { return msg; }

  /* do not do work now */
  event void ActiveNotify.deactivated() {
    return;
  }


//  event result dataReady(uint_t data) {
//    return SUCCESS;
//  } 

}

