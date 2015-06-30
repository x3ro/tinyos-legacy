// $Id: PlotPlugin.java,v 1.3 2003/10/31 04:12:50 mikedemmer Exp $

/* Author Kamin Whitehouse

*/

package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.plot.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.plugins.DirectedGraphPlugin;
import net.tinyos.sim.event.*;
import net.tinyos.matlab.*;

public class PlotPlugin extends GuiPlugin implements SimConst {
    public plotpanel plots;

    private TextArea helpText= new TextArea(
    "This plugin plots points on a graph that are provided using tossim's dbg commands.  \n" +
            "Each point belongs to a plot and the plots can be selected from a drop down list.\n\n"+

    "There are three commands that can be used with this plugin:\n\n"+

    "  dbg(DBG_USR1, \"MyPlotName PLOT: add point x: %d y: %d [params] [options]\\n\", x,y);\n"+
    "  dbg(DBG_USR1, \"MyPlotName PLOT: remove point x: %d y: %d [options]\\n\", x,y); \n"+
    "  dbg(DBG_USR1, \"MyPlotName PLOT: set options [options] \\n\"); \n\n"+

    "These will have the effect of adding or removing a point to a plot.  \n"+
    "MyPlotName\" will automatically appear in the plugin drop-down list and\n"+
    "you can select it to see all the points added to that graph.\n" +
            "Add or remove the plot from the graph window with the +/- buttons.\n\n"+

    "note that you can also add your own plots using analytical functions\n"+
    "e.g. f(x)=x; f(x)=5; f(x)=sin(x) for comparison with the empirical data.\n" +
            "Do this by entering the equation in the bottom panel with a name next to it.\n\n"+

    "There are several parameters you can append to the \"add\" command and options that you\n"+
    "can append to any of the three commands:\n\n"+

    "parameters:\n"+
    "\"color: 0xRRGGBB\" will cause the point to have a color (default blue).\n\n"+

    "\"label: myLable\" will cause the point to have the word \"myLabel\" printed next to it.\n\n"+

    "\"radius: X\" will cause the point to have a radius of X. \n\n"+

    "\"timeout: xxx\" will cause the edge to disappear after xxx milliseconds of simulated time. \n\n"+

    "options:\n"+
    "\"autoScale: true | false\"  will cause the screen to fit all data points or not \n\n"+

    "\"plotStyle: dots | lines | both\" will cause the plot to be scatter or line plot\n\n"+

    "\"xMin: X\" set the min x value on the axis.\n\n"+

    "\"xMax: X\" set the max x value on the axis.\n\n"+

    "\"yMin: Y\" set the min y value on the axis.\n\n"+

    "\"yMax: Y\" set the max y value on the axis.");

    public PlotPlugin(){
        super();
    }

    public void handleEvent(SimEvent event) {
        if (event instanceof TossimInitEvent) {
            plots.init();
        } else if (event instanceof DebugMsgEvent) {
            DebugMsgEvent dme = (DebugMsgEvent) event;
            if (dme.getMessage().indexOf("PLOT:") != -1) {
                int timeout=-1;
                double x = -1 ,y=-1;
                double radius = 1;
                String label=null;
                Color color=null;
                StringTokenizer st = new StringTokenizer(dme.getMessage());
                String plotName = st.nextToken();
                EmpiricalFunction f=(EmpiricalFunction)plots.getFunction(plotName);
                if(f==null)
                    f = new EmpiricalFunction();

                st.nextToken(); //"PLOT"
                while(st.hasMoreTokens()){
                    String paramName=st.nextToken();
                    if(paramName.equals("label:")){
                        label= st.nextToken();
                    }
                    else if(paramName.equals("x:")){
                        x= Double.parseDouble(st.nextToken());
                    }
                    else if(paramName.equals("y:")){
                        y= Double.parseDouble(st.nextToken());
                    }
                    else if(paramName.equals("radius:")){
                        radius= Double.parseDouble(st.nextToken());
                    }
                    else if(paramName.equals("timeout:")){
                        timeout= Integer.parseInt(st.nextToken()) + (int)(tv.getTosTime()*1000);
                    }
                    else if(paramName.equals("color:")){
                        try{
                            color=new Color(Integer.decode(st.nextToken()).intValue());
                        }
                        catch(Exception e){}
                    }
                    else if(paramName.equals("xMin:")){
                        plots.setMinX(Double.parseDouble(st.nextToken()));
                    }
                    else if(paramName.equals("yMin:")){
                        plots.setMinY(Double.parseDouble(st.nextToken()));
                    }
                    else if(paramName.equals("xMax:")){
                        plots.setMaxX(Double.parseDouble(st.nextToken()));
                    }
                    else if(paramName.equals("yMax:")){
                        plots.setMaxY(Double.parseDouble(st.nextToken()));
                    }
/*                    else if(paramName.equals("timeout:")){
                        timeout= (int)(tv.getTosTime()*1000) + Integer.parseInt(st.nextToken());
                    }*/
/*                    else if(paramName.equals("autoScale:")){
                        plot.autoScale= Boolean.getBoolean(st.nextToken());
                    }*/
                    else if(paramName.equals("plotStyle:")){
                        f.plotStyle=st.nextToken();
                    }
                    else if(paramName.equals("autoScale:")){
                        boolean onOff = Boolean.getBoolean(st.nextToken());
                        plots.setFitToScreen(onOff);
                        if(onOff) plots.FitToScreen();
                    }
                }

                //dbg("XX PLOT: add point XX")
                if (dme.getMessage().indexOf("add point") != -1) {
                    f.points.add(f.new PlotPoint(x,y,radius, timeout, color,label));
                }
                //dbg("XX PLOT: remove point XX")
                else if (dme.getMessage().indexOf("remove point") != -1) {
                    while(f.points.remove(f.new PlotPoint(x,y,radius, timeout, color,label)));
                }
                plots.includePoint(x,y);
                plots.addFunction(f,color,plotName);
                plots.repaint();
            }
        }
    }

    public void register() {
        pluginPanel.setLayout (new BorderLayout());

        plots = new plotpanel();
        plots.setPreferredSize(new Dimension(500, 350));
        plots.setTv(tv);

        pluginPanel.add (plots, BorderLayout.CENTER);
        pluginPanel.add (new plotcontrolpanel(plots, helpText), BorderLayout.NORTH);
        pluginPanel.add (new plotformulapanel(plots), BorderLayout.SOUTH);

//        pluginPanel.add(plPanel);
        pluginPanel.revalidate();

    }

    public void deregister() {
    }

    public void draw(Graphics graphics) {
    }

    public String toString() {
        return "Plot";
    }
}


