/*
 * Created on Sep 28, 2004 by Joachim PRaetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.diagram;

import java.awt.Graphics;

/**
 * <p>This is the abstract model for an Attribute for a {@link de.tub.eyes.diagram.Node Node} that is not
 * constituted from Text but needs a graphical display.
 * The attribute may have completely random look and meaning, as nothing is implied with this base class.
 * </p>
 * 
 * <p>
 * Any graphic attribute (or, more precise sublasses of GraphicAttribute) have to be able to draw themselves,
 * for which their {@link #paint(Graphics, int, int) paint} method is called. The parameters provided with paint 
 * are the offsets at which the subclass can start painting on the graphics, without interfering other
 * attributes the node may have. For the same reason the {@link #getHeight() getHeight()} method exists. It allows
 * the node to tell the next attribute where to be rendered, without interfering the GraphicAttribute. 
 * </p>
 *  
 * @author Joachim Praetorius
 *  
 */
public abstract class GraphicAttribute extends Attribute {

    /**
     *  Needed to resemble empty Constructor from superclass
     */
    public GraphicAttribute() {
        super();
    }

    /**
     * Needed to resemble Constructor from superclass
     * @param name The name of the Attribute
     */
    public GraphicAttribute(String name) {
        super(name);
    }

    /**
     * Needed to resemble Constructor from superclass
     * @param name The name of the atribute
     * @param show indicates whether the attribute should be displayed or not
     */
    public GraphicAttribute(String name, boolean show) {
        super(name, show);
    }

    /**
     * Tells the GraphicAttribute to drawe itself on the given Graphics object.
     * The offsetX and offsetY Parameters indicate, where the GraphicAttribute may
     * start painting on the Graphics, without interfering with other Attributes being painted on 
     * the same Graphics. 
     * @param g The Graphics object to paint on
     * @param offsetX The offset in X direction
     * @param offsetY The offset in Y direction 
     */
    public abstract void paint(Graphics g, int offsetX, int offsetY);

    /**
     * To allow other Attributes to be painted without interference, each GraphicAttribute has to be able to 
     * tell its height, so other Attributes can be drawn correctly
     * @return the height of the GraphicAttribute in pixels
     */
    public abstract int getHeight();
}