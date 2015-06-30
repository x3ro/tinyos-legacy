/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

package net.tinyos.mctorrent;

import java.io.*;
import net.tinyos.util.*;

import net.tinyos.deluge.*;

public class McTorrentImage {
	private int numPages;
	private int numPktsLastPage;
	private byte [] bytes;
	private int crc;
	
	public McTorrentImage (String ihexFileName) throws IOException {
		BufferedReader reader = new BufferedReader(new FileReader(ihexFileName));
		String ihexString = "";
		String line;
		while ((line = reader.readLine()) != null)
			ihexString += line + "\n";
		
		IhexReader ihexImage = new IhexReader(ihexString);
		
		byte [] ihexImageBytes = ihexImage.getBytes();		
                int ihexImageSize = ihexImage.getSize();
                int paddingSize = 0;

                if ((ihexImageSize % Consts.BYTES_PER_PKT) != 0)
                    paddingSize = Consts.BYTES_PER_PKT - (ihexImageSize % Consts.BYTES_PER_PKT);
                bytes = new byte[ihexImageSize + paddingSize];
                System.arraycopy(ihexImageBytes, 0, bytes, 0, ihexImageSize);
                for (int i = ihexImageSize; i < ihexImageSize + paddingSize; i++)
                    bytes[i] = (byte)0;
 
		crc = Crc.calc(bytes, bytes.length);
		
                // Note that bytes has been padded to multiple of packets.
		if (bytes.length % Consts.BYTES_PER_PAGE == 0) { 
			numPages = bytes.length / Consts.BYTES_PER_PAGE;
			numPktsLastPage = Consts.PKTS_PER_PAGE;
		} else {
			numPages = bytes.length / Consts.BYTES_PER_PAGE + 1;
			numPktsLastPage = (bytes.length % Consts.BYTES_PER_PAGE) / Consts.BYTES_PER_PKT;
		}

		System.out.println();
		System.out.println("Total number of bytes to be sent: " + bytes.length);
		System.out.println("Number of packets per page      : " + Consts.PKTS_PER_PAGE);
		System.out.println("Number of bytes per packet      : " + Consts.BYTES_PER_PKT);
		System.out.println("Number of pages                 : " + numPages);
		System.out.println("Number of packets in final page : " + numPktsLastPage);
		System.out.println("CRC                             : 0x" + Integer.toHexString(crc));		
		System.out.println();
	}
	
	public int getNumPages() {
		return numPages;
	}
	
	public int getNumPktsLastPage() {
		return numPktsLastPage;
	}
	
	public byte [] getBytes() {
		return bytes;
	}
	
	public int getCrc() {
		return crc;
	}

}
