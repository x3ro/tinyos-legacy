/* "Copyright (c) 2001 and The Regents of the University  
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001 
 */

//***********************************************************************
//***********************************************************************
//This is the parent class to all PacketAnalyzers
//***********************************************************************
//***********************************************************************

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.surge.util.*;
import net.tinyos.message.*;
import java.util.*;
import java.lang.*;
import java.awt.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;

public abstract class PacketAnalyzer implements MessageListener, PacketEventListener, NodeClickedEventListener, EdgeClickedEventListener, NodeEventListener, EdgeEventListener, NodePainter, EdgePainter, ScreenPainter, NodeDialogContributor, EdgeDialogContributor
{
  public PacketAnalyzer() { 
    MainClass.getMoteIF().registerListener(new SurgeMsg(), this);
  }

  // For MessageListener
  public void messageReceived(int addr, Message m) {
    this.PacketReceived((SurgeMsg)m);
  }

  public  void PacketReceived(SurgeMsg msg) { }

  public  void NodeCreated(NodeEvent e) { }

  public  void NodeDeleted(NodeEvent e) { }

  public  void EdgeCreated(EdgeEvent e) { }

  public  void EdgeDeleted(EdgeEvent e) { }

  public  void NodeClicked(NodeClickedEvent e) { }

  public  void EdgeClicked(EdgeClickedEvent e) { }

  public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g) { }

  public void PaintEdge(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, int screenX1, int screenY1, int screenX2, int screenY2, Graphics g) { }

  public void PaintScreenBefore(Graphics g) { }

  public void PaintScreenAfter(Graphics g) { }

  public ActivePanel GetProprietaryNodeInfoPanel(Integer nodeNumber) { 
    return null;
  }

  public ActivePanel GetProprietaryEdgeInfoPanel(Integer source, Integer destination) {
    return null;
  }

  public void AnalyzerDisplayEnable() {
    MainClass.displayManager.AddScreenPainter(this);//paint on the screen over the edges and nodes

    //register myself to be able to contribute to the node/edge properties panel
    MainClass.displayManager.AddNodeDialogContributor(this);
    MainClass.displayManager.AddEdgeDialogContributor(this);

    MainClass.displayManager.AddNodePainter(this);//paint the nodes
  }

  public void AnalyzerDisplayDisable() {
    MainClass.displayManager.RemoveScreenPainter(this);//paint on the screen over the edges and nodes

    //register myself to be able to contribute to the node/edge properties panel
    MainClass.displayManager.RemoveNodeDialogContributor(this);
    MainClass.displayManager.RemoveEdgeDialogContributor(this);

    MainClass.displayManager.RemoveNodePainter(this);//paint the nodes
  }
}
