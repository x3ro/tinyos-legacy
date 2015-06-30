/* This plugin sets the rssi value of each mote based on their
 * locations in the mote window. Motes can read their rssi values from the
 * ADC, using ADC Channel PORT_RSSI (Defined below).
 */

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.plugins.CalamariPlugin;
import net.tinyos.sim.plugins.DirectedGraphPlugin;
import net.tinyos.sim.event.*;
import net.tinyos.matlab.*;

public class LeaderElectionPlugin  extends Plugin implements SimConst {

    /* Mapping from coordinate axis to location ADC value */
    Vector leaders = new Vector();

    public void handleEvent(SimEvent event) {
        if (event instanceof TossimInitEvent) {
            Enumeration enum = leaders.elements();
            while (enum.hasMoreElements()) {
                Leader leader = (Leader) enum.nextElement();
		//                if(leader.mover.isRegistered()){
		Iterator moteI= state.getMoteSimObjects().iterator();
		while(moteI.hasNext()){
		    MoteSimObject mote=(MoteSimObject)moteI.next();
		    if(mote!=null){
			simComm.sendCommand(new SetADCPortValueCommand((short) mote.getID(), 0L, leader.mover.getLeaderAdcChannel(), 0));
		    }
		}
		    //                }
		leader.leaderID=-1;
            }
            return;
        }
        Enumeration enum = leaders.elements();
        double x,y,dist,minDist;
        MoteCoordinateAttribute coord;
        Iterator moteIterator;
        int closest,i;
        while (enum.hasMoreElements()) {
            Leader leader = (Leader) enum.nextElement();
            minDist = Double.MAX_VALUE;
            closest=-1;
            moteIterator = state.getMoteSimObjects().iterator();
            if(leader.mover.isRegistered()){
                x = leader.mover.getXPosition();
                y = leader.mover.getYPosition();
                while(moteIterator.hasNext()){
                    MoteSimObject mote=(MoteSimObject)moteIterator.next();
                    coord = mote.getCoordinate();
                    dist=Math.sqrt( Math.pow(x-coord.getX(),2) + Math.pow(y-coord.getY(),2));
                    if(dist<minDist){
                        closest=mote.getID();
                        minDist=dist;
                    }
                }
                if(closest != leader.leaderID){
                    if(leader.leaderID!=-1)
                        simComm.sendCommand(new SetADCPortValueCommand((short) leader.leaderID, 0L, leader.mover.getLeaderAdcChannel(), 0));
                    simComm.sendCommand(new SetADCPortValueCommand((short) closest, 0L, leader.mover.getLeaderAdcChannel(), 1));
                    leader.leaderID=closest;
                }
            }
            else
                leader.leaderID=-1;
        }
    }

    public void register() {
        JTextArea ta = new JTextArea(2, 50);
        ta.setFont(tv.defaultFont);
        ta.setEditable(false);
        ta.setBackground(Color.lightGray);
        ta.setLineWrap(true);
        ta.setText("This plugin will choose leaders as determined by the motion plugins that you enable.");
        pluginPanel.add(ta);

        Plugin plugins[] = tv.getPluginPanel().plugins();
        for(int i=0;i<plugins.length;i++){
            if(plugins[i] instanceof MotionPlugin){
                registerLeader((MotionPlugin)plugins[i]);
            }
        }
    }

    public void deregister
            () {
    }

    public void draw(Graphics graphics) {
        Enumeration enum = leaders.elements();
        while (enum.hasMoreElements()) {
            Leader leader = (Leader) enum.nextElement();
            MoteSimObject mote = state.getMoteSimObject(leader.leaderID);
            if (mote == null) continue;
            MoteCoordinateAttribute coord = mote.getCoordinate();
            graphics.setColor(leader.mover.getColor());
            graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 10, (int) cT.simYToGUIY(coord.getY()) - 10, 20, 20);
            graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 9, (int) cT.simYToGUIY(coord.getY()) - 9, 18, 18);
            graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 8, (int) cT.simYToGUIY(coord.getY()) - 8, 16, 16);
        }
    }

    public String toString
            () {
        return "Leader Election";
    }

    public void registerLeader(MotionPlugin mover){
        leaders.add(new Leader(mover));
    }

    class Leader {
        MotionPlugin mover;
        int leaderID;

        public Leader(MotionPlugin Mover){
            mover=Mover;
            leaderID=-1;
        }
    }
}


