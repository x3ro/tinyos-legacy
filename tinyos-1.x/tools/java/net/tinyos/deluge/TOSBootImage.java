// $Id: TOSBootImage.java,v 1.1 2005/07/22 17:52:37 jwhui Exp $

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
import java.lang.*;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

public class TOSBootImage {

  public final static int METADATA_SIZE = 128;
  private final static int STRING_SIZE = 16;
  private final static int SIZE_SIZE = 4;
  private final static int UNIX_TIME_SIZE = 4;
  private final static int USER_HASH_SIZE = 4;
  private final static int UID_HASH_SIZE = 4;

  private String name;     // 16
  private String userid;   // 16
  private String hostname; // 16
  private String platform; // 16
  private int    size;     // 4
  private long   unixTime; // 4
  private long   userHash; // 4
  private long   uidHash;  // 4

  private boolean delugeSupport = false;

  private IhexReader image = null;
  private byte supplement[] = null;
  private int supplementSize;

  public TOSBootImage(String filename) {

    if (filename.equals("")) {
      throw new IllegalArgumentException( "no file specified" );
    }

    File file = new File(filename);
    if (!file.exists()) {
      throw new IllegalArgumentException( "no such file " + filename );
    }

    try {

      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      DocumentBuilder parser = factory.newDocumentBuilder();
      Document doc = parser.parse(filename);
      String tmp;

      NodeList nlist=doc.getElementsByTagName("program_name");
      name = nlist.item(0).getFirstChild().getNodeValue();

      nlist=doc.getElementsByTagName("unix_time");
      tmp = nlist.item(0).getFirstChild().getNodeValue();
      unixTime = Long.parseLong(tmp.substring(0,tmp.indexOf('L')),16);

      nlist=doc.getElementsByTagName("user_id");
      userid = nlist.item(0).getFirstChild().getNodeValue();

      nlist=doc.getElementsByTagName("hostname");
      hostname = nlist.item(0).getFirstChild().getNodeValue();

      nlist=doc.getElementsByTagName("user_hash");
      tmp = nlist.item(0).getFirstChild().getNodeValue();
      userHash = Long.parseLong(tmp.substring(0,tmp.indexOf('L')),16);

      nlist=doc.getElementsByTagName("uid_hash");
      tmp = nlist.item(0).getFirstChild().getNodeValue();
      uidHash = Long.parseLong(tmp.substring(0,tmp.indexOf('L')),16);

      nlist=doc.getElementsByTagName("platform");
      tmp = nlist.item(0).getFirstChild().getNodeValue();
      platform = nlist.item(0).getFirstChild().getNodeValue();

      nlist=doc.getElementsByTagName("image");
      String imageStr = nlist.item(0).getFirstChild().getNodeValue();
      image = new IhexReader(imageStr);

      nlist=doc.getElementsByTagName("supplement");
      if (nlist.item(0) != null) {
	String supplementStr = nlist.item(0).getFirstChild().getNodeValue().trim();
	for ( int i = 0; i < supplementStr.length(); i++ ) {
	  if (supplementStr.charAt(i) == '\n') continue;
	  supplementSize++;
	  i++;
	}
	supplement = new byte[supplementSize];
	supplementSize = 0;
	for ( int i = 0; i < supplementStr.length(); i++ ) {
	  if (supplementStr.charAt(i) == '\n') continue;
	  supplement[supplementSize++] = (byte)Integer.parseInt(supplementStr.substring(i,i+2), 16);
	  i++;
	}
	System.out.println("Supplement read complete:");
	System.out.println("  Total bytes = " + supplementSize);
      }

      nlist=doc.getElementsByTagName("deluge_support");
      tmp = nlist.item(0).getFirstChild().getNodeValue();
      delugeSupport = tmp.equals("yes");

    } catch (Exception e) {
      e.printStackTrace();
    }

  }

  TOSBootImage(byte[] bytes) {

    int curOffset = 0;

    byte tmpBytes[] = new byte[STRING_SIZE];
    for ( int i = 0; i < STRING_SIZE; i++ )
      tmpBytes[i] = (byte)(bytes[curOffset++] & 0xff);
    name = new String(tmpBytes);

    if (name.indexOf('\0') != -1)
      name = name.substring(0, name.indexOf('\0'));

    for ( int i = 0; i < STRING_SIZE; i++ )
      tmpBytes[i] = (byte)(bytes[curOffset++] & 0xff);
    userid = new String(tmpBytes);

    if (userid.indexOf('\0') != -1)
      userid = userid.substring(0, userid.indexOf('\0'));
    if (userid.length() == 0) 
      userid = "N/A";

    for ( int i = 0; i < STRING_SIZE; i++ )
      tmpBytes[i] = (byte)(bytes[curOffset++] & 0xff);
    hostname = new String(tmpBytes);

    if (hostname.indexOf('\0') != -1)
      hostname = hostname.substring(0, hostname.indexOf('\0'));
    if (hostname.length() == 0) 
      hostname = "N/A";

    for ( int i = 0; i < STRING_SIZE; i++ )
      tmpBytes[i] = (byte)(bytes[curOffset++] & 0xff);
    platform = new String(tmpBytes);

    if (platform.indexOf('\0') != -1)
      platform = platform.substring(0, platform.indexOf('\0'));
    if (platform.length() == 0) 
      platform = "N/A";

    unixTime = 0;
    for ( int i = 0; i < UNIX_TIME_SIZE; i++ )
      unixTime |= (long)(bytes[curOffset++] & 0xff) << (i*8);

    userHash = 0;
    for ( int i = 0; i < USER_HASH_SIZE; i++ )
      userHash |= (long)(bytes[curOffset++] & 0xff) << (i*8);

    uidHash = 0;
    for ( int i = 0; i < UID_HASH_SIZE; i++ )
      uidHash |= (long)(bytes[curOffset++] & 0xff) << (i*8);

    delugeSupport = ( bytes[curOffset++] != 0 ) ? true : false;

  }

  public byte[] getBytes() {

    byte bytes[];
    int curOffset = 0;

    if ( supplementSize != 0 )
      bytes = new byte[METADATA_SIZE + image.getSize() + supplementSize + 8];
    else
      bytes = new byte[METADATA_SIZE + image.getSize() + 8];

    byte tmpBytes[] = name.getBytes();
    System.arraycopy(tmpBytes, 0, bytes, curOffset, tmpBytes.length);
    curOffset += STRING_SIZE;

    tmpBytes = userid.getBytes();
    System.arraycopy(tmpBytes, 0, bytes, curOffset, tmpBytes.length);
    curOffset += STRING_SIZE;

    tmpBytes = hostname.getBytes();
    System.arraycopy(tmpBytes, 0, bytes, curOffset, tmpBytes.length);
    curOffset += STRING_SIZE;

    tmpBytes = platform.getBytes();
    System.arraycopy(tmpBytes, 0, bytes, curOffset, tmpBytes.length);
    curOffset += STRING_SIZE;

    for ( int i = 0; i < 4; i++ )
      bytes[curOffset++] = (byte)((unixTime >> (8*i)) & 0xff);

    for ( int i = 0; i < 4; i++ )
      bytes[curOffset++] = (byte)((userHash >> (8*i)) & 0xff);

    for ( int i = 0; i < 4; i++ )
      bytes[curOffset++] = (byte)((uidHash >> (8*i)) & 0xff);

    bytes[curOffset++] = (byte)((delugeSupport) ? 0x1 : 0x0);

    System.arraycopy(image.getBytes(), 0, bytes, METADATA_SIZE, image.getSize());

    if (supplementSize != 0) {
      for ( int i = 0; i < 4; i++ )
	bytes[METADATA_SIZE + image.getSize() + i] = 0;
      for ( int i = 0; i < 4; i++ )
	bytes[METADATA_SIZE + image.getSize() + 4 + i] = (byte)((supplementSize >> (8*i)) & 0xff);
      System.arraycopy(supplement, 0, bytes, 
		       METADATA_SIZE + image.getSize() + 8, supplementSize);
    }
    else {
      for ( int i = 0; i < 8; i++ ) {
	bytes[bytes.length - i - 1] = 0;
      }
    }

    return bytes;

  }

  public String toString() {
    Date date = new Date(unixTime*1000);
    return ("    Prog Name:   " + name + "\n" +
	    "    Compiled On: " + date + "\n" +
	    "    Platform:    " + platform + "\n" +
	    "    User ID:     " + userid + "\n" +
	    "    Hostname:    " + hostname + "\n" +
	    "    User Hash:   0x" + Long.toHexString(userHash));
  }

  public String getName() { return name; }
  public String getHostname() { return hostname; }
  public String getUserID() { return userid; }
  public String getPlatform() { return platform; }
  public int getSize() { return size; }
  public long getUnixTime() { return unixTime; }
  public long getUserHash() { return userHash; }
  public long getUIDHash() { return uidHash; }
  public boolean getDelugeSupport() { return delugeSupport; }

}
