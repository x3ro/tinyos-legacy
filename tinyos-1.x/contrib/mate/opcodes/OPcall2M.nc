/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
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
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * History:   Apr 14, 2003         Inception.
 *
 */

includes Bombilla;
includes BombillaMsgs;

module OPcall2M {
  provides {
    interface BombillaBytecode;
  }
  uses {
    interface BombillaStacks as Stacks;
    interface BombillaContextComm as Comm;
    interface BombillaVirus as Virus;
    interface BombillaAnalysis as Analysis;
  }
}

implementation {
  BombillaState* st;

  event result_t Comm.registerCapsule(BombillaState* state) {
    int i;
    //int pc=0;

    st = state;
    state->capsules[BOMB_CAPSULE_SUB0].capsule.type = BOMB_CAPSULE_SUB0;
    state->capsules[BOMB_CAPSULE_SUB1].capsule.type = BOMB_CAPSULE_SUB1;
    state->capsules[BOMB_CAPSULE_SUB2].capsule.type = BOMB_CAPSULE_SUB2;
    state->capsules[BOMB_CAPSULE_SUB3].capsule.type = BOMB_CAPSULE_SUB3;
    /*
    state->capsules[BOMB_CAPSULE_SUB0].capsule.code[pc++] = OPgetvar | 2;
    state->capsules[BOMB_CAPSULE_SUB0].capsule.code[pc++] = OPcall1;
    state->capsules[BOMB_CAPSULE_SUB0].capsule.code[pc++] = OPret;

    pc = 0;
    state->capsules[BOMB_CAPSULE_SUB1].capsule.code[pc++] = OPgetvar | 12;
    state->capsules[BOMB_CAPSULE_SUB1].capsule.code[pc++] = OPcall2;
    state->capsules[BOMB_CAPSULE_SUB1].capsule.code[pc++] = OPcall3;
    state->capsules[BOMB_CAPSULE_SUB1].capsule.code[pc++] = OPret;

    pc = 0;
    state->capsules[BOMB_CAPSULE_SUB2].capsule.code[pc++] = OPgetvar | 10;
    state->capsules[BOMB_CAPSULE_SUB2].capsule.code[pc++] = OPcall0;
    state->capsules[BOMB_CAPSULE_SUB2].capsule.code[pc++] = OPret;

    pc = 0;
    state->capsules[BOMB_CAPSULE_SUB3].capsule.code[pc++] = OPgetvar | 2;
    state->capsules[BOMB_CAPSULE_SUB3].capsule.code[pc++] = OPret;
    */

    for (i = 0; i <= BOMB_CAPSULE_SUB3; i++) {
      state->capsules[i].capsule.type |= BOMB_OPTION_FORWARD;
      state->capsules[i].capsule.version = 0;
      call Virus.registerCapsule(state->capsules[i].capsule.type,
                                 &(state->capsules[i].capsule));
      call Analysis.analyzeCapsuleVars(state, i);
    }

    return SUCCESS;
  }

  event result_t Comm.analyzeLockSets(BombillaState* state) {
    int i;
    for (i = 0; i < BOMB_CAPSULE_NUM; i++) {
      call Analysis.analyzeCapsuleCallsDeep(state, i);
    }
    return SUCCESS;
  }

  command result_t BombillaBytecode.execute(uint8_t instr,
					    BombillaContext* context,
					    BombillaState* state) {
    dbg(DBG_USR1, "VM (%i): Calling subroutine %hhu\n", (int)context->which, (uint8_t)(instr & 0x3));
    call Stacks.pushReturnAddr(context);
    context->capsule = &(state->capsules[instr & 0x3]);
    context->pc = 0;
    return SUCCESS;
  }

  event result_t Virus.capsuleInstalled(BombillaCapsule* capsule) {
    uint8_t id = capsule->type;
    if (id <= (BOMB_CAPSULE_SUB3 | BOMB_OPTION_FORWARD)) {
      dbg(DBG_USR1, "VM: Installing subroutine capsule %i\n", id);
      st->capsules[id & 0x3].capsule = *capsule;
      call Comm.reboot();
    }
    return SUCCESS;
  }

  event result_t Virus.enableExecution() {
    return SUCCESS;
  }

  event result_t Virus.disableExecution() {
    return SUCCESS;
  }

  event result_t Virus.capsuleHeard(uint8_t type) {
    return SUCCESS;
  }

  event void Virus.capsuleForce(uint8_t type) {
    return;
  }
}
