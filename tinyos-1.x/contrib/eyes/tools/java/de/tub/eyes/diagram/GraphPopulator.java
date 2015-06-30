/*
 * GraphPopulater.java
 *
 * Created on 17. Februar 2005, 06:02
 */

package de.tub.eyes.diagram;

import java.util.Date;

/**
 *
 * @author develop
 */
public interface GraphPopulator {
    public Node addNode(int id, Date date);
    public Link addLink(int startNode, int endNode, Date date);
}
