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

public class ViewerCommands {

	public static final short CMD_READ = 0;
	public static final short CMD_WRITE = 1; 
	public static final short CMD_ERASE = 2;
	public static final short CMD_FLUSH = 4;
	public static final short CMD_PING = 5;
	public static final short CMD_CRC = 6;
	
	public static final short REPLY_READ = 10;
	public static final short REPLY_WRITE = 11;
	public static final short REPLY_ERASE = 12;
	public static final short REPLY_FLUSH = 14;
	public static final short REPLY_PING = 15;
	public static final short REPLY_CRC = 16;
	
	public static final short REPLY_READ_CALL_FAILED = 20;
	public static final short REPLY_WRITE_CALL_FAILED = 21;
	public static final short REPLY_ERASE_CALL_FAILED = 22;
	public static final short REPLY_FLUSH_CALL_FAILED = 24;
	public static final short REPLY_CRC_CALL_FAILED = 26;
	
	public static final short REPLY_READ_FAILED = 30;
	public static final short REPLY_WRITE_FAILED = 31;
	public static final short REPLY_ERASE_FAILED = 32;
	public static final short REPLY_FLUSH_FAILED = 34;
	public static final short REPLY_CRC_FAILED = 36;
	
}