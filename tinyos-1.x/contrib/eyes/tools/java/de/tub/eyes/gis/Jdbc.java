/*
 * jdbc.java
 *
 * Created on April 3, 2006, 4:50 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package de.tub.eyes.gis;

import java.sql.*;
import java.util.*;

/**
 *
 * @author develop
 */
public class Jdbc implements Plugin {
    private Connection db = null;
    private Properties config = null;
    
    /** Creates a new instance of jdbc */
    public Jdbc(Properties config) {
        this.config = config;
    }
    
    public boolean init() {
        try {
            Class.forName("org.postgresql.Driver");
        
        } catch (Exception e) {
            System.err.println("Error opening PostgreSQL JDBC driver");
            return false;
        }
        
        String url, usr, pwd;

        url = config.getProperty("jdbc_url");
        usr = config.getProperty("jdbc_usr");
        pwd = config.getProperty("jdbc_pwd");
        
        try {
            db = DriverManager.getConnection(url, usr, pwd);
        } catch (Exception e) {
            System.err.println(e.getLocalizedMessage());
            return false;
        }
        return true;
    }
        
    public boolean readDB(TreeMap nodes) {
        if (db == null)
            return false;
        
        nodes.clear();
        
        int cntMaps = Integer.parseInt(config.getProperty("jdbc_cntMaps", "0"));
        //int cntMaps = Integer.parseInt(config.getProperty("map_cntImgs", "0"));        
        //if (cntMaps == 0 || cntMaps == 0)
        //    return false;
        
        float [] floorMin = new float [cntMaps];
        float [] floorMax = new float[cntMaps];
        float [] scale = new float[cntMaps];
        int [] type = new int[cntMaps];
        
        for (int i=0; i<cntMaps; i++) {
            String name = "jdbc_zMin_" + i;
            floorMin[i]= Float.parseFloat(config.getProperty(name));
            name = "jdbc_zMax_" + i;
            floorMax[i]= Float.parseFloat(config.getProperty(name));           
        }
                 
        for (int i=0; i<cntMaps; i++) {
            String name = "jdbc_scale_" + i;
            scale[i]= Float.parseFloat(config.getProperty(name));            
        }
        
        for (int i=0; i<cntMaps; i++) {
            String name = "jdbc_mapType_" + i;
            type[i]= Integer.parseInt(config.getProperty(name, "0"));            
        }       
        
        Statement  st=null;
        
        try {
            st = db.createStatement();
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        ResultSet rs=null;
        
        for (int map=0; map < cntMaps; map++) {
            String statement;
            switch(type[map]) {
                
                case 0:
                    statement = "SELECT * from node_xyz WHERE location_z >= " + floorMin[map]
                            + " AND location_z <= " + floorMax[map];
                    break;
                case 1:
                    statement = "SELECT * from node_xyz WHERE location_x >= " + floorMin[map]
                            + " AND location_x <= " + floorMax[map];
                    break;
                case 2:
                    statement = "SELECT * from node_xyz WHERE location_y >= " + floorMin[map]
                            + " AND location_y <= " + floorMax[map];
                    break;
                default:
                    continue;
            }
        
            try {
                rs = st.executeQuery(statement);
            } catch (Exception e) { continue; }
        
            if (rs == null)
                continue;
            try {
                while (rs.next()) {
                    MapXY node;
                    int x,y;
                    
                    Integer ID = new Integer(rs.getInt("node_id"));
                    if ((node = (MapXY)nodes.get(ID)) == null)
                        node = new MapXY();
                                        
                    switch (type[map]) {
                        
                        case 0:
                            x = (int)(rs.getFloat("location_x")*scale[map]);
                            y = (int)(rs.getFloat("location_y")*scale[map]);                            
                            break;
                        case 1:
                            x = (int)(rs.getFloat("location_y")*scale[map]);
                            y = (int)(rs.getFloat("location_z")*scale[map]);                            
                            break;
                        case 2:
                            x = (int)(rs.getFloat("location_x")*scale[map]);
                            y = (int)(rs.getFloat("location_z")*scale[map]);                            
                            break;
                        default:
                            continue;
                    }
                            
                    //System.out.println("x="+x+" y="+y+" map="+map+" ID="+ID);                    
                    node.set(map,x,y);
                    nodes.put(ID, node);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
            try { rs.close(); } catch (Exception e) {
                e.printStackTrace();
            }
        }
             
        try { st.close(); } catch (Exception e) {        
            e.printStackTrace();
        }
        
        return true;
    }
}
