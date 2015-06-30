/*
 * GraphUpdater.java
 *
 * Created on 17. Februar 2005, 05:25
 */

package de.tub.eyes.diagram;

/**
 *
 * @author Till Wimmer
 */
public interface GraphRemover {
    public void removeNode(int id);
    public void removeLink(int startNode, int endNode);
}
