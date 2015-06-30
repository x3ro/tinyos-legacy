/*
 * Avpair.java
 *
 * Created on 8. August 2005, 22:11
 */

package de.tub.eyes.apps.PS;

/**
 *
 * @author Till Wimmer
 */
public class Avpair implements java.io.Serializable {
    int attributeID;
    long value;
    
    /** Creates a new instance of Avpair */
    public Avpair() {
        
    }
    
    public Avpair(int attributeID, long value) {
        this.attributeID = attributeID;
        this.value = value;
    }
    
    public int getAttributeID() {
        return attributeID;
    }
        
    public long getValue() {
        return value;
    }
        
    public String toString() {
        return new String("Avpair{ AttributeID = " + attributeID + " Value = " + value + " }");
    }
    
}
