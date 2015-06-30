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
includes TinyDB;


/** TupleIntf allows interactions with Tuples, which are base data fetched from
    the Attr interface and stored in a packed array of fixed width fields.
	<p>
    Note that Tuple's should not be confused with QueryResults (or QueryResultTuples)
    which represent more complicated, arbitrary sized data structures consisting of
    an arbitrary number of records.  Tuples are used internally to collect data
    about sensors -- QueryResults are sent to neighboring motes and stored in result
    buffers for external processing.
*/
interface TupleIntf {
  /** @return The size (in bytes) of Tuples corresponding to the specified query */
  command uint16_t tupleSize(ParsedQueryPtr q);

  /** @return The size (in bytes) of the specified field of the specified query,
       or 0 if the field is null or out of range
  */
  command uint16_t fieldSize(ParsedQueryPtr q, uint8_t fieldNo);

  /** Set  the speccified field in the specified tuple corresponding to the specified query
      to the specified data.
      @param q The query that t belongs to
      @param t The tuple whose field should be set
      @param fieldIdx The field to set in t
      @param data The data to write to t (fieldSize(...) bytes will be copied
      @return FAIL if the field is out of range or NULL, or SUCCESS otherwise 
  */
  command result_t setField(ParsedQueryPtr q, TuplePtr t, uint8_t fieldIdx, CharPtr data);

  /** Set the specified field in the specified tuple, using the provided size and type arrays
      to determine where to write the data.
      @param fieldIdx The index of the field to set
      @param t The tuple whose field is to be set
      @param numFields The number of fields in the tuple
      @param sizes The size of each field (in bytes);  must be at least numFields long
      @param types The types of each field (From SchemaType.h); must be at least numFields long
      @param data The data to write into the field
      @return FAIL if the field is out or range or NULL, SUCCESS otherwise.
  */
  command result_t setFieldNoQuery(TuplePtr t, 
					    uint8_t fieldIdx, 
					    uint8_t numFields, 
					    uint8_t sizes[], 
					    uint8_t types[], 
					    CharPtr data);

  /** Return a pointer to the field data for the specified field of the specified query 
      @param q The query that t belongs to
      @param t The Tuple to get the field from
      @param fieldIdx The idx of the field to retrieve
      @return A pointer to the requested field, or NULL if no such field exists (note that writing to this pointer
              will overwrite the tuple data!)
  */
  command CharPtr getFieldPtr(ParsedQueryPtr q, TuplePtr t, uint8_t fieldIdx);

  /** Return a pointer into the field data for the specified field, using the
      provided arrays of sizes and types to compute the appropriate offset.
      @param t The tuple to get the field from
      @param fieldIdx The index of the field to retrieve
      @param numFields The total number of fields in the tuple
      @param sizes The sizes (in bytes) of the fields in the tuple;  this array must be at least numFields entries
      @param The typs (from SchemaType.h) of the fields in the tuple; this array must be at least numFields entries
      @return A pointer to the requested field, or NULL if no such field exists
              (note that writing to this pointer will overwrite tuple data!)
  */
  command CharPtr getFieldPtrNoQuery(TuplePtr t, 
					       uint8_t fieldIdx, 
					       uint8_t numFields, 
					       uint8_t sizes[], 
					       uint8_t types[]);  

  /** Set all the fields of the specified tuple to 0, and reset the bitmap that
       tracks which fields have been written */
  command result_t tupleInit(ParsedQueryPtr q, TuplePtr t);

  /** @return TRUE iff all fields of the specified tuple have been set since it was last reset */
  command bool isTupleComplete(ParsedQueryPtr q, TuplePtr t);

  /** @return An attribute descriptor for the next unset field in the specified tuple, or NULL if
       all fields are set.
  */
  command AttrDescPtr getNextQueryField(ParsedQueryPtr q, TuplePtr t);

  /** Fetch the index of the next empty field in the tuple
     @param (on return) fieldIdx The index of the next empty field in the query 
     @return err_NoMoreResults if there are no more empty fields
     
  */
  command TinyDBError getNextEmptyFieldIdx(ParsedQueryPtr q, TuplePtr t, uint8_t *fieldIdx);
}

