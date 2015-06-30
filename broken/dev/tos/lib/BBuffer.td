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
/*
 * Authors:   Philip Levis
 * History:   July 19, 2002
 *	     
 *
 */

includes Bombilla;

module BBuffer {
  provides interface BombillaBuffer as Buffer;
  uses interface BombillaError;
}


implementation {

  command result_t Buffer.clear(BombillaContext* context, 
				BombillaDataBuffer* buffer) {
    int i;
    buffer->size = 0;
    buffer->type = BOMB_DATA_NONE;
    for (i = 0; i < BOMB_BUF_LEN; i++) {
      buffer->entries[i] = 0;
    }
    return SUCCESS;
  }

  command result_t Buffer.checkAndSetTypes(BombillaContext* context, 
					   BombillaDataBuffer* buffer, 
					   BombillaStackVariable* var) {
    BombillaSensorType type = BOMB_DATA_NONE;
    dbg(DBG_USR1, "VM: Check buffer type %i against %i\n", (int)buffer->type, (int)var->type);
    if (var->type == BOMB_TYPE_VALUE) {
      type = BOMB_DATA_VALUE;
    }
    else if (var->type == BOMB_TYPE_SENSE) {
      type = var->sense.type;
    }
    // If it's a clean buffer, set its type
    if (buffer->type == BOMB_DATA_NONE) {
      buffer-> type = type;
      return SUCCESS;
    }
    else if (buffer->type == type) {
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command result_t Buffer.append(BombillaContext* context,
				 BombillaDataBuffer* buffer,
				 BombillaStackVariable* var) {
    if (buffer->size >= BOMB_BUF_LEN) {
      dbg(DBG_ERROR, "VM: Data buffer overrun.\n");
      call BombillaError.error(context, BOMB_ERROR_BUFFER_OVERFLOW);
      return FAIL;
    }
    if (call Buffer.checkAndSetTypes(context, buffer, var) == FAIL) {
      call BombillaError.error(context, BOMB_ERROR_TYPE_CHECK);
      return FAIL;
    }
    if (var->type == BOMB_TYPE_VALUE) {
      buffer->entries[(int)buffer->size] = var->value.var;
      buffer->size++;
      return SUCCESS;
    }
    else if (var->type == BOMB_TYPE_SENSE) {
      buffer->entries[(int)buffer->size] = var->sense.var;
      buffer->size++;
      return SUCCESS;
    }
    else {
      dbg(DBG_USR1, "VM: Buffers only contain values or readings.\n");
      return FAIL;
    }
  } 

  command uint8_t Buffer.concatenate(BombillaContext* context,
				     BombillaDataBuffer* dest,
				     BombillaDataBuffer* src) {
    if (dest->type != src->type) {
      call BombillaError.error(context, BOMB_ERROR_INVALID_TYPE);
      return FAIL;
    }
    else {
      uint8_t i;
      uint8_t start;
      uint8_t end;
      BombillaStackVariable var;

      start = dest->size;
      end = start + src->size;
      end = (end > BOMB_BUF_LEN)? BOMB_BUF_LEN:end;
      for (i = start; i < end; i++) {
	call Buffer.get(context, src, i - start, &var);
	call Buffer.append(context, dest, &var);
      }
      return (start + src->size) - end;
    }
  }
  command result_t Buffer.prepend(BombillaContext* context,
				  BombillaDataBuffer* buffer, 
				  BombillaStackVariable* var) {
    if (buffer->size >= BOMB_BUF_LEN) {
      dbg(DBG_ERROR, "VM: Data buffer overrun.\n");
      call BombillaError.error(context, BOMB_ERROR_BUFFER_OVERFLOW);
      return FAIL;
    }
    if (call Buffer.checkAndSetTypes(context, buffer, var) == FAIL) {
      return FAIL;
    }
    if (var->type == BOMB_TYPE_VALUE) {
      uint8_t i;
      for (i = buffer->size; i > 0; i--) {
	buffer->entries[(int)i] = buffer->entries[(int)i - 1];
      }
      buffer->entries[0] = var->value.var;
      buffer->size++;
      return SUCCESS;
    }
    else if (var->type == BOMB_TYPE_SENSE) {
      uint8_t i;
      for (i = buffer->size; i > 0; i--) {
	buffer->entries[(int)i] = buffer->entries[(int)i - 1];
      }
      buffer->entries[0] = var->sense.var;
      buffer->size++;
      return SUCCESS;
    }
    else {
      dbg(DBG_USR1, "VM: Buffers only contain values or readings.\n");
      return FAIL;
    }
  }

  command result_t Buffer.get(BombillaContext* context,
			      BombillaDataBuffer* buffer, 
			      uint8_t bufferIndex,
			      BombillaStackVariable* dest){
    if (bufferIndex >= buffer->size) {
      dbg(DBG_ERROR, "VM: Index %i out of bounds on buffer of size %i.\n", (int)buffer->size, (int)bufferIndex);
      call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
      return FAIL;
    }
    else if (buffer->type == BOMB_DATA_VALUE) {
      dest->type = BOMB_TYPE_VALUE;
      dest->value.var = buffer->entries[bufferIndex];
      return SUCCESS;
    }
    else if (buffer->type > BOMB_DATA_VALUE && 
	     buffer->type < BOMB_DATA_END) {
      dest->type = BOMB_TYPE_SENSE;
      dest->sense.type = buffer->type;
      dest->sense.var = buffer->entries[bufferIndex];
      return SUCCESS;
    }
    else {
      dbg(DBG_ERROR, "VM: Tried to get entry from buffer of unknown type!\n");
      return FAIL;
    }
  }



  command result_t Buffer.yank(BombillaContext* context,
			       BombillaDataBuffer* buffer, 
			       uint8_t bufferIndex,
			       BombillaStackVariable* dest) {
    if (bufferIndex >= buffer->size) {
      dbg(DBG_ERROR, "VM: Index %i out of bounds on buffer of size %i.\n", (int)buffer->size, (int)bufferIndex);
      call BombillaError.error(context, BOMB_ERROR_INDEX_OUT_OF_BOUNDS);
      return FAIL;
    }
    else if (buffer->type == BOMB_DATA_VALUE) {
      uint8_t i;
      dest->type = BOMB_TYPE_VALUE;
      dest->value.var = buffer->entries[bufferIndex];
      for (i = bufferIndex; i < (buffer->size - 1); i++) {
	buffer->entries[i] = buffer->entries[i+1];
      }
      buffer->size--;
      return SUCCESS;
    }
    else if (buffer->type > BOMB_DATA_VALUE && 
	     buffer->type < BOMB_DATA_END) {
      uint8_t i;
      dest->type = BOMB_TYPE_SENSE;
      dest->sense.type = buffer->type;
      dest->sense.var = buffer->entries[bufferIndex];
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

  command result_t Buffer.sortAscending(BombillaContext* context,
					BombillaDataBuffer* buffer) {
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

  command result_t Buffer.sortDescending(BombillaContext* context,
					 BombillaDataBuffer* buffer) {
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
}

