// $Id: DelugeImage.java,v 1.1 2005/07/22 17:52:37 jwhui Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

package net.tinyos.deluge;

public class DelugeImage {

  private static final int MAX_SIZE = 1024*512;
  
  private short image[] = new short[MAX_SIZE];
  private short numPages;
  private int byteCount;
  private int size;
  
  private short crcByte(short crc, byte b) {
    int i;
    
    crc = (short)(crc ^ b << 8);
    i = 8;
    do {
      if ((crc & 0x8000) != 0)
	crc = (short)(crc << 1 ^ 0x1021);
      else
	crc = (short)(crc << 1);
    } while (--i > 0);
    
    return crc;
  }

  public DelugeImage(byte[] tmpBytes, int length) {

    short bytes[] = new short[length];

    size = 2*DelugeConsts.DELUGE_MAX_PAGES;

    for ( int i = 0; i < length; i++ ) 
      bytes[i] = (short)(tmpBytes[i] & 0xff);

    short crc = 0;
    for ( int i = 0; i < length; i++ ) {
      if ((size % DelugeConsts.DELUGE_BYTES_PER_PAGE) == 0) {
	int offset = 2*((size-1)/DelugeConsts.DELUGE_BYTES_PER_PAGE);
	image[offset+0] = (short)((crc >> 0x0) & 0xff);
	image[offset+1] = (short)((crc >> 0x8) & 0xff);
	crc = 0;
      }
      crc = crcByte(crc, (byte)bytes[i]);
      image[size++] = bytes[i];
    }

    // finish out rest of page and calculate CRC
    while((size % DelugeConsts.DELUGE_BYTES_PER_PAGE) != 0) {
      crc = crcByte(crc, (byte)0x0);
      image[size++] = 0;
    }

    int offset = 2*((size-1)/DelugeConsts.DELUGE_BYTES_PER_PAGE);
    image[offset+0] = (short)((crc >> 0x0) & 0xff);
    image[offset+1] = (short)((crc >> 0x8) & 0xff);

    numPages = (short)(((size-1)/(DelugeConsts.DELUGE_PKTS_PER_PAGE*DelugeConsts.DELUGE_PKT_PAYLOAD_SIZE))+1);

  }

  private void printByte(int byteVal) {
    if (byteVal >= 0 && byteVal < 16)
      System.out.print("0");
    System.out.print(Integer.toHexString(byteVal).toUpperCase() + " " );
    byteCount++;
    if (byteCount >= 16) {
      System.out.println();
      byteCount = 0;
    }
  }

  public void dump() {
    byteCount = 0;
    for (int i = 0; i < size; i++ )
      printByte(image[i]);
    System.out.println();
  }

  public short[] getBytes() { return image; }

  public short getNumPages() { return numPages; }

}