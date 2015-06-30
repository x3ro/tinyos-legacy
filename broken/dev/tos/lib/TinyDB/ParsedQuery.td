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
module ParsedQuery {
  provides {
    interface ParsedQueryIntf;
  }
  uses {
    interface Operator as AggOperator;
    interface TupleIntf;
    interface AttrUse;
    interface QueryResultIntf;
    interface Leds;
    command TinyDBError finalizeAggExpr(QueryResult *qr, ParsedQueryPtr q, Expr *e, char *result_buf);
    command short getGroupNoFromQr(QueryResult *qr);
  }
}

implementation {


  command bool ParsedQueryIntf.queryFieldIsNull(uint8_t field) {
    //high bit of query field indicates field is null
    return (field & NULL_QUERY_FIELD) > 0;
  }

  command Expr ParsedQueryIntf.getExpr(ParsedQueryPtr q, uint8_t n) {
    return *(Expr *)(&((char *)q)[sizeof(ParsedQuery) + (q->numFields - 1) * sizeof(char) + n * sizeof(Expr)]);
  }

  command ExprPtr ParsedQueryIntf.getExprPtr(ParsedQueryPtr q, uint8_t n) {
    return (Expr *)(&((char *)q)[sizeof(ParsedQuery) + (q->numFields - 1) * sizeof(char) + n * sizeof(Expr)]);
  }

  command uint8_t ParsedQueryIntf.getFieldId(ParsedQueryPtr q, uint8_t n) {
    return (q->queryToSchemaFieldMap[n]); //note:  may be NULL_QUERY_FIELD
  }

  command result_t ParsedQueryIntf.setExpr(ParsedQueryPtr q, uint8_t n, Expr e) {
    (*(Expr *)(&((char *)q)[sizeof(ParsedQuery) + (q->numFields - 1) * sizeof(char) + n * sizeof(Expr)])) = e;
    return SUCCESS;
  }

  command TuplePtr ParsedQueryIntf.getTuplePtr(ParsedQueryPtr q) {
    return (Tuple *)(&((char *)q)[sizeof(ParsedQuery) + (q->numFields - 1) * sizeof(char) + (q->numExprs) * sizeof(Expr)]);
  }

  command short ParsedQueryIntf.baseSize(QueryPtr q) {
    return sizeof(ParsedQuery) +  (sizeof(char) * ((q)->numFields - 1))  +  (sizeof(Expr) * ((q)->numExprs));
  }


  command short ParsedQueryIntf.pqSize(ParsedQueryPtr pq) {
    return sizeof(ParsedQuery) +  (sizeof(char) * ((pq)->numFields - 1))  +  (sizeof(Expr) * ((pq)->numExprs));
  }

  command uint8_t ParsedQueryIntf.numResultFields(ParsedQueryPtr q, bool *agg) {
    short i;
    Expr *e;
    short numAggs = 0;

    for (i = 0; i < q->numExprs; i++) {
      e = call ParsedQueryIntf.getExprPtr(q, i);
      if (e->opType != kSEL) {
	numAggs++;
      }
    }

    
    if (numAggs > 0) { 
      *agg = TRUE;
      return numAggs;
    } else {
      *agg = FALSE;
      return q->numFields;
    }    
  }

  /** Copy data from the field resultid (as returned by getResultId) of qr into result_buf
   */
  command TinyDBError ParsedQueryIntf.getResultField(ParsedQueryPtr q, QueryResultPtr qr, uint8_t resultid, char *result_buf) {
    QueryResult localqr;
    ResultTuple rt;
    short numRecords = call QueryResultIntf.numRecords(qr,q);
    bool isAgg = (qr->qrType != kNOT_AGG);
    uint8_t fieldId = resultid & 0x7F;
    bool isGroupNo = (resultid == GROUP_FIELD); //are we just returning the group number?
    TinyDBError err;

    if (resultid == NULL_QUERY_FIELD) {

      return err_InvalidIndex;
    }

    if (!isAgg) {
      Tuple *t;
      char *data;

      err = call QueryResultIntf.toTuplePtr(qr, q, &t);
      if (err != err_NoError) return err;
      
      data = call TupleIntf.getFieldPtr(q, t, fieldId);
      if (data == NULL) return err_InvalidIndex;

      memcpy(result_buf, data, call TupleIntf.fieldSize(q,fieldId));
     
      return err_NoError;
    } else {
      Expr *e = isGroupNo?NULL:call ParsedQueryIntf.getExprPtr(q, fieldId);
      short i;

      for (i = 0; i < numRecords; i++) {
	//look for a ResultTuple for the appropriate expression
	rt = call QueryResultIntf.getResultTuple(qr, i, q);
	err = call QueryResultIntf.fromResultTuple(rt, &localqr, q);
	if (err != err_NoError) { 
	  return err;
	}
	if (isGroupNo) {
	  *(short *)result_buf = call getGroupNoFromQr(&localqr);
	  return err_NoError;
	} else {
	  if (call AggOperator.resultIsForExpr(&localqr, e)) {
	    err = call finalizeAggExpr(&localqr, q , e, result_buf);
	    if (err != err_NoError) { 
	      return err;
	    }
	    else return err_NoError;
	  }
	}
      }
    }


    return err_InvalidIndex;
  }
  
  /** Set id to the be the index into query results from q corresponding to field f
     Return err_InvalidIndex if the query does not contain a corresponding field
  */
  command TinyDBError ParsedQueryIntf.getResultId(ParsedQueryPtr q, Field *f, uint8_t *id) {
    AttrDescPtr attr = call AttrUse.getAttr(f->name);
    uint8_t i;
    uint8_t fid = 0xFF;

    if (attr == NULL) return err_InvalidIndex;

    for (i = 0; i < q->numFields; i++) {
      if (q->queryToSchemaFieldMap[i] == attr->idx) {
	fid = i;
      }
    }

    if (fid == 0xFF) return err_InvalidIndex;

    for (i = 0; i < q->numExprs; i++) {
	Expr *e = call ParsedQueryIntf.getExprPtr(q, i);
	if (e->opType != kSEL && e->ex.agg.groupingField == fid) {
	  *id = GROUP_FIELD;
	  return err_NoError;
	}
    }


    if (f->op == NOOP) {
      *id = fid;
      return err_NoError;
    } else {
      for (i = 0; i < q->numExprs; i++) {
	Expr *e = call ParsedQueryIntf.getExprPtr(q, i);
	if (e->opType != kSEL && e->ex.agg.field == fid && e->ex.agg.op == f->op) {
	  //found it!
	  *id = e->idx;
	  return err_NoError;
	}
      }
    }
    
    //didn't find it
    return err_InvalidIndex;
    
  }


  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo) {
    return SUCCESS;
  }

  event TinyDBError AggOperator.processedResult(QueryResultPtr qr, ParsedQueryPtr q, ExprPtr e) {
    return err_NoError;
  }

  event TinyDBError AggOperator.processedTuple(TuplePtr t, ParsedQueryPtr q, ExprPtr e, bool passed) {
    return err_NoError;
  }

}
