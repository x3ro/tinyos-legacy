/*									tab:4
 * VM.c - simple byte-code interpreter
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
 * History:   created 2/8/2002
 *
 * A simple virtual machine for TinyOS.
 */

#include "tos.h"
#include "VM.h"
#include "tos-vm.h"
#include "dbg.h"

#define LOGSIZE                 16
#define MEMSIZE                 16
#define PGMSIZE                 24

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
#define STATE_WAIT               5
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
  short var;
  char type;
} sense_var;

typedef struct {
  short var;
} value_var;

typedef struct {
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

#define TOS_FRAME_TYPE INTERP_frame
TOS_FRAME_BEGIN(INTERP_frame) {
  char pc;
  char sp;
  char state;
  char version;  
  char has_program;
  char sense_type;
  char logBufCount;
  char logBuffer[LOGSIZE];
  char program[PGMSIZE];
  stack_var stack[MEMSIZE];
  vm_msg buffer;
  TOS_Msg capsule;
}
TOS_FRAME_END(INTERP_frame);

void push_constant(short x) {
  if (VAR(sp) >= MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to run off end of stack.\n"));
    return;
  }
  VAR(stack)[(int)VAR(sp)].type = VAR_VALUE;
  VAR(stack)[(int)VAR(sp)].value.var = x;
  VAR(sp)++;
}

void push_message(vm_msg* ptr) {
  if (VAR(sp) >= MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to run off end of stack.\n"));
    return;
  }
  VAR(stack)[(int)VAR(sp)].type = VAR_MSG;
  VAR(stack)[(int)VAR(sp)].msg.var = ptr;
  VAR(sp)++;
}

void push_sense(char type, short val) {
  if (VAR(sp) >= MEMSIZE) {
    dbg(DBG_ERROR, ("VM: Tried to run off end of stack.\n"));
    return;
  }
  VAR(stack)[(int)VAR(sp)].type = VAR_SENSE;
  VAR(stack)[(int)VAR(sp)].sense.var = val;
  VAR(stack)[(int)VAR(sp)].sense.type = type;
  VAR(sp)++;
}

stack_var* pop() {
  stack_var* val;
  VAR(sp)--;
  if (VAR(sp) < 0) {
    VAR(sp) = 0;
    dbg(DBG_ERROR, ("VM: Tried to pop off end of stack.\n"));
    VAR(stack)[0].type = VAR_INVALID;
    return &(VAR(stack)[0]);
  }
  val = &(VAR(stack)[(int)VAR(sp)]);
  return val;
}

void logAppend(char* data, char len) {
  char rval;
  if ((len + VAR(logBufCount)) > LOGSIZE) {
    dbg(DBG_USR1, ("VM: Write over log boundary. Flush, then reexecute instruction.\n"));
    rval = TOS_CALL_COMMAND(VM_SUB_LOG_WRITE)(VAR(logBuffer));
    if (rval) {
      VAR(state) = STATE_WAIT;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log write failed! Retrying.\n"));
    }
    VAR(pc)--; // Reexecute the instruction either on log flush or immediately
  } else if ((len + VAR(logBufCount) == LOGSIZE)) {
    int i;
    dbg(DBG_USR1, ("VM: Write on log boundary. Flush.\n"));
    for (i = 0; i < len; i++) {
      VAR(logBuffer)[(int)VAR(logBufCount)] = data[i];
      VAR(logBufCount)++;
    }
    rval = TOS_CALL_COMMAND(VM_SUB_LOG_WRITE)(VAR(logBuffer));
    if (rval) {
      VAR(state) = STATE_WAIT;
    }
    else {
      VAR(pc)--;
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


char TOS_COMMAND(VM_INIT)(){
  TOS_CALL_COMMAND(VM_SUB_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(VM_SUB_CLOCK_INIT)(tick1ps);
  VAR(sp)          = 0;
  VAR(pc)          = 0;
  VAR(state)       = STATE_HALT;
  VAR(version)     = -1;
  
  VAR(has_program) = 0;
    
  VAR(logBufCount) = 0;
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

  push_constant(0);

  /* cnt_to_rfm and leds with capsule forwarding every 16 clock ticks */
  VAR(program)[index++] = OPhalt; // Comment out this instr to enable program
  VAR(program)[index++] = (char)(OPpushc | 0x1);
  VAR(program)[index++] = OPadd;
  VAR(program)[index++] = OPcopy;
  VAR(program)[index++] = OPpushm;
  VAR(program)[index++] = OPadd;
  VAR(program)[index++] = OPsend;
  VAR(program)[index++] = OPcopy;
  VAR(program)[index++] = (char)(OPpushc | 0x7);
  VAR(program)[index++] = OPand;
  VAR(program)[index++] = OPputled;
  VAR(program)[index++] = OPcopy;
  VAR(program)[index++] = OPinv;
  VAR(program)[index++] = (char)(OPpushc | 0x1);
  VAR(program)[index++] = (char)(OPpushc | 0x4);
  VAR(program)[index++] = OPshiftl;
  VAR(program)[index++] = OPadd;
  // If counter is >= 16, jump to capsule forwarding code
  VAR(program)[index] = (char)(OPblez | (index + 2));
  index++;
  VAR(program)[index++] = OPhalt;
  VAR(program)[index++] = OPforw;
  VAR(program)[index++] = OPpop;         // Remove counter
  VAR(program)[index++] = OPpushc;       // Replace it with 0
  VAR(program)[index++] = OPpushc;       // Makes jump always succeed
  VAR(program)[index] = (char)(OPblez | (index - 5));
  return 1;
}

/* run - run interpeter from current state
 */

TOS_TASK(run) {
  compute_instruction();  
}


char TOS_EVENT(VM_LOG_READ_EVENT)(char* data, char success) {
  if (VAR(state) == STATE_LOG_WAIT) {
    stack_var* arg_one = pop();
    dbg(DBG_USR1, ("VM: Log read completed. Writing into packet.\n"));
    if (success) {
      int i;
      vm_msg* msg = arg_one->msg.var;
      char* buf = (char*)msg->entries;
      for (i = 0; i < VAR(logBufCount); i++) {
	buf[i] = data[i];
      }
      msg->num_entries = PACKET_MAX_ENTRIES + 1;
      push_message(msg);
    }
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
  }
  return 1;
}

/*  VM_DATA_EVENT(data):
    handler for subsystem data event, fired when data ready.

    store data in frame, resume interpreter
    it should be in waitdata state
 */

char TOS_EVENT(VM_SEND_DONE)(char* msg) {
  if (VAR(state) == STATE_PACKET_SEND) {
    if (((vm_msg*)msg) == &VAR(buffer)) {
      VAR(buffer).num_entries = 0;
    }
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
  }
  return 1;
}

/* Clock Event Handler  */

void TOS_EVENT(VM_CLOCK_EVENT)(){
  if (VAR(state) == STATE_HALT) {
    VAR(pc) = 0;
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
  }
}


char TOS_EVENT(VM_LOG_DONE_EVENT)(char success) {
  int i;
  if (success) {
    dbg(DBG_USR1, ("VM: Log write completed.\n"));
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Log write unsuccessful!\n"));
    VAR(state) = STATE_HALT;
  }
  VAR(logBufCount) = 0;
  for (i = 0; i < LOGSIZE; i++) {
    VAR(logBuffer)[i] = (char)0;
  }
  return 1;
}

/* VM_CAPSULE_EVENT
 * 0 - len
 * 1:len-1 bytes of code
 */



TOS_MsgPtr TOS_EVENT(VM_CAPSULE_RECEIVE)(TOS_MsgPtr data){
  int i;
  char version = data->data[0];;
  short vdiff = version - VAR(version);
  if ((vdiff < 64 && vdiff > 0) || (vdiff < -64 && vdiff > -128)) {
    dbg(DBG_USR1, ("VM: Received new code capsule... updating.\n"));

    VAR(version) = version;
    for (i = 0; i < PGMSIZE; i++) {
      VAR(program)[i] = data->data[i+1];
    }
    VAR(pc) = 0;
    VAR(sp) = 0;
    VAR(buffer).num_entries = 0;
    push_constant(0);
    VAR(state) = STATE_HALT;
  }
  else {
    dbg(DBG_USR1, ("VM: Received new code capsule... too old.\n"));
  }
  return data;
}

TOS_MsgPtr TOS_EVENT(VM_CAPSULE_SEND_DONE)(TOS_MsgPtr data){
  if (VAR(state) == STATE_PACKET_SEND && data == &VAR(capsule)) {
    dbg(DBG_USR1, ("VM: Finished sending capsule.\n"));
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
  }
  return data;
}



char TOS_EVENT(VM_PHOTO_EVENT)(short data) {
  dbg(DBG_USR1, ("VM_SIMPLE: Got photo data: %i\n", (int)data));
  if (VAR(state) == STATE_DATA_WAIT) {
    push_sense(DATA_PHOTO, data);
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
  }
  return 1;
}

char TOS_EVENT(VM_TEMP_EVENT)(short data) {
  dbg(DBG_USR1, ("VM_SIMPLE: Got temp data: %i\n", (int)data));
  if (VAR(state) == STATE_DATA_WAIT) {
    push_sense(DATA_TEMP, data);
    VAR(state) = STATE_RUN;
    TOS_POST_TASK(run);
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

void execute_add() {
  stack_var* arg_one = pop();
  stack_var* arg_two = pop();
  if (arg_one->type == VAR_SENSE) {
    if (arg_two->type == VAR_SENSE) {
      if (arg_one->sense.type != arg_two->sense.type) {
	dbg(DBG_USR1, ("VM: Tried to combine incompatible sensor values.\n"));
	push_sense(arg_one->sense.type, arg_one->sense.var);
      }
      
    }
    else if (arg_two->type == VAR_VALUE) {
      push_sense(arg_one->sense.type, arg_one->sense.var + arg_two->value.var);
    }
    else if (arg_two->type == VAR_MSG) {
      msg_sense_append(arg_two->msg.var, arg_one->sense.type, arg_one->sense.var);
      push_message(arg_two->msg.var);
    }
  }
  else if (arg_one->type == VAR_MSG) {
    if (arg_two->type == VAR_SENSE) {
      msg_sense_append(arg_one->msg.var, arg_two->sense.type, arg_two->sense.var);
      push_message(arg_one->msg.var);
    }
    else if (arg_two->type == VAR_VALUE) {
      msg_sense_append(arg_one->msg.var, SENSE_TYPE_VALUE, arg_two->value.var);
      push_message(arg_one->msg.var);
    }
    else if (arg_two->type == VAR_MSG) {
      msg_merge(arg_one->msg.var, arg_two->msg.var);
      push_message(arg_one->msg.var);
    }
  }
  else if (arg_one->type == VAR_VALUE) {
    if (arg_two->type == VAR_SENSE) {
      push_sense(arg_two->sense.type, (arg_two->sense.var + arg_one->value.var));
    }
    else if (arg_two->type == VAR_VALUE) {
      push_constant(arg_two->value.var + arg_one->value.var);
    }
    else if (arg_two->type == VAR_MSG) {
      msg_sense_append(arg_two->msg.var, SENSE_TYPE_VALUE, arg_one->value.var);
      push_message(arg_two->msg.var);
    }
  }
  else {
    dbg(DBG_ERROR, ("VM: Tried adding unknown types!\n"));
  }
  return;
}

void compute_vclass(char instr) {
  char arg = xarg(instr);
  if ((instr & xopmask) == OPpushc) {
    dbg(DBG_USR1, ("VM: Pushing constant: %i\n", (int)arg));
    push_constant(arg);
  }
  else if ((instr & xopmask) == OPblez) {
    stack_var* var = pop();
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
      VAR(pc) = arg;
    }
  }
  else {
    dbg(DBG_ERROR, ("VM: Tried to execute unknown instruction: 0x%hhx\n", instr));
    return;
  }
  TOS_POST_TASK(run);
}


void compute_instruction() {
  char instr = VAR(program[(int)VAR(pc)]);

  dbg(DBG_USR1, ("VM: Fetching instruction: 0x%hhx\n", instr));
  if (VAR(state) != STATE_RUN) {
    dbg(DBG_ERROR, ("VM: Tried to execute instruction in non-run state: %i\n", VAR(state)));
    return;
  }
  
  VAR(pc)++;

  if (is_vclass(instr)) {
    compute_vclass(instr);
    return;
  }
  
  switch (instr) {
    stack_var* arg_one;
    stack_var* arg_two;
    short result;
    
  case OPhalt: {
    dbg(DBG_USR1, ("VM: Halting.\n"));
    VAR(state) = STATE_HALT;
    break;
  }
    
  case OPreset: {
    dbg(DBG_USR1, ("VM: Reset.\n"));
    VAR(sp) = 0;
    break;
  }

  case OPadd: {
    dbg(DBG_USR1, ("VM: Adding.\n"));
    execute_add();
    break;
  }

        
  case OPand: {
    dbg(DBG_USR1, ("VM: ANDing.\n"));
    arg_one = pop();
    arg_two = pop();
    if (arg_one->type != VAR_VALUE || arg_two->type != VAR_VALUE) {
      dbg(DBG_ERROR, ("VM: Tried to AND a non-value variable\n"));
    }
    result = arg_one->value.var & arg_two->value.var;
    push_constant(result);
    break;
  }
    
  case OPor: {
    dbg(DBG_USR1, ("VM: ORing\n"));
    arg_one = pop();
    arg_two = pop();
    if (arg_one->type != VAR_VALUE || arg_two->type != VAR_VALUE) {
      dbg(DBG_ERROR, ("VM: Tried to OR a non-value variable\n"));
      break;
    }
    result = arg_one->value.var | arg_two->value.var;
    push_constant(result);
    break;
  }
        
  case OPshiftl: {
    short shift;
    dbg(DBG_USR1, ("VM: Shifting.\n"));
    arg_two = pop();
    arg_one = pop();
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
    push_constant(result);
    break;
  }
    
  case OPshiftr: {
    short shift;
    dbg(DBG_USR1, ("VM: Shifting.\n"));
    arg_two = pop();
    arg_one = pop();
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
    push_constant(result);
    break;
  }
    

  case OPputled: {
    short val;
    arg_one = pop();
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
    push_constant(TOS_LOCAL_ADDRESS);
    break;
  }

  case OPinv: {
    dbg(DBG_USR1, ("VM: Inverting.\n"));
    arg_one = pop();
    if (arg_one->type == VAR_VALUE) {
      short val = arg_one->value.var;
      dbg(DBG_USR1, ("VM: Inverting %i to %i.\n", val, -val));
      push_constant(-val);
    }
    else if (arg_one->type == VAR_SENSE) {
      push_sense(arg_one->sense.type, -(arg_one->sense.var));
    }
    else {
      dbg(DBG_ERROR, ("VM: Tried to invert a message!\n"));
    }
    break;
  }

  case OPcopy: {
    dbg(DBG_USR1, ("VM: Copying stack value.\n"));
    arg_one = pop();
    if (arg_one->type == VAR_VALUE) {
      push_constant(arg_one->value.var);
      push_constant(arg_one->value.var);
    }
    else if (arg_one->type == VAR_MSG) {
      push_message(arg_one->msg.var);
      push_message(arg_one->msg.var);
    }
    else if (arg_one->type == VAR_SENSE) {
      push_sense(arg_one->sense.type, arg_one->sense.var);
      push_sense(arg_one->sense.type, arg_one->sense.var);
    }
    else {
      dbg(DBG_ERROR, ("VM: Trying to copy invalid stack variable\n"));
    }
    break;
  }

  case OPpop: {
    dbg(DBG_USR1, ("VM: Popping stack.\n"));
    pop();
    break;
  }
    
  case OPsense: {
    dbg(DBG_USR1, ("VM: Getting sensor value.\n"));
    arg_one = pop();
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
	push_sense(arg_one->value.var, 0);
	break;
      }
      if (rval) {
	VAR(state) = STATE_DATA_WAIT;
      }
      else {
	dbg(DBG_USR1, ("VM: ADC is busy, retry.\n"));
	push_constant(arg_one->value.var);
	VAR(pc)--; // This will just cause the instruction to be reiussed
      }
    }
    break;
  }
    
  case OPsend: {
    dbg(DBG_USR1, ("VM: Sending a message.\n"));
    arg_one = pop();
    if (arg_one->type != VAR_MSG) {
      dbg(DBG_ERROR, ("VM: Tried to send a non-message!\n"));
      break;
    }
    if (TOS_CALL_COMMAND(VM_SUB_SEND_PACKET)((char*)(arg_one->msg.var), sizeof(vm_msg))) {
      VAR(state) = STATE_PACKET_SEND;
    }
    else {
      //VAR(state) = STATE_WAIT;
      push_message(arg_one->msg.var);
      VAR(pc)--;
    }
    break;
  }

  case OPcast: {
    dbg(DBG_USR1, ("VM: Casting sval to val\n"));
    arg_one = pop();
    if (arg_one->type != VAR_SENSE) {
      dbg(DBG_ERROR, ("VM: Trying to cast a non-sensor value\n"));
    }
    else {
      push_constant(arg_one->sense.var);
    }
    break;
  }
    
  case OPpushm: {
    dbg(DBG_USR1, ("VM: Pushing message.\n"));
    push_message(&VAR(buffer));
    break;
  }
        
  case OPmovm: { // Pop a value off message onto the op stack
    vm_msg* msg;
    char index;
    arg_one = pop();
    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to pop a msg value of a non-message!\n"));
      break;
    }
    msg = arg_one->msg.var;
    index = msg->num_entries;
    if (index <= 0) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to pop a value off an empty message: pushing 0.\n"));
      push_constant(0);
    }
    else {
      msg_entry* entry;
      index--;
      msg->num_entries--;

      entry = &(msg->entries[(int)index]);
      if (entry->type == SENSE_TYPE_VALUE) {
	push_constant(entry->value);
      }
      else {
	push_sense(entry->type, entry->value);
      }
    }
    break;
  }
    
  case OPclear: {
    dbg(DBG_USR1, ("VM: Clearing stack variable.\n"));
    arg_one = pop();
    if (arg_one->type == VAR_SENSE) {
      push_sense(arg_one->sense.type, 0);
    }
    else if (arg_one->type == VAR_VALUE) {
      push_constant(0);
    }
    else if (arg_one->type == VAR_MSG) {
      vm_msg* msg = arg_one->msg.var;
      msg->num_entries = 0;
      push_message(msg);
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
    arg_one = pop();
    dbg(DBG_USR1, ("VM: NOT top of stack.\n"));
    if (arg_one->type == VAR_SENSE) {
      push_sense(arg_one->sense.type, ~(arg_one->sense.var));
    }
    else if (arg_one->type == VAR_VALUE) {
      push_constant(~(arg_one->value.var));
    }
    else {
      dbg(DBG_ERROR, ("VM: Trying to NOT a message.\n"));
      push_message(arg_one->msg.var);
    }
    break;
  }
   
  case OPlog: {
    msg_entry entry;
    arg_one = pop();
    if (arg_one->type == VAR_SENSE) {
      dbg(DBG_USR1, ("VM: Logging sensor value.\n"));
      entry.type = arg_one->sense.type;
      entry.id = (char)(TOS_LOCAL_ADDRESS & 0xff);
      entry.value = arg_one->sense.var;
      logAppend((char*)&(entry), sizeof(msg_entry));
    }
    else if (arg_one->type == VAR_VALUE) {
      dbg(DBG_USR1, ("VM: Logging value.\n"));
      entry.type = SENSE_TYPE_VALUE;
      entry.id = (char)(TOS_LOCAL_ADDRESS & 0xff);
      entry.value = arg_one->value.var;
      logAppend((char*)&(entry), sizeof(msg_entry));
    }
    else if (arg_one->type == VAR_MSG) {
      vm_msg* msg = arg_one->msg.var;
      char* ptr = (char*)&(msg->entries); // Log entries of packet
      dbg(DBG_USR1, ("VM: Logging first 16 bytes of message.\n"));
      logAppend(ptr, LOGSIZE);
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to log invalid type!\n"));
    }
    break;
  }

  case OPlogr: { // msg,#,...
    arg_one = pop(); // Must be msg (buffer to read into)
    arg_two = pop(); // Must be # (log line to read)

    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to read log into non-message type!\n"));
      VAR(state) = STATE_HALT; 
    }
    else if (arg_two->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log line index non-value type!\n"));
      VAR(state) = STATE_HALT; 
    }
    else {
      short line;
      line = arg_two->value.var + 16; // First 16 lines of EEPROM are reserved
      push_message(arg_one->msg.var);
      dbg(DBG_USR1, ("VM: Trying to read line %i into message.\n", (int)line));
      line = TOS_CALL_COMMAND(VM_SUB_LOG_READ)(line, (char*)arg_one->msg.var->entries);
      
      if (!line) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Log read failed. Retry.\n"));
	push_constant(arg_two->value.var);
	VAR(pc)--;
      }
      else {
	VAR(state) = STATE_LOG_WAIT;
      }
    }
    break;
  }

  case OPlogr2: { // #,msg,...
    arg_two = pop(); // Must be value (index in log)
    arg_one = pop(); // Must be msg (buffer to read into)

    if (arg_one->type != VAR_MSG) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Tried to read log into non-message type!\n"));
      VAR(state) = STATE_HALT; 
    }
    else if (arg_two->type != VAR_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log line index non-value type!\n"));
      VAR(state) = STATE_HALT; 
    }
    else {
      short line;
      line = arg_two->value.var + 16; // First 16 lines of EEPROM are reserved
      push_message(arg_one->msg.var);
      dbg(DBG_USR1, ("VM: Trying to read line %i into message.\n", (int)line));
      line = TOS_CALL_COMMAND(VM_SUB_LOG_READ)(line, (char*)arg_one->msg.var->entries);
      
      if (!line) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Log read failed. Retry.\n"));
	push_constant(arg_two->value.var);
	VAR(pc)--;
      }
      else {
	VAR(state) = STATE_LOG_WAIT;
      }
    }
    break;
  }

  case OPforw: {
    int i;
    dbg(DBG_USR1, ("VM: Forwarding code capsule.\n"));
    for (i = 1; i <= PGMSIZE ; i++) {
      VAR(capsule).data[i] = VAR(program)[i-1];
    }
    VAR(capsule).data[0] = VAR(version);
    i = TOS_CALL_COMMAND(VM_SUB_SEND_CAPSULE)(TOS_BCAST_ADDR, (char)0x1e, (TOS_MsgPtr)&(VAR(capsule)));
    
    if (i) {
      VAR(state) = STATE_PACKET_SEND;
    }
    else {
      VAR(pc)--;
    }
    break;
  }
  default:
    dbg(DBG_ERROR, ("VM: Unrecognized instruction: 0x%hhx!\n", instr));
  }
  
  if (VAR(state) == STATE_RUN) {
    TOS_POST_TASK(run);
  }
  
}









