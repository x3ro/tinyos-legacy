// $Id: Copier.java,v 1.1 2004/01/13 18:43:50 idgay Exp $

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
import java.io.*;

class Copier {
    Comm comm;

    Copier(Comm comm) {
	this.comm = comm;
    }

    String copyToMote(File f, String moteName) {
	FileInputStream in;
     
	try {
	    in = new FileInputStream(f);
	}
	catch (FileNotFoundException e) {
	    return moteName + " not found";
	}

	comm.checkedSend(new Op(FS.FSOP_WRITE_OPEN).
	    argString(moteName).argBoolean(true).argBoolean(true));

	int maxData = Op.maxData - 2;
	byte[] buffer = new byte[maxData];
	for (;;) {
	    Op cmd = new Op(FS.FSOP_WRITE);

	    try {
		int actualData = in.read(buffer);
		if (actualData <= 0) 
		    break;

		cmd.argU8(actualData);
		cmd.argBytes(buffer, actualData);
		comm.checkedSend(cmd);
	    }
	    catch (IOException e) {
		comm.checkedSend(new Op(FS.FSOP_WRITE_CLOSE));
		return "error reading " + f.getPath();
	    }

	}
	comm.checkedSend(new Op(FS.FSOP_WRITE_CLOSE));
	return null;
    }

    String copyFromMote(String moteName, File f, String[] contents) {
	FileOutputStream out;
	int max = 400;
	StringBuffer head = new StringBuffer(max);
     
	try {
	    out = new FileOutputStream(f);
	}
	catch (FileNotFoundException e) {
	    return moteName + " could not be created";
	}

	comm.checkedSend(new Op(FS.FSOP_READ_OPEN).argString(moteName));

	int maxData = Op.maxData - 2;
	byte[] buffer = new byte[maxData];
	for (;;) {
	    FSReplyMsg data =
	      comm.checkedSend(new Op(FS.FSOP_READ).argU8(maxData));

	    int count = data.getElement_data(0);
	    if (count == 0)
	      break;

	    for (int i = 1; i <= count; i++) {
		byte b = (byte)data.getElement_data(i);
		buffer[i - 1] = b;
		if (max > 0) {
		    head.append((char)b);
		    max--;
		}
	    }
	    try {
		out.write(buffer, 0, count);
	    }
	    catch (IOException e) {
		comm.checkedSend(new Op(FS.FSOP_READ_CLOSE));
		return "error writing " + f.getPath();
	    }
	}
	comm.checkedSend(new Op(FS.FSOP_READ_CLOSE));

	contents[0] = head.toString();
	return null;
    }
}
