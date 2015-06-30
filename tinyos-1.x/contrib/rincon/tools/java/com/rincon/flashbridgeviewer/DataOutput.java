package com.rincon.flashbridgeviewer;

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

import java.io.File;
import java.util.Arrays;


public class DataOutput {

	/** True if we save to a file, False if we print to screen */
	private boolean toFile = false;

	/** File to dump the image to */
	private File outFile;

	/** The index we're writing to the screen */
	private int screenIndex = 0;

	/** Characters get printed at the end of every row */
	private char[] characterView = new char[0x16];

	/** Keep track of multi-messaged debug numbers */
	private boolean numberNext = false;

	/** Keep track of multi-messaged hex debug number formatting */
	private boolean hex = false;

	/**
	 * Method to output data either to the screen in a nice format, or to a
	 * binary file
	 * 
	 * @param data
	 * @param
	 */
	public void output(short[] data, int length) {
		// Print nicely to the screen
		for (int i = 0; i < length; i++) {
			characterView[screenIndex] = (char) data[i];

			// Here's where we do our formatting
			if (screenIndex == 8) {
				// New 8-bit column space
				System.out.print("  ");
			}

			if (screenIndex > 15) { // used to be 15
				// Print out the character view and start a new line
				dumpCharacters();
				System.out.println();
				screenIndex = 0;
			}

			if (Integer.toHexString(data[i]).length() < 2) {
				// Numbers 0-F only prints 1 character instead of 2.
				System.out.print("0");
			}
			System.out.print(Integer.toHexString(data[i]).toUpperCase() + " ");
			screenIndex++;
		}
	}

	private String resultToString(int result) {
		if (result == 0) {
			return "STORAGE_OK";
		} else if (result == 1) {
			return "STORAGE_FAIL";
		} else if (result == 2) {
			return "STORAGE_INVALID_SIGNATURE";
		} else if (result == 3) {
			return "STORAGE_INVALID_CRC";
		}
		return "INVALID RETURN CODE";
	}

	/**
	 * Turn an array of short[]'s to a String
	 * 
	 * @param data
	 * @return
	 */
	private String dataToString(short[] data) {
		String returnString = "";

		for (int i = 0; i < data.length; i++) {
			returnString += (char) data[i];
		}
		return returnString;
	}

	/**
	 * Dump the character representation of the last line to the screen
	 * 
	 */
	private void dumpCharacters() {
		System.out.print("  |  ");
		for (int charIndex = 0; charIndex < characterView.length; charIndex++) {
			if (charIndex == 8) {
				// 8-bit character column space
				System.out.print("  ");
			}
			System.out.print(characterView[charIndex]);
		}
		Arrays.fill(characterView, ' ');
	}

	/**
	 * Flush out the remaining data
	 * 
	 */
	public void flush() {
		// to screen
		for (int i = screenIndex; i < 16; i++) {
			System.out.print("   ");
			if (i == 8) {
				// column
				System.out.print("  ");
			}
		}
		dumpCharacters();
		System.out.println();
	}
}
