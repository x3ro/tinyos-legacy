// $Id: LinkedMessage.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

package net.tinyos.message;

public class LinkedMessage extends net.tinyos.message.Message {

    /** 
	LinkedMessage offers a mechanism for chaining embedded messages
	together through nested dispatch while preserving access to parent
	fields and allowing the creation of only a single message class per
	logical message type.  A canonical application is dispatch of messages
	embedded in a MultiHopMsg: an application handler for the
	embedded payload may need to access the information stored in the
	MultiHopMsg, such as originaddr.  The application may get a handle on
	the container of the embedded payload by calling getParent() on the
	payload.   A convinience method findParent(Class parentClass) is also
	provided when an application handler wants to locate a container of a
	particular class.  
     */

    /**
     * Create a new LinkedMessage with the default data_length of 256 and
     * default amType of -1.
     */
    LinkedMessage() { 
	super(256);
	amTypeSet(-1);
    }


    /**
     * Create a new LinkedMessage with the given data_length.
     */
    public LinkedMessage(int data_length) {
        super(data_length);
        amTypeSet(-1);
    }

    /**
     * Create a new LinkedMessage with the given data_length
     * and base offset.
     */
    public LinkedMessage(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(-1);
    }

    /**
     * Create a new LinkedMessage using the given byte array
     * as backing store.
     */
    public LinkedMessage(byte[] data) {
        super(data);
        amTypeSet(-1);
    }

    /**
     * Create a new LinkedMessage using the given byte array
     * as backing store, with the given base offset.
     */
    public LinkedMessage(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(-1);
    }

    /**
     * Create a new LinkedMessage using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public LinkedMessage(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(-1);
    }

    /**
     * Create a new LinkedMessage embedded in the given message
     * at the given base offset.
     */
    public LinkedMessage(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, 256);
        amTypeSet(-1);
    }

    /**
     * Create a new LinkedMessage embedded in the given message
     * at the given base offset and length.
     */
    public LinkedMessage(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(-1);
    }


    net.tinyos.message.Message parent;

    /**
     * Get the Parent value.
     * @return the Parent value.
     */
    public net.tinyos.message.Message getParent() {
	return parent;
    }

    /**
     * Set the Parent value.
     * @param newParent The new Parent value.
     */
    public void setParent(net.tinyos.message.Message newParent) {
	this.parent = newParent;
    }

    /** 
     * Finds a parent of a particular class.  The method uses isInstance() to
     * check for class type, so a returned message may be an instance of a
     * subclass.  
     * @param parentClass -- the class of the parent message that we're trying
     * to find.  
     * @returns message that is a instance of parentClass (or its subclass);
     * null if no such parent exists.  
     */

    public Message findParent(Class parentClass) { 
	if (parentClass.isInstance(parent)) {
	    return parent;
	} else if (parent instanceof LinkedMessage) {
	    return ((LinkedMessage)parent).findParent(parentClass);
	} else 
	    return null;
    }

    
}