package com.rincon.eaveslogger;

/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

/**
 * This application is like Listen, but it logs everything
 * to a file so you can view it later.  good for eavesdropping
 * and debugging networks.
 * 
 * @author David Moss (dmm@rincon.com)
 */
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;

import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PacketSource;
import net.tinyos.util.PrintStreamMessenger;

public class EavesLogger {
	
	/** The output name of the log file */
	private String outFilename = "log.txt";
	
	/** The start time of this application */
	private double startTime;
	
	/** The output log file */
	private File outFile;
	
	/** PrintWriter to write to the log file */
	private PrintWriter out;
	
	/**
	 * Constructor
	 * @param args
	 */
	public EavesLogger(String[] args) {
		System.out.println("Starting EavesLogger <out file>");
		if(args.length > 0) {
			outFilename = args[0];
		}
		outFile = new File(outFilename);
		if(outFile.exists()) {
			System.err.println(outFilename + " already exists! Delete? (Y/N)");
			BufferedReader stdin = new BufferedReader(
		    		new InputStreamReader(System.in));
	    	try {
				String answer = stdin.readLine();
				if(answer.toUpperCase().startsWith("Y")) {
					outFile.delete();
				} else {
					System.exit(1);
				}
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		System.out.println("Saving log file to " + outFile.getAbsolutePath() + "...");
	
		startTime = System.currentTimeMillis();
		
		// Build the packet reader
		PacketSource reader = BuildSource.makePacketSource();
		if (reader == null) {
			System.err.println("Invalid packet source (check your MOTECOM environment variable)");
			System.exit(2);
		}

		try {
			outFile.createNewFile();
			out = new PrintWriter(
			        new BufferedWriter(new FileWriter(outFile)));
			reader.open(PrintStreamMessenger.err);
			
			int i;
			String output;
			for (;;) {
				byte[] packet = reader.readPacket();
				
				output = getElapsedTime() + " : \t";
				for(i = 0; i < packet.length; i++) {
					if(packet[i] >= 0 && packet[i] < 16) {
						output += 0;
					}
					output += Integer.toHexString(packet[i] & 0xFF).toUpperCase() + " ";
				}
				output += "\n";
				out.write(output);
				System.out.print(output);
				out.flush();
				System.out.flush();
			}
		} catch (IOException e) {
			System.err.println("Error on " + reader.getName() + ": " + e);
		} finally {
			out.close();
		}
	}

	/**
	 * Get the elapsed time in milliseconds since the program started
	 * @return "time[ms]"
	 */
	private String getElapsedTime() {
		return (System.currentTimeMillis() - startTime) + "[ms]";
	}
	
	
	/** 
	 * Main method
	 * @param args
	 */
	public static void main(String[] args) {
		new EavesLogger(args);
	}
}
