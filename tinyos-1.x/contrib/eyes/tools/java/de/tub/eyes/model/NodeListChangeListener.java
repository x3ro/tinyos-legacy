/*
 * Created on Sep 20, 2004 by Joachim Praetorius
 * Project EYES Demonstrator
 *
 */

package de.tub.eyes.model;

import de.tub.eyes.diagram.Node;

/**
 * Allows to monitor the change of Selection of Nodes in a
 * {@link de.tub.eyes.diagram.Diagram Diagram}. The newly selected Node is
 * reported to the Listener so it can use this Node easily without another call
 *
 * @author jpraetorius
 */
public interface NodeListChangeListener {
    /**
     * Provides the newly selected Node to the Listener implementing this
     * Interface
     *
     * @param newNode
     */
    public void addNode(Node newNode);
}
