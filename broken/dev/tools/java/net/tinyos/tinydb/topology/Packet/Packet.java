package net.tinyos.tinydb.topology.Packet;

import java.util.*;
import net.tinyos.tinydb.topology.util.*;
import net.tinyos.tinydb.topology.*;
import net.tinyos.tinydb.*;

	          //This class will hold all information about the packets
	          //as the packets change between versions, the static variables in this class
	          //can be changed to reflect changes, thereby keeping the packet specifics
	          //contained in this class and increasing modularity
public class Packet
{
	public static final int NODEID_IDX	=	1;
	public static final int PARENT_IDX	=	2;
	public static final int LIGHT_IDX	=	3;
	public static final int TEMP_IDX	=	4;
	public static final int VOLTAGE_IDX	=	5;
	private static int currentValueIdx = LIGHT_IDX;
	private Vector resultVector;
	public Packet(QueryResult qr)
	{
		resultVector = qr.resultVector();
	} 
	public Integer getNodeId()
	{
		return new Integer((String)resultVector.elementAt(NODEID_IDX));
	}
	public Integer getParent()
	{
		return new Integer((String)resultVector.elementAt(PARENT_IDX));
	}
	public int getValue()
	{
		return Integer.parseInt((String)resultVector.elementAt(currentValueIdx));
	}
	public static void setCurrentValueIdx(int idx)
	{
		currentValueIdx = idx;
	}
	// XXX preserved for backward compatibility to some Surge code
	public Vector CreateRoutePathArray()
	{
		Vector v = new Vector(2);
		v.addElement(getNodeId());
		v.addElement(getParent());
		return v;
	}
}
