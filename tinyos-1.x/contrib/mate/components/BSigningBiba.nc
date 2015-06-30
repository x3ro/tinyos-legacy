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
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
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
 * Authors:   Philip Levis
 * History:   Nov 21, 2002
 *	     
 *
 */

includes Bombilla;
includes BombillaMsgs;
includes SEAL;

module BSigningBiba {
  provides interface StdControl;
  provides interface BombillaSigning as Signing;
  uses interface BombillaError;
}

implementation {


  
  enum {
    BSIGN_IDLE = 0,
    BSIGN_PENDING = 1,
    BSIGN_WORKING = 2,
    BSIGN_CANCELLED = 3
  };

  uint32_t A, B, C, D;
  uint64_t messageHash;
  uint32_t hashes[3];
  
  result_t signSuccess;
  
  uint8_t state;
  BombillaCapsule* input;
  BombillaCapsule* output;

  int msgLen;
  int chunkLen;
  int capsuleLen;
  int binSize;
  
  result_t checkSig(BombillaCapsule* capsule);
  
  command result_t StdControl.init() {
    chunkLen = 64;
    msgLen = chunkLen - sizeof(uint64_t);
    capsuleLen = sizeof(BombillaCapsule) - sizeof(BombillaBiBaSignature);
    binSize = 72640;
    state = BSIGN_CANCELLED;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    state = BSIGN_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    state = BSIGN_CANCELLED;
    return SUCCESS;
  }

  void fillBuffer(uint8_t* buffer, uint8_t* data, uint8_t len) {
    int i;
    uint64_t* lenPtr;
    nmemcpy(buffer, data, len);
    dbg(DBG_CRYPTO, "Starting buffer:\n  ");
    for (i = 0; i < chunkLen; i++) {
      dbg_clear(DBG_CRYPTO, "%02hhx ", buffer[i]);
      if ((i + 1) % 8 == 0) {dbg_clear(DBG_CRYPTO, "\n  ");} 
    }
    dbg(DBG_CRYPTO, "Filled in %i bytes of buffer.\n", len);
    buffer[len] = (uint8_t)0x80;
    dbg(DBG_CRYPTO, "Appended 0x80.\n");
    for (i = len + 1; i < msgLen; i++) {
      buffer[i] = 0;
    }
    dbg(DBG_CRYPTO, "Filled in %i zeroes for total length of %i.\n", msgLen - len - 1, msgLen);
    lenPtr = (uint64_t*)&(buffer[msgLen]);
    *lenPtr = (uint64_t)len;
    dbg(DBG_CRYPTO, "Filled in length filed for total length of %i\n", msgLen + sizeof(uint64_t));
    dbg(DBG_CRYPTO, "Final buffer:\n  ");
    for (i = 0; i < chunkLen; i++) {
      dbg_clear(DBG_CRYPTO, "%02hhx ", buffer[i]);
      if ((i + 1) % 8 == 0) {dbg_clear(DBG_CRYPTO, "\n  ");} 
    }
  }

#define MASK32 0xffffffff
#define F(X,Y,Z) ((((X)&(Y)) | ((~(X))&(Z))))
#define G(X,Y,Z) ((((X)&(Y)) | ((X)&(Z)) | ((Y)&(Z))))
#define H(X,Y,Z) (((X)^(Y)^(Z)))
#define lshift(x,s) (((((x)<<(s))&MASK32) | (((x)>>(32-(s)))&MASK32)))

#define ROUND1(a,b,c,d,k,s) a = lshift((a + F(b,c,d) + M[k])&MASK32, s)
#define ROUND2(a,b,c,d,k,s) a = lshift((a + G(b,c,d) + M[k] + 0x5A827999)&MASK32,s)
#define ROUND3(a,b,c,d,k,s) a = lshift((a + H(b,c,d) + M[k] + 0x6ED9EBA1)&MASK32,s)

  uint64_t mdfour64(uint32_t *M) {
    uint32_t AA, BB, CC, DD;
    uint64_t result = 0;
    
    A = 0x67452301;
    B = 0xefcdab89;
    C = 0x98badcfe;
    D = 0x10325476;

    dbg(DBG_CRYPTO, "Initializing hash.\n");
    AA = A; BB = B; CC = C; DD = D;

    ROUND1(A,B,C,D,  0,  3);  ROUND1(D,A,B,C,  1,  7);  
    ROUND1(C,D,A,B,  2, 11);  ROUND1(B,C,D,A,  3, 19);
    ROUND1(A,B,C,D,  4,  3);  ROUND1(D,A,B,C,  5,  7);  
    ROUND1(C,D,A,B,  6, 11);  ROUND1(B,C,D,A,  7, 19);
    ROUND1(A,B,C,D,  8,  3);  ROUND1(D,A,B,C,  9,  7);  
    ROUND1(C,D,A,B, 10, 11);  ROUND1(B,C,D,A, 11, 19);
    ROUND1(A,B,C,D, 12,  3);  ROUND1(D,A,B,C, 13,  7);  
    ROUND1(C,D,A,B, 14, 11);  ROUND1(B,C,D,A, 15, 19);        
    dbg(DBG_CRYPTO, "Completed round 1.\n");
  
    ROUND2(A,B,C,D,  0,  3);  ROUND2(D,A,B,C,  4,  5);  
    ROUND2(C,D,A,B,  8,  9);  ROUND2(B,C,D,A, 12, 13);
    ROUND2(A,B,C,D,  1,  3);  ROUND2(D,A,B,C,  5,  5);  
    ROUND2(C,D,A,B,  9,  9);  ROUND2(B,C,D,A, 13, 13);
    ROUND2(A,B,C,D,  2,  3);  ROUND2(D,A,B,C,  6,  5);  
    ROUND2(C,D,A,B, 10,  9);  ROUND2(B,C,D,A, 14, 13);
    ROUND2(A,B,C,D,  3,  3);  ROUND2(D,A,B,C,  7,  5);  
    ROUND2(C,D,A,B, 11,  9);  ROUND2(B,C,D,A, 15, 13);
    dbg(DBG_CRYPTO, "Completed round 2.\n");
  
    ROUND3(A,B,C,D,  0,  3);  ROUND3(D,A,B,C,  8,  9);  
    ROUND3(C,D,A,B,  4, 11);  ROUND3(B,C,D,A, 12, 15);
    ROUND3(A,B,C,D,  2,  3);  ROUND3(D,A,B,C, 10,  9);  
    ROUND3(C,D,A,B,  6, 11);  ROUND3(B,C,D,A, 14, 15);
    ROUND3(A,B,C,D,  1,  3);  ROUND3(D,A,B,C,  9,  9);  
    ROUND3(C,D,A,B,  5, 11);  ROUND3(B,C,D,A, 13, 15);
    ROUND3(A,B,C,D,  3,  3);  ROUND3(D,A,B,C, 11,  9);  
    ROUND3(C,D,A,B,  7, 11);  ROUND3(B,C,D,A, 15, 15);
    dbg(DBG_CRYPTO, "Completed round 3.\n");
  
    A += AA; B += BB; 
    C += CC; D += DD;
  
    A &= MASK32; B &= MASK32; 
    C &= MASK32; D &= MASK32;

    dbg(DBG_CRYPTO, "Hash: 0x%x%x%x%x (0x%x%x)\n", A, B, C, D, C, D);

    result = 0;
    result |= (A ^ C);
    result = result << 32;
    result |= (B ^ D);
    
    return result;
  }

  uint64_t getSEAL(uint16_t idx) {
    return SEALTable[idx];
  }
  
  uint64_t computeHash(BombillaCapsule* capsule) {
    uint32_t buffer[(chunkLen >> 2)];
    uint64_t result;
    fillBuffer((uint8_t*)buffer, (uint8_t*)capsule, capsuleLen);
    result = mdfour64(buffer);
    dbg(DBG_CRYPTO, "Computed: 0x%016llx\n", result);
    return result;
  }

  task void checkCompleteTask() {
    result_t success = FAIL;
    if (state != BSIGN_PENDING) {return;}
    if ((hashes[0] == hashes[1]) && (hashes[1] == hashes[2])) {
      dbg(DBG_CRYPTO, "BiBa: Signature verified.\n");
      success = SUCCESS;
    }
    else {
      dbg(DBG_CRYPTO, "BiBa: Signature failed.\n");
    }
    state = BSIGN_IDLE;
    signal Signing.checkComplete(input, success);
  }

  task void thirdCheckTask() {
    uint64_t vals[2];
    uint32_t buffer[chunkLen >> 2];
    uint16_t idx = (input->signature.indexes >> 20) & 0x3ff;

    dbg(DBG_CRYPTO, "BiBa: Third check task starting: %i\n", (int)idx);
    
    vals[0] = messageHash;
    vals[1] = getSEAL(idx);
    fillBuffer((uint8_t*)buffer, (uint8_t*)vals, sizeof(vals));
    vals[0] = mdfour64(buffer);
    hashes[2] = vals[0] % binSize;
    post checkCompleteTask();
  }

  task void secondCheckTask() {
    uint64_t vals[2];
    uint32_t buffer[chunkLen >> 2];
    uint16_t idx = (input->signature.indexes >> 10) & 0x3ff;

    dbg(DBG_CRYPTO, "BiBa: Second check task starting: %i\n", (int)idx);

    vals[0] = messageHash;
    vals[1] = getSEAL(idx);
    fillBuffer((uint8_t*)buffer, (uint8_t*)vals, sizeof(vals));
    vals[0] = mdfour64(buffer);
    hashes[1] = vals[0] % binSize;
    post thirdCheckTask();
  }

  task void firstCheckTask() {
    uint64_t vals[2];
    uint32_t buffer[chunkLen >> 2];
    uint16_t idx = input->signature.indexes & 0x3ff;

    dbg(DBG_CRYPTO, "BiBa: First check task starting: %i\n", (int)idx);

    vals[0] = messageHash;
    vals[1] = getSEAL(idx);
    fillBuffer((uint8_t*)buffer, (uint8_t*)vals, sizeof(vals));
    vals[0] = mdfour64(buffer);
    hashes[0] = vals[0] % binSize;
    post secondCheckTask();
  }
  
  task void signingTask() {
    if (state != BSIGN_PENDING) {return;}
    messageHash = (computeHash(input) ^ input->signature.counter);
    post firstCheckTask();
  }
  
  command result_t Signing.checkSignature(BombillaCapsule* capsule) {
    dbg(DBG_CRYPTO, "BiBa: Checking signature.\n");
    if (state != BSIGN_IDLE) {
      return FAIL;
    }
    else {
      uint16_t indexes[3];
      indexes[0] = capsule->signature.indexes & 0x3f;
      indexes[1] = (capsule->signature.indexes >> 10) & 0x3f;
      indexes[2] = (capsule->signature.indexes >> 20) & 0x3f;
      if (indexes[0] == indexes[1] || indexes[1] == indexes[2] ||
	  indexes[0] == indexes[2]) {
	dbg(DBG_CRYPTO, "BiBa: Redundant indexes provided. Fail.\n");
	return FAIL;
      }
      state = BSIGN_PENDING;
      input = capsule;
      post signingTask();
      return SUCCESS;
    }
  }
}
