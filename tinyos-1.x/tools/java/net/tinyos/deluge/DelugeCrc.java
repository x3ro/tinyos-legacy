// $Id: DelugeCrc.java,v 1.1 2005/07/22 17:52:37 jwhui Exp $

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

public class DelugeCrc {

  public static short crcByte(short crc, byte b) {
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

  public static DelugeAdvMsg computeAdvCrc(DelugeAdvMsg advMsg) {

    // calc crc of adv message
    byte[] tmpBytes = advMsg.dataGet();
    short  crc;

    int start = DelugeAdvMsg.offset_nodeDesc_vNum();
    int stop = DelugeAdvMsg.offset_nodeDesc_crc();

    crc = 0;
    for ( int i = start; i < stop; i++ )
      crc = DelugeCrc.crcByte(crc, tmpBytes[i]);
    advMsg.set_nodeDesc_crc(crc);

    start = DelugeAdvMsg.offset_imgDesc_uid();
    stop = DelugeAdvMsg.offset_imgDesc_crc();

    crc = 0;
    for ( int i = start; i < stop; i++ )
      crc = DelugeCrc.crcByte(crc, tmpBytes[i]);
    advMsg.set_imgDesc_crc(crc);

    return advMsg;

  }

}