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
/** Expression evaluator that allows for more complicated select and aggregate expressions.
 *  For example 	"select avg(s.temp * 2) from sensors as s
 *		 where s.temp / 5 > 25
 *		 group by s.light >> 2"
 *
 *  Author:  Kyle Stanek 
 *           Designed by Kyle Stanek and Sam Madden
 *  Created on July 15, 2002 at 3:52 PM
 */ 

module ExprEvalC {
  provides {
    interface ExprEval;
  }
}

implementation
{
  // Prototype for local utility function
  short evaluateSimpleExpr(short a, short op, short b);
  
  command short ExprEval.evaluate(Expr *e, short fieldValue) {
    short fieldOp = e->fieldOp;
    short fieldConst = e->fieldConst;

    return evaluateSimpleExpr(fieldValue, fieldOp, fieldConst);
  }
  
  command short ExprEval.evaluateGroupBy(AggregateExpression a, short grpByFieldValue) {
    short grpByFieldOp = a.groupFieldOp;
    short grpByFieldConst = a.groupFieldConst;

    return evaluateSimpleExpr(grpByFieldValue, grpByFieldOp, grpByFieldConst);
  }
  
  //returns c, where c = a op b
  short evaluateSimpleExpr(short a, short op, short b) {
    
    //  Op codes are defined in TinyDB.h
    switch(op) { 
    case FOP_NOOP: //no op
      break;
    case FOP_TIMES:
      return (a * b); 
    case FOP_DIVIDE: 
      return (a / b); 
    case FOP_ADD: 
      return (a + b); 
    case FOP_SUBTRACT: 
      return (a - b); 
    case FOP_MOD: 
      return (a % b); 
    case FOP_RSHIFT: 
      return (a >> b); 
    }
    
    return a;
  }
}

