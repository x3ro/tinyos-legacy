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
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
 * History:   July 21, 2002
 *	     
 *
 */

/**
 * @author Philip Levis
 */


includes Mate;

module MVirus {
  provides {
    interface StdControl;
    interface MateVirus as Virus;
    interface MateEngineControl as EngineControl;
  }
  uses {
    interface MateError;

    interface Timer as VersionTimer;
    interface ReceiveMsg as VersionReceive;
    interface ReceiveMsg as VersionRequest;
    interface SendMsg as VersionSend;

    interface Timer as CapsuleTimer;
    interface ReceiveMsg as CapsuleChunkReceive;
    interface Receive as CapsuleChunkRouteReceive;
    interface Intercept as CapsuleChunkRouteIntercept;
    
    interface SendMsg as CapsuleChunkSend;
    interface ReceiveMsg as CapsuleStatusReceive;
    interface SendMsg as CapsuleStatusSend;
    
    interface Random as Random;
    interface StdControl as SubControl;
  }
}


implementation {

  typedef enum {
    MVIRUS_MAINTAIN,    // Everything seems to be in order: default state
    MVIRUS_REQUEST,     // Somebody has something newer: receive capsules
    MVIRUS_RESPOND,     // Somebody has something older: send capsules
  } MVirusState;

  MateCapsule* capsules[MATE_CAPSULE_NUM];
  MateCapsuleVersion versions[MATE_CAPSULE_NUM];
  
  MateTrickleTimer versionTimer;
  MateTrickleTimer capsuleTimer;
  MVirusState state;
  
  uint8_t currentCapsule;  // If we're exchanging1 a capsule, which one
  MateCapsuleVersion currentVersion; // If we need a capsule, what version
  uint8_t needBitmask[MVIRUS_BITMASK_SIZE];
  
  bool sendBusy;
  bool capsuleBusy;
  
  TOS_Msg sendMessage;
  TOS_MsgPtr sendPtr;

  void sendCapsulePacket();
  void sendVersionPacket(uint16_t to);


  void printNeedBitmask() {
#ifdef PLATFORM_PC
    int i;
    dbg(DBG_USR3, "\tneedBitmask: ");
    for (i = 0; i < MVIRUS_BITMASK_ENTRIES; i++) {
      dbg_clear(DBG_USR3, "%s", (needBitmask[i/8] & (0x80 >> (i % 8)))? "1":"0");
    }
    dbg_clear(DBG_USR3, "\n");
#endif
  }
  
  uint8_t bitEntry(uint8_t* mask, uint8_t which) {
    return (mask[which >> 3] & (1 << (7 - (which & 7))));
  }
  
  /* Select a new threshold, in the range [interval/2,interval], and
     clear out temporary state. */
  void newCounter(MateTrickleTimer* timer) {
    timer->elapsed = 0;
    timer->threshold = timer->interval / 2;
    timer->threshold += call Random.rand() % (timer->interval / 2);
    //dbg(DBG_USR3, "MVirus: Picking new counter %i in range [%i,%i].\n", (int)timer->threshold, (int)timer->interval/2, (int)timer->interval);
    timer->numHeard = 0;
  }

  void decayNeedField() {
    int i;
    dbg(DBG_USR3, "MVirus: Decaying need field.\n");
    printNeedBitmask();
    for (i = 0; i < MVIRUS_BITMASK_SIZE; i++) {
      needBitmask[i] &= (uint8_t)(call Random.rand());
    }
    printNeedBitmask();
  }

  void clearInvalidBits() {
    int i;
    uint8_t neededBits;
    uint16_t size = sizeof(MateCapsule) - MATE_CAPSULE_SIZE + capsules[currentCapsule]->dataSize;
    dbg(DBG_USR3, "MVirus: Total size of capsule is %i-%i+%i = %i (%i).\n", (int)sizeof(MateCapsule), (int)MATE_CAPSULE_SIZE, (int)capsules[currentCapsule]->dataSize, (int)(size), (int)MVIRUS_CHUNK_SIZE);
    size += (MVIRUS_CHUNK_SIZE - 1);
    size /= MVIRUS_CHUNK_SIZE;
    neededBits = size;
    dbg(DBG_USR3, "MVirus: Clearing need bits for caspule %i.%i. (%i)\n", (int)currentCapsule, (int)currentVersion, (int)size);
    printNeedBitmask();
    if (neededBits & 7) {
      uint8_t mask = (0x80 >> ((neededBits & 7) - 1));
      mask -= 1;
      mask = ~mask;
      needBitmask[neededBits / 8] &= mask;
      neededBits -= neededBits & 7;
      neededBits += 8;
    }
    for (i = neededBits / 8; i < MVIRUS_BITMASK_SIZE; i++) {
      needBitmask[i]  = 0;
    }
    printNeedBitmask();
  }

  void removeNeededBit(uint16_t bit) {
    uint8_t mask = (1 << (7 - (bit & 7)));
    dbg(DBG_USR3, "MVirus: clear mask for %i: %hhx -> %hhx\n", bit/8, mask, ~mask);
    mask = ~mask;
    needBitmask[bit / 8] &= mask;
  }
  
  command result_t StdControl.init() {
    call SubControl.init();
    call Random.init();
    
    state = MVIRUS_MAINTAIN;
    currentCapsule = MATE_CAPSULE_INVALID;
    memset(needBitmask, 0, MVIRUS_BITMASK_SIZE);

    // Initialize (but do not start) the timers
    versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
    capsuleTimer.interval = MVIRUS_CAPSULE_TAU;
    newCounter(&versionTimer);
    newCounter(&capsuleTimer);    

    sendPtr = (TOS_MsgPtr)&sendMessage;
    
    dbg(DBG_USR3, "MVirus: Initialized:\n\tchunk size=%i; bitmask size=%i\n", (int)MVIRUS_CHUNK_SIZE, (int)MVIRUS_BITMASK_SIZE);
    dbg(DBG_USR3, "\tversion constants: quantum=%i;tau_l=%i;tau_h=%i;k=%i\n", (int)MVIRUS_VERSION_TIMER, (int)MVIRUS_VERSION_TAU_MIN, (int)MVIRUS_VERSION_TAU_MAX, (int)MVIRUS_VERSION_REDUNDANCY);
    dbg(DBG_USR3, "\tcapsule constants: quantum=%i;tau=%i;repeat=%i;k=%i.\n", (int)MVIRUS_CAPSULE_TIMER, (int)MVIRUS_CAPSULE_TAU, (int)MVIRUS_CAPSULE_REPEAT, (int)MVIRUS_CAPSULE_REDUNDANCY);

    sendBusy = FALSE;
    capsuleBusy = FALSE;
    
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();
    dbg(DBG_USR3, "MVirus started.\n");
    call VersionTimer.start(TIMER_REPEAT, MVIRUS_VERSION_TIMER);
    dbg(DBG_USR3, "MVirus version timer started.\n");
    return SUCCESS;
  }

  command result_t Virus.registerCapsule(MateCapsuleID id, MateCapsule* capsule) {
    dbg(DBG_USR3, "MVirus: Registering capsule %i as 0x%x\n", (int)id, capsule);
    capsules[id] = capsule;
    return SUCCESS;
  }
  
  
  command result_t StdControl.stop() {
    call VersionTimer.stop();
    call CapsuleTimer.stop();
    dbg(DBG_USR3, "MVirus stopped.\n");
    return call SubControl.stop();
  }

  void toRequestState(uint8_t capsuleNum, MateCapsuleVersion version) {
    dbg(DBG_USR3, "MVirus: Moving to request state, capsule %i version %i.\n", (int)capsuleNum, (int)version);
    state = MVIRUS_REQUEST;
    currentCapsule = capsuleNum;
    currentVersion = version;
    memset(needBitmask, 0xff, MVIRUS_BITMASK_SIZE);
    signal EngineControl.halt();
    
    versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
    newCounter(&versionTimer);
    call VersionTimer.stop();
    call VersionTimer.start(TIMER_REPEAT, MVIRUS_VERSION_TIMER);
  }

  void toResponseState(uint8_t capsuleNum) {
    dbg(DBG_USR3, "MVirus: Moving to response state, capsule %i version %i.\n", (int)capsuleNum, (int)versions[capsuleNum]);
    state = MVIRUS_RESPOND;
    currentCapsule = capsuleNum;
    
    newCounter(&capsuleTimer);
    call CapsuleTimer.stop();
    call CapsuleTimer.start(TIMER_REPEAT, MVIRUS_CAPSULE_TIMER);
  }

  void toMaintainState() {
    dbg(DBG_USR3, "MVirus: Moving to maintain state, capsule %i version %i.\n");
    state = MVIRUS_MAINTAIN;
    call CapsuleTimer.stop();
  }
  
  
  task void versionTimerTask() {
    versionTimer.elapsed++;
    if (versionTimer.elapsed == versionTimer.threshold) {
      if (versionTimer.numHeard < MVIRUS_VERSION_REDUNDANCY) {
//	dbg(DBG_USR3, "MVirus: Sending version packet @%s\n", currentTime());
	sendVersionPacket(TOS_BCAST_ADDR);
      }
    }
    else if (versionTimer.elapsed >= versionTimer.interval) {
      dbg(DBG_USR3, "MVirus: Version tau elapsed, picking new t.\n");
      versionTimer.interval *= 2;
      if (versionTimer.interval > MVIRUS_VERSION_TAU_MAX) {
	versionTimer.interval = MVIRUS_VERSION_TAU_MAX;
      }
      newCounter(&versionTimer);
    }
    else {
      // do nothing
    }
  }

  task void capsuleTimerTask() {
    capsuleTimer.elapsed++;
    if (capsuleTimer.elapsed == capsuleTimer.threshold) {
      if (capsuleTimer.numHeard < MVIRUS_CAPSULE_REDUNDANCY) {
//	dbg(DBG_USR3, "MVirus: Sending capsule packet @%s.\n", currentTime());
	sendCapsulePacket();
	capsuleTimer.numHeard++;
      }
    }
    else if (capsuleTimer.elapsed >= capsuleTimer.interval) {
      newCounter(&capsuleTimer);
      decayNeedField();
    }
    else {
      // do nothing
    }
  }


  int8_t getRandomChunkIndex(uint8_t capsule) {
    uint8_t idx;
    uint8_t count = 0;
    uint16_t size = sizeof(MateCapsule);

    dbg(DBG_USR3, "MVirus: Get random chunk index from\n");
    printNeedBitmask();
    size -= (MATE_CAPSULE_SIZE - capsules[capsule]->dataSize);
    size += (MVIRUS_CHUNK_SIZE - 1);
    size /= MVIRUS_CHUNK_SIZE;
    for (idx = 0; idx < size; idx++) {
      if (bitEntry(needBitmask, idx)) {
	count++;
      }
    }

    if (count == 0) {
      dbg(DBG_USR3, "MVirus: Tried to select capsule chunk to send, but none were needed. Returning -1.\n");
      return -1;
    }

    count = (call Random.rand() % count) + 1;

    for (idx = 0; idx < size; idx++) {
      if (bitEntry(needBitmask, idx)) {
	count--;
      }
      if (count == 0) {
	dbg(DBG_USR3, "MVirus: Select capsule chunk %i to send.\n", (int)idx);
	return (int8_t)idx;
      }
    }
    dbg(DBG_USR3, "MVirus: Tried to select capsule chunk to send, but encountered an error due to miscount. Returning -1.\n");
    return -1;
  }
  
  void sendCapsulePacket() {
    if (sendBusy) {
      dbg(DBG_USR3, "MVirus: Tried to send capsule, but send busy.\n");
      return;
    }
    else {
      int8_t idx = getRandomChunkIndex(currentCapsule);
      if (idx >= 0) {
	MateCapsuleChunkMsg* chunk = (MateCapsuleChunkMsg*)sendPtr->data;

	uint8_t* chunkPtr = (uint8_t*)capsules[currentCapsule];
	chunkPtr += MVIRUS_CHUNK_SIZE * idx;
	memcpy(chunk->chunk, chunkPtr, MVIRUS_CHUNK_SIZE);

	chunk->capsuleNum = currentCapsule;
	chunk->piece = idx;
	chunk->version = versions[currentCapsule];
	if (call CapsuleChunkSend.send(TOS_BCAST_ADDR, sizeof(MateCapsuleChunkMsg), sendPtr) == SUCCESS) {
	  dbg(DBG_USR3, "MVirus: Sent chunk %i of capsule %i.%i.\n", (int)idx, (int)currentCapsule, (int)currentVersion);
	  sendBusy = TRUE;
	  removeNeededBit(idx);
	}
	else {
	  dbg(DBG_USR3, "MVirus: Sending chunk %i of capsule %i.%i FAILED.\n", (int)idx, (int)currentCapsule, (int)currentVersion);
	}
      }
      else {
	dbg(DBG_USR3, "MVirus: Tried to send capsule, but nothing to send. Return to maintain state.\n");
	toMaintainState();
      }
    }
  }

  void sendVersionPacket(uint16_t to) {
    if (sendBusy) {
      dbg(DBG_USR3, "MVirus: Tried to send version packet, but send busy.\n");
      return;
    }
    
    if (state == MVIRUS_MAINTAIN ||
	state == MVIRUS_RESPOND) {
      int i;
      MateVersionMsg* versionMsg = (MateVersionMsg*)sendPtr->data;
      dbg(DBG_USR3, "MVirus: In state %i, sending version vector:\n  ", (int)state);
      for (i = 0; i < MATE_CAPSULE_NUM; i++) {
	dbg_clear(DBG_USR3, "[%i]", (int)versions[i]);
	versionMsg->versions[i] = versions[i];
      }
      dbg_clear(DBG_USR3, "\n");
      if (call VersionSend.send(to,
				sizeof(MateVersionMsg),
				sendPtr) == SUCCESS) {
	dbg(DBG_USR3, "MVirus: Sent version vector.\n");
	sendBusy = TRUE;
      }
    }
    else if (state == MVIRUS_REQUEST && to == TOS_BCAST_ADDR) {
      MateCapsuleStatusMsg* statusMsg = (MateCapsuleStatusMsg*)sendPtr->data;
      statusMsg->capsuleNum = currentCapsule;
      statusMsg->version = currentVersion;
      memcpy(statusMsg->bitmask, needBitmask, MVIRUS_BITMASK_SIZE);
      dbg(DBG_USR3, "MVirus: In state %i, sending bitmask:\n", (int)state);
      printNeedBitmask();
      if (call CapsuleStatusSend.send(TOS_BCAST_ADDR,
				      sizeof(MateCapsuleStatusMsg),
				      sendPtr) == SUCCESS) {
	dbg(DBG_USR3, "MVirus: Sent version bitmask.\n");
	sendBusy = TRUE;
      }
    }
    else {
      dbg(DBG_USR3|DBG_ERROR, "MVirus: In invalid state for sending version packet: %i\n", (int)state);
      return;
    }
  }
  
  TOS_MsgPtr receiveVector(TOS_MsgPtr msg) {
    uint8_t capsuleNum;
    int8_t comparison = 0; // msg is: -1 older, 0 same, 1 newer
    MateVersionMsg* versionMsg = (MateVersionMsg*)msg->data;

    if (state == MVIRUS_REQUEST) {
      if (versionMsg->versions[currentCapsule] > currentVersion) {
	dbg(DBG_USR3, "In request state for %i.%i, upgrade to %i.%i.\n",
	    (int)currentCapsule, (int)currentVersion,
	    (int)currentCapsule, (int)versionMsg->versions[currentCapsule]);
	toRequestState(currentCapsule, versionMsg->versions[currentCapsule]);
      }
      else if (versionMsg->versions[currentCapsule] == currentVersion) {
	versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
	newCounter(&versionTimer);
	call VersionTimer.stop();
	call VersionTimer.start(TIMER_REPEAT, MVIRUS_VERSION_TIMER);
      }
      else {
	dbg(DBG_USR3, "In request state for %i.%i already.\n", (int)currentCapsule, (int)currentVersion);
      }
      return msg;
    }
    
    for (capsuleNum = 0; capsuleNum < MATE_CAPSULE_NUM; capsuleNum++) {
      if (capsules[capsuleNum] != NULL) {
	if(versionMsg->versions[capsuleNum] > versions[capsuleNum]) {
	  comparison = 1;
	  break;
	}
	else if (versionMsg->versions[capsuleNum] <
		 versions[capsuleNum]) {
	  comparison = -1;
	  break;
	}
      }
    }
    
    // Requests are given precedence over responses: there's no
    // point updating someone to something that's out of date.
    if (comparison == 0) {
      dbg(DBG_USR3, "Heard identical vector, suppressing.\n");
      versionTimer.numHeard++;
    }
    else if (comparison == 1) {
      dbg(DBG_USR3, "Heard newer vector, requesting.\n");
      if (state != MVIRUS_REQUEST) {
	toRequestState(capsuleNum, versionMsg->versions[capsuleNum]);
      }
    }
    else if (comparison == -1) {
      dbg(DBG_USR3, "Heard older vector, updating.\n");
      if (state == MVIRUS_MAINTAIN) {
	memset(needBitmask, 0xff, MVIRUS_BITMASK_SIZE);
	toResponseState(capsuleNum);
      }
    }
    return msg;
  }

  task void checkNeedTask() {
    uint8_t i;
    for (i = 0; i < MVIRUS_BITMASK_SIZE; i++) {
      if (needBitmask[i] != 0) {
	return;
      }
    }
    //dbg(DBG_USR3, "MVirus: all chunks for %i.%i received, move to maintain state @%s.\n", (int)currentCapsule, (int)currentVersion, currentTime());
    //printf("%i: MVirus: all chunks for %i.%i received, move to maintain state @%s.\n", (int)tos_state.current_node, (int)currentCapsule, (int)currentVersion, currentTime());
    signal Virus.capsuleInstalled(currentCapsule, capsules[currentCapsule]);
    versions[currentCapsule] = currentVersion;
    versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
    newCounter(&versionTimer);
    toMaintainState();
    signal EngineControl.resume();
  }
  
  void installChunk(MateCapsuleChunkMsg* chunk) {
    uint8_t* destPtr = (uint8_t*)capsules[chunk->capsuleNum];
    destPtr += chunk->piece * MVIRUS_CHUNK_SIZE;
    dbg(DBG_USR3, "MVirus: Copying chunk %i of capsule %i version %i.\n", chunk->piece, chunk->capsuleNum, chunk->version);
    memcpy(destPtr, chunk->chunk, MVIRUS_CHUNK_SIZE);
    // Remove that bit entry
    if (chunk->piece == 0) { // If it's the chunk metadata, clear out bits
      clearInvalidBits();
    }
    removeNeededBit(chunk->piece);
    printNeedBitmask();
    post checkNeedTask();
  }


  void chunkReceive(MateCapsuleChunkMsg* chunk) {
    capsuleTimer.numHeard++;
    
//    dbg(DBG_USR3, "MVirus: Received chunk %i of capsule %i.%i @%s.\n", (int)chunk->piece, (int)chunk->capsuleNum, (int)chunk->version, currentTime());
    if (state == MVIRUS_REQUEST) {
      if (chunk->capsuleNum == currentCapsule &&
	  chunk->version == currentVersion &&
	  bitEntry(needBitmask, chunk->piece)) {
	installChunk(chunk);
	versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
	newCounter(&versionTimer);
      }
      else if (chunk->capsuleNum == currentCapsule &&
	       chunk->version > currentVersion) {
	toRequestState(chunk->capsuleNum, chunk->version);
	installChunk(chunk);
	versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
	newCounter(&versionTimer);
      }
    }
    else if (state == MVIRUS_MAINTAIN) {
      if (chunk->version > versions[chunk->capsuleNum]) {
	toRequestState(chunk->capsuleNum, chunk->version);
	installChunk(chunk);
	versionTimer.interval = MVIRUS_VERSION_TAU_MIN;
	newCounter(&versionTimer);
      }
    }
  }
  
  event TOS_MsgPtr CapsuleChunkReceive.receive(TOS_MsgPtr msg) {
    MateCapsuleChunkMsg* chunk = (MateCapsuleChunkMsg*)msg->data;
    dbg(DBG_USR3, "MVirus: Received chunk broadcast.\n");
    chunkReceive(chunk);
    return msg;
  }

  event TOS_MsgPtr CapsuleChunkRouteReceive.receive(TOS_MsgPtr msg,
						    void* payload,
						    uint16_t payloadLen) {
    if (payloadLen == sizeof(MateCapsuleChunkMsg)) {
      MateCapsuleChunkMsg* chunk = (MateCapsuleChunkMsg*)payload;
      dbg(DBG_USR3, "MVirus: Received routed chunk.\n");
      chunkReceive(chunk);
    }
    else {
      dbg(DBG_USR3, "MVirus: Intercepted routed chunk of improper size (%i not %i).\n", payloadLen, sizeof(MateCapsuleChunkMsg));
    }
    return msg;
  }

  event result_t CapsuleChunkRouteIntercept.intercept(TOS_MsgPtr msg,
							void* payload,
							uint16_t payloadLen) {
    if (payloadLen == sizeof(MateCapsuleChunkMsg)) {
      MateCapsuleChunkMsg* chunk = (MateCapsuleChunkMsg*)payload;
      if (msg->addr == TOS_LOCAL_ADDRESS) {
	dbg(DBG_USR3, "MVirus: Intercepted routed chunk.\n");
      }
      else {
	dbg(DBG_USR3, "MVirus: Snooped routed chunk for %i.\n", (int)msg->addr);
      }
      chunkReceive(chunk);
    }
    else {
      dbg(DBG_USR3, "MVirus: Intercepted routed chunk of improper size (%i not %i).\n", payloadLen, sizeof(MateCapsuleChunkMsg));
    }
    return SUCCESS;
  }

  
  
  event TOS_MsgPtr CapsuleStatusReceive.receive(TOS_MsgPtr msg) {
    MateCapsuleStatusMsg* statusMsg = (MateCapsuleStatusMsg*)msg->data;
    MateCapsuleVersion version = statusMsg->version;
    MateCapsuleID which = statusMsg->capsuleNum;
    dbg(DBG_USR3, "MVirus: Received status message for %i.%i @%s\n", (int)which, (int)version, currentTime());
    // If I'm requesting this capsule already...
    if ((state == MVIRUS_REQUEST) &&
	(currentCapsule == which)) {
      // and this version, increment my counter.
      if (currentVersion == version) {
	versionTimer.numHeard++;
      }
      // and an older version, request the new version.
      else if (currentVersion < version) {
	toRequestState(which, version);
      }
    }
    // If I'm idle or responding, and need this capsule,
    // start requesting it.
    else if (((state == MVIRUS_MAINTAIN) || (state == MVIRUS_RESPOND)) &&
	     (versions[which] < version)) {
      toRequestState(which, version);
    }
    // If I'm idle and have this capsule, respond with parts of it.
    else if (state == MVIRUS_MAINTAIN &&
	     (versions[which] == version)) {
      memcpy(needBitmask, statusMsg->bitmask, MVIRUS_BITMASK_SIZE);
      toResponseState(which);
    }

    // If I'm responding, then add these to the parts I know are needed.
    if ((state == MVIRUS_RESPOND) &&
	(currentCapsule == which) &&
	(versions[which] == version)) {
      int i;
      for (i = 0; i < MVIRUS_BITMASK_SIZE; i++) {
	needBitmask[i] |= statusMsg->bitmask[i];
      }
    }
    return msg;
  }

  event TOS_MsgPtr VersionReceive.receive(TOS_MsgPtr msg) {
//    dbg(DBG_USR3, "MVirus: Received version vector @%s.\n", currentTime());
    return receiveVector(msg);
  }

  event TOS_MsgPtr VersionRequest.receive(TOS_MsgPtr msg) {
//    dbg(DBG_USR3, "MVirus: Received version request @%s.\n", currentTime());
    sendVersionPacket(TOS_UART_ADDR);
    return msg;
  }

  event result_t CapsuleStatusSend.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == sendPtr) {
      sendBusy = FALSE;
//      dbg(DBG_USR3, "MVirus: CapsuleStatus send done event handled @%s.\n", currentTime());
    }
    else {
      dbg(DBG_USR3, "MVirus: CapsuleStatus send done event FOR WRONG PACKET handled @%s.\n", currentTime());
    }
    return SUCCESS;
  }

  event result_t CapsuleChunkSend.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == sendPtr) {
      sendBusy = FALSE;
//      dbg(DBG_USR3, "MVirus: CapsuleChunk send done event handled @%s.\n", currentTime());
    }
    return SUCCESS;
  }

  event result_t VersionSend.sendDone(TOS_MsgPtr msg, result_t success) {
    if (msg == sendPtr) {
      sendBusy = FALSE;
//      dbg(DBG_USR3, "MVirus: Version send done event handled @%s.\n", currentTime());
    }
    return SUCCESS;
  }

  event result_t VersionTimer.fired() {
    post versionTimerTask();
    return SUCCESS;
  }

  event result_t CapsuleTimer.fired() {
    post capsuleTimerTask();
    return SUCCESS;
  }
  
}
