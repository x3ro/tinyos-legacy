// $Id: Dir.java,v 1.1 2004/01/13 18:43:50 idgay Exp $

/*									tab:4
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.matchbox.demo;

import net.tinyos.matchbox.*;
import java.util.*;

class Dir {
    Comm comm;

    Dir(Comm comm) {
	this.comm = comm;
    }

    static long getSize(FSReplyMsg msg) {
	return
	    msg.getElement_data(0) |
	    msg.getElement_data(1) << 8 |
	    msg.getElement_data(2) << 16 |
	    msg.getElement_data(3) << 24L;
    }

    long freeBytes() {
	FSReplyMsg free = comm.checkedSend(new Op(FS.FSOP_FREE_SPACE));

	return getSize(free);
    }

    long fileSize(String fname) {
	comm.checkedSend(new Op(FS.FSOP_READ_OPEN).argString(fname));
	FSReplyMsg size = comm.checkedSend(new Op(FS.FSOP_READ_REMAINING));
	long s = getSize(size);
	comm.checkedSend(new Op(FS.FSOP_READ_CLOSE));

	return s;
    }

    void delete(String fname) {
	comm.checkedSend(new Op(FS.FSOP_DELETE).argString(fname));
    }

    void rename(String from, String to) {
	comm.checkedSend(new Op(FS.FSOP_RENAME).
	    argString(from).argString(to));
    }

    Vector readDirectory() {
	Vector files = new Vector();

	comm.checkedSend(new Op(FS.FSOP_DIR_START));

	for (;;) {
	    FSReplyMsg reply = comm.send(new Op(FS.FSOP_DIR_READNEXT));

	    switch (reply.get_result()) {
	    case FS.FS_NO_MORE_FILES:
		return files;
	    case FS.FS_OK:
		files.add(reply.getString_data());
		break;
	    default:
		comm.check(reply);
		break;
	    }
	}
    }
}
