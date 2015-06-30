/*
 * Created on Sep 28, 2004 by Joachim PRaetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.diagram;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.Font;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Random;

import javax.swing.Timer;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.components.ConfigComponent;
import de.tub.eyes.apps.PS.PSSubscription;

/**
 * <p>This is a sample implementation for a GraphicAttribute.</p>
 * <p>To show how a GraphicAttribute could be subclassed and implemented,
 * this class was constructoed. It just shows an small red bar, that in- or decreases
 * arbitrarily (it might resemble e.g. a link quiality).
 * </p>
 *
 * @author Till Wimmer
 * @see de.tub.eyes.diagram.GraphicAttribute
 */
public class BarAttribute extends GraphicAttribute implements ActionListener {
    private Node n;
    private Timer timer;
    private int attrib;    
    private static final int FRAME_WIDTH = 50;
    private static final int FRAME_HEIGHT = 5;
    private static final int BAR_HEIGHT = 5;
    private static final int FONT_SIZE = 9;
    private static ConfigComponent cc = Demonstrator.getConfigComponent();
    /**
     * @param name
     */
    public BarAttribute(String name, Node n) {
        super(name);
        this.n = n;
    }

    /**
     * @param name
     * @param show
     */
    public BarAttribute(String name, boolean show, Node n) {
        super(name, show);
        this.n = n;
        timer = new Timer(1000,this);
    }
    
    public BarAttribute(String name, NodePS n, int attrib) {
        super(name);
        this.n = n;
        this.attrib = attrib;
        timer = new Timer(1000,this);
    }
    
    public BarAttribute(String name, boolean show, NodePS n, int attrib) {
        super(name, show);
        this.n = n;
        this.attrib = attrib;        
        timer = new Timer(1000,this);
    }

    public void paint(Graphics g, int offsetX, int offsetY) {               
        if (! (cc.isDefined(attrib) && cc.isEnabled(attrib) && cc.getType(attrib) == cc.TYPE_BAR) )
            return;
        
        double offset = cc.getMin(attrib);
        double scale = cc.getMax(attrib) - offset;
        double value;
        
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
        
        value = (FRAME_WIDTH/(scale-offset))*(value-offset);
        int width = (int)value;
        
        if (width > FRAME_WIDTH)
            width = FRAME_WIDTH;
        if (width < 0)
            width = 0;
        
        Color oldColor = g.getColor();
        Font oldFont = g.getFont();
        g.setColor(Color.red);
        g.fillRect(offsetX, offsetY, width, BAR_HEIGHT);
        g.setColor(Color.black);
        g.drawRect(offsetX, offsetY, FRAME_WIDTH, FRAME_HEIGHT);
        g.setFont(new Font(null,Font.PLAIN,FONT_SIZE));
        int textWidth = g.getFontMetrics().stringWidth(PSSubscription.getAttribName(attrib));
        g.drawString(PSSubscription.getAttribName(attrib), offsetX-textWidth - 4, offsetY+FONT_SIZE/2+1);
        g.setFont(oldFont);
        g.setColor(oldColor);
    }

    /**
     * @see de.tub.eyes.diagram.GraphicAttribute#getHeight()
     */
    public int getHeight() {
        return (FONT_SIZE > FRAME_HEIGHT) ? FONT_SIZE : FRAME_HEIGHT;
    }

    /**
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        n.repaint();
    }

}
