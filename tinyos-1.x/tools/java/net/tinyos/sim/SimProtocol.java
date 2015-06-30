// $Id: SimProtocol.java,v 1.12 2004/06/24 20:57:29 mikedemmer Exp $

/*									tab:2
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Dennis Chi, Nelson Lee
 * Date:        November 20 2003
 * Desc:        
 *
 */

/**
 * @author Dennis Chi
 * @author Nelson Lee
 * @author Phil Levis
 */


package net.tinyos.sim;

import java.io.*;
import java.util.*;
import net.tinyos.message.Message;
import net.tinyos.sim.event.*;

/**
 * This class implements the basic functionality to communicate with
 * the simulator. It does not handle details such as setting up connections, 
 * managing sockets, dispatching events, and so forth.
 */
public class SimProtocol implements SimConst {
  public static final short TOSSIM_COMMAND_PORT = 10584;
  public static final short TOSSIM_EVENT_PORT = 10585;

  private static final boolean DEBUG = false;
  private InputStream is;
  private OutputStream os;
  private DataInputStream dis;
  private DataOutputStream dos;
  private boolean ackEventImmediately = true;
  
  public SimProtocol(InputStream inputStream, OutputStream outputStream) {
    this.is = inputStream;
    this.os = outputStream;
    dis = new DataInputStream(is);
    dos = new DataOutputStream(new BufferedOutputStream(os));
  }
  
  public SimProtocol(InputStream inputStream, OutputStream outputStream, boolean ackEventImmediately) {
    this.is = inputStream;
    this.os = outputStream;
    dis = new DataInputStream(is);
    dos = new DataOutputStream(new BufferedOutputStream(os));
    this.ackEventImmediately = ackEventImmediately;
  }

  /** 
   * Blocks until the next event can be read from the input stream
   * and returns it. Delays for 'delay' ms before sending an ACK.
   */
  public TossimEvent readEvent(long delay) throws IOException {
    if (DEBUG) System.err.println("SimProtocol.readEvent called");
    TossimEvent event = null;
    while (event == null) {
      short msgType = dis.readShort();
      short moteID = dis.readShort();
      long time = dis.readLong();
      short payload_len = dis.readShort();

      if (DEBUG) System.err.println("SimProtocol.readEvent: type "+Integer.toHexString(msgType)+" mote "+Integer.toHexString(moteID)+" time "+Long.toHexString(time)+" payload_len "+Integer.toHexString(payload_len));

      byte payload[] = new byte[payload_len];
      dis.readFully(payload);

      switch (msgType) {
	case net.tinyos.sim.msg.DebugMsgEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.DebugMsgEvent(moteID, time, payload);
	  break;

	case net.tinyos.sim.msg.RadioMsgSentEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.RadioMsgSentEvent(moteID, time, payload);
	  break;

	case net.tinyos.sim.msg.UARTMsgSentEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.UARTMsgSentEvent(moteID, time, payload);
	  break;

	case net.tinyos.sim.msg.ADCDataReadyEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.ADCDataReadyEvent(moteID, time, payload);
	  break;

      case net.tinyos.sim.msg.TossimInitEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.TossimInitEvent(moteID, time, payload);
	  break;

      case net.tinyos.sim.msg.InterruptEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.InterruptEvent(moteID, time, payload);
	  break;

      case net.tinyos.sim.msg.VariableResolveResponse.AM_TYPE:
	  event = new net.tinyos.sim.event.VariableResolveResponse(moteID, time, payload);
	  break;

      case net.tinyos.sim.msg.VariableRequestResponse.AM_TYPE:
	  event = new net.tinyos.sim.event.VariableRequestResponse(moteID, time, payload);
	  break;

      case net.tinyos.sim.msg.LedEvent.AM_TYPE:
	  event = new net.tinyos.sim.event.LedEvent(moteID, time, payload);
	  break;
	  
	default:
	  // Ignore it
	  System.err.println("SimProtocol.readEvent: Unknown event type "+msgType+" received, dropping");
	  event = null;
	  break;
      }

      if (delay != 0) {
	try {
	  Thread.currentThread().sleep(delay);
	} catch (InterruptedException ie) {
	  // Ignore
	}
      }
      if (ackEventImmediately) {
	ackEventRead();
      }
    }
    return event;
  }

  public void ackEventRead() throws IOException {
    os.write(0);
    os.flush();
  }

  
  /** 
   * Blocks until the next event can be read from the input stream
   * and returns it. 
   */
  public TossimEvent readEvent() throws IOException {
    return this.readEvent(0);
  }

  public void writeCommandNoAck(TossimCommand cmd) throws IOException {
    if (!(cmd instanceof Message)) throw new IOException("writeCommand: cmd must be of type net.tinyos.message.Message");
    if (DEBUG) System.err.println("SimProtocol.writeCommand: writing "+cmd);
    Message msg = (Message)cmd;
    dos.writeShort((int)msg.amType());
    dos.writeShort(cmd.getMoteID());
    dos.writeLong(cmd.getTime());
    int payload_len = msg.dataLength();
    dos.writeShort(payload_len);
    if (payload_len > 0) 
      dos.write(msg.dataGet(), msg.baseOffset(), msg.dataLength());
  }

  public void waitForAck() throws IOException {
    dos.flush();
    int ack = is.read();
  }
  
  public void writeCommand(TossimCommand cmd) throws IOException {
    writeCommandNoAck(cmd);
    waitForAck();
  }
}
