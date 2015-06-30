/*									tab:4
 * mate_stacks.c - Functions for manipulating Mate stacks.
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
 * History:   created 3/23/2002
 *
 * Utility functions for Mate.
 */

void push_value_operand(context_t* c, short x) {
  if (c->stack.sp >= MATE_MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to push off end of stack.\n"));
    enter_error_state(c, ERROR_STACK_OVERFLOW);
    return;
  }
  c->stack.stack[(int)c->stack.sp].type = MATE_TYPE_VALUE;
  c->stack.stack[(int)c->stack.sp].value.var = x;
  c->stack.sp++;
}

void push_buffer_operand(context_t* c, vm_buffer* ptr) {
  if (c->stack.sp >= MATE_MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to push off end of stack.\n"));
    enter_error_state(c, ERROR_STACK_OVERFLOW);
    return;
  }
  c->stack.stack[(int)c->stack.sp].type = MATE_TYPE_BUFFER;
  c->stack.stack[(int)c->stack.sp].buf.var = ptr;
  c->stack.sp++;
}

void push_sense_operand(context_t* c, char type, short val) {
  if (c->stack.sp >= MATE_MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to push off end of stack.\n"));
    enter_error_state(c, ERROR_STACK_OVERFLOW);    
    return;
  }
  c->stack.stack[(int)c->stack.sp].type = MATE_TYPE_SENSE;
  c->stack.stack[(int)c->stack.sp].sense.var = val;
  c->stack.stack[(int)c->stack.sp].sense.type = type;
  c->stack.sp++;
}

void push_operand(context_t* c, stack_var* op) {
  if (c->stack.sp >= MATE_MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to push off end of stack.\n"));
    enter_error_state(c, ERROR_STACK_OVERFLOW);    
    return;
  }
  c->stack.stack[(int)c->stack.sp] = *op;
  c->stack.sp++;
}

stack_var* pop_operand(context_t* c) {
  stack_var* val;
  c->stack.sp--;
  if (c->stack.sp < 0) {
    c->stack.sp = 0;
    dbg(DBG_ERROR, ("VM: Tried to pop off end of stack.\n"));
    c->stack.stack[0].type = MATE_TYPE_INVALID;
    enter_error_state(c, ERROR_STACK_UNDERFLOW);
    return &(c->stack.stack[0]);
  }
  val = &(c->stack.stack[(int)c->stack.sp]);
  return val;
}

void push_return_addr(context_t* context) {
  return_stack* rstack = &(context->rstack);
  if (rstack->sp >= MATE_CALLDEPTH) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried calling to a depth greater than %i, the max supported.\n", (int)MATE_CALLDEPTH));
    enter_error_state(context, ERROR_RSTACK_OVERFLOW);
    return;
  }
  rstack->stack[(int)rstack->sp].code = context->code;
  rstack->stack[(int)rstack->sp].pc = context->pc;
  rstack->sp++;
  dbg(DBG_USR1, ("VM: Pushing %hhx,%hhx onto return stack.\n", context->code->capsule.type, context->pc));
}

void pop_return_addr(context_t* context) {
  return_stack* rstack = &(context->rstack);
  return_var* rval;
  if (rstack->sp <= 0) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to pop return site off empty stack!\n"));
    rval = &(rstack->stack[0]);
    rval->code = context->code;
    rval->pc = 0;
    enter_error_state(context, ERROR_RSTACK_UNDERFLOW);
  }
  else {
    rstack->sp--;
    rval = &(rstack->stack[(int)rstack->sp]);
  }
  context->code = rval->code;
  context->pc = rval->pc;
}
