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
 * MessageSelection class that tries to find available message types
 * in TinyOS tools directory structure. It assumes that the root
 * directory provided ("." in null constructor) is in the Java
 * CLASSPATH variable, as it uses directory paths to generate class
 * names to load.
 */

package net.tinyos.message;

import java.io.*;
import java.util.*;

public class MessageSelection {
    private String rootPath;
    private Message[] messages = new Message[0];
    private Vector vector = new Vector();
    private Class messageClass;
    
    public static final int MAX_DEPTH = 12;

    public MessageSelection() {
	rootPath = ".";
	loadMessages();
    }
    
    public MessageSelection(String rootPath) {
	this.rootPath = rootPath;
	loadMessages();
    }

    public Message[] messages() {
	return messages;
    }

    public String getRootPath() {
	return rootPath;
    }
    
    private void loadMessages() {
	try {
	    File rootFile = new File(rootPath);
	    
	    Message m = new Message(0);
	    this.messageClass = m.getClass();

	    findMessages(rootFile, 0);
	    messages = new Message[vector.size()];
	    for (int i = 0; i < vector.size(); i++) {
		messages[i] = (Message)vector.elementAt(i);
	    }
	}
	catch (IOException exception) {
	    System.err.println(exception);
	    messages = new Message[0];
	}
	catch (InstantiationException exception) {
	    System.err.println(exception);
	    messages = new Message[0];
	}
	catch (ClassNotFoundException exception) {
	    System.err.println(exception);
	    messages = new Message[0];
	}
	catch (IllegalAccessException exception) {
	    System.err.println(exception);
	    messages = new Message[0];
	}
    }

    private boolean isRelated(Class subC, Class superC) {
	if (subC == superC) {return false;}
	for (Class tmp = subC.getSuperclass(); tmp != null; tmp = tmp.getSuperclass()) {
	    if (tmp.equals(superC)) {
		return true;
	    }
	}
	return false;
    }
    
    private void findMessages(File file, int depth)
	throws IOException,
	       ClassNotFoundException,
	       InstantiationException,
	       IllegalAccessException {

	String indent = "";
	for (int cnt = 0; cnt < depth; cnt++) {
	    indent += "  ";
	}
	
	if (depth > MAX_DEPTH) {
	    System.err.println("Maximum search depth (" + MAX_DEPTH + ") reached by: " + file.getName());
	}

	else if (file.isDirectory()) {
	    String[] dirents = file.list();
	    //System.out.println(indent + "Searching " + file);
	    for (int i = 0; i < dirents.length; i++) {
		File subFile = new File(file.getPath() + "/" + dirents[i]);
		//System.out.println(indent + "  " + subFile);
		findMessages(subFile, depth + 1);
	    }
	}
	else if (file.isFile()) { // Could be a Java class
	    String fileName = file.getPath();
	    String classEnd = ".class";
	    if (fileName.endsWith(classEnd)) {
		// Cut off the .class, leading ./,
		// then change '/'s in path to '.'s
		String className = fileName.substring(0, fileName.length() - classEnd.length());
		className = className.substring(2);
		className = className.replace('/', '.');
		try {
		    Class newClass = Class.forName(className);
		    if (isRelated(newClass, messageClass)) {
			Message m = (Message)newClass.newInstance();
			System.out.println("Found message type " + newClass);
			vector.addElement(m);
		    }
		}
		catch (NoClassDefFoundError e) {}
	    }
	}
	else {
	    System.out.println(indent + "Unknown file type: " + file + "!");
	}
    }

    public static void main(String[] args) {
	MessageSelection ms = new MessageSelection(".");
    }
}
