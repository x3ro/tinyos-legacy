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
 *	Test Application using QueuedASend 
 *
 *	A trivial application to demonstrate the use of
 *	QueuedASend for buffer management and forward queueing
 *	in the MultiHop component.  
 *
 *	Every APPLICATION_NOTIFY ms the SchedulePolicy component sends an 
 *	ActiveNotify event indicating the application can send one message. 
 * 
 *	If sampling sensor data, the idea is to send 
 *	the ith - 1 sample when the ActiveNotify event is
 *	received and then take the next sample.
 *
 *
 * Author:	Barbara Hohlt
 * Project:	MultiHop QueuedASend	
 *
 **/

module TestMHQASendM {

  provides interface StdControl as Control;
  uses {
	interface AllocSend as Send; 
	interface Receive;
	interface ActiveNotify;
	//interface StdControl as ADCControl;
	//interface ADC;
  }
}
implementation
{
  TOS_MsgPtr msg1;
  TOS_MsgPtr tmp1;
  int16_t counter;
  int16_t sent;
  enum {
    MAX_CHIRPS = 10
  };

  command result_t Control.init() {

    //call ADCControl.init();
    return SUCCESS; 
  }
 
  command result_t Control.start() {
    counter = 0;
    sent = 0;
    return SUCCESS; 
  } 

  command result_t Control.stop() {
    return SUCCESS;
  } 

  task void doProcessing() {

    TOS_MHopMsg *message;
    uint16_t len;

    dbg(DBG_ROUTE,"TestBufferMgnt:doProcessing().\n");

    /* get a free buffer */
    msg1 = NULL;
    msg1 = call Send.allocBuffer();
    if (msg1 == NULL) {
      dbg(DBG_ROUTE, "TestBufferMgnt: freeList empty.\n");
      return;
    }
    call Send.getBuffer(msg1,&len);

    message = (TOS_MHopMsg *) msg1->data;
    message->seqno = counter;

    /* put message on sendQueue and sends */
    call Send.send(msg1,len);
    sent++;
    tmp1 = msg1;

   // call ADC.getData();

    return;
  }


  /* message sent */
  /* WARNING: The msg buffer has been put on the freeList !!! */ 
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {

    if ((msg != tmp1) || (success != 1))
    	return SUCCESS;
	
    // get ith data sample
    // call ADC.getData();
    
    counter++;
    dbg(DBG_ROUTE, "TestBufferMgnt: Send done for message %d sent %d at 0x%x. :%u\n",
counter, sent,msg,success );

    return SUCCESS;
  }

 /* OK to do processing
  */
 event void ActiveNotify.activated() {

    //call ADCControl.start();

    // send ith - 1 sample
    if (counter < (int16_t)MAX_CHIRPS)
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

