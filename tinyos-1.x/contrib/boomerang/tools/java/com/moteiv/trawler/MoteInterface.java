/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

package com.moteiv.trawler;

import net.tinyos.util.*;
import net.tinyos.message.*;
import java.io.*;
import java.util.*;
import java.awt.Dimension;
import edu.uci.ics.jung.graph.*;
import com.moteiv.oscope.GraphPanel;
import com.moteiv.oscope.Channel;
import edu.uci.ics.jung.visualization.LayoutMutable;

public class MoteInterface implements MessageListener,Runnable {
    Graph g;
    int group_id;
    MoteIF mote;
    Hashtable nodes;
    Dispatcher d;
    PrintWriter pw = null;
    LayoutMutable l;
    //    public MoteInterface(Graph g) { 
    //	this(g, -1, ); 
    //    }

    public MoteInterface(Graph g, int gid, LayoutMutable _l ) {
	group_id = gid;
	l = _l;
        try {
	    this.g = g;
            mote = new MoteIF(PrintStreamMessenger.err, group_id);
	    //	    mote.registerListener(new MultiHopMsg(), this);
        }
        catch (Exception e) {
            System.err.println("Unable to connect to sf@localhost:9001");
            System.exit(-1);
        }
	try {
	    mote.registerListener(new MultiHopMsg(), this);
	    d = new Dispatcher(mote, new MultiHopMsg(), "id", "data");
	    d.registerListener(new DeltaMsg(), this);
	} catch (Exception e) {
	    System.err.println("Unable to construct a secondary dispatcher");
	    System.err.println(e);
	    e.printStackTrace();
	    System.exit(-1);
	}
       
	nodes = new Hashtable();
    }

    public Hashtable getNodes() {
	return nodes;
    }
    
    public MoteIF getMoteIF() {
	return mote;
    }

    File logFile;

    /**
     * Get the LogFile value.
     * @return the LogFile value.
     */
    public File getLogFile() {
	return logFile;
    }

    /**
     * Set the LogFile value.
     * @param newLogFile The new LogFile value.
     */
    public void setLogFile(File newLogFile) {
	if (newLogFile != null) {
	    if ((newLogFile.getName()=="") ||
		(newLogFile.getName()==null)) {
		newLogFile = null;
	    }
	}
	this.logFile = newLogFile;
	if (logFile == null) {
	    //	    try {
		pw.close();
		//	    } catch (IOException ioe) {}
	    pw = null;
	    return;
	}
	try {
	    FileOutputStream fos = new FileOutputStream(logFile,false);
	    pw = new PrintWriter(fos);
	} catch (FileNotFoundException fnfe) { 
	    System.out.println("Could not log data to "+logFile+" continuing with the previous log");
	    System.out.println(fnfe);
	} catch (SecurityException se) { 
	    System.out.println("Security exception, permission denied while trying to write "+logFile);
	    System.out.println(se);
	}
    }

    

    public void messageReceived(int dest_addr, Message msg) {
	//        if (msg instanceof MultiHopMsg) {
	//	    process((MultiHopMsg)msg);
	//} else 
	if (msg instanceof MultiHopMsg) {
	    if (pw != null) {
		//		try {
		    pw.print(System.currentTimeMillis());
		    pw.print(" ");
		    pw.print(msg);
		    //		} catch (IOException ioe) { }
	    }
	} else if (msg instanceof DeltaMsg) {
	    processEdge((DeltaMsg) msg);
	} else {
	    System.out.println("Unknown message type received.");
	}
    }

    private void processEdge(DeltaMsg msg) {
	//	System.err.println(msg); 
	NodeData n = process((MultiHopMsg) msg.getParent());// the origin node
	// JP 2006-05-07: Sometimes the graph is not yet set up, ie on
	// boot.  In this case, just return.
	if (n == null)
	    return;
	NodeData m = null;
	n.update(msg);
	
	
	// Set up edge weigths:  active edge (this one) should be bold, other
	// edges from the origin should be marked as inactive
	// RS 2006-05-08: Andrew Redfern still reports that there is a
	// null pointer exception occuring at the synchronizatiosn, so apply
	// defensive programming

        if (n.getGraph() == null ) 
	    return;


	// remove old edges from the graph. 
	synchronized (n.getGraph()) {
	Set edges = new HashSet(n.getOutEdges());

	// Update the neighborhood 
	for (int i = 0; i< msg.get_neighborsize(); i++ ) {
	    if (msg.getElement_neighbors(i) == 126)
		continue; // Do not add or display the UART node
	    if (msg.getElement_neighbors(i) != 65535) {
		m = getOrCreateNode(msg.getElement_neighbors(i));
	    } else {
		continue;
	    }
	    if (m == null) {
		//System.err.println("Heard from mote "+n+" but have not yet heard from its parent "+m);
		continue;
	    }
	    if (m == n) {
		//System.err.println("Self edges are not meaningful, node: "+m.getAddress());
		continue;
	    }

	    LinkData e = (LinkData) n.findEdge(m); 
	    if (e == null) {
		e = new LinkData(n, m);
		g.addEdge(e);
		l.update();
		//		createChannel(e, "LinkQualityPanel");
	    } else {// edge was found; lets remove it from the set 
		edges.remove(e); // if this throws exception, perhaps we
				 // should take it easy on the removal. 
	    }

	    m.update(null);// we are still aware of that vertex, even though
			   // we have no data to update
	    //	    System.err.println("Quality from "+msg.getElement_neighbors(i) +" is "+msg.getElement_quality(i));
	    e.update(msg.getElement_quality(i), 
		     m.getAddress() == msg.get_parent(),
		     (int)msg.get_seqno()
		     ); // update the edge
	    //System.err.println("Updating edge from "+n+" to "+m);
	}
	Iterator i = edges.iterator();
	while (i.hasNext()) {
	    try {
		LinkData e = (LinkData) i.next();
		g.removeEdge(e);
		if (e.getSensorChannel() != null) {
		    e.getSensorChannel().setActive(false);
		}
	    } catch (Exception f) {
		System.out.println("Problems removing an edge ");
		f.printStackTrace();
	    }
	}
	}
    }
    

    public NodeData getOrCreateNode(int address) { 
	NodeData n = null;
	n = (NodeData) nodes.get(new Integer(address));
	if (n == null) {
	    // if the graph doesn't exist, we can't create the node
	    if (g == null)
		return null;
	    n = new NodeData(address);
	    nodes.put(new Integer(address), n);
	    g.addVertex(n);
	    l.update();
	    Dimension d = l.getCurrentSize();
	    l.forceMove(n, Math.random()*(d.getWidth()-200) +100, Math.random()*(d.getHeight()-200)+100);
	    //	    createChannel(n, "ADC Readings");
	    System.out.println("Added Node: " + address);
	} else if (n.getGraph() == null) {
	    g.addVertex(n);
	}
	return n;
	
    }

    private NodeData process(MultiHopMsg msg) {
	// get addr
	return getOrCreateNode(msg.get_originaddr());
    }

    public void run() {
	try {
	    Thread.sleep(2000);
	}
	catch (Exception e) {
	}
    }
    protected void reset() {
	// resetting the interface consists of the following actions:
	// 1. delete all references to sensor channels relating to edges
	// 2. delete all references to sensor channels relating to nodes
	// 3. clear the node hashtable
	LinkData edge = null;
	NodeData vertex = null; 
	for (Enumeration e = nodes.elements(); e.hasMoreElements(); ) {
	    vertex = (NodeData) e.nextElement();
	    Set edges = new HashSet(vertex.getOutEdges());
	    Iterator i = edges.iterator();
	    if (i.hasNext()) {
		edge = (LinkData)i.next();
		break;
	    }
	}
	if (vertex != null) { 
	    Channel c = vertex.getSensorChannel();
	    GraphPanel gp = c.getGraphPanel();
	    Vector channels = gp.getChannels();
	    for (Enumeration e = channels.elements(); e.hasMoreElements(); ) {
		Channel x1 = (Channel)e.nextElement();
		gp.removeChannel( x1 );
		x1.clear();
	    }
	}

	if (edge != null) {
	    Channel c = edge.getSensorChannel();
	    GraphPanel gp = c.getGraphPanel();
	    Vector channels = gp.getChannels();
	    for (Enumeration e = channels.elements(); e.hasMoreElements(); ) {
		Channel x1 = (Channel)e.nextElement();
		gp.removeChannel( x1 );
		x1.clear();
	    }
	}
	
	nodes.clear();
    }
}
