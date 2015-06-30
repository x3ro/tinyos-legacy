package com.rincon.blackbook.bdictionary;

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
import com.rincon.blackbook.messages.BlackbookConnectMsg;

public class BDictionaryArgParser implements BDictionaryEvents {

	/** Transceiver communication with the mote */
	private BDictionary bDictionary;
	
	/**
	 * Constructor
	 * @param args
	 */
	public BDictionaryArgParser(String[] args) {
		bDictionary = new BDictionary();
		bDictionary.addListener(this);
		
		if(args.length < 1) {
			reportError("Not enough arguments");
		}
		
		if(args[0].toLowerCase().matches("-open")) {
			if (args.length > 2) {
				bDictionary.open(args[1], Util.parseInt(args[2]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-close")) {
			bDictionary.close();
			
		} else if(args[0].toLowerCase().matches("-insert")) {
			if (args.length > 3) {
				if(Util.parseShort(args[3]) > BlackbookConnectMsg.totalSize_data()) {
					reportError("Cannot fit value size + " + Util.parseShort(args[3]) + " into a single UART message with data size " + BlackbookConnectMsg.totalSize_data());
				}
				bDictionary.insert(Util.parseLong(args[1]), Util.stringToData(args[2]), Util.parseShort(args[3]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-retrieve")) {
			if(args.length > 1) {
				bDictionary.retrieve(Util.parseLong(args[1]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-remove")) {
			if(args.length > 1) {
				bDictionary.remove(Util.parseLong(args[1]));
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else if(args[0].toLowerCase().matches("-getfirstkey")) {
			bDictionary.getFirstKey();
			
		} else if(args[0].toLowerCase().matches("-getnextkey")) {
			if(args.length > 1) {
				bDictionary.getNextKey(Util.parseLong(args[1]));
			} else {
				reportError("Missing parameter(s)");
			}
	
		} else if(args[0].toLowerCase().matches("-isdictionary")) {
			if(args.length > 1) {
				bDictionary.isFileDictionary(args[1]);
			} else {
				reportError("Missing parameter(s)");
			}
			
		} else {
			reportError("Unknown argument: " + args[0]);
		}
	}
	
	private void reportError(String error) {
		System.err.println(error);
		System.err.println(getUsage());
		System.exit(1);
	}
	
	
	public static String getUsage() {
		String usage = "";
		usage += "  BDictionary\n";
		usage += "\t-open <filename> <minimum size>\n";
		usage += "\t-close\n";
		usage += "\t-insert <key> <value> <length>\n";
		usage += "\t-retrieve <key>\n";
		usage += "\t-remove <key>\n";
		usage += "\t-getFirstKey\n";
		usage += "\t-getNextKey <current key>\n";
		usage += "\t-isDictionary <filename>\n";
		return usage;
	}
	
	

	/***************** BDictionary Events ****************/
	public void opened(int totalSize, boolean result) {
		System.out.print("BDictionary opened ");
		if(result) {
			System.out.println("SUCCESS: " + totalSize + " bytes");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void inserted(long key, boolean result) {
		System.out.print("BDictionary inserted ");
		if(result) {
			System.out.println("SUCCESS: Key 0x" + Long.toHexString(key).toUpperCase() + " Inserted");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void retrieved(short[] valueHolder, int valueSize, boolean result) {
		System.out.print("BDictionary retrieved ");
		if(result) {
			System.out.println("SUCCESS");
			DataOutput output = new DataOutput();
			output.output(valueHolder, valueSize);
			output.flush();

		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
		
	}


	public void removed(long key, boolean result) {
		System.out.print("BDictionary removed ");
		if(result) {
			System.out.println("SUCCESS: Key 0x" + Long.toHexString(key).toUpperCase() + " Removed");
		} else {
			System.out.println("FAIL");
		}
		System.exit(0);
	}


	public void nextKey(long nextKey, boolean result) {
		System.out.print("BDictionary next key ");
		if(result) {
			System.out.println("SUCCESS: Next Key is 0x" + Long.toHexString(nextKey).toUpperCase());
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

	public void fileIsDictionary(boolean isDictionary, boolean result) {
		System.out.print("BDictionary fileIsDictionary ");
		if(result) {
			System.out.print("SUCCESS: File ");
			if(isDictionary) {
				System.out.print("is");
			} else {
				System.out.print("is NOT");
			}
			System.out.println(" a dictionary file.");
		} else {
			System.out.println("FAIL");
		}
		
		System.exit(0);
	}

}
