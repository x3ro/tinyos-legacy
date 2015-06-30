/*
 * NodeSurge.java
 *
 * Created on 20. Februar 2005, 18:58
 */

package de.tub.eyes.diagram;

import java.awt.*;
import java.util.*;
import javax.swing.*;

import de.tub.eyes.apps.demonstrator.*;

/**
 *
 * @author develop
 */
/**
 * Models a Node in a TinyOS Network.
 * This class holds some common attributes, as x,y,id,reading... but also provides
 * the possibility to add random custom attributes. Therefore it contains a Map in which
 * {@link de.tub.eyes.diagram.Attribute Attribute} objects can be placed.
 * These may contain arbitrary information.
 * The Diagram is known to the nodes so they can issue a repaint, when this is needed due to changed information
 *
 * @author Joachim Praetorius
 */
public class NodeSurge implements Node {

    private static final int RADIUS = 20;
    private static final int SELECTION_RADIUS = 27;
    private static final int R_OFFSET = 10;
    private static final int S_OFFSET = 14;
    private static final Color node = Color.green.darker();
    private static final Color selection = Color.orange;
    private static ImageIcon imageHelper = new ImageIcon("img/base.png", "img/base.png");
    private static Image image = imageHelper.getImage();
    // TODO: make this properly
    private static int uartAddr = 0;//Integer.parseInt(Demonstrator.getProps().getProperty("uartAddr", "126"));

    //***Painting information***
    private int x, y;
    private boolean selected;
    Rectangle bounds;
    Diagram diagram;

    //***Node Information***
    Map attributes;
    int id, reading, parent, epoch;
    String name;
    Date date;
    boolean visible = false;

    /**
     * Empty Constructor
     *
     */
    public NodeSurge() {

    }

    /**
     * Creates a new Node with the given Parameters
     * @param x The x Location
     * @param y The y Location
     * @param d The Diagram the Node belongs to
     */
    public NodeSurge(int x, int y, Diagram d, Date date) {
        this.x = x;
        this.y = y;
        this.diagram = d;
        this.date = date;
        attributes = new HashMap();
        bounds = new Rectangle(x - R_OFFSET, y - R_OFFSET, RADIUS, RADIUS);
    }

    /**
     * Tests whether a given point is within the bounds of the Node or not
     * @param x The x position
     * @param y The y Position
     * @return <code>true</code> if (x,y) is contained by the Node, <code>false otherwise
     */
    public boolean contains(int x, int y) {
        return bounds.contains(x, y);
    }

    /**
     * Sets the selected State of the node. This influences how the Node is drawn.
     * @param selected <code>true</code> or <code>false</code>
     */
    public void setSelected(boolean selected) {
        if (this.selected != selected) {
            this.selected = selected;
            repaint();
        }
    }

    public boolean isSelected() {
      if (selected) return true;
      else return false;
    }

    public void setPosition(int x, int y) {
        if (this.x != x || this.y != y) {
            this.x = x;
            this.y = y;
            bounds.setLocation(x - R_OFFSET, y - R_OFFSET);
            repaint();
        }
    }

    /**
     * Sets the Position of the node
     * @param p The Point where the node should reside
     */
    public void setPosition(Point p) {
        if (this.x != p.x || this.y != p.y) {
            this.x = p.x;
            this.y = p.y;
            bounds.setLocation(x - R_OFFSET, y - R_OFFSET);
            repaint();
        }
    }

    /**
     * Returns the current position of the Node as a 2D Point
     * @return The Point where the node resides
     */
    public Point getPosition() {
        return new Point(x, y);
    }

    /**
     * Paints the Node. This is a simple green circle, sorrounded by an orange one, if the Node is selected.
     * After the node has painted itself it paints some of the fixed attributes.
     * After that all attributes are taken from the Map and are painted one after each
     * other, depending on their type. {@link TextAttribute TextAttributes} are painted by the Node,
     * {@link GraphicAttribute GraphicAttributes} have their paint() method called for that task.
     * @param g The Grapics Object to paint on
     */
    public void paint(Graphics g) {
        if ( !visible )
            return;
        
        Graphics2D g2 = (Graphics2D) g;
        g2.setColor(node);
                
        if (id == uartAddr) {
            //g2.fillRect(x - S_OFFSET, y - S_OFFSET, 20, 20);
            g2.setColor(Color.black);
            //g2.drawString("UART", x-20, y + 30);
            g2.drawImage(image, x - 20, y - 20,40,40,null);
            return;
        }
        
        g2.fillOval(x - R_OFFSET, y - R_OFFSET, RADIUS, RADIUS);
        if (selected) {
            g2.setStroke(new BasicStroke(2));
            g2.setColor(selection);
            g2.drawOval(x - S_OFFSET, y - S_OFFSET, SELECTION_RADIUS,
                    SELECTION_RADIUS);
        }

        g2.setColor(Color.black);
        g2.drawString("Mote: " + id, x - R_OFFSET, y + R_OFFSET + 8);
        int inc = 15;

        for (Iterator it = attributes.keySet().iterator(); it.hasNext();) {
            Attribute a = (Attribute) attributes.get(it.next());
            if (a.isShow()) {
                
                if (a instanceof DotAttribute) {
                    GraphicAttribute ga = (GraphicAttribute) a;
                    ga.paint(g2, x - R_OFFSET , y - R_OFFSET);
                    continue;
                }
                
                if (a instanceof GraphicAttribute) {
                    GraphicAttribute ga = (GraphicAttribute) a;
                    ga.paint(g2, x - R_OFFSET, y + R_OFFSET + inc);
                    inc += ga.getHeight() + 5;
                    continue;
                }

            }

        }
    }

    /**
     * Returns the bounds of the Node
     * @return The bounds
     */
    public Rectangle getBounds() {
        return bounds;
    }

    /**
     * Sets the bounds of the Node
     * @param bounds The new bounds
     */
    public void setBounds(Rectangle bounds) {
        this.bounds = bounds;
    }

    /**
     * Issues a repaint.
     *
     */
    public void repaint() {
        repaint(bounds);
    }

    /**
     * Normally this would be used to only repaint the needed bounds of the Display,
     * which would speed up redrawing, as only small parts would be repainted.
     * Unfortunately I have put no time in using correct bounds, so this calls a
     * 'big' repaint, but may be cured easily.
     * @param bounds The bounds which are 'dirty' and need to be repainted.
     */
    public void repaint(Rectangle bounds) {
        if (diagram != null) {
            diagram.repaint();
            //diagram.repaint(bounds)
        }
    }

    /**
     * Getter for 'name' Property
     * @return The value of Property 'name'
     */
    public String getName() {
        return name;
    }

    /**
     * Setter for the 'name' property
     * @param name the new Name
     */
    public void setName(String name) {
        this.name = name;
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
        if (id == 126) {           
            bounds.setRect(x - 20, y - 20, 40,  40);
        }
        repaint();
    }

    /**
     * Getter for 'reading' Property
     * @return The value of Property 'reading'
     */
    public int getReading() {
        return reading;
    }

    /**
     * Setter for the 'reading' property
     * @param reading The new Reading
     */
    public void setReading(int reading) {
        this.reading = reading;
        repaint();
    }

    /**
     * Adds a new Attribute under the given key.
     * @param key The key under which the Attibute is stored. May be used to resemble names.
     * @param value The attribute to add to the Node
     */
    public void addAttribute(Object key, Attribute value) {
        attributes.put(key, value);
    }

    /**
     * Updates the Value stored for a Key in the Attributes map. I.e. replaces an existing Attribute.
     * Repaint() is called, so the change is reflected.
     * @param key The key for the attribute to update
     * @param value The new Attribute
     */
    public void updateAttribute(Object key, Attribute value) {
        attributes.put(key, value);
        repaint();
    }

    /**
     * Returns the Attribute stored for the given key
     * @param key The key to search for
     * @return The Attribute stored for that key, or <code>null</code> if no Attribute is stored for that key.
     */
    public Object getAttribute(Object key) {
        return attributes.get(key);
    }

    /**
     * Returns all Attributes
     * @return All Attributes in a Map
     */
    public Map getAttributes() {
        return attributes;
    }

    /**
     * Sets the Attributes of the Node
     * @param attributes The new Attributes
     */
    public void setAttributes(Map attributes) {
        this.attributes = attributes;
    }

    /**
     * Getter for 'epoch' Property
     * @return The value of Property 'epoch'
     */
    public int getEpoch() {
        return epoch;
    }

    /**
     * Setter for the 'epoch' property
     * @param epoch The new epoch
     */
    public void setEpoch(int epoch) {
        this.epoch = epoch;
    }

    /**
     * Getter for 'parent' Property
     * @return The value of Property 'parent'
     */
    public int getParent() {
        return parent;
    }

    /**
     * Setter for the 'parent' property
     * @param parent The new Parent
     */
    public void setParent(int parent) {
        this.parent = parent;
    }

    public String toString(){ // when adding a node, this method is automatically called
      return "Mote "+getId();
    }
    
    public NodePS getPS() {
        return new NodePS(this.x, this.y, this.diagram, this.date);
    }
    
    public void setVisible(boolean visible) {
        this.visible = visible;
    }
    
    public boolean getVisible() {
        return this.visible;
    }
}
