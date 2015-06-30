/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2002 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.viz.sensor;

import java.awt.*;
import java.util.Date;

import edu.umd.cs.jazz.component.ZEllipse;
import edu.umd.cs.jazz.util.ZRenderContext;

import net.tinyos.viz.Mote;

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
   * Value to indicate invalid sensor data
   */
  public final static int INVALID_VALUE = -1000000;

  /**
   * Size of oval to draw
   */
  public final static int SIZE = 26;

  private int[] values;
  private int vizType = SIMPLE;
  private int colorScheme = GRAY;
  private int sensor;
  private long time;

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
    values = new int[10];
    for (int i=0; i<10; i++) {
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
    values = new int[10];
    sensor = -1;
//    ellipse = new Ellipse2D.Double();
  }

  public long getTime() {
    return time;
  }

  /**
   * Sets the sensor value at position i to value v
   *
   * @param i Sensor position to set value of
   * @param v Sensor value
   */
  public void setSensorValue(int i, int value) {
    time = new Date().getTime();
    values[i] = value;
    repaint();
  }

  /**
   * Gets the sensor value at position i to value v
   *
   * @param i Sensor position to get value of
   * @return Sensor value
   */
  public int getSensorValue(int i) {
    return values[i];
  }

  /**
   * Visualizes the sensor value at position i
   *
   * @param i Sensor position to visualize
   */
  public void setSensorToVisualize(int i) {
    sensor = i;
    repaint();
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
   */
  public void setColorScheme(int scheme) {
    colorScheme = scheme;
    repaint();
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
          // calculate temp color
          // temperature 0 -->    (0,0,255)
          // temperature 127 -->  (255,255,0)
          // temperature 255 --> (255,0,0);
          if (values[sensor] <= 0) {
            red = 0;
            green = 0;
            blue = 255;
          }
          else if (values[sensor] <= 127) {
            red = (int)(255*(float)((float)(values[sensor])/(float)127));
            green = red;
            blue = 255-red;
          }
          else if (values[sensor] <= 255) {
            red = 255;
            green = (int)(255*(float)((float)(255-values[sensor])/(float)128));
            blue = 0;
          }
        }
        else if (colorScheme == GRAY) { 
          red = 255-values[sensor];
          green = red;
          blue = red;
        }
        else if (colorScheme == RED) { 
          red = 255-values[sensor];
          green = 0;
          blue = 0;
        }
        else if (colorScheme == GREEN) { 
          green = 255-(int)((float)255*((float)values[sensor]/(float)10));
          red = 0;
          blue = 0;
        }
        g2.setPaint(new Color(red,green,blue));
        g2.fillOval((int)(x-SIZE/2),(int)(y-SIZE/2),SIZE,SIZE);
        g2.setPaint(Color.black);
        g2.drawOval((int)(x-SIZE/2),(int)(y-SIZE/2),SIZE,SIZE);

        g2.setComposite(originalComposite);
      }
    }   
  }

}