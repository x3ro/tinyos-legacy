// $Id: FlowAnalyzer.java,v 1.4 2004/05/15 23:16:37 jlhill Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * @author Wei Hong
 */

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.message.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;
import net.tinyos.surge.messages.*;


class EdgeData{
    int source, dest;
    int quality;
    int used;
    long time;
}

class NodeData{
    int id;
    int max_flow;
    boolean visited;
    EdgeData best;
    Hashtable edges = new Hashtable();
}
	


public class FlowAnalyzer extends PacketAnalyzer implements Runnable{
    Hashtable nodes = new Hashtable();
    Hashtable edges = new Hashtable();
    public FlowAnalyzer() {
	super();
	
	if(MainClass.getMoteIF() != null)MainClass.getMoteIF().registerListener(new DebugPacket(), this);

	//create new hashtables for your proprietary data

	//register to be notified of nodes and edges being created or deleted
	MainClass.objectMaintainer.AddEdgeEventListener(this);//listen to node events
	MainClass.objectMaintainer.AddNodeEventListener(this);//listen to edge event
	AnalyzerDisplayEnable();


	// Start decay thread
	new Thread(this).start();


    }

    public void messageReceived(int addr, Message m) {
	if(m.amType() == 17){
		//don't care about the reports, just the incomming estimates
	}else{
          MultihopMsg msg = new MultihopMsg(m.dataGet());
          this.DebugPacketReceived(msg);
	}

    }

    public synchronized void PacketReceived(MultihopMsg msg) {
    }	

    public synchronized void DebugPacketReceived(MultihopMsg msg) {
	DebugPacket DMsg = new DebugPacket(msg.dataGet(),msg.offset_data(0));
	int sourceID= (msg.get_originaddr());
	NodeData source = (NodeData)nodes.get(new Integer(sourceID));
	if(source == null){
		 source = new NodeData();
		 source.id = sourceID;
		 nodes.put(new Integer(sourceID), source);
        }	
	for(int i = 0; i < (int)DMsg.get_estEntries(); i ++){
        	int dest = (int)DMsg.getElement_estList_id(i);
        	int quality = (int)DMsg.getElement_estList_sendEst(i);
		updateEdge(source, dest, quality);
	}
    }


	void updateEdge(NodeData source, int dest, int quality){
	         EdgeData edge = (EdgeData)source.edges.get(new Integer(dest));
		if(edge == null) {
			edge = new EdgeData();
			edge.source = source.id;
			edge.dest = dest;
			edges.put(new Integer(edges.size()+1), edge);
			source.edges.put(new Integer(dest), edge);
		}
		edge.quality = quality;
		edge.time = new Date().getTime();

	}

    //NODE PAINTER
    //Put some function here to paint whatever you want over the node.
    //The x1,y1 coordinates are the top left corner within which the node will be drawn
    //The x2,y2 coordinates are the bottom right corner
    //Paint everything on the graphics object
    //this function is called by DisplayManager
    public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g) 
    {
		NodeData next = (NodeData)nodes.get(pNodeNumber);
	if(next == null) return;
    g.setColor(Color.red);
    //g.drawString("" + next.max_flow, (x1+x2)/2, y2-(y2-y1)/4 - 50);

    }

    //SCREEN PAINTER
    //Put some function here to paint whatever you want over the screen before and after
    //all edges and nodes have been painted.


    public void PaintScreenBefore(Graphics g) 
    {
	Dimension d = MainClass.mainFrame.GetGraphDisplayPanel().getSize();
	//place the background image.

    }

    public void run(){
	while(1 == 1){
		for(Enumeration nodeset = nodes.elements();nodeset.hasMoreElements();)
 		{
   			NodeData node = (NodeData)nodeset.nextElement();
			try{
			maxFlow(node.id, 0);	
			}catch (Exception e){
			e.printStackTrace();
			}
		}
		try{Thread.sleep(10000);}catch(Exception e){}
	}
    }


public double getFlow(int node){
	NodeData next = (NodeData)nodes.get(new Integer(node));
	if(next == null) return 0.0;
	else return ((double)next.max_flow)/255.0;
}


void maxFlow(int source, int dest){
		clearHistory();
		int val = 0;
		NodeData next = (NodeData)nodes.get(new Integer(source));
	  	int added = 1;
		while(added != 0){
			added = walk(next, dest);
			clear(next, dest, added);
			val += added;
		}	
		next.max_flow = val;
    }

void clear(NodeData source, int dest, int added){
	if(source == null) return;
	if(source.best == null) return;
	source.best.used += added;
	if(source.best.dest == dest) return;
	NodeData next = (NodeData)nodes.get(new Integer(source.best.dest));	
	clear(next, dest, added);
}

int walk(NodeData source, int dest){
	  if(source.visited) return 0;
	  source.visited = true;
	  int max = 0;
	  for(Enumeration edgeset = source.edges.elements();edgeset.hasMoreElements();)
 	  {
   		EdgeData edge = (EdgeData)edgeset.nextElement();
		NodeData next = (NodeData)nodes.get(new Integer(edge.dest));
		int val = 0;
		if(edge.dest == dest) val = 10000;
		else {
			if(next != null) val = walk(next, dest);
		}
		int edge_max = edge.quality - edge.used;
		if(val > edge_max) val = edge_max;
		if(val > max) {
			max = val;
			source.best = edge;
		}
	  }
	  source.visited = false;
	  return max;
	}

void clearHistory(){
	for(Enumeration edgeset = edges.elements();edgeset.hasMoreElements();)
 	{
   		EdgeData edge = (EdgeData)edgeset.nextElement();
		edge.used = 0;
	}
}

}
