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
package ncunit.avrora;

import avrora.sim.Simulator;

/**
 * Interface to check assertions in the simulator (e.g., specific hardware or
 * simulation state).
 * Calls to assertJavaClass expect a class that implements this interface.
 * 
 * @author lachenas
 *
 */
public interface NCAssert {

	/**
	 * Function that allows for initializations.
	 * Called when the corresponding assertJavaClass call is executed. 
	 * @param simulator the instance of the simulator
	 */
	void init(Simulator simulator);

	/**
	 * First possibility to check assertions.
	 * Called when the corresponding assertJavaClass call is executed.
	 * Should return false only if the assertion has failed.
	 * @return false iff the assert failed 
	 */
	boolean callNow();
	
	/**
	 * Second possibility to check assertions.
	 * Called when the code of the test case function has been completely
	 * executed.
	 * Should return false only if the assertion has failed.
	 * @return false iff the assert failed
	 */
	boolean callAfter();
	
	/**
	 * Third possibility to check assertions.
	 * Called when a time with the timerDelay parameter of assertJavaClass fires. 
	 * Should return false only if the assertion has failed.
	 * @return false iff the assert failed
	 */
	boolean callTimer();
}
