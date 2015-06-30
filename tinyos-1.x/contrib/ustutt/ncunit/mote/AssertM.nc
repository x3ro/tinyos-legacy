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
#include <stdio.h>
module AssertM {
  provides {
	interface Assert;
  }
  uses interface Leds;
}
implementation {

  enum {
	MSG_LENGTH = 80,
  };

#include "ncunit.h"

  typedef struct AssertJavaClassInfo {
	volatile char* javaClass;
	volatile char* message;
	volatile uint32_t timerDelay;
  } AssertJavaClassInfo;

  typedef struct AssertCallsInfo {
	volatile char* functionName;
	volatile char* message;
	volatile char* parameterName;
	volatile void* comparisonValue;
	volatile CompOperator compOperator;
  } AssertCallsInfo;

  typedef struct VariablePointerInfo{
	volatile void* pointer;
	volatile char* variableName;
  } __attribute__((packed)) VariablePointerInfo;

  static void assertFailMsg(char* message) __attribute__((noinline)) {
	asm volatile ("nop"::);
#ifdef PLATFORM_PC
	dbg_clear(DBG_USR1, "Assert failed: %s\n", message);
	exit(1);
#endif
  }

  static void assertJavaClassMsg(AssertJavaClassInfo* info) __attribute__((noinline)) {
	asm volatile ("nop"::);
  }

  static void assertCallsMsg(AssertCallsInfo* info) __attribute__((noinline)) {
	asm volatile ("nop"::);
	call Leds.yellowToggle();
  }

  static void getDataPointer(VariablePointerInfo* info) __attribute__((noinline)) {
	asm volatile ("nop"::);
  }

  command void Assert.assertNull(void* pointer) {
	call Assert.assertNullMsg("", pointer);
  }

  command void Assert.assertNullMsg(char* message, void* pointer) {
	if (pointer != NULL) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertNull not NULL -- %s", message);
	  assertFailMsg(completeMsg);
	}
  }

  command void Assert.assertNotNull(void* pointer) {
	call Assert.assertNotNullMsg("", pointer);
  }

  command void Assert.assertNotNullMsg(char* message, void* pointer) {
	if (pointer == NULL) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertNotNull NULL -- %s", message);
	  assertFailMsg(completeMsg);
	}
  }

  command void Assert.assertTrue(bool value) {
	call Assert.assertTrueMsg("", value);
  }

  command void Assert.assertTrueMsg(char* message, bool value) {
	if (value != TRUE) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertTrue not TRUE -- %s", message);
	  assertFailMsg(completeMsg);
	}
  }

  command void Assert.assertFalse(bool value) {
	call Assert.assertFalseMsg("", value);
  }

  command void Assert.assertFalseMsg(char* message, bool value) {
	if (value != FALSE) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertFalse not FALSE -- %s", message);
	  assertFailMsg(completeMsg);
	}
  }

  command void Assert.assertSame(void* pointer1, void* pointer2) {
	call Assert.assertSameMsg("", pointer1, pointer2);
  }

  command void Assert.assertSameMsg(char* message, void* pointer1, void* pointer2) {
	if (pointer1 != pointer2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertSame not the same %#x != %#x -- %s", pointer1, pointer2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertNotSame(void* pointer1, void* pointer2) {
	call Assert.assertNotSameMsg("", pointer1, pointer2);
  }

  command void Assert.assertNotSameMsg(char* message, void* pointer1, void* pointer2) {
	if (pointer1 == pointer2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertNotSame are the same %#x == %#x -- %s", pointer1, pointer2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertEqualsInt(int32_t int1, int32_t int2) {
	call Assert.assertEqualsIntMsg("", int1, int2);
  }

  command void Assert.assertEqualsIntMsg(char* message, int32_t int1, int32_t int2) {
	if (int1 != int2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertEqualsInt not equal %li != %li -- %s", int1, int2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertEqualsUint(uint32_t uint1, uint32_t uint2) {
	call Assert.assertEqualsUintMsg("", uint1, uint2);
  }

  command void Assert.assertEqualsUintMsg(char* message, uint32_t uint1, uint32_t uint2) {
	if (uint1 != uint2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertEqualsUint not equal %li != %li -- %s", uint1, uint2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertEqualsBool(bool bool1, bool bool2) {
	call Assert.assertEqualsBoolMsg("", bool1, bool2);
  }

  command void Assert.assertEqualsBoolMsg(char* message, bool bool1, bool bool2) {
	if (bool1 != bool2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertEqualsBool not equal %i != %i -- %s", bool1, bool2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertEqualsDouble(double double1, double double2) {
	call Assert.assertEqualsDoubleMsg("", double1, double2);
  }

  command void Assert.assertEqualsDoubleMsg(char* message, double double1, double double2) {
	if (double1 != double2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertEqualsDouble not equal %f != %f -- %s", double1, double2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertEqualsFloat(float float1, float float2) {
	call Assert.assertEqualsFloatMsg("", float1, float2);
  }

  command void Assert.assertEqualsFloatMsg(char* message, float float1, float float2) {
	if (float1 != float2) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertEqualsFloat not equal %f != %f -- %s", float1, float2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.assertEqualsMem(void* pointer1, void* pointer2, uint16_t size) {
	call Assert.assertEqualsMemMsg("", pointer1, pointer2, size);
  }

  command void Assert.assertEqualsMemMsg(char* message, void* pointer1, void* pointer2, uint16_t size) {
	if (memcmp(pointer1, pointer2, size) != 0) {
	  char completeMsg[MSG_LENGTH];
	  sprintf(completeMsg, "nCUnit: assertEqualsMem not equal *%#x != *%#x -- %s", pointer1, pointer2, message);
	  assertFailMsg(completeMsg);
	}
  }


  command void Assert.fail() {
	call Assert.failMsg("");
  }

  command void Assert.failMsg(char* message) {
	char completeMsg[MSG_LENGTH];
	sprintf(completeMsg, "nCUnit: failMsg -- %s", message);
	assertFailMsg(completeMsg);
  }


  command void Assert.assertJavaClass(char* javaClass, uint32_t timerDelay) {
	call Assert.assertJavaClassMsg("", javaClass, timerDelay);
  }

  command void Assert.assertJavaClassMsg(char* message, char* javaClass, uint32_t timerDelay) {
	AssertJavaClassInfo javaClassInfo;
	/*	char completeMsg[MSG_LENGTH];
		sprintf(completeMsg, "nCUnit: assertJavaClassMsg %s -- %s", javaClass, message);*/
	javaClassInfo.message = message;
	javaClassInfo.javaClass = javaClass;
	javaClassInfo.timerDelay = timerDelay;
	assertJavaClassMsg(&javaClassInfo);
  }

  command void Assert.assertCalls(char* functionName, char* paramName, volatile void* value, CompOperator op) {
	call Assert.assertCallsMsg("", functionName, paramName, value, op);
  }

  command void Assert.assertCallsMsg(char* message, char* functionName, char* paramName, volatile void* value, CompOperator op) {
	volatile AssertCallsInfo callsInfo;
	/*	char completeMsg[MSG_LENGTH];
		sprintf(completeMsg, "nCUnit: asserCallsMsg %s -- %s", functionName, message);*/
	callsInfo.message = message;
	callsInfo.functionName = functionName;
	callsInfo.parameterName = paramName;
	callsInfo.comparisonValue = value;
	callsInfo.compOperator = op;
	assertCallsMsg(&callsInfo);
  }

  command void* Assert.getDataPointer(char* variableName) {
	VariablePointerInfo pointerInfo;
	pointerInfo.variableName = variableName;
	getDataPointer(&pointerInfo);
	return (void*) pointerInfo.pointer;
  }

}
