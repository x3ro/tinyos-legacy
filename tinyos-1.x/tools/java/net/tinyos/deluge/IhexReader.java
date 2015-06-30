// $Id: IhexReader.java,v 1.1 2005/07/22 17:52:37 jwhui Exp $

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

import java.io.*; 
import java.util.*;

public class IhexReader {

  private static final int MAX_SIZE = 1024*512;

  private static final int RECTYP_DATA     = 0;
  private static final int RECTYP_EOF      = 1;
  private static final int RECTYP_EXTSEG   = 2;
  private static final int RECTYP_STARTSEG = 3;

  private byte ihexdata[] = new byte[MAX_SIZE];

  private int imageOffset = 0;

  public IhexReader(String str) throws IOException {
    int totalBytes = 0;
    int physicalAddr = 0;
    int sectionBaseAddr = 0;
    int sectionCount = 0;
    int imgStartOffset = 0;
    int upperSegBaseAddr = 0;

    try {
      StringTokenizer strtok = new StringTokenizer(str, "\n");

      String line;

      int rectyp = RECTYP_DATA;

      while(strtok.hasMoreTokens() && rectyp != RECTYP_EOF) {
	line = strtok.nextToken();
	char bline[] = line.toUpperCase().toCharArray();

	if (bline[0] != ':')
	  throw new IOException("Parse error in ihex file.");

	int reclen = Integer.parseInt(Character.toString(bline[1]) + 
				      Character.toString(bline[2]),
				      16);

	int offset = Integer.parseInt(Character.toString(bline[3]) + 
				      Character.toString(bline[4]) +
				      Character.toString(bline[5]) +
				      Character.toString(bline[6]),
				      16);

	rectyp = Integer.parseInt(Character.toString(bline[7]) +
				  Character.toString(bline[8]),
				  16);

	switch(rectyp) {
	  
	case RECTYP_DATA:
	  if ((upperSegBaseAddr+offset) != physicalAddr) {
	    int sectionLen = physicalAddr - sectionBaseAddr;
	    for ( int i = 0; i < 4; i++ )
	      ihexdata[imgStartOffset+4+i] = (byte)((sectionLen >> (i*8)) & 0xff);
	  }
	  
	  if (imageOffset == 0 || (upperSegBaseAddr+offset) != physicalAddr) {
	    sectionCount++;
	    physicalAddr = (upperSegBaseAddr+offset);
	    sectionBaseAddr = (upperSegBaseAddr+offset);
	    imgStartOffset = imageOffset;
	    ihexdata[imageOffset+0] = (byte)((physicalAddr >> 0) & 0xff);
	    ihexdata[imageOffset+1] = (byte)((physicalAddr >> 8) & 0xff);
	    imageOffset += 8;
	  }
	  
	  for ( int i = 0; i < reclen; i++ ) {
	    ihexdata[imageOffset++] = (byte)Integer.parseInt(Character.toString(bline[2*i+9]) +
								 Character.toString(bline[2*i+10]),
								 16);
	    totalBytes++;
	    physicalAddr++;
	  }
	  break;

	case RECTYP_EXTSEG:
	  upperSegBaseAddr = Integer.parseInt(Character.toString(bline[9]) +
					      Character.toString(bline[10]) +
					      Character.toString(bline[11]) +
					      Character.toString(bline[12]),
					      16);
	  upperSegBaseAddr <<= 4;
	  break;

	case RECTYP_EOF:
	  int sectionLen = physicalAddr - sectionBaseAddr;
	  for ( int i = 0; i < 4; i++ )
	    ihexdata[imgStartOffset+4+i] = (byte)((sectionLen >> (i*8)) & 0xff);
	  for ( int i = 0; i < 8; i++ )
	    ihexdata[imageOffset++] = 0x0;
	  break;

	case RECTYP_STARTSEG:
	  break;

	default:
	  System.out.println(bline);
	  throw new IOException("Parse error in ihex file (unexpected type " + rectyp + ")");
	  
	}
      }
    } catch (Exception e) {
      e.printStackTrace();
    }

    System.out.println("Ihex read complete:");
    System.out.println("  Total bytes = " + totalBytes);
    System.out.println("  Sections = " + sectionCount);

  }

  public int getSize() { return imageOffset; }

  public byte[] getBytes() { return ihexdata; }

}