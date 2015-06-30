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


package net.tinyos.task.taskviz.sensor;

import java.awt.*;
import java.util.Date;

import edu.umd.cs.jazz.component.ZEllipse;
import edu.umd.cs.jazz.util.ZRenderContext;

import net.tinyos.task.taskviz.Mote;

// this class does not do serialization correctly, unlike ZEllipse
/**
 * This class represents and renders a mote with sensors
 */
public class SensorMote extends Mote {

  /**
   * Simple visualization of data
   */
  public final static int SIMPLE = 0;

  /**
   * Gradient visualization of data
   */
  public final static int GRADIENT = 1;

  /**
   * Use color in visualization
   */
  public final static int COLOR = 0;

  /**
   * Use gray-scale in visualization
   */
  public final static int GRAY = 1;

  /**
   * Use red-scale in visualization
   */
  public final static int RED = 2;

  /**
   * Use green-scale in visualization
   */
  public final static int GREEN = 3;

  /**
   * Use blue-scale in visualization
   */
  public final static int BLUE = 4;

  /**
   * Value to indicate invalid sensor data
   */
  public final static int INVALID_VALUE = -1000000;

  /**
   * Size of oval to draw
   */
  public final static int SIZE = 26;

  public final static int SENSOR_SIZE = 20;
  private int[] values;
  private String[] attributes;
  private int vizType = SIMPLE;
  private int colorScheme = GRAY;
  private int sensor;
  private long time;
  private int maxValue;
  private int numSensors = 0;

//  private Ellipse2D ellipse;

  /**
   * Constructor that places a mote centered at x,y with the given id
   *
   * @param x X coordinate to place the mote at
   * @param y Y coordinate to place the mote at
   * @param id Id of the mote being created
   */
  public SensorMote(double x, double y, int id) {
    super(x,y,id);
    values = new int[SENSOR_SIZE];
    attributes = new String[SENSOR_SIZE];
    for (int i=0; i<SENSOR_SIZE; i++) {
      values[i] = INVALID_VALUE;
    }
    sensor = -1;
//    ellipse = new Ellipse2D.Double();
  }

  /**
   * Constructor that places a mote centered at x,y with no id
   *
   * @param x X coordinate to place the mote at
   * @param y Y coordinate to place the mote at
   */
  public SensorMote(double x, double y) {
    super(x,y);
    values = new int[SENSOR_SIZE];
    attributes = new String[SENSOR_SIZE];
    for (int i=0; i<SENSOR_SIZE; i++) {
      values[i] = INVALID_VALUE;
    }
    sensor = -1;
//    ellipse = new Ellipse2D.Double();
  }

  public long getTime() {
    return time;
  }

  public int getNumSensors() {
    return numSensors;
  }

  /**
   * Sets the sensor value at position i to value v
   *
   * @param i Sensor position to set value of
   * @param v Sensor value
   * @param att Sensor attribute
   */
  public void setSensorValue(int i, int value, String att) {
    time = new Date().getTime();
    values[i] = value;
    attributes[i] = att;
    repaint();
    if (numSensors < i+1) {
      numSensors = i+1;
    }
//System.out.println("node :"+getId()+": got value: "+value+" for slot: "+i);
  }

  /**
   * Gets the sensor value at position i 
   *
   * @param i Sensor position to get value of
   * @return Sensor value
   */
  public int getSensorValue(int i) {
    return values[i];
  }

  /**
   * Gets the sensor attribute at position
   *
   * @param i Sensor position to get attribute for
   * @return Sensor attribute
   */
  public String getSensorAttribute(int i) {
    return attributes[i];
  }

  /**
   * Visualizes the sensor value at position i
   *
   * @param i Sensor position to visualize
   */
  public void setSensorToVisualize(int i) {
    sensor = i;
    repaint();
//System.out.println("node: "+getId()+": visualizing sensor: "+i);
  }

  /**
   * Return the sensor currently being visualized
   *
   * @return index of sensor being visualized
   */
  public int getSensorToVisualize() {
      return sensor;
  }

  /**
   * Sets the visualization type: simple or gradient
   *
   * @param type Visualization type
   */
  public void setVisualizationType(int type) {
    vizType = type;
    repaint();
  }

  /**
   * Sets the color scheme for visualization: color or gray-scale
   *
   * @param scheme Color scheme to use
   * @param max Max value of sensor
   */
  public void setColorScheme(int scheme, int max) {
    colorScheme = scheme;
    maxValue = max;
    repaint();
//System.out.println("color update for :"+getId()+": with "+scheme);
  }  

  /**
   * Creates a composite value to allow transparency
   *
   * @param alpha Amount of transparency
   */
  private AlphaComposite makeComposite(float alpha) {
    int type = AlphaComposite.SRC_OVER;
    return(AlphaComposite.getInstance(type, alpha));
  }

  /**
   * Renders the sensor mote according to the selected sensor type and the visualization type
   *
   * @param renderContext Jazz object to use for rendering
   */
  public void render(ZRenderContext renderContext) {
    super.render(renderContext);
    Graphics2D g2 = renderContext.getGraphics2D(); 

    if ((sensor >= 0) && (values[sensor] != INVALID_VALUE)) {
      if (vizType == SIMPLE) {
        Composite originalComposite = g2.getComposite();
        g2.setComposite(makeComposite(0.7f));
        int red=0, blue=0, green=0;
        if (colorScheme == COLOR) { 
//System.out.println("color");
          // calculate temp color
          // temperature 0 -->    (0,0,255)   0
          // temperature 127 -->  (255,255,0) 2047 
          // temperature 255 --> (255,0,0);   4095
          if (values[sensor] <= 0) {
            red = 0;
            green = 0;
            blue = 255;
          }
          else if (values[sensor] <= (int)(maxValue/2)) {
            red = (int)(255*(float)((float)(values[sensor])/(float)(maxValue/2)));
            green = red;
            blue = 255-red;
          }
          else if (values[sensor] <= maxValue) {
            red = 255;
            green = (int)(255*(float)((float)(maxValue-values[sensor])/(float)(maxValue/2)));
            blue = 0;
          }
          else {
            red = 255;
            green = 0;
            blue = 0;
          }
        }
        else if (colorScheme == GRAY) { 
          red = (int)((float)255*((float)values[sensor]/(float)maxValue));
          green = red;
          blue = red;
//System.out.println("gray: "+red);
        }
        else if (colorScheme == RED) { 
          red = (int)((float)255*((float)values[sensor]/(float)maxValue));
          green = 0;
          blue = 0;
//System.out.println("red: "+red);
        }
        else if (colorScheme == GREEN) { 
          green = (int)((float)255*((float)values[sensor]/(float)maxValue));
          red = 0;
          blue = 0;
//System.out.println("green: "+green);
        }
        else if (colorScheme == BLUE) { 
          blue = (int)((float)255*((float)values[sensor]/(float)maxValue));
          red = 0;
          green = 0;
//System.out.println("blue: "+blue);
        }
	try {
	    g2.setPaint(new Color(red,green,blue));
	    g2.fillOval((int)(x-SIZE/2),(int)(y-SIZE/2),SIZE,SIZE);
	    g2.setPaint(Color.black);
	    g2.drawOval((int)(x-SIZE/2),(int)(y-SIZE/2),SIZE,SIZE);
	    g2.setComposite(originalComposite);


	} catch (IllegalArgumentException e) {
	    System.out.println("Got bad color in SensorMote.java.");
	    g2.setPaint(Color.black);
	    g2.setComposite(originalComposite);
	    //ok -- bad color
	}
      }

    }   

      g2.setFont(new Font("times",Font.PLAIN,10));
      g2.drawString((new Integer(getId())).toString(), (int)(x-SIZE/2)+7,(int)(y-SIZE/2)+18);

  }

}
