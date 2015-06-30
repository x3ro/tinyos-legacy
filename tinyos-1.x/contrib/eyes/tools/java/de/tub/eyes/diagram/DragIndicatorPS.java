/*
 * DragIndicatorPS.java
 *
 * Created on 26. Mai 2005, 00:50
 */

package de.tub.eyes.diagram;

import java.awt.*;
import java.awt.image.BufferedImage;

/**
 *
 * @author Till Wimmer
 */
public class DragIndicatorPS extends NodePS implements DragIndicator {
    
    Image ghost;

    public DragIndicatorPS(int x, int y, Diagram d, NodePS dragee) {
        diagram = d;
        setBounds(dragee.getBounds());
        id = dragee.getId();
        readings = dragee.getReadings();
        attributes = dragee.getAttributes();
        summonGhost(dragee);
    }

    /**
     * customized paint
     * @see de.tub.eyes.diagram.Node#paint(Graphics)
     */
    public void paint(Graphics2D g) {
        g.setComposite(AlphaComposite
                .getInstance(AlphaComposite.SRC_OVER, 0.8f));
        g.drawImage(ghost, bounds.x, bounds.y, null);
    }

    private void summonGhost(Node dragee) {
        Rectangle dBounds = dragee.getBounds();
        ghost = new BufferedImage(dBounds.width, dBounds.height,
                BufferedImage.TYPE_INT_RGB);
        Graphics g = ghost.getGraphics();
        g.translate(-dBounds.x, -dBounds.y);
        dragee.paint(g);
        g.dispose();
    }
}
