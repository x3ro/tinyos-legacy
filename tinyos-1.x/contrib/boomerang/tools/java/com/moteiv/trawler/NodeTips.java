/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
package com.moteiv.trawler;

import java.awt.event.MouseEvent;
import java.awt.geom.Point2D;
import edu.uci.ics.jung.graph.Vertex;
import edu.uci.ics.jung.graph.Edge;

import edu.uci.ics.jung.visualization.*;
public class NodeTips implements VisualizationViewer.ToolTipListener {
        VisualizationViewer vv;

        public NodeTips(VisualizationViewer vv) {
            this.vv = vv;
        }
    
        public String getToolTipText(MouseEvent e) {
	    try {
	        PickSupport pickSupport = vv.getPickSupport();
	        Point2D p = vv.transform(e.getPoint());
		
		Vertex v = pickSupport.getVertex(p.getX(), p.getY());
		if (v != null) {
		    return v.toString();
		} else {
		    Edge edge = pickSupport.getEdge(p.getX(), p.getY());
		    if(edge != null) {
			return edge.toString();
		    }
		    return null;
		}
	    } catch (Exception g) { 
		return null;
	    }
	}
}
