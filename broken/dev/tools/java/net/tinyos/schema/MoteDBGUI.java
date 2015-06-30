/*									tab:4
 * MoteDBGUI.java
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
 */

package net.tinyos.schema;
import net.tinyos.amhandler.*;

import javax.swing.*;
import javax.swing.tree.*;
import java.util.*;

/** Build a simple gui showing motes responding to MOTEINFO messages
 */
public class MoteDBGUI implements AMHandler, Runnable{

    // defines for MOTEINFO messages
    static final byte kSCHEMA_MESSAGE = (byte)255;
    static final byte kVERSION_MESSAGE = (byte)254;
    static final byte kVERSION_REQUEST = (byte)2;
    static final byte kSCHEMA_REQUEST = (byte)0;
    static final byte kINFO_MESSAGE = (byte)252;
    static final byte kFIELD_MESSAGE = (byte)251;
    static final byte kFIELD_REPLY_MESSAGE = (byte)250;
    
    // predefined messages for output
    byte[] versionRequestMessage = {kVERSION_REQUEST};
    byte[] schemaRequestMessage = {kSCHEMA_REQUEST};
    byte[] fieldRequestMessage = {AMInterface.TOS_BCAST_ADDR_LO,AMInterface.TOS_BCAST_ADDR_HI, 0};


  AMInterface aif;// = new AMInterface("COM2");
    Hashtable schemas = new Hashtable();


    Hashtable motes;

    JFrame frame;
    JTree tree;
    DefaultMutableTreeNode top = new DefaultMutableTreeNode("Motes");

    public MoteDBGUI(String commPort) {
      aif = new AMInterface(commPort,false);
	JScrollPane pane;
	Thread t = new Thread(this);

	frame = new JFrame("Motes Responding to MOTEINFO API");
	tree = new JTree(top);
	
	pane = new JScrollPane(tree);
	frame.getContentPane().add(pane);
	frame.setSize(200,400);
	frame.show();

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

    public void addMote(String moteInfo) {
	short moteId = Schema.moteId(moteInfo);
	Schema s;
	GUIMoteInfo m;
	System.out.print("Read Schema: " );
	DefaultMutableTreeNode node;
	DefaultMutableTreeNode sensor = null;
	DefaultMutableTreeNode field = null;
	m = (GUIMoteInfo)schemas.get(new Short(moteId));
	
	if (m == null) {
	    node = new DefaultMutableTreeNode("Sensor ID " + moteId);
	    m = new GUIMoteInfo();
	    m.schema = new Schema(moteInfo);
	    m.lastHeard = new Date().getTime();
	    schemas.put(new Short(moteId), m);
	    m.treeNode = node;
	    m.lastNum = m.schema.numFields();
	    //top.add(node);
	    ((DefaultTreeModel)tree.getModel()).insertNodeInto(node, top, top.getChildCount());
	    //((DefaultTreeModel)tree.getModel()).nodeChanged(top);
	} else {
	    node = m.treeNode;
	    m.schema.addField(moteInfo);
	    m.lastHeard = new Date().getTime();
	    System.out.println(m.schema.toString());
	}

	//if (m.lastNum != m.schema.numFields()) {
	    m.lastNum = m.schema.numFields();
	    //node.removeAllChildren();
	    for (int i = 0; i < m.schema.numFields(); i++) {
		SchemaField f = m.schema.getField(i);
		if (f == null) continue;
		String name = f.getName();
		
		if (m.readings.size() > i) {
		  int value = ((Integer)m.readings.elementAt(i)).intValue();
		  value = (int)((((double)value)/Math.pow(2,f.getBits())) * (f.getMax() - f.getMin())) + f.getMin();
		  name = name + " (" + value + ")";
		  System.out.println("Value was : " + value);
		}
		if (m.readingNodes.size() <= i || m.readingNodes.elementAt(i) == null) {
		    sensor = new DefaultMutableTreeNode(name);
		    
		    while (m.readingNodes.size() <= i)
			m.readingNodes.addElement(null);

		    m.readingNodes.setElementAt(sensor,i);

		    field = new DefaultMutableTreeNode("Version: " + f.getVersion(),false);
		    sensor.add(field);
		    
		    field = new DefaultMutableTreeNode("Type: " + f.getTypeString(),false);
		    sensor.add(field);
		    
		    field = new DefaultMutableTreeNode("Units: " + f.getUnitsString(),false);
		    sensor.add(field);
		    
		    field = new DefaultMutableTreeNode("Bits per reading: " + f.getBits(),false);
		    sensor.add(field);
		    
		    field = new DefaultMutableTreeNode("Max reading: " + f.getMax(),false);
		    sensor.add(field);
		    
		    field = new DefaultMutableTreeNode("Min reading: " + f.getMin(),false);
		    sensor.add(field);
		    
		    if (f.getInput() > 0) {
			field = new DefaultMutableTreeNode("Input port: " + f.getInputString(),false);
			sensor.add(field);
		    }
		    
		    field = new DefaultMutableTreeNode("Input direction: " + f.getDirectionString(),false);
		    sensor.add(field);
		    
		    if (f.getCost() > 0) {
			field = new DefaultMutableTreeNode("Cost per reading: " + f.getCost() + " J",false);
			sensor.add(field);
		    }
		    
		    if (f.getTime() > 0) {
			field = new DefaultMutableTreeNode("Time per reading: " + f.getTime() + " s",false);
			sensor.add(field);
		    }
		    ((DefaultTreeModel)tree.getModel()).insertNodeInto(sensor, node, node.getChildCount());
		    //tree.scrollPathToVisible(new TreePath(sensor.getPath()));
		} else {
		    sensor = (DefaultMutableTreeNode)m.readingNodes.elementAt(i);
		    sensor.setUserObject(name);
		    ((DefaultTreeModel)tree.getModel()).nodeChanged(sensor);
		}


	    }
	    //}	




    }

    public void addSensorReading(String reading) {
	GUIMoteInfo m;
	short id = Schema.moteId(reading);

	m = (GUIMoteInfo)schemas.get(new Short(id));

	if (m == null) return; //just ignore unknown sensors

	int value = 0;
	for (int i = 2; i < 10; i++) {
	    value += ((int)reading.charAt(i))<<((i - 2) * 8);
	}

	while (m.readings.size() <= (int)reading.charAt(2)) {
	    m.readings.addElement(new Integer(-1));
	    m.readingNodes.addElement(null);
	}
	m.readings.setElementAt( new Integer(value), (int)reading.charAt(2));
    }

    public void handleAM(byte[] data, short addr, byte id, byte group) {
	switch (id) {
	case kSCHEMA_MESSAGE:
	    String dataStr = new String(data);
	    
	    addMote(dataStr);

	    try {
		short sid = Schema.moteId(new String(data));
		fieldRequestMessage[2] = (byte)((byte)data[3]); /* index */;
		aif.sendAM(fieldRequestMessage, kFIELD_MESSAGE, sid /* source */);
		Thread.currentThread().sleep(500);
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
    
    
    public static void usage() {
      System.err.println("usage:   java MoteDBGUI comm_port");
      System.err.println("example: java MoteDBGUI COM1");
      System.exit(-1); 
    }
    
    public static void main(String argv[]) {
      if (argv.length != 1)
	usage();

      MoteDBGUI gui = new MoteDBGUI(argv[0]);
	
    }



    
}

class GUIMoteInfo {
    public Schema schema;
    public long lastHeard = 0;
    public Vector readings = new Vector();
    public DefaultMutableTreeNode treeNode;
    public Vector readingNodes = new Vector();
    public int lastNum;

}
