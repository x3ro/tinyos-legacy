/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 * Implementation for Query interface
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
module QueryM {
  provides {
    interface Query;
  }
}

implementation {
  
  
  command uint8_t Query.getField(QueryPtr q, uint8_t idx) {
    return q->fields[idx];
  }
  
  command uint8_t *Query.getFieldPtr(QueryPtr q, uint8_t idx) {
    return &(q->fields[idx]);
  }
  
  command result_t Query.setField(QueryPtr q, uint8_t numFields, uint8_t *f) {
    memcpy(&q->fields, f, numFields);
    q->numFields = numFields;
    return SUCCESS;
  }
  
  command Cond Query.getCondition(QueryPtr q, uint8_t idx) {
    return q->cond[idx];
  }

  command result_t Query.setCondition(QueryPtr q, uint8_t idx, CondPtr c) {
    //c = (Cond *)((char *)((char *)q + sizeof(struct Query) + idx * sizeof(struct Cond)));
    //c = &q->cond[idx];
    memcpy(&q->cond[idx], c, sizeof(struct Cond));
    return SUCCESS;
  }

  command bool Query.gotAllConds(QueryPtr q) {
    dbg(DBG_USR1, "gotAllConds %2X\n",q->seenConds);
    return (q->seenConds & (0xFF)) == 0xFF;
  }
  
  command bool Query.gotAllFields(QueryPtr q) {
    dbg(DBG_USR1, "gotAllFields %d\n",q->seenFields);
    return (q->seenFields);
  }
  
  command bool Query.gotCompleteQuery(QueryPtr q) {
    return rcombine(call Query.gotAllFields(q), call Query.gotAllConds(q));
  }
  
  command bool Query.addQuery(QueryMsgPtr qmsg, QueryPtr q) {
    result_t seenBefore = FALSE;

    if (qmsg->dataType == FIELD_MSG) {
      dbg(DBG_USR1,"FIELD_MSG %2X\n",q->seenFields);
      call Query.setField(q, qmsg->numFields, qmsg->u.fields);
      //seenBefore = q->seenFields;
      q->seenFields = TRUE;     // only one field message

    } else if (qmsg->dataType == COND_MSG) {
      dbg(DBG_USR1,"COND_MSG %2X\n",q->seenConds);
      call Query.setCondition(q, qmsg->index, &qmsg->u.cond);
      seenBefore = (q->seenConds & (1 << qmsg->index));
      q->seenConds |= (1 << qmsg->index);
    }

    return seenBefore;
  }

  command result_t Query.parseQuery(QueryPtr q, UllaQueryPtr uq) {

    uq->qid = q->qid;
    uq->numFields = q->numFields;
    uq->numConds = q->numConds;
    //uq->interval = q->interval;
    //uq->nsamples = q->nsamples;
    return SUCCESS;
  }

} 
