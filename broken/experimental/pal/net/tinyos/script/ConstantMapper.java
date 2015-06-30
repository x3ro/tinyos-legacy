// $Id: ConstantMapper.java,v 1.1 2004/02/17 23:06:37 scipio Exp $

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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Oct 6 2003
 * Desc:        Error codes for VM gui things.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.io.*;
import java.lang.reflect.*;
import java.util.*;


public class ConstantMapper {

    private Hashtable nameTable;
    private Hashtable codeTable;
    private ClassLoader loader;
    private String className;
    private String prefix;
    
    public ConstantMapper(String className, String prefix) {
	this.className = className;
	this.prefix = prefix;
	loader = this.getClass().getClassLoader();
	codeTable = new Hashtable();
	nameTable = new Hashtable();
	loadMap();
    }

    private void loadMap() {
	try {
	    Class constants = loader.loadClass(className);
	    Field[] fields = constants.getFields();
	    int prefixLen = prefix.length();
	    for (int i = 0; i < fields.length; i++) {
		Field field = fields[i];
		String fieldName = field.getName();
		if (fieldName.length() > prefixLen &&
		    fieldName.substring(0,prefixLen).equals(prefix)) {
		    String name = fieldName.substring(prefixLen);
		    byte val = (byte)(field.getShort(constants) & 0xff);
		    Byte code = new Byte(val);
		    //System.out.println(name + " -> " + code);
		    codeTable.put(code, name);
		    nameTable.put(name, code);
		}
	    }
	}
	catch (Exception e) {
	    System.out.println();
	    System.err.println(e);
	    e.printStackTrace();
	}
    }
    

    public String codeToName(byte code) {
	Byte b = new Byte(code);
	if (!codeTable.containsKey(b)) {
	    return "UNKNOWN";
	}
	else {
	    String val = (String)codeTable.get(b);
	    return val;
	}
    }

    public byte nameToCode(String name) {
	if (!nameTable.containsKey(name)) {
	    return (byte)0xff;
	}
	else {
	    Byte b = (Byte)nameTable.get(name);
	    return b.byteValue();
	}
    }    

    public Enumeration names() {
	return nameTable.keys();
    }

    public String getPrefix() {
	return prefix;
    }
    
    public static void main(String[] args) {
	try {
	    String arg = "net.tinyos.vm_asm.MateConstants";
	    if (args.length > 1) {
		arg = args[1];
	    }
	    ConstantMapper codes = new ConstantMapper(arg, args[0]);
	    Enumeration names = codes.names();
	    while (names.hasMoreElements()) {
		String name = (String)names.nextElement();
		System.out.println(name + ": " + codes.nameToCode(name));
	    }
	}
	catch (Exception ex) {
	    ex.printStackTrace();
	}
    }
}
