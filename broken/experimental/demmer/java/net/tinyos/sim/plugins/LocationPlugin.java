// $Id: LocationPlugin.java,v 1.3 2003/11/21 01:32:45 mikedemmer Exp $

/* This plugin sets the "virtual" location of each mote based on its 
 * location in the mote window. Motes can read their location from the
 * ADC, using the FakeLocation component (talk to Matt).
 */

package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class LocationPlugin extends GuiPlugin implements SimConst {
  private static final boolean DEBUG = false;

  public static final byte PORT_LOCATION_X = (byte)128;
  public static final byte PORT_LOCATION_Y = (byte)129;
  public static final byte PORT_LOCATION_Z = (byte)130;
  /* Mapping from coordinate axis to location ADC value */
  public static final double SCALE = 65535.0;

  private void setLocation(MoteSimObject mote) {
    MoteCoordinateAttribute coord = mote.getCoordinate();

    int x = (int)(((coord.getX() * SCALE) / cT.getMoteScaleWidth())); 
    int y = (int)(((coord.getY() * SCALE) / cT.getMoteScaleHeight()));

    if (DEBUG) System.err.println("LOCATION: Mote "+mote.getID()+" ("+coord.getX()+","+coord.getY()+") -> ("+Integer.toHexString(x)+","+Integer.toHexString(y)+")");

    try {
      simComm.sendCommand(new SetADCPortValueCommand((short)mote.getID(), 0L, PORT_LOCATION_X, x));
      simComm.sendCommand(new SetADCPortValueCommand((short)mote.getID(), 0L, PORT_LOCATION_Y, y));
      tv.setStatus("Setting location of mote "+mote.getID()+" to ("+x+","+y+")");
    } catch (java.io.IOException ioe) {
      // Just ignore it
      return;
    }
  }

  public void handleEvent(SimEvent event) {

    if (event instanceof TossimInitEvent) {
      if (DEBUG) System.err.println("LOCATION: Setting mote locations");
      tv.pause();
      Collection motes = state.getMoteSimObjects();
      Iterator it = motes.iterator();
      while (it.hasNext()) {
	MoteSimObject mote = (MoteSimObject)it.next();
	setLocation(mote);
      }
      motePanel.refresh();
      tv.resume();
    }

    if (event instanceof AttributeEvent) {
      AttributeEvent ae = (AttributeEvent)event;
      if (ae.getType() == AttributeEvent.ATTRIBUTE_CHANGED) {
	if (ae.getOwner() instanceof MoteSimObject &&
	    ae.getAttribute() instanceof MoteCoordinateAttribute) {
	  MoteSimObject mote = (MoteSimObject)ae.getOwner();
	  setLocation(mote);
	  motePanel.refresh();
	}
      }
    }
  }

  public void register() {
    JTextArea ta = new JTextArea(3,40);
    ta.setFont(tv.defaultFont);
    ta.setEditable(false);
    ta.setBackground(Color.lightGray);
    ta.setLineWrap(true);
    ta.setText("Sets location of motes according to their values on the display.");
    pluginPanel.add(ta);
  }
  public void deregister() {}

  public void draw(Graphics graphics) {
  }
  public String toString() {
    return "Set location";
  }
    
}


