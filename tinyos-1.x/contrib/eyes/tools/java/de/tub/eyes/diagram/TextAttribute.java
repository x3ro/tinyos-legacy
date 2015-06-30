/*
 * Created on Sep 28, 2004 by Joachim Praetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.diagram;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.Font;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.components.ConfigComponent;

/**
 * <p>This is the abstract model for an Attribute for a {@link de.tub.eyes.diagram.Node Node} that is 
 * constituted from Text.
 * The attribute may have completely random meaning and content.
 * </p>
 * 
 * <p>
 * In contrast to {@link de.tub.eyes.diagram.GraphicAttribute GraphicAttributes} TextAttributes don't
 * need to draw themselves but get painted by Node they belong to. Therefor the {@link #getName() getName}
 * and {@link #getValue() getValue} methods are called and displayed as:<pre> $NAME: $VALUE</pre>.  
 * </p>
 * 
 * @author Till Wimmer
 *  
 */
public class TextAttribute extends GraphicAttribute {

    private static final int X_OFFSET = -5;
    private static final int Y_OFFSET = -5;
    private static final int FONT_SIZE = 11;    
    private Node n;
    private int attrib = -1;    
    private static ConfigComponent cc = Demonstrator.getConfigComponent();

    /**
     * Creates a TextAttribtue with the given name
     * @param name The name of the Attribute
     */
    public TextAttribute(String name, Node n) {
        super(name);
        this.n = n;
    }

    /**
     * Creates a TextAttribtue with the given name
     * @param name The name of the Attribute
     */
    public TextAttribute(String name, boolean show, Node n) {
        super(name, show);
        this.n = n;

    }

    /**
     * Creates a TextAttribtue with the given name and value
     * @param name The name of the Attribute
     * @param attrib The ID of the Attribute
     */
    public TextAttribute(String name, boolean show, NodePS n, int attrib) {
        super(name, show);
        this.n = n;
        this.attrib = attrib;
    }
    
    public void paint(Graphics g, int x, int y) {
        if (! (cc.isDefined(attrib) && cc.isEnabled(attrib) && cc.getType(attrib) == cc.TYPE_TXT))
            return;

        String value = null;
        
        if (n instanceof NodePS && ((NodePS)n).readingExists(attrib)) {
            Object obj = ((NodePS)n).getReading(attrib);
            if (obj instanceof String)
                value = ((String)obj);
            else
                return;            
        }     
        //else 
        //    value = n.getReading();   
        
        Color oldColor = g.getColor();
        Font oldFont = g.getFont();        
        g.setColor(Color.black);
        g.setFont(new Font(null,Font.PLAIN,FONT_SIZE));
        int textWidth = g.getFontMetrics().stringWidth(name);
        g.drawString(name + ": " + value, x-X_OFFSET-textWidth, y-Y_OFFSET);
        g.setFont(oldFont);
        g.setColor(oldColor);
    }
    
    /**
     * @see de.tub.eyes.diagram.GraphicAttribute#getHeight()
     */
    public int getHeight() {
        return FONT_SIZE;
    }    
}
