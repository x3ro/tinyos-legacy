package edu.mit.mers.localization;

import java.util.*;

/**
 * The Tag class represents a tag mote in a network of sensor motes. 
 */
public class Tag {
    public static final int TYPE_ANCHOR = 0;
    public static final int TYPE_SUBSTRATE = 1; // normal node...
    public static final int TYPE_RELAY = 2;
    public static final int TYPE_FRIEND = 3; // friend tag
    public static final int TYPE_FOE = 4;
    public static final int TYPE_BASE_STATION = 5;

    public static final int NUM_TYPES = 6;
   

    /**
     * The name of this node.
     */
    private int nodeID;

    private int tagType;

    /**
     * A map from nodes to timestamps
     */
    private Map observations;

    private boolean useStrength = false;

    private double strengthDerivedX = 1.0;
    private double strengthDerivedY = 1.0;
	
    /**
     * Creates a new node with the specifed name, coordinates and distance.
     */
    public Tag(int nodeID) {
	this.nodeID = nodeID;
	this.observations = new HashMap();
	tagType = TYPE_FRIEND;
    }
	
    public Tag(TagRecord t)
    {
	this.nodeID = t.getID();
	this.tagType = t.getTagType();
	this.observations = new HashMap();
    }

    /**
     * Returns the name of this node.
     */
    public int getID() {
	return nodeID;
    }
	
    public String getName() {
	return (new Integer(nodeID)).toString();
    }

    public boolean isFriend()
    {
	return tagType == TYPE_FRIEND;
    }
    
    public boolean isFoe()
    {
	return tagType == TYPE_FOE;
    }

    public int getTagType()
    {
	return tagType;
    }

    public void setTagType(int type)
    {
	tagType = type;
    }

    // record class
    public class TagObservationRec
    {
	public TagObservationRec(Date time, int strength)
	{
	    this.time = time;
	    this.strength = strength;
	}

	public int strength;
	public Date time;
    }

    /**
     * Get observation
     */
    public ArrayList getObservation(Node node) {
	return (ArrayList)observations.get(node);
    }
	
    /**
     * Add observation
     */
    public void addObservation(Node node, int strength) {
	ArrayList times;
	if (observations.containsKey(node))
	    times = (ArrayList)observations.get(node);
	else {
	    times = new ArrayList();
	    observations.put(node, times);
	}
	times.add(new TagObservationRec(new Date(), strength));
    }
	
    /**
     * Get observations
     */
    public Iterator getObservations() {
	return observations.entrySet().iterator();
    }
	
    static long timeSeconds (Calendar t, Date d) {
	t.setTime(d);
	return t.get(Calendar.HOUR)*60*60 + t.get(Calendar.MINUTE)*60 + t.get(Calendar.SECOND);
    }

    static double timeDiff (Date t1, Date t2) {
	Calendar cal = new GregorianCalendar();
	long s1      = timeSeconds(cal, t1);
	long s2      = timeSeconds(cal, t2);
	return (s1 - s2);
    }

    static double timeDelta (Date time) {
	Date now = new Date();
	return timeDiff(now, time);
    }

    public boolean isCurrent (Date time) {
	return (timeDelta(time) < 10.0);
    }

    /**
     * Returns the x coordinate of this node.
     */
    public double getX() {
	if(useStrength)
	{
	    calcStrengthLoc();
	    return strengthDerivedX;
	}
	    
	int    count  = 0;
	double x      = 0.0;
	Iterator iObz = observations.entrySet().iterator();
	while (iObz.hasNext()) {
	    Map.Entry obs = (Map.Entry)iObz.next();
	    Node node       = (Node)obs.getKey();
	    ArrayList obsRecs = (ArrayList)obs.getValue();
	    Iterator iObsRecs = obsRecs.iterator();
	    while (iObsRecs.hasNext()) {
		TagObservationRec rec = (TagObservationRec)iObsRecs.next();
		Date time = rec.time;
		if (isCurrent(time)) {
		    count++;
		    x += node.getGroundX();
		} else
		    iObsRecs.remove();
	    }
	}
	if (count > 0)
	    return x / count;
	else
	    return 0.0;
    }
	
    /**
     * Returns the y coordinate of this node.
     */
    public double getY() {
	if(useStrength)
	{
	    // getX calls calcStrengthLoc for us.
	    return strengthDerivedY;
	}

	int    count  = 0;
	double y      = 0.0;
	Iterator iObz = observations.entrySet().iterator();
	while (iObz.hasNext()) {
	    Map.Entry obs = (Map.Entry)iObz.next();
	    Node node = (Node)obs.getKey();
	    ArrayList obsRecs = (ArrayList)obs.getValue();
	    Iterator iObsRecs = obsRecs.iterator();
	    while (iObsRecs.hasNext()) {
		TagObservationRec rec = (TagObservationRec)iObsRecs.next();
		Date time = rec.time;
		if (isCurrent(time)) {
		    count++;
		    y += node.getGroundY();
		} else
		    iObsRecs.remove();
	    }
	}
	if (count > 0)
	    return y / count;
	else
	    return 0.0;
    }


    private double mapStrengthToDist(int strength)
    {
	if(strength < 30)
	    return 0.3;
	if(strength < 60)
	    return 0.5;
	if(strength < 90)
	    return 0.8;
	if(strength < 120)
	    return 1.0;
	if(strength < 150)
	    return 1.2;
	if(strength < 200)
	    return 1.4;
	if(strength < 250)
	    return 1.5;
	if(strength < 300)
	    return 1.5;
	return 1.5;
    }

    public void calcStrengthLoc() {
	// First, find out our distances to various jerks.
	HashMap distances = new HashMap();

	Iterator iObz = observations.entrySet().iterator();
	while (iObz.hasNext()) {
	    Map.Entry obs = (Map.Entry)iObz.next();
	    Node node = (Node)obs.getKey();
	    ArrayList obsRecs = (ArrayList)obs.getValue();
	    Iterator iObsRecs = obsRecs.iterator();

	    double dist = 1.0;
	    int count = 0;

	    while (iObsRecs.hasNext()) {
		TagObservationRec rec = (TagObservationRec)iObsRecs.next();
		Date time = rec.time;
		if (isCurrent(time)) {
		    count++;
		    dist = dist + mapStrengthToDist(rec.strength);
		} else
		    iObsRecs.remove();
	    }

	    if(count > 0)
	    {
		dist /= count;
		distances.put(node, new Double(dist));
	    }

	}

	double dedx = 0;
	double dedy = 0;
	double rn = 0;
	double xn = 0;
	double yn = 0;
	double xb = strengthDerivedX;
	double yb = strengthDerivedY;
	double alpha = 0.01;

	for(int i=0;i<1000;i++) {

	    Iterator iDists = distances.entrySet().iterator();
	    while(iDists.hasNext()) {
		Map.Entry entry = (Map.Entry)iDists.next();
		Node node = (Node)entry.getKey();
		double dist = ((Double)entry.getValue()).doubleValue();

		xn = node.getX();
		yn = node.getY();

		rn = dist;

		dedx += -4.0*((xn-xb)*(xn-xb) + (yn-yb)*(yn-yb) - rn*rn)*(xn-xb);
		dedy += -4.0*((xn-xb)*(xn-xb) + (yn-yb)*(yn-yb) - rn*rn)*(yn-yb);
	    }

	    xb += -alpha*dedx;
	    yb += -alpha*dedy;
	    dedx = 0;
	    dedy = 0;
	}

	strengthDerivedX = xb;
	strengthDerivedY = xb;
    }
	
	
    /**
     * Returns a description of this node.
     */
    public String toString() {
	return "Tag '" + nodeID + "' (" + getX() + "," + getY() + ")";
    }
}
