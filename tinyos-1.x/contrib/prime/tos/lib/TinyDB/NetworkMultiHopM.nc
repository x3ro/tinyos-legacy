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
 * Author:	Wei Hong
 *
 */


/* Routing component for TinyDB.  Can receive and send
   data and query messages.  Data messages are tuples
   or aggregate values.  Queries represent portions
   of queries being injected into the network.

   In the TAG world, query messages flood down the routing tree,
   and data messages are sent up the network (to the node's) parent
   towards the root.  Obviously, there are other routing mechanisms
   that might make sense,  but the routing system needs to be careful
   to do duplicate elimination -- which may be hard since this API
   doesn't export the contents of the data messages.

   The routing in this module will be based on the standard interfaces
   Send, Receive, Intercept and Bcast.
*/

includes TinyDB;
// includes TosTime; 
module NetworkMultiHopM {

  provides {
    interface Network;
    interface StdControl;
    interface NetworkMonitor;
  }

  uses {
    interface Send;
	interface Intercept;
	interface Intercept as Snoop;
	interface MultiHopMonitor;
	interface StdControl as MultiHopStdControl;
	interface MultiHopControl;
    interface SendMsg as SendQueryMsg;
    interface SendMsg as SendDataMsg;
    interface SendMsg as SendStatusMsg;
    interface SendMsg as SendQueryRequest;
    interface SendMsg as SendCommandMsg;

    interface ReceiveMsg as RcvQueryMsg;
#ifdef kQUERY_SHARING
    interface ReceiveMsg as RcvRequestMsg;
#endif
    interface ReceiveMsg as RcvCommandMsg;
#ifdef kSUPPORTS_EVENTS
    interface ReceiveMsg as RcvEventMsg;
    interface SendMsg as SendEventMsg;
#endif
#ifdef kSTATUS
    interface ReceiveMsg as RcvStatusMessage;
#endif

    interface CommandUse;
#ifdef kSUPPORTS_EVENTS
    interface EventUse;
#endif
#ifdef kSTATUS
	interface QueryProcessor;
#endif
    interface Leds;
	/*
    interface ReceiveMsg as RcvRTCTime;
    interface Time;
	*/
	interface QueueControl;
  }
}
implementation 
{
	TOS_Msg mDbg;
	bool mWasCommand;
	bool UARTBusy;

	command result_t StdControl.init() 
	{
		UARTBusy = FALSE;
		mWasCommand = FALSE;
		return call MultiHopStdControl.init();
	}

    command result_t StdControl.start() 
	{
		return call MultiHopStdControl.start();
    }
     
    command result_t StdControl.stop() 
	{
		return call MultiHopStdControl.stop();
    }

	command QueryResultPtr Network.getDataPayLoad(TOS_MsgPtr msg)
	{
		uint16_t len;
		return (QueryResultPtr)call Send.getBuffer(msg, &len);
	}

	command TinyDBError Network.sendDataMessage(TOS_MsgPtr msg) 
	{
		if (call Send.send(msg, sizeof(QueryResult)) == FAIL)
			return err_MessageSendFailed;
		call Leds.redToggle();
		return err_NoError;
	}

	event result_t Send.sendDone(TOS_MsgPtr msg, result_t success)
	{
		signal Network.sendDataDone(msg, success);
		return SUCCESS;
	}

	command QueryMessagePtr Network.getQueryPayLoad(TOS_MsgPtr msg)
	{
		return (QueryMessagePtr)msg->data;
	}

    command TinyDBError Network.sendQueryMessage(TOS_MsgPtr msg) 
	{
		if (call SendQueryMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg) == SUCCESS) 
		{
			call Leds.redToggle();
			return err_NoError;
		} 
		return err_MessageSendFailed;
    }

#ifdef kQUERY_SHARING
	command QueryRequestMessagePtr Network.getQueryRequestPayLoad(TOS_MsgPtr msg)
	{
		return (QueryRequestMessagePtr)msg->data;
	}

	command TinyDBError Network.sendQueryRequest(TOS_MsgPtr msg, uint16_t to)
	{
		if (call SendQueryRequest.send(to, kMSG_LEN, msg) == SUCCESS) 
		{
		   return err_NoError;
		}  
		return err_MessageSendFailed;
	}
#endif
     
	event result_t SendQueryMsg.sendDone(TOS_MsgPtr msg, result_t success) 
	{
		signal Network.sendQueryDone(msg, success);
		return SUCCESS;
	}

	event result_t SendCommandMsg.sendDone(TOS_MsgPtr msg, result_t success)
	{
		if (mWasCommand)
		{
			SchemaErrorNo errorNo;
			// XXX ignore command return value for now
			call CommandUse.invokeMsg(&mDbg, NULL, &errorNo);
			mWasCommand = FALSE;
		}
		return SUCCESS;
	}

#ifdef kSUPPORTS_EVENTS
	event result_t SendEventMsg.sendDone(TOS_MsgPtr msg, result_t success)
	{
		return SUCCESS;
	}
#endif

    event result_t SendQueryRequest.sendDone(TOS_MsgPtr msg, result_t success) 
	{
		signal Network.sendQueryRequestDone(msg, success);
		return SUCCESS;
    }

    event result_t SendDataMsg.sendDone(TOS_MsgPtr msg, result_t success) 
	{
		return SUCCESS;
	}

    event result_t SendStatusMsg.sendDone(TOS_MsgPtr msg, result_t success) 
	{
		return SUCCESS;
	}

    /* Event that's fired when a query message arrives */
	event TOS_MsgPtr RcvQueryMsg.receive(TOS_MsgPtr msg) 
	{
		QueryMessagePtr qMsg = call Network.getQueryPayLoad(msg);
		signal Network.querySub(qMsg);
		return msg;
    }

#ifdef kQUERY_SHARING
    /* Event thats fired when a request for a query arrives from a neighbor */
	event TOS_MsgPtr RcvRequestMsg.receive(TOS_MsgPtr msg) 
	{
		QueryRequestMessagePtr qreqMsg = call Network.getQueryRequestPayLoad(msg);
		signal Network.queryRequestSub(qreqMsg);
		return msg;
	}
#endif

	event result_t Intercept.intercept(TOS_MsgPtr msg, void* payload, uint16_t payloadLen) 
	{
		/* no cross node aggregation in this release of GSK */
		/* simply forward on */
		call Leds.greenToggle();
		return SUCCESS;
#if 0
		QueryResultPtr qr = (QueryResultPtr)payload;
		signal Network.dataSub(qr);
		return FAIL; // do not forward the message, TinyDB will resend
#endif
	}

	event result_t Snoop.intercept(TOS_MsgPtr msg, void* payload, uint16_t payloadLen)
	{
		QueryResultPtr qr = (QueryResultPtr)payload;
		uint16_t sender = call MultiHopControl.getSender(msg);
		bool isParent = call NetworkMonitor.getParent() == sender;
		if (call MultiHopControl.getParent() == TOS_UART_ADDR) // if this is root
			return SUCCESS;
		signal Network.snoopedSub(qr, isParent, sender);
		return SUCCESS;
	}

#ifdef kSUPPORTS_EVENTS
     /** Intercept schema event messages and execute the event */
	event TOS_MsgPtr RcvEventMsg.receive(TOS_MsgPtr msg) 
	{
		bool shouldResend;

		shouldResend = ((struct EventMsg*)(msg->data))->fromBase;
		((struct EventMsg*)(msg->data))->fromBase = FALSE;

		if (shouldResend)
		{
			call SendEventMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg);
		}

		call EventUse.signalEventMsg(msg);
		return msg;
    }
#endif
#if 0
    /** Receive a RTCTime msg */
    event TOS_MsgPtr RcvRTCTime.receive(TOS_MsgPtr msg)
    {
          tos_time_t tt;
          struct RTCMsg * p =(struct RTCMsg *)(msg ->data);
          tt.high32 =p.time_high;
          tt.low32 = p.time_low32;
          call Time.set(tt);
          return msg;
    }
#endif

      /** Intercept schema command messages so that they can be forwarded from the root out
       to the rest of the nodes
    */     
	event TOS_MsgPtr RcvCommandMsg.receive(TOS_MsgPtr msg) 
	{
		SchemaErrorNo errorNo;
		bool shouldResend;
		
		call Leds.redToggle();
		shouldResend = ((struct CommandMsg *)(msg->data))->fromBase;
		((struct CommandMsg *)(msg->data))->fromBase = FALSE;
		mWasCommand = TRUE;
		if (shouldResend)
		{
			call Leds.greenToggle();
			if (call SendCommandMsg.send(TOS_BCAST_ADDR, kMSG_LEN, msg) 
				== SUCCESS)
				mDbg = *msg; // save off command for later execution
			else
				mWasCommand = FALSE;
		}
		else
		{
			// XXX ignore command return values for now
			call CommandUse.invokeMsg(msg, NULL, &errorNo);
		}

		return msg;
    }

#ifdef kSTATUS
    /* Event that's fired when a status request message arrives */
    event TOS_MsgPtr RcvStatusMessage.receive(TOS_MsgPtr msg) 
	{
		if (((StatusMessage*)msg->data)->fromBase)
		{
			short numqs, i;
			StatusMessage *smsg;

			smsg = (StatusMessage *)&(mDbg.data);
			smsg->fromBase = FALSE;
			numqs = call QueryProcessor.numQueries();
			if (numqs > kMAX_QUERIES) 
				numqs = kMAX_QUERIES;
			smsg->numQueries = numqs;
			for (i = 0; i < numqs; i++) 
			{
				uint8_t qid = (uint8_t)((call QueryProcessor.getQueryIdx(i))->qid);
				dbg(DBG_USR2, "i = %d, qid = %d\n", i, qid );
				smsg->queries[i] = qid;
			}

			call SendStatusMsg.send(TOS_BCAST_ADDR, kMSG_LEN, &mDbg);
		}
		return msg;
    }
#endif

    command uint16_t NetworkMonitor.getContention() 
	{
		// XXX temporarily disabled
		return 0;
    }

    command void NetworkMonitor.updateContention(bool failure, int status) 
	{
		// XXX temporarily disabled
    }

	command uint16_t NetworkMonitor.getParent()
	{
		return call MultiHopControl.getParent();
	}

	command uint8_t NetworkMonitor.getQueueLength()
	{
		return call QueueControl.getOccupancy();
	}

	command uint8_t NetworkMonitor.getXmitCount()
	{
		return call QueueControl.getXmitCount();
	}

	command uint8_t NetworkMonitor.getQuality()
	{
		return call MultiHopControl.getQuality();
	}
	command uint8_t NetworkMonitor.getDepth()
	{
		return call MultiHopControl.getDepth();
	}

	command uint8_t NetworkMonitor.getMHopQueueLength()
	{
		return call MultiHopControl.getOccupancy();
	}

#ifdef kSUPPORTS_EVENTS
	event result_t EventUse.eventDone(char *name, SchemaErrorNo err) 
	{
		return SUCCESS;
	}
#endif
	event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo err)
	{
		return SUCCESS;
	}

	event result_t QueryProcessor.queryComplete(ParsedQueryPtr q)
	{
		return SUCCESS;
	}
}
