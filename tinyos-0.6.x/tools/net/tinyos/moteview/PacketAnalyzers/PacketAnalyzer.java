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

package net.tinyos.moteview.PacketAnalyzers;

import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.util.*;
import java.util.*;
import java.lang.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.moteview.Dialog.*;
import java.io.*;
import java.util.zip.*;

public class PacketAnalyzer implements net.tinyos.moteview.event.PacketEventListener, NodeClickedEventListener, EdgeClickedEventListener, NodeEventListener, EdgeEventListener, NodePainter, EdgePainter, ScreenPainter, NodeDialogContributor, EdgeDialogContributor//, java.io.Serializable
{
	public PacketAnalyzer()
	{
				//register myself to recieve PacketEvents
		MainClass.AddPacketEventListener(this);

	}

    public  void PacketRecieved(PacketEvent e)
    {
    }

	public  void NodeCreated(NodeEvent e)
    {
    }

    public  void NodeDeleted(NodeEvent e)
    {
    }

	public  void EdgeCreated(EdgeEvent e)
    {
    }

    public  void EdgeDeleted(EdgeEvent e)
    {
    }

    public  void NodeClicked(NodeClickedEvent e)
    {
    }

    public  void NodeDragged(NodeDraggedEvent e)
    {
    }

    public  void EdgeClicked(EdgeClickedEvent e)
    {
    }

	public void PaintNode(Integer pNodeNumber, int x1, int y1, int x2, int y2, Graphics g)
	{
	}

	public void PaintEdge(Integer pSourceNodeNumber, Integer pDestinationNodeNumber, int screenX1, int screenY1, int screenX2, int screenY2, Graphics g)
	{
	}

	public void PaintScreenBefore(Graphics g)
	{
	}

	public void PaintScreenAfter(Graphics g)
	{
	}

	public ActivePanel GetProprietaryNodeInfoPanel(Integer nodeNumber)
	{
		return null;
	}

	public ActivePanel GetProprietaryEdgeInfoPanel(Integer source, Integer destination)
	{
		return null;
	}

	public ActivePanel GetOptionsPanel(){return null;}

}