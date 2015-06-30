/*									tab:4
 * Schema.java
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
 * Authors:  Sam Madden

Java class to read / parse mote schemas and report values from them.

 */

import java.util.*;


public class Schema {
    static final byte ID_LO_IDX = 0;  //offset into AM string of mote id
    static final byte ID_HI_IDX = 1;
    static final byte COUNT_IDX = 2; //offset into AM string of field count
    static final byte INDEX_IDX = 3; //offset into AM string of field index
    static final byte FIELD_START_IDX = 4; //offset into AM string of beginning of field-data
    
    short moteId;
    Hashtable fields; //of SchemaField

    public Schema(String init) {
	moteId = moteId(init);
	fields = new Hashtable();
	addField(init);
    }

    public void addField(String field) {
	fields.put(new Byte(schemaIdx(field)),
		   new SchemaField(field.substring(FIELD_START_IDX)));
    }

    public short getId() {
	return moteId;
    }

    public static short moteId(String schemaStr) {
      short id = (short)(((((short)schemaStr.charAt(ID_HI_IDX)) << 8) & 0xFF00) + ((short)schemaStr.charAt(ID_LO_IDX)));
      return id;
    }

    public static byte schemaIdx(String schemaStr) {
	return (byte)schemaStr.charAt(INDEX_IDX);
    }

    public int numFields() {
	return fields.size();
    }

    public SchemaField getField(int i) {
	return (SchemaField)fields.get(new Byte((byte)i));
    }
    public String toString() {
	Enumeration e = fields.elements();
	String s = "Id : " + moteId + "\n";
	int i = 0;
	while (e.hasMoreElements()) {
	    s += "Field " + i++ + "\n -------------- \n";
	    s += ((SchemaField)e.nextElement()).toString();
	}
	return s;
    }
    
}
