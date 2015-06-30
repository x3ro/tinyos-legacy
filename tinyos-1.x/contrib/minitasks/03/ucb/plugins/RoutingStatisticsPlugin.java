/* Author Kamin Whitehouse

*/

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.plugins.DirectedGraphPlugin;
import net.tinyos.sim.plugins.PlotPlugin;
import net.tinyos.sim.event.*;
import net.tinyos.matlab.*;
import net.tinyos.plot.EmpiricalFunction;
import net.tinyos.plot.EmpiricalFunction.PlotPoint;

public class RoutingStatisticsPlugin extends Plugin implements SimConst {
    private Hashtable routes = new Hashtable();
    private int lastSecUpdated=0;
    private PlotPlugin plotPlugin;
    private Vector mesgs = new Vector();

    private EmpiricalFunction bandwidthPlot = new EmpiricalFunction();
    private EmpiricalFunction latencyPlot = new EmpiricalFunction();
    private EmpiricalFunction lossRatePlot = new EmpiricalFunction();
    private EmpiricalFunction energyPlot = new EmpiricalFunction();

    private static final double BANDWIDTH_WINDOW=1;
    private static final double ENERGY_WINDOW=1;
    private static final double LOSS_RATE_WINDOW=1;
    private static final double LATENCY_WINDOW=1;
    private static final double TTL=2;

    public void handleEvent(SimEvent event) {
        if (event instanceof RadioMsgSentEvent) {
            mesgs.add(new Mesg(tv.getTosTime()));
        }
        if (event instanceof TossimInitEvent) {
            bandwidthPlot.points.clear();
            latencyPlot.points.clear();
            lossRatePlot.points.clear();
            energyPlot.points.clear();
            if(plotPlugin!=null){
                plotPlugin.plots.setMaxX(5);
                plotPlugin.plots.setMinX(-5);
                plotPlugin.plots.setMaxY(5);
                plotPlugin.plots.setMinY(-5);
            }
            lastSecUpdated=0;
            mesgs=new Vector();
            routes.clear();
        } else if (event instanceof DebugMsgEvent) {
            DebugMsgEvent dme = (DebugMsgEvent) event;
            if (dme.getMessage().indexOf("ROUTING") != -1) {
                System.out.println(dme.getMessage());
                StringTokenizer st = new StringTokenizer(dme.getMessage());
                st.nextToken(); st.nextToken();
//                int nodeID = dme.getMoteID();
                int sourceID = Integer.parseInt(st.nextToken());
                int seqNo = Integer.parseInt(st.nextToken());
                if (dme.getMessage().indexOf("sent") != -1) {
                    routes.put(new TwoKey(sourceID,seqNo), new Route(sourceID, seqNo));
                    System.out.println("new route: " + sourceID + " " + seqNo);
                }
                else if (dme.getMessage().indexOf("forwarded") != -1) {
                    Route r = (Route)routes.remove(new TwoKey(sourceID,seqNo));
                    if(r==null) return;
                    r.Forwarded();
                    routes.put(new TwoKey(sourceID,seqNo), r);
                    System.out.println("forwarded: " + sourceID + " " + seqNo);
                }
                else if (dme.getMessage().indexOf("received") != -1) {
                    Route r = (Route)routes.remove(new TwoKey(sourceID,seqNo));
                    if(r==null) return;
                    r.Received();
                    routes.put(new TwoKey(sourceID,seqNo), r);
                    System.out.println("received: " + sourceID + " " + seqNo);
                }
            }
        }

        //now, see if we should update the plots
        double time = tv.getTosTime();
        if(time-lastSecUpdated>=1){
            lastSecUpdated=(int)time;
            int numReceived=0, numSent=0, numNotLost=0, numMsgs=0;
            Vector latencies=new Vector();
            Enumeration e = routes.elements();
            while(e.hasMoreElements()){
                Route route = (Route)e.nextElement();

                //plot the bandwidth
                if(time - route.receiveTime <BANDWIDTH_WINDOW && time - route.receiveTime >0 && route.received){
                    numReceived++;
                }

                //plot the latency
                if(time - route.receiveTime <LATENCY_WINDOW && time - route.receiveTime >0 && route.received){
                    latencies.add(new Double(route.receiveTime-route.sendTime));
                }

                //plot the loss rate
                if(time - route.receiveTime <LOSS_RATE_WINDOW && time - route.receiveTime >0){
                    if(route.received){
                        numNotLost++;
                    }
                    numSent++;
                }
            }

            e = mesgs.elements();
            while(e.hasMoreElements()){
                Mesg route = (Mesg)e.nextElement();

                //plot the energy
                if(time - route.time <ENERGY_WINDOW ){
                    numMsgs++;
                }
            }

            Enumeration l = latencies.elements();
            double total=0;
            while(l.hasMoreElements()){
                Double latency = (Double)l.nextElement();
                total+=latency.doubleValue();
            }

            registerPlots();
            //now add the collected statistics to the plots
            bandwidthPlot.points.add(bandwidthPlot.new PlotPoint(lastSecUpdated,numReceived,1, -1, null,null));
            System.out.println("numReceived = "+ numReceived);
            energyPlot.points.add(energyPlot.new PlotPoint(lastSecUpdated,numMsgs,1, -1,null,null));
            System.out.println("numMsgs= "+ numMsgs);
            lossRatePlot.points.add(lossRatePlot.new PlotPoint(lastSecUpdated,(numSent==0)?0:numNotLost/(numSent*1.0),1, -1,null,null));
            System.out.println("delivery rate = " + ((numSent==0)?0:numNotLost/(numSent*1.0)) + "; numNotLost = "+ numNotLost + "; numSent = "+ numSent);
            latencyPlot.points.add(latencyPlot.new PlotPoint(lastSecUpdated,(latencies.size()==0)?0:total/(1.0*latencies.size()),1, -1, null,null));
            System.out.println("latency = "+ ((latencies.size()==0)?0:total/(1.0*latencies.size())));

//            plotPlugin.plots.includePoint(x,y);
            plotPlugin.plots.repaint();
        }
    }

    void registerPlots(){
        if(plotPlugin==null){
            System.out.println("the Routing plugin rquires the Plot plugin.");
            return;
        }
        if(plotPlugin.plots.getFunction(new String("Bandwidth (#msgs)"))==null)
            plotPlugin.plots.addFunction(bandwidthPlot, Color.blue.darker(), "Bandwidth (#msgs)");
        if(plotPlugin.plots.getFunction(new String("Energy (#msgs)"))==null)
            plotPlugin.plots.addFunction(energyPlot, Color.red.darker(), "Energy (#msgs)");
        if(plotPlugin.plots.getFunction(new String("Delivery Rate (%)"))==null)
            plotPlugin.plots.addFunction(lossRatePlot, Color.green.darker(), "Delivery Rate (%)");
        if(plotPlugin.plots.getFunction(new String("Latency (sec)"))==null)
            plotPlugin.plots.addFunction(latencyPlot, Color.orange.brighter(), "Latency (sec)");


    }

    public void register() {
        JTextArea ta = new JTextArea(2, 50);
        ta.setFont(tv.defaultFont);
        ta.setEditable(false);
        ta.setBackground(Color.lightGray);
        ta.setLineWrap(true);
        ta.setText("this plugin listens to ROUTING dbg messages and plots statistics.");
        pluginPanel.add(ta);

        Plugin plugins[] = tv.getPluginPanel().plugins();
        for(int i=0;i<plugins.length;i++){
            if(plugins[i] instanceof PlotPlugin){
                plotPlugin = ((PlotPlugin)plugins[i]);
                break;
            }
        }

    }

    public void deregister
            () {
    }

    public void draw(Graphics graphics) {
    }

    public String toString() {
        return "Routing";
    }

    public class Neighborhood {
        public int nodeID;
        public Vector neighbors;

        Neighborhood(int id) {
            nodeID=id;
            neighbors=new Vector();
        }

    }

    private class Route{
        int sourceID;
        int seqNo;
        double sendTime;
        double receiveTime;
        boolean received;
        int forwards;
        public Route(int Source, int Seq){
            sourceID=Source;
            seqNo=Seq;
            sendTime = tv.getTosTime();
            receiveTime=sendTime+TTL;
            received=false;
            forwards = 0;
        }

        public void Forwarded(){
            forwards++;
        }

        public void Received(){
            received=true;
            receiveTime=tv.getTosTime();
        }

    }

    private class Mesg{
        public double time;
        public Mesg(double t){
            time=t;
        }
    }

    private class TwoKey{
        public Object key1;
        public Object key2;
        public TwoKey(Object k1, Object k2){
            key1=k1;
            key2=k2;
        }

        public TwoKey(int k1, int k2){
            key1=new Integer(k1);
            key2=new Integer(k2);
        }

        public int hashCode(){
            return key1.hashCode() + key2.hashCode();
        }

        public boolean equals(Object twoKey){
            return key1.equals( ((TwoKey)twoKey).key1) && key2.equals( ((TwoKey)twoKey).key2) ;
        }

    }

}



