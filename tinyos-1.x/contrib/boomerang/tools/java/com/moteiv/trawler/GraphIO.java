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
import java.io.*;
import java.awt.Dimension;
import edu.uci.ics.jung.graph.*;
import edu.uci.ics.jung.visualization.*;
import edu.uci.ics.jung.graph.decorators.*;

public class GraphIO {

    static boolean saveGraph(Graph g, Layout l, MoteInterface mif, String file) {
	try {
	    // find the upper left corner of hte bounding box

	    double xmin = Double.POSITIVE_INFINITY;
	    double ymin = Double.POSITIVE_INFINITY;
	    double x,y;
	    for (Enumeration e= mif.getNodes().elements(); e.hasMoreElements(); ) {
		NodeData node = (NodeData) e.nextElement(); 
		x = l.getX(node);
		y = l.getY(node); 
		if (x < xmin) 
		    xmin = x;
		if (y < ymin)
		    ymin = y;
	    }
	    ymin = Math.floor(ymin) - 10;
	    xmin = Math.floor(xmin) - 10; 
	    
	    FileOutputStream fos = new FileOutputStream(file, false);
	    PrintWriter pw = new PrintWriter(fos);
	    for (Enumeration e = mif.getNodes().elements(); e.hasMoreElements();) {
		NodeData node = (NodeData)e.nextElement();
		pw.println(node.getAddress() + " " + (l.getX(node)-xmin) + " " + (l.getY(node)-ymin));
	    }
	    pw.close();
	    fos.close();
	}
	catch (Exception e) { return false; }
	return true;
    }
    
    static boolean resetPrefs(Graph g, LayoutMutable l, MoteInterface mif, String file) {
	File f = new File(file);
	f.delete(); // delete the existing preferences. 
	mif.reset();
	g.removeAllEdges();
	g.removeAllVertices();
	l.update();
	return true;
    }

    static boolean loadGraph(Graph g, LayoutMutable l, MoteInterface mif, String file) {
	double xmax = Double.NEGATIVE_INFINITY;
	double ymax = Double.NEGATIVE_INFINITY;
	double x,y;
	try {
	    BufferedReader in = new BufferedReader(new FileReader(file));
	    while (in.ready()) {
		String[] results = in.readLine().split("\\s");
		NodeData node = mif.getOrCreateNode((new Integer(results[0])).intValue());
		Indexer.getAndUpdateIndexer(g);
		l.update();
		x = (new Double(results[1])).doubleValue();
		y = (new Double(results[2])).doubleValue();
		l.forceMove(node, x, y);
		if (x > xmax) 
		    xmax = x;
		if (y > ymax) 
		    ymax = y;
		g.removeVertex(node);
		Indexer.getAndUpdateIndexer(g);
	    }
	    in.close();
	    l.initialize(new Dimension((int) Math.ceil(xmax)+10, (int) Math.ceil(ymax)+10));
	}
	catch (java.io.FileNotFoundException fnfe) { 
	    return false; 
	}
	catch (Exception e) { 
	    e.printStackTrace();
	    return false; 
	}
	return true;
    }

}
