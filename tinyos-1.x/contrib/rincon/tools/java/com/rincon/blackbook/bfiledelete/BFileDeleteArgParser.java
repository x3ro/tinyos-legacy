package com.rincon.blackbook.bfiledelete;

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

public class BFileDeleteArgParser implements BFileDeleteEvents {

	/** BFileDelete Transceiver */
	private BFileDelete bFileDelete;
	
	/**
	 * Constructor
	 * @param args
	 */
	public BFileDeleteArgParser(String[] args) {
		bFileDelete = new BFileDelete();
		bFileDelete.addListener(this);
		
		if(args.length < 1) {
			reportError("Not enough arguments");
		}
		
		if(args[0].toLowerCase().matches("-delete")) {
			if (args.length > 1) {
				bFileDelete.delete(args[1]);
			} else {
				reportError("Missing parameter(s)");
			}
			
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
		usage += "  BFileDelete\n";
		usage += "\t-delete <filename>\n";
		return usage;
	}


	/***************** BFileDelete Events ****************/
	public void deleted(boolean result) {
		System.out.print("BFileDelete delete ");
		if(result) {
			System.out.println("SUCCESS");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}
}