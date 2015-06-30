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
/*
 * Authors:   Philip Levis
 * History:   Jul 19, 2004    Preparation for 2.0 release
 *	      Sep 28, 2004    Added resource encoding support
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MBuffer {
  provides {
    interface MateBuffer as Buffer;
    interface MateType as BufferType;
  }
  uses {
    interface MateError as Error;
    interface MateTypes as Types;
  }
}


implementation {

  command result_t Buffer.clear(MateContext* context, 
				MateDataBuffer* buffer) {
    int i;
    buffer->size = 0;
    buffer->type = MATE_TYPE_NONE;
    for (i = 0; i < MATE_BUF_LEN; i++) {
      buffer->entries[i] = 0;
    }
    return SUCCESS;
  }

  command result_t Buffer.checkAndSetTypes(MateContext* context, 
					   MateDataBuffer* buffer, 
					   MateStackVariable* var) {
    MateDataType type = var->type;
    dbg(DBG_USR1, "VM: Check buffer type %i against %i\n", (int)buffer->type, (int)var->type);
    // If it's a clean buffer, set its type
    if (!call Types.checkValue(context, var)) {
      dbg(DBG_USR1, "VM: Buffers can only contain values\n");
      return FAIL;
    }
    else if (buffer->type == MATE_TYPE_NONE) {
      buffer->type = type;
      return SUCCESS;
    }
    else if (buffer->type == var->type) {
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Buffer.append(MateContext* context,
				 MateDataBuffer* buffer,
				 MateStackVariable* var) {
    if (buffer->size >= MATE_BUF_LEN) {
      dbg(DBG_ERROR, "VM: Data buffer overrun.\n");
      call Error.error(context, MATE_ERROR_BUFFER_OVERFLOW);
      return FAIL;
    }
    if (call Buffer.checkAndSetTypes(context, buffer, var) == FAIL) {
      call Error.error(context, MATE_ERROR_TYPE_CHECK);
      return FAIL;
    }
    else {
      buffer->entries[(int)buffer->size] = var->value.var;
      buffer->size++;
      return SUCCESS;
    }
  } 

  command uint8_t Buffer.concatenate(MateContext* context,
				     MateDataBuffer* dest,
				     MateDataBuffer* src) {
    if (dest->type != src->type) {
      call Error.error(context, MATE_ERROR_INVALID_TYPE);
      return FAIL;
    }
    else {
      uint8_t i;
      uint8_t start;
      uint8_t end;
      MateStackVariable var;

      start = dest->size;
      end = start + src->size;
      end = (end > MATE_BUF_LEN)? MATE_BUF_LEN:end;
      for (i = start; i < end; i++) {
	call Buffer.get(context, src, i - start, &var);
	call Buffer.append(context, dest, &var);
      }
      return (start + src->size) - end;
    }
  }
  command result_t Buffer.prepend(MateContext* context,
				  MateDataBuffer* buffer, 
				  MateStackVariable* var) {
    if (buffer->size >= MATE_BUF_LEN) {
      dbg(DBG_ERROR, "VM: Data buffer overrun.\n");
      call Error.error(context, MATE_ERROR_BUFFER_OVERFLOW);
      return FAIL;
    }
    else if (call Buffer.checkAndSetTypes(context, buffer, var) == FAIL) {
      call Error.error(context, MATE_ERROR_TYPE_CHECK);
      return FAIL;
    }
    else {
      uint8_t i;
      for (i = buffer->size; i > 0; i--) {
        buffer->entries[(int)i] = buffer->entries[(int)i - 1];
      }
      buffer->entries[0] = var->value.var;
      buffer->size++;
      return SUCCESS;
    }
  }

  command result_t Buffer.get(MateContext* context,
			      MateDataBuffer* buffer, 
			      uint8_t bufferIndex,
			      MateStackVariable* dest){
    if (bufferIndex >= buffer->size) {
      dbg(DBG_ERROR, "VM: Index %i out of bounds on buffer of size %i.\n", (int)bufferIndex, (int)buffer->size);
      call Error.error(context, MATE_ERROR_INDEX_OUT_OF_BOUNDS);
      return FAIL;
    }
    else if (buffer->type != MATE_TYPE_NONE) {
      dest->type = buffer->type;
      dest->value.var = buffer->entries[bufferIndex];
      return SUCCESS;
    }
    else {
      dbg(DBG_ERROR, "VM: Tried to get entry from buffer of unknown type!\n");
      return FAIL;
    }
  }



  command result_t Buffer.yank(MateContext* context,
			       MateDataBuffer* buffer, 
			       uint8_t bufferIndex,
			       MateStackVariable* dest) {
    if (bufferIndex >= buffer->size) {
          dbg(DBG_ERROR, "VM: Index %i out of bounds on buffer of size %i.\n", (int)bufferIndex, (int)buffer->size);
      call Error.error(context, MATE_ERROR_INDEX_OUT_OF_BOUNDS);
      return FAIL;
    }
    else if (buffer->type != MATE_TYPE_NONE) {
      uint8_t i;
      dest->type = MATE_TYPE_INTEGER;
      dest->value.var = buffer->entries[bufferIndex];
      for (i = bufferIndex; i < (buffer->size - 1); i++) {
	buffer->entries[i] = buffer->entries[i+1];
      }
      buffer->size--;
      return SUCCESS;
    }
    else {
      dbg(DBG_ERROR, "VM: Tried to get entry from buffer of unknown type!\n");
      return FAIL;
    }
    return FAIL;
  }

  command result_t Buffer.set(MateContext* context,
			      MateDataBuffer* buffer,
			      uint8_t bufferIndex,
			      MateStackVariable* src) {

    if (bufferIndex >= MATE_BUF_LEN) {
      call Error.error(context, MATE_ERROR_INDEX_OUT_OF_BOUNDS);
    }
    if (call Buffer.checkAndSetTypes(context, buffer, src) == FAIL) {
      dbg(DBG_ERROR, "VM: Tried to set entry in buffer of wrong type!\n");
      return FAIL;
    }
    else if (bufferIndex > buffer->size) {
      int i;
      for (i = buffer->size; i < bufferIndex; i++) {
	buffer->entries[i] = 0;
      }
    }
    buffer->entries[bufferIndex] = src->value.var;
    
    if (buffer->size <= bufferIndex) {
      buffer->size = bufferIndex + 1;
    }
    return SUCCESS;
  }


  
  command result_t Buffer.sortAscending(MateContext* context,
					MateDataBuffer* buffer) {
    uint8_t i, j;
    int16_t val;
    uint8_t num = buffer->size;
    uint8_t best;
    for (i = 0; i < num; i++) {
      val = buffer->entries[(int)i];
      best = i;
      for (j = i + 1; j < num; j++) {
	if (buffer->entries[(int)j] < val) {
	  best = j;
	  val = buffer->entries[(int)j];
	}
      }
      if (best != i) {
	buffer->entries[(int)best] = buffer->entries[(int)i];
	buffer->entries[(int)i] = val;
      }
    }
    return SUCCESS;
  }

  command result_t Buffer.sortDescending(MateContext* context,
					 MateDataBuffer* buffer) {
    uint8_t i, j;
    int16_t val;
    uint8_t num = buffer->size;
    uint8_t best;
    for (i = 0; i < num; i++) {
      val = buffer->entries[(int)i];
      best = i;
      for (j = i + 1; j < num; j++) {
	if (buffer->entries[(int)j] > val) {
	  best = j;
	  val = buffer->entries[(int)j];
	}
      }
      if (best != i) {
	buffer->entries[(int)best] = buffer->entries[(int)i];
	buffer->entries[(int)i] = val;
      }
    }
    return SUCCESS;
  }

  command result_t BufferType.encode(MateNetworkStruct* dest, void* src) {
    uint8_t len;
    MateDataBuffer* buf = (MateDataBuffer*)src;

    len = (uint8_t) offsetof(MateDataBuffer, entries); // Metadata 
    len += (buf->size * sizeof(buf->entries[0])); // Data
    dest->length = len;
    memcpy(dest->data, src, len);
    return SUCCESS;
  }

  command result_t BufferType.decode(void* dest, MateNetworkStruct* msg, uint8_t destLen) {
    uint8_t len = msg->length;
    if (len > destLen) {
      dbg(DBG_USR1|DBG_ERROR, "MBuffer: Tried to decode a buffer of length %i into too small a memory region, of length %i.\n", (int)len, (int)destLen);
      return FAIL;
    }
    memcpy(dest, msg->data, len);
    return SUCCESS;
  }

  command uint8_t BufferType.length(void* resource) {
    uint8_t len;
    MateDataBuffer* buf = (MateDataBuffer*)resource;
    len = (uint8_t) offsetof(MateDataBuffer, entries); // Metadata 
    len += (buf->size * sizeof(buf->entries[0])); // Data
    return len;
  }

  command uint8_t BufferType.allocationSize() {
    return sizeof(MateDataBuffer);
  }

  command bool BufferType.supported() {
    return TRUE;
  }
  
}

