/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

package com.moteiv.oscope;
import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.oscope.OscopeMsg;
import net.tinyos.oscope.OscopeResetMsg;
import java.io.*;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Date;
import javax.swing.*;
import java.awt.geom.*;

/**
 * File: ScopeDriver.java
 *
 * Description: 
 * This class serves as the interface between the MoteIF that's
 * generating OscopeMessages and the GraphPanel.  In keeping with the previous
 * version of the oscilloscope the class creates a channel per mote and per
 * oscope channel.   The channels are indexed by their generated legend.  To
 * instantiate the ScopeDriver, a instantiated GraphPanel and a MoteIF are
 * needed; at some point MoteIF should be replaced with a more generic
 * Dispatcher, so that OscopeMsgs can be sent via multihop.
 */ 

public class ScopeDriver implements MessageListener {
    MoteIF mote; 
    GraphPanel panel;
    //    static final int NUM_CHANNELS = 10;
    static int NUM_READINGS = 10;
    private static final boolean VERBOSE = false;
    
    // We store different scope channels in a hashtable that's indexed by the
    // legend string. 
    
    Hashtable t = new Hashtable();

    public ScopeDriver(MoteIF _mote, GraphPanel _panel) { 
	mote = _mote;
	panel = _panel;
	mote.registerListener(new OscopeMsg(), this);
    } 

    
    /**
     * This is the handler invoked when a  msg is received from 
     * SerialForward.
     */

    public void messageReceived(int dest_addr, Message msg) {
	if (msg instanceof OscopeMsg) {
	    oscopeReceived( dest_addr, (OscopeMsg)msg);
	} else {
	    throw new RuntimeException("messageReceived: Got bad message type: "+msg);
	}
    }

    /**
     * Derive the canonical legend string based on the mote ID and channel
     * ID.  The legend string also used as a key to look up the channel. 
     */

    public String makeLegendString(int moteID, int channelID) { 
	return "Mote "+moteID+" Chan "+channelID;
    }

    /**
     * Recover the channel based on the mote ID and channel ID.
     */

    public Channel findChannel(int moteID, int channelID) {
	boolean foundPlot = false; 
	int i; 
	String legend = makeLegendString(moteID, channelID); 
	Channel c = (Channel)t.get(legend);
	if (c == null) { 
	    System.out.println("Creating Channel for "+legend);
	    c = new Channel(); 
	    c.setGraphPanel(panel);
	    c.setDataLegend(legend);
	    c.setActive(true);
	    if (panel.getNumChannels() == 0) {
		c.setMaster(true);
	    }
	    t.put(legend,c);
	    panel.addChannel(c);
	}
	return c;
    }
    
    /**
     * Message handler for oscope messages. 
     */

    public void oscopeReceived(int dest_addr, OscopeMsg omsg) {
        boolean foundPlot = false;
	int moteID, packetNum, channelID, i;
	Channel channel;

	moteID = omsg.get_sourceMoteID();
	channelID = omsg.get_channel();
	packetNum = omsg.get_lastSampleNumber();

	channel = findChannel(moteID, channelID); 
	if (channel.getLastPoint() == -1) { 
	    channel.setLastPoint(packetNum); 
	}
	
	int packetLoss = packetNum - channel.getLastPoint() - NUM_READINGS;
	
	for(int j = 0; j < packetLoss; j++) {
	    // Add "NUM_READINGS" blank points for each lost packet
	    for(i = 0; i < NUM_READINGS; i++)  
		channel.addPoint(null);
	}
	channel.setLastPoint(packetNum);
        int limit = omsg.numElements_data();
	for (i = 0; i < limit; i++) {
	    Point2D newPoint;
	    int val = omsg.getElement_data(i);
	   
	    if (VERBOSE) 
		System.err.println("val: "+val+" (0x"+Integer.toHexString(val)+")");
	    newPoint = new Point2D.Double( ((double)(packetNum+i)), (double)val );
	    //	    System.out.println("Adding to channel" + channel.getDataLegend()+" point "+newPoint);
	    
	    channel.addPoint( newPoint);
	}
    } 

    /**
     * Sends the a oscilloscope reset message to the associated MoteIF.  This
     * method is called when the "clear" button gets pressed in the associated
     * control panel. 
     */ 

    public void clear_data() {
	// Reset all motes

	try {
	    System.err.println("SENDING OscopeResetmsg\n");
	    mote.send(MoteIF.TOS_BCAST_ADDR, new OscopeResetMsg());
	} catch (IOException ioe) {
	    System.err.println("Warning: Got IOException sending reset message: "+ioe);
	    ioe.printStackTrace();
	}
    }

    // Currently non-functional b/c of switch to 2D point data
    /*
    void load_data(){
	JFileChooser	file_chooser = new JFileChooser();
	File		loadedFile;
	FileReader	dataIn;
	String		lineIn;
	int		retval,chanNum,numSamples;
	boolean		keepReading;

	retval = file_chooser.showOpenDialog(null);
	if( retval == JFileChooser.APPROVE_OPTION ) {
	    try {
		loadedFile = file_chooser.getSelectedFile();
		System.out.println( "Opened file: "+loadedFile.getName() );
		dataIn = new FileReader( loadedFile );
		keepReading = true;
		chanNum = numSamples = -1;
		while( keepReading ) {
		    lineIn = read_line( dataIn );
		    if( lineIn == null )
			keepReading = false;
		    else if( !lineIn.startsWith( "#" ) ) {
			if( chanNum == -1 ) {
			    try {
				chanNum = Integer.parseInt( lineIn.substring(0,lineIn.indexOf(" ")) );
				numSamples = Integer.parseInt( lineIn.substring(lineIn.indexOf(" ")+1,lineIn.length()) );
				data[chanNum] = new Vector2();
				System.out.println( ""+chanNum+" "+numSamples+"\n" );
			    } catch (NumberFormatException e) {
				System.out.println("File is invalid." );
				System.out.println(e);
			    }
			} else {
			    try {
				numSamples--;
				if( numSamples <= 0 )
				    numSamples = chanNum = -1;
			    } catch (NumberFormatException e) {
				System.out.println("File is invalid." );
				System.out.println(e);
			    }
			}
		    }
		}
		dataIn.close();
	    } catch( IOException e ) {
		System.out.println( e );
	    }
	}

    }

    String read_line( FileReader dataIn ) {
        StringBuffer lineIn = new StringBuffer();
	int		c,readOne;

	try {
	    while( true ) {
		c = dataIn.read();
		if( c == -1 || c == '\n' ) {
		    if( lineIn.toString().length() > 0 )
			return lineIn.toString();
		    else
			return null;
		}
		else
		    lineIn.append((char)c);
	    }
	} catch ( IOException e ) {
	}
	return lineIn.toString();
    }
    */
}