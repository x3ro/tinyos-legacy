/**
 * Copyright (c) 2003 - The University of Texas at Austin and
 *                      The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE
 * UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
 * INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS
 * SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS AT AUSTIN
 * AND THE OHIO STATE UNIVERSITY HAVE BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY
 * SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

/*
 *  Author/Contact: Young-ri Choi
 *                  yrchoi@cs.utexas.edu
 *
 *  This implementation is based on the design 
 *  by Mohamed G. Gouda, Young-ri Choi, Anish Arora and Vinayak Naik.
 *
 */

includes GridTreeMsg;
includes ReliableCommMsg;

module GridRoutingM
{
  uses{
  	interface StdControl as CommControl;
	interface ReliableSendMsg;
	interface ReliableReceiveMsg;
	interface GridInfo;
	interface CC1000Control;
  }
  provides{
  	interface Routing;
	interface StdControl;
  }
}
implementation
{
  command result_t StdControl.init() {
  	return call CommControl.init();
  }

  command result_t StdControl.start() {
  	call CommControl.start();
	return call CC1000Control.SetRFPower(12);
  }

  command result_t StdControl.stop() {
  	return call CommControl.stop();
  }

  result_t genSendDone(TOS_MsgPtr msg, result_t success){
	signal Routing.sendDone(msg, success);
	return success;
  }


/* forward a msg received from ReliableReceiveMsg */
  result_t sendForward(TOS_MsgPtr pmsg, uint16_t fromAddr, uint8_t fromQueuePos){
	RouteMsg *msg = (RouteMsg *)pmsg->data;
    gpoint id = call GridInfo.getParent();
	uint16_t addr;

	if(!(id.x==0xff && id.y==0xff)){ // if I have a parent!
		// next dst ID
		msg->dst.x = id.x;
		msg->dst.y = id.y;

		addr = call GridInfo.getIDtoAddress(id);

  		if(call ReliableSendMsg.send(addr, sizeof(RouteMsg), pmsg, fromAddr,fromQueuePos)){
			dbg(DBG_USR3, "Routing: forward msg to address %d\n", addr);
			return SUCCESS;
		}
		else{
			return FAIL;
		}
	}
	else{	// if I don't have a parent!
		return FAIL;
	}
}

/* send a msg generated in local */
  result_t sendLocal(TOS_MsgPtr pmsg){

	RouteMsg *msg = (RouteMsg *)pmsg->data;
    gpoint id = call GridInfo.getParent();
	uint16_t addr;

	if(!(id.x==0xff && id.y==0xff)){ // if I have a parent!
		// next dst ID
		msg->dst.x = id.x;
		msg->dst.y = id.y;

		addr = call GridInfo.getIDtoAddress(id);

  		if(call ReliableSendMsg.send(addr, sizeof(RouteMsg), pmsg, TOS_LOCAL_ADDRESS, 0)){
			dbg(DBG_USR3, "Routing: send msg to address %d\n", addr);
			return SUCCESS;
		}
		else{
			genSendDone(pmsg,FAIL);
			return FAIL;
		}
	}
	else{	// if I don't have a parent!
		genSendDone(pmsg,FAIL);
		return FAIL;
	}
  }

  command result_t Routing.send(TOS_MsgPtr pmsg){
	return sendLocal(pmsg);
  }

  result_t sendDone(TOS_MsgPtr pmsg, result_t success){
  	
	uint16_t frAddr;

	frAddr = (uint16_t)pmsg->data[sizeof(RouteMsg)+FromAddrPos];
	frAddr = frAddr << 8;
	frAddr = frAddr | ((uint16_t)pmsg->data[sizeof(RouteMsg)+FromAddrPos+1]);

	if(frAddr == TOS_LOCAL_ADDRESS)	{	// sendDone for local send
		dbg(DBG_USR3, "sendDone of local\n");
    	return signal Routing.sendDone(pmsg, success);
	}
	else {	// sendDone for forward send
		dbg(DBG_USR3, "sendDone of forward\n");
		return success;
	}

  }

  event result_t ReliableSendMsg.sendDone(TOS_MsgPtr pmsg, result_t success) {
	return sendDone(pmsg, success);
  }

  event TOS_MsgPtr ReliableReceiveMsg.receive(TOS_MsgPtr pmsg, uint16_t fromAddr, uint8_t fromQueuePos)
  {
	RouteMsg *msg = (RouteMsg *)pmsg->data;
    gpoint myID = call GridInfo.getMyID();

	// If I am a base station (and I am the dst),
	// then signal to upper layer!
	if((myID.x == 0 && myID.y== 0)	
	  && (myID.x == msg->dst.x && myID.y == msg->dst.y))
  		return signal Routing.receive(pmsg);

	// if I am the destination, then forward the msg to my parent
	if(myID.x == msg->dst.x && myID.y == msg->dst.y){
		sendForward(pmsg, fromAddr, fromQueuePos);
		return pmsg;

	}
	// if I am not the dst, ignore!
	else
		return pmsg;

  }
}
