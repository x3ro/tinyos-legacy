/*
 * GIS.java
 *
 * Created on March 24, 2006, 5:49 AM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package de.tub.eyes.gis;

import java.sql.*;
import java.util.*;
import java.io.*;


/**
 *
 * @author Till Wimmer
 */
public class GIS {
    private Connection db = null;
    private static TreeMap nodes = new TreeMap();
    private static Properties config = null;
    private static String propFile = null;
    private Plugin plugin = null;
    
    static final String [] GIS_TYPES = {"jdbc", "textfile"};
    
    /** Creates a new instance of GIS */
    public GIS() {
    }
    
    public GIS(String propFile)  {
        this.propFile = propFile;
    }
    
    public boolean init(String className) {
        if (!readProps())
            return false;
        
        if (className.equals("jdbc")) {
            plugin = new Jdbc(config);
            return plugin.init();
        }
        
        if (className.equals("textfile")) {
            plugin = new Textfile(config);
            return plugin.init();
        }
        
        return false;
    }
        
    public boolean readDB() {
        if (plugin == null)
            return false;
        
        return plugin.readDB(nodes);        
    }
    
    public static int [] getFloorXY(int ID, int map) {
        //System.out.print("getFloorXY: ");
        if (nodes == null) {
            System.err.println("nodes = null!");
        
            return null;
        }
        
        MapXY node = null;
        if ( (node=(MapXY)nodes.get(new Integer(ID))) == null ) {
            System.out.println("ID not found.");
            
            return null;
        }
        else {
            //System.out.println("ID "+ID+": map = "+node.map+" x = "+node.x+" y = "+node.y);
            return node.get(map);
        }
    }
        
    public void setPropFile(String propFile) {
        this.propFile = propFile;
    }
    
    private boolean readProps() {
        try {
            config = new Properties();
            if (propFile == null)
                config.load( new FileInputStream("GIS.properties"));
            else
                config.load(new FileInputStream(propFile));
        }
        catch (IOException e) {
            System.err.println(e);
            return false;
        }
        
        return true;
    }    
}
