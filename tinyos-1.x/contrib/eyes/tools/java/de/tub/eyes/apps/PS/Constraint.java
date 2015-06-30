/*
 * Constraint.java
 *
 * Created on 8. August 2005, 22:08
 */

package de.tub.eyes.apps.PS;

/**
 *
 * @author Till Wimmer
 */

public class Constraint implements java.io.Serializable {        
    int attributeID;
    int operationID;
    long value;
    
    public Constraint() {
        
    }
    
    public Constraint(int attributeID, int operationID, long value) {
        this.attributeID = attributeID;
        this.operationID = operationID;
        this.value = value;
    }
    
    public int getAttributeID() {
        return attributeID;
    }
    
    public int getOperationID() {
        return operationID;
    }
    
    public long getValue() {
        return value;
    }
        
    public String toString() {
        return new String("Constraint{ AttributeID = " + attributeID + " OperatorID = " + operationID + " Value = " + value + " }");
    }    
}
