// $Id: Stream.h,v 1.2 2004/07/17 00:08:29 jhellerstein Exp $

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
 *              Design by Wei Hong, Joe Hellerstein and Sam Madden
 * Date last modified:  7/14/04
 *
 *
 */

/**
 * @author Wei Hong
 * @author Design by Wei Hong
 * @author Joe Hellerstein
 * @author and Sam Madden
 */

#include "Tuple.h"

// Status flags for opening streams
#define STCLOSED 0
#define STOPENING 1
#define STOPEN 2


typedef enum {
  ACQUISITION_STREAM = 0, 
  STORED_STREAM = 1
} StreamType;

typedef struct {
	uint8_t numFields;
	uint8_t fieldId[TINYDB_MAX_FIELDS];
} AcqStream;

typedef struct {
	void *handle;
	// XXX pending smgr design
} SmgrStream;

// opaque stream definition
typedef struct {
	StreamType type;
	union {
	  AcqStream acqStream;
	  SmgrStream smgrStream;
	} str;
  TupleDesc tupleDesc; // WHY IS THIS NOT IN StreamDesc
} StreamDef, *StreamDefPtr;

typedef struct {
  uint8_t fieldStatus[TINYDB_MAX_FIELDS];
} AcqStreamDesc, *AcqStreamDescPtr;

typedef struct {
  // XXX pending smgr design
} SmgrStreamDesc;

typedef struct strdesc {
  StreamDefPtr streamDef;
  union {
	AcqStreamDesc acqDesc;
	SmgrStreamDesc smgrDesc;
  } streamDesc;
  struct strdesc *nextStreamDesc; // keep a linked list of open streamDescs
} StreamDesc, *StreamDescPtr;

