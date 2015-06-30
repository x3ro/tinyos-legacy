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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import ncunit.parser.NCUnitParser;
import ncunit.parser.ParseException;

public class NCUnit {
	
	private HashMap<String, List<String>> testFunctions = null;
	private HashMap<String, Set<String>> assertUses = null;
	private String currentFileName;
	private int testCaseCounter = 1;
	private HashSet<String> uninlineFunctions = new HashSet<String>();

	public NCUnit() {
		super();
	}
	
	public String generateTestCalls() {
		String result = "";
		result += "#include <avr/pgmspace.h>\n";
		result += "static const prog_uchar _testCaseNumber = 0xff;\n\n";
		result += "command void TestStarter.startTest() {\n";
		result += "call Leds.init();\n";
		result += "  switch (PRG_RDB(&_testCaseNumber)) {\n";
		List<String> functionList = testFunctions.get(currentFileName);
		for (String functionName : functionList) {
			result += "  case "+testCaseCounter+":\n";
			result += "call Leds.greenToggle();\n";
			result += "  signal TestStarter.testCaseStart(\"Test case \\\""+functionName+"\\\": \");\n";
			result += "  "+functionName+"();\n";
			result += "  signal TestStarter.testCaseEnd();\n";
			result += "  break;\n";
			testCaseCounter++;
		}
		result += "  default:";
		result += "call Leds.yellowToggle();\n";
		result += "  }\n";
		result += "}";
		return result;
	}

	public void process(String xmlFile, String outputDir) {
		try {
			TestXMLParser xmlParser = new TestXMLParser(new FileInputStream(xmlFile));
			testFunctions = xmlParser.searchTestAttribute();
			assertUses = xmlParser.searchAssertUses();
			
		    for (String fileName : testFunctions.keySet()) {
		    	currentFileName = fileName;
		    	parseFile(fileName, outputDir, assertUses.get(fileName));
		    }
		    for (String fileName : assertUses.keySet()) {
		    	if (!testFunctions.keySet().contains(fileName)) {
			    	currentFileName = fileName;
			    	parseFile(fileName, outputDir, assertUses.get(fileName));
		    	}
		    }
		    
		    writeTestStarterC(outputDir);
		    writeStartScripts(outputDir);
		    writeUninlineFunctions(outputDir);
			
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			System.exit(-1);
		} catch (ParseException e) {
			e.printStackTrace();
			System.exit(-1);
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(-1);
		}
	}

	private void parseFile(String fileName, String outputDir, Set<String> assertInterfaces) throws ParseException, IOException{
		System.out.println("Parsing file "+fileName);
		NCUnitParser ncParser;
		File file = new File(fileName);
		ncParser = new NCUnitParser(this, new FileInputStream(file), assertInterfaces);
		ncParser.nesCFile().print(new PrintWriter(new FileOutputStream(outputDir+"/"+file.getName())));
		uninlineFunctions.addAll(ncParser.getUninlineFunctions());
	}
	
	private void writeTestStarterC(String outputDir) {
		try {
			PrintWriter writer = new PrintWriter(new FileOutputStream(outputDir+"/TestStarterC.nc"));
			writer.println("configuration TestStarterC {");
			writer.println("  provides interface TestStarter;");
			writer.println("}");
			writer.println("implementation {");
			for (String fileName : testFunctions.keySet()) {
				String componentName = getComponentName(fileName);
				writer.println("  components "+componentName+";");
				writer.println("  TestStarter = "+componentName+";");
			}
			writer.println("}");
			writer.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
	
	private void writeUninlineFunctions(String outputDir) {
		if (uninlineFunctions.isEmpty()) {
			new File(outputDir+"/uninline.txt").delete();
		}
		else {
			try {
				PrintWriter writer = new PrintWriter(outputDir+"/uninline.txt");
				writer.print("-funinline=");
				boolean isFirst = true;
				for (String function : uninlineFunctions) {
					if (!isFirst) {
						writer.print(",");
					}
					else {
						isFirst = false;
					}
					writer.print(function.replaceAll("\\.", "\\\\\\$"));
				}
				writer.println();
				writer.close();
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		}
	}
	
	private String getComponentName(String fileName) {
		String componentName = fileName.substring(0, fileName.lastIndexOf(".nc"));
		if (componentName.indexOf("/") >= 0) {
			componentName = componentName.substring(componentName.lastIndexOf("/")+1);
		}
		if (componentName.indexOf("\\") >= 0) {
			componentName = componentName.substring(componentName.lastIndexOf("\\")+1);
		}
		return componentName;
	}
	
	private void writeStartScripts(String outputDir) {
		int counter = 1;
		for (String moduleName : testFunctions.keySet()) {
			String componentName = getComponentName(moduleName);
			for (int i=0; i<testFunctions.get(moduleName).size(); i++) {
				try {
					PrintWriter writer = new PrintWriter(outputDir+"/testcase"+counter);
					writer.println("#!/bin/bash");
					writer.println("echo \"nCUnit: "+componentName+"."+testFunctions.get(moduleName).get(i)+"\"");
					writer.println("cd "+new File(outputDir).getAbsolutePath().replace('\\', '/'));
					writer.println("if [[ $OS = \"Windows_NT\" ]]");
					writer.println("then");
					writer.println("  NCUNIT_CP=\"`cygpath --windows ${NCUNIT_ROOT}/bin`;`cygpath --windows ${NESC_CP}`;`cygpath --windows ${AVRORA_ROOT}/bin`;${CLASSPATH}\"");
					writer.println("else");
					writer.println("  NCUNIT_CP=\"${NCUNIT_ROOT}/bin:${NESC_CP}:${AVRORA_ROOT}/bin:${CLASSPATH}\"");
					writer.println("fi");
					writer.println("java -cp \"$NCUNIT_CP\" avrora.Main -colors=false -banner=false -platform=mica2 -seconds=100 -monitors=ncunit.avrora.NCUnitMonitor,ncunit.avrora.DebugOutputMonitor -test-component="+componentName+" -test-case="+counter+" -symbol-table=../mica2test/main.st -xml-file=output.xml ../mica2test/main.od");
					writer.close();
				} catch (FileNotFoundException e) {
					e.printStackTrace();
				}
				counter++;
			}
			
		}
		try {
			PrintWriter writer = new PrintWriter(outputDir+"/start_tests");
			writer.println("#!/bin/bash");
			for (int i=1; i<counter; i++) {
				writer.println("bash "+new File(outputDir).getAbsolutePath().replace('\\', '/')+"/testcase"+i+" > testoutput"+i+".out");
			}
			// call result analyzer
			writer.println("if [[ $OS = \"Windows_NT\" ]]");
			writer.println("then");
			writer.println("  NCUNIT_CP=\"`cygpath --windows ${NCUNIT_ROOT}/bin`\"");
			writer.println("else");
			writer.println("  NCUNIT_CP=\"${NCUNIT_ROOT}/bin\"");
			writer.println("fi");
			writer.print("java -cp \"$NCUNIT_CP\" ncunit.output.TestCaseAnalyzer");
			for (int i=1; i<counter; i++) {
				writer.print(" testoutput"+i+".out");
			}
			writer.println();
			writer.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if (args.length != 2) {
			System.out.println("Parameters: xmlFile outputDir");
			System.exit(-1);
		}
		new NCUnit().process(args[0], args[1]);
	}

}
