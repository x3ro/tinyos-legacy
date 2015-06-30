// $Id: CentroidPlugin.java,v 1.8 2004/06/11 21:30:14 mikedemmer Exp $

/* Matt Welsh, mdw@eecs.harvard.edu */

package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class CentroidPlugin extends GuiPlugin implements SimConst {
  private static final boolean DEBUG = false;

  /* Fake magenetometer port */
  public static final byte MAG_PORT = (byte)131;
  /* Mapping from coordinate axis to location ADC value */
  public static final double SCALE = 65535.0;
  public static final boolean MOVE_OBJECT_CIRCLE = true;
  public static final boolean MOVE_OBJECT_RANDOM = false;
  /* Rate at which the object moves */
  public static final double STEP_TIME = 2.0;
  public static final double STEP_SIZE = 5.0;
  public static final double CHANGEDIR_PROB = 0.15;
  public static final double CIRCLE_RADIUS = 30.0;
  public static final double MAG_MAXDIST = 20.0;
  public static final double MAG_MAXVAL = 1024.0;

  private double cur_theta = 0;
  private int cur_step = 0;
  private int cur_xdir = 1, cur_ydir = 1;
  private double object_x, object_y, centroid_x, centroid_y;
  int centroid_mote = -1;

  private double calcDistance(double x1, double y1, double x2, double y2) {
    double xd = x1 - x2;
    double yd = y1 - y2;
    return Math.sqrt((xd * xd) + (yd * yd));
  }

  private double calcMagValue(double dist) {
    return Math.max(0.0, (-1.0 * (MAG_MAXVAL/MAG_MAXDIST) * dist) + MAG_MAXVAL);
  }

  private void setObjectLocation(double objx, double objy) {
    object_x = objx;
    object_y = objy;

    Collection motes = state.getMoteSimObjects();
    Iterator it = motes.iterator();
    try {
      while (it.hasNext()) {
	MoteSimObject mote = (MoteSimObject)it.next();
	CoordinateAttribute coord = mote.getCoordinate();
	double dist = calcDistance(coord.getX(), coord.getY(), object_x, object_y);
	double magValue = calcMagValue(dist);
	simComm.sendCommand(new SetADCPortValueCommand((short)mote.getID(), 0L, 
	      MAG_PORT, (int)magValue));
      }
    } catch (java.io.IOException ioe) {
      // Ignore it
      return;
    }
  }

  private void moveObject() {
    if (!MOVE_OBJECT_RANDOM && !MOVE_OBJECT_CIRCLE) return;
    double ox, oy;

    if (MOVE_OBJECT_CIRCLE) {
      cur_theta += (0.02 * STEP_SIZE);
      double dx = Math.cos(cur_theta);
      double dy = Math.sin(cur_theta);
      ox = 50.0 + (dx * CIRCLE_RADIUS);
      oy = 50.0 + (dy * CIRCLE_RADIUS);
    } else {
      // Change direction?
      SimRandom rand = driver.getSimRandom();
      if (rand.nextDouble() < CHANGEDIR_PROB) {
	double p = rand.nextDouble();
	if (p < 0.33) {
	  cur_xdir = 1;
	} else if (p < 0.66) {
	  cur_xdir = -1;
	} else {
	  cur_xdir = 0;
	}
      }
      if (rand.nextDouble() < CHANGEDIR_PROB) {
	double p = rand.nextDouble();
	if (p < 0.33) {
	  cur_ydir = 1;
	} else if (p < 0.66) {
	  cur_ydir = -1;
	} else {
	  cur_ydir = 0;
	}
      }

      ox = object_x + (cur_xdir * STEP_SIZE);
      oy = object_y + (cur_ydir * STEP_SIZE);

      // Check for boundary
      if (ox < 10.0 || ox > 90.0) {
	cur_xdir *= -1;
	ox = object_x + (cur_xdir * STEP_SIZE);
      }
      if (oy < 10.0 || oy > 90.0) {
	cur_ydir *= -1;
	oy = object_y + (cur_ydir * STEP_SIZE);
      }
    }

    setObjectLocation(ox, oy);
    motePanel.refresh();
  }

  public void handleEvent(SimEvent event) {

    if (event instanceof TossimInitEvent) {
      cur_step = 0;
      cur_xdir = 1; cur_ydir = 1;
      centroid_mote = -1;
      cur_theta = 0.0;
      setObjectLocation(50.0, 50.0);
      motePanel.refresh();
    }

    if ((int)(tv.getTosTime() / STEP_TIME) > cur_step) {
      cur_step++;
      moveObject();
    }

    if (event instanceof DebugMsgEvent) {
      DebugMsgEvent dme = (DebugMsgEvent)event;
      if (dme.getMessage().indexOf("Centroid: Calculated centroid") != -1) {
	StringTokenizer st = new StringTokenizer(dme.getMessage());
	String skip;
	int cx, cy;
	skip = st.nextToken();
	skip = st.nextToken();
	skip = st.nextToken();
	try {
	  cx = Integer.parseInt(st.nextToken());
	  cy = Integer.parseInt(st.nextToken());
	} catch (Exception e) {
	  return;
	}
	centroid_x = ((cx * 1.0) / SCALE) * cT.getMoteScaleWidth();
	centroid_y = ((cy * 1.0) / SCALE) * cT.getMoteScaleHeight();
	centroid_mote = dme.getMoteID();

	double dist = calcDistance(object_x, object_y, centroid_x, centroid_y);
	System.err.println("Centroid: mote "+centroid_mote+" time "+tv.getTosTime()+" dist "+dist);
      }
    }

    if (event instanceof AttributeEvent) {
      AttributeEvent ae = (AttributeEvent)event;
      if (ae.getType() == AttributeEvent.ATTRIBUTE_CHANGED) {
	if (ae.getOwner() instanceof MoteSimObject &&
	    ae.getAttribute() instanceof CoordinateAttribute) {
	  MoteSimObject mote = (MoteSimObject)ae.getOwner();
	  setObjectLocation(object_x, object_y);
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
    cur_theta = 0.0;
    cur_step = 0;
    cur_xdir = 1; cur_ydir = 1;
    centroid_mote = -1;
    setObjectLocation(50.0, 50.0);
  }
  public void deregister() {}

  public void draw(Graphics graphics) {
    graphics.setFont(tv.smallFont);
    graphics.setColor(Color.red);
    int x = (int)cT.simXToGUIX(object_x);
    int y = (int)cT.simYToGUIY(object_y);
    int size = 10;
    x -= size/2; y -= size/2;
    graphics.drawOval(x, y, size, size);
    graphics.drawString("Object", x+size+1, y);

    if (centroid_mote != -1) {
      graphics.setColor(Color.green);
      x = (int)cT.simXToGUIX(centroid_x);
      y = (int)cT.simYToGUIY(centroid_y);
      size = 6;
      x -= size/2; y -= size/2;
      graphics.drawOval(x, y, size, size);
      graphics.drawString("Centroid", x+size+1, y+size+1);

      try {
	MoteSimObject mote = state.getMoteSimObject(centroid_mote);
	CoordinateAttribute coord = mote.getCoordinate();
	int mx = (int)cT.simXToGUIX(coord.getX());
	int my = (int)cT.simYToGUIY(coord.getY());
	graphics.drawLine(x+(size/2), y+(size/2), mx, my);
      } catch (NullPointerException e) {
	return;
      }
    }

  }
  public String toString() {
    return "Centroid";
  }
    
}


