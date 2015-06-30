/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 * Enhanced version for finer controls
 *
 * Authors: Lin Gu
 * Date: 6/18/2003
 */

//This is an AM messaging layer implementation that understands multiple
// output devices.  All packets addressed to TOS_UART_ADDR are sent to the UART
// instead of the radio.

includes sensorboard;
// includes avrhardware;

module AMEnhanced
{
  provides {
    interface StdControl as Control;
    
    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    // How many packets were received in the past second
    command uint16_t activity();
  }

  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();

    interface StdControl as UARTControl;
    interface BareSendMsg as UARTSend;
    interface ReceiveMsg as UARTReceive;

    interface StdControl as RadioControl;
    interface BareSendMsg as RadioSend;
    interface ReceiveMsg as RadioReceive;
    interface Leds; 
    interface StdControl as TimerControl;
    interface Timer as ActivityTimer;
    interface PowerManagement;
    interface RadarSwitch;
  }
}
implementation
{
#include "NetworkControlMessages.h"
#include "PktDef.h"
#include "ProgCommMsg.h"
#include "sensorboard.h"
  // #include "avrhardware.h"

#define AM_CONTROL_RELAY_INTERVAL 200

  typedef enum {
    DL_IDLE = 0,
    DL_DISABLING,
    DL_DISABLED = 2,
    DL_ENABLING,
    DL_BUSY = 4,
  } DataLinkState; // change the state boolean to a state set --lin

  TOS_MsgPtr buffer;
  uint16_t lastCount;
  uint16_t counter;
  DataLinkState dlsAm;
  int nWait;
  TOS_Msg msgControl;
  bool bReprogrammable;

  // Initialization of this component
  command bool Control.init() {
    result_t ok1, ok2;

    atomic 
      {
	call TimerControl.init();
	ok1 = call UARTControl.init();
	ok2 = call RadioControl.init();
	dlsAm = DL_IDLE;
	lastCount = 0;
	counter = 0;
	nWait = -121;
	bReprogrammable = TRUE;

	dbg(DBG_BOOT, "AM Module initialized\n");
      }

    return rcombine(ok1, ok2);
  }

  // Command to be used for power managment
  command bool Control.start() {
   
    result_t ok0,ok1,ok2,ok3;
   
    ok0 = call TimerControl.start();
    ok1 = call UARTControl.start();
    ok2 = call RadioControl.start();
    ok3 = SUCCESS; // stop using activity timer for statistics --lin
    // -- lin ok3 = call ActivityTimer.start(TIMER_REPEAT, 1000);

    //HACK -- unset start here to work around possible lost calls to 
    // sendDone which seem to occur when using power management.  SRM 4.4.03
    atomic {
      dlsAm = DL_IDLE;
    }

    call PowerManagement.adjustPower();

    return rcombine4(ok0, ok1, ok2, ok3);
  }

  
  command bool Control.stop() {
    result_t ok1 = call UARTControl.stop();
    result_t ok2 = call RadioControl.stop();
    result_t ok3 = call ActivityTimer.stop();
    // call TimerControl.stop();
    call PowerManagement.adjustPower();
    return rcombine3(ok1, ok2, ok3);
  }

  command uint16_t activity() {
    return lastCount;
  }

  /* Shall this node react to the control packet? */
  inline bool controlHit(ControlPkt *pcp)
    {
      if ((TOS_LOCAL_ADDRESS >= pcp->maStart1 && TOS_LOCAL_ADDRESS <= pcp->maEnd1) ||
	  (TOS_LOCAL_ADDRESS >= pcp->maStart2 && TOS_LOCAL_ADDRESS <= pcp->maEnd2) ||
	  (TOS_LOCAL_ADDRESS >= pcp->maStart3 && TOS_LOCAL_ADDRESS <= pcp->maEnd3) ||
	  (TOS_LOCAL_ADDRESS >= pcp->maStart4 && TOS_LOCAL_ADDRESS <= pcp->maEnd4))
	return TRUE;
      else
	return FALSE;
    } // controlHit

  void dbgPacket(TOS_MsgPtr data) {
    uint8_t i;

    for(i = 0; i < sizeof(TOS_Msg); i++)
      {
	dbg_clear(DBG_AM, "%02hhx ", ((uint8_t *)data)[i]);
      }
    dbg(DBG_AM, "\n");
  }

  // Handle the event of the completion of a message transmission
  result_t reportSendDone(TOS_MsgPtr msg, result_t success) {
    atomic 
      {
	if (dlsAm == DL_BUSY)
	  {
	    dlsAm = DL_IDLE;
	  }
      } 
    // atomic

    signal SendMsg.sendDone[msg->type](msg, success);
    signal sendDone();

    return SUCCESS;
  }

  // This task schedules the transmission of the conrol message
  task void controlPktTask() {
    result_t ok;
    TOS_MsgPtr buf;

    atomic
      {
	buf = &msgControl;
      }

    dbg(DBG_AM, "AM:controlPktTask: sending\n");
    dbgPacket(buf);

    ok = call RadioSend.send(buf);

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buf, FAIL);
  } // controlPkgTask

int helpfunc(int *pa)
{
	*pa = TOS_LOCAL_ADDRESS;
	*pa++;
	return *pa;
}
  event result_t ActivityTimer.fired() {
    switch (dlsAm)
      {
      case DL_IDLE:
      case DL_BUSY:
	lastCount = counter;
	counter = 0;
	return SUCCESS;
	break;

      case DL_DISABLING:
      case DL_DISABLED:
	if (nWait > -121)
	  {
	    if (nWait<=0)
	      {
		/* time out (or got the precedent's message). Should
		   send out the control message. */

		switch(nWait)
		  {
		  case 0:
		    post controlPktTask();
		    TOSH_SET_YELLOW_LED_PIN();
		    break;

		  case -20:
		    post controlPktTask();
		    break;

		  case -40:
		  case -60:
		  case -80:
		  case -100:
		    post controlPktTask();
		    break;
		    
		  case -115:
		    // TOSH_SET_SOUNDER_CTL_PIN();
		    break;

		  case -120:
		    post controlPktTask();
		    // turn on sounder		    
		    // TOSH_CLR_SOUNDER_CTL_PIN();
		    break;
		    
		  default:
		    ;
		  } // switch
	      } // if nWait <= 0

	    nWait--;
	  } // if nWait > -121
	else
	  {
	    call ActivityTimer.stop();
	    if (!bReprogrammable)
	      {
	        // halt
                long l;
		cli();
	        TOSH_CLR_RED_LED_PIN();
	  	TOSH_CLR_YELLOW_LED_PIN();
	 	TOSH_CLR_GREEN_LED_PIN();
		for (l=0;l<100000;l=l)
		  {
		    volatile int a;
		    a= 3;
		a = helpfunc((int *)(&a));
		    dbg(DBG_AM, "halt...%ld\n", a);
		  } // for
	      } // if reprogrammable
	  } // else nWait > -121

	return SUCCESS;

	break;

      default:
	;
      } // switch
  }
  
  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
  default event result_t sendDone() {
    return SUCCESS;
  }

  // This task schedules the transmission of the Active Message
  task void sendTask() {
    result_t ok;
    TOS_MsgPtr buf;

    atomic
      {
	buf = buffer;
      }

    dbg(DBG_AM, "AM:sendTask: sending\n");
    dbgPacket(buf);

    if (buf->addr == TOS_UART_ADDR)
      ok = call UARTSend.send(buf);
    else
      {
	call RadarSwitch.pause();
	ok = call RadioSend.send(buf);
      }

    if (ok == FAIL) // failed, signal completion immediately
      reportSendDone(buf, FAIL);
  }

  result_t copyControlPkt(TOS_MsgPtr pmsgSrc)
    {
      ControlPkt *pcpSrc = (ControlPkt *)(pmsgSrc->data), 
	*pcpDest = (ControlPkt *)(msgControl.data);

      msgControl.length = pmsgSrc->length;
      msgControl.addr = pmsgSrc->addr;
      msgControl.type = pmsgSrc->type;
      msgControl.group = pmsgSrc->group;
      pcpDest->maStart1 = pcpSrc->maStart1;
      pcpDest->maStart2 = pcpSrc->maStart2;
      pcpDest->maStart3 = pcpSrc->maStart3;
      pcpDest->maStart4 = pcpSrc->maStart4;
      pcpDest->maEnd1 = pcpSrc->maEnd1;
      pcpDest->maEnd2 = pcpSrc->maEnd2;
      pcpDest->maEnd3 = pcpSrc->maEnd3;
      pcpDest->maEnd4 = pcpSrc->maEnd4;
      pcpDest->maSender = TOS_LOCAL_ADDRESS;
      pcpDest->nOp = pcpSrc->nOp;
      // pcpSrc->nLength is not used

      return SUCCESS;
    } // copyControlPkt

  result_t doNetControl(uint8_t type, TOS_MsgPtr data) {
    /* Control packet --lin
       There could be many ways of using control packets.
       At present the following are implemented:
       * disable_upper_portion
       * enable_upper_portion
       /////// overall the state machine needs to be better
       implemented. The flow needs to be considered more carefully
       and synchronization needs to be added.
    */

    ControlPkt *pcp = (ControlPkt *)(data->data);
    
    dbg(DBG_AM, "AMEnhanced: doNetControl for %x\n", data->addr);

	switch (pcp->nOp)
	  {
	  case NC_DISABLE_UPPER_PORTION:
	  case NC_DISABLE4:
	    if (dlsAm == DL_IDLE || dlsAm == DL_BUSY)
	      {
		dlsAm = DL_DISABLED; // we should not need DL_DISABLING --lin
		dbg(DBG_AM, "AM: Disabled\n");
		TOSH_CLR_YELLOW_LED_PIN();
		TOSH_CLR_RED_LED_PIN();
	      }

	    if (pcp->maSender <= TOS_LOCAL_ADDRESS)
	      {
		if (controlHit(pcp))
		  {
		    bReprogrammable = FALSE;
		    TOSH_CLR_YELLOW_LED_PIN();
		    TOSH_CLR_RED_LED_PIN();
		  }

		nWait = TOS_LOCAL_ADDRESS - pcp->maSender;
		call ActivityTimer.stop();
		copyControlPkt(data);
		call ActivityTimer.start(TIMER_REPEAT, 
					 AM_CONTROL_RELAY_INTERVAL);
		TOSH_CLR_YELLOW_LED_PIN();
	      }
	      
	    break;
	    /*
	  case NC_ENABLE_UPPER_PORTION:
	    if (dlsAm == DL_DISABLED || dlsAm == DL_DISABLING)
	      {
		dlsAm = DL_IDLE;
	      }
	    break;
	    */ // right now do not enable ///////
	  default:
	    ;
	  } // switch

    return SUCCESS;
  } // doNetControl

#define IS_REPROG_MSG(id) \
  (id == AM_READFRAG || \
   id == AM_WRITEFRAG || \
   id == AM_NEWPROG || \
   id == AM_STARTPROG || \
   id == AM_FRAGMENTREQUESTMSG || \
   id == AM_PROGFRAGMENTMSG || \
   id == AM_NEWPROGRAMANNOUNCEMSG || \
   id == AM_STARTPROGRAMMSG)

    // Command to accept transmission of an Active Message
    /* Here the AMStandard's logic, using 'state' and 'oldstate', is 
       again unreliable. In the scenario of
       send, send_done, interrupt (such as a sensor reading)->some event, send,
       2 outstanding packets will be there. But I hesitate to fix it now. 
       --lin */

    command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, TOS_MsgPtr data) {
    // add control facility --lin

      dbg(DBG_AM, "AMEnhanced:send: dlsAm: %x\n", dlsAm);

    if (dlsAm == DL_DISABLING)
      {
	dlsAm = DL_DISABLED;
	dbg(DBG_AM, "AM: Disabled\n");
		TOSH_CLR_YELLOW_LED_PIN();
		TOSH_CLR_RED_LED_PIN();
      }

    if (id == MSG_CONTROL)
      {
	/* control message still needs to be sent. But the localhost
	   peeks at the message to do the control */
	data->length = length;
	data->type = id;
	data->addr = TOS_BCAST_ADDR;
	data->group = TOS_AM_GROUP;
	doNetControl(id, data);

	return SUCCESS;
      }

    if (dlsAm == DL_DISABLING || 
	dlsAm == DL_IDLE || 
	(bReprogrammable && IS_REPROG_MSG(id))) 
      {
	if (dlsAm == DL_DISABLING)
	  {
	    dlsAm = DL_DISABLED;
	    dbg(DBG_AM, "AM: Disabled\n");
		TOSH_CLR_YELLOW_LED_PIN();
		TOSH_CLR_RED_LED_PIN();
	  }

	if (length > DATA_LENGTH) {
	  dbg(DBG_AM, "AM: Send length too long: %i. Fail.\n", (int)length);
	  return FAIL;
	}
	if (!(post sendTask())) {
	  dbg(DBG_AM, "AM: post sendTask failed.\n");
	  return FAIL;
	}
	else 
	  dlsAm = (dlsAm == DL_IDLE) ? DL_BUSY : dlsAm;

	buffer = data;
	data->length = length;
	data->addr = addr;
	data->type = id;
	buffer->group = TOS_AM_GROUP;
	dbg(DBG_AM, "Sending message: %hx, %hhx\n\t", addr, id);
	// dbgPacket(data);
	return SUCCESS;
      }
    else
      {
	dbg(DBG_AM, "AMEnhanced: messaage abandoned\n");
      }
    
    return FAIL;
    }

  event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
    return reportSendDone(msg, success);
  }
  event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
    call RadarSwitch.resume();

    return reportSendDone(msg, success);
  }

  result_t procReceivedControlPkt(TOS_MsgPtr packet)
    {
      /* If there is a control packet pending, just accelerate
	 it. Otherwise, schedule to forward the control packet. */
      ControlPkt *pcp = (ControlPkt *)(packet->data);
      int nDistance = (int)(TOS_LOCAL_ADDRESS - pcp->maSender);
		
      if (nDistance>0)
	{
	  if (nWait > nDistance)
	    {
	      nWait = nDistance;
	    }
	  else
	    {
	      if (nWait <= -121)
		{
		  // no pending control packets
		  doNetControl(packet->type, packet);
		} // if nWait < 0
	    } // else nWait > nDistance
	} // if nDistance > 0
      else
	{
	  dlsAm = DL_DISABLED;
		TOSH_CLR_YELLOW_LED_PIN();
		TOSH_CLR_RED_LED_PIN();
	} // else nDistance > 0
	
	return SUCCESS;
    } // procReceivedPkt

  // Handle the event of the reception of an incoming message
  TOS_MsgPtr received(TOS_MsgPtr packet)  __attribute__ ((C, spontaneous)) {
    uint16_t addr = TOS_LOCAL_ADDRESS;

    /* process control packets */
    if (packet->type == MSG_CONTROL)
      {
	procReceivedControlPkt(packet);
	return packet;
      }

    if (dlsAm == DL_DISABLED &&
	!(bReprogrammable && IS_REPROG_MSG(packet->type)))
      {
      return packet;
      }

    counter++;
    dbg(DBG_AM, "AM_address = %hx, %hhx; counter:%i\n", packet->addr, packet->type, (int)counter);

    if (//packet->crc == 1 && // Uncomment this line to check crcs
	packet->group == TOS_AM_GROUP &&
	(packet->addr == TOS_BCAST_ADDR ||
	 packet->addr == addr))
      {
	uint8_t type = packet->type;
	TOS_MsgPtr tmp;
    
	// Debugging output
	dbg(DBG_AM, "Received message:\n\t");
	dbgPacket(packet);
	dbg(DBG_AM, "AM_type = %d\n", type);

	// process network control messages
	if (type == MSG_CONTROL)
	  {
	  }

	// dispatch message
	tmp = signal ReceiveMsg.receive[type](packet);
	if (tmp) 
	  packet = tmp;
      }
    return packet;
  }

  // default do-nothing message receive handler
  default event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) {
    return msg;
  }

  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr packet) {
    return received(packet);
  }
  event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr packet) {
    return received(packet);
  }
}

