/*
 * mapXY.java
 *
 * Created on April 3, 2006, 5:48 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package de.tub.eyes.gis;

import java.util.*;

/**
 *
 * @author Till Wimmer
 */
public class MapXY {
    Map coordinates;
    
    /** Creates a new instance of mapXY */
    public MapXY() {
        coordinates = new TreeMap();
    }        
        
    public void set(int map, int x, int y) {
        int [] xy = {x,y};
        coordinates.put(new Integer(map), xy);  
    }
    
    public int[] get(int map) {
        return (int[])coordinates.get(new Integer(map));
    }
}
