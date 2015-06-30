// $Id: NidoSerialDataSource.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

package net.tinyos.sf.old.nido;

import java.net.*;
import java.util.*;
import java.io.*;
import net.tinyos.sf.old.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class NidoSerialDataSource implements DataSource {
  private Socket eventSocket = null;
  private Socket cmdSocket = null;
  private SimProtocol eventProtocol = null;
  private SimProtocol cmdProtocol = null;
  private SerialForward sf;

  public NidoSerialDataSource() {
  }
  public NidoSerialDataSource(SerialForward sf) {
    this.sf = sf;
  }
  public void setSerialForward(SerialForward sf) {
    this.sf = sf;
  }

  public boolean OpenSource() {
    sf.VERBOSE("Opening TOSSIM virtual serial port source");
    try {
      sf.VERBOSE("Connecting to TOSSIM event port " + SimProtocol.TOSSIM_EVENT_PORT);
      eventSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_EVENT_PORT);
      InputStream is = eventSocket.getInputStream();
      OutputStream os = eventSocket.getOutputStream();
      eventProtocol = new SimProtocol(is, os);
      sf.VERBOSE("Connection opened to TOSSIM event port");

      sf.VERBOSE("Connecting to TOSSIM command port " + SimProtocol.TOSSIM_COMMAND_PORT);
      cmdSocket = new Socket("127.0.0.1", SimProtocol.TOSSIM_COMMAND_PORT);
      is = cmdSocket.getInputStream();
      os = cmdSocket.getOutputStream();
      cmdProtocol = new SimProtocol(is, os);
      sf.VERBOSE("Connection opened to TOSSIM command port");
    }
    catch (IOException e) {
      sf.VERBOSE("Cannot connect to TOSSIM");
      return false;
    }
    return true;
  }

  public boolean CloseSource() {
    sf.VERBOSE("Closing TOSSIM virtual serial port source");
    try {
      eventSocket.close();
      cmdSocket.close();
    } catch (Exception e) {
      // Ignore
    }
    eventSocket = null;
    cmdSocket = null;
    return true;
  }

  public byte[] ReadPacket() {

    while (true) { // Until we get a suitable event
      try {
	TossimEvent ev = eventProtocol.readEvent();
	if (ev.getMoteID() == 0 && ev instanceof UARTMsgSentEvent) {
	  UARTMsgSentEvent mev = (UARTMsgSentEvent)ev;
	  // Fit packet to correct size
	  if (mev.dataGet().length > sf.PACKET_SIZE) {
	    byte newarr[] = new byte[sf.PACKET_SIZE];
	    System.arraycopy(mev.dataGet(), 0, newarr, 0, sf.PACKET_SIZE);
	    return newarr;
	  } else if (mev.dataGet().length < sf.PACKET_SIZE) {
	    byte newarr[] = new byte[sf.PACKET_SIZE];
	    System.arraycopy(mev.dataGet(), 0, newarr, 0, mev.dataGet().length);
	    return newarr;
	  } else {
	    return mev.dataGet();
	  }
	}
      }
      catch (InterruptedIOException exception) {
	  sf.VERBOSE("TOSSIM connection closed.\n");
	  return null;
      }
      catch (IOException ioe) {
	sf.VERBOSE("TOSSIM source unable to read packet: "+ioe);
	return null;
      }
    }
  }

  public boolean WritePacket (byte[] packet) {
    int trycount = 0;
    while (trycount < 2) {
      try {
	if (cmdSocket == null) return false; 
	// Send to UART on mote 0 - need to pad to correct length
	UARTMsgSendCommand cmd = new UARTMsgSendCommand((short)0, 0L, packet);
	cmdProtocol.writeCommand(cmd);
	return true;
      } catch(IOException e) {
	CloseSource();
	OpenSource();
	trycount++;
      }
    }
    sf.VERBOSE("Unable to write UART packet to TOSSIM");
    return false;
  }
}
