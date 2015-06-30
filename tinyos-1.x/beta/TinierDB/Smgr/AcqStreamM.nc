// $Id: AcqStreamM.nc,v 1.2 2004/07/17 00:08:29 jhellerstein Exp $

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
 * Authors:	Wei Hong
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
includes Tuple;
includes Stream;


module AcqStreamM {
  uses {
	interface Tuple;
	interface AttrUse;
  }

  provides {
	interface Stream;
	interface StdControl;
  }
}

implementation {

  /* ----------------------------- Module Variables ------------------------------- */
	    
  uint8_t          mPendingMask;

  // keep track of all streams
  StreamDescPtr mAllStreams;
  StreamDescPtr mLastStream;

  StreamDescPtr mCurStr;

  // state for fetchTuple
  TupleStructPtr         mFetchTuple;
  uint8_t          mCurFieldIdx;
  uint32_t         mFetchMask;

  command result_t StdControl.init() {
	mPendingMask = 0;
	mAllStreams = NULL;
	mLastStream = NULL;
	mCurStr = NULL;
	mFetchTuple = NULL;
	mCurFieldIdx = 0x00FF;
	mFetchMask = 0;
	return SUCCESS;
  }
  command result_t StdControl.start() {
	return SUCCESS;
  }
  command result_t StdControl.stop() {
	return SUCCESS;
  }
  
  /* ------------------- Bits used in mPendingMask to determine current state ----------------- */
  enum { ST_OPEN_BIT = 0x0001, // opening the stream
		 FETCHTUP_BIT = 0x0002, // fetching a tuple
		 ATTR_STARTING_BIT = 0x0003 // are we starting attributes?
  };



  /* ----------------- Functions to modify pending mask --------------------- */
 
  void SET_OPENING_STREAM() {(mPendingMask |= ST_OPEN_BIT); }
  void UNSET_OPENING_STREAM() { (mPendingMask &= (ST_OPEN_BIT ^ 0xFFFF)); }
  bool IS_OPENING_STREAM() { return (mPendingMask & ST_OPEN_BIT) != 0; }

  void SET_FETCHING_TUPLE() {(mPendingMask |= FETCHTUP_BIT); }
  void UNSET_FETCHING_STREAM() { (mPendingMask &= (FETCHTUP_BIT ^ 0xFFFF)); }
  bool IS_FETCHING_STREAM() { return (mPendingMask & FETCHTUP_BIT) != 0; }

  bool IS_STARTING_ATTRIBUTE() { return (mPendingMask & ATTR_STARTING_BIT) != 0; }
  void UNSET_STARTING_ATTRIBUTE() { (mPendingMask &= (ATTR_STARTING_BIT ^ 0xFFFF)); }
  void SET_STARTING_ATTRIBUTE() { (mPendingMask |= ATTR_STARTING_BIT); }

  /* -------------------- Protos for Internal Routines ---------------------- */
  task void acqOpenDoneTask();
  task void fetchFieldDoneTask();
  result_t fetchNextField(StreamDescPtr streamDesc,
						  uint32_t fieldMask,
						  uint8_t *fieldNoPtr, // OUT: the field that was fetched
						  TupleStructPtr tuple  // OUT, allocated by caller, field will be filled in
						  );


  /* ------------------- Interface Implementation --------------------------- */

  // Open on an AcqStream doesn't do much ... just initializes a stream descriptor.
  // We don't turn on sensors now; we'll let that happen lazily during acquisition.
  command result_t Stream.open(StreamDef stream, StreamDesc streamDesc) {
	// set module-global of currently opening stream
	// Assert (mCurStr == NULL)
	mCurStr = NULL;
	atomic {
	  if (!IS_OPENING_STREAM()) {
		SET_OPENING_STREAM();
		mCurStr = &(streamDesc);
	  }
	}
	if (!mCurStr)
	  return FAIL; // Someone else is opening
	memset(&(streamDesc.streamDesc.acqDesc.fieldStatus), 0, /* TINYDB_MAX_FIELDS */ 32);
	post acqOpenDoneTask();
	return SUCCESS;
  }
	
  // why is this worth a command??
  command TupleDescPtr Stream.getTupleDesc(StreamDescPtr streamDesc) {
	return (&(streamDesc->streamDef->tupleDesc));
  }

  // fetch the next complete tuple in stream
  command result_t Stream.fetchTuple(StreamDescPtr streamDesc, uint32_t fieldMask,
							  TupleStructPtr tuple) {
	// We kick off a split-phase loop through each of the fields
	// doing a split-phase fetchField for each.
	SET_FETCHING_TUPLE();
	mCurStr = streamDesc;
	mFetchTuple = tuple;
	mCurFieldIdx = 0;
	mFetchMask = fieldMask;
	  
	return fetchNextField(streamDesc,  fieldMask, &mCurFieldIdx, tuple);
  }


  command result_t Stream.close(StreamDescPtr streamDesc) {
	// find the streamDesc on the list of streams, and delete it.
	// SHOULD WE SHUT DOWN ITS ATTRs?
	return SUCCESS;
  }

  /* -------------------- Internal Routines ---------------------- */	  

  // The task that's posted to complete the split-phase open() call.
  task void acqOpenDoneTask() {
	StreamDescPtr tmpStr;
	// add streamDesc to list of open streams
	if (mLastStream) mLastStream->nextStreamDesc = mCurStr;
	mLastStream = tmpStr = mCurStr;
	UNSET_OPENING_STREAM();

	signal Stream.openDone(tmpStr, SUCCESS);
  }

  // This routing does the work of dispatching the next fetch of a field from the Attr component.
  // It starts from field numbered (*fieldNoPtr), and walks the bitmap til it finds a field
  // slated for fetching.  Then it OVERWRITES *fieldNoPtr, and tells the Attr component
  // to OVERWRITE the corresponding field in the tuple.
  result_t fetchNextField(StreamDescPtr streamDesc,
						  uint32_t fieldMask,
						  uint8_t *fieldNoPtr, // OUT: the field that was fetched
						  TupleStructPtr tuple  // OUT, allocated by caller, field will be filled in
						  ) {
	CharPtr fieldBufPtr;
	bool isNull;
	SchemaErrorNo errorNo;
	uint8_t i;
	bool started;
	AttrDescPtr attrDesc;

	// find the next field to fetch, starting with (*fieldNoPtr) (inclusive)
	for (i = *fieldNoPtr; i < streamDesc->streamDef->tupleDesc.numFields; i++)
	  if (fieldMask & (1 << i)) {
		*fieldNoPtr = i; // OVERWRITE *fieldNoPtr with the field we'll fetch!
		break;
	  }

	// has the Attribute been started?  If not, do so now!
	// XXXX AttrUse.isStarted may not make sense since there's no way to turn it off when it's stopped!
	if ((call AttrUse.isStarted(streamDesc->streamDef->tupleDesc.fDescs[*fieldNoPtr].name, &started)) == SUCCESS) {
	  if (!started) {
		if (!IS_STARTING_ATTRIBUTE()) {
		  SET_STARTING_ATTRIBUTE();
		  attrDesc = call AttrUse.getAttr(streamDesc->streamDef->tupleDesc.fDescs[*fieldNoPtr].name);
		  return call AttrUse.startAttr(attrDesc->id);
		}
		return SUCCESS; // we're starting this attr
	  }
	}
	else
	  return FAIL;// isStarted call bombed!


	// find the location in tuple to write the new field
	call Tuple.getFieldPtr(tuple, &(streamDesc->streamDef->tupleDesc), *fieldNoPtr, &fieldBufPtr, &isNull);
	if (call AttrUse.getAttrValue(streamDesc->streamDef->tupleDesc.fDescs[*fieldNoPtr].name, 
								  (char *)fieldBufPtr, &errorNo) == SUCCESS) {
	  if (errorNo != SCHEMA_RESULT_PENDING) {
		// getAttrValue did its thing synchronously.  Need to post a task to handle the result.
		post fetchFieldDoneTask();
	  }
	  if (errorNo == SCHEMA_ERROR)
		return FAIL;
	  else return SUCCESS;
	}
	return FAIL; // HOW DID WE DROP THROUGH TO HERE?  HAVE A RETURN HERE TO MAKE THE COMPILER HAPPY.
  }


  event result_t AttrUse.startAttrDone(uint8_t id)
	{
	  UNSET_STARTING_ATTRIBUTE();
	  // attr is started up, so now continue fetching.
	  return fetchNextField(mCurStr, mFetchMask, &mCurFieldIdx, mFetchTuple);

	}

  // OK, we finished acquiring a field.  Kick off another one.
  result_t doFinishField() {
	mCurFieldIdx++;
	return fetchNextField(mCurStr, mFetchMask, &mCurFieldIdx, mFetchTuple);
  }	  

  /** Completion event after some data was fetched */
  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo) {
	return doFinishField();
  }

  /** Used to make attribute setting split phase even when its not ... */
  task void fetchFieldDoneTask() {
	(void) doFinishField();
  }
}
 
