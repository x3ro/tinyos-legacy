/*
 * Project EYES Demonstrator
 * 
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

import java.awt.*;
import java.awt.image.BufferedImage;

/**
 * <p>
 * This is used to display the Node, while it is dragged around. By this not the
 * original Node is updated all the time, but this Ghost is used for that. The methods for
 * that are contained in the JDiagramViewer MouseAdapter methods.
 * <p>
 * In short this Node obtains an image of the node to be dragged and some other vital information
 * and paints it when required.
 * 
 * @author Joachim Praetorius
 * @see de.tub.eyes.diagram.JDiagramViewer
 */
public class DragIndicatorSurge extends NodeSurge implements DragIndicator {
    Image ghost;

    public DragIndicatorSurge(int x, int y, Diagram d, Node dragee) {
        diagram = d;
        setBounds(dragee.getBounds());
        id = dragee.getId();
        reading = dragee.getReading();
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