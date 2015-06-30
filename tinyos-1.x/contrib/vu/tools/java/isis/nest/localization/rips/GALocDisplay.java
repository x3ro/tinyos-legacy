/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
 // @author Brano Kusy: kusy@isis.vanderbilt.edu
 
package isis.nest.localization.rips;

import java.awt.Canvas;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Frame;
import java.awt.Graphics;
import java.awt.Image;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;


public class GALocDisplay extends Frame
{
    protected LocalizationSolution solution        = null;
    protected DispCanvas           canvas          = null;
    protected Dimension            dim             = null;
    protected Graphics             currentGraphics = null;

    class DispCanvas extends Canvas
    {
        public void paint( Graphics g )
        {           
            re_display( g );            
        }

        public void update( Graphics g )
        {
            re_display( g );
        }                   

        public void re_display( Graphics g ) 
        {       
            int i,j;
            dim = getSize();
            Image offscreen = createImage(dim.width,dim.height);
            Graphics b = offscreen.getGraphics();
    
            currentGraphics = b; 

            // paint background
            b.setColor( Color.white );
            b.fillRect( 0, 0, dim.width, dim.height );
                                
            if( solution != null )
            {
                // draw measurements
                /*i=0;
                Iterator it = solution.problem.abcd_measurements.iterator();
                while( it.hasNext() )
                {
                    ABCDMeasurement m = (ABCDMeasurement)it.next();
                    if( m.sensor_A_ind>=0 && m.sensor_B_ind>=0 && m.sensor_C_ind>=0 && m.sensor_D_ind>=0 )
                    {                    
                        int xa = x2screenX( solution.sensors[m.sensor_A_ind].x );
                        int ya = y2screenY( solution.sensors[m.sensor_A_ind].y );
                        int xb = x2screenX( solution.sensors[m.sensor_B_ind].x );
                        int yb = y2screenY( solution.sensors[m.sensor_B_ind].y );
                        int xc = x2screenX( solution.sensors[m.sensor_C_ind].x );
                        int yc = y2screenY( solution.sensors[m.sensor_C_ind].y );
                        int xd = x2screenX( solution.sensors[m.sensor_D_ind].x );
                        int yd = y2screenY( solution.sensors[m.sensor_D_ind].y );
                    
                        float norm_error = (float)(solution.measurement_errors[i] / 0.5);
                        if( norm_error > 1)
                            norm_error = 1; 
                        norm_error = 1-norm_error;
                    
                        b.setColor( new Color(1.0f,norm_error,norm_error));
                        b.drawLine(xa,ya,xc,yc);
                        b.drawLine(xc,yc,xb,yb);
                        b.drawLine(xb,yb,xd,yd);
                        b.drawLine(xd,yd,xa,ya);
                    }
                    ++i;                    
                }*/
            
                // draw sensors               
                for( i=0; i<solution.problem.sensors.size(); ++i )
                {
                    LocalizationData.Sensor sensor = (LocalizationData.Sensor)solution.problem.sensors.values().toArray()[i]; 
                    
                    int x1 = x2screenX( sensor.pos.x );
                    int y1 = y2screenY( sensor.pos.y );
                
                    b.setColor( Color.GREEN );
                    if( sensor.anchor )
                    {                                    
                        b.fillOval( x1-10, y1-10, 20, 20 );
                        b.drawString( Integer.toString(i), x1+10, y1+10);
                    }
                    else
                    {
                        b.fillOval( x1-4, y1-4, 8, 8 );
                        b.setColor( Color.BLUE );
                    
                        int x2 = x2screenX( solution.sensors[i].x );
                        int y2 = y2screenY( solution.sensors[i].y );
                    
                        b.drawLine(x1,y1,x2,y2);
                
                        //b.setColor( Color.RED );
                        b.fillOval( x2-3, y2-3, 6, 6 );
                    }
                }                                
            }

            g.drawImage(offscreen,0,0,this);
        }                
    }
	private LocalizationSolutionCallback callback = null;
	private class myWindowAdapter extends WindowAdapter{
		private LocalizationSolutionCallback callback;
		public myWindowAdapter(LocalizationSolutionCallback callback){
			this.callback = callback;
		}
        public void windowClosing(WindowEvent we) 
        {
        	callback.localizationFinished();
        	hide();
        }
	}

    public GALocDisplay(LocalizationSolutionCallback callback)
    {
        super();
        this.callback = callback;
        setSize( 800, 600 );

        addWindowListener( new myWindowAdapter(callback) ); 

        canvas = new DispCanvas();          
        add( canvas ); 

        setTitle("Rips Localization Window"); 
    }

    public GALocDisplay()
    {
        super();
        this.callback = null;
        setSize( 800, 600 );

        addWindowListener( new WindowAdapter() 
            {
                public void windowClosing(WindowEvent we) 
                {
                	//hide();
                	System.exit(0);
                }
            }
        );

        canvas = new DispCanvas();          
        add( canvas ); 

        setTitle("Localization Test"); 
    }
    
    public Graphics getGraphics()
    {
        return currentGraphics;             
    }

    public int x2screenX( double x )
    {
        return 40+(int)((dim.width-80) * (x / solution.problem.x_max));            
    }

    public int y2screenY( double y )
    {
        return 40+(int)((dim.height-80) * (y / solution.problem.y_max));            
    }            

    public void update( LocalizationSolution solution )
    {
        this.solution = solution;
        canvas.invalidate();
        canvas.repaint();       
    }

}
