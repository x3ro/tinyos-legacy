package de.tub.eyes.gui.customelements;

import java.awt.*;
import java.util.List;

import javax.swing.JComponent;

/**
 * This is a custom FocusTraversal Policy that allows to transfer the 
 * Focus between Components in a container in a predetermined way.
 * Normally a Swing Container focuses Components in the order they were added
 * to the container. 
 * This Traversal policy relies on a List (filled with Componments) to determine 
 * the next focusable component. By that adding and focus traversal are decoupled.
 * 
 * @author Joachim Praetorius
 */
public class SimpleFocusTraversalPolicy extends FocusTraversalPolicy {

    private List componentsToCycle;
    private Container container;

    public SimpleFocusTraversalPolicy(Container c, List l) {
        componentsToCycle = l;
        container = c;
    }

    /**
     * @see java.awt.FocusTraversalPolicy#getComponentAfter(java.awt.Container,
     *      java.awt.Component)
     */
    public Component getComponentAfter(Container focusCycleRoot,
            Component aComponent) {
        int index = componentsToCycle.indexOf(aComponent);
        JComponent jc;
        if (index == (componentsToCycle.size() - 1)) {
            jc = (JComponent) componentsToCycle.get(0);
            if (!jc.isEnabled()) {
                return getComponentAfter(focusCycleRoot, jc);
            } else {
                return jc;
            }//else
        } else {
            jc = (JComponent) componentsToCycle.get(index + 1);
            if (!jc.isEnabled()) {
                return getComponentAfter(focusCycleRoot, jc);
            } else {
                return jc;
            }//else
        }
    }

    /**
     * @see java.awt.FocusTraversalPolicy#getComponentBefore(java.awt.Container,
     *      java.awt.Component)
     */
    public Component getComponentBefore(Container focusCycleRoot,
            Component aComponent) {
        int index = componentsToCycle.indexOf(aComponent);
        JComponent jc;
        if (index == 0) {
            jc = (JComponent) componentsToCycle
                    .get(componentsToCycle.size() - 1);
            if (!jc.isEnabled()) {
                return getComponentBefore(focusCycleRoot, jc);
            } else {
                return jc;
            }//else
        } else {
            jc = (JComponent) componentsToCycle.get(index - 1);
            if (!jc.isEnabled()) {
                return getComponentBefore(focusCycleRoot, jc);
            } else {
                return jc;
            }//else
        }
    }

    /**
     * @see java.awt.FocusTraversalPolicy#getFirstComponent(java.awt.Container)
     */
    public Component getFirstComponent(Container focusCycleRoot) {
        return (Component) componentsToCycle.get(0);
    }

    /**
     * @see java.awt.FocusTraversalPolicy#getLastComponent(java.awt.Container)
     */
    public Component getLastComponent(Container focusCycleRoot) {
        return (Component) componentsToCycle.get(componentsToCycle.size() - 1);
    }

    /**
     * @see java.awt.FocusTraversalPolicy#getDefaultComponent(java.awt.Container)
     */
    public Component getDefaultComponent(Container focusCycleRoot) {
        return container;
    }

}