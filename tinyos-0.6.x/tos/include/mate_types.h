/*									tab:4
 * mate_types.h - Data structure types and constants used in Mate.
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
 *
 */

#ifndef MATE_TYPES_H_INCLUDED

#include "list.h"
#include <stddef.h>

#define MATE_HEADERSIZES         4
#define MATE_HEADERSIZE          (MATE_HEADERSIZES << 1)
#define MATE_CALLDEPTH           8
#define MATE_MEMSIZE            16

#define MATE_ERROR               ((char)0x1d)
#define MATE_CAPSULE             ((char)0x1e)
#define MATE_RAW                 ((char)0x1f)

#define MATE_DATA_NONE          -1
#define MATE_DATA_VALUE          0
#define MATE_DATA_PHOTO          1
#define MATE_DATA_TEMP           2

#define MATE_TYPE_INVALID        0
#define MATE_TYPE_VALUE          1
#define MATE_TYPE_BUFFER         2
#define MATE_TYPE_SENSE          4

#define MATE_BUF_MAX            10
#define MATE_HEAPSIZE           16
#define MATE_MAX_PARALLEL        4

#define NUM_YIELDS               4

#define PGMSIZE 24

#define CAPSULE_FORW           0x1


/* Types of capsules */
#define CAPSULE_NUM   7 /* How many capsules there are */
#define CAPSULE_SUB0  0
#define CAPSULE_SUB1  1
#define CAPSULE_SUB2  2
#define CAPSULE_SUB3  3
#define CAPSULE_CLOCK 4
#define CAPSULE_SEND  5
#define CAPSULE_RECV  6

#define ERROR_TRIGGERED                   0
#define ERROR_INVALID_RUNNABLE            1
#define ERROR_STACK_OVERFLOW              2
#define ERROR_STACK_UNDERFLOW             3  
#define ERROR_BUFFER_OVERFLOW             4
#define ERROR_BUFFER_UNDERFLOW            5
#define ERROR_INDEX_OUT_OF_BOUNDS         6
#define ERROR_INSTRUCTION_RUNOFF          7
#define ERROR_LOCK_OVERFLOW               8
#define ERROR_LOCK_STEAL                  9
#define ERROR_UNLOCK_INVALID             10
#define ERROR_QUEUE_ENQUEUE              11
#define ERROR_QUEUE_REMOVE               12
#define ERROR_RSTACK_OVERFLOW            13
#define ERROR_RSTACK_UNDERFLOW           14  
#define ERROR_INVALID_ACCESS             15

typedef struct {
  list_t queue;
} mate_queue;

typedef struct {
  char type;
  char version;
  char length;
  char options;
  char code[PGMSIZE];
} capsule_t;

typedef struct {
  short usedVars;
  capsule_t capsule;
} capsule_buf;

typedef struct {
  char type;
  char size;
  short entries[MATE_BUF_MAX];
} vm_buffer;

typedef struct {
  char header[MATE_HEADERSIZE];
  vm_buffer payload;
} vm_packet;

typedef struct {
  char type;
  short var;
} sense_var;

typedef struct {
  char padding;
  short var;
} value_var;

typedef struct {
  char padding;
  vm_buffer* var;
} buffer_var;

typedef struct {
  char type;
  union {
    sense_var sense;
    value_var value;
    buffer_var  buf;
  };
} stack_var;

typedef struct {
  capsule_buf* code;
  char pc;
} return_var;

typedef struct {
  char sp;
  return_var stack[MATE_CALLDEPTH];
} return_stack;

typedef struct {
  char sp;
  stack_var stack[MATE_MEMSIZE];
} op_stack;
   	 
typedef struct {
  char pc;
  char state;
  capsule_buf* code;
  char which;
  short condition;
  short heldSet;
  short relinquishSet;
  short acquireSet;
  short header[MATE_HEADERSIZES];
  op_stack stack;
  return_stack rstack;
  list_link_t link;
  mate_queue* queue;
} context_t;

typedef struct {
  //char size;
  context_t* holder;
} lock_t;

char TOS_COMMAND(VM_RUN)(context_t* context);

void reset_context(context_t* context);

void push_value_operand(context_t* context, short val);
void push_sense_operand(context_t* context, char type, short val);
void push_buffer_operand(context_t* context, vm_buffer* ptr);
void push_operand(context_t* context, stack_var* op);
stack_var* pop_operand(context_t* c);

void buffer_clear(vm_buffer* buffer);
char buffer_append(vm_buffer* buffer, stack_var* arg);
char buffer_prepend(vm_buffer* buffer, stack_var* arg);
stack_var* buffer_get(vm_buffer* buffer, int index);

// Uses a static variable -- calling twice will destroy first value
stack_var* buffer_yank(vm_buffer* buffer, int index);



#endif // MATE_TYPES_H_INCLUDED
