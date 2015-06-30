/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Jun 21 2004
 * Desc:        Class that chunks programs and injects them.
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

public class ScriptInjector {
  private MoteIF moteIF;
  private ConstantMapper virusMap;
  
  public ScriptInjector(MoteIF moteIF, ConstantMapper virusMap) {
    this.moteIF = moteIF;
    this.virusMap = virusMap;
  }
  
  public void inject(byte[] code, byte handlerID, byte options, int version) throws IOException {
    CapsuleMsg msg = new CapsuleMsg();
    byte[] d  = msg.get_capsule_data();
    System.err.println("max size: " + d.length);
    if (d.length < code.length) {
      throw new IOException("The compiled program is too long: it is " + code.length + " bytes when the maximum is " + d.length + " bytes.");
    }
    msg.set_capsule_data(code);
    msg.set_capsule_dataSize(code.length);
    msg.set_capsule_options(options);


    int chunkSize = virusMap.nameToCode("CHUNK_SIZE");
    byte[] capsule = msg.dataGet();
    int capsuleHeaderSize = 6;
    int totalSize = code.length + capsuleHeaderSize;
    int numChunks = (totalSize +  chunkSize - 1) / chunkSize;
    
    System.err.print("Sending " + numChunks + " chunks (" + totalSize + "," + chunkSize + "): ");
    
    for (byte i = 0; i < numChunks; i++) {
      int thisChunkSize;
      if (i == numChunks - 1) {
	thisChunkSize = totalSize % chunkSize;
      }
      else {
	thisChunkSize = chunkSize;
      }
      
      CapsuleChunkMsg chunk = new CapsuleChunkMsg();
      chunk.set_version(version);
      chunk.set_capsuleNum(handlerID);
      chunk.set_piece(i);
      short[] chunkData = new short[chunkSize];
      for (int j = 0; j < thisChunkSize; j++) {
	chunkData[j] = capsule[i * chunkSize + j];
      }
      chunk.set_chunk(chunkData);
      int moteID = Integer.parseInt("ffff", 16);
      //System.out.println(chunk);
      moteIF.send(moteID, chunk);
      System.out.print("+");
      try {Thread.sleep(100);}
      catch (Exception e) {}
    }
    System.out.println();				
  }
  
}
