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
/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     9/24/2002
 *
 */

// data structures for Events

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
