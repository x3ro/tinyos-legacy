/*
 * JConfigurableDiagramViewer.java
 *
 * Created on 17. Februar 2005, 17:37
 */

package de.tub.eyes.diagram;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.gis.*;

import java.util.*;
import java.util.regex.*;
import java.io.*;
import java.io.IOException;

import java.awt.Dimension;
/**
 *
 * @author develop
 */
public class JConfigurableDiagramViewer extends JDiagramViewer {
    
    //private Demonstrator d;
    private int mapNo=-1;
    
    /** Creates a new instance of JConfigurableDiagramViewer */
    public JConfigurableDiagramViewer() {
        super();
    }
    
    /**
     * Convenience Method. Adds a new Node with the given id to the Diagram.
     * @param id The Id of the Node to add.
     */
    public Node addNode(int id, Date date) {
        Node n;
        if (Demonstrator.isSurge())
            n = new NodeSurge(getNewX(id), getNewY(id), diagram, date);
        else
            n = new NodePS(getNewX(id), getNewY(id), diagram, date);
        
        n.setId(id);
        //n.setReading(getNewX());
        diagram.addNode(n);
        
        return n;
    }
    private int getNewX(int id) {
        if (this.getWidth() == 0)
            return random.nextInt(DEFAULT_WIDTH)+10;
        else
            return random.nextInt(this.getWidth()-20)+10;                                   
    }
         
    private int getNewY(int id) {                     
        if (this.getHeight() ==0)
            return random.nextInt(DEFAULT_HEIGHT)+10;
        else
            return random.nextInt(this.getHeight()-20)+10;
    }
    
    /*
     private int getNewX(int id) {
        MoteXY xy;
        //System.out.println("Width = "+this.getWidth());
        if ( (xy = (MoteXY)xyMap.get(new Integer(id))) != null ) {
            return xy.x;           
        }
        else {
            if (this.getWidth() == 0)
                return random.nextInt(DEFAULT_WIDTH)+10;
            else
                return random.nextInt(this.getWidth()-20)+10;                                   
        }   
    }

    private int getNewY(int id) {
        MoteXY xy;
        if ( (xy = (MoteXY)xyMap.get(new Integer(id))) != null ) {
            return xy.y;           
        }
        else {
            if (this.getHeight() ==0)
                return random.nextInt(DEFAULT_HEIGHT)+10;
            else
                return random.nextInt(this.getHeight()-20)+10;
        }
    }
    */

    
 
    
    public void setMap(int mapNo) {
        this.mapNo = mapNo;
        super.setMap(mapNo);
    }
            
}
