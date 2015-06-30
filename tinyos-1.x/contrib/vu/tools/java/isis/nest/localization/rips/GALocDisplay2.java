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

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Image;
import java.text.DecimalFormat;
import java.text.NumberFormat;

import javax.swing.JScrollPane;


public class GALocDisplay2 extends javax.swing.JPanel implements LocalizationSolutionCallback
{        
    // gui parts
    private javax.swing.JPanel locControlPanel;
    private javax.swing.JPanel bottomPanel;    
    private javax.swing.JPanel graphPanel;    
    private javax.swing.JPanel logPanel;
    private javax.swing.JButton startLocButton;
    private javax.swing.JButton stopLocButton;     
    private javax.swing.JTextArea log;
    private JScrollPane logScroll;               
    private DispCanvas canvas;
    private Dimension dim = null;
    private double xymax1 = 100;
    private int xymax2 = 100;
    private NumberFormat formatter = new DecimalFormat("0.00000");
     
    
    //  loc data
    private LocalizationData localizationData;
    private LocalizationSolution solution = null;
    
    private LocalizationThread locThread = null;
              
    
    class DispCanvas extends javax.swing.JPanel
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
            
            // calculate scaling paramaters
            dim = getSize();            
            if( localizationData.x_max / localizationData.y_max > dim.width / (double)dim.height )
            {
                // space on bottom
                xymax1 = localizationData.x_max;
                xymax2 = dim.width; 
            }
            else
            {
                // space on right
                xymax1 = localizationData.y_max;
                xymax2 = dim.height;                
            }            
            
            Image offscreen = createImage(dim.width,dim.height);
            Graphics b = offscreen.getGraphics();                       

            // paint background
            b.setColor( getBackground() );
            b.fillRect( 0, 0, dim.width, dim.height );
                        
            // draw search region
            b.setColor( Color.YELLOW );
            int x1 = x2screenX( 0 );
            int y1 = y2screenY( 0 );
            int x2 = x2screenX( localizationData.x_max );
            int y2 = y2screenY( localizationData.y_max );
            b.drawRect( x1, y1, x2-x1, y2-y1 );            
            
            if( localizationData != null )
            {
                for( i=0; i<localizationData.sensors.size(); ++i )
                {
                    LocalizationData.Sensor sensor = (LocalizationData.Sensor)localizationData.sensors.values().toArray()[i]; 

                    x1 = x2screenX( sensor.pos.x );
                    y1 = y2screenY( sensor.pos.y );

                    b.setColor( new Color(72,183,76));
                    if( sensor.anchor )                                  
                        b.fillOval( x1-10, y1-10, 20, 20 );
                    else
                        b.fillOval( x1-4, y1-4, 8, 8 );
                    b.drawString( Integer.toString(sensor.id), x1+10, y1+10);
                        
                    if( !sensor.anchor && solution != null )
                    {                           
                        x2 = x2screenX( solution.sensors[i].x );
                        y2 = y2screenY( solution.sensors[i].y );

                        b.setColor( Color.BLUE );
                        b.drawLine(x1,y1,x2,y2);
                        b.fillOval( x2-3, y2-3, 6, 6 );                        
                    }
                }
            }                    

            g.drawImage(offscreen,0,0,this);
        }                
    }            
    
    public GALocDisplay2( LocalizationData localizationData )
    {
        super();
        this.localizationData = localizationData;
        initComponents();        
    }
    
    public int x2screenX( double x )
    {      
        return 40+(int)((xymax2-80) * (x / xymax1));            
    }

    public int y2screenY( double y )
    {
        return x2screenX(y);           
    }            
    
    public void localizationSolution(int steps, LocalizationSolution solution)
    {        
        this.solution = solution;                
        canvas.invalidate();
        canvas.repaint();
                        
        String s = steps + "\t" +  
                   formatter.format(solution.locError()) + "\t" +
                   formatter.format(solution.maxLocError())+"\n";
                   
        addLog(s);     
    }
    
    public void localizationFinished()
    {
        if( solution != null )
            solution.printSensorCoordinates(); 
    }
       
    private void start()
    {                
        if( locThread!=null || localizationData==null || localizationData.abcd_measurements.size()==0 )
            return;
        try
        {
            locThread = new LocalizationThread(this,localizationData);
            clearLog();
        }
        catch( Exception e )
        {
            e.printStackTrace();
        }
    }
    
    public void clearLog()
    {
        log.setText("");        
    }
    
    public void addLog( String str )
    {                
        if( log.getText().length() > 100000 )
            log.setText("");        
        log.setText(log.getText().concat(str));        
        logScroll.getVerticalScrollBar().setValue(logScroll.getVerticalScrollBar().getMaximum());               
    }
    
    public void reset()
    {
        solution = null;
        stop();
    }
    
    public void stop()
    {
        if( locThread != null )
            locThread.stopLoc();
        locThread = null;
    }
    
    private void initComponents() 
    {      
        java.awt.GridBagConstraints gridBagConstraints;
                              
        locControlPanel = new javax.swing.JPanel();        
        bottomPanel = new javax.swing.JPanel();       
        logPanel = new javax.swing.JPanel();
        startLocButton = new javax.swing.JButton();
        stopLocButton = new javax.swing.JButton();
        graphPanel = new javax.swing.JPanel();       
        log = new javax.swing.JTextArea();        
                
        canvas = new DispCanvas();        

        setLayout(new java.awt.GridBagLayout());
        locControlPanel.setLayout(new java.awt.GridBagLayout());
       
        startLocButton.setPreferredSize(new java.awt.Dimension(150, 20));
        startLocButton.setMinimumSize(new java.awt.Dimension(120, 20));
        startLocButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
        startLocButton.setText("Start localization");
        startLocButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                start();
            }
        });        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
        locControlPanel.add(startLocButton, gridBagConstraints);
        
        stopLocButton.setPreferredSize(new java.awt.Dimension(150, 20));
        stopLocButton.setMinimumSize(new java.awt.Dimension(120, 20));
        stopLocButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
        stopLocButton.setText("Stop localization");
        stopLocButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                stop();
            }
        });        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
        locControlPanel.add(stopLocButton, gridBagConstraints);
        
        add(locControlPanel, gridBagConstraints);
        
        graphPanel.setLayout(new java.awt.GridBagLayout());
        graphPanel.setBorder(new javax.swing.border.TitledBorder("Sensor map"));
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        graphPanel.add(canvas,gridBagConstraints);
               
        bottomPanel.setLayout(new java.awt.GridBagLayout());
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 0.7;
        gridBagConstraints.weighty = 1.0;                        
        bottomPanel.add(graphPanel,gridBagConstraints);
        
                                
        logPanel.setLayout(new java.awt.GridBagLayout());
        logPanel.setBorder(new javax.swing.border.TitledBorder("Log (steps, avg error, max error)"));
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 0.3;
        gridBagConstraints.weighty = 1.0;                        
        bottomPanel.add(logPanel,gridBagConstraints);
        
        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;        
        log.setFont(new java.awt.Font("Courier", java.awt.Font.PLAIN, 12));
        log.setAutoscrolls(true);
        logScroll = new JScrollPane(log);
        logPanel.add(logScroll,gridBagConstraints);
               
        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;        
        add(bottomPanel, gridBagConstraints);                
    }
    
}
