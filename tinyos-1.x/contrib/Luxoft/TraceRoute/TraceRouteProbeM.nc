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
 * Authors:  Dmitriy Korovkin
 *           LUXOFT Inc.
 * Date:     9/15/2003
 *
 */
/*
 * TraceRoute facility test application
 */
includes AM;
includes PiggyBack;
includes MultiHop;
includes TraceFunctions;

module TraceRouteProbeM
{
  provides
  {
    interface StdControl;
  }
  uses 
  {
    interface PiggyBack as PiggyFlood;
    interface PiggyBack as PiggyRoute;
    interface StdControl as TraceRtCtl;
    interface Timer;
    interface RouteControl;
  }
}
implementation
{
  /* 
   * Internal variables
   */
  TOS_Msg buffer; //message buffer we will provide
  uint16_t tracingHost; //host we are going to trace route
  TOS_Msg backBuffer; //message buffer we will provide for back tracing

  /*
   * Task starts routing information gathering process
   */
  task void StartGathering()
  {
    call PiggyFlood.gather(&buffer, tracingHost);
  }
  /*
   * StdControl interface functions
   */
  command result_t StdControl.init()
  {
    result_t ok1; //call results 
    tracingHost = 1;
    ok1 = call TraceRtCtl.init();
    return ok1;
  }

  command result_t StdControl.start()
  {
    result_t ok1, ok2; //call results 

    ok1 = call TraceRtCtl.start();
    call RouteControl.setUpdateInterval(1);
    ok2 = call Timer.start(TIMER_REPEAT, 10000);
    return rcombine(ok1, ok2);
  }

  command result_t StdControl.stop()
  {
    result_t ok1, ok2; //call results 

    ok1 = call Timer.stop();
    ok2 = call TraceRtCtl.stop();
    return rcombine(ok1, ok2);
  }

  /*
   * PiggyBack Flooding interface functions
   */
  event TOS_MsgPtr PiggyFlood.routeReady(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    return msg;
  }

  event result_t PiggyFlood.getBack(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    PiggyMsg* pPMsg = (PiggyMsg*)payload;  
    TOS_MHopMsg* pMHMsg = (TOS_MHopMsg*)backBuffer.data;
    PiggyMsg* pPMHMsg = (PiggyMsg*)pMHMsg->data;

    //Data length in multihop message
    uint16_t len = (TOSH_DATA_LENGTH - offsetof(TOS_MHopMsg, data));
    
    //FIXME: This may be potentially dangerous
    if (pPMsg->idx > nAvail(len))
      pPMsg->idx = nAvail(len);
    memcpy(pPMHMsg, pPMsg, len);
    call PiggyRoute.gatherBack(&backBuffer, pPMsg->source);
    return FAIL;
  }

  /*
   * PiggyBack Routing interface functions
   */
  event TOS_MsgPtr PiggyRoute.routeReady(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    return msg;
  }

  event result_t PiggyRoute.getBack(TOS_MsgPtr msg, void* payload, 
    uint16_t payloadLen)
  {
    return SUCCESS;
  }

  /*
   * Timer interface functions
   */
  event result_t Timer.fired()
  {
    dbg(DBG_USR1, "Timer event\n");
    if(TOS_LOCAL_ADDRESS == 0)
    {
      post StartGathering();
    }
    return SUCCESS;
  }
}

//eof
