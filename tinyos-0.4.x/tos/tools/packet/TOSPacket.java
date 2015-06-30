/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Phil Levis
 * Date:                16.viii.2001
 * Description:         Abstract packet class
 *
 * This class represents a TinyOS packet (TOS_Msg). It allows for users to
 * create packet subclasses for their applications while still allowing
 * a generalized interface to the structure of the information.
 *
 * All of the fields are stored as big-endian (Java ordered) values in the
 * class, then shifted to little-endian when translating into or from
 * byte arrays.
 *
 * All fields in a packet should have a name starting with "packetField_",
 * such as "short packetField_destination". Users of the class may either
 * use the full field name (packetField_destination) or the identifier
 * (destination) when 
 
 */

package packet;

import java.lang.reflect.*;

public abstract class TOSPacket {

    public TOSPacket() {}
        
    public abstract byte[] toByteArray();
    public abstract void initialize(byte[] packet) throws IllegalArgumentException;
    public abstract byte[] getDataSection();

    public int headerLength() {return 0;}
    public int footerLength() {return 0;}
    public int packetLength() {return 38;}
    public int dataLength() {return packetLength() - (headerLength() + footerLength());}

    
    
    public String[] getByteFieldNames() {
	Class thisClass = getClass();
	Field[] fields = thisClass.getFields();

	String[] fieldNames = new String[fields.length];
	int numPacketFields = 0;
	for (int i = 0; i < fields.length; i++) {
	    Field field = fields[i];
	    String name = field.getType().getName();
	    if (name.equals("byte")) {
		fieldNames[numPacketFields] = field.getName();
		numPacketFields++;
	    }
	}
	
	String [] byteFields = new String[numPacketFields];
	for (int i = 0; i < numPacketFields; i++) {
	    byteFields[i] = fieldNames[i];
	}
	
	return byteFields;
    }

    
    public String[] getTwoByteFieldNames() {
	Class thisClass = getClass();
	Field[] fields = thisClass.getFields();

	String[] fieldNames = new String[fields.length];
	int numPacketFields = 0;
	for (int i = 0; i < fields.length; i++) {
	    Field field = fields[i];
	    String name = field.getType().getName();
	    if (name.equals("short")) {
		fieldNames[numPacketFields] = field.getName();
		numPacketFields++;
	    }
	}
	
	String [] twoByteFields = new String[numPacketFields];
	for (int i = 0; i < numPacketFields; i++) {
	    twoByteFields[i] = fieldNames[i];
	}
	
	return twoByteFields;
    }

    public String[] getFourByteFieldNames() {
	Class thisClass = getClass();
	Field[] fields = thisClass.getFields();

	String[] fieldNames = new String[fields.length];
	int numPacketFields = 0;
	for (int i = 0; i < fields.length; i++) {
	    Field field = fields[i];
	    String name = field.getType().getName();
	    if (name.equals("int")) {
		fieldNames[numPacketFields] = field.getName();
		numPacketFields++;
	    }
	}
	
	String [] fourByteFields = new String[numPacketFields];
	for (int i = 0; i < numPacketFields; i++) {
	    fourByteFields[i] = fieldNames[i];
	}
	
	return fourByteFields;
    }

    public String[] getEightByteFieldNames() {
	Class thisClass = getClass();
	Field[] fields = thisClass.getFields();

	String[] fieldNames = new String[fields.length];
	int numPacketFields = 0;
	for (int i = 0; i < fields.length; i++) {
	    Field field = fields[i];
	    String name = field.getType().getName();
	    if (name.equals("long")) {
		fieldNames[numPacketFields] = field.getName();
		numPacketFields++;
	    }
	}
	
	String [] eightByteFields = new String[numPacketFields];
	for (int i = 0; i < numPacketFields; i++) {
	    eightByteFields[i] = fieldNames[i];
	}
	
	return eightByteFields;	
    }

    
    public Field[] getPacketFields() {
	Class thisClass = getClass();
	Field[] fields = thisClass.getFields();

	Field[] newFields = new Field[fields.length];
	int numPacketFields = 0;
	for (int i = 0; i < fields.length; i++) {
	    Field field = fields[i];
	    String name = field.getName();
	    if (name.startsWith("packetField_", 0)) {
		newFields[numPacketFields] = field;
		numPacketFields++;
	    }
	}

	fields = newFields;
	newFields = new Field[numPacketFields];
	for (int i = 0; i < numPacketFields; i++) {
	    newFields[i] = fields[i];
	}

	return newFields;
    }

    public void setOneByteField(String fieldName, byte value) throws NoSuchFieldException, IllegalArgumentException, IllegalAccessException, IllegalTypeException  {
	
	fieldName = convertName(fieldName);

	Class thisClass = getClass();
	Field field = thisClass.getField(fieldName);
	if (!field.getType().getName().equals("byte")) {
	    throw new IllegalTypeException("Attempted to assign byte to field of type " + field.getType().getName());
	}
	field.setByte(this, value);
	
    }
    
    public void setTwoByteField(String fieldName, short value) throws NoSuchFieldException, IllegalArgumentException, IllegalAccessException, IllegalTypeException {

	fieldName = convertName(fieldName);

	Class thisClass = getClass();
	Field field = thisClass.getField(fieldName);
	if (!field.getType().getName().equals("short")) {
	    throw new IllegalTypeException("Attempted to assign short to field of type " + field.getType().getName());
	}
	field.setShort(this, value);
    }
    
    public void setFourByteField(String fieldName, int value) throws NoSuchFieldException, IllegalArgumentException, IllegalAccessException, IllegalTypeException  {
	fieldName = convertName(fieldName);
	
	Class thisClass = getClass();
	Field field = thisClass.getField(fieldName);
	if (!field.getType().getName().equals("int")) {
	    throw new IllegalTypeException("Attempted to assign int to field of type " + field.getType().getName());
	}
	field.setInt(this, value);
    }
    
    public void setEightByteField(String fieldName, long value) throws NoSuchFieldException, IllegalArgumentException, IllegalAccessException, IllegalTypeException  {
	fieldName = convertName(fieldName);
		
	Class thisClass = getClass();
	Field field = thisClass.getField(fieldName);
	if (!field.getType().getName().equals("long")) {
	    throw new IllegalTypeException("Attempted to assign long to field of type " + field.getType().getName());
	}
	field.setLong(this, value);
    }
    
    private String convertName(String name) {
	if (!name.startsWith("packetField_", 0)) {
	    name = "packetField_" + name;
	}
	return name;
    }

    public static String dataToString(byte[] data) {
	String dataString = "";
	for (int i = 0; i < data.length; i++) {
	    String datum = Integer.toString((int)(data[i] & 0xff), 16);
	    if (datum.length() == 1) {dataString += "0";}
	    dataString += datum;
	    if (((i + 1) % 10) == 0) {
		dataString += "\n";
	    }
	    else {
		dataString += " ";
	    }
	}

	return dataString;
    }
    
}
