/*									tab:4
 * SensorTracker
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

Java class which maintains a list of currently visible motes,
their schemas, and their most recently read sensor values.

 */

package net.tinyos.schema;
import net.tinyos.amhandler.*;


import java.util.*;


public class SensorTracker implements Runnable, AMHandler {

    // defines for MOTEINFO messages
    static final byte kSCHEMA_MESSAGE = (byte)255;
    static final byte kVERSION_MESSAGE = (byte)254;
    static final byte kVERSION_REQUEST = (byte)2;
    static final byte kSCHEMA_REQUEST = (byte)0;
    static final byte kINFO_MESSAGE = (byte)252;
    static final byte kFIELD_MESSAGE = (byte)251;
    static final byte kFIELD_REPLY_MESSAGE = (byte)250;

    // sensor schema message 10-byte format =
    //   sensorid:1, fieldid:1, reading:8

    static final int READING_ID_BYTE = 0;
    static final int READING_FIELD_BYTE = 1;
    static final int READING_FIRST_BYTE = 2;
    static final int READING_LAST_BYTE = 10;

    // predefined messages for output
    byte[] versionRequestMessage = {kVERSION_REQUEST};
    byte[] schemaRequestMessage = {kSCHEMA_REQUEST};
    byte[] fieldRequestMessage = {AMInterface.TOS_BCAST_ADDR_LO,AMInterface.TOS_BCAST_ADDR_HI, 0};

    AMInterface aif = new AMInterface("COM1",false);
    Hashtable schemas = new Hashtable();
    Vector moteList;

    public SensorTracker() {
	moteList = new Vector();

	Thread t = new Thread(this);
	t.start();
    }
    
    /** Periodically send a schemaRequestMessage asking all motes to transmit their schemas
     */
    public void run() {
	try {
	    aif.open();
	    
	    //the AM we respond to
	    aif.registerHandler(this, kSCHEMA_MESSAGE);
	    aif.registerHandler(this, kVERSION_MESSAGE);
	    aif.registerHandler(this, kFIELD_REPLY_MESSAGE);

	    while (true) {
		aif.sendAM(schemaRequestMessage, kINFO_MESSAGE, AMInterface.TOS_BCAST_ADDR);
	        Thread.currentThread().sleep(2000);
	    }
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

    /** @return The number of sensors we've ever seen */
    public int getNumSensors() {
	return moteList.size();
    }

    /** Return the schema for the idxth sensor we've seen */
    public Schema getSensorSchema(int idx) {
	return ((MoteInfo)(moteList.elementAt(idx))).schema;
    }

    /** Return the integer value of the latest sensor reading
	from the idxth sensors field fieldid 
    */
    public int getSensorReading(int idx, int fieldId) {
	MoteInfo m = (MoteInfo)(moteList.elementAt(idx));
	if (m.readings.size() <= fieldId) return -1;
	return ((Integer)m.readings.elementAt(fieldId)).intValue();
    }


    /** Active message handler -- used by AMInterface.java */
    public void handleAM(byte[] data, short addr, byte id, byte group) {
	switch (id) {
	case kSCHEMA_MESSAGE:
	    String dataStr = new String(data);
	    short sid = Schema.moteId(dataStr);
	    addMote(dataStr);

	    try {
		Thread.currentThread().sleep(500);
		fieldRequestMessage[1] = (byte)((byte)data[3]); /* index */;
		aif.sendAM(fieldRequestMessage, kFIELD_MESSAGE, sid /* source */);

	    } catch (Exception e) {
		e.printStackTrace();
	    }
	    break;
	    
	case kVERSION_MESSAGE:
	    System.out.print("Read Version: " );
	    break;
	case kFIELD_REPLY_MESSAGE:
	    System.out.print("Read Field: " );
	    addSensorReading(new String(data));
	    break;
	}
	for (int i = 0; i < data.length; i++) {
	    System.out.print(data[i] + ", ");
	}
	System.out.print("\n");
    }

    /** Add a new sensor reading to this tracker.
	Sensor readings consists of a 10 byte string, as follows:
	[sensor id byte][field id byte][8 bytes of sensor data (long)]
	@param reading The reading string 
    */
    private void addSensorReading(String reading) {
	MoteInfo m;
	short id = Schema.moteId(reading);
	m = (MoteInfo)schemas.get(new Short(id));

	if (m == null) return; //just ignore unknown sensors
	
	int value = 0;
	for (int i = READING_FIRST_BYTE; i < READING_LAST_BYTE; i++) {
	    value += ((int)reading.charAt(i))<<((i - READING_FIRST_BYTE) * 8);
	}
	System.out.println("READ SENSOR VALUE : " + value + ", FIELD ID = " + (int)(reading.charAt(READING_FIELD_BYTE)));

	while (m.readings.size() <= (int)reading.charAt(READING_FIELD_BYTE)) {
	    m.readings.addElement(new Integer(-1));
	}
	m.readings.setElementAt( new Integer(value), (int)reading.charAt(READING_FIELD_BYTE));
    }


    /** Adds information about a new mote to the tracker
	Parses the specified string into a Schema, which consists
	of an array of SchemaFields<p>
	See Schema.java and SchemaField.java
	@param moteInfo The mote info string 
    */
    private void addMote(String moteInfo) {
	short moteId = Schema.moteId(moteInfo);
	Schema s;
	MoteInfo m;
	m = (MoteInfo)schemas.get(new Short(moteId));
	
	if (m == null) {
	    m = new MoteInfo();
	    m.schema = new Schema(moteInfo);
	    m.lastHeard = new Date().getTime();
	    schemas.put(new Short(moteId), m);
	    moteList.addElement(m);
	} else {
	    m.schema.addField(moteInfo);
	    m.lastHeard = new Date().getTime();
	    System.out.println(m.schema.toString());
	}
    }


}

class MoteInfo {
    public Schema schema;
    public long lastHeard = 0;
    public Vector readings = new Vector();
}
