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
 * Interface for Query Message
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UllaQuery;

interface Query {

  command uint8_t getField(QueryPtr q, uint8_t idx);
  command uint8_t *getFieldPtr(QueryPtr q, uint8_t idx);
  command uint8_t setField(QueryPtr q, uint8_t idx, uint8_t *f);
  command Cond getCondition(QueryPtr q, uint8_t idx);
  command result_t setCondition(QueryPtr q, uint8_t idx, CondPtr c);

  command bool gotAllConds(QueryPtr q);
  command bool gotAllFields(QueryPtr q);
  command bool gotCompleteQuery(QueryPtr q);
  
  /**
   * Assembles all the query messages into a single query
   * @param qmsg incoming query messages
   * @param q output
   * @return false if the query message is known before
   **/
  command bool addQuery(QueryMsgPtr qmsg, QueryPtr q);
  
  // need to be added to notify when memory is allocated 2006/02/24
  //event result_t addQueryDone(QueryPtr q);
  
  /**
   * Parses the query and starts measurement
   * @param q input query to parse
   * @param uq parsed query known as ulla query
   **/
  command result_t parseQuery(QueryPtr q, UllaQueryPtr uq);
  
}
