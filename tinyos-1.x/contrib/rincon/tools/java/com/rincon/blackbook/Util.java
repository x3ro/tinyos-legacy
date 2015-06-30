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

public class Util {

	
	/**
	 * Turn an array of short[]'s to a String
	 * 
	 * @param data
	 * @return
	 */
	public static String dataToString(short[] data) {
		String returnString = "";

		for (int i = 0; i < data.length; i++) {
			returnString += (char) data[i];
		}
		return returnString;
	}

	/**
	 * Turn a string into a short[] array of data
	 * @param string
	 * @return
	 */
	public static short[] stringToData(String string) {
		char[] charData = string.toCharArray();
		short[] returnData = new short[charData.length];
		
		
		for(int i = 0; i < charData.length; i++) {
			returnData[i] = (short) charData[i];
		}
		
		return returnData;
	}
	
	/**
	 * Attempt to decode the int value, and deal with any illegible remarks.
	 * 
	 * @param intString
	 * @return
	 */
	public static int parseInt(String intString) {
		try {
			return Integer.decode(intString).intValue();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}
		return 0;
	}

	/**
	 * Attempt to decode the long value, and deal with any illegible remarks.
	 * 
	 * @param longString
	 * @return
	 */
	public static long parseLong(String longString) {
		try {			
			return Long.decode(longString).longValue();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}

		return 0;
	}

	/**
	 * Attempt to decode the short value, and deal with any illegible remarks.
	 * 
	 * @param shortString
	 * @return
	 */
	public static short parseShort(String shortString) {
		try {			
			return Short.decode(shortString).shortValue();
		} catch (NumberFormatException e) {
			e.printStackTrace();
		}

		return 0;
	}
	
	/**
	 * Convert some data to a filename
	 * @param data
	 * @return
	 */
	public static String dataToFilename(short[] data) {
		String returnString = "";
		
		for(int i = 0; i < 14; i++) {
			returnString += (char) data[i];
		}
		return returnString;
	}

	/**
	 * Takes a filename string and converts it to a 14 element
	 * filename short array
	 * @param s
	 * @return
	 */
	public static short[] filenameToData(String filename) {
		int filenameLength = 14;
		short[] returnData = new short[filenameLength];
		char[] charData = filename.toCharArray();
		
		for(int i = 0; i < charData.length && i < filenameLength; i++) {
			returnData[i] = (short) charData[i];
		}
		
		for(int i = charData.length; i < filenameLength; i++) {
			returnData[i] = 0;
		}
		
		return returnData;
	}

	
	/**
	 * Turn an array of shorts into an array of bytes
	 * @param shortData
	 * @return
	 */
	public static byte[] shortsToBytes(short[] shortData, int length) {
		byte[] byteData = new byte[length];
		for(int i = 0; i < length; i++) {
			byteData[i] = (byte) shortData[i];
		}
		
		return byteData;
	}
	

	/**
	 * Convert a byte array to short array.
	 * @param byteData
	 * @return
	 */
	public static short[] bytesToShorts(byte[] byteData) {
		short[] shortData = new short[byteData.length];
		for(int i = 0; i < byteData.length; i++) {
			shortData[i] = (short) byteData[i];
		}
		
		return shortData;
	}

}
