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
 * Authors:   Neil Patel
 * History:   Apr 11, 2003         Inception.
 *
 */

includes AM;
includes Bombilla;
includes BombillaMsgs;

module RecvContextM {
  uses {
    interface ReceiveMsg as ReceivePacket;
    interface BombillaStacks as Stacks;
    interface BombillaContextSynch as Synch;
    interface BombillaContextComm as Comm;
    interface BombillaVirus as Virus;
    interface BombillaAnalysis as Analysis;
  }
}

implementation {
  BombillaContext recvContext;

  event result_t Comm.registerCapsule(BombillaState* state) {
    int pc = 0;

    recvContext.which = BOMB_CAPSULE_RECV;
    recvContext.vmData = state;

    recvContext.rootCapsule = &(state->capsules[BOMB_CAPSULE_RECV_INDEX]);
    recvContext.state = BOMB_STATE_HALT;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.type = recvContext.which;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.type |= BOMB_OPTION_FORWARD;
        
    call Virus.registerCapsule(state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.type,
                               &(state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule));

    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.code[pc++] = OPbhead;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.code[pc++] = OPpushc | 7;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.code[pc++] = OPland;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.code[pc++] = OPputled;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.code[pc++] = OPhalt;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.options = 0;
    state->capsules[BOMB_CAPSULE_RECV_INDEX].capsule.version = 0;
    
    call Analysis.analyzeCapsuleVars(state, BOMB_CAPSULE_RECV_INDEX);
    
    return SUCCESS;
  }

  event result_t Comm.analyzeLockSets(BombillaState* state) {
    return SUCCESS;
  }
  
  void alertReceiveContext(TOS_MsgPtr msg) {
    if (!msg->crc) {return;}
    if (recvContext.state != BOMB_STATE_HALT) {
      dbg(DBG_USR1, "VM (%i): Received packet, receive context busy, drop.\n", recvContext.which);
    }
    else {
      int i;
      BombillaPacket* packet = (BombillaPacket*)(msg->data);
      BombillaDataBuffer* buffer = (BombillaDataBuffer*)&(packet->payload);
      BombillaState* state = recvContext.vmData;
      dbg(DBG_USR1, "VM (%i): Received packet, enqueuing receive context to run.\n", recvContext.which);
      dbg(DBG_USR1, "VM (%i): Copying %i bytes of header over:\n  ", recvContext.which, sizeof(recvContext.header));
      for (i = 0; i < sizeof(recvContext.header); i++) {
        dbg_clear(DBG_USR1, "%02hhx", packet->header[i]);
      }
      dbg_clear(DBG_USR1, "\n->");
      nmemcpy(&(recvContext.header), packet->header, sizeof(recvContext.header));
      for (i = 0; i < sizeof(recvContext.header); i++) {
        dbg_clear(DBG_USR1, "%02hhx", ((uint8_t*)recvContext.header)[i]);
      }
      dbg_clear(DBG_USR1, "\n");
      nmemcpy(&(state->recvBuffer), buffer, sizeof(BombillaDataBuffer));
      call Synch.initializeContext(&recvContext, state);
      call Stacks.pushBuffer(&recvContext, &state->recvBuffer);
      call Synch.resumeContext(&recvContext, &recvContext, &(state->readyQueue), state->locks);
    }
    return; 
  }

  event TOS_MsgPtr ReceivePacket.receive(TOS_MsgPtr msg) {
    alertReceiveContext(msg);
    return msg;
  }

  event result_t Synch.makeRunnable(BombillaContext* context) {
    return SUCCESS;
  }

  event result_t Virus.capsuleInstalled(BombillaCapsule* capsule) {
    //capsuleAnalysis(capsule->type & BOMB_OPTION_MASK);
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
