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

//Hongwei
#ifndef DeadThreshold
#define DeadThreshold 3
#endif

module TestRoutingM 
{
  provides{
	interface StdControl;
  }
  uses{
	interface Leds;
	interface Routing;
	interface StdControl as RoutingControl;
	interface Timer;

	interface StdControl as UARTControl;
	interface SendMsg as UARTSend;    
 
	//hongwei
   	interface Xnp;
  }
}

implementation
{

  TOS_Msg inMsgBuf, outMsgBuf;

  int8_t pending;
  uint16_t tick;
  uint8_t count;

  //Hongwei:
  uint16_t pendingDeadCount;

  command result_t StdControl.init(){
    pending = FALSE;
	tick = 0;
	count = 0;

	//Hongwei:
	pendingDeadCount = 0;

    return rcombine3(call RoutingControl.init(), call Xnp.NPX_SET_IDS(), call UARTControl.init());
  }

  command result_t StdControl.start(){
  	result_t ok1, ok2, ok3;
	ok1 = call RoutingControl.start();
	ok2 = call Timer.start(TIMER_REPEAT,1000);
	ok3 = call UARTControl.start();

	return rcombine3(ok1,ok2,ok3);
  }

  command result_t StdControl.stop(){
  	result_t ok1, ok2, ok3;
	ok1 = call RoutingControl.stop();
	ok2 = call Timer.stop();
	ok3 = call UARTControl.stop();

	return rcombine3(ok1,ok2,ok3);
  }

  event result_t Timer.fired(){
    AppMsg *msg = (AppMsg *)(outMsgBuf.data+HEADER_LEN);

	tick++;

	if(TOS_LOCAL_ADDRESS != 0 && ( tick%30 == 0)){
		// generate random messages to send
		msg->src = TOS_LOCAL_ADDRESS;
		msg->count = count;

		if(!pending){
			pending = TRUE;
  			if(call Routing.send(&outMsgBuf)){
				//call Leds.redToggle();
				dbg(DBG_USR2, "TestRouting sends msg (count %d)\n", msg->count);
			}
			else pending = FALSE;
		}
		else { //Hongwei:
		  	pendingDeadCount++;
			if (pendingDeadCount > DeadThreshold)
				pending = FALSE;
		}
	}

  	return SUCCESS;
  }

  event result_t Routing.sendDone(TOS_MsgPtr pmsg, result_t success)
  {
	if(success == SUCCESS){
		count++;
	}

		pending = FALSE;

  	return success;
  }

  event TOS_MsgPtr Routing.receive(TOS_MsgPtr pmsg)
  {
        AppMsg *msg = (AppMsg *)(pmsg->data+HEADER_LEN);
      	struct ReportedMsg *cmsg = (struct ReportedMsg *)(outMsgBuf.data);

	if(TOS_LOCAL_ADDRESS != 0){
	}
	else{
		cmsg->src = msg->src;
		cmsg->count = msg->count;
		cmsg->type = msg->type;
		cmsg->time = msg->time;
   		outMsgBuf.addr = TOS_UART_ADDR;

		if(!pending){
			pending = TRUE;
			if(call UARTSend.send(TOS_UART_ADDR, sizeof(struct ReportedMsg),&outMsgBuf)){
				//call Leds.redToggle();
			}
			else {
				pending = FALSE;
			}
		}
        else { //Hongwei:
			pendingDeadCount++;
			if (pendingDeadCount > DeadThreshold)
				pending = FALSE;
		}
	}

  	return pmsg;
  }

  event result_t UARTSend.sendDone(TOS_MsgPtr pmsg, result_t success)
  {
		pending = FALSE;

  	return success;
  }

  //Hongwei
  event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP){
    return call Xnp.NPX_DOWNLOAD_ACK(SUCCESS);
  }

  event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet, uint16_t wEENofP){
    return SUCCESS;
  }

}
