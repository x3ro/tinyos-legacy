/*
 * NodePS.java
 *
 * Created on 18. Februar 2005, 23:26
 */

package de.tub.eyes.diagram;

import java.util.*;

/**
 *
 * @author Till Wimmer
 */
public class NodePS extends NodeSurge {
    Vector readings;
    
    /** Creates a new instance of NodePS */
    public NodePS() {
        super();
        readings = new Vector();
    }

    public NodePS(int x, int y, Diagram d, Date date) {
        super(x,y,d,date);
        readings = new Vector();
    }

    /**
     * Getter for 'reading' Property
     * @return The value of Property 'reading'
     */
    public Object getReading(int no) {
        return readings.elementAt(no);
    }

    /**
     * Setter for the 'reading' property
     * @param reading The new Reading
     */
    public void setReading(int no, Object reading) {
        if (readings.size() < no+1 )
            readings.setSize(no+1);
        readings.set(no, reading);
        repaint();
    }
    
    public boolean readingExists(int no) {
        if (no < readings.size() && readings.get(no) != null)
            return true;
        else
            return false;
    }
    
    public void dumpReadings() {
        for (Iterator it=readings.iterator();it.hasNext();) {
            Long val  = (Long)it.next();
            System.out.println("Reading #" + readings.indexOf(val) + " = " + val);
        }
    }
    
    public Vector getReadings() {
        return this.readings;
    }
    
}
