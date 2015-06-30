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
 */

module MultiHopRoute {
  
  provides {
    interface StdControl as Control;
  }

  uses {
    interface PowerModeRoute as PowerMode; 
    interface StdControl as SubControl;
    interface Send as Send;
    interface ReceiveMsg as ReceiveMsg;
    interface SlackerQ as Queue;
  }
}
implementation {

  SlackerQueue receiveQueue;
  SlackerQueue *freeList;
  TOS_Msg storage;
  TOS_MsgPtr buffer;
  TOS_MsgPtr schedPtr;

  powermode theMode;
  uint8_t theState;
  int slot_i;


  /* NidoHack */
  TOS_Msg msg1;
  bool dumfirsttime;
  int dumdata_slot;
  void dummyMsg() ;
  
  command result_t Control.init() {
//    TOSH_MAKE_BOOST_ENABLE_OUTPUT();
//    TOSH_CLR_BOOST_ENABLE_PIN();
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Initialized.\n");
    buffer = (TOS_MsgPtr)&storage;
    freeList = &receiveQueue;
    call Queue.init(freeList, TRUE);

    if (NidoHack && DummyDemand)
	dummyMsg();

    return call SubControl.init();
  }
  
  command result_t Control.start() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Started.\n");
    return call SubControl.start();
  }
  
  command result_t Control.stop() {
    dbg(DBG_BOOT|DBG_ROUTE, "MultiHopRoute: Stopped.\n");
    return call SubControl.stop();
  }

 /*
  * ReceiveMsg.receive
  *
  * - receive an IvyMsg from downstream
  * - increment hop count
  * - forward the message
  * - return a free buffeer from the freeList
  *
  * TODO: If msg not received after X cycles,
  *	then recycle RECEIVE slot and decrement demand.
  */
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    TOS_MsgPtr rBuf;

    IvyMsg *message = (IvyMsg *) m->data;

    dbg(DBG_ROUTE, "MultiHopRoute: Received a packet.\n");

    /* ignore messages from self */
    if ( (message->mymote_id == (uint16_t) TOS_LOCAL_ADDRESS) &&
       (message->myapp_id == (uint16_t) IVY_NETID) )
        return m;

    /* return a buffer from the freeList... */
    rBuf = call Queue.dequeue(freeList);
    if (rBuf == NULL)
	return m;

    if (message->hop_count == 1)
    {
	message->myapp_id = IVY_NETID;
    	message->mymote_id = TOS_LOCAL_ADDRESS;
    }
    message->hop_count++;
    call Send.send(m,sizeof(IvyMsg));

    return rBuf;
  }

  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {

     /* we will reuse our power schedule buffer */
     if ( NidoHack && Monitor && (msg == schedPtr) )
     {
	schedPtr = 0;
    	dbg(DBG_ROUTE, "MultiHopRoute::sendDone got power schedule message back.\n");
	return SUCCESS;
     }

     /* we will reuse our dummy message */
     if ( NidoHack && DummyDemand && (msg == &msg1) )
     {
    	dbg(DBG_ROUTE, "MultiHopRoute::sendDone got dummy message back.\n");
	return SUCCESS;
     }

    /* return msg to the freeList...*/
    call Queue.enqueue(freeList,msg);

    return SUCCESS;
  }
  
  /*
   * NOTE IN PROGRESS
   * Currently not used or called.
   *
   */
  event void PowerMode.messageNotify(powermode powerMode, 
				uint8_t slotState, int s) {
    theMode = powerMode;
    theState = slotState;
    slot_i = s;

   /* here we get a message from our pretend application mote 
    * and forward it */
   if (NidoHack && DummyDemand && (theState == RECEIVE) )
   {
	if (dumfirsttime) {
	    dumdata_slot = slot_i;
	    dumfirsttime = FALSE;
	}
        dbg(DBG_ROUTE, "MultiHopRoute: Generate a packet.\n");
      	if (dumdata_slot == slot_i)
    	    call Send.send(&msg1,sizeof(IvyMsg));
   }

    return;
  }  


  /* Here we are notified to send our power schedule */
  event void PowerMode.scheduleNotify(TOS_MsgPtr sched, uint16_t len) {
    dbg(DBG_ROUTE, "MultiHopRoute:scheduleNotify().\n");
    schedPtr = sched;
    call Send.send(sched,len);
    return;
  } 

  /* NidoHack
   * make a dummy msg to send
   * upstream 
   */
  void dummyMsg() {

    int hops;
    IvyMsg *message = (IvyMsg *) msg1.data;

    dumfirsttime = TRUE;
    dumdata_slot = -1;
    switch(TOS_LOCAL_ADDRESS)
    {
	case IVY_BASE_STATION_ADDR:
            hops = 0;
            break;
        case 1:
        case 2:
            hops = 1;
            break;
        case 3:
        case 4:
        case 5:
        case 6:
            hops = 2;
            break;
        default:
            hops = 3;

    }

    memset(msg1.data,0,DATA_LENGTH);
    message->myapp_id = (uint16_t) IVY_NETID;
    message->mymote_id = (uint16_t) TOS_LOCAL_ADDRESS;
    message->app_id = (uint16_t) IVY_APPID;
    message->mote_id = (uint16_t) TOS_LOCAL_ADDRESS;
    message->hop_count = (uint8_t) hops;


    return;
  }
}
