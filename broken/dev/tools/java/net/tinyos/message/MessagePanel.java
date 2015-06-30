/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Authors:  Philip Levis  <pal@cs.berkeley.edu>
 *
 */

/**
 * MessagePanel is a swing panel representing a TinyOS message type:
 * message fields can be viewed and edited.
 */

package net.tinyos.message;


import java.awt.*;
import java.lang.reflect.*;
import java.util.*;
import javax.swing.*;
import javax.swing.text.*;

public class MessagePanel extends JPanel {
    private Message message;
    private Vector fields = new Vector();

    public MessagePanel(Message msg) throws Exception {
	message = msg;
	loadFields();
	
	this.setLayout(new GridLayout(0, 1));
	this.setAlignmentX(LEFT_ALIGNMENT);
	for (int i = 0; i < fields.size(); i++) {
	    JPanel panel = (JPanel)fields.elementAt(i);
	    panel.setAlignmentX(LEFT_ALIGNMENT);
	    add(panel);
	}

	//MessageField m = new MessageField(msg, "Type", 8, Character.TYPE);
	//MessageField m2 = new MessageField(msg, "Addr", 16, Character.TYPE);
	//MessageField m3 = new MessageField(msg, "Group", 8, Character.TYPE);
	//MessageField m4 = new MessageField(msg, "Length", 8, Character.TYPE);
	//MessageField m5 = new MessageField(msg, "Data", 8, Byte.TYPE, true, 29);
	//m.write();
	//m2.write();
	//m3.write();
	//m4.write();
	//m5.write();
    }

    private void loadFields() {
	Method [] methods = message.getClass().getMethods();
	for (int i = 0; i < methods.length; i++) {
	    Method method = methods[i];
	    String name = method.getName();
	    if (name.startsWith("set")) {
		name = name.substring(3);
		if (method.getParameterTypes().length == 1) {
		    //System.err.println("Found field " + name);
		    loadField(name, method);
		}
		else if (method.getParameterTypes().length == 2) {
		    //System.err.println("Found array field " + name);
		    loadArrayField(name, method);
		}
		else {
		    System.err.println("Found unknown field " + name.substring(3) + " with " + method.getParameterTypes().length + " parameters: not adding to structure.");
		}
	    }
	}
    }


    // Pass the set method so we can look at its parameters more
    // easily -- otherwise we'd have to scan the method list again
    private void loadField(String name, Method setMethod) {
	Method get;
	Method set;
	Method offset;
	Method size;
	Class[] params = null;
	//System.err.println("Loading field: " + name);
	try {
	    offset = message.getClass().getMethod("offset" + name, params);
	    size = message.getClass().getMethod("size" + name, params);
	    get = message.getClass().getMethod("get" + name, params);
	    set = setMethod;
	    Integer lengthObj = (Integer)size.invoke(message, null);
	    int unitLength = lengthObj.intValue();
	    MessageField field = new MessageField(message, name, unitLength, get.getReturnType());
	    fields.addElement(field);
	}
	catch (NoSuchMethodException exception) {
	    System.err.println(exception);
	}
	catch (IllegalAccessException exception) {
	    System.err.println(exception);
	}
    	catch (InvocationTargetException exception) {
	    System.err.println(exception);
	}
    }

    private void loadArrayField(String name, Method setMethod) {
	Method get;
	Method set;
	Method offset;
	Method size;
	Method unit;
	Class[] params = new Class[1];
	params[0] = Integer.TYPE;

	//System.err.println("Loading array field: " + name);
	try {
	    offset = message.getClass().getMethod("offset" + name, params);
	    size = message.getClass().getMethod("size" + name, null);
	    get = message.getClass().getMethod("get" + name, params);
	    unit = message.getClass().getMethod("unit" + name, null);
	    set = setMethod;
	    Integer lengthObj = (Integer)unit.invoke(message, null);
	    int unitLength = lengthObj.intValue();
	    Integer sizeObj = (Integer)size.invoke(message, null);
	    int totalLength = sizeObj.intValue();
	    MessageField field = new MessageField(message, name, unitLength, get.getReturnType(), true, totalLength / unitLength);
	    fields.addElement(field);
	}
	catch (NoSuchMethodException exception) {
	    System.err.println(exception);
	}
	catch (IllegalAccessException exception) {
	    System.err.println(exception);
	}
    	catch (InvocationTargetException exception) {
	    System.err.println(exception);
	}
    }
    
    
    public void write() throws Exception {
	for (int i = 0; i < fields.size(); i++) {
	    MessageField field = (MessageField)fields.elementAt(i);
	    field.write();
	}
    }

    public Message getMessage() throws Exception {
	write();
	return message;
    }
    
    public byte[] get() throws Exception {
	write();
	return message.dataGet();
    }
    
    public static void main(String[] args) throws Exception {
	Message msg = new TOSMsg();
	MessagePanel p = new MessagePanel(new net.tinyos.oscope.OscopeMsg());
	JFrame frame = new JFrame("MessagePanel Test");
	frame.getContentPane().add(p);
	frame.pack();
	frame.setVisible(true);
    }
}
