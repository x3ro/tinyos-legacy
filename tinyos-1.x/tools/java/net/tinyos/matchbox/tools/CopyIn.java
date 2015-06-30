// $Id: CopyIn.java,v 1.2 2003/10/07 21:45:54 idgay Exp $

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
package net.tinyos.matchbox.tools;

import net.tinyos.matchbox.*;
import java.io.*;

class CopyIn {
    Comm comm;

    CopyIn() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	if (argv.length != 1) {
	    System.err.println("usage: java tools.CopyIn matchbox-filename");
	    System.err.println("  copies standard input to matchbox-filename");
	    System.exit(2);
	}
	new CopyIn().copy(argv[0]);
	System.exit(0);
    }

    void copy(String fname) {
	comm.checkedSend(new Op(FS.FSOP_WRITE_OPEN).
	    argString(fname).argBoolean(true).argBoolean(true));

	int maxData = Op.maxData - 2;
	byte[] buffer = new byte[maxData];
	for (;;) {
	    Op cmd = new Op(FS.FSOP_WRITE);

	    try {
		int actualData = System.in.read(buffer);
		if (actualData <= 0) 
		    break;

		cmd.argU8(actualData);
		cmd.argBytes(buffer, actualData);
		comm.checkedSend(cmd);
	    }
	    catch (IOException e) {
		System.err.println("error reading input");
		System.exit(1);
	    }

	}
	comm.checkedSend(new Op(FS.FSOP_WRITE_CLOSE));
    }
}
