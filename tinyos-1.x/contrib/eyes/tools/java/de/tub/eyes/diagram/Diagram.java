/*
 * Project EYES Demonstrator
 *
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

import java.awt.Graphics;
import java.awt.Rectangle;
import java.util.*;
import de.tub.eyes.gui.customelements.NodeListViewer; // added by Chen

/**
 * <p>
 * This is the simple Model for a Diagram. It just contains Nodes and Links.
 * In not completely correct MVC it knows the View (JDiagramViewer) to tell it when to repaint.
 * Additionally it provides some convenience methods on the Elements of the network.
 * </p>
 *
 * @author Joachim Praetorius
 * @see de.tub.eyes.diagram.JDiagramViewer
 * @see de.tub.eyes.diagram.Node
 * @see de.tub.eyes.diagram.Link
 */
public class Diagram implements GraphRemover {
    private List nodes;
    private List links;
    private JDiagramViewer viewer;
    private NodeListViewer nodeListViewer; // added by Chen
    private boolean linksVisible = true;

    /**
     * Creates a new empty Diagram.
     *
     */
    public Diagram() {
        nodes = new ArrayList();
        links = new ArrayList();
    }

    public void setNodeListViewer(NodeListViewer n){
      nodeListViewer = n;
    }

    public void addGhostNode(Node n) {
      nodes.add(n);
      repaint();
    }

   /**
     * Adds the given node to the network and calls repaint(), so the node is shown
     * @param n The node to add
     */
    public synchronized void addNode(Node n) {
      nodes.add(n);
      nodeListViewer.addNode(n); // added by Chen
      
      repaint();
    }

    public synchronized List getNodeList() {

        /// synch problem... Vector would be syncronized
        return nodes;
    }

    /**
     * Removes the given node
     * @param n The node to remove
     */
    public void removeNode(Node n) {
        nodes.remove(n);
        nodeListViewer.removeNode(n);
        repaint();
    }

    public void removeNode(int id) {
        removeNode(getNodeById(id));
    }
    
    /**
     * Adds a Link to the network
     * @param l The link to add
     */
    public synchronized void addLink(Link l) {      
        links.add(l);
        repaint();
    }

    /**
     * Removes a link from the network
     * @param l the Linkk to remove
     */
    public void removeLink(Link l) {
        links.remove(l);
        repaint();
    }

    public void removeLink(int startNode, int endNode) {
        Link l = getLinkForStartId(startNode);
        if (l != null && l.getEnd().getId() == endNode)
            removeLink(getLinkForStartId(startNode));

    }
    
    /**
     * Returns the node that has been added as nth (so the first node would be <code>getNode(0)</code>)
     * @param n The number of the node
     * @return The node that was added at nth place, or <code>null</code> if this node does not exist-
     */
    public Node getNode(int n) {
        return (Node) nodes.get(n);
    }

    /**
     * Returns the node with the given id
     * @param id The id of the Node to return
     * @return The Node with the giveen id, or <code>null</code> if this node doesn't exist in the network
     */
    public Node getNodeById(int id) {
        for (Iterator it = nodes.iterator(); it.hasNext();) {
            Node n = (Node) it.next();
            if (n.getId() == id) {
                return n;
            }
        }

        return null;
    }

    /**
     * <p>This method returns the Link of the Node with the given Id.
     * The idea behind this method is that each node only has one outgoing link (i.e. a link where
     * it is the start node) This can be assumed, as the Nodes are linked in a tree fashion,
     * so every node may have null or more children but only has one parent. <br>
     *
     * @param start The id of the Node the link is searched for
     * @return The Link where the node with id <code>start</code> is start Node or <code>null</code> if this node doesn't exist.
     */
    public Link getLinkForStartId(int start) {
        for (Iterator it = links.iterator(); it.hasNext();) {
            Link l = (Link) it.next();
            if (l.getStart().getId() == start) {
                return l;
            }
        }

        return null;
    }

    /**
     * Paints the Diagram on the given Graphics. The Diagram lets the Links and nodes paint
     * themselves via their respective <code>paint</code> methods.
     * @param g The graphics to paint on
     * @see Node#paint(Graphics)
     * @see Link#paint(Graphics)
     */
    public synchronized void paint(Graphics g) {
        if (linksVisible) {
            for (Iterator it = links.iterator(); it.hasNext();) {
                Link l = (Link) it.next();
                if (l.getStart().getVisible() && l.getEnd().getVisible())
                    l.setVisible(true);
                else
                    l.setVisible(false);
                l.paint(g);
            }
        }

        for (Iterator it = nodes.iterator(); it.hasNext();) {
            Node n = (Node) it.next();
            n.paint(g);
        }

    }

    /**
     * Returns the Node that is located at the given location in the diagram.
     * Each node looks up whether the identified point is within its
     * bounds. If the point is contained the Node is returned. If no Node
     * if clicked, <code>null</code> is returned.
     * @param x The x location
     * @param y The y location
     * @return The node containing that location ot <code>null</code> if no node contains the given location
     */
    public Node nodeAt(int x, int y) {
        for (Iterator it = nodes.iterator(); it.hasNext();) {
            Node n = (Node) it.next();
            if (n.contains(x, y)) {
                return n;
            }
        }
        return null;
    }

    /**
     * Tells the viewer to repaint
     * @see javax.swing.JComponent#repaint()
     */
    public void repaint() {
        viewer.repaint();
    }

    /**
     * Tells the viewer to repaint within the given bounds
     * @see javax.swing.JComponent#repaint(java.awt.Rectangle)
     */
    public void repaint(Rectangle bounds) {
        viewer.repaint(bounds);
    }

    /**
     * Sets the viewer
     * @param viewer the viewer to notice of repaints
     */
    public void setViewer(JDiagramViewer viewer) {
        this.viewer = viewer;
    }
    
    public void setLinksVisible(boolean linksVisible) {
        this.linksVisible = linksVisible;
    }
    
    public void resize(double ratioWidth, double ratioHeight) {
        //System.out.println("resize! ratX = " + ratioWidth + " ratY = " + ratioHeight);
        for (Iterator it = nodes.iterator(); it.hasNext();) {
            Node n = (Node) it.next();
            n.setPosition((int)(n.getPosition().x * ratioWidth), (int)(n.getPosition().y * ratioHeight));
            n.repaint();
        }
    }    
}
