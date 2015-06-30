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
module TestAssertM {

  provides interface StdControl;

  uses interface Assert;
  uses interface Assert as Assert2;
  uses interface StdControl as TestControl;
  uses interface Leds;
}
implementation {

#include "ncunit.h"
#include "AM.h"

  command result_t StdControl.init() {
	uint8_t i = 123;
	debug(DBG_USR1, "You can output arbitrary text similar to TOSSIM: %u", i);
	return SUCCESS;
  }

  command result_t StdControl.start() {
	call TestControl.init();
	return SUCCESS;
  }

  command result_t StdControl.stop() {
	return SUCCESS;
  }

  void testFunction1() @test() {
	uint8_t* varPtr;
	volatile uint16_t bcastAddr = TOS_BCAST_ADDR;

   	call Assert.assertJavaClassMsg("java class", "example.TestJavaAssert", 1000);
	//   	call Assert.failMsg("Failed assertion");
	call Assert.assertCalls("ToTestM.SendMsg.send", "address", &bcastAddr, COMP_EQUALS);
	call Assert.assertCalls("ToTestM.Leds.redToggle", NULL, NULL, COMP_NONE);
	// modify variable to cause previous assert fail
   	varPtr = (uint8_t*) call Assert.getDataPointer("ToTestM.variable");
	*varPtr = 0;

	// call function under test
	call TestControl.start();
  }

  void testFunction2() @test() {
	uint8_t* varPtr;
	volatile uint16_t bcastAddr = TOS_BCAST_ADDR;

   	call Assert.assertJavaClassMsg("java class", "example.TestJavaAssert", 1000);
	//   	call Assert.failMsg("Failed assertion");
	call Assert.assertCalls("ToTestM.SendMsg.send", "address", &bcastAddr, COMP_EQUALS);
	call Assert.assertCalls("ToTestM.Leds.redToggle", NULL, NULL, COMP_NONE);

	// call function under test
	call TestControl.start();
  }

}
