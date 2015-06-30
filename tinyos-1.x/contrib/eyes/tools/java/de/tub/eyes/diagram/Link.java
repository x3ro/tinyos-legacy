/*
 * Project Test
 * 
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

import java.awt.*;
import java.util.Date;

/**
 * Models a Link between two nodes. This class knows its diagram, to be able to call
 * repaint, when necessary- Additionally it observes its two Nodes, to get informed of
 * position changes, so the link follows node movements without further care.
 * 
 * @author Joachim Praetorius
 */
public class Link implements NodeMoveListener {

    private static final Color color = Color.green;
    private static final int LINE_WIDTH = 2;

    private Node start;
    private Node end;
    private Diagram diagram;

    //**Link Information***
    int id;
    Date date;
    boolean visible = false;

    /**
     * Returns the Node the Link ends at
     * @return The end Node
     */
    public Node getEnd() {
        return end;
    }

    /**
     * Sets the Node the link ends at
     * @param end The node the link should end at
     */
    public void setEnd(Node end) {
        this.end = end;
        repaint();
    }

    /**
     * Returns the Node the Link starts at
     * @return The start Node
     */
    public Node getStart() {
        return start;
    }

    /**
     * Sets the Node the link starts at
     * @param start The node the link should start at
     */
    public void setStart(Node start) {
        this.start = start;
        repaint();
    }

    /**
     * @param start
     * @param end
     * @param diagram
     */
    public Link(Node start, Node end, Diagram diagram, Date date) {
        super();
        this.start = start;
        this.end = end;
        this.diagram = diagram;
        this.date = date;
    }

    /**
     * Paints the Link. This is just a Line between the two points 
     * defined by the positions of the start and the end node
     * @param g The graphics to paint on
     */
    public void paint(Graphics g) {
        if (!visible)
            return;
        
        Point p1 = start.getPosition();
        Point p2 = end.getPosition();
        if (p1.x < 0 || p1.y < 0 || p2.x < 0 || p2.y < 0)
            return;
        
        Graphics2D g2 = (Graphics2D) g;
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                RenderingHints.VALUE_ANTIALIAS_ON);

        g2.setStroke(new BasicStroke(LINE_WIDTH));
        g2.setColor(color);
        g2.drawLine(p1.x, p1.y, p2.x, p2.y);
    }

    /**
     * Getter for 'id' Property
     * @return The value of Property 'id'
     */
    public int getId() {
        return id;
    }

    /**
     * Setter for the 'id' property
     * @param id the new Id
     */
    public void setId(int id) {
        this.id = id;
        repaint();
    }
    
    public void setVisible(boolean visible) {
        this.visible = visible;
    }
    
    public boolean getVisible() {
        return this.visible;
    }
    
    /**
     * Informs the Link that a Node it is connected to has moved. Calls repaint
     * @see de.tub.eyes.diagram.NodeMoveListener#moved(de.tub.eyes.diagram.Node)
     */
    public void moved(Node n) {
        repaint();
    }

    /**
     * Tells the Diagram to reepaint, to relect changes to the Link
     */
    private void repaint() {
        diagram.repaint();
    }

}