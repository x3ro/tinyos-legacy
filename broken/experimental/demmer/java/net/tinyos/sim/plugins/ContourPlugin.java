// $Id: ContourPlugin.java,v 1.3 2003/11/21 01:32:45 mikedemmer Exp $

package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class ContourPlugin extends GuiPlugin {
  private static final boolean DEBUG = false;
  private static final int MAX_CPOINTS = 20;
  private static final boolean GENERATE_CONTOUR = true;
  private static final double STEP_TIME = 5.0;
  private static final double STEP_SIZE = 0.1;
  private static final short SENSOR_PORT = 0;
  private static final int ABOVE_SENSOR_VALUE = 1000;
  private static final int BELOW_SENSOR_VALUE = 0;

  private Vector cpoints = new Vector();
  private int cur_step;
  private double cur_theta;

  class cpoint {
    MoteSimObject mote;
    double x; double y;
    public String toString() {
      return "("+x+","+y+")";
    }
  }

  public void handleEvent(SimEvent event) {

    if (event instanceof TossimInitEvent) {
      cur_step = 0;
      cur_theta = 0.0;
    }

    if (event instanceof DebugMsgEvent) {
      DebugMsgEvent dme = (DebugMsgEvent)event;
      if (dme.getMessage().indexOf("CONTOUR POINT:") != -1) {
	StringTokenizer st = new StringTokenizer(dme.getMessage());
	String skip;
	skip = st.nextToken(); 
	skip = st.nextToken(); 
	String xs = st.nextToken();
	String ys = st.nextToken();
	cpoint cp = new cpoint();
	cp.mote = state.getMoteSimObject(dme.getMoteID());
	try {
	  cp.x = (Integer.parseInt(xs) * cT.getMoteScaleWidth()) / LocationPlugin.SCALE;
	  cp.y = (Integer.parseInt(ys) * cT.getMoteScaleHeight()) / LocationPlugin.SCALE;
	} catch (Exception e) {
	  return;
	}
	cpoints.addElement(cp);

	System.err.println("CPOINT ("+cp.x+","+cp.y+") dist "+distToContour(cp.x, cp.y));

	if (MAX_CPOINTS != -1) {
	  while (cpoints.size() > MAX_CPOINTS) {
	    cpoints.removeElementAt(0);
	  }
	}
	motePanel.refresh();
      }
    }

    if ((int)(tv.getTosTime() / STEP_TIME) > cur_step) {
      cur_step++;
      moveContour();
    }
  }

  private double distToContour(double x, double y) {
    // Definition of current contour line
    double A = Math.tan(cur_theta);
    double B = -1;
    double C = 50.0 - (50.0 * Math.tan(cur_theta));
    double dist = Math.abs(A*x + B*y + C) / Math.sqrt(A*A + B*B);
    return dist;
  }

  private void moveContour() {
    if (!GENERATE_CONTOUR) return;
    cur_theta += STEP_SIZE;
    clearPoints();
    System.err.println("cur_theta now "+cur_theta);

    Collection motes = state.getMoteSimObjects();
    Iterator it = motes.iterator();

    if (DEBUG) System.err.println(" ----------- ");
    while (it.hasNext()) {
      MoteSimObject mote = (MoteSimObject)it.next();
      MoteCoordinateAttribute coord = mote.getCoordinate();
      double x = coord.getX();
      double y = coord.getY();
      int sensorValue = BELOW_SENSOR_VALUE;

      // Calculate above/below line for all motes
      double val = (Math.tan(cur_theta) * (x - 50.0)) - (y - 50.0);
      if (cur_theta >= (Math.PI/2) && cur_theta < (3*Math.PI/2)) {
	val *= -1.0;
      }
      // Above or on line
      if (val >= 0) {
        sensorValue = ABOVE_SENSOR_VALUE;
      }

      try {
	if (DEBUG) System.err.println("Contour: "+mote.getID()+" "+sensorValue);
	simComm.sendCommand(new 
	    SetADCPortValueCommand((short)mote.getID(), 0L, 
	      SENSOR_PORT, sensorValue));
      } catch (java.io.IOException ioe) {
	// Ignore it
	return;
      }
    }
  }

  private void clearPoints() {
    cpoints = new Vector();
    motePanel.refresh();
  }
  
  public void register() {
    JButton clearButton = new JButton("Clear");
    clearButton.addActionListener(new cbListener());
    clearButton.setFont(tv.defaultFont);
    pluginPanel.add(clearButton);
    pluginPanel.revalidate();

    cur_step = 0;
    cur_theta = 0.0;

  }
  public void deregister() { 
    clearPoints();
  }
  public void reset() {
    clearPoints();
  }

  public void draw(Graphics graphics) {
    Iterator it = cpoints.iterator();

    graphics.setFont(tv.smallFont);
    graphics.setColor(Color.red);
    while (it.hasNext()) {
      cpoint cp = (cpoint)it.next();
      int x = (int)cT.simXToGUIX(cp.x);
      int y = (int)cT.simYToGUIY(cp.y);
      int size = 6;
      x -= size/2; y -= size/2;
      graphics.drawOval(x, y, size, size);
      graphics.drawString(cp.mote.toString(), x+size+1, y);
    }

    if (GENERATE_CONTOUR) {
      int x1, y1, x2, y2;
      x1 = (int)cT.simXToGUIX((50.0 * Math.cos(cur_theta)) + 50.0);
      x2 = (int)cT.simXToGUIX((50.0 * Math.cos(cur_theta+Math.PI)) + 50.0);
      y1 = (int)cT.simYToGUIY((50.0 * Math.sin(cur_theta)) + 50.0);
      y2 = (int)cT.simYToGUIY((50.0 * Math.sin(cur_theta+Math.PI)) + 50.0);
      graphics.setColor(Color.blue);
      graphics.drawLine(x1, y1, x2, y2);
    }
  }

  public String toString() {
    return "Contour points";
  }

  class cbListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      clearPoints();
    }
  }


}
