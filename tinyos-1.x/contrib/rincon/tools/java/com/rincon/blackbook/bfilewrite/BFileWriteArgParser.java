package com.rincon.blackbook.bfilewrite;

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

import com.rincon.blackbook.Util;
import com.rincon.blackbook.messages.BlackbookConnectMsg;

public class BFileWriteArgParser implements BFileWriteEvents {

	/** Transceiver communication with the mote */
	private BFileWrite bFileWrite;
	
	public BFileWriteArgParser(String[] args) {
		bFileWrite = new BFileWrite();
		bFileWrite.addListener(this);
		
		if(args.length < 1) {
			reportError("Not enough arguments");
		}
		
		if(args[0].toLowerCase().matches("-open")) {
			if (args.length > 2) {
				bFileWrite.open(args[1], Util.parseLong(args[2]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-close")) {
			bFileWrite.close();
			
		} else if(args[0].toLowerCase().matches("-save")) {
			bFileWrite.save();
			
		} else if(args[0].toLowerCase().matches("-append")) {
			// We can append any length of data we want,
			// but since our TOS_Msg can only hold so many bytes,
			// we'll stick with that maximum.  And because we
			// can only type characters into the command line, we'll
			// stick with that too.  Keep in mind, for testing purposes,
			// it would also be easy to have an argument to this command
			// line function to say how many bytes to append.
			if (args.length > 1) {
				int length = args[1].length();
				if(length >= BlackbookConnectMsg.totalSize_data()) {
					length = BlackbookConnectMsg.totalSize_data();
				}
				bFileWrite.append(Util.stringToData(args[1]), length);
				
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-getremaining")) {
			System.out.println(bFileWrite.getRemaining() + " bytes available for writing");
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
		usage += "  BFileWrite\n";
		usage += "\t-open <filename>\n";
		usage += "\t-close\n";
		usage += "\t-save\n";
		usage += "\t-append <written data>\n";
		usage += "\t-getRemaining\n";
		return usage;
	}
	

	/***************** BFileWrite Events ****************/
	public void opened(String fileName, long len, boolean result) {
		System.out.print("BFileWrite opened ");
		if(result) {
			System.out.println("SUCCESS: " + fileName);
			System.out.println("\n" + len + " bytes");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void saved(boolean result) {
		System.out.print("BFileWrite save ");
		if(result) {
			System.out.println("SUCCESS");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void appended(int amountWritten, boolean result) {
		System.out.print("BFileWrite append ");
		
		if(result) {
			System.out.println("SUCCESS: " + amountWritten + " bytes");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}

	public void closed(boolean result) {
		System.out.print("Closed ");
		if(result) {
			System.out.println("SUCCESS");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}
	
}
