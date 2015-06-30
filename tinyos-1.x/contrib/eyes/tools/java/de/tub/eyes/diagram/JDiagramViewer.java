/*
 * Project Test
 *
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

import java.awt.*;
import java.awt.event.*;

import java.util.*;
import java.util.List;

import javax.swing.*;
import javax.swing.border.LineBorder;


import java.applet.*;
import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.gui.customelements.NodeListViewer;
import de.tub.eyes.components.ConfigComponent;
import de.tub.eyes.gis.*;

/**
 * This is the Swing Component being responsible for displaying a {@link de.tub.eyes.diagram.Diagram Diagram}.
 * It mainly provides some handling for the mouse, as well as some convenience methods on the Diagram, e.g.
 * adding a new Node or a Link.
 *
 * @author Joachim Praetorius
 */
public class JDiagramViewer extends JComponent implements GraphPopulator {
    protected Diagram diagram;
    //static private List nodes;
    private Selection selection;
    private static List selectionListeners;
    private DragIndicator tracker;
    private JPopupMenu popupMenu;
    protected Random random;
    private NodeListViewer nodeListViewer;
    private boolean bgVisible = true;
    private boolean mouseIsPressed = false;
    private int mapNo = -1;
    private int zoom = 1;
    private static ConfigComponent cc = Demonstrator.getConfigComponent();
    private static int uartAddr = Integer.parseInt(Demonstrator.getProps().getProperty("uartAddr", "126"));
    private Maps maps;
    public static final float [] zoomFactor = new float[6];
    {
        zoomFactor[0] = 0.75f;         
        zoomFactor[1] = 1.0f; 
        zoomFactor[2] = 1.25f; 
        zoomFactor[3] = 1.5f; 
        zoomFactor[4] = 1.75f; 
        zoomFactor[5] = 2.0f;
    }
    
    public static final int DEFAULT_WIDTH = 580;
    public static final int DEFAULT_HEIGHT = 580;
    private int baseSizeX=DEFAULT_WIDTH, baseSizeY=DEFAULT_HEIGHT;
    private int sizeX=baseSizeX, sizeY=baseSizeY;
    private JScrollPane pane = null;
    
    
    /**
     * Creates a new JDiagramViewer and adds MouseListeners
     *
     */
    public JDiagramViewer() {
        selectionListeners = new ArrayList();
        diagram = new Diagram();
        diagram.setViewer(this);        
 
        maps = new Maps(Demonstrator.getProps());
        
        random = new Random();
        buildPopupMenu();
        setBorder(new LineBorder(Color.black, 1));
        selection = new Selection();
        addMouseListener(new MouseAdapter() {
            public void mousePressed(MouseEvent e) {
                if (e.getButton() == e.BUTTON3) {
                    JDiagramViewer.this.showPopup(e);
                } else {
                    JDiagramViewer.this.mousePressed(e);
                }              
                
            }

            public void mouseReleased(MouseEvent e) {
                if (e.isPopupTrigger()) {
                    JDiagramViewer.this.showPopup(e);
                    return;
                }
                JDiagramViewer.this.mouseReleased(e);
            }

            public void mouseClicked(MouseEvent e) {
                if (e.isPopupTrigger()) {
                    JDiagramViewer.this.showPopup(e);
                    return;
                }
            }

            /**
             * @see java.awt.event.MouseAdapter#mouseClicked(java.awt.event.MouseEvent)
             */

        });

        addMouseMotionListener(new MouseMotionAdapter() {
            public void mouseDragged(MouseEvent e) {
                JDiagramViewer.this.mouseDragged(e);
            }
        });
        
        addComponentListener(new ComponentListener() {
            private Dimension oldDim;
             
            public void componentHidden(ComponentEvent e) { }

            public void componentMoved(ComponentEvent e) { }

            public void componentResized(ComponentEvent e) {

               if (oldDim == null) {
                    oldDim = e.getComponent().getSize();
                    return;
                }

                doResize(oldDim.getWidth(), oldDim.getHeight(), e.getComponent().getWidth(), e.getComponent().getHeight());                                
                oldDim = e.getComponent().getSize();
            }

            public void componentShown(ComponentEvent e) {

                if ( oldDim == null )
                    oldDim = e.getComponent().getSize();
            }
       });        
    }

    /**
     * Creates a new JDiagramViewer for the given Diagram and adds MouseListeners
     * @param d The Diagram to show
     */
    public JDiagramViewer(Diagram d) {
        random = new Random();
        buildPopupMenu();
        setBorder(new LineBorder(Color.black, 1));
        this.diagram = d;
        selection = new Selection();
        addMouseListener(new MouseAdapter() {
            public void mousePressed(MouseEvent e) {
                JDiagramViewer.this.mousePressed(e);
            }
            

            public void mouseReleased(MouseEvent e) {
                if (e.isPopupTrigger()) {
                    JDiagramViewer.this.showPopup(e);
                    return;
                }
                JDiagramViewer.this.mouseReleased(e);
            }

            /**
             * @see java.awt.event.MouseAdapter#mouseClicked(java.awt.event.MouseEvent)
             */

        });

        addMouseMotionListener(new MouseMotionAdapter() {
            public void mouseDragged(MouseEvent e) {
                JDiagramViewer.this.mouseDragged(e);
            }
        });
    }

    public void setNodeListViewer(NodeListViewer n){ //glueing NodeListViewer between NetworkViewComponent and Diagram
      diagram.setNodeListViewer(n);
    }

    /**
     * Wrapper for {@link Diagram#getNodeById(int) Diagram.getNodeById()}
     * @param id The Id of the Node to find
     * @return The node with the given Id or <code>null</code> if the Node is not present
     */
    public Node getNodeById(int id) {
        return diagram.getNodeById(id);
    }

    /**
     * Convenience Method. Adds a new Node with the given id to the Diagram.
     * @param id The Id of the Node to add.
     */
    public Node addNode(int id, Date date) {
        Node n;
        //if (d.isSurge())
            n = new NodeSurge(getNewX(), getNewY(), diagram, date);
        //else
        //    n = new NodePS(getNewX(), getNewY(), diagram, date);
        
        n.setId(id);
        n.setReading(getNewX());
        diagram.addNode(n);
        
        return n;
    }

    /**
     * Convenience Method. Adds a new Link between the Nodes with the given Ids to the Diagram.
     * @param startNode the Id of the node the link starts at
     * @param endNode the Id of the node the link ends at
     */
    public Link addLink(int startNode, int endNode, Date date) {
        Node n1 = diagram.getNodeById(startNode);
        Node n2 = diagram.getNodeById(endNode);
        if (n1 != null && n2 != null) {
            // There must be only one link to a parent!
            Link oldLink = diagram.getLinkForStartId(startNode);
            if ( oldLink != null )
                diagram.removeLink(oldLink);
                
            Link l = new Link(n1, n2, diagram, date);
            diagram.addLink(l);
            n1.setParent(endNode);
            return l;
        }
        return null;
    }

    /**
     * Convenience Method. If the Link for the start Node already exists, its
     * end node is updated if necessary. So changing links can be reflected without a
     * remove/add new cycle.
     * @param start the Id of the node the link starts at
     * @param end the Id of the node the link ends at
     */
    public void renewLinkForStartNode(int start, int end) {
        Link l = diagram.getLinkForStartId(start);
        if (l != null) {
            if (l.getEnd().getId() != end) {
                l.setEnd(diagram.getNodeById(end));
            }
        }
        else {
            if (nodeIdExists(start) && nodeIdExists(end)) {
                addLink(start,end,Calendar.getInstance().getTime());
            }
        }
    }

    /**
     * Returns <code>true</code> if a node with the given Id exists in the Diagram, <code>false</code>otherwise
     * @param id The Id of the node to search
     * @return <code>true</code> if a node with the given Id exists in the Diagram, <code>false</code>otherwise
     */
    public boolean nodeIdExists(int id) {
        return diagram.getNodeById(id) != null;
    }

    /**
     * Returns the primary selected node. In the case that only one node in the Diagram is selected this is the
     * selected node. If more than one node is selected the primary selected node is the node that was selected
     * first.
     *
     * @return The node that was selected as first one, or <code>null</code> if no node is selected
     */
    public Node getPrimarySelection() {
        return selection.getPrimarySelection();
    }

    /**
     * Adds a Listener that gets informed about changes of the primary selection
     * @param sl The Listener to add
     */
    public void addPrimarySelectionListener(SelectionListener sl) {
 //     System.out.println("in addPrimarySelectionListener: the listener is: " + sl);
      selectionListeners.add(sl);
 //     System.out.println("selectionListeners: " + selectionListeners.size());
    }

    /**
     * Removes a SelectionListener from the List f registered Listeners
     * @param sl The Listener to remove
     */
    public void removePrimarySelectionListener(SelectionListener sl) {
        selectionListeners.remove(sl);
    }

    /**
     * Convenience method, used to generate an X Position for a new Node
     * @return A random int
     */
    protected int getNewX() {       
        //return random.nextInt(600);
        return random.nextInt(this.getWidth()-20)+10;
    }

    /**
     * Convenience method, used to generate a Y Position for a new Node
     * @return A random int
     */
    protected int getNewY() {
        //return random.nextInt(600);
        return random.nextInt(this.getHeight()-20)+10;
    }

    /**
     * Paints a white background and then delegates to the diagram, if one is present
     * @see Diagram#paint(Graphics)
     * @see javax.swing.JComponent#paintComponent(java.awt.Graphics)
     */
    protected void paintComponent(Graphics g) {
        //super.paintComponent(g);
        Graphics2D g2 = (Graphics2D) g;
        
        if ((!mouseIsPressed) && bgVisible) {
            paintBackground(g2);
        }        
//        g2.setColor(Color.white);
//        g2.fillRect(0, 0, getWidth(), getHeight());
        if (diagram != null) {
            diagram.paint(g2);

        }
        
        if (mapNo > -1 && mapNo < maps.getCnt() ) {
            Dimension d = getSize();
            int sizeX = (int)(maps.getWidth(mapNo)*zoomFactor[zoom]);
            int sizeY = (int)(maps.getHeight(mapNo)*zoomFactor[zoom]);
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 0.5f));
            //g2.drawImage(maps[mapNo],0,0,(int)d.getWidth(),(int)d.getHeight(),null);
            g2.drawImage(maps.getMap(mapNo),0,0,sizeX,sizeY,null);
        }
    }

    public double distance(int x, int y, int x1, int y1){
        return Math.sqrt( (x-x1)*(x-x1)+(y-y1)*(y-y1));
    }

    public void paintBackground(Graphics2D g)
    {      
        int bgAttrib = cc.getBackgroundAttribute();
        if (! (bgAttrib > -1 && cc.isDefined(bgAttrib) && cc.isEnabled(bgAttrib) && cc.getType(bgAttrib) == cc.TYPE_BG) )
            return;        
        
        int x = 0;
        int y = 0;
        int step = 10;
        List nodes;
        double offset = cc.getMin(bgAttrib);        
        double scale = cc.getMax(bgAttrib) - offset;
        double value;

        for(;x < getWidth(); x += step) {
                        
            for(y = 0;y < getHeight(); y += step) {
                double val = 0;
                double sum = 0;
                double total = 0;
                double min = 10000000;

                nodes = diagram.getNodeList();

                for (Iterator it = nodes.iterator(); it.hasNext();) {
                    Node n = (Node) it.next();
                    if ( n.getId() == uartAddr ) // no coloring for UART
                      continue;
                    
                    if ( !n.getVisible())
                        continue;
                  
                    if (n instanceof NodePS && ((NodePS)n).readingExists(bgAttrib)) {
                        Object obj = ((NodePS)n).getReading(bgAttrib);
                        if (obj instanceof Long)
                            value = ((Long)obj).doubleValue();
                        else if (obj instanceof Double)
                            value = ((Double)obj).doubleValue();                        
                        else
                            continue;
                    }
                    else 
                        value = (double)n.getReading();
                    value = (255/(scale-offset))*(value-offset);
                  
                    double dist = distance(x, y, (int)n.getPosition().getX(), (int)n.getPosition().getY());
                    if(n.getReading() != -1) { //121
                        if (dist < min) 
                            min = dist;
                        val += value  / dist /dist;
                        sum += (1/dist/dist);
                    }
                }
                
                int reading = (int)(val / sum);
                if (reading > 255)
                    reading = 255;
                if (reading < 0)
                    reading = 0;
                
                g.setColor(new Color(reading, reading, reading));
                g.fillRect(x, y, step, step);
            } // for y
        } // for x
    }

    /**
     * Informs all Selection Listeners that the primary Selection has changed
     * @param n The new primary selected node. May be <code>null</code> if no node was selected.
     * @see #getPrimarySelection()
     * @see Selection
     * @see Selection#getPrimarySelection()
     */
    public void firePrimarySelectionChanged(Node n) {
//      System.out.println("selectionListeners: " + selectionListeners.size());
      for (Iterator it = selectionListeners.iterator(); it.hasNext();) {
        Object o = it.next();
//        System.out.println("the listener is: " + o);
        ((SelectionListener) o).selectionChanged(n);
      }
    }

    /**
     * Convenience mousehandling method. Shows the Nodes Popup-Context menu.
     * Currently the popup only is available on windows, due to incompatibilities
     * in the handling of mouseClicked and mousePressed
     * @param e The mouseEvent
     */
    private void showPopup(MouseEvent e) {
        if (e.getButton() == e.BUTTON3) {
            popupMenu.show(this, e.getX(), e.getY());
        }        
    }

    /**
     * Convenience mousehandling method.
     * @param e the mouse Event
     */
    private void mousePressed(MouseEvent e) {
        mouseIsPressed = true;
        selection.add(diagram.nodeAt(e.getX(), e.getY()), e.isShiftDown());
        firePrimarySelectionChanged(selection.getPrimarySelection());
    }

    /**
      * Added 10-11-2004 - allows to select nodes programatically from the List, reflecting the changes to the property viewer
      * @param n the node to add
      * @param add add to selection or replace existing selection
      */
     public void addNodeToSelection(Node n, boolean add) {
       if(add == true) {
         selection.add(n);
       } else {
         selection.remove(n);
       }
      firePrimarySelectionChanged(selection.getPrimarySelection());
     }

    /**
     * Convenience mousehandling method.
     * @param e the mouse Event
     */
    private void mouseDragged(MouseEvent e) {
        if (tracker == null) {
            Node n = selection.getPrimarySelection();
            if (n == null)
                return;
            if (n instanceof NodePS)
                tracker = new DragIndicatorPS(0, 0, diagram, (NodePS)n);
            else
                tracker = new DragIndicatorSurge(0, 0, diagram, n);
            diagram.addGhostNode(tracker);
        } else {
            tracker.setPosition(e.getX(), e.getY());
        }
    }

    /**
     * Convenience mousehandling method.
     * @param e the mouse Event
     */
    private void mouseReleased(MouseEvent e) {
        mouseIsPressed = false;
        if (tracker != null) {
            diagram.removeNode(tracker);
            Node n = selection.getPrimarySelection();
            n.setPosition(tracker.getPosition());
            tracker = null;
        }
    }

    /**
     * Creates the popupmenu that gets shown by showPopupMenu()
     *
     */
    private void buildPopupMenu() {
        popupMenu = new JPopupMenu();
        ImageIcon addIcon = new ImageIcon("img/add.png");
        ImageIcon removeIcon = new ImageIcon("img/remove.png");
        JMenuItem addItem = new JMenuItem("add to Graph", addIcon);
        JMenuItem removeItem = new JMenuItem("remove from Graph", removeIcon);
        
        //popupMenu.add(addItem);
        //popupMenu.add(removeItem);
        popupMenu.add(new JMenuItem("add to hell"));
        popupMenu.add(new JMenuItem("add to heaven"));
    }
    
    public Diagram getDiagram() {
        return diagram;
    }
    
    public void setBgVisible(boolean bgVisible) {
        this.bgVisible = bgVisible;
    }
    
    public void setMap(int mapNo) {
        this.mapNo = mapNo;
        
        if (mapNo == -1) {
            baseSizeX = DEFAULT_WIDTH;
            baseSizeY = DEFAULT_HEIGHT;
        }
        else {
            baseSizeX = maps.getWidth(mapNo);
            baseSizeY = maps.getHeight(mapNo);            
        }
        sizeX = baseSizeX;
        sizeY = baseSizeY;
        
        float oldX = (float)getWidth();
        float oldY = (float)getHeight();
        
        setSize(sizeX, sizeY);
    }
    
    public void setZoom(int zoom) {
        this.zoom = zoom;
        Properties props = Demonstrator.getProps();
        int newSizeX = (int)(baseSizeX*zoomFactor[zoom]);
        int newSizeY = (int)(baseSizeY*zoomFactor[zoom]);
        if (mapNo == -1)
            diagram.resize(newSizeX/(float)sizeX,newSizeY/(float)sizeY);
        sizeX = newSizeX;
        sizeY = newSizeY;
        
        setSize(sizeX, sizeY);                
    }
    
    private void doResize (double oldWidth, double oldHeight, double newWidth, double newHeight) {
    //    if (Math.abs(oldWidth - newWidth) < 10.0 && Math.abs(oldHeight - newHeight) < 10.0)
    //        return;
    //    diagram.resize(newWidth/oldWidth, newHeight/oldHeight);
    }
    
    public Dimension getPreferredSize() {
        if (sizeX > -1 && sizeY > -1) 
            return new Dimension(sizeX,sizeY);
        else
            return getSize();
    }
    
    public void setScrollPane(JScrollPane pane) {
        this.pane = pane;
    }
}
