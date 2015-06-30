	package com.rincon.blackbook;

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

import com.rincon.blackbook.bclean.BClean;
import com.rincon.blackbook.bclean.BCleanEvents;
import com.rincon.blackbook.bdictionary.BDictionaryArgParser;
import com.rincon.blackbook.bfiledelete.BFileDeleteArgParser;
import com.rincon.blackbook.bfiledir.BFileDirArgParser;
import com.rincon.blackbook.bfileread.BFileReadArgParser;
import com.rincon.blackbook.bfilewrite.BFileWriteArgParser;
import com.rincon.blackbook.bboot.BBoot;
import com.rincon.blackbook.bboot.BBootEvents;

public class BlackbookConnect implements BBootEvents, BCleanEvents {
	
	/** Boot Transceiver */
	private BBoot bBoot;
	
	/** BClean Transceiver */
	private BClean bClean;
	
	/**
	 * Constructor
	 */
	public BlackbookConnect(String[] args) {
		bBoot = new BBoot();
		bBoot.addListener(this);
		
		bClean = new BClean();
		bClean.addListener(this);
		
		processArguments(args);
	}

	/**
	 * Process the command line arguments and send the
	 * commands to the mote for execution
	 * @param args
	 */
	private void processArguments(String[] args) {
		if(args.length < 1) {
			System.err.println("Not enough arguments!");
			usage();
			System.exit(1);
		}
		
		if(args[0].toLowerCase().matches("bdictionary")) {
			new BDictionaryArgParser(getSubArgs(args));
			
		} else if(args[0].toLowerCase().matches("bfiledelete")) {
			new BFileDeleteArgParser(getSubArgs(args));
			
		} else if(args[0].toLowerCase().matches("bfiledir")) {
			new BFileDirArgParser(getSubArgs(args));
			
		} else if(args[0].toLowerCase().matches("bfileread")) {
			new BFileReadArgParser(getSubArgs(args));
			
		} else if(args[0].toLowerCase().matches("bfilewrite")) {
			new BFileWriteArgParser(getSubArgs(args));
			
		} else {
			System.err.println("Unknown Argument: " + args[0]);
			usage();
			System.exit(1);
		}
	}

	
	/**
	 * Print all argument parsers' command line usage
	 *
	 */
	private void usage() {
		System.out.println("\nBlackbook Usage:");
		System.out.println("com.rincon.blackbook.TestBlackbook [interface] -[command] <params>");
		System.out.println("_____________________________________");
		System.out.println(BDictionaryArgParser.getUsage());
		System.out.println(BFileDeleteArgParser.getUsage());
		System.out.println(BFileDirArgParser.getUsage());
		System.out.println(BFileReadArgParser.getUsage());
		System.out.println(BFileWriteArgParser.getUsage());
	}
	
	/** 
	 * Extract the sub-arguments for a given command
	 * @param args
	 * @return everything but the first index
	 */
	private String[] getSubArgs(String[] args) {
		String[] subArgs = new String[args.length - 1];
		
		for(int i = 0; i < args.length - 1; i++) {
			subArgs[i] = args[i+1];
		}
		
		return subArgs;
	}
	

	/***************** Boot Events ****************/
	/**
	 * Boot Event
	 * This will only occur when the mote is reset while 
	 * the TestBlackbook application is running, which
	 * isn't likely.
	 */
	public void booted(int totalNodes, short totalFiles, boolean result) {
		System.out.print("Blackbook Boot: ");
		if(result) {
			System.out.println("SUCCESS");
		} else {
			System.out.println("FAIL");
		}
		System.out.println("\t" + totalNodes + " nodes; " + totalFiles + " files.");
		System.exit(0);
	}

	
	/***************** BClean Events ****************/
	public void erasing() {
		System.out.println("Erasing Sector... Please wait.");
	}

	public void gcDone(boolean result) {
		System.out.println("Done Erasing Sectors");
	}
	
	/**
	 * Main Method
	 * @param args
	 */
	public static void main(String[] args) {
		new BlackbookConnect(args);
	}


}
