// $Id: MotePanel.java,v 1.3 2003/11/17 20:11:33 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Phil Levis
 * Date:        October 11 2002
 * Desc:        Double buffer area and clicking functionaliy.
 *
 */

/**
 * @author Phil Levis
 */


package net.tinyos.sim;

import net.tinyos.sim.event.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.*;

public class MotePanel extends JPanel {

    private TinyViz tv;
    private SimDriver driver;
    private Image doubleBufferImage;
    private Dimension doubleBufferImageSize;
    private Graphics doubleBufferGraphic;
    private MouseHandler mouseHandler;
    
    private SimEventBus eventBus;
    private SimState state;
    
    private Insets insets;
    
    private int xLines = 7;
    private int yLines = 7;
    private int numDashes = 63; // number of dashes in lines
    private boolean gridOn = false;

    private CoordinateTransformer cT;

    private SimObjectPopupMenu popup = null;
    private MouseEvent mouseEvent = null;
    
    public MotePanel(TinyViz tv) {
        this.tv = tv;
        this.driver = tv.getSimDriver();
	this.eventBus = driver.getEventBus();
	this.state = driver.getSimState();
	this.cT = tv.getCoordTransformer();
	mouseHandler = new MouseHandler(this, tv);

	this.setBackground(Color.white);
	this.addMouseListener(mouseHandler);
	this.addMouseMotionListener(mouseHandler);
	
	this.setPreferredSize(new Dimension((int)cT.getWindowWidth(), (int)cT.getWindowHeight()));

	// XXX
	RepaintManager.currentManager(this).setDoubleBufferingEnabled(false);


    }

    public void toggleGrid() {
      synchronized (eventBus) {
	gridOn = !gridOn;
	refresh();
      }
    }

    private void drawDottedLine(Graphics g, int x1, int y1, int x2, int y2) {
	double xDiff = (double)(x2 - x1);
	double yDiff = (double)(y2 - y1);
	double dashes = (double)numDashes;
	
	for (int i = 0; i < numDashes; i+=2) {
	    double index = (double)i;
	    int xStart = (int)((index / dashes) * xDiff + (double)x1);
	    int yStart = (int)((index / dashes) * yDiff + (double)y1);
	    int xEnd   = (int)(((index + 1.0) / dashes) * xDiff + (double)x1);
	    int yEnd = (int)(((index + 1.0) / dashes) * yDiff + (double)y1);
	    
	    g.drawLine(xStart, yStart, xEnd, yEnd);
	}
    }
    
    public void paintGrid(Graphics graphics) {
	graphics.setColor(tv.paleBlue);
	graphics.setFont(tv.smallFont);
	
	//String scaleStr = "Scale: " + cT.getMoteScaleWidth() + "x" + cT.getMoteScaleHeight();
	//graphics.drawString(scaleStr, 2, 10);

	int xTick = (int)(cT.getWindowWidth() / (xLines + 1));
	int yTick = (int)(cT.getWindowHeight() / (yLines + 1));

	// Draw vertical lines
	for (int i = 0; i < xLines; i++) {
	    int xCoord = xTick * (i + 1);
	    graphics.drawLine(xCoord, 10, xCoord, (int)cT.getWindowHeight());
	    //drawDottedLine(graphics, xCoord, 10, xCoord, (int)cT.getWindowHeight());
	    double index = (cT.getMoteScaleWidth() / (double)(xLines + 1)) * (double)(i + 1);
	    String label = "" + index;
	    if (label.length() > 6) {label = label.substring(0,5);}
	    graphics.drawString(label, xCoord-10, 10);
	    
	}

	// Draw horizontal lines
	for (int i = 0; i < yLines; i++) {
	    int yCoord = yTick * (i + 1);
	    graphics.drawLine(0, yCoord, (int)cT.getWindowWidth(), yCoord);
	    //drawDottedLine(graphics, 0, yCoord, (int)cT.getWindowWidth(), yCoord);

	    double index = (cT.getMoteScaleHeight() / (double)(yLines + 1)) * (double)(i + 1);
	    String label = "" + index;
	    if (label.length() > 6) {label = label.substring(0,5);}
	    graphics.drawString(label, 0, yCoord-2);
	}

	// Draw thick vertical line separating grid from rest of gui
	//graphics.fillRect(xTick * (xLines + 1), 0, 40, (int)cT.getWindowWidth());
	
    }
    
    public void paint(Graphics graphics) {

      // Don't want any events to be processed while we are painting
      synchronized (eventBus) {
	if ((popup != null) && (mouseEvent != null)) {
	  //System.out.println("About to call show on PopupMenu");
	  popup.show(mouseEvent.getComponent(), mouseEvent.getX(), mouseEvent.getY());
	  //System.out.println("Done calling show on PopupMenu");
	  mouseEvent = null;
	  popup = null;
	}
	else if ((popup != null) || (mouseEvent != null)) {
	  System.out.println("ERROR WITH POPUP MENUS, synchronization is off!");
	  System.exit(-1);
	}

	//System.out.println("paint in TinyVizDoubleBufferPanel called");
	//Dimension size = getSize();
	//eventBus.enqueuePaintEvent(this);
	Dimension size = getSize();

	if ((doubleBufferImage == null) ||
	    (size.width != doubleBufferImageSize.width) ||
	    (size.height != doubleBufferImageSize.height)) {
	  doubleBufferImage = createImage(size.width, size.height);
	  doubleBufferImageSize = size;
	  cT.setWindowWidth(size.width);
	  cT.setWindowHeight(size.height);
	}

	if (doubleBufferGraphic != null) {
	  doubleBufferGraphic.dispose();
	}

	doubleBufferGraphic = doubleBufferImage.getGraphics();

	//doubleBufferGraphic.setColor(Color.gray);
	doubleBufferGraphic.fillRect(0, 0, (int)size.getWidth(), (int)size.getHeight());
	doubleBufferGraphic.setFont(tv.smallFont);
	super.paint(doubleBufferGraphic);//first paint the panel normally
	if (gridOn) paintGrid(doubleBufferGraphic);
	tv.getPluginPanel().drawPlugins(doubleBufferGraphic);
	mouseHandler.draw(doubleBufferGraphic);
	graphics.drawImage(doubleBufferImage,0,0,this);
      }
    }

    Runnable waitRunnable = new Runnable() {
      public void run() {
	// Do nothing
	return;
      }
    };

    public void refreshAndWait() {
      repaint();
      try {
	SwingUtilities.invokeAndWait(waitRunnable);
      } catch (Exception ie) {
	// Ignore
      }
    }

    public void refresh() {
      repaint();
    }

    public void refresh(SimObjectPopupMenu popup, MouseEvent e) {
	synchronized (eventBus) {
	    this.popup = popup;
	    this.mouseEvent = e;
	    repaint();
	}
    }
    
    public CoordinateTransformer getCoordinateTransformer() {
	return cT;
    }
}

