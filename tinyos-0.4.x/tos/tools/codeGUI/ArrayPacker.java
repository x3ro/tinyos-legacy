/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Phil Levis
 *
 *
 */

package codeGUI;


public static class ArrayPacker {
    private static boolean isLittleEndian = true;

    public static void setLittleEndian(boolean val) {isLittleEndian = val;}

    
    public static byte getByte(byte[] array, int offset) {
	return array[offset];
    }

    public static short getShort(byte[] array, int offset) {
	short rval;
	if (isLittleEndian) {
	    rval = (array[offset] & 0xff) | ((array[offset + 1] << 8) & 0xff);
	}
	else {
	    rval = (array[offset + 1] & 0xff) | ((array[offset] << 8) & 0xff);
	}
	return rval;
    }
    
    public static int getInt(byte[] array, int offset) {
	int rval;
	if (isLittleEndian) {
	    rval = (array[offset] & 0xff) |
		((array[offset + 1] << 8) & 0xff) |
		((array[offset + 2] << 16) & 0xff) |
		((array[offset + 3] << 24) & 0xff);
	}
	else {
	    rval = (array[offset + 4] & 0xff) |
		((array[offset + 3] << 8) & 0xff) |
		((array[offset + 2] << 16) & 0xff) |
		((array[offset + 1] << 24) & 0xff);
	}
	return rval;
    }

    public static long getLong(byte[] array, int offset) {

    } 
    
    public static void putByte(byte[] array, int offset, byte value) {
	array[offset] = value;
    }

    public static void putShort(byte[] array, int offset, short value) {

    }

    public static void putInt(byte[] array, int offset, int value) {

    }

    public static void putLong(byte[] array, int offset, long value) {

    }
    
    
}
