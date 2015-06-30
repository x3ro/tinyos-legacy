//$Id: SerialPort.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

package net.tinyos.comm;

import java.io.*;

public interface SerialPort
{
  public final static NativeSerial.DataBits DATABITS_7 = NativeSerial.DataBits.DATABITS_7;
  public final static NativeSerial.DataBits DATABITS_8 = NativeSerial.DataBits.DATABITS_8;

  public final static NativeSerial.Parity PARITY_NONE = NativeSerial.Parity.PARITY_NONE;
  public final static NativeSerial.Parity PARITY_ODD = NativeSerial.Parity.PARITY_ODD;
  public final static NativeSerial.Parity PARITY_EVEN = NativeSerial.Parity.PARITY_EVEN;
  public final static NativeSerial.Parity PARITY_MARK = NativeSerial.Parity.PARITY_MARK;
  public final static NativeSerial.Parity PARITY_SPACE = NativeSerial.Parity.PARITY_SPACE;

  public final static NativeSerial.StopBits STOPBITS_1 = NativeSerial.StopBits.STOPBITS_1;
  public final static NativeSerial.StopBits STOPBITS_2 = NativeSerial.StopBits.STOPBITS_2;
  public final static NativeSerial.StopBits STOPBITS_1P5 = NativeSerial.StopBits.STOPBITS_1P5;

  public InputStream getInputStream() throws IOException;
  public OutputStream getOutputStream() throws IOException;

  public void close();

  public void setSerialPortParams(
    int baudrate,
    NativeSerial.DataBits dataBits,
    NativeSerial.Parity parity,
    NativeSerial.StopBits stopBits
  ) throws UnsupportedCommOperationException;

  public int getBaudRate();
  public NativeSerial.DataBits getDataBits();
  public NativeSerial.StopBits getStopBits();
  public NativeSerial.Parity getParity();
}

