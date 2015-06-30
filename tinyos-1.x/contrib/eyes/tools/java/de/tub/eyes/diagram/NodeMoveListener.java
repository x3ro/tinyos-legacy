/*
 * Project EYES Demonstartor
 * 
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

/**
 * This interface is used to enable the Links to observe the Nodes. By that the Links
 * move with the Nodes without further care.
 * 
 * @author Joachim Praetorius
 */
public interface NodeMoveListener {
    /**
     * Informs the Listener that the Node has moved
     * @param n The Node that moved
     */
    public void moved(Node n);
}