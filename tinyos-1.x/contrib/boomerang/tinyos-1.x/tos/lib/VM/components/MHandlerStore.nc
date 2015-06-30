/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2004 Intel Corporation 
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
 * Authors:   Philip Levis
 * History:   March 10, 2004   Creation
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MHandlerStore {
  provides {
    interface StdControl;
    interface MateHandlerStore as HandlerStore[uint8_t id];
    interface MateEngineControl as EngineControl;
  }
  uses {
    interface StdControl as SubControl;
    interface MateVirus as Virus;
    interface MateAnalysis as Analysis;
  }
  
}

implementation {


  // This structure has been designed to be the same
  // as the end of a capsule, sop 
  typedef struct {
    MateHandlerLength codeLength;
    MateOpcode code[MATE_HANDLER_SIZE];
  } MateHandler;
  
  MateHandler* handlers[MATE_HANDLER_NUM];
  MateCapsule capsules[MATE_HANDLER_NUM];
  
  command result_t StdControl.init() {
    int i;
    for (i = 0; i < MATE_HANDLER_NUM; i++) {
      handlers[i] = (MateHandler*)&(capsules[i].dataSize);
    }
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  command result_t HandlerStore.initializeHandler[uint8_t id]() {
    if (id >= MATE_HANDLER_NUM) {return FAIL;}
    handlers[id] = (MateHandler*)&(capsules[id].dataSize);
    memset(&capsules[id], sizeof(MateCapsule), 0);
    handlers[id]->code[0] = OP_HALT;
    handlers[id]->codeLength = 1;
    call Virus.registerCapsule(id, &capsules[id]);
    call Analysis.analyzeVars((MateHandlerID)id);
    return SUCCESS;
  }

    command MateHandlerOptions HandlerStore.getOptions[uint8_t id]() {
    return 0;
  }
  
  command MateHandlerLength HandlerStore.getCodeLength[uint8_t id]() {
    return handlers[id]->codeLength;
  }

  command MateOpcode  HandlerStore.getOpcode[uint8_t id](uint16_t which) {
    return handlers[id]->code[which];
  }
  
  event result_t Virus.capsuleInstalled(MateCapsuleID id, MateCapsule* capsule) {
    if (id < 0 || id > MATE_CAPSULE_NUM) {
      dbg(DBG_ERROR, "MHandlerStore: ERROR: Invalid capsule (%i) installed, do nothing.\n", (int)id);
      return FAIL;
    }
    call Analysis.analyzeVars((MateHandlerID)id);
    {
#ifdef PLATFORM_PC
      int i;
      dbg(DBG_USR3|DBG_TEMP, "HandlerStore: Installing capsule %i:\n\t", (int)id);
      for (i = 0; i < handlers[id]->codeLength; i++) {
	dbg_clear(DBG_USR3|DBG_TEMP, "[%hhx]", call HandlerStore.getOpcode[(int)id](i));
      }
      dbg_clear(DBG_USR3|DBG_TEMP, "\n");
#endif
    }
    signal HandlerStore.handlerChanged[id]();
    signal EngineControl.reboot();
    return SUCCESS;
  }
  
 default event void HandlerStore.handlerChanged[uint8_t which]() {
   dbg(DBG_USR1|DBG_ERROR, "HandlerStore: Default capsule changed called for id %hhx: invalid capsule ID (no mask?)...\n", which);
 }
 
  event result_t Virus.capsuleHeard(uint8_t type) {
   return SUCCESS;
  }
  
  event result_t Virus.disableExecution() {
    return SUCCESS;
  }

  event result_t Virus.enableExecution() {
    return SUCCESS;
  }

  event void Virus.capsuleForce(uint8_t type) {}

  
}
