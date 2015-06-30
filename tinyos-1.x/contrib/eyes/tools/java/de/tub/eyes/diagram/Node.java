/*
 * Project EYES Demonstrator
 *
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

import java.awt.*;
import java.util.*;

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
public interface Node {

    /**
     * Tests whether a given point is within the bounds of the Node or not
     * @param x The x position
     * @param y The y Position
     * @return <code>true</code> if (x,y) is contained by the Node, <code>false otherwise
     */
    public boolean contains(int x, int y); 

    /**
     * Sets the selected State of the node. This influences how the Node is drawn.
     * @param selected <code>true</code> or <code>false</code>
     */
    public void setSelected(boolean selected);

    public boolean isSelected(); 

    public void setPosition(int x, int y); 

    /**
     * Sets the Position of the node
     * @param p The Point where the node should reside
     */
    public void setPosition(Point p); 
    /**
     * Returns the current position of the Node as a 2D Point
     * @return The Point where the node resides
     */
    public Point getPosition();

    /**
     * Paints the Node. This is a simple green circle, sorrounded by an orange one, if the Node is selected.
     * After the node has painted itself it paints some of the fixed attributes.
     * After that all attributes are taken from the Map and are painted one after each
     * other, depending on their type. {@link TextAttribute TextAttributes} are painted by the Node,
     * {@link GraphicAttribute GraphicAttributes} have their paint() method called for that task.
     * @param g The Grapics Object to paint on
     */
    public void paint(Graphics g); 

    /**
     * Returns the bounds of the Node
     * @return The bounds
     */
    public Rectangle getBounds();

    /**
     * Sets the bounds of the Node
     * @param bounds The new bounds
     */
    public void setBounds(Rectangle bounds); 

    /**
     * Issues a repaint.
     *
     */
    public void repaint(); 

    /**
     * Normally this would be used to only repaint the needed bounds of the Display,
     * which would speed up redrawing, as only small parts would be repainted.
     * Unfortunately I have put no time in using correct bounds, so this calls a
     * 'big' repaint, but may be cured easily.
     * @param bounds The bounds which are 'dirty' and need to be repainted.
     */
    public void repaint(Rectangle bounds);

    /**
     * Getter for 'name' Property
     * @return The value of Property 'name'
     */
    public String getName(); 

    /**
     * Setter for the 'name' property
     * @param name the new Name
     */
    public void setName(String name);

    /**
     * Getter for 'id' Property
     * @return The value of Property 'id'
     */
    public int getId();
    /**
     * Setter for the 'id' property
     * @param id the new Id
     */
    public void setId(int id); 

    /**
     * Getter for 'reading' Property
     * @return The value of Property 'reading'
     */
    public int getReading(); 

    /**
     * Setter for the 'reading' property
     * @param reading The new Reading
     */
    public void setReading(int reading); 

    /**
     * Adds a new Attribute under the given key.
     * @param key The key under which the Attibute is stored. May be used to resemble names.
     * @param value The attribute to add to the Node
     */
    public void addAttribute(Object key, Attribute value); 

    /**
     * Updates the Value stored for a Key in the Attributes map. I.e. replaces an existing Attribute.
     * Repaint() is called, so the change is reflected.
     * @param key The key for the attribute to update
     * @param value The new Attribute
     */
    public void updateAttribute(Object key, Attribute value); 

    /**
     * Returns the Attribute stored for the given key
     * @param key The key to search for
     * @return The Attribute stored for that key, or <code>null</code> if no Attribute is stored for that key.
     */
    public Object getAttribute(Object key); 
    /**
     * Returns all Attributes
     * @return All Attributes in a Map
     */
    public Map getAttributes(); 
    
    /**
     * Sets the Attributes of the Node
     * @param attributes The new Attributes
     */
    public void setAttributes(Map attributes); 

    /**
     * Getter for 'epoch' Property
     * @return The value of Property 'epoch'
     */
    public int getEpoch(); 
    
    /**
     * Setter for the 'epoch' property
     * @param epoch The new epoch
     */
    public void setEpoch(int epoch); 

    /**
     * Getter for 'parent' Property
     * @return The value of Property 'parent'
     */
    public int getParent(); 

    /**
     * Setter for the 'parent' property
     * @param parent The new Parent
     */
    public void setParent(int parent);
    
    public void setVisible(boolean visible);
    
    public boolean getVisible();

    public String toString();
}
