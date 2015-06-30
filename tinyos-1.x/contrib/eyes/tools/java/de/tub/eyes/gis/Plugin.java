/*
 * plugin.java
 *
 * Created on April 3, 2006, 5:32 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package de.tub.eyes.gis;

import java.util.Properties;


/**
 *
 * @author Till Wimmer
 */
public interface Plugin {
    public boolean init();
    public boolean readDB(java.util.TreeMap nodes);
}
