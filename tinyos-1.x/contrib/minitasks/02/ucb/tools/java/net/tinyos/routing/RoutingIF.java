/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.

 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.

 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * Authors:  Kamin Whitehouse  <kamin@cs.berkeley.edu>
 *
 */
package net.tinyos.routing;

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.lang.reflect.*;
import java.util.*;
import java.io.*;

/**
 * RoutingIF class (mote Interface to be used with NEST routing architecture).
 *
 * A message interface built on top of moteIF.  It wraps MoteIF in all ways.
 *  The only difference is that, while moteIF dispatches on the amType field,
 * RoutingIF also dispatches on the routingProtocol field.  Make sure both of
 * them are set when you register as a listener for that message type.
 *
 * @version	2, 17 Jul 2003
 * @author	Kamin Whitehouse
 */
public class RoutingIF implements MessageListener{
    public static boolean DEBUG = false;
    public static boolean DISPLAY_ERROR_MSGS = true;

    MoteIF mif;
    Hashtable templateTbl; // Mapping from routingProtocol to msgTemplate
    
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



    public RoutingIF(String host, int port, int gid) throws Exception {
	mif = new MoteIF(host,port,gid);
    }

    public RoutingIF(SerialStub stub, int gid) throws Exception {
	mif = new MoteIF(stub, gid);
    }

    public RoutingIF(SerialStub stub, int gid, int msg_size, boolean check_crc) throws Exception {
	mif = new MoteIF(stub, gid, msg_size, check_crc);
    }

    public RoutingIF(String host, int port, int gid, int msg_size, boolean check_crc) throws Exception {
	mif = new MoteIF(host, port, gid, msg_size, check_crc);
    }

    public RoutingIF(MoteIF Mif) throws Exception {
	mif = Mif;
    }

    synchronized public void send(int moteId, Message m) throws IOException {
	mif.send(moteId, m);
    }

    synchronized public void registerListener(Message m, MessageListener l) {
	//check to see if this object has a field called "routingProtocol".
	Class c = m.getClass();
	Integer routingProtocol;
	Method method;
	try{
	    method = c.getMethod("get_routingProtocol", null);
	    routingProtocol = (Integer)(method.invoke(m, null));
	}
	catch(Exception e){ 
	    // if the field doesn't exist, 
	    // just pass this listener through to moteIF
	    mif.registerListener(m, l);
	    return;
	}
	//otherwise, remember that protocol for protocol dispatch and
	//register myself as a listener to this message from AM dispath
        Vector vec = (Vector)templateTbl.get(routingProtocol);
        if (vec == null) {
 	 vec = new Vector();
        }
        vec.addElement(new msgTemplate(m, l));
        templateTbl.put(routingProtocol, vec);
        mif.registerListener(m, this);
    }

    synchronized public void deregisterListener(Message m, MessageListener l) {
	//check to see if this object has a field called "routingProtocol".
	Class c = m.getClass();
	Integer routingProtocol;
	Method method;
	try{
	    method = c.getMethod("get_routingProtocol", null);
            routingProtocol = (Integer)(method.invoke(m, null));
	}
	catch(Exception e){ 
	    // if the field doesn't exist, 
	    // just pass this listener through to moteIF
	    mif.deregisterListener(m, l);
	    return;
	}
	//otherwise, remove myself as a listener for this packet
	//and remove this packet from my own dispath table
      mif.deregisterListener(m, this);
      Vector vec = (Vector)templateTbl.get(routingProtocol);
      if (vec == null) {
	throw new IllegalArgumentException("No listeners registered for message type "+m.getClass().getName()+" (Routing Protocol "+routingProtocol.toString()+")");
      }
      msgTemplate mt = new msgTemplate(m, l);
      // Remove all occurrences
      while (vec.removeElement(mt)) ;
      if (vec.size() == 0) templateTbl.remove(routingProtocol);
    }

    public void messageReceived(int to, Message m){
	//check to see if this object has a field called "routingProtocol".
	Class c = m.getClass();
	Integer protocolNumber;
	Method method;
	try{
	    method = c.getMethod("get_routingProtocol", null);
	    protocolNumber = (Integer)(method.invoke(m, null));
	}
	catch(Exception e){ 
	    // if the field doesn't exist, 
	    return;
	}
	Vector vec = (Vector)templateTbl.get(protocolNumber);
	if (vec == null) { //this means that we had a misparsed routing message
	  if (DISPLAY_ERROR_MSGS) Dump.dump("Received packet with protocolNumber "+protocolNumber.toString()+", but no listeners registered", m.toString().getBytes());
	  return;      
	}

	Enumeration en = vec.elements();
	while (en.hasMoreElements()) {
	  msgTemplate temp = (msgTemplate)en.nextElement();
	  temp.listener.messageReceived(((TOSMsg)m).get_addr(), m);
	}
    }

}








