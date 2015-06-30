/**
 * Copyright (c) 2007, Institute of Parallel and Distributed Systems
 * (IPVS), Universität Stuttgart. 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 * 
 *  - Neither the names of the Institute of Parallel and Distributed
 *    Systems and Universität Stuttgart nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */
#ifndef DEBUG_GCC_H
#define DEBUG_GCC_H

/*#include "debugoutput.h"
#include <stdarg.h>
#include <stdio.h>

enum {
  MAX_DEBUG_STRING = 100,
};

typedef struct DebugData {
  uint8_t level;
  char string[MAX_DEBUG_STRING + 1];
} __attribute__((packed)) DebugData;


void  __attribute__((noinline)) _debugOutput(DebugData* debugData) {
	asm volatile ("nop"::);
}

// nesC compiler suppresses calls to dbg!

static void debug(uint8_t level, char* formatString, ...) {
  va_list arguments;
  DebugData debugData;
  debugData.level = level;
  va_start(arguments, formatString);
  vsnprintf(debugData.string, MAX_DEBUG_STRING, formatString, arguments);
  _debugOutput(&debugData);
  va_end(arguments);
}
*/

static void __attribute__((noinline)) debug_int(uint16_t intValue) {
  asm volatile ("nop"::);
}

#endif /* DBG_H */
