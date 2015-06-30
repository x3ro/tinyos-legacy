/*
 * DotAttribute.java
 *
 * Created on 20. Februar 2005, 16:52
 */

package de.tub.eyes.diagram;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Random;

import javax.swing.Timer;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.components.ConfigComponent;

/**
 *
 * @author Till Wimmer
 */
public class DotAttribute extends GraphicAttribute implements ActionListener {
    private Node n;
    private Timer timer;    
    private static final int RADIUS = 16;
    private static final int SELECTION_RADIUS = 27;
    private static final int Y_OFFSET = -2;//43;
    private static final int X_OFFSET = -2; //-2; 
    private int attrib = -1;
    private static ConfigComponent cc = Demonstrator.getConfigComponent();

    /** Creates a new instance of DotAttribute */
    public DotAttribute(String name, Node n) {
        super(name);
        this.n = n;
    }
    
    /** Creates a new instance of DotAttribute */
    public DotAttribute(String name, boolean show, Node n) {
        super(name,show);
        this.n = n;
        timer = new Timer(1000,this);
    }
    
    /** Creates a new instance of DotAttribute */
    public DotAttribute(String name, boolean show, NodePS n, int attrib) {
        super(name,show);
        this.n = n;
        this.attrib = attrib;
        timer = new Timer(1000,this);
    }    

    public void paint(Graphics g, int x, int y) {
        if (! (cc.isDefined(attrib) && cc.isEnabled(attrib) && cc.getType(attrib) == cc.TYPE_DOT) )
            return;

        double value;
        double offset = cc.getMin(attrib);
        double scale = cc.getMax(attrib) - offset;      
        
        if (n instanceof NodePS && ((NodePS)n).readingExists(attrib)) {

            Object obj = ((NodePS)n).getReading(attrib);
            if (obj instanceof Long)
                value = ((Long)obj).doubleValue();
            else if (obj instanceof Double)
                value = ((Double)obj).doubleValue();
            else
                return;
        }   
        else 
            value = (double)n.getReading();        
        
        value = (255/(scale-offset))*(value-offset);
        int color = (int)value;
        if (color > 255)
            color = 255;
        if (color < 0)
            color = 0;
        
        g.setColor(new Color(color,0,0));
        g.fillOval(x - X_OFFSET, y - Y_OFFSET, RADIUS, RADIUS);

    }
    
    /**
     * @see de.tub.eyes.diagram.GraphicAttribute#getHeight()
     */
    public int getHeight() {
        return RADIUS + 5;
    }
    
    /**
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        n.repaint();
    }    
    
}
