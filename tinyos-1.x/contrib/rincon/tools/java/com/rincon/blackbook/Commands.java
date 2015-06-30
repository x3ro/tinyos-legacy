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

public class Commands {


	public static final int TOS_BCAST_ADDR = 0xFFFF;
	public static final short SUCCESS = 1;
	public static final short FAIL = 0;
	
	
	public static final short CMD_BFILEWRITE_OPEN = 0;

	public static final short CMD_BFILEWRITE_CLOSE = 1;
	public static final short CMD_BFILEWRITE_APPEND = 2;
	public static final short CMD_BFILEWRITE_SAVE = 3;
	public static final short CMD_BFILEWRITE_REMAINING = 4;
	 
	public static final short CMD_BFILEREAD_OPEN = 10;
	public static final short CMD_BFILEREAD_CLOSE = 11;
	public static final short CMD_BFILEREAD_READ = 12;
	public static final short CMD_BFILEREAD_SEEK = 13;
	public static final short CMD_BFILEREAD_SKIP = 14;
	public static final short CMD_BFILEREAD_REMAINING = 15;
	 
	public static final short CMD_BFILEDELETE_DELETE = 20;
	 
	public static final short CMD_BFILEDIR_TOTALFILES = 30;
	public static final short CMD_BFILEDIR_TOTALNODES = 31;
	public static final short CMD_BFILEDIR_EXISTS = 32;
	public static final short CMD_BFILEDIR_READNEXT = 33;
	public static final short CMD_BFILEDIR_RESERVEDLENGTH = 34;
	public static final short CMD_BFILEDIR_DATALENGTH = 35;
	public static final short CMD_BFILEDIR_CHECKCORRUPTION = 36;
	public static final short CMD_BFILEDIR_READFIRST = 37;
	public static final short CMD_BFILEDIR_GETFREESPACE = 38;
	
	public static final short CMD_BDICTIONARY_OPEN = 40;
	public static final short CMD_BDICTIONARY_CLOSE = 41;
	public static final short CMD_BDICTIONARY_INSERT = 42;
	public static final short CMD_BDICTIONARY_RETRIEVE = 43;
	public static final short CMD_BDICTIONARY_REMOVE = 44; 
	public static final short CMD_BDICTIONARY_NEXTKEY = 45;
	public static final short CMD_BDICTIONARY_FIRSTKEY = 46;
	public static final short CMD_BDICTIONARY_ISDICTIONARY = 47;
	
	public static final short ERROR_BFILEWRITE_OPEN = 100;
	public static final short ERROR_BFILEWRITE_CLOSE = 101;
	public static final short ERROR_BFILEWRITE_APPEND = 102;
	public static final short ERROR_BFILEWRITE_SAVE = 103;
	public static final short ERROR_BFILEWRITE_REMAINING = 104;
	 
	public static final short ERROR_BFILEREAD_OPEN = 110;
	public static final short ERROR_BFILEREAD_CLOSE = 111;
	public static final short ERROR_BFILEREAD_READ = 112;
	public static final short ERROR_BFILEREAD_SEEK = 113;
	public static final short ERROR_BFILEREAD_SKIP = 114;
	public static final short ERROR_BFILEREAD_REMAINING = 115;
	 
	public static final short ERROR_BFILEDELETE_DELETE = 120;
	 
	public static final short ERROR_BFILEDIR_TOTALFILES = 130;
	public static final short ERROR_BFILEDIR_TOTALNODES = 131;
	public static final short ERROR_BFILEDIR_EXISTS = 132;
	public static final short ERROR_BFILEDIR_READNEXT = 133;
	public static final short ERROR_BFILEDIR_RESERVEDLENGTH = 134;
	public static final short ERROR_BFILEDIR_DATALENGTH = 135;
	public static final short ERROR_BFILEDIR_CHECKCORRUPTION = 136;
	public static final short ERROR_BFILEDIR_READFIRST = 137;
	public static final short ERROR_BFILEDIR_GETFREESPACE = 138;
	
	public static final short ERROR_BDICTIONARY_OPEN = 140;
	public static final short ERROR_BDICTIONARY_CLOSE = 141;
	public static final short ERROR_BDICTIONARY_INSERT = 142;
	public static final short ERROR_BDICTIONARY_RETRIEVE = 143;
	public static final short ERROR_BDICTIONARY_REMOVE = 144;
	public static final short ERROR_BDICTIONARY_NEXTKEY = 145;
	public static final short ERROR_BDICTIONARY_FIRSTKEY = 146;
	public static final short ERROR_BDICTIONARY_ISDICTIONARY = 147;
	
	public static final short REPLY_BFILEWRITE_OPEN = 200;
	public static final short REPLY_BFILEWRITE_CLOSE = 201;
	public static final short REPLY_BFILEWRITE_APPEND = 202;
	public static final short REPLY_BFILEWRITE_SAVE = 203;
	public static final short REPLY_BFILEWRITE_REMAINING = 204;
	 
	public static final short REPLY_BFILEREAD_OPEN = 210;
	public static final short REPLY_BFILEREAD_CLOSE = 211;
	public static final short REPLY_BFILEREAD_READ = 212;
	public static final short REPLY_BFILEREAD_SEEK = 213;
	public static final short REPLY_BFILEREAD_SKIP = 214;
	public static final short REPLY_BFILEREAD_REMAINING = 215;
	 
	public static final short REPLY_BFILEDELETE_DELETE = 220;
	 
	public static final short REPLY_BFILEDIR_TOTALFILES = 230;
	public static final short REPLY_BFILEDIR_TOTALNODES = 231;
	public static final short REPLY_BFILEDIR_EXISTS = 232;
	public static final short REPLY_BFILEDIR_READNEXT = 233;
	public static final short REPLY_BFILEDIR_RESERVEDLENGTH = 234;
	public static final short REPLY_BFILEDIR_DATALENGTH = 235;
	public static final short REPLY_BFILEDIR_CHECKCORRUPTION = 236;
	public static final short REPLY_BFILEDIR_GETFREESPACE = 238;
	
	public static final short REPLY_BDICTIONARY_OPEN = 240;
	public static final short REPLY_BDICTIONARY_CLOSE = 241;
	public static final short REPLY_BDICTIONARY_INSERT = 242;
	public static final short REPLY_BDICTIONARY_RETRIEVE = 243;
	public static final short REPLY_BDICTIONARY_REMOVE = 244;
	public static final short REPLY_BDICTIONARY_NEXTKEY = 245;
	public static final short REPLY_BDICTIONARY_FIRSTKEY = 246;
	public static final short REPLY_BDICTIONARY_ISDICTIONARY = 247;
	
	public static final short REPLY_BOOT = 250;
	public static final short REPLY_BCLEAN_ERASING = 251;
	public static final short REPLY_BCLEAN_DONE = 252;
}
