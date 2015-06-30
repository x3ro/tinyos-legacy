/*									tab:4
 * mate_util.c - Mate utility functions.
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
 * mate_util.c only defines two functions -- the rest are broken up into
 * additional files.
 */

#include "list.h"

void haltContext(context_t* context);

void enter_error_state(context_t* context, char reason) {
  dbg(DBG_ERROR|DBG_USR1, ("VM: ENTERING ERROR STATE %hhi!\n", reason));
  VAR(errorContext) = context;
  VAR(errorInstr) = context->pc - 1;
  VAR(errorCapsule) = context->code->capsule.type;
  VAR(errorVersion) = context->code->capsule.version;
  VAR(errorReason) = reason;
  TOS_CALL_COMMAND(VM_LEDr_off)();
  TOS_CALL_COMMAND(VM_LEDg_off)();
  TOS_CALL_COMMAND(VM_LEDy_off)();
  context->state = STATE_HALT;
  haltContext(context);
  return;
}


inline char check_types(context_t* context, stack_var* var, char types) {
  char rval = (char)(var->type & types);
  if (!rval) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Operand failed type check: type = %i, allowed types = %i\n", (int)var->type, (int)types));
    enter_error_state(context, (var->type << 4) | types | 0x80);
  }
  return rval;
}

static inline char mqueue_empty(mate_queue* mq) {
  return (char)list_empty(&mq->queue);
}


void mqueue_enqueue(context_t* exec, mate_queue* queue, context_t* context) {
  //dbg(DBG_USR3, ("VM: Enqueuing context %hhi on queue.\n", context->which));
  if (context->queue) {enter_error_state(context, ERROR_QUEUE_ENQUEUE);}
  context->queue = queue;
  list_insert_head(&queue->queue, &context->link);
}

context_t* mqueue_dequeue(context_t* exec, mate_queue* queue) {
  context_t* context;
  list_link_t* link;

  if (list_empty(&queue->queue)) {
    return 0;
  }
  
  link = queue->queue.l_prev;
  context = list_item(link, context_t, link);
  list_remove(link);
  context->link.l_next = 0;
  context->link.l_prev = 0;
  context->queue = NULL;
  //dbg(DBG_USR3, ("VM: Dequeuing context %hhi from queue.\n", context->which));
  return context;
}

void mqueue_remove(context_t* exec, mate_queue* queue, context_t* context) {
  if (context->queue != queue) {
    enter_error_state(exec, ERROR_QUEUE_REMOVE);
  }
  context->queue = NULL;
  if (!(context->link.l_next && context->link.l_prev)) {
    enter_error_state(exec, ERROR_QUEUE_REMOVE);
  }
  else {
    list_remove(&context->link);
  }
}


#include "mate_stacks.c"
#include "mate_buffer.c"
#include "mate_locks.c"
#include "mate_synch.c"
#include "mate_comm.c"
