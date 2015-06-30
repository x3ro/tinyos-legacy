/*
 * SnapshotHandler.java
 *
 * Created on 7. November 2005, 16:40
 */

package de.tub.eyes.apps.demonstrator;

import java.util.TreeMap;

/**
 *
 * @author Till Wimmer
 */
public interface SnapshotHandler {
    TreeMap getSnapshot(); 
    void restoreSnapshot(TreeMap dataMap);
}
