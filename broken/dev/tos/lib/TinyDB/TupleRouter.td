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
includes AM;
includes SchemaType;
includes Attr;
includes DBBuffer;
includes TinyDB;

configuration TupleRouter {
  provides interface QueryProcessor;
  provides interface StdControl;
}

implementation {
  components NetworkC, Tuple, Query, ParsedQuery, 
    AggOperator, SelOperator, QueryResult, TupleRouterM, TinyAlloc,
    TimerC, RandomLFSR, GenericComm, PotC, LedsC, HPLInterrupt, TinyDBAttr,
    DBBufferC, TinyDBCommand, Attr, ExprEvalC;

  TupleRouterM.QueryProcessor = QueryProcessor;
  TupleRouterM.StdControl = StdControl;
  TupleRouterM.Network -> NetworkC;
  TupleRouterM.AttrUse -> TinyDBAttr;
  TupleRouterM.TupleIntf -> Tuple;
  TupleRouterM.QueryIntf -> Query;
  TupleRouterM.ParsedQueryIntf -> ParsedQuery;
  TupleRouterM.SelOperator -> SelOperator;
  TupleRouterM.AggOperator -> AggOperator;
  TupleRouterM.QueryResultIntf -> QueryResult;
  TupleRouterM.MemAlloc -> TinyAlloc;
  TupleRouterM.Timer -> TimerC.Timer[unique("Timer")];
  TupleRouterM.Random -> RandomLFSR;
  TupleRouterM.Leds -> LedsC;
  TupleRouterM.TimerControl -> TimerC.StdControl;
  TupleRouterM.ChildControl -> NetworkC.StdControl;
  TupleRouterM.ChildControl -> TinyDBAttr.StdControl;
  TupleRouterM.ChildControl -> TinyDBCommand.StdControl;
  TupleRouterM.ChildControl -> DBBufferC.StdControl;
  TupleRouterM.Interrupt -> HPLInterrupt;
  TupleRouterM.RadioControl -> GenericComm;
  TupleRouterM.DBBuffer -> DBBufferC;
  TupleRouterM.CommandUse -> TinyDBCommand;
  TupleRouterM.addResults -> AggOperator.addResults;


  ParsedQuery.AttrUse -> TinyDBAttr;
  ParsedQuery.QueryResultIntf -> QueryResult;
  ParsedQuery.TupleIntf -> Tuple;
  ParsedQuery.AggOperator -> AggOperator;
  ParsedQuery.finalizeAggExpr -> AggOperator.finalizeAggExpr;
  ParsedQuery.Leds -> LedsC;
  ParsedQuery.getGroupNoFromQr -> AggOperator.getGroupNoFromQr;

  DBBufferC.RadioQueue -> TupleRouterM;
  DBBufferC.MemAlloc -> TinyAlloc;
  DBBufferC.QueryProcessor->TupleRouterM;
  DBBufferC.Leds -> LedsC;
  DBBufferC.CommandUse -> TinyDBCommand;
  DBBufferC.QueryResultIntf -> QueryResult;
  DBBufferC.ParsedQueryIntf -> ParsedQuery;
  DBBufferC.TupleIntf -> Tuple;
  DBBufferC.allocDebug -> TinyAlloc.allocDebug;
  DBBufferC.Interrupt -> HPLInterrupt;

  AggOperator.QueryProcessor -> TupleRouterM;
  AggOperator.TupleIntf -> Tuple;
  AggOperator.ParsedQueryIntf -> ParsedQuery;
  AggOperator.MemAlloc ->TinyAlloc;
  AggOperator.signalError -> TupleRouterM.signalError;
  AggOperator.ExprEval -> ExprEvalC;
  AggOperator.QueryResultIntf -> QueryResult;
  AggOperator.Leds -> LedsC;
  
  SelOperator.TupleIntf -> Tuple;
  SelOperator.ExprEval -> ExprEvalC;

  Tuple.ParsedQueryIntf -> ParsedQuery;
  Tuple.AttrUse -> TinyDBAttr;
  Tuple.QueryProcessor -> TupleRouterM;

  QueryResult.TupleIntf -> Tuple;
  QueryResult.MemAlloc -> TinyAlloc;
  QueryResult.Leds -> LedsC;

  NetworkC.SendDataMsg -> GenericComm.SendMsg[kDATA_MESSAGE_ID];
  NetworkC.SendQueryMsg -> GenericComm.SendMsg[kQUERY_MESSAGE_ID];
  NetworkC.SendQueryRequest -> GenericComm.SendMsg[kQUERY_REQUEST_MESSAGE_ID];
  NetworkC.DebugMsg -> GenericComm.SendMsg[1];
  NetworkC.SchemaMsg -> GenericComm.SendMsg[103];
  
  NetworkC.RcvDataMsg -> GenericComm.ReceiveMsg[kDATA_MESSAGE_ID];
  NetworkC.RcvQueryMsg -> GenericComm.ReceiveMsg[kQUERY_MESSAGE_ID];
  NetworkC.RcvRequestMsg -> GenericComm.ReceiveMsg[kQUERY_REQUEST_MESSAGE_ID];
  NetworkC.RcvSchemaMsg -> GenericComm.ReceiveMsg[103];

  NetworkC.Leds -> LedsC;
  NetworkC.Random -> RandomLFSR;

  NetworkC.CommandUse -> TinyDBCommand;
  NetworkC.ParentAttr -> Attr.Attr[6];

  NetworkC.QueryProcessor -> TupleRouterM;

  TinyAlloc.Leds -> LedsC;
  TinyAlloc.StdControl = StdControl;
}
