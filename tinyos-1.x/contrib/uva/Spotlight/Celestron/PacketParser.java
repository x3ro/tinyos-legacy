//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/PacketParser.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Tian He, Radu Stoleru
// Date: 3/26/2005

public class PacketParser {
	
	// get the unsigned int value from the byte at certain offset
	static public int OneByte(byte[] packet, int offset) {
		int p = (int) packet[offset];
		return ( (p >= 0) ? p : (p + 256));
	}
	
	// get the unsigned int value from two bytes at certain offset
	static public int TwoBytes(byte[] packet, int offset) {
		int p0 = (int) packet[offset];
		int p1 = (int) packet[offset + 1];
		p0 = (p0 >= 0) ? p0 : (p0 + 256);
		p1 = (p1 >= 0) ? p1 : (p1 + 256);
		return (p0 + p1 * 256);
	}
	
	// get the signed int value from two bytes at certain offset
	static public int SignedTwoBytes(byte[] packet, int offset) {
		int p0 = (int) packet[offset];
		int p1 = (int) packet[offset + 1];
		p0 = (p0 >= 0) ? p0 : (p0 + 256);
		// p1 = (p1 >= 0) ? p1 : (p1 + 256);
		return (p0 + p1 * 256);
	}
	
	// get the unsigned int value from four bytes at certain offset
	static public long FourBytes(byte[] packet, int offset) {
		int p0 = (int) packet[offset];
		int p1 = (int) packet[offset + 1];
		int p2 = (int) packet[offset + 2];
		int p3 = (int) packet[offset + 3];
		p0 = (p0 >= 0) ? p0 : (p0 + 256);
		p1 = (p1 >= 0) ? p1 : (p1 + 256);
		p2 = (p2 >= 0) ? p2 : (p2 + 256);
		p3 = (p3 >= 0) ? p3 : (p3 + 256);
		int lower = p0 + p1 * 256 + p2 * 65536;
		long result = (long) lower + ( (long) p3) * 16777216L;
		return result;
	}
	
	// get the first character of a hex string
	static public String PrintHexByte1(byte b) {
		int i = (int) b;
		i = (i >= 0) ? i : (i + 256);
		return Integer.toHexString(i / 16);
	}
	
	// get the second character of a hex string
	static public String PrintHexByte2(byte b) {
		int i = (int) b;
		i = (i >= 0) ? i : (i + 256);
		return Integer.toHexString(i % 16);
	}
	
	// print a byte value in Hex
	static public void PrintHexByte(byte b) {
		int i = (int) b;
		i = (i >= 0) ? i : (i + 256);
		System.out.print(Integer.toHexString(i / 16));
		System.out.print(Integer.toHexString(i % 16));
	}	
	
}
