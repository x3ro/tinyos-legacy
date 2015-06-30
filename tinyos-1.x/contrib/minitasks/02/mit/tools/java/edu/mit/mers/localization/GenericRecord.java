package	edu.mit.mers.localization;

import java.util.*;
import java.lang.*;

public abstract class GenericRecord {
    protected HashMap mapping;
    protected LinkedList keyOrder;

    protected static void error(String reason) {System.out.println(reason);}

    public abstract String recordType();

    protected int getInt(String name) {
	try {
	    Integer x = new Integer((String)(mapping.get(name)));
	    return x.intValue();
	}
	catch (Exception e) {
	    error("Can't find value with name: " + name);
	    return 0;
	}
    }

    protected void setInt(String name, int val) {
	Integer x = new Integer(val);
	mapping.put(name, x);
    }
	
    protected double getDouble(String name) {
	try {
	    Double x = new Double((String)(mapping.get(name)));
	    return x.doubleValue();
	}
	catch (Exception e) {
	    error("Can't find value with name: " + name);
	    return 0.0;
	}
    }

    protected void setDouble(String name, double val) {
	Double x = new Double(val);
	mapping.put(name, x);
    }

    protected String getString(String name) {
	try {
	    return (String)(mapping.get(name));
	}
	catch (Exception e) {
	    error("Can't find value with name: " + name);
	    return "";
	}
    }

    protected void setString(String name, String val) {
	mapping.put(name, val);
    }

    public GenericRecord() {
	mapping = new HashMap(8);
	keyOrder = new LinkedList();
    }

    public GenericRecord(String line, StringTokenizer lineSplit) {
	mapping = new HashMap(8);
	keyOrder = new LinkedList();
	while (lineSplit.hasMoreTokens()) {
	    StringTokenizer pairSplit = new StringTokenizer(lineSplit.nextToken(), "=", false);
	    /*
	    if (pairSplit.countTokens() != 2) {
		error("Can't read pair: " + line);
	    }
	    */
	    String name = (String)pairSplit.nextToken();
	    Object value;
	    if(pairSplit.hasMoreTokens())
		value = pairSplit.nextToken();
	    else
		value = "";
	    mapping.put(name, value);
	    keyOrder.add(name);
	}
    }

    public String toString() {
	StringBuffer result = new StringBuffer(recordType());
	Iterator it = keyOrder.iterator();
	if (it.hasNext() == false) {return "";}
	while (it.hasNext()) {
	    result.append(" ");
	    String name = (String)(it.next());
	    Object value = mapping.get(name);
	    result.append(name);
	    result.append("=");
	    result.append(value);
	}
	return new String(result);
    }

    public static GenericRecord readRecord(String line) {
	StringTokenizer splitter = new StringTokenizer(line, " \t", false);
	if (splitter.countTokens() == 0) {
	    return null;
	}
	String recType = splitter.nextToken();
	GenericRecord result;
	if (recType.equals("mote")) {
	    result = new MoteRecord(line, splitter);
	} else if (recType.equals("motefield")) {
	    result = new MoteFieldRecord(line, splitter);
	} else if (recType.equals("tag")) {
	    result = new TagRecord(line, splitter);
	} else {
	    result = null;
	}
	return result;
    }
}
	    
