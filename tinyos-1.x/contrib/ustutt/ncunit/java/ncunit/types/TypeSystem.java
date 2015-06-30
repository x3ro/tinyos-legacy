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
package ncunit.types;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ListIterator;

import net.tinyos.nesc.dump.NDReader;
import net.tinyos.nesc.dump.xml.Xfunction;
import net.tinyos.nesc.dump.xml.Xinterface;
import net.tinyos.nesc.dump.xml.Xnesc;
import net.tinyos.nesc.dump.xml.Xvariable;

import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

public class TypeSystem {

	public TypeSystem(String xmlFile) {
		super();
		try {
			new NDReader().parse(new InputSource(new FileInputStream(xmlFile)));
		} catch (IOException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		}
	}
	
	public Xfunction getFunctionType(String moduleFunctionName) {
		Xfunction result = null;
		if (moduleFunctionName.indexOf("$") < 0) {
			ListIterator functionIter = Xnesc.functionList.listIterator();
			while (functionIter.hasNext()) {
				Xfunction currentFunction = (Xfunction) functionIter.next();
				if (currentFunction.name.equals(moduleFunctionName)) {
					result = currentFunction;
				}
			}
		}
		else {
			String moduleName = moduleFunctionName.substring(0, moduleFunctionName.indexOf("$"));
			String interfaceName = moduleFunctionName.substring(moduleName.length() + 1);
			if (interfaceName.indexOf("$") >= 0) {
				interfaceName = interfaceName.substring(0, interfaceName.indexOf("$"));
			}
			else {
				interfaceName = null;
			}
			String functionName = moduleFunctionName.substring(moduleFunctionName.lastIndexOf("$") + 1);
			if (interfaceName == null) {
				System.err.println("Unexpected missing interface: "+moduleFunctionName);
			}
			else {
				//System.out.println(moduleName+" "+interfaceName+" "+functionName);
				ListIterator intfcIter = Xnesc.interfaceList.listIterator();
				while (intfcIter.hasNext()) {
					Xinterface intfc = (Xinterface) intfcIter.next();
					if (intfc.container.toString().equals(moduleName) && intfc.name.equals(interfaceName)) {
						ListIterator funcIter = intfc.functions.listIterator();
						while (funcIter.hasNext()) {
							Xfunction func = (Xfunction) funcIter.next();
							if (func.name.equals(functionName)) {
								result = func;
								break;
							}
						}
						break;
					}
				}
			}
		}
		return result;
	}
	
	public Xvariable getParameterType(Xfunction function, String paramName) {
		ListIterator iter = function.parameters.listIterator();
		while (iter.hasNext()) {
			Xvariable param = (Xvariable) iter.next();
			if (param.name.equals(paramName)) {
				return param;
			}
		}
		return null;
	}

}
