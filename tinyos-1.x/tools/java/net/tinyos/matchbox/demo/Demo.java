// $Id: Demo.java,v 1.1 2004/01/13 18:43:50 idgay Exp $
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

class Demo {
    Comm comm;
    GUI gui;

    Demo() {
	comm = new Comm();
	comm.start();

	gui = new GUI(comm);
    }

    public static void main(String[] argv) {
	boolean free = false;

	new Demo();
    }

    static long getSize(FSReplyMsg msg) {
	return
	    msg.getElement_data(0) |
	    msg.getElement_data(1) << 8 |
	    msg.getElement_data(2) << 16 |
	    msg.getElement_data(3) << 24L;
    }

}
