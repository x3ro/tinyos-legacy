/* "Copyright (c) 2001 and The Regents of the University  
* of California.  All rights reserved. 
* 
* Permission to use, copy, modify, and distribute this software and its 
* documentation for any purpose, without fee, and without written agreement is 
* hereby granted, provided that the above copyright notice and the following 
* two paragraphs appear in all copies of this software. 
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
* Authors:   Matt Welsh
*/

package mdw.surge;

import java.lang.Math;
import java.util.*;
import java.text.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public class Util {

  public static final int VALUE_BAR_WIDTH = 50;
  public static final int VALUE_BAR_HEIGHT = 5;

  private static DecimalFormat df;

  static {
    df = new DecimalFormat();
    df.applyPattern("#.####");
  }

  public static String format(double value) {
    return df.format(value);
  }

  public static Color gradientColor(double value) {
    if (value < 0.0) return Color.gray;
    if (value > 1.0) value = 1.0;
    int red = Math.min(255,(int)(512.0 - (value * 512.0)));
    int green = Math.min(255,(int)(value * 512.0));
    int blue = 0;
    return new Color(red, green, blue);
  }

  public static void drawValueBar(int x, int y, double value, boolean label, String labelhead, Graphics g) {
    g.setColor(MainFrame.labelColor);
    g.drawRect(x,y,VALUE_BAR_WIDTH,VALUE_BAR_HEIGHT);

    int barwidth;
    if (value < 0.0) {
      // Unknown value
      barwidth = VALUE_BAR_WIDTH-1;
    } else {
      barwidth = (int)((VALUE_BAR_WIDTH - 1) * Math.min(1.0,value));
    }
    g.setColor(gradientColor(value));
    g.fillRect(x+1,y+1,barwidth,VALUE_BAR_HEIGHT-1);

    if (label || labelhead != null) {
      g.setFont(MainFrame.defaultFont);
      g.setColor(MainFrame.labelColor);
      int off = 2;
      if (labelhead != null) {
	g.drawString(labelhead, x+VALUE_BAR_WIDTH+2, y+VALUE_BAR_HEIGHT);
	off += (labelhead.length()+1) * 5; // Just a guess
      }
      if (label) {
	if (value < 0.0) {
	  g.drawString("?", x+VALUE_BAR_WIDTH+off, y+VALUE_BAR_HEIGHT);
	} else {
	  g.drawString(format(value), x+VALUE_BAR_WIDTH+off, y+VALUE_BAR_HEIGHT);
	}
      }
    }
  }

}