/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Gyorgy Balogh, Gabor Pap, Miklos Maroti
 * Date last modified: 02/09/04
 */

package net.tinyos.prowler;

import java.awt.Canvas;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Frame;
import java.awt.Graphics;
import java.awt.Image;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;

/**
 * Inherited from java.awt.Frame this class controls the graphical output of our
 * experiments. Basically it provides a white background on which we can draw
 * network topology related graphs. See {@link TestBroadcastNode}.
 * 
 * @author Gyorgy Balogh, Gabor Pap, Miklos Maroti
 */
public class Display extends Frame{  

	/** 
	 * The display holds a reference to the simulator, so that it can call its
	 * display function. 
	 */
    protected Simulator  sim    = null;
    
    /** The convas on which we draw. */
    protected DispCanvas canvas = null;        

	/** The size of the displayed area in pixels. */
    protected Dimension  dim    = null;

	/** The size of the displayed area in meters. */
    protected double     width;

    protected Graphics   currentGraphics = null;

	/**
	 * 
	 * Inner class DispCanvas. Draws a white background, draws all the nodes and 
	 * also displays the time and the number of remaining events in the upper
	 * left corner.
	 * 
	 * @author Gabor Pap (gabor.pap@vanderbilt.edu)
	 */    
    class DispCanvas extends Canvas{

        public void paint( Graphics g ){           
            re_display( g );            
        }

        public void update( Graphics g ){
            re_display( g );
        }                   

        public void re_display( Graphics g ){       
            int i,j;
            dim = getSize();
            Image offscreen = createImage(dim.width,dim.height);
            Graphics b = offscreen.getGraphics();
            
            currentGraphics = b; 

            // paint background
            b.setColor( Color.white );
            b.fillRect( 0, 0, dim.width, dim.height );
                        
            // draw nodes                    
            if( sim != null ){               
                sim.display(Display.this);                  
            }
            
            // write time, eventnum
            b.setColor( Color.black );
            b.drawString( "time:" + Double.toString( sim.getSimulationTimeInMillisec()/1000.0 ), 16, 16 );
            b.drawString( "event num:" + Integer.toString(sim.eventQueue.size()), 100, 16 );

            g.drawImage(offscreen,0,0,this);
        }                
    }
    
    /**
     * A parameterized constructor of the Display class, creates a 800 by 800
     * square shaped area on the screen.
     * 
     * @param sim 
     * @param width the size of the area in meters
     */
    public Display( Simulator sim, double width ){
        super();
        this.width = width;
        setSize( 800, 800 );

        addWindowListener( new WindowAdapter() 
            {
                public void windowClosing(WindowEvent we){
                   System.exit(0);
                }
            }
        );
        this.sim = sim;
        canvas = new DispCanvas();          
        add( canvas ); 

        setTitle("Prowler"); 
    }
    
    /**
     * A getter function of graphics, so that users of this class can access it.
     */
    public Graphics getGraphics(){
        return currentGraphics;             
    }
    
    /**
     * Converts distance to pixels.
     * 
     * @param x the x coordinate to be converted
     * @return returns the x coordinate in pixels
     */
    public int x2ScreenX( double x ){
        return 40+(int)((dim.width-80)  * x / width);            
    }

	/**
	 * Converts distance to pixels.
	 * 
	 * @param y the y coordinate to be converted
	 * @return returns the y coordinate in pixels
	 */
    public int y2ScreenY( double y ){
        return 40+(int)((dim.height-80) * y / width);            
    }            
    
    public void update(){
        canvas.invalidate();
        canvas.repaint();       
    }
}
