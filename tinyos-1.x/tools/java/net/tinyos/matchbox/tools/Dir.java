// $Id: Dir.java,v 1.2 2003/10/07 21:45:54 idgay Exp $

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
import java.util.*;

class Dir {
    Comm comm;

    Dir() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	boolean free = false;

	if (argv.length >= 1 && argv[0].equals("-f"))
	    free = true;

	new Dir().readDirectory(free);
	System.exit(0);
    }

    static long getSize(FSReplyMsg msg) {
	return
	    msg.getElement_data(0) |
	    msg.getElement_data(1) << 8 |
	    msg.getElement_data(2) << 16 |
	    msg.getElement_data(3) << 24L;
    }

    void readDirectory(boolean showFree) {
	Vector files = new Vector();

	comm.checkedSend(new Op(FS.FSOP_DIR_START));

	for (;;) {
	    FSReplyMsg reply = comm.send(new Op(FS.FSOP_DIR_READNEXT));

	    switch (reply.get_result()) {
	    case FS.FS_NO_MORE_FILES:
		printFiles(files, showFree);
		if (showFree) {
		    FSReplyMsg free = comm.checkedSend(new Op(FS.FSOP_FREE_SPACE));

		    System.out.println("" + getSize(free) + " bytes free");
		}

		return;
	    case FS.FS_OK:
		files.add(reply.getString_data());
		break;
	    default:
		comm.check(reply);
		break;
	    }
	}
    }

    void printFiles(Vector files, boolean showSize) {
	Enumeration elems = files.elements();

	while (elems.hasMoreElements()) {
	    String fname = (String)elems.nextElement();

	    System.out.print(fname);
	    if (showSize) {
		comm.checkedSend(new Op(FS.FSOP_READ_OPEN).argString(fname));
		FSReplyMsg size = comm.checkedSend(new Op(FS.FSOP_READ_REMAINING));
		System.out.print(" " + getSize(size));
		comm.checkedSend(new Op(FS.FSOP_READ_CLOSE));
	    }
	    System.out.println();
	}
    }
}
