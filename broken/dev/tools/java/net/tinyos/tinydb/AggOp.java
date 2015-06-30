package net.tinyos.tinydb;

import java.util.*;

public class AggOp {
    public static final byte AGG_SUM = 0;
    public static final byte AGG_MIN = 1;
    public static final byte AGG_MAX = 2;
    public static final byte AGG_COUNT = 3;
    public static final byte AGG_AVERAGE = 4;
    public static final byte AGG_NOOP = 6;
    public static final byte AGG_EXPAVG = 7;
    public static final byte AGG_WINAVG = 8;
    public static final byte AGG_WINSUM = 9;
    public static final byte AGG_WINMIN = 10;
    public static final byte AGG_WINMAX = 11;
    public static final byte AGG_WINCNT = 12;


    /** Constructor for normal aggregates */
    public AggOp(byte type) throws NoSuchElementException  {
	if (type < AGG_SUM || type > AGG_NOOP)
	    throw new NoSuchElementException();
	this.type = type;
	this.aggConst = 0;
    }

    /** Constructor for temporal aggregates */
    public AggOp(byte type, short c) throws NoSuchElementException {
	if (type < AGG_EXPAVG || type > AGG_WINCNT)
	    throw new NoSuchElementException();
	this.type = type;
	this.aggConst = c;

    }

    public boolean isTemporal() {
	if (type >= AGG_EXPAVG && type <= AGG_WINCNT) return true;
	return false;
    }
    

    public byte toByte() {
	return type;
    }

    public String toString() {
	switch (type) {
	case AGG_SUM:
	    return "SUM";
	case AGG_MIN:
	    return "MIN";
	case AGG_MAX:
	    return "MAX";
	case AGG_COUNT:
	    return "COUNT";
	case AGG_AVERAGE:
	    return "AVG";
	case AGG_EXPAVG:
	    return "EXP_AVG";
	case AGG_WINAVG:
	    return "WIN_AVG";
	case AGG_WINSUM:
	    return "WIN_SUM";
	case AGG_WINCNT:
	    return "WIN_CNT";
	case AGG_WINMIN:
	    return "WIN_MIN";
	case AGG_WINMAX:
	    return "WIN_MAX";

        
	}
	return "";
    }

    public String getString(int value, int count) {
	switch (type) {
	case AGG_COUNT:
	case AGG_SUM:
	case AGG_WINSUM:
	case AGG_WINCNT:
	case AGG_EXPAVG:
	    return new Integer(value).toString();
	case AGG_MIN:
	case AGG_MAX:
	case AGG_WINMAX:
	case AGG_WINMIN:
	    return new Integer(value).toString() + " (" + new Integer(count).toString() + ")";
	case AGG_AVERAGE:
	case AGG_WINAVG:
	    return new Integer((int)((float)value / (float)count)).toString();
	}
	
	return "";
    }

    public Vector merge(int value1, int count1, int value2, int count2) {
	int count = 0;
	int value = 0;

	switch (type) {
	case AGG_AVERAGE:
	case AGG_WINAVG:
	    count = count1 + count2;
	case AGG_SUM:
	case AGG_EXPAVG:
	case AGG_COUNT:
	case AGG_WINSUM:
	case AGG_WINCNT:
	    value = value1 + value2;
	    break;
	case AGG_WINMIN:
	case AGG_MIN:
	    if (value1 < value2) {
		value = value1;
		count = count1;
	    }
	    else {
		value = value2;
		count = count2;
	    }
	    break;
	case AGG_WINMAX:
	case AGG_MAX:	    
	    if (value1 > value2) {
		value = value1;
		count = count1;
	    } else {
		value = value2;
		count = count2;
	    }
	    break;
	}
	
	Vector v = new Vector();
	v.addElement(new Integer(value));
	v.addElement(new Integer(count));

	return v;
    }

    public short getConst() {
	return aggConst;
    }
    
    private byte type;
    private short aggConst;
}
