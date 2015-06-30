// $Id: PlotStreamPanel.java,v 1.3 2004/02/24 22:49:10 jlhill Exp $

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



    public class PlotStreamPanel extends JPanel
    {
	DataSeries data;
	String text;
	double max;
	double min;
	int max_seen = -1;
	int min_seen = 0;
	public PlotStreamPanel(String text, DataSeries data, double max, double min)
	{
	    this.data = data;
	    this.text = text;
	    this.max = max;
	    this.min = min;
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
		try{
		Dimension d = getSize();
		g.setColor(Color.white);
		g.fillRect(100, 00, d.width, d.height);
		g.setColor(Color.black);
		g.drawString(text, 5, 30);
		g.drawLine(67, 0, d.width, 0);
		g.drawLine(67, d.height-1, d.width,d.height-1);
		g.drawLine(100, 0, 100, d.height - 1);
		g.drawLine(d.width-1, 0, d.width-1, d.height - 1);
		g.setColor(Color.red);
		double x_map = ((double)d.width - 100)/(double)data.getLength();
		double y_map = ((double)d.height)/256.0;
		int y_buf = 0;
		int y_buf_max = 0;
		if(max_seen != -1){
			double dist = 10+max_seen - min_seen;
			if(dist > 256.0) dist = 256.0;
			y_map *= 256.0/dist;
			y_buf = min_seen;
			if(y_buf > 5) y_buf -= 5;
			else y_buf = 0;
			y_buf_max = (int)dist + y_buf;
		}
		int start = data.getStartSequenceNumber();
		int place = -1;
	 	int last_x_val = 100;
		int last_y_val = 0xfff;
		int value = 0;
		for(int i = 0; i < 1000; i ++){
			place = data.getSequenceNumber(i);
			if (place == -1) {
				i = 4000;
			}else{
			value = ((Integer)data.getValue(i)).intValue();
			int plot_value = value;
			if(max_seen == -1) max_seen = min_seen = value;
			if(value > max_seen) max_seen = value;
			if(value < min_seen) min_seen = value;
			plot_value -= (int)y_buf;
			place -= start;
			int y_val = (int)(((double)plot_value)*y_map);
			int x_val = (int)(((double)place + 1.0)*x_map) + 100;
			if(last_y_val == 0xfff) last_y_val = y_val;
			g.drawLine(last_x_val, d.height - last_y_val, x_val, d.height - y_val); 
			last_x_val = x_val;
			last_y_val = y_val;
			}
		}
		String output = new String(((((double)(value)) / 256.0 * (max- min)) + min) + "");
		String y_max = new String(((((double)(y_buf_max)) / 256.0 * (max- min)) + min) + "");
		String y_min = new String(((((double)(y_buf)) / 256.0 * (max- min)) + min) + "");

		if(output.length() > 5) output = output.substring(0, 5);
		if(y_max.length() > 5) y_max = y_max.substring(0, 5);
		if(y_min.length() > 5) y_min = y_min.substring(0, 5);
		g.setColor(Color.black);
		g.drawString(output, 5, 45);
		g.drawString(y_max + "" , 67, 12);
		g.drawString(y_min + "" , 67, 55);
		
	}catch(Exception e){
	}
			
    }
}
