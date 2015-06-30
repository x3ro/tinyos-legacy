/*									tab:4
 * mate_comm.c - Mate utility communication functions.
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
 * Functions for installing code, sending packets, logging data, etc.
 */

void install_capsule(capsule_t* capsule) {
  int i;
  char version = capsule->version;
  char type = capsule->type;
  
  dbg(DBG_USR1, ("VM: Received new code capsule %hhi v%hhi len:%hhi... updating.\n", type, version, capsule->length));
  VAR(code)[(int)type].capsule.version = version;
  VAR(code)[(int)type].usedVars = 0;
  VAR(code)[(int)type].capsule.options = capsule->options;
  
  for (i = 0; i < capsule->length; i++) {
    char instr = capsule->code[i];
    VAR(code)[(int)type].capsule.code[i] = instr;
    if (is_vclass(instr)) {
      char arg = varg(instr);
      VAR(code)[(int)type].usedVars |= (1 << arg);
      dbg(DBG_USR2, ("VM: Capsule %i needs lock 0x%x\n", (int)type, (int)arg));
    }
  }
  dbg(DBG_USR2, ("VM: Capsule %i: 0x%hx\n", (int)type,VAR(code)[(int)type].usedVars));
  

  // Analyze subroutines
  for (i = 0; i <= CAPSULE_SUB3; i++) {
  //for (i = 0; i < 0; i++) {
    int j, k;
    for (j = 0; j <= CAPSULE_SUB3; j++) {
      capsule_t* test_capsule = &VAR(code)[j].capsule;
      for (k = 0; k < test_capsule->length; k++) {
	char instr = test_capsule->code[k];
	if (is_call(instr)) {
	  char arg = carg(instr);
	  VAR(code)[(int)j].usedVars |= VAR(code)[(int)arg].usedVars;
	  dbg(DBG_USR2, ("VM: Subroutine %i includes locks from subroutine %i\n", j, (int)arg));
	}
	//else if (instr == OPsendr) {
	//  VAR(code)[(int)j].usedVars |= VAR(code)[CAPSULE_SEND].usedVars;
	//	}
      }
    }
    dbg(DBG_USR2, ("VM: Subroutine %i :%hx\n", (int)i, VAR(code)[(int)i].usedVars));
  }

  for (i = CAPSULE_CLOCK; i < CAPSULE_NUM; i++) {
    int k;
    capsule_t* test_capsule = &VAR(code)[i].capsule;
    for (k = 0; k < test_capsule->length; k++) {
      char instr = test_capsule->code[k];
      if (is_call(instr)) {
	char arg = carg(instr);
	VAR(code)[(int)i].usedVars |= VAR(code)[(int)arg].usedVars;
	dbg(DBG_USR2, ("VM: Capsule %i includes locks from subroutine %i -> 0x%x\n", i, (int)arg, VAR(code)[(int)i].usedVars));
      }
      //else if (instr == OPsendr) {
      //VAR(code)[(int)i].usedVars |= VAR(code)[CAPSULE_SEND].usedVars;
      //}
    }
    dbg(DBG_USR2, ("VM: Capsule %i :0x%hx\n", (int)i, VAR(code)[(int)i].usedVars));
  }
  
  //VAR(code)[CAPSULE_CLOCK].usedVars;
  //VAR(sendContext).usedVars = VAR(code)[CAPSULE_SEND].usedVars;
  //VAR(recvContext).usedVars = VAR(code)[CAPSULE_RECV].usedVars;

  if (type == CAPSULE_CLOCK) {
    resetContext(&VAR(clockContext));
    VAR(clockCounter) = 0;
    push_value_operand(&VAR(clockContext), 0);
  }
  else if (type == CAPSULE_SEND) {
    resetContext(&VAR(sendContext));
   }
  else if (type == CAPSULE_RECV) {
    resetContext(&VAR(recvContext));
   }
  else {
    resetContext(&VAR(clockContext));
    resetContext(&VAR(sendContext));
    resetContext(&VAR(recvContext));
    push_value_operand(&VAR(clockContext), 0);
  }
  

  dbg_clear(DBG_USR1, ("\n"));
  VAR(errorContext) = 0;
  return;
}

void logAppend(context_t* context, vm_buffer* buffer) {
  if (VAR(logWaitingContext) != NULL) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Logger busy! Retrying append.\n"));
    context->pc--;
  }
  else {
    int i;
    for (i = 0; i < 16; i++) {
      ((char*)&(VAR(logBuffer)))[i] = ((char*)buffer)[i];
    }
    if (TOS_CALL_COMMAND(VM_SUB_LOG_APPEND)((char*)buffer)) {
      context->state = STATE_LOG_WAIT;
      yield(context);
      VAR(loggerIndex)++;
      VAR(logWaitingContext) = context;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log append failed! Retrying.\n"));
      context->pc--;
    }
  }
}

void logWrite(context_t* context, short line, vm_buffer* buffer) {
  if (VAR(logWaitingContext) != NULL) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Logger busy! Retrying write.\n"));
    context->pc--;
  }
  else {
    int i;
    for (i = 0; i < 16; i++) {
      ((char*)&(VAR(logBuffer)))[i] = ((char*)buffer)[i];
    }
    if (TOS_CALL_COMMAND(VM_SUB_LOG_WRITE)(line, (char*)buffer)) {
      context->state = STATE_LOG_WAIT;
      yield(context);
      VAR(loggerIndex) = line;
      VAR(logWaitingContext) = context;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Log write failed! Retrying.\n"));
      context->pc--;
    }
  }
}

void logRead(context_t* context, short line, vm_buffer* buffer) {
  char rval;
  VAR(logWaitingContext) = context;
  push_buffer_operand(context, buffer);
  dbg(DBG_USR1, ("VM: Trying to read line %i into message.\n", (int)line));
  rval = TOS_CALL_COMMAND(VM_SUB_LOG_READ)(line + LOGGER_START_LINE, 
					   (char*)&VAR(logBuffer));
  
  if (!rval) {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Log read failed. Retry.\n"));
    push_value_operand(context, line);
    VAR(logWaitingContext) = NULL;
    context->pc--;
  }
  else {
    context->state = STATE_LOG_WAIT;
    // yield(context);
  }
}

char forward_capsule(char codeNum) {
  int i;
  char rval;
  capsule_t* capsule;
  if ((codeNum < 0) ||
      (codeNum >= CAPSULE_NUM) ||
      ((VAR(code)[(int)codeNum].capsule.options & CAPSULE_FORW) == 0)) {
    return 0;
  }
  capsule = (capsule_t*)(VAR(capsuleMsgPtr)->msg.data);
  dbg(DBG_USR1, ("VM: Forwarding code capsule %hhi.\n", codeNum));
    
  for (i = 0; i <= PGMSIZE ; i++) {
    capsule->code[i] = VAR(code)[(int)codeNum].capsule.code[i];
  }
  capsule->version = VAR(code)[(int)codeNum].capsule.version;
  capsule->type = VAR(code)[(int)codeNum].capsule.type;
  rval = TOS_CALL_COMMAND(VM_SUB_SEND_CAPSULE)(TOS_BCAST_ADDR, (char)MATE_CAPSULE, (VAR(capsuleMsgPtr)), sizeof(capsule_t));
  return rval;
}

void send_raw_packet(context_t* context, vm_buffer* buffer) {
  dbg(DBG_USR1, ("VM: Context %i trying to send raw packet.\n", (int)context->which));
  if (VAR(sendWaitingContext) != 0) {
    context->pc--;
    push_buffer_operand(context, buffer);
    return;
  }
  else {
    int i;
    char size = (buffer->size * 2) + 2;
    stack_var* addrVar = pop_operand(context);
    if (check_types(context, addrVar, VAR_V)) {
      for(i = 0; i < MATE_HEADERSIZE; i++) {
        VAR(raw_packet).msg.data[i] = ((char*)context->header)[i];
      }
      ((short*)VAR(raw_packet).msg.data)[0] = VAR(receivedPackets);
      ((short*)VAR(raw_packet).msg.data)[1] = VAR(droppedPackets);
      
      for(i = 0; i < size; i++) {
	VAR(raw_packet).msg.data[MATE_HEADERSIZE + i] = ((char*)buffer)[i];
      }
      if (TOS_CALL_COMMAND(VM_SUB_SEND_RAW)(TOS_BCAST_ADDR, MATE_RAW, &(VAR(raw_packet)), size + MATE_HEADERSIZE)) {
      	VAR(sendWaitingContext) = context;
	context->state = STATE_PACKET_SEND;
	yield(context);
      }
      else {
	context->pc--;
	push_operand(context, addrVar);
	push_buffer_operand(context, buffer);
      }
    }
  }
}

void send_to_uart(context_t* context, vm_buffer* buffer) {
  if (VAR(sendWaitingContext) != 0) {
    context->pc--;
    push_buffer_operand(context, buffer);
    return;
  }
  else {
    int i;
    char size = (buffer->size * 2) + 2;
    size = 18;
    for(i = 0; i < MATE_HEADERSIZE; i++) {
      VAR(raw_packet).msg.data[i] = ((char*)context->header)[i];
    }

    ((short*)VAR(raw_packet).msg.data)[0] = VAR(receivedPackets);
    ((short*)VAR(raw_packet).msg.data)[1] = VAR(droppedPackets);
    
    for(i = 0; i < size; i++) {
      VAR(raw_packet).msg.data[i + MATE_HEADERSIZE] = ((char*)buffer)[i];
    }
    if (TOS_CALL_COMMAND(VM_SUB_SEND_RAW)(TOS_UART_ADDR, MATE_RAW, &VAR(raw_packet), size + MATE_HEADERSIZE)) {
      VAR(sendWaitingContext) = context;
      context->state = STATE_PACKET_SEND;
      yield(context);
    }
    else {
      context->pc--;
      push_buffer_operand(context, buffer);
    }
  }
}
