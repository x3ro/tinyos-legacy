// $Id: Util.java,v 1.2 2003/10/07 21:46:05 idgay Exp $

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
/* Authors:   Matt Welsh
*/

/**
 * @author Matt Welsh
 */


package net.tinyos.surge;

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
