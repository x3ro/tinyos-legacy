// $Id: Tuple.h,v 1.3 2004/07/17 00:07:53 jhellerstein Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * Authors:	Joe Hellerstein
 *              Design by Sam Madden, Wei Hong, and Joe Hellerstein
 * Date last modified:  7/14/04
 *
 *
 */

/**
 * @author Joe Hellerstein
 * @author Design by Joe Hellerstein
 * @author Wei Hong
 * @author and Sam Madden
 */


/* Tuples are always full, but with null compression
   Fields in the tuple are defined on a per query basis,
   with mappings defined by the appropriate query
   data structure.
   If a field is null (e.g. not defined on the local sensor), its
   notNull bit is set to 0.

   Tuples should be accesses exclusively through TUPLE.comp
*/
#ifndef TUPLE_H
#define TUPLE_H

#include "MultiHop.h"

enum {QUERY_FIELD_SIZE = 8};

// XXX We're assuming we're using the TOS Multihop component, and
//     defining TINYDB_PAYLOAD_LEN in terms of TOS_MHopMsg.   If somebody swaps in a new 
//     routing layer (e.g. doesn't multihop at all), this will be inaccurate, 
//     either conservative or broken.  Can we clean this up?

// packet payload left over in a multihop msg
#define MULTIHOP_HEADER_LEN offsetof(TOS_MHopMsg,data) 

// packet payload available to TinyDB
#define TINYDB_PAYLOAD_LEN (TOSH_DATA_LENGTH - MULTIHOP_HEADER_LEN) 
// packet space left for the actual data (fields) of a tuple 
// -3 is /* offsetof(ResultTuple,tup) */ 
// -5 is /* offsetof(Tuple,fieldData) */ 
#define TINYDB_MAX_DATA (TINYDB_PAYLOAD_LEN - 3 - 5)



// maximum number of fields in a tuple.  Used in picking TupleDesc size. This is conservative.  
// Use ifndef to allow people to override elsewhere.
// XXX NOTE: We do not support more than 32 fields.  Currently various places in the code use 
// uint32 bitmaps to identify boolean properties of the fields in a tuple!
#ifndef TINYDB_MAX_FIELDS
#define TINYDB_MAX_FIELDS TINYDB_MAX_DATA
#endif

// #if ((TINYDB_MAX_FIELDS) > 32)
// Somebody is getting greedy ... make sure they crash in an obvious way, and think about
// how to get past the fundamental 32-field limit!
// #define TINYDB_MAX_FIELDS 0
// #endif

// The main Tuple data structure
typedef struct {
  uint8_t numFields; //1
  uint32_t notNull;  //bitmap defining the fields that are null or not null //5
  //bit i corresponds to ith entry in ParsedQuery.queryToSchemaFieldMap

  uint8_t fieldData[TINYDB_MAX_DATA]; //Access only through TUPLE.comp!
} TupleStruct, *TupleStructPtr, **TupleStructHandle;

// FieldDesc: Description of a field
typedef struct {
  char name[QUERY_FIELD_SIZE]; //8
  uint8_t type;//9
  //alias info here?
} FieldDesc, *FieldDescPtr;

// TupleDesc: Description of a tuple
typedef struct {
  uint8_t numFields; // 1
  FieldDesc fDescs[TINYDB_MAX_FIELDS];
} TupleDesc, *TupleDescPtr;

// TupleSlot: A place to store a self-describing tuple
typedef struct {
  TupleDescPtr desc;
  TupleStruct tup;
} TupleSlot, *TupleSlotPtr;
 
#endif // TUPLE_H
