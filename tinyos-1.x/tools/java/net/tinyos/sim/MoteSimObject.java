// $Id: MoteSimObject.java,v 1.9 2004/04/14 18:29:25 mikedemmer Exp $

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
 * Authors:	Phil Levis, Nelson Lee
 * Date:        December 11, 2002
 * Desc:        mote object for AdvSim
 *
 */

/**
 * @author Phil Levis
 * @author Nelson Lee
 */

package net.tinyos.sim;
import java.util.*;
import java.awt.*;

public class MoteSimObject extends SimObject {
  private int id;
  private MotePowerAttribute power;
  private MoteLedsAttribute leds;

  // A single popup menu can be assigned to all mote sim objects since
  // the mouse handler will set the target of the popup before
  // activating it.
  static private SimObjectPopupMenu motePopup;
  
  static public void setPopupMenu(SimObjectPopupMenu popup) {
    motePopup = popup;
  }

  public SimObjectPopupMenu getPopupMenu() {
    return motePopup;
  }
  
  public MoteSimObject(SimDriver driver, double x, double y, int id) {
    super(driver, MOTE_OBJECT_SIZE, x, y);
    
    this.id = id;
    
    power = new MotePowerAttribute(true);
    addAttribute(power);

    leds = new MoteLedsAttribute();
    addAttribute(leds);
                 
    addAttribute(new MoteIDAttribute(id));
  }

  public int getID() {
    return id;
  }

  public boolean getPower() {
    return power.getPower();
  }
  
  public void setPower(boolean onoff) {
    power.setPower(onoff);
    if (!onoff) {
      leds.setRedOff();
      leds.setGreenOff();
      leds.setYellowOff();
    }
  }

  public void draw(Graphics graphics, CoordinateTransformer cT) {
    int x = (int)cT.simXToGUIX(coord.getX());
    int y = (int)cT.simYToGUIY(coord.getY());
      
    int size = (int)cT.simXToGUIX(objectSize);
    int xl = x-(size/2);
    int yl = y-(size/2);

    if (isSelected()) {
      graphics.setColor(SELECTED_COLOR);
    } else {
      graphics.setColor(BASIC_COLOR);
    }
      
    if (!isVisible()) {
      return;
    }
    
    // need to change the color if the mote is off
    if (! getPower()) {
      if (isSelected()) {
        graphics.setColor(SELECTED_COLOR_OFF);
      }
      else {
        graphics.setColor(BASIC_COLOR_OFF);
      }
    }
    graphics.fillOval(xl, yl, size, size);

    // Writing out MoteID
    int id = getID(); 
    graphics.setColor(Color.black);
    graphics.drawString(Integer.toString(id), xl, yl-1);

    // Drawing Leds
    MoteLedsAttribute leds = (MoteLedsAttribute)
                             getAttribute("net.tinyos.sim.MoteLedsAttribute");
    if (leds.redLedOn()) {
      graphics.setColor(Color.red);
      graphics.fillRect(xl, y-(size/6), size/3, size/3);
    }
    if (leds.greenLedOn()) {
      graphics.setColor(Color.green);
      graphics.fillRect(xl+(size/3), y-(size/6), size/3, size/3);
    }
    if (leds.yellowLedOn()) {
      graphics.setColor(Color.yellow);
      graphics.fillRect(xl + (2*size/3), y-(size/6), size/3, size/3);
    }

    // Draw label if it exists
    MoteLabelAttribute label = (MoteLabelAttribute)
                               getAttribute("net.tinyos.sim.MoteLabelAttribute");
    if (label != null) {
      graphics.setColor(Color.black);
      graphics.drawString(label.getLabel(), x + label.getX(), y + label.getY());
    }
  }

  public String toString() {
    return "[Mote "+id+"]";
  }
}


