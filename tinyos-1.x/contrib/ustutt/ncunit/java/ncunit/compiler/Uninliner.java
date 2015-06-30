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
package ncunit.compiler;

import java.io.File;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.Set;
import java.util.StringTokenizer;

public class Uninliner {
	
	private static final String FUNCTIONS_STRING = "funinline=";
	
	class StreamGobbler extends Thread
	{
	    InputStream is;
	    String type;
	    
	    StreamGobbler(InputStream is, String type)
	    {
	        this.is = is;
	        this.type = type;
	    }
	    
	    public void run()
	    {
	        try
	        {
	            InputStreamReader isr = new InputStreamReader(is);
	            BufferedReader br = new BufferedReader(isr);
	            String line=null;
	            while ( (line = br.readLine()) != null) {
					if (type.equals("ERROR")) {
						System.err.println(line);
					}
					else {
						System.out.println(line);    
					}
				}
			} catch (IOException ioe)
				{
	                ioe.printStackTrace();  
				}
	    }
	}
	
	public void process(String[] args) {
		if (args[args.length - 1].endsWith("mica2test/app.c")) {
			HashSet<String> functionNames = new HashSet<String>();
			// process parameters
			for (int i=0; i<args.length; i++) {
				if (functionNames.isEmpty() && (args[i].indexOf(FUNCTIONS_STRING) >= 0)) {
					String functionsString = args[i].substring(args[i].indexOf(FUNCTIONS_STRING) + FUNCTIONS_STRING.length());
					StringTokenizer tokenizer = new StringTokenizer(functionsString, ", ");
					while (tokenizer.hasMoreTokens()) {
						String newFunction = tokenizer.nextToken();
						functionNames.add(newFunction);
						//						System.err.println(newFunction);
					}
					//					System.err.println("Functionnames "+functionNames.size());
					args[i] = "-DUNINLINED";
				}
			}
			if (!functionNames.isEmpty()) {
				copyFile("mica2test/app.c", "mica2test/app.c.uninline");
				processDeclarations("mica2test/app.c.uninline", "mica2test/app.c", functionNames);
			}
		}
		callCompiler(args);
	}
	
	private void copyFile(String inputFile, String outputFile) {
		try {
			BufferedReader reader = new BufferedReader(new FileReader(inputFile));
			PrintWriter writer = new PrintWriter(new FileWriter(outputFile));
			String currentLine = reader.readLine();
			while (currentLine != null) {
				writer.println(currentLine);
				currentLine = reader.readLine();
			}
			writer.close();
			reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void processDeclarations(String inputFile, String outputFile, Set<String> functionNames) {
		try {
			BufferedReader reader = new BufferedReader(new FileReader(inputFile));
			PrintWriter writer = new PrintWriter(new FileWriter(outputFile));
			String currentLine = reader.readLine();
			while (currentLine != null) {
				if (currentLine.indexOf("static") >= 0) {
					for (String functionName : functionNames) {
						if (currentLine.indexOf(functionName) >= 0) {
							String newString = "";
							StringTokenizer tokenizer = new StringTokenizer(currentLine);
							while (tokenizer.hasMoreTokens()) {
								String currentToken = tokenizer.nextToken();
								if (!currentToken.equals("inline")) {
									newString += currentToken+" ";
								}
							}
							int bracketIndex = newString.lastIndexOf("{");
							if (bracketIndex >= 0) {
								newString = " __attribute__((noinline)) "+newString.substring(0, bracketIndex) + " {";
							}
							else {
								int semicolonIndex = newString.lastIndexOf(";");
								if (semicolonIndex >= 0) {
									newString = newString.substring(0, semicolonIndex) + " __attribute((noinline)) ;";
								}
							}
							currentLine = newString;
						}
					}
				}
				writer.println(currentLine);
				currentLine = reader.readLine();
			}
			writer.close();
			reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	private void callCompiler(String[] args) {
		try {
			String[] command = new String[args.length + 1];
			command[0] = "avr-gcc";
			for (int i=0; i<args.length; i++) {
				command[i+1] = args[i];
			}
			Process process = Runtime.getRuntime().exec(command, null, null);
	           // any error message?
            StreamGobbler errorGobbler = new
                StreamGobbler(process.getErrorStream(), "ERROR");            
            
            // any output?
            StreamGobbler outputGobbler = new
                StreamGobbler(process.getInputStream(), "OUTPUT");
                
            // kick them off
            errorGobbler.start();
            outputGobbler.start();
                                    
            // any error???
            int exitVal = process.waitFor();
			errorGobbler.join();
			outputGobbler.join();
            System.exit(exitVal);
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		Uninliner uninliner = new Uninliner();
		uninliner.process(args);
	}

}
