/*
 * "Copyright (c) 2001 and The Regents of the University 
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
 * $Id: RInject.java,v 1.4 2003/07/03 05:10:03 cssharp Exp $
 */

/**
 * This application works with the TestUartRadio in tinyos/apps.
 * The string input on the command line is sent to the remote LCD display.
 *
 * // -fshort-enums
 * 
 * @author Joe Polastre
 */
import net.tinyos.util.*;
import java.io.*;
import net.tinyos.message.*;

public class RInject {
        
  public static final short TOS_BCAST_ADDR = (short) 0xffff;
	
  public static void usage() {
    System.out.println ("java RInject <groupid> <node> <clearleds|build|crumb <ma1|ma2>|route <ma1|ma2|maall ledval>>");
    System.exit(1);
  }
  
  public static byte writeEnum(TOSMsg msg, byte pos, byte enumVal) 
  {
    msg.setElement_data(pos++, enumVal);    
    //    msg.setElement_data(pos++, (byte)0);
    return pos;
  }

  public static byte writeByte(TOSMsg msg, byte pos, byte val) 
  {
    msg.setElement_data(pos++, val);
    return pos;
  }

  public static byte writeShort(TOSMsg msg, byte pos, short val)
  {
    msg.setElement_data(pos++, (byte)((val & 0xff)));
    msg.setElement_data(pos++, (byte)((val >> 8) & 0xff));
    return pos;
  }

  public static byte matobyte (String ma) 
  {
    if ("ma1".equals(ma)){
      return 2;
    } 
    if ("ma2".equals(ma)) {
      return 3;
    }
    if ("maall".equals(ma)) {
      return 16;
    }
    throw new IllegalArgumentException();
  }

  public static void main(String[] argv) throws Exception
  {
    byte group_id = 0;
    short node = 0;
    TOSMsg msg = new TOSMsg(36);
    byte pos = 0;
    
    if (argv.length < 3) {
      usage();
      System.exit(-1);
    }
    
    try {
      group_id = (byte)(Integer.parseInt(argv[0]) & 0xff);
      node = (short)(Integer.parseInt(argv[1]) & 0xffff);

//      pos = writeShort (msg, pos, node);

      if (argv[2].equals("build")) {
        pos = writeEnum (msg, pos, (byte)1); // tree_route
        pos = writeEnum (msg, pos, (byte)0); // destination landmark tree
      } else if (argv[2].equals ("crumb")) {
        pos = writeEnum (msg, pos, (byte)2); // crumb build
        pos = writeEnum (msg, pos, matobyte(argv[3])); // 
      } else if (argv[2].equals ("route")) {
        pos = writeEnum (msg, pos, (byte)3); // route
        pos = writeEnum (msg, pos, matobyte(argv[3]));
        pos = writeEnum (msg, pos, (byte)1); // leds
        pos = writeByte (msg, pos, (byte)Integer.parseInt(argv[4]));
      } else if (argv[2].equals("clearleds")) {
        pos = writeEnum (msg, pos, (byte)4); // clear your leds
      }
    } catch (Exception e) {
      e.printStackTrace();
      usage();
    }

    pos = writeShort( msg, pos, (short)1 ); // my address
    pos = writeByte( msg, pos, (byte)System.currentTimeMillis() ); // "sequence number"
    pos = writeByte( msg, pos, (byte)50 ); // am type

    msg.set_addr(node);// always send to address 0; we'll have it rebroadcast the
                    // packet for us
    msg.set_group(group_id);
    msg.set_type((short)102); // send by single hop address
    msg.amTypeSet((short)102);
    msg.set_length(pos);
    
    System.out.println (msg);

    SerialForwarderStub sfs = new SerialForwarderStub ("127.0.0.1", 9000);
    sfs.Open();
    // Need to wait for a read_log message to come back
    sfs.Write(msg.dataGet());
    sfs.Close();
    System.exit(0);
  }
}

