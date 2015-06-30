/*									tab:4
 * mate_buffer.c - Buffer functions.
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:   Philip Levis
 * History:   created 4/18/2002
 */


void buffer_clear(vm_buffer* buffer) {
  int i;
  buffer->size = 0;
  buffer->type = MATE_DATA_NONE;
  for (i = 0; i < MATE_BUF_MAX; i++) {
    buffer->entries[i] = 0;
  }
}

char buffer_check_type(vm_buffer* buffer, stack_var* arg) {
  char arg_type = MATE_DATA_NONE;
  dbg(DBG_USR1, ("VM: Check buffer type %i against %i\n", buffer->type, arg->type));
  if (arg->type == MATE_TYPE_VALUE) {arg_type = MATE_DATA_VALUE;}
  else if (arg->type == MATE_TYPE_SENSE) {arg_type = arg->sense.type;}
  if (buffer->type == MATE_DATA_NONE) {
    dbg(DBG_USR1, ("VM: Setting buffer type from %i to %i\n", (int)buffer->type, (int)arg->type));
    buffer->type = arg_type;
    return 1;
  }
  else if (buffer->type == arg_type) {
    return 1;
  }
  else { // Neither a clear nor a properly typed buffer
    return 0;
  }
}

char buffer_append(vm_buffer* buffer, stack_var* arg) {
  if (buffer->size >= MATE_BUF_MAX) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to append to a full buffer!\n"));
    return 8;
  }
  else if (arg->type == MATE_TYPE_VALUE) {
    buffer->entries[(int)buffer->size] = arg->value.var;
    buffer->size++;
  }
  else if (arg->type == MATE_TYPE_SENSE) {
    buffer->entries[(int)buffer->size] = arg->sense.var;
    buffer->size++;
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried appending invalid variable to buffer!: Buffer type: %i, var type: %i\n", buffer->type, arg->type));
    return 9;
  }
  return 0;
}

char buffer_prepend(vm_buffer* buffer, stack_var* arg) {
  if (!buffer_check_type(buffer, arg)) {
    return 12;
  }
  if (buffer->size >= MATE_BUF_MAX) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to prepend to a full buffer!\n"));
    return 8;
  }
  else if (arg->type == MATE_TYPE_VALUE) {
    char i;
    for (i = buffer->size; i > 0; i--) {
      buffer->entries[(int)i] = buffer->entries[(int)i - 1];
    }
    buffer->entries[0] = arg->value.var;
    buffer->size++;
  }
  else if (arg->type == MATE_TYPE_SENSE) {
    char i;
    for (i = buffer->size; i > 0; i--) {
      buffer->entries[(int)i] = buffer->entries[(int)i - 1];
    }
    buffer->entries[0] = arg->sense.var;
    buffer->size++;
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried prepending invalid variable to buffer!: Buffer type: %i, var type: %i\n", buffer->type, arg->type));
    return 9;
  }
  return 0;
}

stack_var* buffer_get(vm_buffer* buffer, int index) {
  VAR(tmp).type = MATE_TYPE_VALUE;
  VAR(tmp).value.var = 0;
  if (index < 0 || index >= buffer->size) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Access out of bounds index on buffer: %i!\n", index));
  }
  else if (buffer->type == MATE_DATA_VALUE) {
    VAR(tmp).type = MATE_TYPE_VALUE;
    VAR(tmp).value.var = buffer->entries[index];
  }
  else if (buffer->type == MATE_DATA_PHOTO || buffer->type == MATE_DATA_TEMP) {
    VAR(tmp).type = MATE_TYPE_SENSE;
    VAR(tmp).sense.type = buffer->type;
    VAR(tmp).sense.var = buffer->entries[index];
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to get entry from buffer of unknown type!\n"));
  }
  return &VAR(tmp);
}

stack_var* buffer_yank(vm_buffer* buffer, int index) {
  VAR(tmp).type = MATE_TYPE_VALUE;
  VAR(tmp).value.var = 0;
  if (index < 0 || index >= buffer->size) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Access out of bounds index on buffer: %i!\n", index));
  }
  else if (buffer->type == MATE_DATA_VALUE) {
    int i;
    VAR(tmp).type = MATE_TYPE_VALUE;
    VAR(tmp).value.var = buffer->entries[index];
    for (i = index; i < (buffer->size - 1); i++) {
      buffer->entries[i] = buffer->entries[i+1];
    }
    buffer->size--;
  }
  else if (buffer->type == MATE_DATA_PHOTO || buffer->type == MATE_DATA_TEMP) {
    int i;
    VAR(tmp).type = MATE_TYPE_SENSE;
    VAR(tmp).sense.type = buffer->type;
    VAR(tmp).sense.var = buffer->entries[index];
    for (i = index; i < (buffer->size - 1); i++) {
      buffer->entries[i] = buffer->entries[i+1];
    }
    buffer->size--;
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to get entry from buffer of unknown type!\n"));
  }
  return &VAR(tmp);
}


/* Takes a buffer and sorts it in ascending order -- the first element
 * of the buffer will be the lowest, and the last will be the highest.
 * */

void buffer_sorta(vm_buffer* buffer) {
  char i, j;
  short val;
  char num = buffer->size;
  char best;
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
}

/* Takes a buffer and sorts it in descending order -- the first
 * element of the buffer will be the highest, and the last will be the
 * lowest.  */

void buffer_sortd(vm_buffer* buffer) {
  char i, j;
  short val;
  char num = buffer->size;
  char best;
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
}
