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
 *
 *
 * (c) 2005 Shockfish SA for the port to Siemens TC65
 *
 *
 */

package com.shockfish.tinyos.packet;

import java.util.*;
import java.io.*;
import javax.microedition.io.*;
import com.siemens.icm.io.*;

import net.tinyos.packet.StreamByteSource;

// The eventlistener has not been ported yet.

public class Tc65SerialByteSource extends StreamByteSource // implements
															// SerialPortEventListener
{

	private CommConnection commConn;

	private String portName;

	private int baudRate;

	public Tc65SerialByteSource(String portName, int baudRate) {
		// these are ignored for now
		this.portName = portName;
		this.baudRate = baudRate;

	}

	public void openStreams() throws IOException {
		try {
			String strCOM = "comm:com0;baudrate=57600;blocking=on;autocts=off;autorts=off";
			commConn = (CommConnection) Connector.open(strCOM);

			is = commConn.openInputStream();
			os = commConn.openOutputStream();

			// serialPort.addEventListener(this);
			// serialPort.notifyOnDataAvailable(true);
		} catch (Exception e) {
			commConn.close();
			throw new IOException("Couldn't configure " + portName);
		}

	}

	public void closeStreams() throws IOException {
		commConn.close();
	}

	Object sync = new Object();

	public byte readByte() throws IOException {

		// on TC65 we do not perform any sync.

		return super.readByte();
	}

}