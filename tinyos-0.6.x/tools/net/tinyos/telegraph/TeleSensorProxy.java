package net.tinyos.telegraph;

import net.tinyos.schema.*;


import java.io.*;
import java.net.*;
import java.util.*;

/** TeleSensorProxy interfaces a set of sensors (located via the SensorTracker) 
    to Telegraph.  For each new sensor it discovers, it registers that Sensor
    with the Telegraph server running at TELE_PORT on the machine TELE_HOST.
    <p>
    It periodically asks the sensor tracker for new sensor readings and forwards
    those readings to Telegraph.
    <p>
    Sensor sources use the SensorSourceView reader and are named according to 
    their id -- for instance, sensor id 16 will be named "Sensor16".
    <p>
    Currently sensors are never removed from Telegraph.
    <p>
    @author Sam Madden
*/

public class TeleSensorProxy {
    static final int TELE_PORT = 2005;
    static final String TELE_HOST = "localhost";
    static final String SENSOR_SOURCE_VIEW_ID = "6";
    static final String SENSOR_PORT_REQUEST_COMMAND = "5\n"; //5 == command, newline sends it
    public static void main(String argv[]) {
	SensorTracker tracker;
	try {
	Socket teleSock = new Socket(InetAddress.getByName(TELE_HOST), TELE_PORT);
	OutputStreamWriter writer;
	BufferedReader reader;
	String portStr;
	int tuplePort;
	int lastNumSensors = 0;
	DatagramPacket pack;
	DatagramSocket sock = new DatagramSocket();

	writer = new OutputStreamWriter(teleSock.getOutputStream());
	reader = new BufferedReader(new InputStreamReader(teleSock.getInputStream()));
	
	writer.write(SENSOR_PORT_REQUEST_COMMAND); //ask for the socket to send tuples to
	writer.flush();
	portStr = reader.readLine();
	teleSock.close();

	tuplePort = (new Integer(portStr)).intValue();

	tracker = new SensorTracker();

	while (true) {
	    int i;
	    boolean added = false;
	    for (i = 0; i < tracker.getNumSensors(); i++) {
		Schema s = tracker.getSensorSchema(i);
		String readingStr = (new Short(s.getId())).toString() + ",";

		if (i >= lastNumSensors) { //is new ? 
		    //add the sensor to telegraph
		    added = addSchemaToTeleCatalog(s);
		}

		//build strng of readings for this sensor
		for (int j = 0; j < s.numFields(); j++) {
		    readingStr += (new Integer(tracker.getSensorReading(i,j))).toString();
		    if (j != s.numFields() - 1)
			readingStr += ",";
		}
		System.out.println("Writing packet to port : " + tuplePort + ", bytes = '" + readingStr + "'");

		pack = new DatagramPacket(readingStr.getBytes(),readingStr.length());
		pack.setAddress(InetAddress.getByName(TELE_HOST));
		pack.setPort(tuplePort);
		sock.send(pack);
		Thread.currentThread().sleep(50);

	    }
	    Thread.currentThread().sleep(1000);
	    if (added) lastNumSensors = i;
	}
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }


    /** Given a sensor schema, send the appropriate command to Telegraph to add the
	sensor to the catalog.
	@param s The schema of the sensor to add
	@return true iff the sensor was successfully added
    */
    static boolean addSchemaToTeleCatalog(Schema s) {
	Vector fields = new Vector();
	Vector values = new Vector();
	Vector cols = new Vector();
	Vector col;
	    
      /* expected catalog format:
	 <id>0</id>
	 <readerid>0</readerid>
	 <cachereaderid>-1</cachereaderid>
	 <cacherefreshperiod>0</cacherefreshperiod>
	 <lastcacheupdate>0</lastcacheupdate>
	 <isstreaming>0</isstreaming>
	 <name>SourceR</name>
	 <readerinit>telegraph/test/dummy13636</readerinit>
	 <viewpred></viewpred>
	 <bindings></bindings>
	 <rangeindex></rangeindex>
	 <primarykey></primarykey>
	 <cachefile></cachefile>
	 <description>dummy</description>
      */
	//build list of fields
	fields.addElement("readerid");
	fields.addElement("cachereaderid");
	fields.addElement("cacherefreshperiod");
	fields.addElement("lastcacheupdate");
	fields.addElement("isstreaming");
	fields.addElement("name");
	fields.addElement("readerinit");
	fields.addElement("viewpred");
	fields.addElement("bindings");
	fields.addElement("rangeindex");
	fields.addElement("primarykey");
	fields.addElement("cachefile");
	fields.addElement("description");
	
	//list of values      for source
	values.addElement(SENSOR_SOURCE_VIEW_ID); //readerid
	values.addElement("-1"); //cachereaderid (none)
	values.addElement("0"); //cacherefreshperiod (none)
	values.addElement("0"); //lastcacheupdata (none)
	values.addElement("1"); //is streaming
	values.addElement("Sensor" + s.getId()); //name
	values.addElement((new Short(s.getId())).toString()); //init -- sensorid
	values.addElement(""); //viewpred
	values.addElement(""); //bindings
	values.addElement(""); //rangeindex
	values.addElement(""); //primarkey
	values.addElement(""); //cachefile
	values.addElement(""); //description
	
	//plus one set of entries per column
	for (int i = 0; i < s.numFields(); i++) {
	    //and columns
	    col = new Vector();
	    if (s.getField(i) == null)
		return false;
	    col.addElement(s.getField(i).getName()); //name
	    col.addElement("java.lang.Integer"); //type
	    col.addElement(""); //description
	    cols.addElement(col);
	}

	//then add it
	System.out.println("Trying RemoteAddSource");
	try {
	    RemoteSource.RemoteAddSource(InetAddress.getByName(TELE_HOST), 0, fields, values, cols);
	    System.out.println("Successful.");
	} catch (Exception e) {
	    System.out.println("RemoteAddSource Failed : " + e);
	}
	return true;
    }
}
