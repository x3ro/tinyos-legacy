/*									tab:4
 * VM2.c - simple byte-code interpreter, 2nd edition
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * History:   created 2/23/2002
 *
 * A simple virtual machine for TinyOS.
 */

#include "tos.h"
#include "VM2.h"
#include "tos-vm2.h"
#include "dbg.h"

#define VM_CAPSULE    ((char)0x1e)
#define VM_RAW        ((char)0x1f)
#define FRAMESIZES               4
#define FRAMESIZE      (FRAMESIZES * 2)
#define HEADERSIZES              4
#define HEADERSIZE    (HEADERSIZES * 2)
#define CALLDEPTH                8

#define LOGSIZE                 16
#define MEMSIZE                 16

#define DATA_PHOTO               1
#define DATA_TEMP                2

#define VAR_INVALID              0
#define VAR_VALUE                1
#define VAR_MSG                  2
#define VAR_SENSE                3

#define STATE_HALT               0
#define STATE_RUN                1
#define STATE_DATA_WAIT          2
#define STATE_PACKET_WAIT        3
#define STATE_PACKET_SEND        4
#define STATE_CAPSULE_SEND       5
#define STATE_LOG_WAIT           6

#define PACKET_MAX_ENTRIES       5

#define SENSE_TYPE_VALUE        -1

typedef struct {
  char type;
  char id;
  short value;
} msg_entry;

typedef struct {
  char num_entries;
  msg_entry entries[PACKET_MAX_ENTRIES];
} vm_msg;

typedef struct {
  char header[HEADERSIZE];
  vm_msg payload;
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
  vm_msg* var;
} msg_var;

typedef struct {
  char type;
  union {
    sense_var sense;
    value_var value;
    msg_var   msg;
  };
} stack_var;

typedef struct {
  char code;
  char pc;
} return_var;

typedef struct {
  char sp;
  return_var stack[CALLDEPTH];
} return_stack;

typedef struct {
  char pc;
  char sp;
  char state;
  char code;
  char which;
  stack_var stack[MEMSIZE];
  short header[HEADERSIZES];
  return_stack rstack;
} stack_t;

#define TOS_FRAME_TYPE INTERP_frame
TOS_FRAME_BEGIN(INTERP_frame) {
  char sense_type;
  char logBufCount;
  char logBuffer[LOGSIZE];

  short frame[FRAMESIZES];

  char clockCounter;
  char clockTrigger;

  char sendStackActive;
  char recvStackActive;
  
  stack_var shared_var;
  
  capsule_t code[CAPSULE_NUM];
  stack_t clock_stack;
  stack_t send_stack;
  stack_t recv_stack;

  stack_t* log_waiting_stack;
  stack_t* send_waiting_stack;
  stack_t* adc_waiting_stack;
  
  vm_msg buffer;
  TOS_Msg capsule_msg;
  TOS_MsgPtr capsule_msg_ptr;
  TOS_Msg raw_packet;
}
TOS_FRAME_END(INTERP_frame);

void push_constant(stack_t* s, short x) {
  if (s->sp >= MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to run off end of stack.\n"));
    return;
  }
  s->stack[(int)s->sp].type = VAR_VALUE;
  s->stack[(int)s->sp].value.var = x;
  s->sp++;
}

void push_message(stack_t* s, vm_msg* ptr) {
  if (s->sp >= MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to run off end of stack.\n"));
    return;
  }
  s->stack[(int)s->sp].type = VAR_MSG;
  s->stack[(int)s->sp].msg.var = ptr;

  s->sp++;
}

void push_sense(stack_t* s, char type, short val) {
  if (s->sp >= MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to run off end of stack.\n"));
    return;
  }
  s->stack[(int)s->sp].type = VAR_SENSE;
  s->stack[(int)s->sp].sense.var = val;
  s->stack[(int)s->sp].sense.type = type;
  s->sp++;
}

stack_var* pop(stack_t* s) {
  stack_var* val;
  s->sp--;
  if (s->sp < 0) {
    s->sp = 0;
    dbg(DBG_ERROR, ("VM: Tried to pop off end of stack.\n"));
    s->stack[0].type = VAR_INVALID;
    return &(s->stack[0]);
  }
  val = &(s->stack[(int)s->sp]);
  return val;
}

void push_call(stack_t* s) {
  return_stack* rstack = &(s->rstack);
  if (rstack->sp >= CALLDEPTH) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried calling to a depth greater than %i, the max supported.\n", (int)CALLDEPTH));
    return;
  }
  rstack->stack[(int)rstack->sp].code = s->code;
  rstack->stack[(int)rstack->sp].pc = s->pc;
  rstack->sp++;
  dbg(DBG_USR1, ("VM: Pushing %hhx,%hhx onto return stack.\n", s->code, s->pc));
}

void pop_call(stack_t* stack) {
  return_stack* rstack = &(stack->rstack);
  return_var* rval;
  if (rstack->sp <= 0) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to pop return site off empty stack!\n"));
    rval = &(rstack->stack[0]);
  }
  else {
    rstack->sp--;
    rval = &(rstack->stack[(int)rstack->sp]);
  }
  stack->code = rval->code;
  stack->pc = rval->pc;
}

void reset_stack(stack_t* stack) {
  stack->pc = 0;
  stack->sp = 0;
  stack->rstack.sp = 0;
  stack->state = STATE_HALT;
}

void process_user_intr(stack_t* stack, char instr) {
  switch(instr) {
  case OPusr0:
  case OPusr1:
  case OPusr2:
  case OPusr3:
  case OPusr4:
  case OPusr5:
  case OPusr6:
  case OPusr7:
  default:
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried executing non-existent user instruction!\n"));
  }
  return;
}


void logAppend(stack_t* stack, char* data, char len) {
  char rval;
  if ((len + VAR(logBufCount)) > LOGSIZE) {
    dbg(DBG_USR1, ("VM: Write over log boundary. Flush, then reexecute instruction.\n"));
    rval = TOS_CALL_COMMAND(VM_SUB_LOG_WRITE)(VAR(logBuffer));
    if (rval) {
      stack->state = STATE_LOG_WAIT;
      VAR(log_waiting_stack) = stack;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log write failed! Retrying.\n"));
    }
    stack->pc--; // Reexecute the instruction either on log flush or immediately
  } else if ((len + VAR(logBufCount) == LOGSIZE)) {
    int i;
    dbg(DBG_USR1, ("VM: Write on log boundary. Flush.\n"));
    for (i = 0; i < len; i++) {
      VAR(logBuffer)[(int)VAR(logBufCount)] = data[i];
      VAR(logBufCount)++;
    }
    rval = TOS_CALL_COMMAND(VM_SUB_LOG_WRITE)(VAR(logBuffer));
    if (rval) {
      stack->state = STATE_LOG_WAIT;
      VAR(log_waiting_stack) = stack;
    }
    else {
      VAR(logBufCount) -= len; // Don't want to enter data twice
      stack->pc--;
    }
  } else {
    int i;
    dbg(DBG_USR1, ("VM: Write into log buffer.\n"));
    for (i = 0; i < len; i++) {
      VAR(logBuffer)[(int)VAR(logBufCount)] = data[i];
      VAR(logBufCount)++;
    }
  }
  
}

char forward_capsule(char codeNum) {
  int i;
  char rval;
  capsule_t* capsule = (capsule_t*)(VAR(capsule_msg_ptr)->data);
  dbg(DBG_USR1, ("VM: Forwarding code capsule %hhi.\n", codeNum));
    
  for (i = 0; i <= PGMSIZE ; i++) {
    capsule->code[i] = VAR(code)[(int)codeNum].code[i];
  }
  capsule->version = VAR(code)[(int)codeNum].version;
  capsule->type = VAR(code)[(int)codeNum].type;
  
  rval = TOS_CALL_COMMAND(VM_SUB_SEND_CAPSULE)(TOS_BCAST_ADDR, (char)VM_CAPSULE, (VAR(capsule_msg_ptr)));
  return rval;
}


char TOS_COMMAND(VM_INIT)(){
  int i;
  TOS_CALL_COMMAND(VM_SUB_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(VM_SUB_CLOCK_INIT)(tick1ps);

  for (i = 0; i < CAPSULE_NUM; i++) {
    VAR(code)[i].type = i;
    VAR(code)[i].version = -1;
    VAR(code)[i].code[0] = OPhalt;
  }
  
  reset_stack(&VAR(clock_stack));
  VAR(clock_stack).code        = CAPSULE_CLOCK;
  
  reset_stack(&VAR(send_stack));
  VAR(send_stack).code         = CAPSULE_SEND;
    
  reset_stack(&VAR(recv_stack));
  VAR(recv_stack).code         = CAPSULE_RECV;
      
  VAR(logBufCount)             = 0;
  VAR(shared_var).type         = VAR_VALUE;
  VAR(shared_var).value.var    = 0;
  
  VAR(capsule_msg_ptr)         = &(VAR(capsule_msg));

  VAR(clockTrigger)            = 1;
  VAR(clockCounter)            = 0;
  VAR(sendStackActive)         = 0;

  VAR(frame)[0]                = (char)0xff;
  VAR(frame)[1]                = (char)0xff;
  VAR(frame)[2]                = (char)0x64;
  
  dbg(DBG_USR1, ("VM initialized\n"));
  return 1;
}

void LEDop(short cmd) {
  char op = (cmd >> 3) & 3;
  char led = cmd & 7;
  switch (op) {
  case 0:			/* set */
    if (led & 1) TOS_CALL_COMMAND(VM_LEDr_on)();
    else TOS_CALL_COMMAND(VM_LEDr_off)();
    if (led & 2) TOS_CALL_COMMAND(VM_LEDg_on)();
    else TOS_CALL_COMMAND(VM_LEDg_off)();
    if (led & 4) TOS_CALL_COMMAND(VM_LEDy_on)();
    else TOS_CALL_COMMAND(VM_LEDy_off)();
    break;
  case 1:			/* OFF 0 bits */
    if (!(led & 1)) TOS_CALL_COMMAND(VM_LEDr_off)();
    if (!(led & 2)) TOS_CALL_COMMAND(VM_LEDg_off)();
    if (!(led & 4)) TOS_CALL_COMMAND(VM_LEDy_off)();
    break;
  case 2:			/* on 1 bits */
    if (led & 1) TOS_CALL_COMMAND(VM_LEDr_on)();
    if (led & 2) TOS_CALL_COMMAND(VM_LEDg_on)();
    if (led & 4) TOS_CALL_COMMAND(VM_LEDy_on)();
    break;
  case 3:			/* TOGGLE 1 bits */
    if (led & 1) TOS_CALL_COMMAND(VM_LEDr_toggle)();
    if (led & 2) TOS_CALL_COMMAND(VM_LEDg_toggle)();
    if (led & 4) TOS_CALL_COMMAND(VM_LEDy_toggle)();
    break;
  default:
    dbg(DBG_ERROR, ("VM: LED command had unknown operations.\n"));
  }
}

/* VM_START command:
*/
char TOS_COMMAND(VM_START)(){
  int index = 0;
  push_constant(&(VAR(clock_stack)), 0);

  //  VAR(code)[CAPSULE_CLOCK].code[index++] = OPhalt; // Comment out this
                                                   // instr to enable program

  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPcopy;
  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPpushc | 7);
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPand;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPputled;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPcopy;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPpushm;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPclear;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPsend;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPhalt;

  /*VAR(code)[CAPSULE_CLOCK].code[index++] = OPgets;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPpushm;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPclear;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPuart;
  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPpushc | 0);
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPsets;

  VAR(code)[CAPSULE_CLOCK].code[index++] = OPgets;
  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPsets;
  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPpushc | 25);
  VAR(code)[CAPSULE_CLOCK].code[index++] = OPputled;
  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPpushc | 0);
  VAR(code)[CAPSULE_CLOCK].code[index++] = (char)(OPblez | 7);*/
  
  
  return 1;
}

/* run - run interpeter from current state
 */

TOS_TASK(run_clock);
TOS_TASK(run_send);
TOS_TASK(run_recv);

TOS_TASK(run_clock) {
  compute_instruction(&(VAR(clock_stack)));
  compute_instruction(&(VAR(clock_stack)));
  compute_instruction(&(VAR(clock_stack)));  
  if (VAR(clock_stack).state == STATE_RUN) {
    TOS_POST_TASK(run_clock);
  }
}

TOS_TASK(run_send) {
 compute_instruction(&(VAR(send_stack)));  
  if (VAR(send_stack).state == STATE_RUN) {
    TOS_POST_TASK(run_send);
  }
}

TOS_TASK(run_recv) {
  compute_instruction(&(VAR(recv_stack)));
  if (VAR(recv_stack).state == STATE_RUN) {
    TOS_POST_TASK(run_recv);
  }
}

void execute_stack(stack_t* stack) {
  if (stack == &VAR(clock_stack)) {
    TOS_POST_TASK(run_clock);
  }
  else if (stack == &VAR(send_stack)) {
    TOS_POST_TASK(run_send);
  }
  else if (stack == &VAR(recv_stack)) {
    TOS_POST_TASK(run_recv);
  }
}


char TOS_EVENT(VM_LOG_READ_EVENT)(char* data, char success) {
  stack_t* stack = VAR(log_waiting_stack);
  
  if (stack->state == STATE_LOG_WAIT) {
    stack_var* arg_one = pop(stack);
    dbg(DBG_USR1, ("VM: Log read completed. Writing into packet.\n"));
    if (success) {
      int i;
      vm_msg* msg = arg_one->msg.var;
      char* buf = (char*)msg->entries;
      for (i = 0; i < VAR(logBufCount); i++) {
	buf[i] = data[i];
      }
      msg->num_entries = PACKET_MAX_ENTRIES + 1;
      push_message(stack, msg);
    }
    stack->state = STATE_RUN;
    execute_stack(stack);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Log read returned when waiting stack was not in LOG_WAIT state.\n"));
  }
   
  return 1;
}

/*  VM_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.

    store data in frame, resume interpreter
    it should be in waitdata state
 */

char TOS_EVENT(VM_SEND_DONE)(char* msg) {
  stack_t* stack = VAR(send_waiting_stack);
  dbg(DBG_USR1, ("VM: Message send done.\n"));
  if (stack && stack->state == STATE_PACKET_SEND) {
    VAR(send_waiting_stack) = 0;
    if (((vm_msg*)msg) == &VAR(buffer)) {
      VAR(buffer).num_entries = 0;
    }
    stack->state = STATE_RUN;
    execute_stack(stack);
    dbg(DBG_USR1, ("VM: Resume execution on capsule %hhi.\n", stack->code));
  }
  return 1;
}

char TOS_EVENT(VM_CAPSULE_SEND_DONE)(TOS_MsgPtr packet) {
  stack_t* stack = VAR(send_waiting_stack);
  if (stack && stack->state == STATE_CAPSULE_SEND) {
    dbg(DBG_USR1, ("VM: Capsule send done.\n"));
    VAR(send_waiting_stack) = 0;
    stack->state = STATE_RUN;
    execute_stack(stack);
    dbg(DBG_USR1, ("VM: Resume execution on capsule %hhi.\n", stack->code));
  }
  return 1;
}

TOS_TASK(clock_task) {
  VAR(clockCounter)++;
  if (VAR(clockCounter) >= VAR(clockTrigger) && 
      (VAR(clock_stack).state == STATE_HALT ||
       VAR(clock_stack).state == STATE_RUN)) {
    VAR(clockCounter) = 0;
    VAR(clock_stack).rstack.sp = 0;
    VAR(clock_stack).pc = 0;
    VAR(clock_stack).code = CAPSULE_CLOCK;
    dbg(DBG_USR1, ("VM: Executing clock command: %i,%i.\n", (int)VAR(clockCounter), (int)VAR(clockTrigger)));

    if (VAR(clock_stack).state == STATE_HALT) {
      TOS_POST_TASK(run_clock);
      VAR(clock_stack).state = STATE_RUN;
    }
  }
  else {
    dbg(DBG_USR1, ("VM: Clock event handled, incremented counter to %i, waiting for %i\n", (int)VAR(clockCounter), (int)VAR(clockTrigger)));
  }
}

/* Clock Event Handler  */

void TOS_EVENT(VM_CLOCK_EVENT)(){
  TOS_POST_TASK(clock_task); // Launch task to make synchronous
}

TOS_TASK(write_success_task) {
  int i;
  stack_t* stack = VAR(log_waiting_stack);
  if (stack->state == STATE_LOG_WAIT) {
    VAR(log_waiting_stack) = 0;
    dbg(DBG_USR1, ("VM: Log write completed.\n"));
    stack->state = STATE_RUN;
    VAR(logBufCount) = 0;
    for (i = 0; i < LOGSIZE; i++) {
      VAR(logBuffer)[i] = (char)0;
    }
    execute_stack(stack);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Mixup with log writing stack; stored stack in improper state.\n"));
  }
}

TOS_TASK(write_fail_task) {
  int i;
  stack_t* stack = VAR(log_waiting_stack);
  if (stack->state == STATE_LOG_WAIT) {
    VAR(log_waiting_stack) = 0;
    dbg(DBG_USR1|DBG_ERROR, ("VM: Log write unsuccessful!\n"));
    stack->state = STATE_HALT;
    VAR(logBufCount) = 0;
    for (i = 0; i < LOGSIZE; i++) {
      VAR(logBuffer)[i] = (char)0;
    }
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Mixup with log writing stack; stored stack in improper state.\n"));
  }
}

char TOS_EVENT(VM_LOG_DONE_EVENT)(char success) {
  if (success) { // Launch tasks to make synchronous
    TOS_POST_TASK(write_success_task);
  }
  else {
    TOS_POST_TASK(write_fail_task);
  }
  return 1;
}


/* VM_CAPSULE_EVENT
 * 0 - len
 * 1:len-1 bytes of code
 */
TOS_MsgPtr TOS_EVENT(VM_CAPSULE_RECEIVE)(TOS_MsgPtr data){
  int i;
  capsule_t* capsule = (capsule_t*)data->data;
  char type = capsule->type;
  char version = capsule->version;
  short vdiff = version - VAR(code)[(int)type].version;
  if ((vdiff < 64 && vdiff > 0) || (vdiff < -64 && vdiff > -128)) {
    dbg(DBG_USR1, ("VM: Received new code capsule... updating.\n"));

    VAR(code)[(int)type].version = version;
    for (i = 0; i < PGMSIZE; i++) {
      VAR(code)[(int)type].code[i] = capsule->code[i];
    }
    if (type == CAPSULE_CLOCK) {
      VAR(clock_stack).state = STATE_HALT;
      VAR(clock_stack).sp = 0;
      VAR(clockCounter) = 0;
      push_constant(&VAR(clock_stack), 0);
    }
    else if (type == CAPSULE_SEND) {
      VAR(send_stack).state  = STATE_HALT;
      VAR(send_stack).sp = 0;
    }
    else if (type == CAPSULE_RECV) {
      VAR(recv_stack).state  = STATE_HALT;
      VAR(recv_stack).sp = 0;
    }
    else {
      VAR(clock_stack).state = STATE_HALT;
      VAR(clock_stack).sp = 0;
      push_constant(&VAR(clock_stack), 0);
      VAR(send_stack).state  = STATE_HALT;
      VAR(send_stack).sp = 0;
      VAR(recv_stack).state  = STATE_HALT;
      VAR(recv_stack).sp = 0;
    }
  }
  else {
    dbg(DBG_USR1, ("VM: Received new code capsule... too old.\n"));
  }
  return data;
}

TOS_MsgPtr TOS_EVENT(VM_RAW_RECEIVE)(TOS_MsgPtr msg) {
  int i;
  if (!VAR(recvStackActive)) {
    vm_packet* packet = (vm_packet*)msg->data;
    char* stack_header = (char*)(VAR(recv_stack).header);
    dbg(DBG_USR1|DBG_ROUTE, ("VM: Receive handler called.\n"));
    for (i = 0; i < HEADERSIZE; i++) {
      stack_header[i] = packet->header[i];
    }
    VAR(recv_stack).sp = 0;
    VAR(recv_stack).pc = 0;
    push_message(&(VAR(recv_stack)), &(packet->payload));
    VAR(recv_stack).state = STATE_RUN;
    execute_stack(&VAR(recv_stack));
    VAR(recvStackActive) = 1;
  }
  else {
    dbg(DBG_USR1|DBG_ROUTE, ("VM: Can't handled two receive packets at once. Droppig second one.\n"));
  }
  return msg;
}

char TOS_EVENT(VM_PHOTO_EVENT)(short data) {
  stack_t* stack = VAR(adc_waiting_stack);
  dbg(DBG_USR1, ("VM: Got photo data: %i\n", (int)data));

  if (stack->state == STATE_DATA_WAIT) {
    push_sense(stack, DATA_PHOTO, data);
    stack->state = STATE_RUN;
    execute_stack(stack);
  }
  
  return 1;
}

char TOS_EVENT(VM_TEMP_EVENT)(short data) {
  stack_t* stack = VAR(adc_waiting_stack);
  dbg(DBG_USR1, ("VM: Got temp data: %i\n", (int)data));

  if (stack->state == STATE_DATA_WAIT) {
    push_sense(stack, DATA_TEMP, data);
    stack->state = STATE_RUN;
    execute_stack(stack);
  }
  return 1;
}


void msg_sense_append(vm_msg* msg, char type, short val) {
  if (msg->num_entries < PACKET_MAX_ENTRIES) {
    int index = msg->num_entries;
    msg->entries[index].type = type;
    msg->entries[index].id = (char)(TOS_LOCAL_ADDRESS & 0xff);
    msg->entries[index].value = val;
    msg->num_entries++;
  }
}

void msg_merge(vm_msg* dest, vm_msg* source) {
  int i;
  for (i = 0; dest->num_entries < PACKET_MAX_ENTRIES && i < source->num_entries; i++) {
    int index = dest->num_entries;
    dest->entries[index].type = source->entries[i].type;
    dest->entries[index].id = source->entries[i].id;
    dest->entries[index].value = source->entries[i].value;
    dest->num_entries++;
  }
}

char are_equal(stack_var* one, stack_var* two) {
  if (one->type != two->type) {
    dbg(DBG_USR1, ("VM: Different types. Not equal.\n"));
    return 0;
  }
  if (one->type == VAR_SENSE) {
    if (one->sense.type != two->sense.type) {
      dbg(DBG_USR1, ("VM: Different sensor types. Not equal.\n"));
      return 0;
    }
    else if (one->sense.var != two->sense.var) {
      dbg(DBG_USR1, ("VM: Different values %i != %i.\n", (int)one->sense.var, (int)two->sense.var));
      return 0;
    }
    else {
      return 1;
    }
  }
  else if (one->type == VAR_VALUE) {
    dbg(DBG_USR1, ("VM: Values %i,%i.\n", (int)one->sense.var, (int)two->sense.var));
    return (one->value.var == two->value.var);
  }
  else if (one->type == VAR_MSG) {
    return (one->msg.var == two->msg.var);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried testing equality on unrecognized (but matching) types!\n"));
    return 0;
  }
}

void execute_add(stack_t* stack) {
  stack_var* arg_one = pop(stack);
  stack_var* arg_two = pop(stack);
  if (arg_one->type == VAR_SENSE) {
    if (arg_two->type == VAR_SENSE) {
      if (arg_one->sense.type != arg_two->sense.type) {
	dbg(DBG_USR1, ("VM: Tried to combine incompatible sensor values.\n"));
	push_sense(stack, arg_one->sense.type, arg_one->sense.var);
      }
      else {
	short newval;
	newval = arg_one->sense.var + arg_two->sense.var;
	push_sense(stack, arg_one->sense.type, newval);
      }
    }
    else if (arg_two->type == VAR_VALUE) {
      push_sense(stack, arg_one->sense.type, arg_one->sense.var + arg_two->value.var);
    }
    else if (arg_two->type == VAR_MSG) {
      msg_sense_append(arg_two->msg.var, arg_one->sense.type, arg_one->sense.var);
      push_message(stack, arg_two->msg.var);
    }
  }
  else if (arg_one->type == VAR_MSG) {
    if (arg_two->type == VAR_SENSE) {
      msg_sense_append(arg_one->msg.var, arg_two->sense.type, arg_two->sense.var);
      push_message(stack, arg_one->msg.var);
    }
    else if (arg_two->type == VAR_VALUE) {
      msg_sense_append(arg_one->msg.var, SENSE_TYPE_VALUE, arg_two->value.var);
      push_message(stack, arg_one->msg.var);
    }
    else if (arg_two->type == VAR_MSG) {
      msg_merge(arg_one->msg.var, arg_two->msg.var);
      push_message(stack, arg_one->msg.var);
    }
  }
  else if (arg_one->type == VAR_VALUE) {
    if (arg_two->type == VAR_SENSE) {
      push_sense(stack, arg_two->sense.type, (arg_two->sense.var + arg_one->value.var));
    }
    else if (arg_two->type == VAR_VALUE) {
      push_constant(stack, arg_two->value.var + arg_one->value.var);
    }
    else if (arg_two->type == VAR_MSG) {
      msg_sense_append(arg_two->msg.var, SENSE_TYPE_VALUE, arg_one->value.var);
      push_message(stack, arg_two->msg.var);
    }
  }
  else {
    dbg(DBG_ERROR, ("VM: Tried adding unknown types!\n"));
  }
  return;
}

void execute_sendr(stack_t* stack) {
  stack_var* arg_one;
  stack_var* arg_two;
  
  dbg(DBG_USR1, ("VM: Issuing sendr instruction.\n"));
  if (stack != &(VAR(send_stack))) { // Pass control to send stack
    dbg(DBG_USR1, ("VM: In non-send stack. Pass control over.\n"));
    if (VAR(send_waiting_stack) != 0) {
      stack->pc--;
      return;
    }
    arg_one = pop(stack);
    
    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to send non-message!\n"));
      return;
    }
    VAR(sendStackActive) = 0;
    
    VAR(send_stack).sp = 0;
    VAR(send_stack).pc = 0;
    push_message(&VAR(send_stack), arg_one->msg.var);
    VAR(send_stack).state = STATE_RUN;
    execute_stack(&VAR(send_stack));
    VAR(send_waiting_stack) = stack;
    stack->state = STATE_PACKET_WAIT;
  }
  else { // We're in the send stack...
    dbg(DBG_USR1, ("VM: In send stack. Compute header and send.\n"));
    if (VAR(sendStackActive) == 0) {
      int index;
      int i;
      int rval;
      char* msg_to_send;
      char* vm_buf;
      VAR(sendStackActive) = 1;
      arg_one = pop(stack);
      arg_two = pop(stack);
      if (arg_two->type != VAR_MSG) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to send non-packet on send stack!\n"));
	return;
      }
      if (arg_one->type != VAR_VALUE) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to send packet to invalid address!\n"));
	return;
      }
      
      msg_to_send = (VAR(raw_packet).data);
      for (i = 0; i < HEADERSIZE; i++) {
	msg_to_send[i] = ((char*)stack->header)[i];
      }
      index = HEADERSIZE;
      vm_buf = (char*)arg_two->msg.var;
      for (i = 0;i < (sizeof(vm_msg)); i++) {
	msg_to_send[i + index] = vm_buf[i];
      }
      
      rval = TOS_CALL_COMMAND(VM_SUB_SEND_RAW)(arg_one->value.var, VM_RAW, (TOS_MsgPtr)&(VAR(raw_packet)));
      
      if (!rval) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to transmit but radio channel busy! Retry!\n"));
	push_message(stack, arg_two->msg.var);
	push_constant(stack, arg_one->value.var);
	stack->pc--;
      }
      else { // This will make control pass back to the stack that called us
	dbg(DBG_USR1, ("VM: Sending raw packet. Control will return to calling stack on completion.\n"));
	VAR(send_waiting_stack)->state = STATE_PACKET_SEND;
	stack->state = STATE_HALT;
      }
    }
    else {
      dbg(DBG_USR1, ("VM: Send channel busy. Reissuing instruction.\n"));
      stack->pc--;
    }
  }
}

void execute_sclass(stack_t* stack, char instr) {
  stack_var* arg_one;
  char opcode = sop(instr);
  char arg = sarg(instr);

  dbg(DBG_USR1, ("VM: Computing sclass.\n"));
  switch(opcode) {
  case OPsetms: {
    short* header = (short*)stack->header;
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set message field to non-value!\n"));
      break;
    }
    if (arg >= FRAMESIZES) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to index short beyond message size!\n"));
      break;
    }
    dbg(DBG_USR1, ("VM: setms %i to %hi\n", (int)arg, arg_one->value.var));
    header[(int)arg] = arg_one->value.var;
    break;
  }
    
  case OPsetmb: {
    char* header = (char*)stack->header;
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set message field to non-value!\n"));
      break;
    }
    dbg(DBG_USR1, ("VM: setmb %i to %hhi\n", (int)arg, (char)arg_one->value.var));
    header[(int)arg] = (char)(arg_one->value.var);
    break;
  }
    
  case OPsetfs: {
    short* frame = (short*)VAR(frame);
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set message field to non-value!\n"));
      break;
    }
    if (arg >= FRAMESIZES) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to index short beyond frame size!\n"));
      break;
    }
    dbg(DBG_USR1, ("VM: setfs %i to h%i\n", (int)arg, arg_one->value.var));
    frame[(int)arg] = arg_one->value.var;
    break;
  }
    
  case OPsetfb: {
    char* frame = (char*)VAR(frame);
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set message field to non-value!\n"));
      break;
    }
    dbg(DBG_USR1, ("VM: setfb %i to %hhi\n", (int)arg, (char)arg_one->value.var));
    frame[(int)arg] = (char)(arg_one->value.var);
    break;
  }
    
  case OPgetms: {
    if (arg >= HEADERSIZES) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to index short beyond message size!\n"));
      break;
    }
    dbg(DBG_USR1, ("VM: getms %i: %hi\n", (int)arg, (stack->header[(int)arg])));
    push_constant(stack, stack->header[(int)arg]);
    break;
  }
  case OPgetmb: {
    char* header = (char*)stack->header;
    dbg(DBG_USR1, ("VM: getmb %i: %hhi\n", (int)arg, (header[(int)arg])));
    push_constant(stack, (short)(header[(int)arg]));
    break;
  }
    
  case OPgetfs: {
    if (arg >= HEADERSIZES) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to index short beyond message size!\n"));
      break;
    }
    dbg(DBG_USR1, ("VM: getfs %hi: %i\n", (int)arg, (VAR(frame)[(int)arg]))); 
    push_constant(stack, VAR(frame)[(int)arg]);
    break;
  }
    
  case OPgetfb: {
    char* frame = (char*)VAR(frame);
    dbg(DBG_USR1, ("VM: getfb %i: %hhi\n", (int)arg, (frame[(int)arg]))); 
    push_constant(stack, (short)(frame[(int)arg]));
    break;
  }
  default:
    dbg(DBG_ERROR, ("VM: Tried to execute non-existent slcass: 0x%hhx!\n", instr));
    break;
  }
}

void execute_xclass(stack_t* stack, char instr) {
  char arg = xarg(instr);
  if ((instr & xopmask) == OPpushc) {
    dbg(DBG_USR1, ("VM: Pushing constant: %i\n", (int)arg));
    push_constant(stack, arg);
  }
  else if ((instr & xopmask) == OPblez) {
    stack_var* var = pop(stack);
    short val;
    if (var->type == VAR_VALUE) {
      val = var->value.var;
    }
    else if (var->type == VAR_SENSE) {
      val = var->sense.var;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: blzero on a message: always jumps\n"));
      val = 0;
    }
    dbg(DBG_USR1, ("VM: blzero -- val is %i, jump to is %i\n", (int)val, (int)arg));
    if (val <= 0) {
      stack->pc = arg;
    }
  }
  else {
    dbg(DBG_ERROR, ("VM: Tried to execute unknown instruction: 0x%hhx\n", instr));
    return;
  }
}

// Need this separate function to placate the AVR compiler gods -- if
// they're in the standard sixbit instr function, it breaks.
void execute_sixbit_other_instr(stack_t* stack, char instr) {
  stack_var* arg_one;
  stack_var* arg_two;
  
  if (instr == OPswap) {
    stack_var tmp;
    arg_one = pop(stack);
    arg_two = pop(stack);
    tmp = *arg_two;
    
    if (arg_one->type == VAR_MSG) {
      push_message(stack, arg_one->msg.var);
    }
    else if (arg_one->type == VAR_VALUE) {
      push_constant(stack, arg_one->value.var);
    }
    else if (arg_one->type == VAR_SENSE) {
      push_sense(stack, arg_one->sense.type, arg_one->sense.var);
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("Tried to swap an invalid stack variable!\n"));
    }
    if (tmp.type == VAR_MSG) {
      push_message(stack, tmp.msg.var);
    }
    else if (tmp.type == VAR_VALUE) {
      push_constant(stack, tmp.value.var);
    }
    else if (tmp.type == VAR_SENSE) {
      push_sense(stack, tmp.sense.type, tmp.sense.var);
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("Tried to swap an invalid stack variable!\n"));
    }
    
    
    return;
  }
  else if (instr == OPuart) {
    dbg(DBG_USR1, ("VM: Sending to UART. Compute header and send.\n"));
    if (VAR(send_waiting_stack) == 0) {
      int index;
      int i;
      char* msg_to_send;
      char* vm_buf;
      VAR(sendStackActive) = 1;
      arg_one = pop(stack);
      if (arg_one->type != VAR_MSG) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to send non-packet on send stack!\n"));
	return;
      }

      msg_to_send = (VAR(raw_packet).data);
      for (i = 0; i < HEADERSIZE; i++) {
	msg_to_send[i] = ((char*)stack->header)[i];
      }
      index = HEADERSIZE;
      vm_buf = (char*)arg_one->msg.var;
      for (i = 0;i < (sizeof(vm_msg)); i++) {
	msg_to_send[i + index] = vm_buf[i];
      }
      
      dbg(DBG_USR1, ("VM: Sending a message.\n"));
      
      
      if (TOS_CALL_COMMAND(VM_SUB_SEND_RAW)(TOS_UART_ADDR, VM_RAW, (TOS_MsgPtr)&(VAR(raw_packet)))) {
	dbg(DBG_USR1, ("VM: Send request successful. Waiting for response.\n"));
	stack->state = STATE_PACKET_SEND;
	VAR(send_waiting_stack) = stack;
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Send request failed. Retrying.\n"));
	push_message(stack, arg_one->msg.var);
	stack->pc--;
      }
    }
    else {
      dbg(DBG_USR1, ("VM: Send channel busy. Reissuing instruction.\n"));
      stack->pc--;
    }

  }
  else if (instr == OPforw) {
    stack_t* waiter = VAR(send_waiting_stack);
    dbg(DBG_USR1, ("VM: Executing forw instruction.\n"));
    if (waiter == 0) {
      char codeNum = stack->code;
      char rval = forward_capsule(codeNum);
      
      if (rval) {
	stack->state = STATE_CAPSULE_SEND;
	VAR(send_waiting_stack) = stack;
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Thought radio stack was free for capsule send, but it's not... retry!\n"));
	stack->pc--;
      }
    }
    else {
      dbg(DBG_USR1, ("VM: Tried to send code capsule. Radio stack busy. Retry.\n"));
      stack->pc--;
    }
    return;
  }
    
  else if (instr == OPforwo) {
    stack_t* waiter = VAR(send_waiting_stack);
    dbg(DBG_USR1, ("VM: Executing forwo instruction.\n"));
    if (waiter == 0) {
      char rval, codeNum;
      arg_one = pop(stack);
      if (arg_one->type != VAR_VALUE) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Code segment not specified with a constant!\n"));
	return;
      }
      
      codeNum = (char)arg_one->value.var;
      if (codeNum < 0 || codeNum >= CAPSULE_NUM) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Capsule number outside of valid range -- forwarding aborted!\n"));
	return;
      }
      rval = forward_capsule(codeNum);
      
      if (rval) {
	stack->state = STATE_CAPSULE_SEND;
	VAR(send_waiting_stack) = stack;
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Thought radio stack was free for capsule send, but it's not... retry!\n"));
	stack->pc--;
      }
    }
    else {
      dbg(DBG_USR1, ("VM: Tried to send code capsule. Radio stack busy. Retry.\n"));
      stack->pc--;
    }
    return;
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to execute unrecognized instruction -- this should never happen in execute_sixbit_other_instr()!\n"));
  }
}

void execute_sixbit_instr(stack_t* stack, char instr) {
  stack_var* arg_one;

  if (instr == OPswap || instr == OPuart ||  instr == OPforw || instr == OPforwo) {
    execute_sixbit_other_instr(stack, instr);
    return;
  }
  /*else if (instr == OPusr0) {process_user_intr(stack, instr);}
  else if (instr == OPusr1) {process_user_intr(stack, instr);}
  else if (instr == OPusr2) {process_user_intr(stack, instr);}
  else if (instr == OPusr3) {process_user_intr(stack, instr);}
  else if (instr == OPusr4) {process_user_intr(stack, instr);}
  else if (instr == OPusr5) {process_user_intr(stack, instr);}
  else if (instr == OPusr6) {process_user_intr(stack, instr);}
  else if (instr == OPusr7) {process_user_intr(stack, instr);}
  */
  else if (instr == OPsetgrp) {
    char newgrp;
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set group to non-value!\n"));
      return;
    }
    newgrp = (char)(arg_one->value.var & 0xff);
    dbg(DBG_USR1, ("VM: Setting group to 0x%hhx\n", newgrp));
    LOCAL_GROUP = newgrp;
    return;
  }
    
  else if (instr == OPpot) {
    short pot = (short)TOS_CALL_COMMAND(VM_SUB_GET_POT)();
    push_constant(stack, pot);
    return;
  }
    
  else if (instr == OPpots) {
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set pot to non-value!\n"));
      return;
    }
    TOS_CALL_COMMAND(VM_SUB_SET_POT)((char)arg_one->value.var);
    return;
  } 
    
  else if (instr == OPclockc) {
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set clock counter rate with non-value!\n"));
      return;
    }
    VAR(clockTrigger) = (char)(arg_one->value.var & 0xff);
    return;
  }
    
  else if (instr == OPclockf) {
    char counter;
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set clock frequency with non-value!\n"));
      return;
    }
    counter = (char)(arg_one->value.var & 0xff);
    TOS_CALL_COMMAND(VM_SUB_CLOCK_INIT)(counter, 7);
    return;
  }
  else if (instr == OPret) {
    dbg(DBG_USR1, ("VM: Returning from subroutine %hhi\n", stack->code));
    pop_call(stack);
    return;
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to execute unknown 6-bit instruction: 0x%hhx", instr));
  }
}

void execute_fivebit_instr(stack_t* stack, char instr) {
  stack_var* arg_one;
  stack_var* arg_two;
  
  switch(instr) {
  case OPcast: {
    dbg(DBG_USR1, ("VM: Casting sval to val\n"));
    arg_one = pop(stack);
    if (arg_one->type != VAR_SENSE) {
      dbg(DBG_ERROR, ("VM: Trying to cast a non-sensor value\n"));
    }
    else {
      push_constant(stack, arg_one->sense.var);
    }
    break;
  }
    
  case OPpushm: {
    dbg(DBG_USR1, ("VM: Pushing message.\n"));
    push_message(stack, &VAR(buffer));
    break;
  }
      
  case OPmovm: { // Pop a value off message onto the op stack
    vm_msg* msg;
    char index;
    arg_one = pop(stack);
    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to pop a msg value of a non-message!\n"));
      break;
    }
    msg = arg_one->msg.var;
    index = msg->num_entries;
    if (index <= 0) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to pop a value off an empty message: pushing 0.\n"));
      push_constant(stack, 0);
    }
    else {
      msg_entry* entry;
      index--;
      msg->num_entries--;
      
      entry = &(msg->entries[(int)index]);
      if (entry->type == SENSE_TYPE_VALUE) {
	push_constant(stack, entry->value);
      }
      else {
	push_sense(stack, entry->type, entry->value);
      }
    }
    break;
  }
    
  case OPclear: {
    dbg(DBG_USR1, ("VM: Clearing stack variable.\n"));
    arg_one = pop(stack);
    if (arg_one->type == VAR_SENSE) {
      push_sense(stack, arg_one->sense.type, 0);
    }
    else if (arg_one->type == VAR_VALUE) {
      push_constant(stack, 0);
    }
    else if (arg_one->type == VAR_MSG) {
      vm_msg* msg = arg_one->msg.var;
      msg->num_entries = 0;
      push_message(stack, msg);
    }
    break;
  }
      
  case OPson: {
    TOS_CALL_COMMAND(VM_SUB_SOUND_ON)();
    break;
  }
    
  case OPsoff: {
    TOS_CALL_COMMAND(VM_SUB_SOUND_OFF)();
    break;
  }
    
  case OPnot: {
    arg_one = pop(stack);
    dbg(DBG_USR1, ("VM: NOT top of stack.\n"));
    if (arg_one->type == VAR_SENSE) {
      push_sense(stack, arg_one->sense.type, ~(arg_one->sense.var));
    }
    else if (arg_one->type == VAR_VALUE) {
      push_constant(stack, ~(arg_one->value.var));
    }
    else {
      dbg(DBG_ERROR, ("VM: Trying to NOT a message.\n"));
      push_message(stack, arg_one->msg.var);
    }
    break;
  }
    
  case OPlog: {
    msg_entry entry;
    arg_one = pop(stack);
    if (arg_one->type == VAR_SENSE) {
      dbg(DBG_USR1, ("VM: Logging sensor value.\n"));
      entry.type = arg_one->sense.type;
      entry.id = (char)(TOS_LOCAL_ADDRESS & 0xff);
      entry.value = arg_one->sense.var;
      logAppend(stack, (char*)&(entry), sizeof(msg_entry));
    }
    else if (arg_one->type == VAR_VALUE) {
      dbg(DBG_USR1, ("VM: Logging value.\n"));
      entry.type = SENSE_TYPE_VALUE;
      entry.id = (char)(TOS_LOCAL_ADDRESS & 0xff);
      entry.value = arg_one->value.var;
      logAppend(stack, (char*)&(entry), sizeof(msg_entry));
    }
    else if (arg_one->type == VAR_MSG) {
      vm_msg* msg = arg_one->msg.var;
      char* ptr = (char*)&(msg->entries); // Log entries of packet
      dbg(DBG_USR1, ("VM: Logging first 16 bytes of message.\n"));
      logAppend(stack, ptr, LOGSIZE);
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to log invalid type!\n"));
    }
    break;
  }
    
  case OPlogr: { // msg,#,...
    arg_one = pop(stack); // Must be msg (buffer to read into)
    arg_two = pop(stack); // Must be # (log line to read)
    
    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to read log into non-message type!\n"));
      stack->state = STATE_HALT; 
    }
    else if (arg_two->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log line index non-value type!\n"));
      stack->state = STATE_HALT; 
    }
    else {
      short line;
      line = arg_two->value.var + 16; // First 16 lines of EEPROM are reserved
      push_message(stack, arg_one->msg.var);
      dbg(DBG_USR1, ("VM: Trying to read line %i into message.\n", (int)line));
      line = TOS_CALL_COMMAND(VM_SUB_LOG_READ)(line, (char*)arg_one->msg.var->entries);
      
      if (!line) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Log read failed. Retry.\n"));
	push_constant(stack, arg_two->value.var);
	stack->pc--;
      }
      else {
	stack->state = STATE_LOG_WAIT;
      }
    }
    break;
  }
    
  case OPlogr2: { // #,msg,...
    arg_two = pop(stack); // Must be value (index in log)
    arg_one = pop(stack); // Must be msg (buffer to read into)
    
    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to read log into non-message type!\n"));
      stack->state = STATE_HALT; 
    }
    else if (arg_two->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log line index non-value type!\n"));
      stack->state = STATE_HALT; 
    }
    else {
      short line;
      line = arg_two->value.var + 16; // First 16 lines of EEPROM are reserved
      push_message(stack, arg_one->msg.var);
      dbg(DBG_USR1, ("VM: Trying to read line %i into message.\n", (int)line));
      line = TOS_CALL_COMMAND(VM_SUB_LOG_READ)(line, (char*)arg_one->msg.var->entries);
      
      if (!line) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Log read failed. Retry.\n"));
	arg_one = pop(stack);
	push_constant(stack, arg_two->value.var);
	push_message(stack, arg_one->msg.var);
	stack->pc--;
      }
      else {
	stack->state = STATE_LOG_WAIT;
      }
    }
    break;
  }
    
  case OPgets: {
    if (VAR(shared_var).type == VAR_VALUE) {
      push_constant(stack, VAR(shared_var).value.var);
    }
    else if (VAR(shared_var).type == VAR_SENSE) {
      push_sense(stack, VAR(shared_var).sense.type, VAR(shared_var).sense.var);
    }
    else if (VAR(shared_var).type == VAR_MSG) {
      push_message(stack, VAR(shared_var).msg.var);
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to get invalid shared value!\n"));
    }
    break;
  }
    
  case OPsets: {
    arg_one = pop(stack);
    if (arg_one->type == VAR_VALUE) {
      VAR(shared_var).type = VAR_VALUE;
      VAR(shared_var).value.var = arg_one->value.var;
    }
    else if (arg_one->type == VAR_SENSE) {
      VAR(shared_var).type = VAR_SENSE;
      VAR(shared_var).sense.var = arg_one->sense.var;
      VAR(shared_var).sense.type = arg_one->sense.type;
    }
    else if (arg_one->type == VAR_MSG) {
      VAR(shared_var).type = VAR_MSG;
      VAR(shared_var).msg.var = arg_one->msg.var;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to set shared value to invalid type!\n"));
    }
    break;
  }
    
  case OPrand: {
    short val = TOS_CALL_COMMAND(VM_SUB_RAND)();
    dbg(DBG_USR1, ("VM: Pushing random number: 0x%hx\n", val));
    push_constant(stack, val);
    break;
  }
    
  case OPeq: {
    dbg(DBG_USR1, ("VM: Testing equality.\n"));
    arg_one = pop(stack);
    arg_two = pop(stack);
    push_constant(stack, (short)are_equal(arg_one, arg_two));
    break;
  }
    
  case OPneq: {
    dbg(DBG_USR1, ("VM: Testing inequality.\n"));
    arg_one = pop(stack);
    arg_two = pop(stack);
    push_constant(stack, (short)!(are_equal(arg_one, arg_two)));
    break;
  }
    
  case OPcall: {
    arg_one = pop(stack);
    if (arg_one->type != VAR_VALUE) {
      dbg(DBG_ERROR, ("VM: Tried to call into non-value!\n"));
      break;
    }
    else if (arg_one->value.var < 0 || arg_one->value.var > CAPSULE_SUB3) {
      dbg(DBG_ERROR, ("VM: Tried to call into non-subprocedure: %hi!\n", arg_one->value.var));
      break;
    }
    dbg(DBG_USR1, ("VM: Calling subroutine %hi\n", arg_one->value.var));
    push_call(stack);
    stack->code = (char)arg_one->value.var;
    stack->pc = 0;
    break;
  }
  default: {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to execute unknown five-bit instruciotn: 0x%hhx!\n", instr));
  }
  }
  return;
}

void compute_instruction(stack_t* stack) {
  char instr;

  instr = VAR(code)[(int)stack->code].code[(int)stack->pc];
  
  //dbg(DBG_USR1, ("VM: Fetching instruction %hhx from capsule %hhx: 0x%hhx\n", stack->pc, stack->code, instr));
  if (stack->state != STATE_RUN) {
    dbg(DBG_ERROR, ("VM: Tried to execute instruction in non-run state: %i\n", stack->state));
    return;
  }

  stack->pc++;
  
  if (is_xclass(instr)) {
    execute_xclass(stack, instr);
  }
  else if (is_sclass(instr)) {
    execute_sclass(stack, instr);
  }
  else {
    switch (instr) {
      stack_var* arg_one;
      stack_var* arg_two;
      short result;
      
    case OPhalt: {
      dbg(DBG_USR1, ("VM: Halting.\n"));
      stack->state = STATE_HALT;
      if (stack == &(VAR(recv_stack))) {VAR(recvStackActive) = 0;}
      if (stack == &(VAR(send_stack))) {
	VAR(sendStackActive) = 0;
	VAR(send_waiting_stack)->state = STATE_RUN;
	execute_stack(VAR(send_waiting_stack));
	VAR(send_waiting_stack) = 0;
      }
      break;
    }
      
    case OPreset: {
      dbg(DBG_USR1, ("VM: Reset.\n"));
      stack->sp = 0;
      break;
    }
      
    case OPadd: {
      dbg(DBG_USR1, ("VM: Adding.\n"));
      execute_add(stack);
      break;
    }
      
      
    case OPand: {
      dbg(DBG_USR1, ("VM: ANDing.\n"));
      arg_one = pop(stack);
      arg_two = pop(stack);
      if (arg_one->type != VAR_VALUE || arg_two->type != VAR_VALUE) {
	dbg(DBG_ERROR, ("VM: Tried to AND a non-value variable\n"));
      }
      result = arg_one->value.var & arg_two->value.var;
      push_constant(stack, result);
      break;
    }
      
    case OPor: {
      dbg(DBG_USR1, ("VM: ORing\n"));
      arg_one = pop(stack); 
      arg_two = pop(stack); 
      if (arg_one->type != VAR_VALUE || arg_two->type != VAR_VALUE) {
	dbg(DBG_ERROR, ("VM: Tried to OR a non-value variable\n"));
	break;
      }
      result = arg_one->value.var | arg_two->value.var;
      push_constant(stack, result);
      break;
    }
      
    case OPshiftl: {
      short shift;
      dbg(DBG_USR1, ("VM: Shifting.\n"));
      arg_two = pop(stack);
      arg_one = pop(stack);
      if (arg_one->type != VAR_VALUE || arg_two->type != VAR_VALUE) {
	dbg(DBG_ERROR, ("VM: Tried to SHIFT a non-value variable\n"));
	break;
      }
      
      shift = arg_two->value.var;
      if (shift < 0) {
	result = arg_one->value.var >> -(shift);
	dbg(DBG_USR1, ("VM: Shifted %i >> %i to %i\n", (int)(arg_one->value.var), (int)(-shift), (int)result));
      }
      else {
	result = arg_one->value.var << shift;
	dbg(DBG_USR1, ("VM: Shifted %i << %i to %i\n", (int)(arg_one->value.var), (int)shift, (int)result));
      }
      push_constant(stack, result);
      break;
    }
      
    case OPshiftr: {
      short shift;
      dbg(DBG_USR1, ("VM: Shifting.\n"));
      arg_two = pop(stack);
      arg_one = pop(stack);
      if (arg_one->type != VAR_VALUE || arg_two->type != VAR_VALUE) {
	dbg(DBG_ERROR, ("VM: Tried to SHIFT a non-value variable\n"));
	break;
      }
      
      shift = arg_two->value.var;
      if (shift < 0) {
	result = arg_one->value.var << -(shift);
	dbg(DBG_USR1, ("VM: Shifted %i >> %i to %i\n", (int)(arg_one->value.var), (int)(-shift), (int)result));
      }
      else {
	result = arg_one->value.var >> shift;
	dbg(DBG_USR1, ("VM: Shifted %i << %i to %i\n", (int)(arg_one->value.var), (int)shift, (int)result));
      }
      push_constant(stack, result);
      break;
    }
      
      
    case OPputled: {
      short val;
      arg_one = pop(stack);
      if (arg_one->type != VAR_VALUE) {
	dbg(DBG_ERROR, ("VM: Tried to set LEDs with a non-value variable\n"));
	break;
      }
      val = arg_one->value.var;
      dbg(DBG_USR1, ("VM: Executing LED instruction.\n"));
      LEDop(val);
      break;
    }
      
    case OPid: {
      dbg(DBG_USR1, ("VM: Pushing mote ID\n"));
      push_constant(stack, TOS_LOCAL_ADDRESS);
      break;
    }
      
    case OPinv: {
      dbg(DBG_USR1, ("VM: Inverting.\n"));
      arg_one = pop(stack);
      if (arg_one->type == VAR_VALUE) {
	short val = arg_one->value.var;
	dbg(DBG_USR1, ("VM: Inverting %i to %i.\n", val, -val));
	push_constant(stack, -val);
      }
      else if (arg_one->type == VAR_SENSE) {
	push_sense(stack, arg_one->sense.type, -(arg_one->sense.var));
      }
      else {
	dbg(DBG_ERROR, ("VM: Tried to invert a message!\n"));
      }
      break;
    }
      
    case OPcopy: {
      dbg(DBG_USR1, ("VM: Copying stack value.\n"));
      arg_one = pop(stack);
      if (arg_one->type == VAR_VALUE) {
	push_constant(stack, arg_one->value.var);
	push_constant(stack, arg_one->value.var);
      }
      else if (arg_one->type == VAR_MSG) {
	push_message(stack, arg_one->msg.var);
	push_message(stack, arg_one->msg.var);
      }
      else if (arg_one->type == VAR_SENSE) {
	push_sense(stack, arg_one->sense.type, arg_one->sense.var);
	push_sense(stack, arg_one->sense.type, arg_one->sense.var);
      }
      else {
	dbg(DBG_ERROR, ("VM: Trying to copy invalid stack variable\n"));
      }
      break;
    }
   
    case OPpop: {
      dbg(DBG_USR1, ("VM: Popping stack.\n"));
      pop(stack);
      break;
    }
      
    case OPsense: {
      dbg(DBG_USR1, ("VM: Getting sensor value.\n"));
      arg_one = pop(stack);
      if (arg_one->type != VAR_VALUE) {
	dbg(DBG_ERROR, ("VM: Tried to specify a sensor without a value!\n"));
      }
      else {
	char rval;
	if (arg_one->value.var == DATA_PHOTO) {
	  VAR(sense_type) = DATA_PHOTO;
	  rval =  TOS_CALL_COMMAND(VM_SUB_GET_PHOTO)();
	}
	else if (arg_one->value.var == DATA_TEMP) {
	  VAR(sense_type) = DATA_TEMP;
	  rval =  TOS_CALL_COMMAND(VM_SUB_GET_TEMP)();
	}
	else {
	  dbg(DBG_ERROR|DBG_USR1, ("VM: Tried to get unknown data type: %i\n", (int)arg_one->value.var));
	  push_sense(stack, arg_one->value.var, 0);
	  break;
	}
	if (rval) {
	  stack->state = STATE_DATA_WAIT;
	  VAR(adc_waiting_stack) = stack;
	}
	else {
	  dbg(DBG_USR1, ("VM: ADC is busy, retry.\n"));
	  push_constant(stack, arg_one->value.var);
	  stack->pc--; // This will just cause the instruction to be reiussed
	}
      }
      break;
    }
            
    case OPsend: {
      dbg(DBG_USR1, ("VM: Sending a message.\n"));
      if (VAR(send_waiting_stack) != 0) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to send packet, but radio busy. Re-issue.\n"));
	stack->pc--;
	break;
      }
      
      arg_one = pop(stack);
      if (arg_one->type != VAR_MSG) {
	dbg(DBG_ERROR, ("VM: Tried to send a non-message!\n"));
	break;
      }
      
      if (TOS_CALL_COMMAND(VM_SUB_SEND_PACKET)((char*)(arg_one->msg.var), sizeof(vm_msg))) {
	dbg(DBG_USR1, ("VM: Send request successful. Waiting for response.\n"));
	stack->state = STATE_PACKET_SEND;
	VAR(send_waiting_stack) = stack;
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Send request failed. Retrying.\n"));
	push_message(stack, arg_one->msg.var);
	stack->pc--;
      }
      break;
    }
      
    case OPsendr: {
      execute_sendr(stack);
      break;
    }
      
    case OPcast:
    case OPpushm:
    case OPmovm:
    case OPclear:
    case OPson:
    case OPsoff:
    case OPnot:
    case OPlog:
    case OPlogr:
    case OPlogr2:
    case OPsets:
    case OPgets:
    case OPrand:
    case OPeq:
    case OPneq:
    case OPcall: {
      // AVR tools have a bug -- if the switch statement is too long,
      // it doesn't work. Putting these instructions in a subroutine fixes
      // the problem. How stupid can compiler writers be?
      execute_fivebit_instr(stack, instr);
      break;
    }

    case OPswap:
    case OPuart:
    case OPforw:
    case OPforwo:
    case OPusr0:
    case OPusr1:
    case OPusr2:
    case OPusr3:
    case OPusr4:
    case OPusr5:
    case OPusr6:
    case OPusr7:
    case OPsetgrp:
    case OPpot:
    case OPpots:
    case OPclockc:
    case OPclockf:
    case OPret: {
      execute_sixbit_instr(stack, instr);
      break;
    }
      
    default:
      dbg(DBG_ERROR, ("VM: Unrecognized instruction: 0x%hhx!\n", instr));
    }
  }
}









