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
 * Author:   Su Ping
 *
 * Intel Research Berkeley Lab
 */

includes MoteIdRspMsg;

module MoteIdM { 
    provides 	{
        interface StdControl;
	interface MoteId;
    }

  uses {
    interface SendMsg as SendMoteIdMsg;
    interface StdControl as CommControl;
    interface Leds;
  }
}

/* 
 *  Module Implementation
 */

implementation 
{
  TOS_MsgPtr msg;	
  int8_t send_pending;
  TOS_Msg buf;

  task void response() {
    int16_t sender;
    struct MoteIdRspMsg * pdata = (struct MoteIdRspMsg *) msg->data;
    if (send_pending==0)  {
       // save sender address
       //sender = pdata->source;
       // do broadcast now 
       sender = 0xffff;
       // build a response msg
       pdata->source = TOS_LOCAL_ADDRESS;
       pdata->hopCnt=0;
       pdata->seqno=0;

       // send msg back to sender
       send_pending = call SendMoteIdMsg.send(sender, sizeof(pdata), msg);
    }

  }


  /**
   * Reset send_pending flag to 0 in response to SendMsg.sendDone event
   *
   * @return Returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  event result_t SendMoteIdMsg.sendDone(TOS_MsgPtr pmsg, result_t status)
  {
      call Leds.yellowToggle();
      if (status) { 
          call Leds.redToggle();
		send_pending = 0;
		msg=pmsg;//???
	  signal MoteId.done(pmsg, SUCCESS);
      }
      return SUCCESS;
  }
  
  command result_t MoteId.sendId(TOS_MsgPtr pmsg) {
    msg = pmsg;
    post response();
    return SUCCESS;
  }

  default event result_t MoteId.done(TOS_MsgPtr pmsg, result_t status)
  {
	return SUCCESS;
  }

  /** 
   *  Initialiation the module: 
   *  
   *  1. Initialize module static variables
   *  2. turn yellow Led on
   *  3. Initialize underlining communication layer
   *  @return Returns <code>SUCCESS</code> or <code>FAILED</code>
   **/

  command result_t StdControl.init() {
    msg = &buf;
    send_pending=0;

    // initialize low level component 
    return call CommControl.init();
  }


  command result_t StdControl.start(){
    return call CommControl.start();
  }

  command result_t StdControl.stop(){
    return call CommControl.stop();
  } 
} // end of implementation
