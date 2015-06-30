/*
 * Maps.java
 *
 * Created on April 7, 2006, 2:11 PM
 *
 * To change this template, choose Tools | Template Manager
 * and open the template in the editor.
 */

package de.tub.eyes.diagram;

import java.util.Properties;
import java.awt.Image;
import javax.swing.ImageIcon;
/**
 *
 * @author Till Wimmer
 */
public class Maps {
    private static Properties config = null;
    private static Image [] images = null;
    
    /** Creates a new instance of Maps */
    public Maps(Properties config) {
        this.config = config;
        
        if ( images == null )
            loadImages();
    }
    
    private void loadImages() { 

        int len = Integer.parseInt(config.getProperty("map_cntImgs", "0"));
        
        if ( len == 0)
            return;
        
        images = new Image[len];
        
        for(int i=0;i<len;i++) {
            String name = config.getProperty("map_img_"+i);        
            images[i] = (new ImageIcon(name)).getImage();
        }
    }
    
    public static Image getMap(int id) {
        if (id > images.length - 1 )
            return null;
       
        return images[id];
    }
    
    public static int getWidth(int id) {
        if (id > images.length - 1 )
            return -1;
        
        return images[id].getWidth(null);
    }
    
    public static int getHeight(int id) {
        if (id > images.length - 1 )
            return -1;
        
        return images[id].getHeight(null);
    }    
 
    public static int getCnt() {
        if (images != null)
            return images.length;
        else
            return 0;
    }
    
    public static int getOffsetX(int id) {
        if (id > images.length -  1)
            return -1;
        
        return Integer.parseInt(config.getProperty("map_offX_"+id, "-1"));                
    }
    
    public static int getOffsetY(int id) {
        if (id > images.length -  1)
            return -1;
        
        return Integer.parseInt(config.getProperty("map_offY_"+id, "-1"));                
    }    
}
