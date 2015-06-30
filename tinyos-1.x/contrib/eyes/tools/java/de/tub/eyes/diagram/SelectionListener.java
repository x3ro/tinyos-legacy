/*
 * Created on Sep 28, 2004 by Joachim Praetorius
 * Project EYES Demonstrator
 *
 */
package de.tub.eyes.diagram;

/**
 * 
 * This Interface enables the obeservation of the Selection Object. Whenever the primary Selection
 * changes the Listener gets called.
 * @author Joachim Praetorius
 *  
 */
public interface SelectionListener {
    /**
     * Informs the Listener that the primary selected node has changed
     * @param n The new primary selected node, or <code>null</code> if no node is selected
     * @see Selection#getPrimarySelection() 
     */
    public void selectionChanged(Node n);
}