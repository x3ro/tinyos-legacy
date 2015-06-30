// $Id: Dispatcher.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

package net.tinyos.message;

import java.lang.reflect.*;
import java.util.Hashtable;
import java.util.Vector;
import java.util.Enumeration;
import java.io.*;
import net.tinyos.util.*;
import net.tinyos.packet.*;

public class Dispatcher implements DispatchIF, MessageListener { 
    private static final boolean DEBUG = false;
    protected DispatchIF mif;
    protected Message m;
    protected Method dispatch; 
    protected Method getDataOffsets;
    protected Constructor c;
    protected Hashtable templateTbl; 
    protected Object [] offsetArgs;
    public Dispatcher(DispatchIF mif, Message m, String dispatchName, String payloadName) throws NoSuchMethodException { 
	byte [] foo = new byte[1];
	Class [] cArgs =  new Class[1];
	cArgs[0] = foo.getClass();
	this.mif  = mif;
	templateTbl = new Hashtable();
	// store the method on which we are going to dispatch
	dispatch = m.getClass().getMethod("get_"+dispatchName, (java.lang.Class[])null);
	// store the constructor for the class that we're dispatching on 
	c = m.getClass().getConstructor(cArgs);
	// store the class that will hold the information about the data offset
	cArgs = new Class[1]; cArgs[0] = Integer.TYPE;
	getDataOffsets = m.getClass().getMethod("offset_"+payloadName, cArgs);
	// store the arguments to store the argument to offset_*
	offsetArgs = new Object[1];	offsetArgs[0] = new Integer(0);
	// register with the parent dispatcher
	mif.registerListener(m, this); 
    } 

    public void setDispatcher (DispatchIF newIF) { 
	
	mif.deregisterListener(m, this); 
	mif = newIF;
	mif.registerListener(m, this);
    }

    public void registerListener(Message m, MessageListener l) { 
	Integer amType = new Integer(m.amType()); // 
						  // nastry bit of protocol -- 
	Vector vec = (Vector) templateTbl.get(amType); 
	if (DEBUG)
	    System.err.println("Registered a nested handler for protocol "+m.amType());
	
	if (vec == null) { 
	    vec = new Vector(); 
	} 
	vec.addElement(new msgTemplate(m, l));
	templateTbl.put(amType, vec); 
    } 

    public void deregisterListener(Message m, MessageListener l) {
	Integer amType = new Integer(m.amType());
	Vector vec = (Vector)templateTbl.get(amType);
	if (vec == null) {
	    throw new IllegalArgumentException("No listeners registered for message type "+m.getClass().getName()+" (AM type "+m.amType()+")");
	}
	msgTemplate mt = new msgTemplate(m, l);
	// Remove all occurrences
	while (vec.removeElement(mt)) ;
	if (vec.size() == 0) templateTbl.remove(amType);
    }
    
    public void messageReceived(int addr, Message m) {
	Object []args = new Object[1];
	args[0] = m.dataGet();
	try {
	    Message newMsg = (Message)c.newInstance(args);
	    if (DEBUG) {
		System.err.println("Dispatching on a message class "+newMsg.getClass());
		System.err.println(newMsg);
	    }
	    // We're dispatching on the nested type, field called ID
	    // We've already passed checks of CRC, group, id, etc, so we're good
	    // to go. 
	    
	    Integer type = new Integer(((Number) dispatch.invoke(newMsg, (java.lang.Object[])null)).intValue());
	    if (DEBUG)
		System.err.println("Recovered dispatch ID "+type);
	    
	    Vector v = (Vector)templateTbl.get(type); 
	    if (v == null) {
		// some type of debug information 
		if (DEBUG) 
		    Dump.dump("Received multihop packet with an unknown id: "+type, m.dataGet());
		return; 
	    }
	    Class [] templateConstructorArgClass = new Class[2];
	    templateConstructorArgClass[0] = (new byte[1]).getClass();
	    templateConstructorArgClass[1] = Integer.TYPE;
	    Object [] templateConstructorArgs = new Object[2];
	    templateConstructorArgs[0] = newMsg.dataGet();
	    templateConstructorArgs[1] = new Integer(newMsg.baseOffset() + ((Integer)getDataOffsets.invoke(newMsg, offsetArgs)).intValue());
	    Enumeration en = v.elements();
	    while (en.hasMoreElements()) {
		msgTemplate template = (msgTemplate) en.nextElement();
		Message received;
		Constructor templateConstructor = template.template.getClass().getConstructor(templateConstructorArgClass);
		
		received = (Message) templateConstructor.newInstance(templateConstructorArgs);
		if (received instanceof LinkedMessage) {
		    ((LinkedMessage)received).setParent(newMsg);
		}
		template.listener.messageReceived(-1, received);
	    }
	} catch (NoSuchMethodException nsme) { 
	    System.err.println("Invalid dispatcher type or invalid dispatched type");
	    System.err.println(nsme);
	} catch (InstantiationException ie) {
	    System.err.println("Dispatched message could not be instantiated");
	    System.err.println(ie);
	} catch (IllegalArgumentException iae) {
	    System.err.println("Could not instantiate the dispatched message");
	    System.err.println(iae);
	    iae.printStackTrace();
	} catch (Exception e) {
	    System.err.println("An unknown error occurred");
	    System.err.println(e);
	    e.printStackTrace();
	}
	
    }

    /**
     * Inner class representing a single MessageListener and its
     * associated Message template.
     */
    class msgTemplate {
	Message template;
	MessageListener listener;
	msgTemplate(Message template, MessageListener listener) {
	    this.template = template;
	    this.listener = listener;
	}
	
	public boolean equals(Object o) {
	    try {
		msgTemplate mt = (msgTemplate)o;
		if (mt.template.getClass().equals(this.template.getClass()) &&
		    mt.listener.equals(this.listener)) {
		    return true;
		}
	    } catch (Exception e) {
		return false;
	    }
	    return false;
	}
	
	public int hashCode() {
	    return listener.hashCode();
	}
    }
}

