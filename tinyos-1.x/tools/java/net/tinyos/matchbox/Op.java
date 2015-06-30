// $Id: Op.java,v 1.4 2004/11/18 22:36:16 idgay Exp $

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
package net.tinyos.matchbox;

import net.tinyos.message.*;

public class Op extends FSOpMsg {
    public static int maxData = 29 - DEFAULT_MESSAGE_SIZE;
    protected int offset;

    static void setMaxData(int i) {
	maxData = i;
    }

    public Op(int op) {
	super(maxData + DEFAULT_MESSAGE_SIZE);
	set_op((short)op);
	offset = 0;
    }

    public Op argU8(int x) {
	if (offset >= maxData) {
	    System.err.println("message overflow");
	    System.err.println("offset: "+offset+" max data " + maxData+" msg size "+MoteIF.maxMessageSize);
	    System.exit(2);
	}
	setElement_data(offset++, (short)x);
	return this;
    }

    public Op argU16(int x) {
	return argU8(x & 0xff).argU8((x >> 8) & 0xff);
    }

    public Op argU32(long x) {
	return argU16((int)x & 0xffff).argU16((int)(x >> 16) & 0xffff);
    }

    public Op argBoolean(boolean b) {
	return argU8(b ? 1 : 0);
    }

    public Op argString(String s) { 
         int len = s.length();
         for (int i = 0; i < len; i++)
	     argU8(s.charAt(i));
	 argU8(0);
	 return this;
    }

    public Op argBytes(byte[] buffer, int count) { 
	for (int i = 0; i < count; i++)
	     argU8(buffer[i]);
	 return this;
    }
}
