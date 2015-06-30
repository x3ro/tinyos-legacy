/*
 * textfile.java
 *
 * Created on April 3, 2006, 4:50 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package de.tub.eyes.gis;

import java.io.*;
import java.util.Properties;
import java.util.TreeMap;
import java.util.regex.Pattern;

/**
 *
 * @author develop
 */
public class Textfile implements Plugin {
    private Properties config;
    
    /** Creates a new instance of textfile */
    public Textfile(Properties config) {
        this.config = config;
    }
    
    public boolean init() {
        return true;
    }

    public boolean readDB(TreeMap nodes) {
        String line;
        String fname;        

        if ( (fname = config.getProperty("textfile_TableFile")) == null 
                || fname.equals("") )
            return false;

        File fh = new File(fname);
        FileReader fr = null;
        try {
            fr = new FileReader(fh);
        }
        catch (FileNotFoundException e) {
            System.err.println("File " + fname + ":" + e);
            return false;
        }
        
        nodes.clear();
                
        BufferedReader in = new BufferedReader(fr);
        
        try {
            while ((line = in.readLine()) != null) {
                MapXY node;
                int x,y,map;
                
                String [] data  = Pattern.compile("\t").split(line);
                if (data.length < 4) {
                    System.err.println ("readTable(): XY Parse error");
                    continue;
                }
                Integer id = new Integer(data[0]);
                x = Integer.parseInt(data[1]);
                y = Integer.parseInt(data[2]);
                map = Integer.parseInt(data[3]);
                
                if ( (node = (MapXY)nodes.get(id)) == null)
                    node = new MapXY();
                //nodeMap.put(new Integer(nodeData.ID), nodeData);
                node.set(map,x,y);
                nodes.put(id, node);
            }
        }
        catch (IOException e) {
            System.err.println(e.getMessage());
            return false;
        }
        
        return true;
    }    
}
