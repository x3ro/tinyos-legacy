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
 */

package net.tinyos.schema;

import java.util.*;

/** Java class to read / parse mote schemas and report values from them.
  Given a schema reported by a mote, parses it into a list
  of SchemaFields.
  @author madden
 */

public class Schema {
    static final byte ID_LO_IDX = 0;  //offset into AM string of mote id
    static final byte ID_HI_IDX = 1;
    static final byte COUNT_IDX = 2; //offset into AM string of field count
    static final byte INDEX_IDX = 3; //offset into AM string of field index
    static final byte FIELD_START_IDX = 4; //offset into AM string of beginning of field-data
    
    short moteId;
    Hashtable fields; //of SchemaField

  /** Initialize a schema from a string reported as a part of an AM kSCHEMA_MESSAGE
    message.  Each such message represents the schema for a single field, so a n
    sensor mote will have n fields.  This message should be called for the first field,
    and addField should be called for the remainder.

    @param A string to allocate a new mote for...

    */
    public Schema(String init) {
	moteId = moteId(init);
	fields = new Hashtable();
	addField(init);
    }

  /** Given a string representing the schema of a single field in a mote,
    add that field to the sensor

    @param field The string representation of the field to be added.

    */
    public void addField(String field) {
	fields.put(new Byte(schemaIdx(field)),
		   new SchemaField(field.substring(FIELD_START_IDX)));
    }


  /** @eturn the moteId which this schema represents */
    public short getId() {
	return moteId;
    }

  /** @eturn the moteId given a schema string */
    public static short moteId(String schemaStr) {
      short id = (short)(((((short)schemaStr.charAt(ID_HI_IDX)) << 8) & 0xFF00) + ((short)schemaStr.charAt(ID_LO_IDX)));
      return id;
    }

  /** @return Given a schema string, return the field index which this string represents */
    public static byte schemaIdx(String schemaStr) {
	return (byte)schemaStr.charAt(INDEX_IDX);
    }

  /** @return The number of fields (sensors) which this mote has */
    public int numFields() {
	return fields.size();
    }

  /** @return The SchemaField data structure for the requested field index (0 - based),
    or null if no such field exists 

    @param i The zero based field index to fetch 
    */
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
