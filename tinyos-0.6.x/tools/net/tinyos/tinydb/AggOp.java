package net.tinyos.tinydb;

import java.util.*;

public class AggOp {
    public static final byte AGG_SUM = 0;
    public static final byte AGG_MIN = 1;
    public static final byte AGG_MAX = 2;
    public static final byte AGG_COUNT = 3;
    public static final byte AGG_AVERAGE = 4;
    
    public AggOp(byte type) throws NoSuchElementException  {
	if (type < AGG_SUM || type > AGG_AVERAGE)
	    throw new NoSuchElementException();
	this.type = type;
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
	    return "AVERAGE";

	}
	return "";
    }

    public String getString(int value, int count) {
	switch (type) {
	case AGG_COUNT:
	case AGG_SUM:
	    return new Integer(value).toString();
	case AGG_MIN:
	case AGG_MAX:
	    return new Integer(value).toString() + " (" + new Integer(count).toString() + ")";
	case AGG_AVERAGE:
	    return new Integer((int)((float)value / (float)count)).toString();
	}
	return "";
    }

    public Vector merge(int value1, int count1, int value2, int count2) {
	int count = 0;
	int value = 0;

	switch (type) {
	case AGG_AVERAGE:
	    count = count1 + count2;
	case AGG_SUM:
	case AGG_COUNT:
	    value = value1 + value2;
	    break;
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

    private byte type;
}
