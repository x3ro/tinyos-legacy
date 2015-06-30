/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

// $Id: GraphPanel.java,v 1.1.1.1 2007/11/05 19:10:44 jpolastre Exp $

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
 * File: GraphPanel.java
 *
 * Description:
 * Communicates with SerialForward, receiving packets and displaying
 * the received data graphically.
 *
 * @author Jason Hill and Eric Heien
 */

package com.moteiv.oscope;

import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.awt.geom.*;
import java.io.PrintWriter;
import java.io.FileOutputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
//import java.sql.Time;

public class GraphPanel extends JPanel implements MouseListener, MouseMotionListener {	

    // If true, verbosely report received packet contents

    // If true, log data to a file called LOG_FILENAME
    private static final boolean LOG = false;
    private static final String LOG_FILENAME = "log";

    // Set the number of channels to display and the number of readings
    // per packet.  2 channels and 4 reading means 2 readings per packet
    // per channel.

    private static final double _DEFAULT_BOTTOM = 1024.0;
    private static final double _DEFAULT_TOP = 4096.0-1024.0;
    private static final int _DEFAULT_START = -100;
    private static final int _DEFAULT_END = 1000;
    private static final double X_AXIS_POSITION = 0.1;
    private static final double Y_AXIS_POSITION = 0.1;

    private double DEFAULT_BOTTOM;
    private double DEFAULT_TOP;
    private int DEFAULT_START;
    private int DEFAULT_END;
    boolean sliding = true;
    boolean legendEnabled = true;
    boolean connectPoints = true;
    boolean valueTest = false;
    int valueX, valueY;
    Channel testChannel = null;
    boolean hexAxis = false;

    public boolean isConnectPoints() {
	return connectPoints;
    } 

    public void setConnectPoints(boolean b) { 
	connectPoints = b;
	repaint(100); 
    }
	

    /**
     * Get the type of ticks on the Y axis (hexadecimal or decimal).
     * @return the HexAxis value.
     */
    public boolean isHexAxis() {
	return hexAxis;
    }

    /**
     * Set the display of the Y axis (hexadecimal or decimal)
     * @param newHexAxis The new HexAxis value.
     */
    public void setHexAxis(boolean newHexAxis) {
	this.hexAxis = newHexAxis;
	repaint(100);
    }

    public boolean isSliding() { 
	return sliding;
    } 

    public void setSliding(boolean _sliding) { 
	sliding = _sliding;
	repaint(100);
    }
    /**
     * Get the LegendEnabled value.
     * @return the LegendEnabled value.
     */
    public boolean isLegendEnabled() {
	return legendEnabled;
    }

    /**
     * Set the LegendEnabled value.
     * @param newLegendEnabled The new LegendEnabled value.
     */
    public void setLegendEnabled(boolean newLegendEnabled) {
	this.legendEnabled = newLegendEnabled;
	repaint(100);
    }

    String xLabel;

    /**
     * Get the XLabel value.
     * @return the XLabel value.
     */
    public String getXLabel() {
	return xLabel;
    }

    /**
     * Set the XLabel value.
     * @param newXLabel The new XLabel value.
     */
    public void setXLabel(String newXLabel) {
	this.xLabel = newXLabel;
    }

    String yLabel;

    /**
     * Get the YLabel value.
     * @return the YLabel value.
     */
    public String getYLabel() {
	return yLabel;
    }

    /**
     * Set the YLabel value.
     * @param newYLabel The new YLabel value.
     */
    public void setYLabel(String newYLabel) {
	this.yLabel = newYLabel;
    }

    

    
    //output stream for logging the data to.
    PrintWriter log_os;

    double bottom, top;
    int start, end;
    int maximum_x = 0, minimum_x = Integer.MAX_VALUE;
    Vector cutoff; 
    Point highlight_start, highlight_end;

    Vector channels;
    
    public GraphPanel() {
	this(_DEFAULT_START, _DEFAULT_BOTTOM, _DEFAULT_END, _DEFAULT_TOP);
    }

    public GraphPanel(int _start, double _bottom, int _end, double _top) { 
	super();
	setBackground(Color.white);
	addMouseListener(this);
	addMouseMotionListener(this);
	cutoff = new Vector();
	//create an array to hold the data sets.
	channels = new Vector();

	try{
	  //create a file for logging data to.
	  FileOutputStream f = new FileOutputStream(LOG_FILENAME);
	  log_os = new PrintWriter(f);
	} catch (Exception e) {
	  e.printStackTrace();
	}
	DEFAULT_BOTTOM = _bottom;
	bottom = _bottom;
	DEFAULT_TOP = _top;
	top = _top;
	DEFAULT_START = _start;
	start = _start; 
	DEFAULT_END = _end;
	end = _end;
    }

    public int getEnd() { 
	return end;
    }
    
    public int getStart() {
	return start;
    }

    public void setXBounds(int _start, int _end) {
	start = _start;
	end = _end;
    }
    
    public void addChannel(Channel c) { 
	channels.add(c);
    }
    
    public void removeChannel(Channel c) {
	channels.remove(c);
    }

    public Vector getChannels() {
	return (Vector)channels.clone();// return a copy rather than the object
    }

    public int getNumChannels() { 
	return channels.size();
    }

    public Channel getChannel(int numChannel) { 
	return (Channel)channels.elementAt(numChannel); 
    }
    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
    }

    /* Select a view rectangle. */
    public void mouseDragged(MouseEvent e) {
      Dimension d = getSize();

      if (valueTest) {
	Point2D virt_drag = screenToVirtual(new Point2D.Double(e.getX(), e.getY()));
	Point2D dp = findNearestX(testChannel, virt_drag);
	if (dp != null) {
	    valueX = (int)Math.round(dp.getX());
	    valueY = (int)Math.round(dp.getY());
	}

      } else if (highlight_start != null) {
	highlight_end.x = e.getX();
     	highlight_end.y = e.getY();
      }
      repaint(100);
      e.consume();
    }

    public void mouseMoved(MouseEvent e) {
    }

    public void mouseClicked(MouseEvent e) {
    }

    /* Set zoom to selected rectangle. */
    public void mouseReleased(MouseEvent e) {
	removeMouseMotionListener(this);
	if( highlight_start != null )
	    set_zoom();
	valueTest = false;
	testChannel = null;
	highlight_start = null;
	highlight_end = null;
	e.consume();
	repaint(100);
    }

    public void mousePressed(MouseEvent e) {
      addMouseMotionListener(this);

      // Check to see if mouse clicked near plot
      Dimension d = getSize();
      double  xVal,yVal;
      Point2D virt_click = screenToVirtual(new Point2D.Double(e.getX(), e.getY()));
      for(Enumeration i = channels.elements(); i.hasMoreElements();) {
	  Channel data = (Channel) i.nextElement();
	  Point2D dp = findNearestX(data, virt_click);
	  if (dp != null) {
	      if (Math.abs(dp.getY() - virt_click.getY()) <= (top-bottom)/10) {
		  valueTest = true;
		  testChannel = data;
		  valueX = (int)dp.getX();
		  valueY = (int)dp.getY();
	      }
	  }
      }

      if (!valueTest) {
	highlight_start = new Point();
	highlight_end = new Point();
	highlight_start.x = e.getX();
	highlight_start.y = e.getY();
	highlight_end.x = e.getX();
	highlight_end.y = e.getY();
      }
      repaint(100);
      e.consume();
    }

    public void start() {
    }

    public void stop() {
    }

    //double buffer the graphics.
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;


    public synchronized void paintComponent(Graphics g) {
	//get the size of the window.
	super.paintComponent(g);
	Graphics2D g2d = (Graphics2D) g;
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                             RenderingHints.VALUE_ANTIALIAS_ON);	
	Dimension d = getSize();
	//get the end value of the window.
	int end = this.end;
	
	//blank the screen.
	g2d.setColor(Color.black);
	g2d.fillRect(0, 0, d.width, d.height);

	// Draw axes
	Point2D origin;

	// Prevent tics from being too small
	double xTicSpacing = Math.ceil((end - start)/25.03);
	double yTicSpacing = Math.ceil((top - bottom)/13.7); 
	origin = new Point2D.Double(Math.floor(start + ((end - start) * X_AXIS_POSITION)), 
				    Math.floor(bottom + ((top - bottom) * Y_AXIS_POSITION)));

	
	Color xColor,yColor;
	xColor = Color.white;
	yColor = Color.white;

	drawGridLines(g2d, origin, xTicSpacing, yTicSpacing);
	drawAxisAndTics(g2d, origin, start, end, top, bottom, xTicSpacing, yTicSpacing, xColor, yColor);

	//draw the highlight box if there is one.
	draw_highlight(g2d);

	//draw the input channels.
	for (Enumeration i = channels.elements(); i.hasMoreElements(); ) {
	    Channel c = (Channel) i.nextElement();
	    if (c.isActive()) {
		//		System.out.println("Plotting data for channel "+c.getDataLegend());
		
		g2d.setColor(c.getPlotColor());
		draw_data(g2d, c, start, end);
	    }
	}
	// Draw the value tester line if needed
	if (valueTest) {
          g2d.setFont(new Font("Default", Font.PLAIN, 12));
	  g2d.setColor(new Color((float)0.9, (float)0.9, (float)1.0));
	  Point2D vt = virtualToScreen(new Point2D.Double((double)valueX, (double)valueY));
	  g2d.drawLine((int)vt.getX(), 0, (int)vt.getY(), d.height);
	  g2d.drawRect((int)vt.getX() - 3, (int)vt.getY() - 3, 6, 6);
	  if (isHexAxis()) {
	      g2d.drawString("["+valueX+",0x"+Integer.toHexString(valueY)+"]", (int)vt.getX()+15, (int)vt.getY()-15);
	  } else {
	      g2d.drawString("["+valueX+","+valueY+"]", (int)vt.getX()+15, (int)vt.getY()-15);
	  }
	}

	drawLegend(g2d);
 
	//transfer the constructed image to the screen.
	//	g.drawImage(offscreen, 0, 0, null); 
    }

    // Draw the grid lines
    void drawGridLines(Graphics offgraphics, Point2D origin, 
	double xTicSpacing, double yTicSpacing ) {

      offgraphics.setColor(new Color((float)0.2, (float)0.6, (float)0.2));

      int i = 0;

      Point2D.Double virt, screen;

      virt = (Point2D.Double) origin.clone();//new Point2D(origin.x, origin.y);
      screen = virtualToScreen(virt);
      while (screen.x < getSize().width) {
	offgraphics.drawLine((int)screen.x, 0, (int)screen.x, getSize().height);
	virt.setLocation(virt.getX()+xTicSpacing,virt.getY());
	screen = virtualToScreen(virt);
      }
      virt =  (Point2D.Double) origin.clone();
      screen = virtualToScreen(virt);
      while (screen.x >= 0) {
	offgraphics.drawLine((int)screen.x, 0, (int)screen.x, getSize().height);
	virt.setLocation(virt.getX() - xTicSpacing, virt.getY());
	screen = (Point2D.Double)virtualToScreen(virt);
      }

      virt =  (Point2D.Double) origin.clone();
      screen = (Point2D.Double)virtualToScreen(virt);
      while (screen.y < getSize().height) {
	offgraphics.drawLine(0, (int)screen.y, getSize().width, (int)screen.y);
	virt.setLocation(virt.getX(), virt.getY() - yTicSpacing);
	screen = (Point2D.Double)virtualToScreen(virt);
      }
      virt =  (Point2D.Double) origin.clone();
      screen =   (Point2D.Double)virtualToScreen(virt);
      while (screen.y >= 0) {
	offgraphics.drawLine(0, (int)screen.y, getSize().width, (int)screen.y);
	virt.setLocation(virt.getX(), virt.getY() + yTicSpacing);
	screen =   (Point2D.Double)virtualToScreen(virt);
      }
    }

    void drawAxisAndTics(Graphics offgraphics, Point2D origin, 
			 int start, int end, double top, double bottom, 
			 double xTicSpacing, double yTicSpacing, 
			 Color xColor, Color yColor) {

	int i;

	// Draw axis lines
	Point2D origin_screen = virtualToScreen(origin);
	offgraphics.setColor(xColor);
	offgraphics.drawLine(0, (int)origin_screen.getY(), getSize().width, (int)origin_screen.getY());
	offgraphics.setColor(yColor);
	offgraphics.drawLine((int)origin_screen.getX(), 0, (int)origin_screen.getX(), getSize().height);


	// Draw the tic marks and numbers
	offgraphics.setFont(new Font("Default", Font.PLAIN, 10));
	offgraphics.setColor(yColor);

	Point2D virt, screen;
	boolean label;

	// Y axis
	label = true;
	virt = (Point2D) origin.clone();//new Point2D(origin.getX(), origin.y);
	screen = virtualToScreen(virt);
	while (screen.getY() < getSize().height) {
	    offgraphics.drawLine((int)screen.getX() - 5, (int)screen.getY(), (int)screen.getX() + 5, (int)screen.getY());
	    if (label) {
		String tickstr;
		int xsub;
		if (isHexAxis()) {
		    int tmp = (int)(virt.getY());
		    tickstr = "0x"+Integer.toHexString(tmp);
		    xsub = 40;
		} else {
		    tickstr = new Double(virt.getY()).toString();
		    xsub = 25;
		}
		offgraphics.drawString(tickstr, (int)screen.getX()-xsub, (int)screen.getY()-2);
		label = false;
	    } else {
		label = true;
	    }
	    virt.setLocation(virt.getX(), virt.getY() - yTicSpacing);
	    screen = virtualToScreen(virt);
	}

	label = false;
	virt = new Point2D.Double(origin.getX(), origin.getY() + yTicSpacing);
	screen = virtualToScreen(virt);
	while (screen.getY() >= 0) {
	    offgraphics.drawLine((int)screen.getX() - 5, (int)screen.getY(), (int)screen.getX() + 5, (int)screen.getY());
	    if (label) {
		String tickstr;
		int xsub;
		if (isHexAxis()) {
		    int tmp = (int)(virt.getY());
		    tickstr = "0x"+Integer.toHexString(tmp);
		    xsub = 40;
		} else {
		    tickstr = new Double(virt.getY()).toString();
		    xsub = 25;
		}
		offgraphics.drawString(tickstr, (int)screen.getX()-xsub, (int)screen.getY()-2);
		label = false;
	    } else {
		label = true;
	    }
	    virt.setLocation(virt.getX(), virt.getY() + yTicSpacing);
	    screen = virtualToScreen(virt);
	}

	// X axis
	label = true;
	virt = (Point2D)origin.clone();//new Point2D(origin.getX(), origin.getY());
	screen = virtualToScreen(virt);
	while (screen.getX() < getSize().width) {
	    offgraphics.drawLine((int)screen.getX(), (int)screen.getY() - 5, (int)screen.getX(), (int)screen.getY() + 5);
	    if (label) {
		String tickstr = new Double(virt.getX()).toString();
		offgraphics.drawString(tickstr, (int)screen.getX()-15, (int)screen.getY()+15);
		label = false;
	    } else {
		label = true;
	    }
	    virt.setLocation(virt.getX()+ xTicSpacing, virt.getY());
	    screen = virtualToScreen(virt);
	}

	label = false;
	virt = new Point2D.Double(origin.getX() - xTicSpacing, origin.getY());
	screen = virtualToScreen(virt);
	while (screen.getX() >= 0) {
	    offgraphics.drawLine((int)screen.getX(), (int)screen.getY() - 5, (int)screen.getX(), (int)screen.getY() + 5);
	    if (label) {
		String tickstr = new Double(virt.getX()).toString();
		offgraphics.drawString(tickstr, (int)screen.getX()-15, (int)screen.getY()+15);
		label = false;
	    } else {
		label = true;
	    }
	    virt.setLocation(virt.getX() - xTicSpacing, virt.getY());
	    screen = virtualToScreen(virt);
	}
      
	Graphics2D g2d = (Graphics2D) offgraphics;
	AffineTransform at = g2d.getTransform();
	Font f = g2d.getFont();
	offgraphics.setFont(new Font("Default", Font.BOLD, 12));
	FontMetrics fm = g2d.getFontMetrics();
	screen = virtualToScreen((Point2D) origin); 
	if (getYLabel() != null) { 
	    int lWidth = fm.stringWidth(getYLabel());
	    int ypos = (int) (screen.getY() + lWidth)/2 ;
	    int xpos = (int) (screen.getX() - 30 - fm.getHeight()/2);
	    //	    System.out.println("XPosition: " + xpos+ "YPosition"+ypos);
	    AffineTransform at1 = new AffineTransform();
	    at1.setToRotation(-Math.PI/2.0, xpos, ypos);
	    g2d.setTransform(at1);
	    g2d.drawString(getYLabel(), xpos, ypos);
	}
	g2d.setTransform(at);

	if (getXLabel() != null) { 
	    int lWidth = fm.stringWidth(getXLabel());
	    int xpos = (int) (screen.getX() + getWidth() -lWidth)/2;
	    int ypos = (int) (screen.getY() + fm.getHeight()/2 + 30);
	    g2d.drawString(getXLabel(), xpos, ypos);
	}
	g2d.setFont(f);
    }


    void drawLegend( Graphics offgraphics ) {
	Channel c;
	Graphics2D g2d = (Graphics2D) offgraphics;
	// Draw the legend
	if( isLegendEnabled() ) {
	    FontMetrics fm = g2d.getFontMetrics();
	    int width = 10; 
	    int _width;
	    int activeChannels=0,curChan=0;
	    for (Enumeration i = channels.elements(); i.hasMoreElements(); ) {
		c = (Channel)i.nextElement();
		if (c.isActive()) {
		    activeChannels++;
		    _width = fm.stringWidth(c.getDataLegend());
		    if (_width > width) 
			width = _width;

		}
	    }
	  
	    if( activeChannels == 0 )
		return;
	    
	    int h = fm.getHeight();
	    activeChannels++; //add a font height to the legend box.
	    
	    offgraphics.setColor(Color.black);
	    offgraphics.fillRect( getSize().width-20-40-width, getSize().height-20-h*activeChannels, width+40, h*activeChannels );
	    offgraphics.setColor(Color.white);
	    offgraphics.drawRect( getSize().width-20-40-width, getSize().height-20-h*activeChannels, width+40, h*activeChannels );
	    Line2D l = new Line2D.Double();
	    for (Enumeration i = channels.elements(); i.hasMoreElements(); ) {
		c = (Channel) i.nextElement();
		if( c.isActive() ) {
		    offgraphics.setColor(Color.white);
		    offgraphics.drawString( c.getDataLegend(), getSize().width-20-10-width, getSize().height-20 - h/2-h*curChan );
		    offgraphics.setColor(c.getPlotColor());
		    g2d.setStroke(c.getPlotStroke());
		    l.setLine(getSize().width-20-35-width, getSize().height-20-h*(curChan+1)+h/4, getSize().width-20-15-width, getSize().height-20-h*(curChan+1)+h/4);
		    g2d.draw( l  );
		    curChan++;
		}
	    }
	}
    }

    //return the difference between the two input vectors.

    Vector diff(Iterator a, Iterator b){
	Vector vals = new Vector();
	while(a.hasNext() && b.hasNext()){
	    vals.add(new Double((((Double)b.next()).doubleValue() - ((Double)a.next()).doubleValue())));
	}
	return vals;
    }

    //draw the highlight box.
    void draw_highlight(Graphics g){
    	if(highlight_start == null) return;
	int x, y, h, l;
	x = Math.min(highlight_start.x, highlight_end.x);
	y = Math.min(highlight_start.y, highlight_end.y);
	l = Math.abs(highlight_start.x - highlight_end.x);
	h = Math.abs(highlight_start.y - highlight_end.y);
	g.setColor(Color.white);
	g.fillRect(x,y,l,h);
    }


    void draw_data(Graphics g, Channel data, int start, int end){
    	draw_data(g,data, start, end, 1);
    }

    //scale multiplies a signal by a constant factor.
    void draw_data(Graphics g, Channel _data, int start, int end, int scale){
      Point2D screen = null, screen2 = null;
      boolean noplot=true;  // Used for line plotting
      Vector data = _data.getData();
      //      System.out.println("Will plot " + data.size() +" points");
      Graphics2D g2d = (Graphics2D) g;
      Stroke savedStroke = g2d.getStroke();
      g2d.setStroke(_data.getPlotStroke());
      for(int i = 0; i < data.size(); i ++){
	Point2D virt;
	Line2D l = new Line2D.Double();
	//map each point to a x,y position on the screen.
	if((virt = (Point2D)data.get(i)) != null) {
	  screen = virtualToScreen(virt);
	  if (screen.getX() >= 0 && screen.getX() < getSize().width) {
	      if(connectPoints && !noplot) {
		  l.setLine(screen, screen2); 
		  g2d.draw(l);
		  //	      g.drawLine((int)screen2.getX(),
		  //	      (int)screen2.getY(), (int)screen.getX(),
		  //	      (int)screen.getY());
	      }
	    else if( !connectPoints )
	      g.drawRect((int)screen.getX(), (int)screen.getY(), 1, 1);
	    if (noplot) noplot = false;
	  } else {
	    noplot = true;
	  }
	}
	screen2 = screen;
      }
      g2d.setStroke(savedStroke);
    }

    //functions for controlling zooming.
    void move_up(){
	double height = top - bottom;
	bottom += height/4;
	top += height/4;

    }

    void move_down(){
	double height = top - bottom;
	bottom -= height/4;
	top -= height/4;

    }

    void move_right(){
	int width = end - start;
	start += width/4;
	end += width/4;

    }

    void move_left(){
	int width = end - start;
	start -= width/4;
	end -= width/4;

    }

    void zoom_out_x(){
	int width = end - start;
	start -= width/2;
	end += width/2;
    }

    void zoom_out_y(){
	double height = top - bottom;
	bottom -= height/2;
	top += height/2;
    }

    void zoom_in_x(){
	int width = end - start;
	start += width/4;
	end -= width/4;
    }

    void zoom_in_y(){
	double height = top - bottom;
	bottom += height/4;
	top -= height/4;
    }

    void reset(){
	bottom = DEFAULT_BOTTOM;
	top = DEFAULT_TOP;
	start = DEFAULT_START; 
	end = DEFAULT_END;
    }



    void set_zoom(){
	int base = getSize().height;
	int x_start = Math.min(highlight_start.x, highlight_end.x);
	int x_end = Math.max(highlight_start.x, highlight_end.x);
	int y_start = Math.min(highlight_start.y, highlight_end.y);
	int y_end = Math.max(highlight_start.y, highlight_end.y);
	
	if(Math.abs(x_start - x_end) < 10) return;
	if(Math.abs(y_start - y_end) < 10) return;

	Point2D topleft = screenToVirtual(new Point2D.Double((double)x_start, (double)y_start));
	Point2D botright = screenToVirtual(new Point2D.Double((double)x_end, (double)y_end));

	start = (int)topleft.getX();
	end = (int)botright.getX();
	top = topleft.getY();
	bottom = botright.getY();
    }

    /** Convert from virtual coordinates to screen coordinates. */
    Point2D.Double virtualToScreen(Point2D virt) {
	double xoff = virt.getX() - start;
	double xpos = xoff / (end*1.0 - start*1.0);
	double screen_xpos = xpos * getSize().width;

	double yoff = virt.getY() - bottom;
	double ypos = yoff / (top*1.0 - bottom*1.0);
	double screen_ypos = getSize().height - (ypos * getSize().height);

	return new Point2D.Double(screen_xpos, screen_ypos);
    }

    /** Convert from screen coordinates to virtual coordinates. */
    Point2D screenToVirtual(Point2D screen) {
	double xoff = screen.getX();
	double xpos = xoff / (getSize().width * 1.0);
	double virt_xpos = start + (xpos * (end*1.0 - start*1.0));

	double yoff = screen.getY();
	double ypos = yoff / (getSize().height * 1.0);
	double virt_ypos = top - (ypos * (top*1.0 - bottom*1.0));

	return new Point2D.Double(virt_xpos, virt_ypos);
    }

    /** Find nearest point in 'data' to x-coordinate of given point. */
    Point2D findNearestX(Channel data, Point2D test) {
	return data.findNearestX(test);
    }

    public void clear_data() {
	int i;
	for (Enumeration e = channels.elements(); e.hasMoreElements(); ) { 
	    Channel c = (Channel) e.nextElement();
	    c.clear();
	}
    }

    void save_data() {
	JFileChooser	file_chooser = new JFileChooser();
	File		savedFile;
	FileWriter	dataOut;
	int		retval,i,n;

	retval = file_chooser.showSaveDialog(null);
	if( retval == JFileChooser.APPROVE_OPTION ) {
	    try {
		savedFile = file_chooser.getSelectedFile();
		System.out.println( "Saved file: "+savedFile.getName() );
		dataOut = new FileWriter( savedFile );
		dataOut.write( "# Test Data File\n" );
		dataOut.write( "# "+(new Date())+"\n" );
		for (Enumeration e = channels.elements(); e.hasMoreElements(); ) {
		    Channel c =(Channel) e.nextElement();
		    c.saveData(dataOut);
		}
		dataOut.close();
	    } catch( IOException e ) {
		System.out.println( e );
	    }
	}
    }
    
    
}
