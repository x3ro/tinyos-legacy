/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Kamin Whitehouse
 */

package net.tinyos.pytos;

import net.tinyos.message.*;

public class MessageListenerObject implements MessageListener
{
    public HashableMessageListener callback;
    
    public MessageListenerObject( HashableMessageListener callback )
    {
	this.callback = callback;
    }
    
    public void messageReceived( int addr, Message msg )
    {
	//System.out.println("Java message listener got a message");
	callback.messageReceived(addr, msg);
    }

    public boolean equals(Object o) {
	//System.out.println("message listener object.java equals being called");
	try {
	    MessageListenerObject ml = (MessageListenerObject)o;
	    //System.out.println("checking if hashcodes match");
	    if (ml.hashCode() == this.hashCode()){
		return true;
	    }
	} catch (Exception e) {
	    //System.out.println("exception!");
	    return false;
	}
	//System.out.println("doesn't match");
	return false;
    }
    
    public int hashCode( )
    {
	//System.out.println("Java MessageListener hashCode called");
	return callback.hashCode();
    }
}

