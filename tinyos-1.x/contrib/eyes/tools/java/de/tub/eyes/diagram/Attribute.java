/*
 * Created on Sep 28, 2004 by Joachim Praetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.diagram;

/**
 * <p>
 * This is the Abstract Model for a custom attribute that may be added to a Node.
 * It is thought to be either showing on the Network Display or not (indicated by the show attribute).
 * So arbitrary custom Attributes may be added to Nodes and be displayed if this is desired.
 * </p>
 * <p>
 * Because of the possibility to display the Attributes, this class has two Subclasses:
 * {@link de.tub.eyes.diagram.TextAttribute TextAttribute} and {@link de.tub.eyes.diagram.GraphicAttribute GraphicAttribute}
 * which model either a text-only attribute or a graphical attribute (as a bar, or an indicator lamp...).
 * </p>
 * <p>
 * In this base Version every Attribute has a name and the <code>show</code> attribute which can be set
 * accordingly to the own wishes. Additional information is added at the subclasses.
 * </p>
 * @author Joachim Praetorius
 * @see de.tub.eyes.diagram.GraphicAttribute
 * @see Attribute
 */
public class Attribute {

    String name;
    boolean show;

    /**
     * Creates a new Attribute
     *
     */
    public Attribute() {
    }

    /**
     * Creates a new Attribute with the given name
     * @param name the name for the attribute
     */
    public Attribute(String name) {
        this.name = name;
    }

    /**
     * Creates a new Attribute with the given name and visibility
     * @param name the name for the attribute
     * @param show <code>true</code> if the attribute sould be displayed, <code>false</code> otherwise
     */
    public Attribute(String name, boolean show) {
        this.name = name;
        this.show = show;
    }

    /**
     * Returns the name	
     * @return the name of the Attribute
     */
    public String getName() {
        return name;
    }

    /**
     * Sets the name
     * @param name the name of the attribute
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Returns whether this attribute is shown or not
     * @return <code>true</code> of shown, <code>false</code> otherwise
     */
    public boolean isShow() {
        return show;
    }

    /**
     * Sets whether this attribute should be shown or not
     * @param show <code>true</code> if the attribute should be shown, <code>false</code>otherwise
     */
    public void setShow(boolean show) {
        this.show = show;
    }
}