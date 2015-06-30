// $Id: CldcNetworkByteSource.java,v 1.2 2006/09/11 13:40:03 rogmeier Exp $

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
 *
 * (c) 2005 Shockfish SA for the port to CLDC
 *
 */

package com.shockfish.tinyos.packet;

import java.util.*;
import java.io.*;
import javax.microedition.io.*;
import net.tinyos.packet.StreamByteSource;

public class CldcNetworkByteSource extends StreamByteSource {
	private SocketConnection sc;

	private String host;

	private int port;

	private String sockOpts;

	public CldcNetworkByteSource(String host, int port, String sockOpts) {
		this.host = host;
		this.port = port;
		this.sockOpts = sockOpts;
	}

	protected void openStreams() throws IOException {
		sc = (SocketConnection) Connector.open("socket://" + this.host + ":"
				+ this.port + this.sockOpts);
		sc.setSocketOption(SocketConnection.LINGER, 5);
		sc.setSocketOption(SocketConnection.DELAY, 0);
		is = sc.openInputStream();
		os = sc.openOutputStream();
	}

	protected void closeStreams() throws IOException {
		sc.close();
	}
}
