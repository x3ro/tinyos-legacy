/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.trawler;

import edu.uci.ics.jung.graph.impl.*;
import edu.uci.ics.jung.graph.ArchetypeGraph;
import java.util.Timer;
import java.util.TimerTask; 
import java.util.Set;
import java.util.Iterator;
import edu.uci.ics.jung.graph.Vertex;
import edu.uci.ics.jung.graph.Edge;
import com.moteiv.oscope.Channel;
import com.moteiv.oscope.GraphPanel;
import java.awt.geom.Point2D;
import java.awt.Stroke;
import java.awt.BasicStroke;

public class LinkData extends DirectedSparseEdge implements ChannelDataSource{
    public final String LQI_CHANNEL_ID = "LinkQualityPanel";
    private long lastActive;
    private EdgeDispose maintenanceTask;
    final static int DEFAULT_EDGE_DELAY_MS = 10000; // 10 seconds
    static Timer maintenanceTimer;
    static int edgeDelay;
    
    // Here we're going to add visualization for edge quality over time
    static {
	maintenanceTimer = new Timer(); 
	edgeDelay = DEFAULT_EDGE_DELAY_MS;
    }

    Channel sensorChannel;

    protected void createChannel() {
	ArchetypeGraph g = getGraph();
	if (g == null) 
	    return;
	Object o = g.getUserDatum(LQI_CHANNEL_ID);
	if ((o != null) && (o instanceof GraphPanel)) {
	    GraphPanel gp = (GraphPanel)o;
	    Channel c= new Channel();
	    setSensorChannel(c);
	    c.setGraphPanel(gp);
	    if (gp.getNumChannels() == 0) {
		c.setMaster(true);
	    }
	    gp.addChannel(c);
	}
    }
    /**
     * Get the SensorChannel value.
     * @return the SensorChannel value.
     */
    public Channel getSensorChannel() {
	if (sensorChannel == null) 
	    createChannel();
	return sensorChannel;
    }

    /**
     * Set the SensorChannel value.
     * @param newSensorChannel The new SensorChannel value.
     */
    public void setSensorChannel(Channel newSensorChannel) {
	this.sensorChannel = newSensorChannel;
	sensorChannel.setDataLegend("Link Quality "+ ((NodeData)getSource()).getAddress() + "->" + ((NodeData)getDest()).getAddress());
	sensorChannel.setActive(true);
    }

    

    public LinkData(NodeData from, NodeData to) {
	super(from, to);
	lastActive = System.currentTimeMillis();
	maintenanceTask = new EdgeDispose(); 
    }

    public static int getEdgeDelay() {
	return edgeDelay; 
    }

    public static void setEdgeDelay(int d) {
	edgeDelay = d;
    }
    boolean activeStatus;

    /**
     * Get the ActiveStatus value.
     * @return the ActiveStatus value.
     */
    public boolean getActiveStatus() {
	return activeStatus;
    }

    /**
     * Set the ActiveStatus value.
     * @param newActiveStatus The new ActiveStatus value.
     */
    public void setActiveStatus(boolean newActiveStatus) {
	this.activeStatus = newActiveStatus;
    }
    

    int quality;

    /**
     * Get the Quality value.
     * @return the Quality value.
     */
    public int getQuality() {
	return quality;
    }

    /**
     * Set the Quality value.
     * @param newQuality The new Quality value.
     */
    public void setQuality(int newQuality) {
	this.quality = newQuality;
    }

    

    public void update(int quality, boolean active, int seqNo) {
	// Set up automatic disposal procedures
	maintenanceTask.cancel();
	lastActive = System.currentTimeMillis();
	maintenanceTask = new EdgeDispose();
	maintenanceTimer.schedule(maintenanceTask, (long)getEdgeDelay());
	setActiveStatus(active);
	setQuality(quality);
	if (getSensorChannel() != null) {
	    getSensorChannel().addPoint(new Point2D.Double( ((double)(System.currentTimeMillis()-Trawler.startTime))/1000.0, (double)quality ));
	    getSensorChannel().setActive(true);
	}
    }

    class EdgeDispose extends TimerTask { 
	public void run() {
	    try {
		if (getGraph() != null) {
		    ((edu.uci.ics.jung.graph.Graph)getGraph()).removeEdge((edu.uci.ics.jung.graph.Edge)LinkData.this);
		}
		if (getSensorChannel() != null) {
		    getSensorChannel().setActive(false);
		    //			System.out.println("Turning off the link graph for "+LinkData.this);
		}
	    } catch (Exception e) {
		System.err.println("Exception while disposing of a link:"+ e);
		e.printStackTrace();
	    }
	}
    }
    
}