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
#include "ncunit.h"
interface Assert {

  // Checks if the pointer is NULL
  command void assertNull(void* pointer);
  command void assertNullMsg(char* message, void* pointer);

  // Checks if the pointer is not NULL
  command void assertNotNull(void* pointer);
  command void assertNotNullMsg(char* message, void* pointer);

  // Checks if the value is TRUE
  command void assertTrue(bool value);
  command void assertTrueMsg(char* message, bool value);

  // Checks if the value is FALSE
  command void assertFalse(bool value);
  command void assertFalseMsg(char* message, bool value);

  // Checks if the pointers point to the same address
  command void assertSame(void* pointer1, void* pointer2);
  command void assertSameMsg(char* message, void* pointer1, void* pointer2);

  // Checks if the pointers point not to the same address
  command void assertNotSame(void* pointer1, void* pointer2);
  command void assertNotSameMsg(char* message, void* pointer1, void* pointer2);

  // Checks if the integers are equal
  command void assertEqualsInt(int32_t int1, int32_t int2);
  command void assertEqualsIntMsg(char* message, int32_t int1, int32_t int2);

  // Checks if the integers are equal
  command void assertEqualsUint(uint32_t uint1, uint32_t uint2);
  command void assertEqualsUintMsg(char* message, uint32_t uint1, uint32_t uint2);

  // Checks if the bools are equal
  command void assertEqualsBool(bool bool1, bool bool2);
  command void assertEqualsBoolMsg(char* message, bool bool1, bool bool2);

  // Checks if the doubles are equal
  command void assertEqualsDouble(double double1, double double2);
  command void assertEqualsDoubleMsg(char* message, double double1, double double2);

  // Checks if the floats are equal
  command void assertEqualsFloat(float float1, float float2);
  command void assertEqualsFloatMsg(char* message, float float1, float float2);

  // Checks if the memory regions pointed to by the pointers have the same content
  command void assertEqualsMem(void* pointer1, void* pointer2, uint16_t size);
  command void assertEqualsMemMsg(char* message, void* pointer1, void* pointer2, uint16_t size);

  // Fail the test case
  command void fail();
  command void failMsg(char* message);

  // Execute Java code in the simulator to test assertions
  // timerDelay may contain a timer value in milliseconds if the 
  // check code should be executed after some time (otherwise 0).
  command void assertJavaClass(char* javaClass, uint32_t timerDelay);
  command void assertJavaClassMsg(char* message, char* javaClass, uint32_t timerDelay);

  // Checks if the given function is called during the remainig simulation
  command void assertCalls(char* functionName, char* paramName, volatile void* value, CompOperator op);
  command void assertCallsMsg(char* message, char* functionName, char* paramName, volatile void* value, CompOperator op);

  // Returns a pointer to the given variable.
  // Use "$" as a separator between component and variable name (e.g., AssertM$variable).
  command void* getDataPointer(char* variableName);


}
