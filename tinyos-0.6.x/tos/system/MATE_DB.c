/*									tab:4
 * MATE_DB.c - Mate designed to support databases
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
 * A simple virtual machine for TinyOS. This version of the VM includes
 * operations intended to support database operations.
 */

#include "tos.h"
#include "mate_db_instr.h"
#include "mate_types.h"
#include "MATE_DB.h"
#include "dbg.h"

#define NULL                     0
#define LOGGER_START_LINE        4 //Must be same as LOGGER.c:APPEND_ADDR_START
#define LOGSIZE                 10

#define VAR_V                    MATE_TYPE_VALUE
#define VAR_S                    MATE_TYPE_SENSE
#define VAR_B                    MATE_TYPE_BUFFER
#define VAR_VS                   (VAR_V | VAR_S)
#define VAR_VB                   (VAR_V | VAR_B)
#define VAR_SB                   (VAR_S | VAR_B)
#define VAR_VSB                  (VAR_V | VAR_S | VAR_B)
#define VAR_ANY                  VAR_VSB

#define STATE_HALT               0
#define STATE_RUN                1
#define STATE_DATA_WAIT          2
#define STATE_PACKET_WAIT        3
#define STATE_PACKET_SEND        4
#define STATE_CAPSULE_SEND       5
#define STATE_LOG_WAIT           6
#define STATE_ERROR              7
#define STATE_LOCK_WAIT          8

#define SENSE_TYPE_VALUE        -1


#define TOS_FRAME_TYPE INTERP_frame
TOS_FRAME_BEGIN(INTERP_frame) {
  context_t clockContext;
  context_t sendContext;
  context_t recvContext;
    
  stack_var variables[MATE_HEAPSIZE];
  stack_var tmp; // Used in buffer access instructions

  lock_t locks[MATE_HEAPSIZE];

  mate_queue readyQueue;
  
  vm_buffer buffers[2];
  vm_buffer sendBuffer;
  vm_buffer logBuffer;
  
  capsule_buf code[CAPSULE_NUM];
  
  char sense_type;
  char loggerIndex;

  char clockCounter;
  char clockTrigger;

  char sendContextActive;
  char recvContextActive;

  char errorCapsule;
  char errorInstr;
  char errorVersion;
  char errorReason;

  short receivedPackets;
  short droppedPackets;
  
  context_t* errorContext;
  context_t* logWaitingContext;
  context_t* sendWaitingContext;
  context_t* adcWaitingContext;

  context_t* externalContext;
  AMBuffer capsuleMsg;
  AMBuffer_ptr capsuleMsgPtr;
  AMBuffer raw_packet;
  AMBuffer raw_recv;
}
TOS_FRAME_END(INTERP_frame);

typedef struct {
  short src;
  short dest;
  short hc;
  short data;
} routing_msg;

AMBuffer inject_msg;

#define TICK12ps 85,3
#define TICK11ps 93,3
#define TICK10ps 102,3
#define TICK9ps 114,3
#define TICK8ps 128,3

#define TICK7ps 73,4
#define TICK6ps 85,4
#define TICK5ps 102,4
#define TICK4ps 128,4
#define TICK3ps 192,4

#define TICK2ps 128,5
#define TICK1ps 128,6

#include "mate_util.c"

char TOS_COMMAND(VM_INIT)(){
  int i;
  TOS_CALL_COMMAND(VM_SUB_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(VM_SUB_NET_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(VM_SUB_DATA_INIT)();       /* initialize lower components */
  TOS_CALL_COMMAND(VM_SUB_LOG_INIT)();       /* initialize lower components */

  TOS_CALL_COMMAND(VM_SUB_CLOCK_INIT)(TICK12ps);

  list_init(&VAR(readyQueue).queue);
  //list_init(&VAR(runQueue).queue);
  //list_init(&VAR(recvFreeQueue).queue);

  //mqueue_enqueue(&VAR(clockContext), &VAR(recvFreeQueue), &VAR(recvContext));
  
  inject_msg.msg.hdr.dest = 0xffff;
  inject_msg.msg.hdr.src = 0x12;
  inject_msg.msg.hdr.type = MATE_RAW;
  inject_msg.msg.hdr.group = LOCAL_GROUP;
  {
    routing_msg* msg = (routing_msg*)inject_msg.msg.data;
    msg->src = 0xeeee;
    msg->dest = 0x3412;
    msg->hc = 1;
    msg->data = 0;
  }

  
  for (i = 0; i < CAPSULE_NUM; i++) {
    VAR(code)[i].capsule.length = PGMSIZE;
    VAR(code)[i].capsule.type = i;
    VAR(code)[i].capsule.version = -1;
    VAR(code)[i].capsule.code[0] = OPhalt;
  }

  for (i = 0; i < MATE_HEAPSIZE; i++) {
    VAR(variables)[i].type = MATE_TYPE_VALUE;
    VAR(variables)[i].value.var = 0;
  }
  
  resetContext(&VAR(clockContext));
  VAR(clockContext).code        = &VAR(code)[CAPSULE_CLOCK];
  VAR(clockContext).which       = CAPSULE_CLOCK;

  resetContext(&VAR(sendContext));
  VAR(sendContext).code         = &VAR(code)[CAPSULE_SEND];
  VAR(sendContext).which        = CAPSULE_SEND;

  resetContext(&VAR(recvContext));
  VAR(recvContext).code         = &VAR(code)[CAPSULE_RECV];
  VAR(recvContext).which        = CAPSULE_RECV;

  VAR(capsuleMsgPtr)         = &(VAR(capsuleMsg));

  VAR(clockTrigger)            = 1;
  VAR(clockCounter)            = 0;
  VAR(sendContextActive)         = 0;

  
  VAR(buffers)[0].type = MATE_DATA_NONE;
  VAR(buffers)[1].type = MATE_DATA_NONE;
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

#define SERIAL_EXEC
char TOS_COMMAND(VM_START)(){
  int index = 0;
  VAR(errorContext) = 0;
  push_value_operand(&(VAR(clockContext)), 0);
  
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 28);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPputled; 
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbpush0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbclear;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsense;

  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcast;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcopy;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPsetvar | 0);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsendr;

#ifdef SERIAL_EXEC
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPgetvar | 5);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPpop;
#else
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPgetvar | CAPSULE_CLOCK);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPpop;
#endif  

  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_CLOCK].capsule.length = index;

  index = 0;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPpushc | 25);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPputled; 
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPpushc);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPlnot;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPswap;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPsendr;
#ifdef SERIAL_EXEC
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPgetvar | 5);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpop;
#else
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPgetvar | CAPSULE_SEND);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpop;
#endif  
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_SEND].capsule.length = index;

  index = 0;

  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPpushc | 26);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPputled; 
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPbhead;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPpop;
#ifdef SERIAL_EXEC
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPgetvar | 5);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPpop;
#else
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPgetvar | CAPSULE_RECV);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPpop;
#endif  
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPpushc | 32);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPpushc | 2);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPshiftl;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPcpull;
  VAR(code)[CAPSULE_RECV].capsule.code[index] = (char)(OPjumpc | index);
  index++;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_RECV].capsule.length = index;

  
  /*    
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcopy;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 7);

  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPland;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPputled;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPpop;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbpush0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPuart;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_CLOCK].capsule.length = index;
 {
    int i;
    for (i = 0; i < PGMSIZE; i++) {
      char instr = (char)((i % 32) | OPgetvar);
      VAR(code)[CAPSULE_SUB0].capsule.code[i] = instr;
      VAR(code)[CAPSULE_SUB1].capsule.code[i] = instr;
      VAR(code)[CAPSULE_SUB2].capsule.code[i] = instr;
      VAR(code)[CAPSULE_SUB3].capsule.code[i] = instr;
      VAR(code)[CAPSULE_RECV].capsule.code[i] = instr;
      VAR(code)[CAPSULE_SEND].capsule.code[i] = instr;
    }
    VAR(code)[CAPSULE_SUB0].capsule.code[0] = OPcall1;
    VAR(code)[CAPSULE_SUB1].capsule.code[0] = OPcall2;
    VAR(code)[CAPSULE_SUB2].capsule.code[0] = OPcall3;
    VAR(code)[CAPSULE_SEND].capsule.code[17] = OPcall0;
    VAR(code)[CAPSULE_RECV].capsule.code[17] = OPcall0;
    
  }
  VAR(code)[CAPSULE_SUB0].capsule.length = PGMSIZE;
  VAR(code)[CAPSULE_SUB1].capsule.length = PGMSIZE;
  VAR(code)[CAPSULE_SUB2].capsule.length = PGMSIZE;
  VAR(code)[CAPSULE_SUB3].capsule.length = PGMSIZE;
  //VAR(code)[CAPSULE_CLOCK].capsule.length = PGMSIZE;
  VAR(code)[CAPSULE_SEND].capsule.length = PGMSIZE;
  VAR(code)[CAPSULE_RECV].capsule.length = PGMSIZE;
  */

  /* data aggregation program 
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 25);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPputled;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsense;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcast;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbpush0;
  
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbsize;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 8);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPgt;

  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPjumps | 17);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcopy;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsendr;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcall2;
  
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcall0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcall1;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPpop;
  
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_CLOCK].capsule.length = index;
  index = 0;
  
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPsetvar | 3);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPpushc);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPbyank;

  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPgetvar | 3);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPsetvar | 3);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPbsize;

  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPneq; 
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPjumps | 2);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPret;

  VAR(code)[CAPSULE_SUB0].capsule.length = index;
  
  index = 0;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPpop;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPgetvar | 3);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPpushc | 5);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPshiftr;

  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPcopy;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPsetvar | 3);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPsetvar | 0);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPgetvar | 1);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPpushc | 8);
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPsetvar | 1);
  
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPret;
  VAR(code)[CAPSULE_SUB1].capsule.length = index;

  index = 0;
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = OPshiftr;
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPsetvar | 0);

  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetvar | 1);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = OPshiftr;
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPsetvar | 1);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = OPret;
  VAR(code)[CAPSULE_SUB2].capsule.length = index;

  index = 0;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPpop;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPcall0;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPcall1;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_RECV].capsule.length = index;

  index = 0;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpop;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPpushc | 26);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPputled;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPlnot;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPswap;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPsendr;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPhalt;
  
  VAR(code)[CAPSULE_SEND].capsule.length = index;
  */
  
  /* Synchronization testing
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPcopy;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPsetvar | 0);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPpushc | 7);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPland;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPputled;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPret;
  
  index = 0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcall0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbpush0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbclear;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 0);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPunlock;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsendr;  
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPhalt;

  index = 0;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPgetvar | 0);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpop;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPlnot;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPswap;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPsendr;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPhalt;
  
  index = 0;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPgetms;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPid;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPeq;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPjumps | 5);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPbfull;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPjumps | 8);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPcall0;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPgetvar | 1);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPsendr;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPhalt; 
  */
  /* Ad-hoc routing 
  index = 0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcall0; // Check timer
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPcall1; // Check if parent
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsense;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbpush0;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPbclear;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPsendr;
  VAR(code)[CAPSULE_CLOCK].capsule.code[index++] = OPhalt;

  index = 0;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPcall2;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPgetms | 1);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPid;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPneq;
  
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = (char)(OPjumps | 6);
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPsendr;
  VAR(code)[CAPSULE_RECV].capsule.code[index++] = OPhalt;

  index = 0;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPcall1;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPgetvar);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPsetms | 1);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPid);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPsetms);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPgetvar | 3);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPsetms | 2);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPlnot;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPswap;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPunlock;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = (char)(OPpushc | 3);
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPunlock;
  VAR(code)[CAPSULE_SEND].capsule.code[index++] = OPsendr;
  
  index = 0;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPgetvar | 2);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPcopy;
  
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPsetvar | 2);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPpushc | 4);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPlte;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPjumps | 9);
  // If the counter < 4, return 
  
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPret;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPpushc | 0);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPsetvar | 2);
  
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPgetvar | 1);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPnot;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPpushc;

  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPsetvar | 1);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = (char)(OPjumps | 17);
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPret;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPpushc;

  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPsetvar;
  VAR(code)[CAPSULE_SUB0].capsule.code[index++] = OPhalt;

  index = 0;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPgetvar;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPpushc;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPneq;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = (char)(OPjumps | 5);

  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPhalt;
  VAR(code)[CAPSULE_SUB1].capsule.code[index++] = OPret;

  index = 0;
  index = 0;
  // If the new hopcount isn't better, jump past change code
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetms | 2);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetvar | 3);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = OPgte;
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetms | 2);
  
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPpushc);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPeq);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPor);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPjumps | 10);
  
  // Set new parent
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetms | 0);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPsetvar| 0);

  // If packet isn't from new parent, jump past set heard
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetms | 0);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetvar| 0);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPneq);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPjumps | 20);

  // Mark parent heard
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPgetms | 2);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = OPadd;
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPsetvar | 3);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPpushc | 1);
  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = (char)(OPsetvar | 1);

  VAR(code)[CAPSULE_SUB2].capsule.code[index++] = OPret;
  */
  //VAR(code)[CAPSULE_CLOCK].capsule.options = CAPSULE_FORW;
  
  install_capsule(&VAR(code)[CAPSULE_CLOCK].capsule);
  install_capsule(&VAR(code)[CAPSULE_SEND].capsule);
  install_capsule(&VAR(code)[CAPSULE_RECV].capsule);
  install_capsule(&VAR(code)[CAPSULE_SUB0].capsule);
  install_capsule(&VAR(code)[CAPSULE_SUB1].capsule);
  install_capsule(&VAR(code)[CAPSULE_SUB2].capsule);
  install_capsule(&VAR(code)[CAPSULE_SUB3].capsule);

  return 1;
}

/* run - run interpeter from current state
 */

TOS_TASK(run_clock);
TOS_TASK(run_send);
TOS_TASK(run_recv);
TOS_TASK(run_extern);

TOS_TASK(run_clock) {
  compute_instruction(&(VAR(clockContext)));
  if (VAR(clockContext).state == STATE_RUN) {
    executeContext(&VAR(clockContext));
  }
}

TOS_TASK(run_send) {
  compute_instruction(&(VAR(sendContext)));  
  if (VAR(sendContext).state == STATE_RUN) {
    executeContext(&(VAR(sendContext)));
  }
}

TOS_TASK(run_recv) {
  compute_instruction(&(VAR(recvContext)));
  if (VAR(recvContext).state == STATE_RUN) {
    executeContext(&(VAR(recvContext)));
  }
}

TOS_TASK(run_extern) {
  if (VAR(externalContext)) {
    compute_instruction(VAR(externalContext));
    if (VAR(externalContext)->state == STATE_RUN) {
      executeContext(VAR(externalContext));
    }
  }
}

void executeContext(context_t* context) {
#ifdef TOSSIM
  // sleep(1);
#endif
  if (VAR(errorContext) || context->state == STATE_HALT) {return;}
  if (context == &VAR(clockContext)) {
    TOS_POST_TASK(run_clock);
  }
  else if (context == &VAR(sendContext)) {
    TOS_POST_TASK(run_send);
  }
  else if (context == &VAR(recvContext)) {
    TOS_POST_TASK(run_recv);
  }
  else if (context == VAR(externalContext)) {
    TOS_POST_TASK(run_extern);
  }
}


char TOS_COMMAND(VM_RUN)(context_t* context) {
  if (VAR(externalContext) == 0) {
    VAR(externalContext) = context;
    resumeContext(context, context);
    return 1;
  }
  else {return 0;}
}

char TOS_EVENT(MATE_DB_NULL_FUNC)(char code){return 1;}

char TOS_EVENT(VM_LOG_READ_EVENT)(char* data, char success) {
  context_t* context = VAR(logWaitingContext);
  
  if (context->state == STATE_LOG_WAIT) {
    stack_var* arg_one = pop_operand(context);
    dbg(DBG_USR1, ("VM: Log read completed.\n"));
    if (success) {
      if (data != (char*)arg_one->buf.var) {
	dbg(DBG_USR1|DBG_ERROR, ("VM: Log read into wrong buffer!\n"));
      }
      push_buffer_operand(context, arg_one->buf.var);
    }
    context->state = STATE_RUN;
    resumeContext(context, context);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Log read returned when waiting stack was not in LOG_WAIT state.\n"));
  }
   
  return 1;
}

char TOS_EVENT(VM_SEND_DONE)(char* msg) {
  context_t* context = VAR(sendWaitingContext);
  dbg(DBG_USR1, ("VM: Message send done.\n"));
  if (context && context->state == STATE_PACKET_SEND) {
    VAR(sendWaitingContext) = 0;
    context->state = STATE_RUN;
    resumeContext(context, context);
    dbg(DBG_USR1, ("VM: Resume execution on capsule %hhi.\n", context->code->capsule.type));
  }
  return 1;
}

char TOS_EVENT(VM_CAPSULE_SEND_DONE)(AMBuffer_ptr packet) {
  context_t* context = VAR(sendWaitingContext);
  if (context && context->state == STATE_CAPSULE_SEND) {
    dbg(DBG_USR1, ("VM: Capsule send done.\n"));
    VAR(sendWaitingContext) = 0;
    context->state = STATE_RUN;
    resumeContext(context, context);
    dbg(DBG_USR1, ("VM: Resume execution on capsule %hhi.\n", context->code->capsule.type));
  }
  return 1;
}

TOS_TASK(clock_task) {
  VAR(clockCounter)++;
  
  if (VAR(clockCounter) >= VAR(clockTrigger) && 
      (VAR(clockContext).state == STATE_HALT)) {
    //    short idle;
    //short rand;
    VAR(clockCounter) = 0;
    VAR(clockContext).rstack.sp = 0;
    VAR(clockContext).pc = 0;
    VAR(clockContext).code = &VAR(code)[CAPSULE_CLOCK];
    dbg(DBG_USR1, ("VM: Executing clock context: %i,%i, opstack depth %i.\n", (int)VAR(clockCounter), (int)VAR(clockTrigger), (int)VAR(clockContext).stack.sp));

    //idle = TOS_CALL_COMMAND(VM_SUB_NET_ACTIVITY)();
    //rand = TOS_CALL_COMMAND(VM_SUB_RAND)() & 0x7fff;
    //dbg(DBG_USR1, ("VM: Idle: %hi, rand: %hi\n", idle, rand));
    //if (rand < idle) {
    //    if (forward_capsule(rand & 7) && VAR(sendWaitingContext) == 0) {
    //	  VAR(sendWaitingContext) = &VAR(clockContext);
    //	  VAR(clockContext).state = STATE_PACKET_SEND;
    //	  dbg(DBG_USR1, ("VM: Forwarding capsule %i\n", (rand & 7)));
    //	}
    // }

    

    VAR(clockContext).state = STATE_RUN;
    dbg(DBG_USR2, ("VM: Setting acquireSet of clock context to 0x%x\n", (int)VAR(code)[CAPSULE_CLOCK].usedVars));
    VAR(clockContext).acquireSet = VAR(code)[CAPSULE_CLOCK].usedVars;
    resumeContext(&VAR(clockContext), &VAR(clockContext));
  }
  else {
    dbg(DBG_USR1, ("VM: Clock event handled, incremented counter to %i, waiting for %i\n", (int)VAR(clockCounter), (int)VAR(clockTrigger)));
    VAR(raw_packet).msg.data[0] = VAR(clockContext).state;

    if (!TOS_CALL_COMMAND(VM_SUB_SEND_RAW)(TOS_UART_ADDR, MATE_ERROR, &VAR(raw_packet), 10)) {
      TOS_CALL_COMMAND(RED_LED_TOGGLE)();
    }
  }
}

TOS_TASK(error_task) {
  TOS_CALL_COMMAND(VM_LEDr_toggle)();
  TOS_CALL_COMMAND(VM_LEDg_toggle)();
  TOS_CALL_COMMAND(VM_LEDy_toggle)();
  VAR(raw_packet).msg.data[0] = VAR(errorCapsule);
  VAR(raw_packet).msg.data[1] = VAR(errorInstr);
  VAR(raw_packet).msg.data[2] = VAR(errorContext)->which;
  VAR(raw_packet).msg.data[3] = VAR(errorReason);
  VAR(raw_packet).msg.data[4] = VAR(errorVersion);

  TOS_CALL_COMMAND(VM_SUB_SEND_RAW)(TOS_UART_ADDR, MATE_ERROR, &VAR(raw_packet), 10);
}

/* Clock Event Handler  */
void TOS_EVENT(VM_CLOCK_EVENT)(){

  if (!VAR(errorContext)) {
    TOS_POST_TASK(clock_task); // Launch task to make synchronous
  }
  else {
    TOS_POST_TASK(error_task);
  }
}

TOS_TASK(write_success_task) {
  int i;
  context_t* context = VAR(logWaitingContext);
  if (context->state == STATE_LOG_WAIT) {
    VAR(logWaitingContext) = 0;
    dbg(DBG_USR1, ("VM: Log write completed.\n"));
    context->state = STATE_RUN;
    for (i = 0; i < LOGSIZE; i++) {
      VAR(logBuffer).entries[i] = (char)0;
    }
    VAR(logBuffer).type = MATE_TYPE_INVALID;
    VAR(logBuffer).size = 0;
    resumeContext(context, context);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Mixup with log writing context; stored context in improper state.\n"));
  }
}

TOS_TASK(write_fail_task) {
  int i;
  context_t* context = VAR(logWaitingContext);
  if (context->state == STATE_LOG_WAIT) {
    VAR(logWaitingContext) = 0;
    dbg(DBG_USR1|DBG_ERROR, ("VM: Log write unsuccessful!\n"));
    haltContext(context);
    context->state = STATE_HALT;
    for (i = 0; i < LOGSIZE; i++) {
      VAR(logBuffer).entries[i] = (char)0;
    }
    VAR(logBuffer).type = MATE_TYPE_INVALID;
    VAR(logBuffer).size = 0;
    resumeContext(context, context);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Mixup with log writing context; stored context in improper state.\n"));
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
AMBuffer_ptr TOS_EVENT(VM_CAPSULE_RECEIVE)(AMBuffer_ptr data){
  capsule_t* capsule = (capsule_t*)data->msg.data;
  char type = capsule->type;
  char version = capsule->version;
  short vdiff = version - VAR(code)[(int)type].capsule.version;
  if ((vdiff < 64 && vdiff > 0) || (vdiff < -64 && vdiff > -128)) {
    install_capsule(capsule);
  }
  else {
    dbg(DBG_USR1, ("VM: Received new code capsule... too old: current: %hhi, capsule: %hhi.\n", VAR(code)[(int)type].capsule.version, version));
  }
  return data;
}

char TOS_EVENT(VM_SEND_TIMEOUT)(AMBuffer_ptr msg) {
  return 1;
}

TOS_TASK(raw_recv) {
  int i;
  vm_packet* packet;
  char* context_header;
  packet = (vm_packet*)VAR(raw_recv).msg.data;
  context_header = (char*)(VAR(recvContext).header);
  dbg(DBG_USR1|DBG_ROUTE, ("VM: Receive handler task executing.\n"));
  for (i = 0; i < MATE_HEADERSIZE; i++) {
    context_header[i] = packet->header[i];
  }
  resetContext(&VAR(recvContext));
  push_buffer_operand(&(VAR(recvContext)), &(packet->payload));
  VAR(recvContext).state = STATE_RUN;
  VAR(recvContext).acquireSet = VAR(code)[CAPSULE_RECV].usedVars;
  resumeContext(&VAR(recvContext), &VAR(recvContext));
  VAR(recvContextActive) = 1;
  VAR(receivedPackets)++;
}

AMBuffer_ptr TOS_EVENT(VM_RAW_RECEIVE)(AMBuffer_ptr msg) {
  int i;
  dbg(DBG_USR3, ("VM: Packet reception event.\n"));  
  if (VAR(recvContext).state == STATE_HALT && !VAR(errorContext)) {
    {
      int i;
      dbg(DBG_USR1, ("VM: Received raw packet:\n\t"));
      for (i = 0; i < sizeof(TOS_Msg); i++) {
	dbg_clear(DBG_USR1, ("%02hhx ", ((char*)msg)[i]));
      }
      dbg_clear(DBG_USR1, ("\n"));
    }
    memcpy(&VAR(raw_recv), msg, sizeof(AMBuffer));
    VAR(recvContextActive) = STATE_RUN;
    TOS_POST_TASK(raw_recv);
  }
  else {
    VAR(droppedPackets)++;
    dbg(DBG_USR3|DBG_ROUTE, ("VM: Can't handled two receive packets at once. Dropping second one.\n"));
  }
  return msg;
}

char TOS_EVENT(VM_PHOTO_EVENT)(short data) {
  context_t* context = VAR(adcWaitingContext);
  dbg(DBG_USR1, ("VM: Got photo data: %i\n", (int)data));

  if (context->state == STATE_DATA_WAIT) {
    push_sense_operand(context, MATE_DATA_PHOTO, data);
    context->state = STATE_RUN;
    resumeContext(context, context);
  }
  
  return 1;
}

char TOS_EVENT(VM_TEMP_EVENT)(short data) {
  context_t* context = VAR(adcWaitingContext);
  dbg(DBG_USR1, ("VM: Got temp data: %i\n", (int)data));

  if (context->state == STATE_DATA_WAIT) {
    push_sense_operand(context, MATE_DATA_TEMP, data);
    context->state = STATE_RUN;
    resumeContext(context, context);
  }
  return 1;
}


char buffer_merge(vm_buffer* dest, vm_buffer* source) {
  return 0;
}

char are_equal(stack_var* one, stack_var* two) {
  if (one->type != two->type) {
    dbg(DBG_USR1, ("VM: Different types. Not equal.\n"));
    return 0;
  }
  if (one->type == MATE_TYPE_SENSE) {
    return (one->sense.type == two->sense.type &&
	    one->sense.var  == two->sense.var)? 1:0;
  }
  else if (one->type == MATE_TYPE_VALUE) {
    dbg(DBG_USR1, ("VM: Values %i,%i.\n", (int)one->sense.var, (int)two->sense.var));
    return (one->value.var == two->value.var)? 1:0;
  }
  else if (one->type == MATE_TYPE_BUFFER) {
    return (one->buf.var == two->buf.var)? 1:0;
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: Tried testing equality on unrecognized (but matching) types!\n"));
    return 0;
  }
  return 0;
}

void execute_motectl(context_t* context, short which) {
  dbg(DBG_USR1, ("VM: (%i) Executing motectl!\n", (int)context->which));
}

void execute_add(context_t* context, stack_var* arg_one, stack_var* arg_two) {
  char rval;
  if (arg_one->type == MATE_TYPE_VALUE) {
    if (arg_two->type == MATE_TYPE_VALUE) {
      dbg(DBG_USR1, ("VM: (%i) Adding two values: %i + %i = %i\n", (int)context->which, (int)arg_one->value.var, (int)arg_two->value.var, (int)arg_one->value.var + arg_two->value.var));
      push_value_operand(context, (arg_one->value.var + arg_two->value.var));
    }
    else if (arg_two->type == MATE_TYPE_SENSE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Cannot add values to sensor readings!\n", (int)context->which));
    }
    else if (arg_two->type == MATE_TYPE_BUFFER) {
      rval = buffer_append(arg_two->buf.var, arg_one);
      if (rval == 0) {
	push_buffer_operand(context, arg_two->buf.var);
	dbg(DBG_USR1, ("VM: (%i) Appending value to buffer\n", (int)context->which));
      }
      else {
	enter_error_state(context, ERROR_BUFFER_OVERFLOW);
      }
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Unrecognized type of second operand to add instruction!\n", (int)context->which));
    }
  }
  else if (arg_one->type == MATE_TYPE_SENSE) {
    if (arg_two->type == MATE_TYPE_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Add type not implemented yet!\n", (int)context->which));
    }
    else if (arg_two->type == MATE_TYPE_SENSE) {
      if (arg_one->sense.type == arg_two->sense.type) {
	push_sense_operand(context, arg_one->sense.type,
			   arg_one->sense.var + arg_two->sense.var);
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Cannot add different sensor types!\n", (int)context->which));
      }
    }
    else if (arg_two->type == MATE_TYPE_BUFFER) {
      rval = buffer_append(arg_two->buf.var, arg_one);
      if (rval == 0) {
	push_buffer_operand(context, arg_two->buf.var);
	dbg(DBG_USR1, ("VM: (%i) Appending value to buffer\n", (int)context->which));
      }
      else {
	enter_error_state(context, ERROR_BUFFER_OVERFLOW);
      }
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Unrecognized type of second operand to add instruction!\n", (int)context->which));
    }
  }
  else if (arg_one->type == MATE_TYPE_BUFFER) {
    if (arg_two->type == MATE_TYPE_VALUE) {
      rval = buffer_prepend(arg_one->buf.var, arg_two);
      if (rval == 0) {
	push_buffer_operand(context, arg_one->buf.var);
	dbg(DBG_USR1, ("VM: (%i) Prepending value to buffer.\n", (int)context->which));
      }
      else {
	enter_error_state(context, ERROR_BUFFER_OVERFLOW);
      }
    }
    else if (arg_two->type == MATE_TYPE_SENSE) {
      rval = buffer_prepend(arg_one->buf.var, arg_two);
      if (rval == 0) {
	push_buffer_operand(context, arg_one->buf.var);
	dbg(DBG_USR1, ("VM: (%i) Prepending sensor to buffer.\n", (int)context->which));
      }
      else {
	enter_error_state(context, ERROR_BUFFER_OVERFLOW);
      }
    }
    else if (arg_two->type == MATE_TYPE_BUFFER) {
      rval = buffer_merge(arg_two->buf.var, arg_one->buf.var);
      if (rval == 0) {
	push_buffer_operand(context, arg_two->buf.var);
	dbg(DBG_USR1, ("VM: (%i) Merging two buffers.\n", (int)context->which));
      }
      else {
	enter_error_state(context, ERROR_BUFFER_OVERFLOW);
      }
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Unrecognized type of second operand to add instruction!\n", (int)context->which));
    }
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Unrecognized type of first operand to add instruction!\n", (int)context->which));
  }
  
}

void execute_sendr(context_t* context, vm_buffer* buffer) {
  dbg(DBG_USR1, ("VM: (%i) Issuing sendr instruction.\n", (int)context->which));
  if (VAR(sendContextActive)) { // Send context busy -- reissue instruction
    dbg(DBG_USR1, ("VM: (%i) Send context busy -- retry.\n", (int)context->which));
    push_buffer_operand(context, buffer);
    context->pc--;
    return;
  }
  else { // Copy buffer into send's address space
    int i;
    VAR(sendBuffer).size = buffer->size;
    VAR(sendBuffer).type = buffer->type;
    for (i = 0; i < buffer->size; i++) {
      VAR(sendBuffer).entries[i] = buffer->entries[i];
    }
    resetContext(&VAR(sendContext));
    push_buffer_operand(&VAR(sendContext), &VAR(sendBuffer));
    VAR(sendContext).state = STATE_RUN;
    VAR(sendContext).acquireSet = VAR(code)[CAPSULE_SEND].usedVars;
    mqueue_enqueue(context, &VAR(readyQueue), &VAR(sendContext));
    yield(context);
    //resumeContext(context, &VAR(sendContext));
  }
}

void execute_mclass(context_t* context, char instr) {
  stack_var* arg_one;
  char opcode = mop(instr);
  char arg = marg(instr);

  dbg(DBG_USR1, ("VM: (%i) Computing sclass.\n", (int)context->which));
  switch(opcode) {
  case OPsetms: {
    short* header = (short*)context->header;
    arg_one = pop_operand(context);
    if (arg_one->type != MATE_TYPE_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Tried to set message field to non-value!\n", (int)context->which));
      break;
    }
    if (arg >= MATE_HEADERSIZES) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Tried to index short beyond message size!\n", (int)context->which));
      break;
    }
    dbg(DBG_USR1, ("VM: (%i) setms %i to %hi\n", (int)context->which, (int)arg, arg_one->value.var));
    header[(int)arg] = arg_one->value.var;
    break;
  }
    
  case OPsetmb: {
    char* header = (char*)context->header;
    arg_one = pop_operand(context);
    if (arg_one->type != MATE_TYPE_VALUE) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Tried to set message field to non-value!\n", (int)context->which));
      break;
    }
    dbg(DBG_USR1, ("VM: (%i) setmb %i to %hhi\n", (int)context->which, (int)arg, (char)arg_one->value.var));
    header[(int)arg] = (char)(arg_one->value.var);
    break;
  }
  case OPgetms: {
    if (arg >= MATE_HEADERSIZES) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Tried to index short beyond message size!\n", (int)context->which));
      break;
    }
    dbg(DBG_USR1, ("VM: (%i) getms %i: %hi\n", (int)context->which, (int)arg, (context->header[(int)arg])));
    push_value_operand(context, context->header[(int)arg]);
    break;
  }
  case OPgetmb: {
    char* header = (char*)context->header;
    dbg(DBG_USR1, ("VM: (%i) getmb %i: %hhi\n", (int)context->which, (int)arg, (header[(int)arg])));
    push_value_operand(context, (short)(header[(int)arg]));
    break;
  }
  default:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Unrecognized mclass instruction: %i!\n", (int)context->which, (int)instr));
    break;
  }
}

void execute_vclass(context_t* context, char instr) {
  char varg = varg(instr);
  if ((instr & vopmask) == OPgetvar) {
    if (VAR(locks)[(int)varg].holder != context) {
      enter_error_state(context, ERROR_INVALID_ACCESS);
      return;
    }
    push_operand(context, &(VAR(variables)[(int)varg]));
    dbg(DBG_USR1, ("VM: (%i) Getting heap variable %i: %i\n", (int)context->which, (int)varg, VAR(variables)[(int)varg].value.var));
  }
  else if ((instr & vopmask) == OPsetvar) {
    stack_var* arg = pop_operand(context);
    if (check_types(context, arg, VAR_VS)) {
      dbg(DBG_USR1, ("VM: (%i) Setting heap variable %i to %i\n", (int)context->which, (int)varg, (int)arg->value.var));
      VAR(variables)[(int)varg] = *arg;
    }
    else {
      dbg(DBG_USR1|DBG_ERROR, ("VM: Can only store values and sensor readings in heap.\n"));
    }
  }
  else {
    dbg(DBG_ERROR, ("VM: (%i) Tried to execute unknown v-class instruction: 0x%hhx\n", (int)context->which, instr));
  }
}

void execute_xclass(context_t* context, char instr) {
  char arg = xarg(instr);
  if ((instr & xopmask) == OPpushc) {
    dbg(DBG_USR1, ("VM: (%i) Pushing constant: %i\n", (int)context->which, (int)arg));
    push_value_operand(context, arg);
  }
  else {
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Unknown x-class instruction: %i\n", (int)context->which, (int)(instr & xopmask)));
  }
}

void execute_jclass(context_t* context, char instr) {
  char jarg = jarg(instr);
  stack_var* arg; 
  switch (jop(instr)) {
  case OPjumpc:
    if (context->condition > 0) {
      dbg(DBG_USR1, ("VM: (%i) Executing jumpc -- condition is %i, jumping to %i\n", (int)context->which, (int)context->condition, (int)jarg));
      context->condition--;
      context->pc = jarg;
    }
    else {
      dbg(DBG_USR1, ("VM: (%i) Executing jumpc -- condition is <= 0,  not jumping.\n", (int)context->which));
    }
    break;
  case OPjumps:
    arg = pop_operand(context);
    if ((arg->type == MATE_TYPE_VALUE && arg->value.var <= 0) ||
	(arg->type == MATE_TYPE_BUFFER && arg->buf.var->size <= 0)) {
      dbg(DBG_USR1, ("VM: (%i) Value or buffer size <= 0. Do not jump.\n", (int)context->which));
    }
    else if (jarg >=PGMSIZE || jarg < 0) {
      dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Jump address must be >= 0 and < %i.\n", (int)context->which, (int)PGMSIZE));
    }
    else {
      dbg(DBG_USR1, ("VM: (%i) Jumping to address %i.\n", (int)context->which, (int)jarg));
      context->pc = jarg;
    }
    break;
  default:
    dbg(DBG_ERROR, ("VM: (%i) Tried to execute unknown j-class instruction: 0x%hhx\n", (int)context->which, instr));
  }
}

void execute_set_zero_instr(context_t* context, char instr) {
  switch(instr) {
  case OPhalt:
    dbg(DBG_USR1, ("VM: (%i) Halting context %i\n", (int)context->which, context->which));
    haltContext(context);
    context->state = STATE_HALT;
    if (context == VAR(externalContext)) {
      TOS_SIGNAL_EVENT(VM_EXTERNAL_DONE)(1);
      VAR(externalContext) = 0;
    }
    break;
  case OPid:
    dbg(DBG_USR1, ("VM: (%i) Pushing mote ID: %i\n", (int)context->which, (int)TOS_LOCAL_ADDRESS));
    push_value_operand(context, TOS_LOCAL_ADDRESS);
    break;
  case OPrand: {
    short val = TOS_CALL_COMMAND(VM_SUB_RAND)();
    dbg(DBG_USR1, ("VM: (%i) Pushing random number: %i\n", (int)context->which, (int)val));
    push_value_operand(context, val);
    break;
  }
  case OPctrue:
    dbg(DBG_USR1, ("VM: (%i) Setting branch condition to be true.\n", (int)context->which));
    context->condition = 1;
    break;
  case OPcfalse:
    dbg(DBG_USR1, ("VM: (%i) Setting branch condition to be false.\n", (int)context->which));
    context->condition = 0;
    break;
  case OPcpush:
    dbg(DBG_USR1, ("VM: (%i) Pushing branch condition onto operand stack: %i\n", (int)context->which, (int)context->condition));
    push_value_operand(context, context->condition);
    break;
  case OPlogp:
    dbg(DBG_USR1, ("VM: (%i) Pushing last used log line onto operand stack: %i\n", (int)context->which, (int)VAR(loggerIndex)));
    push_value_operand(context, VAR(loggerIndex));
    break;
  case OPbpush0:
    dbg(DBG_USR1, ("VM: (%i) Pushing buffer 0 onto operand stack.\n", (int)context->which));
    push_buffer_operand(context, &VAR(buffers)[0]);
    break;
  case OPbpush1:
    dbg(DBG_USR1, ("VM: (%i) Pushing buffer 1 onto operand stack.\n", (int)context->which));
    push_buffer_operand(context, &VAR(buffers)[1]);
    break;
  case OPdepth:
    dbg(DBG_USR1, ("VM: (%i) Pushing opstack depth onto operand stack: %i.\n", (int)context->which, (int)context->stack.sp));
    push_value_operand(context, context->stack.sp);
    break;
  case OPerr:
    dbg(DBG_USR1, ("VM: (%i) OPerr executed: entering error state.\n", (int)context->which));
    enter_error_state(context, ERROR_TRIGGERED);
    break;
  case OPret: 
    pop_return_addr(context);
    dbg(DBG_USR1, ("VM: (%i) Returning to capsule %i instruction %i\n", (int)context->which, (int)context->code->capsule.type, (int)context->pc));
    break;
  case OPcall0:
  case OPcall1:
  case OPcall2:
  case OPcall3:
    dbg(DBG_USR1, ("VM (%i) Calling subroutine %hhi\n", (int)context->which, (char)(instr & 0x3))); 
    push_return_addr(context);
    context->code = &VAR(code)[(instr & 0x3)];
    context->pc   = 0;
    break;
   
  default:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set zero instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
  }
}

void execute_set_one_instr(context_t* context, char instr) {
  stack_var* arg = pop_operand(context);
  switch(instr) {
  case OPinv: {
    if (check_types(context, arg, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) Inverting top of stack (-$0): %i\n", (int)context->which, (int)-arg->value.var));
      push_value_operand(context, -arg->value.var);
    }
  }
  case OPsense:
    if (check_types(context, arg, VAR_V)) {
      if (arg->value.var == MATE_DATA_PHOTO) {
	if (!TOS_CALL_COMMAND(VM_SUB_GET_PHOTO)()) {
	  context->pc--;
	  dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Could not get photo data... retrying!\n", (int)context->which));
	  break;
	}
	VAR(adcWaitingContext) = context;
	context->state = STATE_DATA_WAIT;
	yield(context);
	VAR(sense_type) = MATE_DATA_PHOTO;
      }
      else if (arg->value.var == MATE_DATA_TEMP) {
	if (!TOS_CALL_COMMAND(VM_SUB_GET_TEMP)()) {
	  context->pc--;
	  dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Could not get temp data... retrying!\n", (int)context->which));
	  break;
	}
	VAR(adcWaitingContext) = context;
	context->state = STATE_DATA_WAIT;
	yield(context);
	VAR(sense_type) = MATE_DATA_TEMP;
      }
    }
    break;
    
  case OPcopy: {
    stack_var buf;
    buf = *arg;
    dbg(DBG_USR1, ("VM: (%i) Copying top of stack: 0x%x.\n", (int)context->which, (int)buf.value.var));
    push_operand(context, &buf);
    push_operand(context, &buf);
    break;
  }

  case OPnot:
    if (check_types(context, arg, VAR_V)) {
      push_value_operand(context, (arg->value.var)? 0:1);
    }
    break;

  case OPpop: {
    dbg(DBG_USR1, ("VM: (%i) OPpop: Popped top of stack.\n", (int)context->which));
    // Don't have to do anything ....
    break;
  }
    
  case OPsend:
    dbg(DBG_USR1, ("VM: (%i) Context %i trying to send built-in packet.\n", (int)context->which, (int)context->which));
    if (check_types(context, arg, VAR_B)) {
      if (VAR(sendWaitingContext) != 0) {
	// Someone already sending, spin on instruction
	push_operand(context, arg);
	context->pc--;
	dbg(DBG_USR1, ("VM: (%i) Send context waiting. Retry.\n", (int)context->which));
      }
      else {
	VAR(sendWaitingContext) = context;
	// Buffer length is 2 bytes header + 2 bytes/entry
	if (TOS_CALL_COMMAND(VM_SUB_SEND_PACKET)((char*)arg->buf.var, (arg->buf.var->size * 2) + 2)) {
	  context->state = STATE_PACKET_SEND;
	  //yield(context);
	}
	else { // Send failed, relinquish and spin on instruction
	  push_operand(context, arg);
	  VAR(sendWaitingContext) = 0;
	  context->pc--;
	  dbg(DBG_USR1, ("VM: (%i) Send busy. Retry.\n", (int)context->which));
	}
      }
    }
    break;
    
  case OPsendr:
    if (check_types(context, arg, VAR_B)) {
      if (context == &VAR(sendContext)) {
	send_raw_packet(context, arg->buf.var);
      }
      else {
	execute_sendr(context, arg->buf.var);
      }
    }
    break;
    
  case OPuart:
    if (check_types(context, arg, VAR_B)) {
      send_to_uart(context, arg->buf.var);
    }
    break;

  case OPcpull: {
    if (check_types(context, arg, VAR_V)) {
      context->condition = arg->value.var;
    }
    break;
  }
    
  case OPlogw:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set one instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
    break;
    
  case OPbpush:
    if (check_types(context, arg, VAR_V)) {
      if (arg->value.var == 0) {
	push_buffer_operand(context, &VAR(buffers)[0]);
      }
      else if (arg->value.var == 1) {
	push_buffer_operand(context, &VAR(buffers)[1]);
      }
      else {
	dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) mate_db only has two buffers currently: can't push buffer %i\n", (int)context->which, (int)arg->value.var));
      }
    }
    break;
    
  case OPbhead:
    if (check_types(context, arg, VAR_B)) {
      stack_var* var;
      dbg(DBG_USR1, ("VM: (%i) Yanking head of buffer of size %i.\n", (int)context->which, (int)arg->buf.var->size));
      
      var =  buffer_yank(arg->buf.var, 0);
      push_buffer_operand(context, arg->buf.var);
      push_operand(context, var);
    }
    break;

  case OPbtail:
    if (check_types(context, arg, VAR_B)) {
      stack_var* var =  buffer_yank(arg->buf.var, arg->buf.var->size - 1);
      dbg(DBG_USR1, ("VM: (%i) Yanking tail of buffer.\n", (int)context->which));
      push_buffer_operand(context, arg->buf.var);
      push_operand(context, var);
    }
    break;

  case OPbwhich:
    if (check_types(context, arg, VAR_B)) {
      vm_buffer* buf =  arg->buf.var;
      push_buffer_operand(context, buf);
      if (buf == &VAR(buffers)[0]) {
	push_value_operand(context, 0);
      }
      else if (buf == &VAR(buffers)[1]) {
	push_value_operand(context, 1);
      }
      else {
	push_value_operand(context, 2);
      }
    }
    break;
    
  case OPbclear:
    if (check_types(context, arg, VAR_B)) {
      dbg(DBG_USR1, ("VM: (%i) Clearing buffer.\n", (int)context->which));
      buffer_clear(arg->buf.var);
      push_buffer_operand(context, arg->buf.var);
    }
    break;

  case OPbsize:
    if (check_types(context, arg, VAR_B)) {
      dbg(DBG_USR1, ("VM: (%i) Pushing buffer size onto stack: %i\n", (int)context->which, arg->buf.var->size));
      push_buffer_operand(context, arg->buf.var);
      push_value_operand(context, arg->buf.var->size);
    }
    break;

  default:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set one instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
  }
}
void execute_set_two_instr(context_t* context, char instr) {
  stack_var* arg = pop_operand(context);
  switch(instr) {
    // One operand instructions
  case OPbsorta:
    if (check_types(context, arg, VAR_B)) {
      dbg(DBG_USR1, ("VM: (%i) Sorting buffer in ascending order.\n", (int)context->which));
      buffer_sorta(arg->buf.var);
      push_buffer_operand(context, arg->buf.var);
    }
    break;

  case OPbsortd:
    if (check_types(context, arg, VAR_B)) {
      dbg(DBG_USR1, ("VM: (%i) Sorting buffer in descending order.\n", (int)context->which));
      buffer_sortd(arg->buf.var);
      push_buffer_operand(context, arg->buf.var);
    }
    break;
    
  case OPbfull: 
    if (check_types(context, arg, VAR_B)) {
      char rval = (arg->buf.var->size == MATE_BUF_MAX)? 1:0;
      dbg(DBG_USR1, ("VM: (%i) bfull: %hhi\n", (int)context->which, rval));
      push_buffer_operand(context, arg->buf.var);
      push_value_operand(context, rval);
      context->condition = rval;
    }
    break;
    
  case OPcall:
    if (check_types(context, arg, VAR_V)) {
      push_return_addr(context);
      context->code = &VAR(code)[arg->value.var];
      context->pc   = 0;
    }
    break;
  
  case OPputled:
    if (check_types(context, arg, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) putled with %i\n", (int)context->which, arg->value.var));
      LEDop(arg->value.var);
    }
    break;
  
  case OPcast:
    if (check_types(context, arg, VAR_S)) {
      dbg(DBG_USR1, ("VM: (%i) Casting sensor reading to value\n", (int)context->which));
      push_value_operand(context, arg->sense.var);
    }
    break;

  case OPlnot:
    if (check_types(context, arg, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) executing lnot\n", (int)context->which));
      push_value_operand(context, (short)~(arg->value.var));
    }
    break;

  case OPunlock:
    if (check_types(context, arg, VAR_V)) {
      if (arg->value.var < 0 || arg->value.var >= MATE_HEAPSIZE) {
	enter_error_state(context, ERROR_INVALID_RUNNABLE);
      }
      dbg(DBG_USR1|DBG_USR2, ("VM: (%i) Context %i unlocking lock %i\n", (int)context->which, (int)context->which, (int)arg->value.var));
      context->relinquishSet |= (1 << arg->value.var);
      context->acquireSet |= (1 << arg->value.var);
    }
    break;
    
  case OPunlockb:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set two instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
    break;
  case OPpunlock:
    if (check_types(context, arg, VAR_V)) {
      if (arg->value.var < 0 || arg->value.var >= MATE_HEAPSIZE) {
	enter_error_state(context, ERROR_INVALID_RUNNABLE);
      }
      dbg(DBG_USR1|DBG_USR2, ("VM: (%i) Context %i unlocking lock %i\n", (int)context->which, (int)context->which, (int)arg->value.var));
      context->relinquishSet |= (1 << arg->value.var);
    }
    break;
    
  case OPpunlockb:    
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set two instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
// Two operand instructions 
  case OPlogwl:
  case OPlogr:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set two instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
    break;

  case OPbnth: {
    stack_var* arg_two = pop_operand(context);
    if (check_types(context, arg, VAR_V) &&
	check_types(context, arg_two, VAR_B)) {
      stack_var* val = buffer_get(arg_two->buf.var, arg->value.var);
      dbg(DBG_USR1, ("VM: (%i) Getting element #%i from buffer\n", (int)context->which, arg->value.var));
      push_buffer_operand(context, arg_two->buf.var);
      push_operand(context, val);
    }
    break;
  }
    
  case OPbyank: {
    stack_var* arg_two = pop_operand(context);
    if (check_types(context, arg, VAR_V) &&
	check_types(context, arg_two, VAR_B)) {
      stack_var* val = buffer_yank(arg_two->buf.var, arg->value.var);
      dbg(DBG_USR1, ("VM: (%i) Getting element #%i from buffer\n", (int)context->which, arg->value.var));
      push_buffer_operand(context, arg_two->buf.var);
      push_operand(context, val);
    }
    break;
  }

// 1+ operand instruction 
  case OPmotectl:
    if (check_types(context, arg, VAR_V)) {
      execute_motectl(context, arg->value.var);
    }
    break;
   
  default:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set two instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
  }
}
void execute_set_three_instr(context_t* context, char instr) {
  stack_var* arg_one = pop_operand(context);
  stack_var* arg_two = pop_operand(context);

  switch(instr) {
  case OPswap: {
    stack_var temp;
    temp = *arg_two;
    dbg(DBG_USR1, ("VM: (%i) Swapping top of stack...\n", (int)context->which));
    push_operand(context, arg_one);
    push_operand(context, &temp);
    break;
  }
  case OPland:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) push(0x%hx & 0x%hx) = (%i)\n", (int)context->which, arg_one->value.var, arg_two->value.var, (int)(arg_one->value.var & arg_two->value.var)));
      push_value_operand(context, (arg_one->value.var & arg_two->value.var));
    }
    break;

  case OPlor:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) push($0 | $1)\n", (int)context->which));
      push_value_operand(context, (arg_one->value.var | arg_two->value.var));
    }
    break;

  case OPand:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      short rval = (arg_one->value.var && arg_two->value.var)? 1:0;
      dbg(DBG_USR1, ("VM: (%i) push($0 && $1)\n", (int)context->which));
      push_value_operand(context, rval);
      context->condition = rval;
    }
    break;

  case OPor:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      short rval = (arg_one->value.var || arg_two->value.var)? 1:0;
      dbg(DBG_USR1, ("VM: (%i) push($0 || $1)\n", (int)context->which));
      push_value_operand(context, rval);
      context->condition = rval;
    }
    break;
    
  case OPshiftr:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) push($1 << $0)\n", (int)context->which));
      push_value_operand(context, (arg_two->value.var >> arg_one->value.var)); 
    }
    break;
  case OPshiftl:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) push($1 << $0)\n", (int)context->which));
      push_value_operand(context, (arg_two->value.var << arg_one->value.var)); 
    }
    break;
  case OPadd:
    dbg(DBG_USR1, ("VM: (%i) Executing add instruction.\n", (int)context->which));
    execute_add(context, arg_one, arg_two);
    break;
  case OPmod:
    if (check_types(context, arg_one, VAR_V) && 
	check_types(context, arg_two, VAR_V)) {
      dbg(DBG_USR1, ("VM: (%i) push($1 %% $0)\n", (int)context->which));
      push_value_operand(context, (arg_two->value.var % arg_one->value.var)); 
    }
    break;
  case OPeq: {
    char eq = are_equal(arg_one, arg_two);
    if (eq) {
      dbg(DBG_USR1, ("VM: eq: $0 == $1: push 1\n"));
    }
    else {
      dbg(DBG_USR1, ("VM: eq: $0 != $1: push 0\n"));
    }
    push_value_operand(context, eq);
    context->condition = (short)eq;
    break;
  }
  case OPneq: {
    char eq = (are_equal(arg_one, arg_two))? 0:1;
    if (eq) {
      dbg(DBG_USR1, ("VM: neq: $0 != $1: push 1\n"));
    }
    else {
      dbg(DBG_USR1, ("VM: neq: $0 == $1: push 0\n"));
    }
    push_value_operand(context, eq);
    context->condition = (short)eq;
    break;
  }
  case OPlt:
    if (check_types(context, arg_one, arg_two->type)) {
      char eq;
      if (arg_one->type == MATE_TYPE_VALUE) {
	eq = (arg_one->value.var < arg_two->value.var)? 1:0;
      }
      else if (arg_one->type == MATE_TYPE_SENSE) {
	if (arg_one->sense.type == arg_two->sense.type) {
	  eq = (arg_one->sense.var < arg_two->sense.var)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else if (arg_one->type == MATE_TYPE_BUFFER) {
	if (arg_one->buf.var->type == arg_two->buf.var->type) {
	  eq = (arg_one->buf.var->size < arg_two->buf.var->size)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else {
	eq = 0;
      }
      context->condition = (short)eq;
      push_value_operand(context, eq);
      if (eq) {
	dbg(DBG_USR1, ("VM: neq: $0 < $1: push 1\n"));
      }
      else {
	dbg(DBG_USR1, ("VM: neq: $0 < $1: push 0\n"));
      }
    }
    else {
      push_value_operand(context, 0);
      context->condition = (short)0;
    }
    break;
    
  case OPgt:
    if (check_types(context, arg_one, arg_two->type)) {
      char eq;
      if (arg_one->type == MATE_TYPE_VALUE) {
	eq = (arg_one->value.var > arg_two->value.var)? 1:0;
      }
      else if (arg_one->type == MATE_TYPE_SENSE) {
	if (arg_one->sense.type == arg_two->sense.type) {
	  eq = (arg_one->sense.var > arg_two->sense.var)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else if (arg_one->type == MATE_TYPE_BUFFER) {
	if (arg_one->buf.var->type == arg_two->buf.var->type) {
	  eq = (arg_one->buf.var->size > arg_two->buf.var->size)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else {
	eq = 0;
      }
      push_value_operand(context, eq);
      context->condition = (short)eq;
      if (eq) {
	dbg(DBG_USR1, ("VM: neq: $0 > $1: push 1\n"));
      }
      else {
	dbg(DBG_USR1, ("VM: neq: $0 > $1: push 0\n"));
      }
    }
    else {
      push_value_operand(context, 0);
      context->condition = (short)0;
    }
    break;
    
  case OPlte:
    if (check_types(context, arg_one, arg_two->type)) {
      char eq;
      if (arg_one->type == MATE_TYPE_VALUE) {
	eq = (arg_one->value.var <= arg_two->value.var)? 1:0;
      }
      else if (arg_one->type == MATE_TYPE_SENSE) {
	if (arg_one->sense.type == arg_two->sense.type) {
	  eq = (arg_one->sense.var <= arg_two->sense.var)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else if (arg_one->type == MATE_TYPE_BUFFER) {
	if (arg_one->buf.var->type == arg_two->buf.var->type) {
	  eq = (arg_one->buf.var->size <= arg_two->buf.var->size)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else {
	eq = 0;
      }
      push_value_operand(context, eq);
      context->condition = (short)eq;
      if (eq) {
	dbg(DBG_USR1, ("VM: neq: $0 <= $1: push 1\n"));
      }
      else {
	dbg(DBG_USR1, ("VM: neq: $0 <= $1: push 0\n"));
      }
    }
    else {
      push_value_operand(context, 0);
      context->condition = (short)0;
    }
    break;
    
  case OPgte:
    if (check_types(context, arg_one, arg_two->type)) {
      char eq;
      if (arg_one->type == MATE_TYPE_VALUE) {
	eq = (arg_one->value.var >= arg_two->value.var)? 1:0;
      }
      else if (arg_one->type == MATE_TYPE_SENSE) {
	if (arg_one->sense.type == arg_two->sense.type) {
	  eq = (arg_one->sense.var >= arg_two->sense.var)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else if (arg_one->type == MATE_TYPE_BUFFER) {
	if (arg_one->buf.var->type == arg_two->buf.var->type) {
	  eq = (arg_one->buf.var->size >= arg_two->buf.var->size)? 1:0;
	}
	else {
	  eq = 0;
	}
      }
      else {
	eq = 0;
      }
      push_value_operand(context, eq);
      context->condition = (short)eq;
      if (eq) {
	dbg(DBG_USR1, ("VM: neq: $0 >= $1: push 1\n"));
      }
      else {
	dbg(DBG_USR1, ("VM: neq: $0 >= $1: push 0\n"));
      }
    }
    else {
      push_value_operand(context, 0);
      context->condition = (short)0;
    }
    break;

  case OPeqtype: {
    char eq = check_types(context, arg_one, arg_two->type)? 1:0;
    push_value_operand(context, eq);
    context->condition = (short)eq;
    break;
  }
  default:
    dbg(DBG_USR1|DBG_ERROR, ("VM: (%i) Not all set three instructions implemented yet! Instruction: 0x%hhx\n", (int)context->which, (int)instr));
  }
}

void compute_instruction(context_t* context) {
  char instr = context->code->capsule.code[(int)context->pc];
  //dbg(DBG_USR1, ("VM: Fetching instruction %hhx from capsule %hhx: 0x%hhx\n", (int)context->which, stack->pc, stack->code, instr));
  
  if (context->state != STATE_RUN) {
    dbg(DBG_ERROR, ("VM: (%i) Tried to execute instruction in non-run state: %i\n", (int)context->which, context->state));
    return;
  }
  else {
    //dbg(DBG_USR3, ("VM: (%i) Executing instruction %hhi of capsule %hhi\n", (int)context->which, context->pc, context->code->capsule.type));
  }
  context->pc++;

  if (is_mclass(instr)) {
    execute_mclass(context, instr);
  }
  else if (is_vclass(instr)) {
    execute_vclass(context, instr);
  }
  else if (is_jclass(instr)) {
    execute_jclass(context, instr);
  }
  else if (is_xclass(instr)) {
    execute_xclass(context, instr);
  }
  else {
    char instr_set = (instr >> 4);
    switch (instr_set) {
    case 0:
      execute_set_zero_instr(context, instr);
      break;
    case 1:
      execute_set_one_instr(context, instr);
      break;
    case 2:
      execute_set_two_instr(context, instr);
      break;
    case 3:
      execute_set_three_instr(context, instr);
      break;
    default:
      dbg(DBG_ERROR, ("VM: (%i) Unrecognized instruction: 0x%hhx!\n", (int)context->which, instr));
    }
  }
  if (context->pc >= context->code->capsule.length &&
      context->state == STATE_RUN) {
    enter_error_state(context, ERROR_INSTRUCTION_RUNOFF);
  }
}

