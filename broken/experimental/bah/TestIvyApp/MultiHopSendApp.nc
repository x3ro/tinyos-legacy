/*									tab:4
 *
 *
 * "Copyright (c) 2002-2004 The Regents of the University  of California.  
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
 *
 * Author:	Barbara Hohlt
 * Project:	Ivy 
 *
 *
 * This is the MultiHopSend implementation for
 * the an Ivy Application mote.
 */

module MultiHopSendApp {
 
  
  provides {
    interface StdControl as Control;
    interface Send as Send;
    interface ActiveNotify;
  }

  uses {

    interface StdControl as SubControl;
    interface StdControl as CommControl;
    interface PowerModeSendApp as PowerMode; 
    interface Leds;
    interface SendMsg as SendMsg;
    interface SlackerQ as Queue;
  }
}
implementation {

  uint8_t theState;
  int slot_i;
  uint16_t parent;
  
  SlackerQueue fifoQueue; 
  SlackerQueue *sendQueue; 

  void radioOn();
  void radioOff();


  void radioOff(){

    /* Turn radio off here */
    
    call PowerMode.setRadioModeOff();
    signal ActiveNotify.deactivated(); 

    if (PowerMgntOn)
      call CommControl.stop();

    return;
  }

  void radioOn() {
    /* Turn radio on here */

    if (PowerMgntOn)
      call CommControl.start();
    signal ActiveNotify.activated();

    return;
  }

  void sendComplete(TOS_MsgPtr msg, result_t success) {
    if ( SendLeds )
      	call Leds.redOff();

    signal Send.sendDone(msg, success);
    radioOff();

    return;
  }

  /*
   *
   * Get next message from sendQueue
   * and forward
   */
  task void forwardNext() {
    TOS_MsgPtr sMsg;

    dbg(DBG_ROUTE, "MultiHopSend:forwardNext().\n");
    sMsg = call Queue.dequeue(sendQueue);
    if (sMsg == NULL)
    {
        dbg(DBG_ROUTE, "MultiHopSend: no messages to send.\n");
	return;
    }

    if ( call SendMsg.send(parent,sizeof(IvyMsg),sMsg)) {
	if (SendLeds)
    	    call Leds.redOn();
        dbg(DBG_ROUTE, "MultiHopSend:forwardNext() succeeded.\n");

    } else { 
    	dbg(DBG_ROUTE, "MultiHopSend:forwardNext() failed.\n");
	sendComplete(sMsg,FAIL);
    }


    return ;
  }

  command result_t Control.init() {

    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Initialized.\n");

    parent = 0;
    sendQueue = &fifoQueue;
    call Queue.init(sendQueue, FALSE);

    call Leds.init();

    call CommControl.init();
    call SubControl.init();

    return SUCCESS;
  }
  
  command result_t Control.start() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Started.\n");
        signal ActiveNotify.activated();
    	call CommControl.start();
	return call SubControl.start();
  }
  
  command result_t Control.stop() {
        dbg(DBG_BOOT|DBG_ROUTE, "MultiHopSend: Stopped.\n");
    	call CommControl.stop();
	return call SubControl.stop();
  }

  /*
   *  getBuffer 
   * 
   *  - initialize an IvyMsg 
   *  - return sizeof Ivy data buffer 
   *  - return pointer to IvyMsg data buffer 
   * 
   */ 
  command void* Send.getBuffer(TOS_MsgPtr msg, uint16_t* len) {
    IvyMsg *message = (IvyMsg *) msg->data;

    dbg(DBG_ROUTE, "MultiHopSend: getBuffer on message at 0x%x.\n", msg);

    memset(msg,0,DATA_LENGTH);

    message->myapp_id = IVY_APPID;
    message->mymote_id = TOS_LOCAL_ADDRESS;
    message->app_id = IVY_APPID;
    message->mote_id = TOS_LOCAL_ADDRESS;
    message->hop_count = 1;

    *len = IVY_DATA_LEN;
    return (void*)message->data;
  }

  command result_t Send.send(TOS_MsgPtr msg, uint16_t len) {
    result_t rval;

    dbg(DBG_ROUTE, "MultiHopSend: Forward on message at 0x%x.\n", msg);

    /* put message on sendQueue ... */
    rval = call Queue.enqueue(sendQueue,msg);

    return rval;
  }

  default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    return FAIL;
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) 
  {

      sendComplete(msg, success);

      return SUCCESS;
  }

  event void PowerMode.modeNotify(uint16_t theParent, 
			uint8_t slotState, int s) {
    parent = theParent; 
    theState = slotState;
    slot_i = s;

    dbg(DBG_ROUTE, "MultiHopSend:modeNotify: Slot[%d] state = %d \n", slot_i,theState );
    if ( theState == TRANSMIT )
    	post forwardNext();

    return;
  }

  event void PowerMode.radioOnNotify() {
    radioOn();
 
    return;
  } 

  default void event ActiveNotify.activated() {return;}
  default void event ActiveNotify.deactivated() {return;}

}
