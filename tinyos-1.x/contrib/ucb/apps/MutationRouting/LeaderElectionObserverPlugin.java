/*									
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Author: August Joki <august@berkeley.edu>
 *
 *
 *
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
import net.tinyos.matlab.*;



public class LeaderElectionObserverPlugin extends GuiPlugin implements SimConst, ActionListener  {
    
    Vector vehicleObservations;
    Hashtable leaderObservations;
    JCheckBox cbShowEstimates;
    boolean showEstimates = true;
    //Vector observations;
    Vector vehicles;
    Hashtable leaderMotes;
    double time;
    
    public void handleEvent(SimEvent event) {
        if (event instanceof AttributeEvent) {
            AttributeEvent ae = (AttributeEvent) event;
            if (ae.getType() == AttributeEvent.ATTRIBUTE_CHANGED) {
                if (ae.getOwner() instanceof MoteSimObject &&
		    ae.getAttribute() instanceof CoordinateAttribute) {
                    tv.getMotePanel().refresh();
                }
            }
        } 
	else if (event instanceof TossimInitEvent) {
	    Collection motes = state.getMoteSimObjects();
	    Iterator it = motes.iterator();
	    while (it.hasNext()) {
		MoteSimObject mote = (MoteSimObject)it.next();
		int id = mote.getID();
		try {
		    simComm.sendCommand(new SetADCPortValueCommand((short)id, 0L, (byte)73, 0));
		}
		catch (java.io.IOException e) {
		}
	    }
	} 
	else if (event instanceof DebugMsgEvent) {
	    
	    DebugMsgEvent dme = (DebugMsgEvent) event;
	    StringTokenizer st = new StringTokenizer(dme.getMessage());
	    String report;
	    if (dme.getMessage().indexOf("LEADER ELECTION:") != -1) {
		Observation ob;
		st.nextToken(); //"LEADER"
		st.nextToken(); //"ELECTION:"
		report = st.nextToken();
		//System.out.println(report);
		if (report.equals("not")) {
		    report = st.nextToken();
		    //System.out.println(report)
		    if (report.equals("leader")) {
			try {
			    simComm.sendCommand(new SetADCPortValueCommand((short)dme.getMoteID(), 0L, (byte)73, 0)); // tell mote it's no longer a pursuer
			}
			catch (java.io.IOException e) {
			}
			Enumeration e = leaderObservations.elements();
			while (e.hasMoreElements()) {
			    ob = (Observation) e.nextElement();
			    if (ob.moteID == dme.getMoteID()) {
				//losing control of leader
				if(ob.timeNotLeader == 0){
				    ob.timeNotLeader = tv.getTosTime(); //tos time this mote lost leadership
				}
			    }
			}
			
			Enumeration v = vehicleObservations.elements();
			while (v.hasMoreElements()) {
			    ob = (Observation) v.nextElement();
			    if (ob.moteID == dme.getMoteID()) {
				//losing control of leader
				if(ob.timeNotLeader == 0){
				    ob.timeNotLeader = tv.getTosTime(); //tos time this mote lost leadership
				}
			    }
			}
		    }
		    return;
		}
		else if (report.equals("leader")) {
		    /*
		    report = st.nextToken();
		    //System.out.println(report);
		    report = report.substring(9, report.length()-1); // everything after "[mag_sum=" untill "]"
		    //System.out.println(report);
		    double magObserved = (new Double(report)).doubleValue();
		    report = st.nextToken();
		    //System.out.println(report);
		    report = report.substring(7, report.length()-1); // everything after "[x_sum=" untill "]"
		    //System.out.println(report);
		    double xObserved = (new Double(report)).doubleValue();
		    report = st.nextToken();
		    //System.out.println(report);
		    report = report.substring(7, report.length()-1); // everything after "[y_sum=" untill "]"
		    //System.out.println(report);
		    double yObserved = (new Double(report)).doubleValue();
		    xObserved /= magObserved;
		    yObserved /= magObserved;
		    */
		    report = st.nextToken(); //"x: "
		    report = st.nextToken(); //value
		    //System.out.println(report);
		    double xObserved = (new Double(report)).doubleValue();
		    report = st.nextToken(); //"y: "
		    report = st.nextToken(); //value
		    //System.out.println(report);
		    double yObserved = (new Double(report)).doubleValue();
		    
		    // find closest moving object
		    double dist = -1;
		    CoordinateAttribute coord;
		    double x,y,newDist;
		    int vehicleIndex = -1;
		    
		    coord = ((MoteSimObject) state.getMoteSimObject(dme.getMoteID())).getCoordinate();
		    for (int i = 0; i < vehicles.size(); i++) {
			//System.out.println("dist: " + dist);
			//System.out.println("i: " + i);
			x = ((MotionPlugin) vehicles.elementAt(i)).getXPosition();
			y = ((MotionPlugin) vehicles.elementAt(i)).getYPosition();
			//System.out.println("x: " + x + " y: " + y);
			newDist = Math.sqrt(Math.pow(x-coord.getX(),2) + Math.pow(y-coord.getY(),2));
			//System.out.println("new dist: " + newDist);
			if (((MotionPlugin) vehicles.elementAt(i)).isRegistered() && (newDist < dist || dist == -1) ){
			    dist = newDist;
			    //System.out.println("setting dist to new dist");
			    vehicleIndex = i;
			    //System.out.println("setting vehicle index to i");
			}
		    }

		    // add observation
		    if (vehicleIndex != -1) {
			int pursuer = 1;
			if (((MotionPlugin) vehicles.elementAt(vehicleIndex)).toString().equals("Pursuer1")) {
			    pursuer = 2;
			} else if (((MotionPlugin) vehicles.elementAt(vehicleIndex)).toString().equals("Pursuer2")) {
			    pursuer = 3;
			}
			Integer p = new Integer(pursuer);
			if (!leaderMotes.containsKey(p)) {
			    boolean contains = false;
			    for (Enumeration e = leaderMotes.elements(); e.hasMoreElements();) {
				if (dme.getMoteID() ==  ((Observation) (e.nextElement())).moteID) {
				    contains = true;
				    break;
				}
			    }
			    if (!contains) {
				try {
				    simComm.sendCommand(new SetADCPortValueCommand(dme.getMoteID(), 0L, (byte)73, pursuer)); // tell mote it's closest to which pursuer
				    //System.out.println("telling mote " + dme.getMoteID() + " it's a leader");
				}
				catch (java.io.IOException e) {
				}
				leaderMotes.put(p, new Observation(dme.getMoteID(), ((MotionPlugin) vehicles.elementAt(vehicleIndex)).getColor(), coord.getX(), coord.getY()));
			    }
			    else {
				System.out.println("mote " + dme.getMoteID() + " already leader for another moving object");
			    }
			}
			else {
			    double xVehicle = ((MotionPlugin) vehicles.elementAt(vehicleIndex)).getXPosition();
			    double yVehicle = ((MotionPlugin) vehicles.elementAt(vehicleIndex)).getYPosition();
			    Observation obs = (Observation) leaderMotes.get(p);
			    if (dist < Math.sqrt(Math.pow(xVehicle-obs.xEstimate,2) + Math.pow(yVehicle-obs.yEstimate,2))) {
				boolean contains = false;
				for (Enumeration e = leaderMotes.elements(); e.hasMoreElements();) {
				    if (dme.getMoteID() ==  ((Observation) (e.nextElement())).moteID) {
					contains = true;
					break;
				    }
				}
				if (!contains) {
				    try {
					simComm.sendCommand(new SetADCPortValueCommand(dme.getMoteID(), 0L, (byte)73, pursuer)); // tell mote it's closest to which pursuer
					//System.out.println("telling mote " + dme.getMoteID() + " it's a leader");
				    }
				    catch (java.io.IOException e) {
				    }
				    try {
					simComm.sendCommand(new SetADCPortValueCommand((short)obs.moteID, 0L, (byte)73, 0));
					//System.out.println("telling mote " + obs.moteID + " it's no longer a leader");
				    }
				    catch (java.io.IOException e) {
				    }
				    leaderMotes.put(p, new Observation(dme.getMoteID(), ((MotionPlugin) vehicles.elementAt(vehicleIndex)).getColor(), coord.getX(), coord.getY()));
				}
				else {
				    System.out.println("mote " + dme.getMoteID() + " already leader for another moving object");
				}
			    }
			}

			ob = new Observation(dme.getMoteID(), ((MotionPlugin) vehicles.elementAt(vehicleIndex)).getColor(), xObserved, yObserved);
			leaderObservations.remove(new Integer(ob.moteID));
			leaderObservations.put(new Integer(ob.moteID), ob);
			ob = new Observation(dme.getMoteID(), ((MotionPlugin) vehicles.elementAt(vehicleIndex)).getColor(), xObserved, yObserved);
			vehicleObservations.add(ob);
			//System.out.println("adding observation: " + ob);
		    }
		    return;
		}
	    }
	}
    }

    public void register() {
	time = 0;
        JPanel parameterPane = new JPanel();
        parameterPane.setLayout(new GridLayout(7,2,1,1));

        JButton clear = new JButton ("Clear Observations");
        clear.setToolTipText("remove all observations");
        clear.setFont(new Font("Helvetica", Font.PLAIN, 12));
        clear.setForeground(Color.blue);
        clear.setActionCommand("clear");
        clear.addActionListener (this);
        parameterPane.add(clear);

        pluginPanel.add(parameterPane);

	cbShowEstimates = new JCheckBox("Show Position Estimates", showEstimates);
	cbShowEstimates.addItemListener(new LeaderElectionObserverPlugin.cbListener());
	cbShowEstimates.setFont(tv.labelFont);
	parameterPane.add(cbShowEstimates);

        pluginPanel.revalidate();

	//init vectors
	vehicleObservations = new Vector();
	leaderObservations = new Hashtable();
	vehicles = new Vector();
	leaderMotes = new Hashtable();

	//add motion plugins to vehicles vector
        Plugin plugins[] = tv.getSimDriver().getPluginManager().plugins();
        for(int i=0;i<plugins.length;i++){
            if(plugins[i] instanceof MotionPlugin){
		if (((MotionPlugin)plugins[i]).isRegistered()) {
		    //System.out.println("adding vehicle: " + (MotionPlugin)plugins[i]);
		    vehicles.add((MotionPlugin)plugins[i]);
		}
            }
        }
    }

    public void deregister
	() {
    }

    public void draw(Graphics graphics) {
	Enumeration enum = leaderObservations.elements();
        while (enum.hasMoreElements()) {
            Observation obs = (Observation) enum.nextElement();
	    Color colorForCircle;
	    //calculate alpha
	    colorForCircle = calcColor(obs);
	    // remove from the list if the alpha = 0
	    if (colorForCircle.getAlpha() == 0) { // if enough time has elapsed that no more color is left
		leaderObservations.remove(new Integer(obs.moteID));
		//System.out.println("removing observation: " + obs);
	    } 

	    else { // draw observation	

		//draw rings around leader mote colored by last vehicle seen
		graphics.setColor(colorForCircle);
		CoordinateAttribute coord = ((MoteSimObject) state.getMoteSimObject(obs.moteID)).getCoordinate();
		graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 10, (int) cT.simYToGUIY(coord.getY()) - 10, 20, 20);
		graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 9, (int) cT.simYToGUIY(coord.getY()) - 9, 18, 18);
		graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 8, (int) cT.simYToGUIY(coord.getY()) - 8, 16, 16);
	    }
        }
	enum = leaderMotes.elements();
	graphics.setColor(Color.cyan);
	while(enum.hasMoreElements()) {
	    Observation obs = (Observation) enum.nextElement();
	    graphics.drawOval((int) cT.simXToGUIX(obs.xEstimate) - (int) cT.simXToGUIX(MOTE_OBJECT_SIZE)/2, (int) cT.simYToGUIY(obs.yEstimate) - (int) cT.simXToGUIX(MOTE_OBJECT_SIZE)/2, (int) cT.simXToGUIX(MOTE_OBJECT_SIZE), (int) cT.simXToGUIX(MOTE_OBJECT_SIZE));
	}
	if (showEstimates) {
	    Enumeration e = vehicleObservations.elements();
	    while (e.hasMoreElements()) {
		Observation obs = (Observation) e.nextElement();
		Color colorForCircle;
		//calculate alpha
		colorForCircle = calcColor(obs);
		// remove from the list if the alpha = 0
		if (colorForCircle.getAlpha() == 0) { // if enough time has elapsed that no more color is left
		    vehicleObservations.remove(obs);
		    //System.out.println("removing observation: " + obs);
		} 
		
		else { // draw observation	
		    
		    //draw blip for where the leader mote thinks the vehicle is
		    double x,y;
		    if (obs.xEstimate > cT.getMoteScaleWidth()) { // if off screen
			System.out.println("Estimation outside area");
			x = cT.getMoteScaleWidth(); // fit in screen
		    }
		    else {
			x = obs.xEstimate;
		    }
		    if (obs.yEstimate > cT.getMoteScaleHeight()) { // if off screen
			System.out.println("Estimation outside area");
			y = cT.getMoteScaleHeight(); // fit in screen
		    }
		    else {
			y = obs.yEstimate;
		    }
		    graphics.setColor(colorForCircle);
		    //System.out.println("Drawing vehicle observation at X: " + x + " Y: " + y + " color: " + colorForCircle + " alpha: " + colorForCircle.getAlpha());
		    graphics.drawRect((int) cT.simXToGUIX(x)-8, (int) cT.simYToGUIY(y)-8, 16, 16);
		    //graphics.drawRect((int) cT.simXToGUIX(x)-8, (int) cT.simYToGUIY(y)-8, 17, 17);
		    //graphics.drawRect((int) cT.simXToGUIX(x)-8, (int) cT.simYToGUIY(y)-8, 18, 18);
		}
	    }
        }
    }
   
    public String toString() {
        return "Leader Observation";
    }

    private class Observation {
        public int moteID;
	public Color color;
	public double xEstimate;
	public double yEstimate;
	public double timeNotLeader;

	Observation(int id, Color color, double x, double y) {
	    //System.out.println("ID:" + id + " COLOR:" + color + " X:" + x + " Y:" + y);
	    this.moteID = id;
	    this.color = new Color(color.getRed(), color.getGreen(), color.getBlue(), 255);
	    this.xEstimate = x;
	    this.yEstimate = y;
	    this.timeNotLeader = 0;
	}
	
	public String toString() {
	    return "Mote ID: " + moteID + " || color: " + color + " || alpha " + color.getAlpha() +  " || x estimate: " + xEstimate + " || y estimate: " + yEstimate + " || time since not leader: " + timeNotLeader;
	}
    }

    class cbListener implements ItemListener {
	public void itemStateChanged(ItemEvent e) {
	    showEstimates = (e.getStateChange() == e.SELECTED);
	}
    }

    public void actionPerformed (ActionEvent e) {
	try {
	    if(e.getActionCommand() == "clear") {
		vehicleObservations = new Vector();
		leaderObservations = new Hashtable();
		tv.getMotePanel().refresh();
	    }
	} catch(Exception ee) {
	}

    }

    private Color calcColor(Observation observation) {
	if (observation.timeNotLeader == 0.0) { // if this observation is still a leader
	    if ((tv.getTosTime() - time) > 2) {
		observation.color = new Color(observation.color.getRed(), observation.color.getGreen(), observation.color.getBlue(), observation.color.getAlpha() - 1);
		time = tv.getTosTime();
	    }
	    return observation.color;
	} 
	else { 
	    Color tempColor = observation.color;
	    //int alpha = 255 - (int)(tv.getTosTime() - observation.timeNotLeader)*200;
	    int alpha = 0;
	    //System.out.println("alpha: " + alpha);
	    if (alpha < 0){
		alpha = 0;
	    }
	    observation.color = new Color(tempColor.getRed(), tempColor.getGreen(), tempColor.getBlue(), alpha);
	    return observation.color;
	}
    }
}
