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

package net.tinyos.gui;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.*;

public class DoubleBufferPanel extends JPanel {

    public static final int MOTE_SIZE = 15;

    private Image doubleBufferImage;
    private Dimension doubleBufferImageSize;
    private Graphics doubleBufferGraphic;
    private BaseGUIPlugin graphicPanel;
    private MouseHandler mouseHandler;
    
    private Insets insets;
    
    private int moteScaleWidth = 100;
    private int moteScaleHeight = 100;
    private int windowWidth = 0;
    private int windowHeight = 0;
    
    private int xLines = 7;
    private int yLines = 7;
    private int numDashes = 63; // number of dashes in lines
    
    public DoubleBufferPanel(BaseGUIPlugin panel, int moteScaleWidth, int moteScaleHeight) {
	this.graphicPanel = panel;
	this.moteScaleWidth = moteScaleWidth;
	this.moteScaleHeight = moteScaleHeight;
	this.insets = getInsets();

	mouseHandler = new MouseHandler(this, panel);
	this.addMouseListener(mouseHandler);
	this.addMouseMotionListener(mouseHandler);
	
	setWindowSize(430, 430);
    }

    public synchronized void setWindowSize(int width, int height) {
	windowWidth = width;
	windowHeight = height;
	setSize(insets.left + insets.right + width,
		insets.top + insets.bottom + height);
	setPreferredSize(new Dimension(insets.left + insets.right + width,
				       insets.top + insets.bottom + height));
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
	graphics.setColor(Color.black);
	
	String scaleStr = "Scale: " + moteScaleWidth + "x" + moteScaleHeight;
	//graphics.drawString(scaleStr, 2, 10);

	int xTick = windowWidth / (xLines + 1);
	int yTick = windowHeight / (yLines + 1);

	// Draw vertical lines
	for (int i = 0; i < xLines; i++) {
	    int xCoord = xTick * (i + 1);
	    drawDottedLine(graphics, xCoord, 10, xCoord, windowHeight);
	    double index = ((double)moteScaleWidth / (double)(xLines + 1)) * (double)(i + 1);
	    String label = "" + index;
	    if (label.length() > 6) {label = label.substring(0,5);}
	    graphics.drawString(label, xCoord-10, 10);
	    
	}

	// Draw horizontal lines
	for (int i = 0; i < yLines; i++) {
	    int yCoord = yTick * (i + 1);
	    drawDottedLine(graphics, 0, yCoord, windowWidth, yCoord);

	    double index = ((double)moteScaleHeight / (double)(yLines + 1)) * (double)(i + 1);
	    String label = "" + index;
	    if (label.length() > 6) {label = label.substring(0,5);}
	    graphics.drawString(label, 0, yCoord-2);
	}
    }
    
    public void paint(Graphics graphics) {
	super.paint(graphics);//first paint the panel normally

	paintGrid(graphics);
	Dimension size = getSize();

	if ((doubleBufferImage == null) ||
	    (size.width != doubleBufferImageSize.width) ||
	    (size.height != doubleBufferImageSize.height)) {

	    doubleBufferImage = createImage(size.width, size.height);
	    doubleBufferImageSize = size;

	    if (doubleBufferGraphic != null) {
		doubleBufferGraphic.dispose();
	    }
	    
	    doubleBufferGraphic = doubleBufferImage.getGraphics();
	    doubleBufferGraphic.setFont(getFont());
	}
	
	doubleBufferGraphic.setColor(Color.white);
	doubleBufferGraphic.fillRect(0, 0, (int)size.getWidth(), (int)size.getHeight());

	Vector motes = graphicPanel.getMotes();
	Enumeration enum = motes.elements();

	while(enum.hasMoreElements()) {
	    Mote mote = (Mote)enum.nextElement();
	    paintNode(graphics, mote);
	}
    }

    public void refresh() {
	repaint();
    }

    protected void paintNode(Graphics graphics, Mote mote) {
	if (!mote.isVisible()) {
	    return;
	}

	graphics.setColor(mote.getColor());
	int x = (int)moteXToPanelX(mote.getX());
	int y = (int)moteYToPanelY(mote.getY());
	graphics.fillOval(x, y, MOTE_SIZE, MOTE_SIZE);

	String id = "" + mote.getID();
	graphics.setColor(Color.black);
	graphics.drawString(id, x, y);
    }

    public double moteXToPanelX(double x) {
	double scaledMoteX = x / (double)moteScaleWidth;
	return (scaledMoteX * (double)windowWidth);
    }

    public double moteYToPanelY(double y) {
	double scaledMoteY = y / (double)moteScaleHeight;
	return (scaledMoteY * (double)windowHeight);
    }

    public double panelXToMoteX(double x) {
	double scaledPanelX = x / (double)windowWidth;
	return scaledPanelX * (double)moteScaleWidth;
    }

    public double panelYToMoteY(double y) {
	double scaledPanelY = y / (double)windowHeight;
	return scaledPanelY * (double)moteScaleWidth;
    }
    
    protected Mote getMote(int windowX, int windowY) {
	Enumeration enum = graphicPanel.getMotes().elements();
	while (enum.hasMoreElements()) {
	    Mote mote = (Mote)enum.nextElement();
	    double moteWinX = moteXToPanelX(mote.getX());
	    double moteWinY = moteYToPanelY(mote.getY());
	    double dx = (double)windowX - moteWinX;
	    double dy = (double)windowY - moteWinY;
	    int distance = (int)Math.sqrt((dx * dx) + (dy * dy));
	    if (distance <= MOTE_SIZE) {
		System.err.println("Selected mote " + mote);
		return mote;
	    }
	}
	return null;
    }

    protected void setMoteXY(Mote mote, int x, int y) {
	mote.setX(panelXToMoteX((double)x));
	mote.setY(panelYToMoteY((double)y));
    }
    
}
