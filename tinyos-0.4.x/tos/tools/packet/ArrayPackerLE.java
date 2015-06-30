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
 * Date:                17.viii.2001
 *
 * The ArrayPackerLE (Little-Endian) is a simple utility class for packing
 * and unpacking little endian byte packets. All of its put functions take
 * three parameters: the byte array to be modified, the offset into the
 * array that the value is to be placed at, and the value. All of the get
 * methods take two parameters, the array and the offset into the array.
 */

package packet;


public class ArrayPackerLE {

    public static byte getByte(byte[] array, int offset) {
	return array[offset];
    }

    public static short getShort(byte[] array, int offset) {
	short rval;
	rval = (short)(array[offset] & 0xff);
	rval |= (short)((array[offset + 1] & 0xff) << 8);
	return rval;
    }
    
    public static int getInt(byte[] array, int offset) {
	int rval = (array[offset] & 0xff) |
	    ((array[offset + 1] & 0xff) << 8) |
	    ((array[offset + 2] & 0xff) << 16) |
	    ((array[offset + 3] & 0xff) << 24 );
	return rval;
    }

    public static long getLong(byte[] array, int offset) {
	long rval = 0;
	long tval = 0;

	tval = (long)(array[offset] & 0xff);
	rval |= tval;

	tval = (long)(array[offset + 1] & 0xff);
	tval = tval << 8;
	rval |= tval;

	tval = (long)(array[offset + 2] & 0xff);
	tval = tval << 16;
	rval |= tval;

	tval = (long)(array[offset + 3] & 0xff);
	tval = tval << 24;
	rval |= tval;

	tval = (long)(array[offset + 4] & 0xff);
	tval = tval << 32;
	rval |= tval;

	tval = (long)(array[offset + 5] & 0xff);
	tval = tval << 40;
	rval |= tval;

	
	tval = (long)(array[offset + 6] & 0xff);
	tval = tval << 48;
	rval |= tval;

	tval = (long)(array[offset + 7] & 0xff);
	tval = tval << 56;
	rval |= tval;

	return rval;
    } 
    
    public static void putByte(byte[] array, int offset, byte value) {
	array[offset] = value;
    }

    public static void putShort(byte[] array, int offset, short value) {
	array[offset] = (byte)(value & 0xff);
	array[offset + 1] = (byte)((value >> 8) & 0xff);
    }

    public static void putInt(byte[] array, int offset, int value) {
	array[offset] = (byte)(value & 0xff);
	array[offset + 1] = (byte)((value >> 8) & 0xff);
	array[offset + 2] = (byte)((value >> 16) & 0xff);
	array[offset + 3] = (byte)((value >> 24) & 0xff);
    }

    public static void putLong(byte[] array, int offset, long value) {
	array[offset] = (byte)(value & 0xff);
	array[offset + 1] = (byte)((value >> 8) & 0xff);
	array[offset + 2] = (byte)((value >> 16) & 0xff);
	array[offset + 3] = (byte)((value >> 24) & 0xff);
	array[offset + 4] = (byte)((value >> 32) & 0xff);
	array[offset + 5] = (byte)((value >> 40) & 0xff);
	array[offset + 6] = (byte)((value >> 48) & 0xff);
	array[offset + 7] = (byte)((value >> 56) & 0xff);
    }
    
    
}
