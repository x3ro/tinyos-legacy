package edu.mit.mers.localization;

import java.util.*;

/**
 * The Node class represents a node in the distributed network of motes. The
 * node could be an anchor node, the base node or a standard node. Every
 * node has a name, a position (x and y coordinates) and a distance from the
 * base node.
 */
public class Node {
    public static final int TYPE_ANCHOR = 0;
    public static final int TYPE_SUBSTRATE = 1; // normal node...
    public static final int TYPE_RELAY = 2;
    public static final int TYPE_FRIEND = 3; // friend tag
    public static final int TYPE_FOE = 4;
    public static final int TYPE_BASE_STATION = 5;

    public static final int NUM_TYPES = 6;

    static int MaxPotValue = 9;
    /**
     * The name of this node.
     */
    private int nodeID;
    /**
     * The x co-ordinate of this node.
     */
    private double x;
    /**
     * The y co-ordinate of this node.
     */
    private double y;

    /**
     * The ground-truth x co-ordinate of this node.
     */
    private double groundX;
    /**
     * The ground-truth y co-ordinate of this node.
     */
    private double groundY;

    private boolean isEdge;

    private boolean isRelay;

    private int potValue;

    private int moteType;

    private boolean nodeFound;

    private Map distances;
	
    private Map potValueCounts;
	
    private byte radioStats[];

    private String name = "";

    /**
     * Creates a new node with the specifed name, coordinates and distance.
     */
    public Node(int nodeID, double x, double y) {
	this.nodeID = nodeID;
	this.x = x;
	this.y = y;
	this.groundX = x;
	this.groundY = y;
	this.potValue = MaxPotValue;
	this.distances = new HashMap();
	this.potValueCounts = new HashMap();
	this.isEdge = false;
	moteType = (nodeID == 0) ? TYPE_BASE_STATION : TYPE_RELAY;
	nodeFound = (nodeID == 0);
    }

     public Node(MoteRecord m) {
       this.nodeID = m.getID();
       this.groundX = x = m.getX();
       this.groundY = y = m.getY();
       this.potValue = m.getPot();
       this.moteType = m.getMoteType();
       this.name = m.getName();
       this.distances = new HashMap();
       this.potValueCounts = new HashMap();
       nodeFound = (nodeID == 0);
     }
	
    /**
     * Creates a new node with the same name, coordinates and distance as the
     * specified node.
     */
    public Node(Node n) {
	this(n.nodeID, n.x, n.y);
    }
	

    public boolean isFound()
    {
	return nodeFound;
    }

    public void setFound(boolean nodeFound)
    {
	this.nodeFound = nodeFound;
    }

    public int getMoteType()
    {
	return moteType;
    }

    public void setMoteType(int moteType)
    {
	this.moteType = moteType;
    }

    public boolean isAnchor()
    {
	return (moteType == TYPE_ANCHOR);
    }

    public void makeAnchor()
    {
	moteType = TYPE_ANCHOR;
    }

    public boolean isRelay()
    {
	return (moteType == TYPE_RELAY);
    }

    // indicate whether the mote should be displayed
    public boolean isVisible()
    {
	return (moteType != TYPE_RELAY);
    }

    public boolean isNormal()
    {
	return (moteType == TYPE_SUBSTRATE);
    }

    /**
     * Returns the name of this node.
     */
    public int getID() {
	return nodeID;
    }

    public String getIDasString()
    {
	return (new Integer(nodeID)).toString();
    }

    public String getName()
    {
	return name;
    }

    /**
     * Returns the potValue of this node.
     */
    public int getPotValue() {
	return potValue;
    }
	
    /**
     * Sets the potValue of this node.
     */
    public void setPotValue(int x) {
	this.potValue = x;
    }

    /**
     * Returns the isEdge of this node.
     */
    public boolean getIsEdge() {
	return isEdge;
    }
	
    /**
     * Sets the isEdge of this node.
     */
    public void setIsEdge(boolean x) {
	this.isEdge = x;
    }

    /**
     * Returns the isRelay of this node.
     */
    public boolean getIsRelay() {
	return isRelay;
    }
	
    /**
     * Sets the isRelay of this node.
     */
    public void setIsRelay(boolean x) {
	this.isRelay = x;
    }

    /**
     * Returns the x coordinate of this node.
     */
    public double getX() {
	return x;
    }
	
    /**
     * Sets the x coordinate of this node.
     */
    public void setX(double x) {
	this.x = x;
    }
	
    /**
     * Returns the y coordinate of this node.
     */
    public double getY() {
	return y;
    }
	
    /**
     * Sets the y coordinate of this node.
     */
    public void setY(double y) {
	this.y = y;
    }

    /**
     * Returns the ground-truth x coordinate of this node.
     */
    public double getGroundX() {
	return groundX;
    }
	
    /**
     * Sets the ground-truth x coordinate of this node.
     */
    public void setGroundX(double x) {
	this.groundX = x;
    }
	
    /**
     * Returns the ground-truth y coordinate of this node.
     */
    public double getGroundY() {
	return groundY;
    }
	
    /**
     * Sets the ground-truth y coordinate of this node.
     */
    public void setGroundY(double y) {
	this.groundY = y;
    }

    /**
     * Returns the radioStats
     */
    public byte[] getRadioStats() {
	return radioStats;
    }
	
    /**
     * Sets the radioStats of this node.
     */
    public void setRadioStats(byte x[]) {
	this.radioStats = x;
    }
	
    public boolean knowsDistanceToNode(int nodeID) {
	return distances.containsKey(new Integer(nodeID));
    }
	
    /**
     * Returns the distance of this node from the base node.
     */
    public double getDistance(int nodeID) {
	Double dist = (Double)distances.get(new Integer(nodeID));
	if(dist != null)
	    return dist.doubleValue();
	else
	    return 0.0;
    }
	
    /**
     * Sets the distance of this node from the base node.
     */
    public void setDistance(int nodeID, double distance) {
	distances.put(new Integer(nodeID), new Double(distance));
    }

    /**
     * Returns the potValueCount of this node for this potValue
     */
    public int getPotValueCount(int value) {
	Integer count = (Integer)potValueCounts.get(new Integer(value));
	if(count != null)
	    return count.intValue();
	else
	    return 0;
    }
	
    /**
     * Increments the potValueCount of this node for this potValue
     */
    public void incPotValueCount(int value) {
	int count = getPotValueCount(value);
	potValueCounts.put(new Integer(value), new Integer(count + 1));
    }
	
    /**
     * Clears the potValueCounts
     */
    public void zapPotValueCounts () {
	potValueCounts = new HashMap();
    }
	
    /**
     * Returns a description of this node.
     */
    public String toString() {
	return "Node '" + nodeID + "' (" + x + "," + y + ")";
    }
}
