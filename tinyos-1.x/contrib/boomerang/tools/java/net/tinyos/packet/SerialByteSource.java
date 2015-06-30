// $Id: SerialByteSource.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $

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


package net.tinyos.packet;

import java.util.*;
import java.io.*;
import net.tinyos.comm.*;

/**
 * A serial port byte source, with extra special hack to deal with
 * broken javax.comm implementations (IBM's javax.comm does not set the
 * port to raw mode, on Linux, at least in some implementations - call
 * an external program (tinyos-serial-configure) to "fix" this)
 */
public class SerialByteSource extends StreamByteSource
{
  private SerialPort serialPort;
  private String portName;
  private int baudRate;

  public SerialByteSource(String portName, int baudRate) {
    this.portName = portName;
    this.baudRate = baudRate;
  }

  public void openStreams() throws IOException {
    try {
      serialPort = new TOSSerial(portName);
    }
    catch (Exception e) {
      throw new IOException("Could not open " + portName + ": " + e.getMessage());
    }

    try {
      serialPort.setSerialPortParams( baudRate, SerialPort.DATABITS_8,
        SerialPort.PARITY_NONE, SerialPort.STOPBITS_1 );
    }
    catch (Exception e) {
      serialPort.close();
      throw new IOException("Could not configure " + portName + ": " + e.getMessage() );
    }

    is = serialPort.getInputStream();
    os = serialPort.getOutputStream();
  }

  public void closeStreams() throws IOException {
    serialPort.close();
  }

  public String allPorts() {
    return "Listing available comm ports is no longer supported.";
  }

  public byte readByte() throws IOException {
    // XXX On Linux at least, javax.comm input streams are not interruptible.
    // Make them so, relying on the DATA_AVAILABLE serial event.
    return super.readByte();
  }

  protected void finalize() {
    System.out.println("SerialByteSource finalize");
    serialPort.close();
  }
}

