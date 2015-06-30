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

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
import java.util.Set;

import net.tinyos.nesc.dump.NDReader;
import net.tinyos.nesc.dump.xml.Xfunction;
import net.tinyos.nesc.dump.xml.Xinterface;
import net.tinyos.nesc.dump.xml.Xnesc;

import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

public class TestXMLParser {

	public TestXMLParser(InputStream stream) {
		super();
		try {
			new NDReader().parse(new InputSource(stream));
		} catch (IOException e) {
			e.printStackTrace();
		} catch (SAXException e) {
			e.printStackTrace();
		}
	}
	
	public HashMap<String, List<String>> searchTestAttribute() {
		HashMap<String, List<String>> testFunctions = new HashMap<String, List<String>>(); 
		ListIterator functionListIter = Xnesc.functionList.listIterator();
		while (functionListIter.hasNext()) {
			Xfunction currentFunction = (Xfunction) functionListIter.next();
			if (currentFunction.attributeLookup("test") != null) {
				//System.out.println(currentFunction.location.filename);
				List<String> functions = testFunctions.get(currentFunction.location.filename);
				if (functions == null) {
					functions = new LinkedList<String>();
					testFunctions.put(currentFunction.location.filename, functions);
				}
				functions.add(currentFunction.name);
			}
		}
		return testFunctions;
	}
	
	public HashMap<String, Set<String>> searchAssertUses() {
		HashMap<String, Set<String>> assertUses = new HashMap<String, Set<String>>(); 
		ListIterator<Xinterface> interfaceIter = (ListIterator<Xinterface>) Xnesc.interfaceList.listIterator();
		while (interfaceIter.hasNext()) {
			Xinterface currentInterface = interfaceIter.next();
			if ("Assert".equals(currentInterface.instance.parent.qname) && !currentInterface.provided) {
				Set<String> interfaces = assertUses.get(currentInterface.location.filename);
				if (interfaces == null) {
					interfaces = new HashSet<String>();
					assertUses.put(currentInterface.location.filename, interfaces);
				}
				interfaces.add(currentInterface.name);
			}
		}
		return assertUses;
	}
	
}
