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
 * Authors:		Sam Madden
 * Date last modified:  6/25/02
 *
 */

includes Event;
includes AM;
includes IntMsg;
includes PiggyBack;
includes Ping;
#ifdef _WITH_CHANQ_  
includes ChanQ;
#endif

configuration TinyDBApp {
}

implementation {
  components Main, TinyDBAppM, TupleRouter, TimerC, Event, ChanQM, PingM,
#if defined(TRACEROUTE) || defined(_WITH_CHANQ_)
    MultiHopRouter as Router,
#endif
#ifdef TRACEROUTE
    TraceRouteM as TraceRoute, 
    GenericCommPromiscuous as Comm, 
    MultiHopFlood as Flood,
    QueuedSend,
#endif
#ifdef INTMSG
    RfmToInt, IntToUART as IntOut,
#endif
#ifdef _WITH_CHANQ_  
    ECC,
#endif
#ifndef TDBNOLEDS
    LedsC as Leds;
#else
    NoLeds as Leds;
#endif


  Main.StdControl -> TinyDBAppM;
#ifdef INTMSG
  TinyDBAppM.InControl -> RfmToInt.StdControl;
  TinyDBAppM.OutControl -> IntOut.StdControl;
  RfmToInt.IntOutput -> IntOut.IntOutput;
#endif
  TinyDBAppM.Timer ->  TimerC.Timer[unique("Timer")];
  TinyDBAppM.EventControl -> Event;
  TinyDBAppM.EventUse -> Event;
  TinyDBAppM.EventRegister -> Event;
  TinyDBAppM.DBControl -> TupleRouter;
  TinyDBAppM.Leds -> Leds;

/*
 * Ping support methods
 */
  TinyDBAppM.PingControl -> PingM.StdControl;
  TinyDBAppM.RecvPing -> PingM.RecvPing[AM_PINGREQ];
  TinyDBAppM.ReplyPing -> PingM.ReplyPing[AM_PINGREPLY];

//MultiHop routing algorithm
  PingM.Send[AM_PINGREPLY] -> Router.Send[AM_PINGREPLY];
  PingM.Receive[AM_PINGREPLY] -> Router.Receive[AM_PINGREPLY];
  PingM.Intercept[AM_PINGREPLY] -> Router.Intercept[AM_PINGREPLY];
  Router.ReceiveMsg[AM_PINGREPLY] -> Comm.ReceiveMsg[AM_PINGREPLY];

//MultiFlood routing algorithm
  PingM.Send[AM_PINGREQ] -> Flood.Send[AM_PINGREQ];
  PingM.Receive[AM_PINGREQ] -> Flood.Receive[AM_PINGREQ];
  ChanQM.Intercept[AM_PINGREQ] -> Flood.Intercept[AM_PINGREQ];
  
  Flood.ReceiveMsg[AM_PINGREQ] -> Comm.ReceiveMsg[AM_PINGREQ];
  Flood.SendMsg[AM_PINGREQ] -> QueuedSend.SendMsg[AM_PINGREQ];

/*
 * Channel Quality support methods
 */
#ifdef _WITH_CHANQ_  
  TinyDBAppM.ChQControl -> ChanQM.StdControl;
  TinyDBAppM.RecvRequest -> ChanQM.RecvRequest[AM_CQREQ];
#if 0
  TinyDBAppM.SendReq -> ChanQM.SndData[AM_CQREQ];
#endif
  TinyDBAppM.SndData -> ChanQM.SndData[AM_CHANQMSG];
  ChanQM.gimme -> ECC.gimme;
  ChanQM.gimme -> Router.gimme;

//MultiHop routing algorithm
  ChanQM.Send[AM_CHANQMSG] -> Router.Send[AM_CHANQMSG];
  ChanQM.Receive[AM_CHANQMSG] -> Router.Receive[AM_CHANQMSG];
  ChanQM.Intercept[AM_CHANQMSG] -> Router.Intercept[AM_CHANQMSG];
  Router.ReceiveMsg[AM_CHANQMSG] -> Comm.ReceiveMsg[AM_CHANQMSG];

//MultiFlood routing algorithm
  ChanQM.Send[AM_CQREQ] -> Flood.Send[AM_CQREQ];
  ChanQM.Receive[AM_CQREQ] -> Flood.Receive[AM_CQREQ];
  ChanQM.Intercept[AM_CQREQ] -> Flood.Intercept[AM_CQREQ];
  
  Flood.ReceiveMsg[AM_CQREQ] -> Comm.ReceiveMsg[AM_CQREQ];
  Flood.SendMsg[AM_CQREQ] -> QueuedSend.SendMsg[AM_CQREQ];
#endif

/*
 * Traceroute support methods
 */
#ifdef TRACEROUTE
  TinyDBAppM.TraceRtCtl -> TraceRoute;

  TinyDBAppM.PiggyFlood -> TraceRoute.PiggyBack[AM_PIGGYMSG];
  TinyDBAppM.PiggyRoute -> TraceRoute.PiggyBack[AM_PIGGYMSGRT];

  TraceRoute.SubControl -> Flood.StdControl;
  TraceRoute.SubControl -> Router.StdControl;
  
//MultiHop routing algorithm
  TraceRoute.Send[AM_PIGGYMSGRT] -> Router.Send[AM_PIGGYMSGRT];
  TraceRoute.Receive[AM_PIGGYMSGRT] -> Router.Receive[AM_PIGGYMSGRT];
  TraceRoute.Intercept[AM_PIGGYMSGRT] -> Router.Intercept[AM_PIGGYMSGRT];
  Router.ReceiveMsg[AM_PIGGYMSGRT] -> Comm.ReceiveMsg[AM_PIGGYMSGRT];


//MultiFlood routing algorithm
  TraceRoute.Send[AM_PIGGYMSG] -> Flood.Send[AM_PIGGYMSG];
  TraceRoute.Receive[AM_PIGGYMSG] -> Flood.Receive[AM_PIGGYMSG];
  TraceRoute.Intercept[AM_PIGGYMSG] -> Flood.Intercept[AM_PIGGYMSG];
  
  Flood.ReceiveMsg[AM_PIGGYMSG] -> Comm.ReceiveMsg[AM_PIGGYMSG];
  Flood.SendMsg[AM_PIGGYMSG] -> QueuedSend.SendMsg[AM_PIGGYMSG];

#endif
}

//eof
