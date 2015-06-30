package com.rincon.blackbook.bfiledir;

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

public class BFileDirArgParser implements BFileDirEvents {

	/** Transceiver communication with the mote */
	private BFileDir bFileDir;
	
	/**
	 * Constructor
	 * @param args
	 */
	public BFileDirArgParser(String[] args) {
		bFileDir = new BFileDir();
		bFileDir.addListener(this);
		
		if(args.length < 1) {
			reportError("Not enough arguments");
		}
		
		if(args[0].toLowerCase().matches("-gettotalfiles")) {
			System.out.println(bFileDir.getTotalFiles() + " total files");
			System.exit(0);
			
		} else if(args[0].toLowerCase().matches("-gettotalnodes")) {
			System.out.println(bFileDir.getTotalNodes() + " total nodes");
			System.exit(0);
			
		} else if(args[0].toLowerCase().matches("-checkexists")) {
			if (args.length > 1) {
				bFileDir.checkExists(args[1]);
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-readfirst")) {
			bFileDir.readFirst();
			
		} else if(args[0].toLowerCase().matches("-readnext")) {
			if (args.length > 1) {
				bFileDir.readNext(args[1]);
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-getreservedlength")) {
			if (args.length > 1) {
				System.out.println(bFileDir.getReservedLength(args[1]) + " bytes reserved");
				System.exit(0);
				
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-getdatalength")) {
			if (args.length > 1) {
				System.out.println(bFileDir.getDataLength(args[1]) + " bytes");
				System.exit(0);
				
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-checkcorruption")) {
			if (args.length > 1) {
				bFileDir.checkCorruption(args[1]);
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-getfreespace")) {
			System.out.println(bFileDir.getFreeSpace() + " bytes available");
			System.exit(0);
			
		} else {
			System.err.println("Unknown argument: " + args[0]);
			System.err.println(getUsage());
			System.exit(1);
		}
	}
	
	private void reportError(String error) {
		System.err.println(error);
		System.err.println(getUsage());
		System.exit(1);
	}
	
	public static String getUsage() {
		String usage = "";
		usage += "  BFileDir\n";
		usage += "\t-getTotalFiles\n";
		usage += "\t-getTotalNodes\n";
		usage += "\t-getFreeSpace\n";
		usage += "\t-checkExists <filename>\n";
		usage += "\t-readFirst\n";
		usage += "\t-readNext <current filename>\n";
		usage += "\t-getReservedLength <filename>\n";
		usage += "\t-getDataLength <filename>\n";
		usage += "\t-checkCorruption <filename>\n";
		return usage;
	}
	

	/***************** BFileDir Events ****************/
	public void corruptionCheckDone(boolean isCorrupt, boolean result) {
		System.out.print("BFileDir corruption check ");
		
		if(result) {
			System.out.print("SUCCESS: ");
			if(isCorrupt) {
				System.out.println("Corrupted!");
			} else {
				System.out.println("File OK");
			}
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void existsCheckDone(boolean doesExist, boolean result) {
		System.out.print("BFileDir exists check ");
		if(result) {
			System.out.print("SUCCESS: ");
			if(doesExist) {
				System.out.println("File Exists");
			} else {
				System.out.println("File does not exist");
			}
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void nextFile(String fileName, boolean result) {
		System.out.print("BFileDir next file ");
		if(result) {
			System.out.println("SUCCESS: " + fileName);
		} else {
			System.out.println("FAIL: No next file");
		}
		System.exit(0);
	}
}