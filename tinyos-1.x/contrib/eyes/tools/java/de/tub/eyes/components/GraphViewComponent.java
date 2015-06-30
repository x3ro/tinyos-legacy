/*
 * Created on Aug 9, 2004 by jpraetorius
 * Project SwingTest
 *
 */
package de.tub.eyes.components;

import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.*;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;

import net.tinyos.message.Message;
import net.tinyos.surge.*;
import net.tinyos.drain.*;

import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.builder.DefaultFormBuilder;
import com.jgoodies.forms.factories.ButtonBarFactory;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;

import de.tub.eyes.comm.MessageReceiver;
import de.tub.eyes.gui.customelements.CaptionBorder;
import de.tub.eyes.gui.customelements.Oscope;
import de.tub.eyes.model.DataPoint;
import de.tub.eyes.ps.*;
import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.apps.PS.PSSubscription;

/**
 * <p>
 * This class embeds a {@link de.tub.eyes.gui.customelements.PlotGraph PlotGraph} in the
 * form being necessary for the Demonstrator. Additionally it implements the FilterView
 * interface, so only Messages of nodes being added to the Filter are displayed.
 * Depicted in the graph is the reading of the node over the id of the Time-series.
 * </p>
 * <p>
 * <b>Note:</b> This component is currently fixed to receiving SurgeMsg's and can not derive
 * data from other Messages until not being adapted to that.
 * </p>
 * @author Joachim Praetorius
 * @see de.tub.eyes.gui.customelements.PlotGraph
 */
//public class GraphViewComponent extends AbstractComponent implements
//        MessageReceiver, ActionListener, FilterView {
public class GraphViewComponent extends AbstractComponent implements
        MessageReceiver, FilterView {

    //private PlotGraph grapho;
    private Oscope graph;
    private FormLayout layout;
    private CellConstraints cc;
    private JPanel panel;
    private PanelBuilder builder;
//    private DefaultFormBuilder builder;
    private JToggleButton button;

    private static List filter;
    private static Date startTime = new Date();
    private boolean ENABLE = false;
    
    private static ConfigComponent config = Demonstrator.getConfigComponent();    

    /**
     * Constructor. Creates a new graph and a new List for Filter items.
     *
     */
    public GraphViewComponent() {
        filter = new ArrayList();
        graph = new Oscope();

        buildUI();        
    }

    public void initScope() {
      graph.init();
      //graph.panel.repaint();
      graph.start();
   
      ENABLE = true;
    }
    public void repaint() {
        graph.panel.setVisible(true);
        graph.panel.repaint();
        graph.repaint();
    }

    /**
     * Returns the ToggleButton for this component
     * @see de.tub.eyes.components.AbstractComponent#getButton()
     */
    public JToggleButton getButton() {
        return button;
    }

    /**
     * Returns the UI for this Component. In the given case this is a JPanel
     * @see de.tub.eyes.components.AbstractComponent#getUI()
     */
    public Component getUI() {

        CompoundBorder b = new CompoundBorder(new CaptionBorder("Graph View"),
                new EmptyBorder(10, 10, 10, 10));
        panel.setBorder(b);
        initScope();

        return panel;
    }

    /**
     * Creates the UI by adding the components to a container.
     *
     */
    private void buildUI() {
        panel = new JPanel();
        //layout = new FormLayout("f:p:g", "f:p:g,6dlu,t:p");
        layout = new FormLayout("f:p:g", "f:p:g");
        builder = new PanelBuilder(panel, layout);
        //builder = new DefaultFormBuilder(panel, layout);
        cc = new CellConstraints();
        builder.add(graph, cc.xy(1, 1));
        
        button = new JToggleButton("<html>Graph<br>View");
        button.setHorizontalAlignment(JButton.LEFT);        
        button.setActionCommand("graphview");
    }

    /**
     * Used to receive and display messages. Currently this methods only displays
     * {@link SurgeMsg SurgeMsg}s. Additionally these are only displayed, when the
     * id of the sending node (determined via <code>msg.get_originaddr()</code>) is
     * in the List of filtered nodes.
     * @see de.tub.eyes.MessageReceiver#receiveMessage(net.tinyos.message.Message)
     */
    public void receiveMessage(Message m) {
        Date rcvTime = new Date();
        DataPoint dp;       
        
        if (m instanceof SurgeMsg) {                        
            MultihopMsg msg = new MultihopMsg(m.dataGet());
            //SurgeMsg surgeMsg = new SurgeMsg(msg.dataGet(), msg.offset_data(0));
            SurgeMsg surgeMsg = new SurgeMsg(msg.dataGet(), 6);

            int source = msg.get_originaddr();
            for (Iterator it = filter.iterator(); it.hasNext();) {
                Integer ID = (Integer) it.next();
                if (ID.intValue() == source) {
                    //int x = msg.get_seqno();
                    int x = (int)((rcvTime.getTime()-startTime.getTime())/1000);
                    int y = surgeMsg.get_reading();

                    dp = new DataPoint(ID.intValue(), x, y);

                    graph.addData(dp);
                }
            }
        }
        else if (Demonstrator.isDrip()) {
            if (!(m instanceof DrainMsg))
                return;

            DrainMsg mhmsg = (DrainMsg)m;
            PSNotificationMsg msgTemp = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0));
            PSNotificationMsg ps2Msg = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0), 
                    msgTemp.DEFAULT_MESSAGE_SIZE + msgTemp.get_dataLength());
            
            if ( ps2Msg.get_flags() != 2 )
                return;
  
            int source = ps2Msg.get_sourceAddress();            
            for (Iterator it = filter.iterator(); it.hasNext();) {
                Integer ID = (Integer) it.next();
                if (ID.intValue() == source) {
                    for (int i=0; i< ps2Msg.getAVPairCount(); i++) {
                        int attrID = ps2Msg.getAVPairAttributeID(i);
                        if ( attrID == config.getOscopeAttribute()) {
                            long x = (int)((rcvTime.getTime()-startTime.getTime())/1000);
                            double y=0;
                            Object res = PSSubscription.arrayToObject(ps2Msg.getAVPairValue(i), attrID);
                            
                            if (res instanceof Long)
                                y = ((Long)res).doubleValue();
                            else if (res instanceof Double)
                                y = ((Double)res).doubleValue();
                            else
                                continue;
                            
                            dp = new DataPoint(ID.intValue(), x, y);
                            graph.addData(dp);                            
                        }
                    }                    
                }
            }
            
        }
        else {
            //System.out.println("Osci revv");
            
            // We only support drip, currently !
   /*
            MultihopMsg msg = new MultihopMsg(m.dataGet());
            PS_PubMsg psMsg = new PS_PubMsg(msg.dataGet(), msg.offset_data(0));
            int source = msg.get_originaddr();
                        
            for (Iterator it = filter.iterator(); it.hasNext();) {            
                Integer ID = (Integer) it.next();
                if (ID.intValue() == source) {                
                    for (int i=0; i< psMsg.get_publication_numPubData(); i++) {                            
                        if (psMsg.getElement_publication_data_attribute(i) == config.getOscopeAttribute()) {                                
                            int x = (int)((rcvTime.getTime()-startTime.getTime())/1000);
                            int y = psMsg.getElement_publication_data_value(0,0);

                            dp = new DataPoint(ID.intValue(), x, y);

                            graph.addData(dp);
                        } // attrib matches
                    } // for attribs
                } // source match
            } // for filters    
    */        
        }// is PS
    }

    /**
     * Listens to the Buttons that move the Graph.
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        String s = e.getActionCommand();
        /*if (s.equals("left")) {
            grapho.stepLeft();
            System.out.println("garpho.stepLeft()");
        } else if (s.equals("right")) {
            grapho.stepRight();
            System.out.println("garpho.stepRight()");
        } else if (s.equals("up")) {
            grapho.stepUp();
            System.out.println("garpho.stepUp()");
        } else if (s.equals("down")) {
            grapho.stepDown();
            System.out.println("garpho.stepDown()");
        }*/
    }
    
    /**
     * Adds the given id to the list of filtered nodes
     * @see de.tub.eyes.components.FilterView#addToFilter(int)
     */
    public synchronized void addToFilter(int id) {

        //System.out.println("addToFilter(int id): "+ id);
        
        //for (Iterator it = filter.iterator(); it.hasNext();) {
        //    System.out.println("addToFilter - filter list currently has: "+ it.next());
        //}
        
        if (filter.contains(new Integer(id)))
            return;
        else
            filter.add(new Integer(id));

        //for (Iterator it = filter.iterator(); it.hasNext();) {
        //    System.out.println("addToFilter - after adding, filter list has: "+ it.next());
        //}
        
        //  System.out.println("in GVC - addToFilter(int id) - filter.size(): " + filter.size());
    }

    /**
     * removes the given id from the list of filtered nodes
     * @see de.tub.eyes.components.FilterView#removeFromFilter(int)
     */
    public synchronized void removeFromFilter(int id) {

        //System.out.println("removeFromFilter(int id): "+ id);
        Vector toDel = new Vector();

      for (Iterator it = filter.iterator(); it.hasNext(); ) {
            Integer ID = (Integer) it.next();
            
            if (ID.intValue() == id)
                toDel.addElement(ID);
      }
   
      for (Iterator it = toDel.iterator(); it.hasNext(); )                
            filter.remove((Integer)it.next());

      //for (Iterator it = filter.iterator(); it.hasNext();) {
      //      System.out.println("removeFromFilter - after removing, filter list has: "+ it.next());
      //}
    }
}
