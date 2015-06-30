package net.tinyos.tinydb;

import ptolemy.plot.*;
import java.util.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class ResultGraph extends Plot {
    int lineWidth = 1;
    
    public ResultGraph(int lineWidth) {
	setSize(540,550);
	setVisible(true);
	this.lineWidth = lineWidth;
	_setPadding(.1);
    }

    public void addKey(int id, String label) {
      addLegend(id, label);
    }

    public void addPoint(int id, double time, int value) {
      addPoint(id, time, (double)value, true);
      repaint();
    }

    protected void _drawLine(java.awt.Graphics g,
			     int dataset,
			     long startx,
			     long starty,
			     long endx,
			     long endy,
			     boolean clip) 
    {
	Graphics2D g2d = null;
	Stroke oldStroke = null;

	if (g instanceof Graphics2D) {
	    g2d = (Graphics2D)g;
	    oldStroke = g2d.getStroke();
	    g2d.setStroke(new BasicStroke((float)lineWidth));
	}

	super._drawLine(g,dataset,startx,starty,endx,endy,clip);

	if (g instanceof Graphics2D) {
	    g2d.setStroke(oldStroke);
	}
    }

}
