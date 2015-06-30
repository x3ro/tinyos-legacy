/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.trawler;

import java.util.*;
import edu.uci.ics.jung.graph.impl.*;
import edu.uci.ics.jung.graph.ArchetypeGraph;
import net.tinyos.message.Message;
import com.moteiv.oscope.Channel;
import java.awt.geom.Point2D;
import com.moteiv.oscope.GraphPanel;

public class NodeData extends DirectedSparseVertex implements ChannelDataSource {
    public final String NODE_CHANNEL_ID = "ADC Readings";
    private int addr;
    private long m_lastheard;
    private long m_lastref;
    private TimerTask maintenanceTask;
    private static Timer maintenanceTimer; 
    final static int DEFAULT_NODE_DELAY_MS = 30000; // 30 seconds
    final static int DEFAULT_HISTORY = 1000;
    final static int DEFAULT_DETECT_RESET_INTERVAL = 40;
    static int nodeDelay;
    private int m_quality ;
    private int numHeard, m_oldHeard;
    private int m_lost, m_oldLost; 
    private Vector m_vlastheard;
    Channel sensorChannel;

    protected void createChannel() {
	ArchetypeGraph g = getGraph();
	if (g == null) 
	    return;
	Object o = g.getUserDatum(NODE_CHANNEL_ID);
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
	sensorChannel.setDataLegend("Mote "+addr); 
	sensorChannel.setActive(true);
    }

    
    static {
	maintenanceTimer = new Timer();
	nodeDelay = DEFAULT_NODE_DELAY_MS;
    }

    public NodeData(int addr) {
	this.addr = addr;
	m_lastheard = System.currentTimeMillis();
	m_lastref = System.currentTimeMillis();
	maintenanceTask = new NodeDispose();
	maintenanceTimer.schedule(maintenanceTask, (long)getNodeDelay());	
	numHeard = 0; 
	m_lost = 0; 
	m_quality = 0; 
	m_vlastheard = new Vector();
	
    }

    public int getAddress() {
	return addr;
    }

    public int getNumPacketsReceived() { 
	return m_oldHeard + numHeard;
    }

    public int getNumPacketsLost() { 
	return m_oldLost + m_lost;
    }

    public void resetNodeStats() { 
	numHeard = 0; 
	m_lost = 0;
    } 
    /*    public boolean equals(Object a) { 
	if (a instanceof NodeData) {
	    return (addr == ((NodeData) a).getAddress());
	} 
	return false;
    }

    public int hashCode() {
	return getAddress();
    }
    */
    public long getLastHeard() {
	return m_lastheard;
    }

    public long getLastReference() {
	return m_lastref;
    }

    public static int getNodeDelay() { 
	return nodeDelay;
    }

    public static void setNodeDelay(int d) {
	nodeDelay = d;
    }

    private boolean exists(Vector v, int x) {
	Integer[] iArr = new Integer[v.size()];
	System.arraycopy(v.toArray(),0,iArr,0,v.size());
	Arrays.sort(iArr);
	int y = Arrays.binarySearch(iArr, new Integer(x));
	return (y >= 0);
    }


    private void detectReset(int lastheard) {
	Integer[] iArr = new Integer[m_vlastheard.size()];
	System.arraycopy(m_vlastheard.toArray(),0,iArr,0,m_vlastheard.size());
	Arrays.sort(iArr);

	if (m_vlastheard.size() < 1)
	    return;

	if ((lastheard <= 2) ||
	    (lastheard  < iArr[m_vlastheard.size() - 1].intValue()) &&
	    (iArr[m_vlastheard.size() - 1].intValue() - lastheard > DEFAULT_DETECT_RESET_INTERVAL)) {
	    m_oldHeard += m_vlastheard.size();
	    m_oldLost += lost(m_vlastheard);
	    numHeard = 0;
	    m_lost = 0;
	    m_vlastheard = new Vector();
	}
    }

    private int lost(Vector v) {
	int lost = 0;
	Integer[] iArr = new Integer[v.size()];
	System.arraycopy(v.toArray(),0,iArr,0,v.size());
	Arrays.sort(iArr);

	if (v.size() > 1) {
	    //System.out.print("seqnos = [");
	    for (int i = 0; i < v.size() - 1; i++) {
		//System.out.print(iArr[i].intValue() + " ");
		lost += ((iArr[i+1].intValue() - iArr[i].intValue()) - 1);
	    }
	    //System.out.println(iArr[v.size()-1].intValue() + "]");
	}
	
	return lost;
    }

    public void update(Message m) {
	m_lastref = System.currentTimeMillis();

	maintenanceTask.cancel();
	maintenanceTask = new NodeDispose();
	maintenanceTimer.schedule(maintenanceTask, getNodeDelay());

	if ((m != null) && 
	    (m instanceof DeltaMsg) &&
	    (((MultiHopMsg)(((DeltaMsg) m).getParent())).get_originaddr() == getAddress()) ){
	    DeltaMsg d_msg =  (DeltaMsg) m;
	    
	    if (!exists(m_vlastheard,(int)d_msg.get_seqno())) {
		detectReset((int)d_msg.get_seqno());
		m_lastheard = System.currentTimeMillis();
		m_vlastheard.add(new Integer((int)d_msg.get_seqno()));
		numHeard = m_vlastheard.size();
		m_lost = lost(m_vlastheard);
		if (getSensorChannel() != null) {
		    getSensorChannel().addPoint(new Point2D.Double(((double)(System.currentTimeMillis()-Trawler.startTime))/1000.0, (double)d_msg.get_reading()));
		    getSensorChannel().setActive(true);
		}
	    }
	}
    }
    
    public String toString() {
	return "Node"+getAddress();
    }

    class NodeDispose extends TimerTask {
	public void run() {
	    try {
		System.err.println("Will remove  "+NodeData.this);
		if (getGraph() != null) { 
		    ((edu.uci.ics.jung.graph.Graph)getGraph()).removeVertex((edu.uci.ics.jung.graph.Vertex)NodeData.this);
		}
		if (NodeData.this.getSensorChannel() != null) {
		    NodeData.this.getSensorChannel().setActive(false);
		}
	    } catch (Exception e) {
		System.err.println("Exception while disposing of a node:"+ e);
		e.printStackTrace();
	    }
	}
    }   
}