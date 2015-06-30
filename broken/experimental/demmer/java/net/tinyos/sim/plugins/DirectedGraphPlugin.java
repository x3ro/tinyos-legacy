// $Id: DirectedGraphPlugin.java,v 1.2 2003/10/20 22:35:57 mikedemmer Exp $

/* Author Kamin Whitehouse

while this component draws directed graphs, the following code is organized in
terms of neighborhoods, ie. all edges are grouped by the origin node,
so that the user can see only edges from one node if he/she desires.  */




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

public class DirectedGraphPlugin extends GuiPlugin implements SimConst, ActionListener  {
    private TextArea helpText= new TextArea(
    "The DirectedGraphPlugin allows the user to define multiple directed graphs in their TinyOS code \n" +
            "and have them automatically appear as arrows in TinyViz.\n\n"+

    "There are two commands that can be used with this plugin:\n\n"+

    "  dbg(DBG_USR1, \"MyGraphName DIRECTED GRAPH: add edge %d \\n\", someOtherNode);\n"+
    "  dbg(DBG_USR1, \"MyGraphName DIRECTED GRAPH: remove edge %d \\n\", someOtherNode);\n\n"+
    "  dbg(DBG_USR1, \"MyGraphName DIRECTED GRAPH: clear\\n\");\n\n"+

    "These will have the effect of adding or removing edges between someOtherNode\n" +
            "and TOS_LOCAL_ADDRESS.  \"MyGraphName\" will automatically appear \n" +
            "in the plugin drop-down list and "+
    "you can select it to see all the arrows added to that graph.\n\n" +

            "To see only the edges originating with a particular node, select the \"selected motes only\" box.\n\n" +

    "There are several parameters you can append to the \"add\" command:\n\n"+

    "\"color: 0xRRGGBB\" will cause the edge to have a color (default blue).\n\n"+

    "\"label: myLable\" will cause the arrow to have the word \"myLabel\" printed next to it.\n\n"+

    "\"timeout: xxx\" will cause the edge to disappear after xxx milliseconds of simulated time. \n\n"+

    "\"offset: xxx\" will cause the edge be displayed xxx pixels to the side (useful for multiple colored arrows). \n\n"+

    "\"direction: forward | backward | both | none\" will cause the edge of that arrow to point either \n" +
            "towards someNodeID or towards TOS_LOCAL_ADDRESS or both or neither.\n\n" +

    "\"sourceNode: someOtherNodeID\" will cause the edge to originate from someOtherNodeID instead of TOS_LOCAL_ADDRESS.\n\n" +
            "EXAMPLE:\n\n"+

"An example of an \"add\" command with all four options is:\n\n"+

"dbg(DBG_USR1, \"MyGraphName DIRECTED GRAPH: add edge %d color: 0xFF0000 label: %d timeout: 500 direction: both sourceNode: 0\\n\", someNodeID, TOS_LOCAL_ADDRESS);\n\n"+

"This command will cause the edge to be drawn in both directions between node 0\n"  +
"and node someNodeID in RED with the label having the current node's address ID,\n"+
"and the edge will disappear after 500 milliseconds.\n");

    private Hashtable neighborhoods = new Hashtable();
    private JCheckBox cbSelectedOnly;
    private boolean selectedOnly = false;
//    JComboBox cb = new JComboBox();
    JList graphList = new JList();
//    String drawingHood;
    Vector knownHoods = new Vector();

    public void handleEvent(SimEvent event) {
        if (event instanceof AttributeEvent) {
            AttributeEvent ae = (AttributeEvent) event;
            if (ae.getType() == AttributeEvent.ATTRIBUTE_CHANGED) {
                if (ae.getOwner() instanceof MoteSimObject &&
                        ae.getAttribute() instanceof MoteCoordinateAttribute) {
                    tv.getMotePanel().refresh();
                }
            }
        } else if (event instanceof TossimInitEvent) {
            neighborhoods.clear();
            knownHoods=new Vector();
            graphList.setListData(knownHoods);
            pluginPanel.revalidate();
        } else if (event instanceof DebugMsgEvent) {
            DebugMsgEvent dme = (DebugMsgEvent) event;
            if (dme.getMessage().indexOf("DIRECTED GRAPH:") != -1) {
                int nodeID = dme.getMoteID(),neighborID=-1, timeout=-1, offset=0, direction=Arrow.SIDE_LEAD;
                String label=null;
                Color color=Color.lightGray;
                StringTokenizer st = new StringTokenizer(dme.getMessage());
                String hood = st.nextToken();
                if (dme.getMessage().indexOf("clear") != -1) {
                    clearAll(hood);
                    return;
                }
                    if(!knownHoods.contains(hood)){
                    knownHoods.add(hood);
                    int length;
                    int[] selected=null;
                    if(knownHoods.size()>1){
                        selected = graphList.getSelectedIndices();
                        length=selected.length+1;
                    }
                    else length=1;
                    int[] newSelected = new int[length];
                    for(int i=0;i<length-1;i++){
                        newSelected[i]=selected[i];
                    }
                    newSelected[newSelected.length-1]=knownHoods.size()-1;
                    graphList.setListData(knownHoods);
                    graphList.setSelectedIndices(newSelected);
//                    graphList.setSelectedIndex(knownHoods.size()-1);
                }

                st.nextToken(); st.nextToken(); st.nextToken(); st.nextToken();
                neighborID =Integer.parseInt(st.nextToken());
                while(st.hasMoreTokens()){
                    String paramName=st.nextToken();
                    if(paramName.equals("label:")){
                        label= st.nextToken();
                    }
                    else if(paramName.equals("sourceNode:")){
                        nodeID= Integer.parseInt(st.nextToken());
                    }
                    else if(paramName.equals("timeout:")){
                        timeout= (int)(tv.getTosTime()*1000) + Integer.parseInt(st.nextToken());
                    }
                    else if(paramName.equals("offset:")){
                        offset= Integer.parseInt(st.nextToken());;
                    }
                    else if(paramName.equals("color:")){
                        try{
                            color=new Color(Integer.decode(st.nextToken()).intValue());
                        }
                        catch(Exception e){}
                    }
                    else if(paramName.equals("direction:")){
                        String dir = st.nextToken();
                        if(dir.equals("forward")){
                            direction=Arrow.SIDE_LEAD;
                        }
                        else if(dir.equals("backward")){
                            direction=Arrow.SIDE_TRAIL;
                        }
                        else if(dir.equals("both")){
                            direction=Arrow.SIDE_BOTH;
                        }
                        else if(dir.equals("none")){
                            direction=Arrow.SIDE_NONE;
                        }
                    }
                }

                MoteSimObject mote1 = state.getMoteSimObject(nodeID);
                MoteSimObject mote2 = state.getMoteSimObject(neighborID);
                if(mote1==null || mote2==null) return;

                Neighborhood neighborhood;
                if (neighborhoods.containsKey(new Integer(nodeID)))
                    neighborhood = (Neighborhood) neighborhoods.get(new Integer(nodeID));
                else {
                    neighborhood = new Neighborhood(nodeID);
                }

                //dbg("XX DIRECTED GRAPH: add edge XX")
                if (dme.getMessage().indexOf("add edge") != -1) {
                    neighborhood.neighbors.add(new Neighbor(neighborID, hood, color, label, direction, timeout, offset));
                    neighborhoods.put(new Integer(nodeID),neighborhood);
                }
                //dbg("XX DIRECTED GRAPH: remove edge  XX")
                else if (dme.getMessage().indexOf("remove edge") != -1) {
                    while(neighborhood.neighbors.remove(new Neighbor(neighborID, hood)));
                    neighborhoods.put(new Integer(nodeID),neighborhood);
                }
                tv.getMotePanel().refresh();
            }
//            motePanel.refresh();
        }
    }

    public void register() {

/*        JTextArea ta = new JTextArea(2, 50);
        ta.setFont(tv.defaultFont);
        ta.setEditable(false);
        ta.setBackground(Color.lightGray);
        ta.setLineWrap(true);
        ta.setText("This plugin allows you to define graphs, add edges and remove edges with the two following commands."+
                "To display one such graph, select it from the list below.  One can also add " +
                "color or labels to the edges or change the directions of the arrows; see DirectedGraphPlugin.java for documentation.");
        pluginPanel.add(ta);

        JTextArea ta2 = new JTextArea(1, 50);
        ta2.setFont(tv.defaultFont);
        ta2.setEditable(false);
        ta2.setBackground(Color.lightGray);
        ta2.setLineWrap(true);
        ta2.setText("dbg(DBG_USR1, \"MyGraphName DIRECTED GRAPH: remove edge %d\n\", someNodeID);.");
        pluginPanel.add(ta2);

        JTextArea ta3 = new JTextArea(1, 50);
        ta3.setFont(tv.defaultFont);
        ta3.setEditable(false);
        ta3.setBackground(Color.lightGray);
        ta3.setLineWrap(true);
        ta3.setText("dbg(DBG_USR1, \"MyGraphName DIRECTED GRAPH: add edge %d\n\", someNodeID);");
        pluginPanel.add(ta3);
  */
        JPanel parameterPane = new JPanel();
        parameterPane.setLayout(new GridLayout(7,2,1,1));

        // Create radius constant text field and label
        JLabel neighborhoodNameLabel = new JLabel("Graph Name");
        neighborhoodNameLabel.setFont(tv.defaultFont);

//        cb.addActionListener(new ComboBoxListener());

        parameterPane.add(neighborhoodNameLabel);
//        parameterPane.add(cb);
        parameterPane.add(graphList);

        cbSelectedOnly = new JCheckBox("Selected motes only", selectedOnly);
        cbSelectedOnly.addItemListener(new DirectedGraphPlugin.cbListener());
        cbSelectedOnly.setFont(tv.labelFont);

        parameterPane.add(cbSelectedOnly);

        JButton help = new JButton ("Instructions");
        help.setToolTipText("help");
        help.setFont(new Font("Helvetica", Font.PLAIN, 12));
        help.setForeground(Color.blue);
        help.setActionCommand("help");
        help.addActionListener (this);
        parameterPane.add(help);

        pluginPanel.add(parameterPane);

        pluginPanel.revalidate();

    }

    public void deregister
            () {
    }

    public void draw(Graphics graphics) {
        Enumeration enum = neighborhoods.elements();
        while (enum.hasMoreElements()) {
            Neighborhood neighborhood = (Neighborhood) enum.nextElement();
            MoteSimObject mote = state.getMoteSimObject(neighborhood.nodeID);
            if (mote == null) continue;
            MoteCoordinateAttribute coord = mote.getCoordinate();
            if (!selectedOnly ||
            state.getSelectedMoteSimObjects().contains(state.getMoteSimObject(neighborhood.nodeID))) {
                Enumeration neighbors = neighborhood.neighbors.elements();
                while (neighbors.hasMoreElements()) {
                    Neighbor neighborID = (Neighbor) neighbors.nextElement();
                    MoteSimObject neighbor = state.getMoteSimObject(neighborID.nodeID);
                    if( (neighbor == null) || (!isSelected(neighborID.neighborhood)) || (neighborID.timeout >=0 && neighborID.timeout < tv.getTosTime()*1000)) continue;
                    MoteCoordinateAttribute neighborCoord = neighbor.getCoordinate();
                    graphics.setColor(neighborID.color);
                    int x1=(int) cT.simXToGUIX(coord.getX())+neighborID.offset;
                    int y1=(int) cT.simYToGUIY(coord.getY())+neighborID.offset;
                    int x2=(int) cT.simXToGUIX(neighborCoord.getX())+neighborID.offset;
                    int y2=(int) cT.simYToGUIY(neighborCoord.getY())+neighborID.offset;
                    Arrow.drawArrow(graphics,x1, y1,x2, y2,neighborID.direction);
                    if(neighborID.label!=null){
                        int xMidPoint = x1 + (x2-x1)/2;
                        int yMidPoint = y1 + (y2-y1)/2;
                        graphics.drawString(neighborID.label, xMidPoint, yMidPoint);
                    }
                }
            }
        }
    }

    public void clearAll(String hoodName) {
        Enumeration enum = neighborhoods.elements();
        while (enum.hasMoreElements()) {
            Neighborhood neighborhood = (Neighborhood) enum.nextElement();
            Enumeration neighbors = neighborhood.neighbors.elements();
            while (neighbors.hasMoreElements()) {
                Neighbor neighborID = (Neighbor) neighbors.nextElement();
                if(neighborID.neighborhood.equalsIgnoreCase(hoodName)){
                    neighborhood.neighbors.remove(neighborID);
                }
            }
        }
    }

    public boolean isSelected(String graphName){
        int selectedGraphs[] = graphList.getSelectedIndices();
        for(int i=0; i<selectedGraphs.length;i++){
            if(((String)knownHoods.get(selectedGraphs[i])).equalsIgnoreCase(graphName)){
                return true;
            }
        }
        return false;
    }

    public String toString
            () {
        return "Directed Graph";
    }

    public class Neighborhood {
        public int nodeID;
        public Vector neighbors;

        Neighborhood(int id) {
            nodeID=id;
            neighbors=new Vector();
        }

    }

    public class Neighbor {
        public int nodeID;
        public String neighborhood;
        public Color color;
        public String label;
        public int direction;
        public int timeout;
        public int offset; //this draws the arrow a little to the side

        Neighbor(int id, String hood, Color colour, String Label, int Direction, int Timeout, int Offset) {
            nodeID=id;
            neighborhood=hood;
            color=colour;
            label=Label;
            direction=Direction;
            timeout=Timeout;
            offset=Offset;
        }

        Neighbor(int id, String hood) {
            nodeID=id;
            neighborhood=hood;
        }

        public boolean equals(Object obj){
            return (nodeID==((Neighbor)obj).nodeID &&
                    (neighborhood.equals(((Neighbor)obj).neighborhood)));
        }
    }

   class cbListener implements ItemListener {
    public void itemStateChanged(ItemEvent e) {
      selectedOnly = (e.getStateChange() == e.SELECTED);
    }
  }

/*  class ComboBoxListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      drawingHood = (String)cb.getSelectedItem();
      motePanel.refresh();
    }
  }                         */

    public void actionPerformed (ActionEvent e) {
        try {
        if(e.getActionCommand() == "help") {
            if(helpText!=null){
                JDialog dialog = new JDialog();
                dialog.getContentPane().add(helpText);
                dialog.setSize(600,700);
                dialog.setVisible(true);
            }
        }
        } catch(Exception ee) {
        }

    }

}



