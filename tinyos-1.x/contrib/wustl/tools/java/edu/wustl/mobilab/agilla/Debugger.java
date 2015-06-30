// $Id: Debugger.java,v 1.4 2006/11/15 00:22:34 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis
 * By Chien-Liang Fok.
 *
 * Washington University states that Agilla is free software;
 * you can redistribute it and/or modify it under the terms of
 * the current version of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * Agilla is distributed in the hope that it will be useful, but
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS",
 * OR OTHER HARMFUL CODE.
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to
 * indemnify, defend, and hold harmless WU, its employees, officers and
 * agents from any and all claims, costs, or liabilities, including
 * attorneys fees and court costs at both the trial and appellate levels
 * for any loss, damage, or injury caused by your actions or actions of
 * your officers, servants, agents or third parties acting on behalf or
 * under authorization from you, as a result of using Agilla.
 *
 * See the GNU Lesser General Public License for more details, which can
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */
/**
 * Debugger.java
 *
 * @author Chien-Liang Fok
 */

package edu.wustl.mobilab.agilla;

import java.util.Date;

public class Debugger {
	// Specifies the various levels of debug messages.
	public static final int ERROR = 0;
	public static final int STATUS = 1;
	public static final int DEBUG = 2;
	
	public static boolean debug = false;
	public static boolean printAllMsgs = false;
	public static boolean printBeacons = false;
	
	/**
	 * Controls how many debug statements are printed out.
	 * 0 - error messages (always print)
	 * 1 - status messages
	 * 2 - debug messages
	 */
	public static int debugLevel = 0;
	//public static boolean printLocal = false;
	
	public static void dbg(String header, String msg) {
		if (debug) {
			dbg(header, msg, Debugger.ERROR);
		}
	}
	
	public static void dbg(String header, String msg, int level) {
		if (level <= debugLevel) {
			System.out.println("[" + new Date().getTime() + "] " + header + ": " + msg);
			System.out.flush();
		}
	}
	
	public static void dbgErr(String header, String msg) {
		dbgErr(header, msg, Debugger.ERROR);
	}
	
	public static void dbgErr(String header, String msg, int level) {
		if (level <= debugLevel) {
			System.err.println("[" + new Date().getTime() + "] " + header + ": " + msg);
			System.err.flush();
		}		
	}
	
	/*public static void print(String header, String msg) {
		if (printLocal) System.out.println(header + ": " + msg);
	 }*/
	
	public static void warn(String header, String msg) {
		System.out.println("WARNING: " + header + ": " + msg);
	}
}

