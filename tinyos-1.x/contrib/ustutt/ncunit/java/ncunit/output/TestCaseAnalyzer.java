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

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;

public class TestCaseAnalyzer {
	
	public void analyze(String[] fileNames) {
		int successCounter = 0;
		int failCounter = 0;
		for (String file : fileNames) {
			if (isSuccessful(file)) {
				successCounter++;
			}
			else {
				failCounter++;
			}
		}
		System.out.println("===============================================");
		System.out.println("Test cases: "+(successCounter+failCounter));
		System.out.println("Successful: "+successCounter);
		System.out.println("Failed:     "+failCounter);
	}
	
	private boolean isSuccessful(String fileName) {
		try {
			BufferedReader reader = new BufferedReader(new FileReader(fileName));
			String currentLine = reader.readLine();
			if ((currentLine != null) && (currentLine.indexOf("nCUnit:") >= 0)) {
				// first line has to start with name of function
				String testFunction = currentLine.substring(currentLine.indexOf(':')+1).trim();
				currentLine = reader.readLine();
				while (currentLine != null) {
					if (currentLine.indexOf("nCUnit: Completed test case successfully") >= 0) {
						reader.close();
						System.out.println(fileName+": Successfully executed "+testFunction);
						return true;
					}
					else if (currentLine.indexOf("nCUnit: Assertion failed during test case") >= 0) {
						reader.close();
						System.out.println(fileName+": Assertion failed in "+testFunction);
						return false;
					}
					currentLine = reader.readLine();
				}
			}
			reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		// unreachable if correct file processed
		return false;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length == 0) {
			System.err.println("Parameters: name of test case output files");
			System.exit(1);
		}
		new TestCaseAnalyzer().analyze(args);
	}

}
