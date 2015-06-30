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
package ncunit.output;

import java.util.Iterator;

import net.tinyos.nesc.dump.xml.IntegerConstant;
import net.tinyos.nesc.dump.xml.Xfunction;
import net.tinyos.nesc.dump.xml.Xvariable;
import avrora.sim.Simulator;

public class Comparison {
	
	private Simulator simulator;
	
	public Comparison(Simulator simulator) {
		super();
		this.simulator = simulator;
	}
	
	public boolean equalsMem(int address1, int address2, int size) {
		for (int i=0; i<size; i++) {
			if (simulator.getInterpreter().getDataByte(address1 + i) != simulator.getInterpreter().getDataByte(address2 + i)) {
				return false;
			}
		}
		return true;
	}
	
	public boolean equalsParam(Xfunction function, Xvariable param, byte[] compValue) {
		int register = 24;
		Iterator iter = function.parameters.iterator();
		while (iter.hasNext() && (register >= 8)) {
			Xvariable currentParam = (Xvariable) iter.next();
			if (currentParam.equals(param)) {
				if (((IntegerConstant) currentParam.type.size).value > 2) {
					register -= ((IntegerConstant) currentParam.type.size).value - 2;
					if (register % 2 != 0) {
						register--;
					}
				}
				// TODO How to compare values pointed to by pointers? Additional operator?
				if (register >= 8) {
					for (int i=0; i<((IntegerConstant) currentParam.type.size).value; i++) {
						if (compValue[i] != simulator.getInterpreter().getRegisterByte(register + i)) {
							return false;
						}
					}
					return true;
				}
				register -= 2;
			}
			else {
				register -= ((IntegerConstant) currentParam.type.size).value;
				if (register % 2 != 0) {
					register--;
				}
			}
		}
		// TODO remaining parameters on stack
		// param not found or too many parameters
		return false;
	}

	public boolean notEqualsParam(Xfunction function, Xvariable param, byte[] compValue) {
		int register = 24;
		Iterator iter = function.parameters.iterator();
		while (iter.hasNext() && (register >= 8)) {
			Xvariable currentParam = (Xvariable) iter.next();
			if (currentParam.equals(param)) {
				if (((IntegerConstant) currentParam.type.size).value > 2) {
					register -= ((IntegerConstant) currentParam.type.size).value - 2;
					if (register % 2 != 0) {
						register--;
					}
				}
				// TODO How to compare values pointed to by pointers? Additional operator?
				if (register >= 8) {
					boolean foundDifference = false;
					for (int i=0; i<((IntegerConstant) currentParam.type.size).value; i++) {
						if (compValue[i] != simulator.getInterpreter().getRegisterByte(register + i)) {
							foundDifference = true;
						}
					}
					if (foundDifference) {
						return true;
					}
					else {
						return false;
					}
				}
				register -= 2;
			}
			else {
				register -= ((IntegerConstant) currentParam.type.size).value;
				if (register % 2 != 0) {
					register--;
				}
			}
		}
		// TODO remaining parameters on stack
		// param not found or too many parameters
		return false;
	}

}
