/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
 *  Copyright (c) 2004 Intel Corporation 
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
/* Authors:   Philip Levis
 * History:   created 4/18/2002
 *            ported to nesC 6/19/2002
 *            shifted to Mate (instead of Bombilla) 3/10/04
 */

/**
 * @author Philip Levis
 */


#ifndef MATE_TYPES_H_INCLUDED
#define MATE_TYPES_H_INCLUDED

#include "list.h"
#include <stddef.h>
#include "AM.h"
#include "MateConstants.h"


typedef uint8_t  MateOpcode;
typedef uint16_t MateHandlerLength;
typedef uint16_t  MateCapsuleOption;
typedef uint16_t MateCapsuleLength;
typedef uint32_t MateCapsuleVersion;


typedef struct {
  list_t queue;
} MateQueue;

typedef struct {
  uint8_t type;
  uint16_t var;
} MateSensorVariable;

typedef struct {
  uint8_t padding;
  int16_t var;
} MateValueVariable;

typedef struct {
  uint8_t type;
  uint8_t size;
  int16_t entries[MATE_BUF_LEN];
} MateDataBuffer;

typedef struct {
  uint8_t padding;
  MateDataBuffer* var;
} MateBufferVariable;

typedef struct {
  uint8_t type;
  union {
    MateSensorVariable sense;
    MateValueVariable value;
    MateBufferVariable buffer;
  };
} MateStackVariable;

typedef struct {
  uint8_t sp;
  MateStackVariable stack[MATE_OPDEPTH];
} MateOperandStack;
   	 
typedef struct {
  //  uint32_t indexes;
  //uint8_t counter;
} MateBiBaSignature;

/* A MateCapsule is the unit of propagation. */
typedef struct {
  MateCapsuleOption options;
  MateCapsuleLength dataSize;
  int8_t data[MATE_CAPSULE_SIZE];
  //  MateBiBaSignature signature;
} MateCapsule __attribute__((packed));

typedef struct {
  MateHandlerID handler;
  uint16_t pc;
} MateReturnVariable;

typedef struct {
  uint8_t sp;
  MateReturnVariable stack[MATE_CALLDEPTH];
} MateReturnStack;

typedef struct {
  uint16_t pc;                                 // Current pc value
  uint8_t state;                               // Context state
  MateContextID which;                         // Context ID
  MateHandlerID rootHandler;              // Starting routine
  MateHandlerID currentHandler;           // Current routine
  uint8_t heldSet[(MATE_LOCK_COUNT + 7) / 8];    // Held locks
  uint8_t releaseSet[(MATE_LOCK_COUNT + 7) / 8]; // Pending lock releases
  uint8_t acquireSet[(MATE_LOCK_COUNT + 7) / 8]; // Locks to acquire
  list_link_t link;                            // Link entry for wait queues
  MateQueue* queue;                            // Current wait queue
} MateContext;

typedef struct {
  MateContext* holder;
} MateLock;

typedef struct MateErrorMsg {
  uint8_t context;
  uint8_t reason;
  uint8_t capsule;
  uint8_t instruction;
  uint16_t me;
} MateErrorMsg;

typedef struct MatePacketMsg {
  int8_t header[MATE_HEADER_SIZE];
  MateDataBuffer payload;
} MatePacket;

typedef struct MateTrickleTimer {
  uint16_t elapsed;      // Current time (in ticks)
  uint16_t threshold;    // Time to consider transmitting (in ticks) (t)
  uint16_t interval;     // Size of current interval (in ticks)      (tau)
  uint16_t numHeard;     // Number of messages heard                 (c)
} MateTrickleTimer;

typedef struct MateCapsuleChunkMsg {
  MateCapsuleVersion version;
  uint8_t capsuleNum;
  uint8_t piece;
  uint8_t chunk[MVIRUS_CHUNK_SIZE];
} MateCapsuleChunkMsg;

typedef struct MateVersionMsg {
  MateCapsuleVersion versions[MATE_CAPSULE_NUM];
} MateVersionMsg;

typedef struct MateCapsuleStatusMsg {
  uint16_t me;
  MateCapsuleVersion version;
  uint8_t capsuleNum;
  uint8_t bitmask[MVIRUS_BITMASK_SIZE];
} MateCapsuleStatusMsg;

typedef struct MateCapsuleMsg {
  MateCapsule capsule;
} MateCapsuleMsg;

#if 0
void fail(void)
{
  for (;;)
    ;
}
#endif

inline void setpc(MateContext *context, uint16_t val)
{
#if 0
  if (context->currentHandler == MATE_HANDLER_NUM)
    {
      if (val <= 2)
	fail();
    }
#endif
  context->pc = val;
}

#endif
