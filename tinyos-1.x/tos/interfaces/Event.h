// $Id: Event.h,v 1.5 2003/10/07 21:46:14 idgay Exp $

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
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     9/24/2002
 *
 */

// data structures for Events


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */

#include <stdarg.h>
#include "Params.h"

enum {
	MAX_EVENTS = 2,
	MAX_EVENT_NAME_LEN = 8,
	MAX_EVENT_QUEUE_LEN = 8,
	MAX_CMD_PER_EVENT = 4
};

struct EventMsg {
    short nodeid;
    char fromBase;
    char data[0];  
};

enum {
  AM_EVENTMSG = 105
};

typedef struct {
	uint8_t idx; // index into EventDesc array
	char name[MAX_EVENT_NAME_LEN + 1];
	uint8_t cmds[MAX_CMD_PER_EVENT];
	uint8_t numCmds;
	bool deleted;
	ParamList params;
} EventDesc;

typedef EventDesc *EventDescPtr;

typedef struct {
	uint8_t numEvents;
	EventDesc eventDesc[MAX_EVENTS];
} EventDescs;

typedef struct {
	EventDescPtr	eventDesc;
	ParamVals		*eventParams;
} EventInstance;

typedef struct {
	EventInstance	events[MAX_EVENT_QUEUE_LEN];
	bool			inuse;
	short			head;
	short			tail;
	short			size;
} EventQueue;

typedef EventDescs *EventDescsPtr;
