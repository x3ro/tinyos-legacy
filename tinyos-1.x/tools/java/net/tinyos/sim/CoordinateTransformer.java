// $Id: CoordinateTransformer.java,v 1.3 2003/10/07 21:46:03 idgay Exp $

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
 * Desc:        Coordinate Transformer from GUI to Sim coordinates
 *              and vice versa
 *
 */

/**
 * @author Phil Levis
 */

package net.tinyos.sim;

public class CoordinateTransformer {
    private double moteScaleWidth = 100;
    private double moteScaleHeight = 100;
    private double windowWidth = 0;
    private double windowHeight = 0;
    
    public CoordinateTransformer(int moteScaleWidth, int moteScaleHeight, int windowWidth, int windowHeight) {
	this.moteScaleWidth = moteScaleWidth;
	this.moteScaleHeight = moteScaleHeight;
	this.windowWidth = windowWidth;
	this.windowHeight = windowHeight;	
    }

    public synchronized void setMoteScaleWidth(double moteScaleWidth) {
	this.moteScaleWidth = moteScaleWidth;
    }
    
    public synchronized void setMoteScaleHeight(double moteScaleHeight) {
	this.moteScaleHeight = moteScaleHeight;
    }
    
    public synchronized void setWindowWidth(double windowWidth) {
	this.windowWidth = windowWidth;
    }

    public synchronized void setWindowHeight(double windowHeight) {
	this.windowHeight = windowHeight;
    }

    public synchronized double getMoteScaleWidth() {
	return moteScaleWidth;
    }
    
    public synchronized double getMoteScaleHeight() {
	return moteScaleHeight;
    }
    
    public synchronized double getWindowWidth() {
	return windowWidth;
    }

    public synchronized double getWindowHeight() {
	return windowHeight;
    }

    public synchronized double simXToGUIX(double x) {
	double scaledMoteX = x / (double)moteScaleWidth;
	return (scaledMoteX * (double)windowWidth);
    }
    
    public synchronized double simYToGUIY(double y) {
	double scaledMoteY = y / (double)moteScaleHeight;
	return (scaledMoteY * (double)windowHeight);
    }
    
    public synchronized double guiXToSimX(double x) {
	double scaledPanelX = x / (double)windowWidth;
	return scaledPanelX * (double)moteScaleWidth;
    }
    
    public synchronized double guiYToSimY(double y) {
	double scaledPanelY = y / (double)windowHeight;
	return scaledPanelY * (double)moteScaleWidth;
    }
    
    

    
}
