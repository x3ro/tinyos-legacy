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

/**
 * @author Neil Patel
 */


includes AM;
includes Bombilla;

module OnceContextM {
  provides interface StdControl;
  uses {
    interface BombillaContextSynch as Synch;
    interface BombillaContextComm as Comm;
    interface BombillaVirus as Virus;
    interface BombillaAnalysis as Analysis;
    interface Timer;
  }
}

implementation {
  BombillaContext onceContext;

  command result_t StdControl.init() {
    onceContext.which = BOMB_CAPSULE_ONCE;
    onceContext.currentCapsule = &onceContext.rootCapsule;
    onceContext.state = BOMB_STATE_HALT;
    onceContext.rootCapsule.capsule.type = onceContext.which;
    onceContext.rootCapsule.capsule.type |= BOMB_OPTION_FORWARD;
        
    call Virus.registerCapsule(onceContext.rootCapsule.capsule.type,
                               &onceContext.rootCapsule.capsule);

    onceContext.rootCapsule.capsule.options = 0;
    onceContext.rootCapsule.capsule.version = 0;
    if (TOS_LOCAL_ADDRESS == 210) {
      int pc = 0;
      struct timeval tv;
      gettimeofday(&tv, NULL);
      onceContext.rootCapsule.capsule.version = 1;
      onceContext.rootCapsule.capsule.code[pc++] = OPid;
      onceContext.rootCapsule.capsule.code[pc++] = OP2pushc10;
      onceContext.rootCapsule.capsule.code[pc++] = 210;
      onceContext.rootCapsule.capsule.code[pc++] = OPeq;
      onceContext.rootCapsule.capsule.code[pc++] = OPnot;
      onceContext.rootCapsule.capsule.code[pc++] = OP2jumps10;
      onceContext.rootCapsule.capsule.code[pc++] = 16;
      onceContext.rootCapsule.capsule.code[pc++] = OP2pushc10;
      onceContext.rootCapsule.capsule.code[pc++] = ((tv.tv_usec * 5187) % 399) + 1;
      sleep(1);
      onceContext.rootCapsule.capsule.code[pc++] = OProute;
      gettimeofday(&tv, NULL);
      onceContext.rootCapsule.capsule.code[pc++] = OP2pushc10;
      onceContext.rootCapsule.capsule.code[pc++] = ((tv.tv_usec * 3419) % 399) + 1;
      sleep(1);
      onceContext.rootCapsule.capsule.code[pc++] = OProute;
      gettimeofday(&tv, NULL);
      onceContext.rootCapsule.capsule.code[pc++] = OP2pushc10;
      onceContext.rootCapsule.capsule.code[pc++] = ((tv.tv_usec * 6531) % 399) + 1;
      onceContext.rootCapsule.capsule.code[pc++] = OProute;
      onceContext.rootCapsule.capsule.code[pc++] = OPhalt;
    }
    
    call Analysis.analyzeCapsuleVars(&onceContext.rootCapsule);
    call Comm.registerCapsule(&onceContext.rootCapsule);
    return SUCCESS;
  }

  event result_t Timer.fired() {
    return signal Virus.capsuleInstalled(&onceContext.rootCapsule.capsule);
  }
  
  command result_t StdControl.start() {
    if (TOS_LOCAL_ADDRESS == 210) {
      call Timer.start(TIMER_ONE_SHOT, 20000);
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t Comm.analyzeLockSets(BombillaCapsuleBuffer* capsules[]) {
    return SUCCESS;
  }

  event result_t Synch.makeRunnable(BombillaContext* context) {
    return SUCCESS;
  }
  
  event result_t Virus.capsuleInstalled(BombillaCapsule* capsule) {
    call Synch.initializeContext(&onceContext);
    if ((capsule->type & BOMB_OPTION_MASK) == BOMB_CAPSULE_ONCE) {
      dbg(DBG_USR1, "VM: Installing onceContext Capsule. \n");
      onceContext.rootCapsule.capsule = *capsule;
      call Analysis.analyzeCapsuleVars(&onceContext.rootCapsule);
      call Comm.reboot();

      call Synch.initializeContext(&onceContext);
      call Synch.resumeContext(&onceContext, &onceContext);
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
