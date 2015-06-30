package com.rincon.blackbook.bfileread;

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

import com.rincon.blackbook.DataOutput;
import com.rincon.blackbook.Util;

public class BFileReadArgParser implements BFileReadEvents {

	/** Transceiver communication with the mote */
	private BFileRead bFileRead;
	
	/**
	 * Constructor
	 * @param args
	 */
	public BFileReadArgParser(String[] args) {
		bFileRead = new BFileRead();
		bFileRead.addListener(this);
		
		if(args.length < 1) {
			reportError("Not enough arguments");
		}
		
		if(args[0].toLowerCase().matches("-open")) {
			if (args.length > 1) {
				bFileRead.open(args[1]);
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-close")) {
			bFileRead.close();
			
		} else if(args[0].toLowerCase().matches("-read")) {
			// Keep in mind that a message can only hold so many bytes
			// and the TestBlackbook app on the mote will automatically
			// adjust to the correct size for a reply.
			if (args.length > 1) {
				bFileRead.read(Util.parseShort(args[1]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-seek")) {
			if (args.length > 1) {
				bFileRead.seek(Util.parseLong(args[1]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-skip")) {
			if (args.length > 1) {
				bFileRead.skip(Util.parseInt(args[1]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-getremaining")) {
			System.out.println(bFileRead.getRemaining() + " bytes remaining");
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
		usage += "  BFileRead\n";
		usage += "\t-open <filename>\n";
		usage += "\t-close\n";
		usage += "\t-read <amount>\n";
		usage += "\t-seek <address>\n";
		usage += "\t-skip <amount>\n";
		usage += "\t-getRemaining\n";
		return usage;
	}
	
	
	/***************** BFileRead Events ***************/
	public void opened(String fileName, long amount, boolean result) {
		System.out.print("BFileRead opened ");
		if(result) {
			System.out.println("SUCCESS: " + fileName);
			System.out.println("\t" + amount + " bytes");
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


	public void readDone(short[] dataBuffer, int amount, boolean result) {
		System.out.print("BFileRead readDone ");
		if(result) {
			System.out.println("SUCCESS: " + amount + " bytes read\n");
			DataOutput output = new DataOutput();
			output.output(dataBuffer, amount);
			output.flush();
			
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}

}
