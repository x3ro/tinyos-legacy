package de.tub.eyes.components;

import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.*;

import javax.swing.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;

import net.tinyos.message.Message;
import de.tub.eyes.ps.*;
import de.tub.eyes.gis.GIS;
import net.tinyos.surge.*;
import net.tinyos.drain.*;

import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.diagram.*;
import de.tub.eyes.comm.SubscriptionListener;
import de.tub.eyes.comm.MessageReceiver;
import de.tub.eyes.gui.customelements.CaptionBorder;
import de.tub.eyes.gui.customelements.NodePropertyViewer;
import de.tub.eyes.gui.customelements.NodeListViewer; // added by Chen
import de.tub.eyes.apps.PS.PSSubscription;

/**
 * <p>
 * This class embeds a
 * {@link de.tub.eyes.diagram.JDiagramViewer JDiagramViewer}and a
 * {@link de.tub.eyes.gui.customelements.NodePropertyViewer NodePropertyViewer}
 * in the format suitable for Demonstrator.
 * </p>
 * <p>
 * Currently this class only listens to {@link net.tinyos.surge.SurgeMsg SurgeMsg}s and dreives information
 * from them. It can detect new Nodes and adds them to the shown diagram, with a link to the parent
 * (if the link and/or the parent exist). Changing links (i.e. parents) and the latest reading are
 * shown in the display of the Nodes. (More Attributes may be painted on the node, but see the
 * {@link de.tub.eyes.diagram.Node Node} and {@link de.tub.eyes.diagram.Attribute Attribute} classes for
 * detailed information on that.
 * </p>
 *
 * <p>
 * One or more nodes can be selected, the selection of more than one node currently has no effect,
 * Nodes can be moved around on the Diagram for better overview. The currently selected nodes properties
 * are displayed in the NodePropertyViewer that is displayed also. Additionally the currently selected
 * nodes id may be added or removed to the Filter of the {@link de.tub.eyes.components.GraphViewComponent GraphViewComponent}
 * via two buttons.
 * </p>
 *
 * @author Joachim Praetorius
 * @see de.tub.eyes.diagram.Node
 */
public class NetworkViewComponent extends AbstractNetworkComponent implements
        MessageReceiver, ActionListener {

    private JConfigurableDiagramViewer viewer;
    private NodePropertyViewer nodePropertyViewer;
    private NodeListViewer nodeListViewer; // added by Chen
    private FormLayout layout;
    private FormLayout cpanelLayout;
    private CellConstraints cc;
    private PanelBuilder builder;
    private PanelBuilder cpanelBuilder;
    private JToggleButton button;
    private JButton toggleLinksButton, toggleRenderButton, toggleBgButton;
    private JComboBox mapCB, zoomCB;
    private java.util.List filterViewers;
    private boolean linksVisible;
    private boolean bgVisible;
    private boolean rendering;
    private ObjectMaintainer OM;
    private static Date startTime = new Date();
    private static ConfigComponent config = Demonstrator.getConfigComponent();
    private GIS gis;
    private int mapNo = -1;
    private int zoomFactor = 1;

    /**
     * builds a new NetworkView Component
     *
     */
    public NetworkViewComponent() {
        gis = new GIS("../../gis/GIS.properties");
        gis.init("jdbc");
        gis.readDB();
        initComponents();
        buildUI();
    }

    /**
     * The way the messages are handled in here does not seem very reasonable,
     * given the fact that we subscribed to SurgeMsg's at the Demonstrator.
     * Anyway it is taken from the TinyOS Surge java application (in more detail
     * the LocationAnalyzer and the PacketAnalyzer classes), which act in the
     * same way. Even more this seems to be the only way that generates messages
     * with reasonable values. Subscribing to surge.MultihopMsg does not work,
     * nor does casting the received message directly.
     *
     * @see de.tub.eyes.MessageReceiver#receiveMessage(net.tinyos.message.Message)
     */
    public void receiveMessage(Message m) {
                
        Date rcvTime = new Date();
        SurgeMsg surgeMsg = null;
        Node n = null;

        PSNotificationMsg ps2Msg = null;
        MultihopMsg msg = null; 
        //System.out.println("MESSAGE!");

        //config.dump();
        if (Demonstrator.isDrip() ) {
            if (!(m instanceof DrainMsg))
                return;
            
            DrainMsg mhmsg = (DrainMsg)m;
            PSNotificationMsg   msgTemp = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0));
            ps2Msg = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0), 
                    msgTemp.DEFAULT_MESSAGE_SIZE + msgTemp.get_dataLength());
            n = viewer.getNodeById(ps2Msg.get_sourceAddress());            
        } else {
            msg = new MultihopMsg(m.dataGet());
            n = viewer.getNodeById(msg.get_originaddr());
            if (Demonstrator.isSurge())
                //surgeMsg = new SurgeMsg(msg.dataGet(), msg.offset_data(0));
                surgeMsg = new SurgeMsg(msg.dataGet(), 6); //tossim is compiled with wrong headers
            else { 
                ps2Msg = new PSNotificationMsg(msg.dataGet(), msg.offset_data(0));
            }                                    
        }
                         
        if (n != null) {
            n.setEpoch((int)((rcvTime.getTime()-startTime.getTime())/1000));
            setPosition(n);
        }
            
        if (Demonstrator.isSurge()) {
            if (n != null)
                n.setReading(surgeMsg.get_reading());
            OM.PacketReceived(msg);
            return;
        }        
        else {                                           

            if ( ps2Msg == null || ps2Msg.get_flags() != 2 )
                return;
            
            int source = ps2Msg.get_sourceAddress();
            int subscriberID = ps2Msg.get_subscriberID();
            int sourceAddress = ps2Msg.get_sourceAddress();
            int seqNo = ps2Msg.get_subscriptionID();
            //int scope = ps2Msg.get_scope();
            //int pad = ps2Msg.get_pad();
            int parent = ps2Msg.get_parentAddress();

            OM.PacketReceived(source, parent, seqNo);
                        
            //System.out.println("subscriberID = "+subscriberID+" sourceAddress = "+sourceAddress+" parentaddr = "+parent+" subscriptionSeqNo = "+seqNo);
        
            if (!(n instanceof NodePS))
                return;
            
            NodePS nPS = (NodePS)n;
            
            //System.out.println("# of attribs = " + psMsg.get_publication_numPubData());
            //System.out.println("# of attribs = " + ps2Msg.getAVPairCount());

            for (int i=0; i< ps2Msg.getAVPairCount(); i++) {                                            
                
                int attr = ps2Msg.getAVPairAttributeID(i);
                //int size = ps2Msg.getAVPairValue(i).length;
                
                nPS.setReading(attr, PSSubscription.arrayToObject(ps2Msg.getAVPairValue(i), attr));
                                
                if (config.isDefined(attr) && config.isEnabled(attr)) {                
                    switch (config.getType(attr)) {
                        case ConfigComponent.TYPE_NONE: // none
                            break;
                        case ConfigComponent.TYPE_TXT: // text
                            nPS.addAttribute(PSSubscription.getAttribName(attr), new TextAttribute(PSSubscription.getAttribName(attr), true, nPS, attr));
                            //System.out.println("addTextAttribute for attr " + attr);                            
                            break;
                        case ConfigComponent.TYPE_NUM: // number
                            nPS.addAttribute(PSSubscription.getAttribName(attr), new NumAttribute(PSSubscription.getAttribName(attr), true, nPS, attr));
                            //System.out.println("addNumberAttribute for attr " + attr);
                            break;
                        case ConfigComponent.TYPE_BAR: // bar
                            nPS.addAttribute(PSSubscription.getAttribName(attr), new BarAttribute(PSSubscription.getAttribName(attr), true, nPS, attr)); 
                            //System.out.println("addBarAttribute for attr " + attr);                            
                            break;
                        case ConfigComponent.TYPE_DOT: // dot
                            nPS.addAttribute(PSSubscription.getAttribName(attr), new DotAttribute(PSSubscription.getAttribName(attr), true, nPS, attr));
                            //System.out.println("addDotAttribute for attr " + attr);                            
                            break;
                    }
                } // if defined...                   
            } // for data
        } // if PS 
    }

    /**
     * Returns the ToggleButton for this Component
     * @see de.tub.eyes.components.AbstractComponent#getButton()
     */
    public JToggleButton getButton() {
        return button;
    }

    /**
     * Returns the UI for this Component
     * @see de.tub.eyes.components.AbstractComponent#getUI()
     */
    public Component getUI() {
        JComponent c = builder.getPanel();
        c.setBorder(new CompoundBorder(new CaptionBorder("Network View"),
                new EmptyBorder(10, 10, 10, 10)));
                
        return c;
    }

    /**
     * Listens to the add and remove button
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        String s = e.getActionCommand();
        if (s.equals("add")) {
            Node n = viewer.getPrimarySelection();
            fireAddToFilter(n.getId());
            return;
        }

        if (s.equals("remove")) {
            Node n = viewer.getPrimarySelection();
            fireRemoveFromFilter(n.getId());
            return;
        }
        
        if (s.equals("togglelinks")) toggleLinks();      
        if (s.equals("togglerender")) toggleRender();
        if (s.equals("togglebg")) toggleBg();
        
        if (viewer != null && e.getSource() == mapCB) {
            int map = mapCB.getSelectedIndex();
            if (map > -1) {
                mapNo = map-1;
                viewer.setMap(mapNo);
                viewer.setZoom(1);
                zoomCB.setSelectedIndex(1);
                builder.getPanel().revalidate();
                setPositionAll();
            }
        }
        
        if (viewer != null && e.getSource() == zoomCB) {
            zoomFactor = zoomCB.getSelectedIndex();
            viewer.setZoom(zoomFactor);
            builder.getPanel().revalidate();
            setPositionAll();
        }        
    }
    
    public void toggleRender() {
        rendering = !rendering;
    }

    public void toggleLinks() {
        viewer.getDiagram().setLinksVisible(linksVisible = !linksVisible);
        viewer.repaint();
    }
 
    public void toggleBg() {
        viewer.setBgVisible(bgVisible = !bgVisible);
        viewer.repaint();
    }
    
    /**
     * Manages the FilterView implementors to notify when the buttons are pressed
     * @param f The <code>FilterView</code>er to add
     */
    public void addFilterViewer(FilterView f) {
        filterViewers.add(f);
    }

    /**
     * Manages the FilterView implementors to notify when the buttons are pressed
     * @param f The <code>FilterView</code>er to remove
     */
    public void removeFilterViewer(FilterView f) {
        filterViewers.remove(f);
    }

    /**
     * initialization
     *
     */
    private void initComponents() {
        filterViewers = new ArrayList();
        nodePropertyViewer = new NodePropertyViewer();
        nodeListViewer = new NodeListViewer();
        viewer = new JConfigurableDiagramViewer();        
        
        nodeListViewer.setJDiagramViewer(viewer);
        nodeListViewer.setNetworkViewComponent(this);

        viewer.addPrimarySelectionListener(nodePropertyViewer);
        viewer.setNodeListViewer(nodeListViewer);
        
        OM = new ObjectMaintainer();
        OM.AddGraphRemover(viewer.getDiagram());
        OM.AddGraphPopulator(viewer);
         
        button = new JToggleButton("<html>Network<br>View");
        button.setHorizontalAlignment(JButton.LEFT);        

        toggleLinksButton = new JButton("Links on/off");
        toggleLinksButton.setActionCommand("togglelinks");
        toggleLinksButton.addActionListener(this);
        //toggleRenderButton = new JButton("Render on/off");
        //toggleRenderButton.setActionCommand("togglerender");
        //toggleRenderButton.addActionListener(this);
        toggleBgButton = new JButton("Background on/off");
        toggleBgButton.setActionCommand("togglebg");
        toggleBgButton.addActionListener(this);
          
       
        layout = new FormLayout("f:d,10dlu,p", "f:p,10dlu,t:1dlu:g,6dlu,f:p");                
        builder = new PanelBuilder(layout);
        
        cpanelLayout = new FormLayout("p,12dlu,p,12dlu,p,12dlu,p,12dlu,p", "p");
        cpanelBuilder = new PanelBuilder(cpanelLayout);
        cc = new CellConstraints();
        
        linksVisible = true;
        bgVisible = true;
        
        initCB();
        mapCB.addActionListener(this);
        zoomCB.addActionListener(this);
    }

    /**
     * builds the UI
     *
     */
    private void buildUI() {
        cpanelBuilder.add(toggleLinksButton, cc.xy(1,1));
        cpanelBuilder.add(toggleBgButton, cc.xy(3,1));
        cpanelBuilder.add(mapCB, cc.xy(5,1));
        cpanelBuilder.add(zoomCB, cc.xy(7,1));        
        //cpanelBuilder.add(toggleRenderButton, cc.xy(5,1));
        JScrollPane scrViewer = new JScrollPane(viewer);
        viewer.setScrollPane(scrViewer);
        builder.add(scrViewer, cc.xywh(1, 1, 1, 3, CellConstraints.FILL, CellConstraints.FILL));
        builder.add(nodePropertyViewer, cc.xy(3, 1, CellConstraints.RIGHT, CellConstraints.TOP));
        JScrollPane scrListViewer = new JScrollPane(nodeListViewer.buildUI());
        
        builder.add(scrListViewer, cc.xywh(3,3,1,3));
        builder.add(cpanelBuilder.getPanel(), cc.xyw(1,5,3));
    }

    /**
     * Notifies FilterViewers of an <code>add</code> event
     * @param id the id of the node to add to the filter
     */
    public synchronized void fireAddToFilter(int id) {
        for (Iterator it = filterViewers.iterator(); it.hasNext();) {
            ((FilterView) it.next()).addToFilter(id);
        }
    }

    /**
     * Notifies FilterViewers of an <code>remove</code> event
     * @param id the id of the node to remvoe from the filter
     */
    public synchronized void fireRemoveFromFilter(int id) {
        for (Iterator it = filterViewers.iterator(); it.hasNext();) {
            ((FilterView) it.next()).removeFromFilter(id);
        }
    }
    
    public ObjectMaintainer getObjectMaintainer() {
        return this.OM;
    }
    
    private void initCB() {
        mapCB = new JComboBox();
        zoomCB = new JComboBox();
        
        int mapCnt = Integer.parseInt(Demonstrator.getProps().getProperty("map_cntImgs","-1"));
        
        mapCB.addItem("No Map");
        
        for (int cnt=0; cnt < mapCnt; cnt++) {
            String propName = Demonstrator.getProps().getProperty("map_name_" + cnt,"Map " + cnt);
            mapCB.addItem(propName);
        }
        
        zoomCB.addItem("75%");
        zoomCB.addItem("100%");
        zoomCB.addItem("125%");
        zoomCB.addItem("150%");
        zoomCB.addItem("175%");
        zoomCB.addItem("200%");
        zoomCB.setSelectedIndex(1);
    }
    
    private void setPosition(Node n) {
        if (mapNo == -1) {
            n.setVisible(true);
            return;
        }
        else
            n.setVisible(false);
        
        int uart = Integer.parseInt(Demonstrator.getProps().getProperty("uartAddr", "-1"));
        int [] mapXY;
        int id = n.getId();
  
        //if (uart != -1 && id != uart)
        //    id -= 1000;
        
        if ((mapXY = gis.getFloorXY(id, mapNo)) == null )            
            return;

        int offX = Maps.getOffsetX(mapNo);
        int offY = Maps.getOffsetY(mapNo);
        //System.out.println("Viewer Height = " + viewer.getPreferredSize().height);
        float x = (mapXY[0]+offX) * viewer.zoomFactor[zoomFactor];
        float y = (mapXY[1]+offY) * viewer.zoomFactor[zoomFactor];
        n.setPosition((int)x, viewer.getPreferredSize().height - (int)y);
        n.setVisible(true);
        
    }
    
    private void setPositionAll() {
        List nodes = viewer.getDiagram().getNodeList();
        for (Iterator it = nodes.iterator(); it.hasNext();) {
            setPosition((Node)it.next());
        }
        viewer.repaint();
    }
                       
}
