// $Id: YieldInfoPanel.java,v 1.2 2004/02/24 22:14:13 jlhill Exp $

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



    public class YieldInfoPanel extends JPanel
    {
	NodeInfo nodeInfo;
	public YieldInfoPanel(NodeInfo pNodeInfo)
	{
	    nodeInfo = pNodeInfo;
	    setSize(100,100);
	}
   
	public void update(Graphics g)
	{ 
  	  paint(g);
	}
	  
	  public void repaint(Graphics g)
	{
  	  paint(g);
	}


        public void paint(Graphics g)
	{
		Dimension d = getSize();
		int count;
		if(nodeInfo.yieldHistory[nodeInfo.yieldHistory.length -1] != 0) count = nodeInfo.yieldHistory.length;
		else count = nodeInfo.yieldHistoryPointer;
		double width = ((double)(d.width))/(double)count;
		double height = (double)(d.height);	
		g.setColor(Color.white);
		g.fillRect(0, 0, d.width, d.height);
		g.setColor(Color.red);
		double place = 0;
		int last_value = 0xfff;
		int last_x = 0;
		for(double i = nodeInfo.yieldHistory.length - count; i < nodeInfo.yieldHistory.length; i ++){ 
			int j = (int)width;
			double yield = nodeInfo.yieldHistory[((nodeInfo.yieldHistoryPointer  + (int)i)%nodeInfo.yieldHistory.length)];
			int value = (int)(height * (1.0 - yield));
			if(last_value == 0xfff) last_value = value;
			g.drawLine(last_x, last_value, (int)((place + 1.0) * width), value); 
			last_x = (int)(place * width);
			System.out.println(width + "" );
			last_value = value;
			//System.out.println(i + " " + ((nodeInfo.yieldHistoryPointer  + (int)i)%nodeInfo.yieldHistory.length) + " " + count + " " + place + " " + yield);
			place ++;
		}
        }
    }

