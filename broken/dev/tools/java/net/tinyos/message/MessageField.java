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

import net.tinyos.util.*;

public class MessageField extends JPanel {
    private String name;
    private boolean isArray;
    private int length;
    private int unitLength;
    private Class type;
    private Message msg;
    private JTextPane[] field;
    private JLabel label;
    private Message message;
    
    public MessageField(Message msg, String name, int unitLength,
			Class type) {
	super();
	this.msg = msg;
	this.name = name;
	this.unitLength = unitLength;
	this.length = 1;
	this.type = type;
	this.isArray = false;
	this.message = msg;

	String labelName = new String(name);
	for (int i = labelName.length(); i < 16; i++) {
	    labelName += " ";
	}
	label = new JLabel(labelName);

	field = new JTextPane[1];
	field[0] = new JTextPane(new LimitedStyledDocument(unitLength / 4));
	    
	String text = "";
	for (int i = 0; i < ((unitLength + 3) / 4); i++) {
	    text = text + "0";
	}
	field[0].setText(text);

	label.setFont(new Font("Courier", Font.BOLD, 12));
	label.setAlignmentX(LEFT_ALIGNMENT);
	add(label);
	
	field[0].setFont(new Font("Courier", Font.PLAIN, 12));
	field[0].setAlignmentX(RIGHT_ALIGNMENT);
	field[0].setSize(((unitLength + 3) / 4) * 15, 20);
	field[0].setMaximumSize(field[0].getSize());
	add(field[0]);
	
	//System.err.println("Set text (" + text + ") to " + field[0].getText());
	this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	this.setAlignmentX(LEFT_ALIGNMENT);
    }
	
    public MessageField(Message msg, String name, int unitLength,
			Class type, boolean isArray,
			int arrayLength) {
	super();
	this.msg = msg;
	this.name = name;
	this.unitLength = unitLength;
	this.type = type;
	this.isArray = isArray;
	this.length = arrayLength;
	this.message = msg;

	String labelName = new String(name);
	for (int i = labelName.length(); i < 16; i++) {
	    labelName += " ";
	}
	label = new JLabel(labelName);
	add(label);
	label.setAlignmentX(LEFT_ALIGNMENT);

	if (isArray) {
	    if (arrayLength <= 20) {
		this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    }
	    else {
		this.setLayout(new GridLayout((arrayLength % 20) + 1, 20));
	    }
	    field = new JTextPane[arrayLength];
	    //System.err.println("Setting text to ");
	    for (int i = 0; i < arrayLength; i++) {
		field[i] = new JTextPane(new LimitedStyledDocument(unitLength / 4));
		String text = "";
		for (int j = 0; j < ((unitLength + 3)/ 4); j++) {
		    text += "0";
		}
		field[i].setText(text);
		field[i].setAlignmentX(RIGHT_ALIGNMENT);
		field[i].setAlignmentX(RIGHT_ALIGNMENT);
		field[i].setSize(15 * ((unitLength + 3) / 4), 20);
		field[i].setMaximumSize(field[i].getSize());
		//System.err.print(text + " ");
		add(field[i]);
	    }
	    //	    System.err.println();
	}
	else {
	    this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    field = new JTextPane[1];
	    field[0] = new JTextPane(new LimitedStyledDocument((unitLength + 3)/ 4));
	    this.length = 1;
	}
	this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	this.setAlignmentX(LEFT_ALIGNMENT);
    }
	
	
    public int getLength() {return length;}
    public String getName() {return name;}
	
    public void write() throws Exception {
	if (isArray) {
	    writeArray();
	}
	else {
	    String methodName = "set" + name;
	    Class [] argTypes = new Class[1];
	    Object arg;
	    //System.err.println("Writing out " + field[0].getText());
	    if (type.equals(Byte.TYPE)) {
		arg = Byte.valueOf(field[0].getText(), 16);
		argTypes[0] = Byte.TYPE;
	    }
	    else if (type.equals(Short.TYPE)) {
		arg = Short.valueOf(field[0].getText(), 16);
		argTypes[0] = Short.TYPE;
	    }
	    else if (type.equals(Character.TYPE)) {
		arg = new Character((char)Integer.parseInt(field[0].getText(), 16));
		argTypes[0] = Character.TYPE;
	    }
	    else if (type.equals(Integer.TYPE)) {
		arg = Integer.valueOf(field[0].getText(), 16);
		argTypes[0] = Integer.TYPE;
	    }
	    else if (type.equals(Long.TYPE)) {
		arg = Long.valueOf(field[0].getText(), 16);
		argTypes[0] = Long.TYPE;
	    }
	    else {
		System.err.println("Unrecognized type: " + type.getName());
		return;
	    }
	    //System.err.println("Trying to call void " + methodName + "(" + argTypes[0].getName() + "); on " + message.getClass().getName());
	    Method method = message.getClass().getMethod(methodName, argTypes);
	    Object[] args = new Object[1];
	    args[0] = arg;
	    method.invoke(message, args);
	}
    }
    
    private void writeArray() throws Exception {
	String methodName = "set" + name;
	Class [] argTypes = new Class[2];
	Integer index;
	Object arg;
	for (int i = 0; i < getLength(); i++) {
	    index = new Integer(i);
	    argTypes[0] = Integer.TYPE;
	    if (type.equals(Byte.TYPE)) {
		arg = Byte.valueOf(field[i].getText(), 16);
		argTypes[1] = Byte.TYPE;
	    }
	    else if (type.equals(Short.TYPE)) {
		arg = Short.valueOf(field[i].getText(), 16);
		argTypes[1] = Short.TYPE;
	    }
	    else if (type.equals(Character.TYPE)) {
		arg = new Character((char)Integer.parseInt(field[i].getText(), 16));
		argTypes[1] = Character.TYPE;
	    }
	    else if (type.equals(Integer.TYPE)) {
		arg = Integer.valueOf(field[i].getText(), 16);
		argTypes[1] = Integer.TYPE;
	    }
	    else if (type.equals(Long.TYPE)) {
		arg = Long.valueOf(field[i].getText(), 16);
		argTypes[1] = Long.TYPE;
	    }
	    else {
		System.err.println("Unrecognized type: " + type.getName());
		return;
	    }
	    Method method = message.getClass().getMethod(methodName, argTypes);
	    //System.err.println("Trying to call void " + methodName + "(" + argTypes[0].getName() + ", "+ argTypes[1].getName() + "); on " + message.getClass().getName());
	    Object[] args = new Object[2];
	    args[0] = index;
	    args[1] = arg;
	    System.err.println("Calling " + methodName + "(" + args[0] + ", " + args[1] + ");");
	    method.invoke(message, args);
	}
    }
	
    public void read() {
	    
    }
	
}
