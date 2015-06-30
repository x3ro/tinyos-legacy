/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Jun 13 2004
 * Desc:        Main window for script injector.
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.script.tree.*;
import vm_specific.*;

public class VMBufferReader implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  private Configuration config;
  private ConstantMapper dataMap;
  
  public VMBufferReader(String source,
			String configFileName) throws Exception {
    
    config = new Configuration(configFileName);

    moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    moteIF.registerListener(new MateUARTMsg(), this);
    moteIF.registerListener(new MateBCastMsg(), this);
    moteIF.registerListener(new MateMultiHopMsg(), this);
    moteIF.start();
    dataMap = config.getDataMap();

  }

  public void messageReceived(int to, Message message) {
    if (message instanceof MateUARTMsg) {
      receiveUART(message);
    }
    else if (message instanceof MateBCastMsg) {
      receiveBCast(message);
    }
    else if (message instanceof MateMultiHopMsg) {
      receiveMultiHop(message);
    }
    else {
      System.err.println("Received unknown message:");
      System.err.println(message);
    }
  }

  private void receiveUART(Message message) {
    MateUARTMsg msg = (MateUARTMsg)message;
    String name = dataMap.codeToName((byte)msg.get_buffer_type());
    if (!name.equals("BUFFER")) {
      System.err.println("Received UART message containing type " + name + ", ignoring:\n" + msg);
      return;
    }
    printBufferMsg(msg.get_buffer_data_data());
  }

  private void receiveBCast(Message message) {
    MateBCastMsg msg = (MateBCastMsg)message;
    String name = dataMap.codeToName((byte)msg.get_buffer_type());
    if (!name.equals("BUFFER")) {
      System.err.println("Received broadcast message containing type " + name + ", ignoring:\n" + msg);
      return;
    }
    printBufferMsg(msg.get_buffer_data_data());
  }

  private void printBufferMsg(byte[] data) {
    MateBufferMsg msg = new MateBufferMsg(data);
    int size = msg.get_buf_size();
    short[] entries = msg.get_buf_entries();
    String name = dataMap.codeToName((byte)msg.get_buf_type());
    
    System.out.println("Received broadcast buffer of type " + name + ", size " + size + " @ " + new Date(System.currentTimeMillis()));
    System.out.print("  ");
    for (int i = 0; i < size; i++) {
      System.out.print("[" + entries[i] + "]");
    }
    System.out.println();
  }

  private void receiveMultiHop(Message message) {
    MateMultiHopMsg mhMsg = (MateMultiHopMsg)message;
    MateBCastMsg msg = new MateBCastMsg();
    int offset = mhMsg.offset_data(0);
    msg.dataSet(mhMsg.dataGet(), offset, 0, mhMsg.dataLength() - offset);

    String name = dataMap.codeToName((byte)msg.get_buffer_type());
    if (!name.equals("BUFFER")) {
      System.err.println("Received UART message containing type " + name + ", ignoring.");
      return;
    }
    printBufferMsg(msg.get_buffer_data_data());
  }
  
  
  private static void usage() {
    System.err.println("usage: VMBufferReader [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {
    String source = "sf@localhost:9001";
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }

    VMBufferReader br = new VMBufferReader(source, "vm.vmdf");
  }


}
