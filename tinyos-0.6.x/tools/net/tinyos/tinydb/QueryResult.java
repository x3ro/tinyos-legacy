package net.tinyos.tinydb;
import java.util.*;

/** QueryResult accepts a query result in the form of an array of
    bytes read off the network (and a query) and parses the results
    and provides a number of utility routines to read the
    values back.

    @author Sam Madden (madden@cs.berkeley.edu)
*/
public class QueryResult {

    //ugly byte offsets in network message
    //wouldn't recommend messing with these unless you're sure you know
    //what you're doing
    static final int SENDERID_B1 = 1;
    static final int SENDERID_B2 = 0;
    static final int PARENTID_B1 = 3;
    static final int PARENTID_B2 = 2;
    static final int LEVEL_B = 4;
    static final int NW_SIZE_B = 5;
    static final int TIME_REMAINING_B = 6;
    static final int MSG_IDX_B1 = 8;
    static final int MSG_IDX_B2 = 7;

    static final int QID_B = 9;
    static final int IDX_B = 10;
    static final int EPOCH_B1 = 12;
    static final int EPOCH_B2 = 11;
    static final int TUPLE_QID_B = 13; //start of tuple
    static final int NUMFIELDS_B = 14;
    static final int NULLBITS_B1 = 18;
    static final int NULLBITS_B2 = 17;
    static final int NULLBITS_B3 = 16;
    static final int NULLBITS_B4 = 15;
    static final int FIELDS_B1 = 19;

    static final int GROUP_B1 = 14;  //start of aggregate data
    static final int GROUP_B2 = 13;
    static final int EMPTY_B = 15;
    static final int EXPR_IDX_B = 15; //EMPTY_B and EXPR_IDX_B share same byte!
    static final int VALUE_B1 = 17;
    static final int VALUE_B2 = 16;
    static final int COUNT_B1 = 19;
    static final int COUNT_B2 = 18;

    /** Constructor -- parse the specified result assuming it
	is a result for query q 
    */
    public QueryResult(TinyDBQuery q, byte result[]) {
	short curByte = FIELDS_B1;
	FieldRecord fr;

	this.query = q;

	id = result[SENDERID_B2] + (result[SENDERID_B1] << 8);
	parent = result[PARENTID_B2] + (result[PARENTID_B1] << 8);
	epoch = makeInt(result[EPOCH_B2], result[EPOCH_B1]);
	qid = result[QID_B];
	isAgg = q.isAgg();
	fieldValues = new Vector();

	System.out.println("NW SIZE = " + result[NW_SIZE_B]);

	value = new int[q.numExprs()];
	count = new int[q.numExprs()];
	valid = new boolean[q.numExprs()];
		   
	if (isAgg) {  //aggregate query 
	    int eidx = (int)result[EXPR_IDX_B];

	    group = unsign(result[GROUP_B1]) << 8;
	    group += unsign(result[GROUP_B2]);
	    /* This result corresponds to just one of (possibly several) 
	       aggregate expressions in the query.
	       Note that we allocate an array with space for every expression, not just
	       the aggregates.  Valid sez which we've actually merged (see mergeQueryResult) 
	    */
	    value[eidx] = unsign(result[VALUE_B2]);
	    value[eidx] += (unsign(result[VALUE_B1]) << 8);

	    count[eidx] = result[COUNT_B1] << 8;
	    count[eidx] += result[COUNT_B2];
      
	    valid[eidx] = true;
	} else {  //non aggregate query
	    long nullFields = 0;

	    nullFields += result[NULLBITS_B1] << 24;
	    nullFields += result[NULLBITS_B2] << 16;
	    nullFields += result[NULLBITS_B3] << 8;
	    nullFields += result[NULLBITS_B4];

		System.out.print("TUPLE: ");
	    for (int i = 0; i < result[NUMFIELDS_B]; i++) {
		if ((nullFields & (1 << i)) > 0) {
		    try {
			fr = decodeField(i, result, curByte);
			Vector fieldV = new Vector();
			fieldV.addElement(fr.name);
			fieldV.addElement(fr.field.toString());
			fieldValues.addElement(fieldV);
			System.out.print(fieldV.elementAt(0) + " = " + fieldV.elementAt(1) + ", ");
			curByte += fr.size;
		    } catch (ArrayIndexOutOfBoundsException e) {
			System.out.println("Bad tuple.");
		    }
		}
	    }
		System.out.println(" ");
	}
    }


    /** Generate a data message that a local node can use to send out
	a query result.
	Message has specified query id, network size information
	message index, and epoch number
    */
    static public byte[] generateDataMessage(byte queryNo, short msgIdx, short epochNo, byte nwSize, byte timeRem) {
	byte msg[] = new byte[30];
	
	msg[QID_B] = queryNo;

	//	msg[NW_SIZE_B] = (byte)((nwSize & 0xFF00) >> 8);
	msg[NW_SIZE_B] = nwSize;
	msg[TIME_REMAINING_B] = timeRem;
	msg[EPOCH_B1] = (byte)((epochNo & 0xFF00) >> 8);
	msg[EPOCH_B2] = (byte)(epochNo & 0x00FF);

	msg[MSG_IDX_B1] = (byte)((msgIdx & 0xFF00) >> 8);
	msg[MSG_IDX_B2] = (byte)(msgIdx & 0x00FF);

	return msg;
    }

    /** Given a query result message, return the query id it belongs to */
    static public byte queryId(byte result[]) {
	return result[QID_B];
    }

    /** Return the epoch of this result */
    int epochNo() {
	return epoch;
    }

    /** Return the query id of this result */
    int qid() {
	return qid;
    }

    /** Return the group number of this result */
    int group() {
	return group;
    }

	public static int numFields(byte result[])
	{
		return result[NUMFIELDS_B];
	}

    /** Merge the newResult with this query result.
	Merging should perform several functions:
	
	- Combine information from several aggregate results that correspond the evaluations of
	  different aggregate expressions over the tuple.

	- Merge together aggregate values from the same aggregate expression reported to the root
	  by different sensors.

      Current only does the former.

    */
    void mergeQueryResult(QueryResult newResult) {
	if (newResult.group == group) {
	    for (int i = 0; i < query.numExprs(); i++) {
		if (newResult.valid[i] && !valid[i]) { //new result has an expr we dont
		    valid[i] = true;
		    count[i] = newResult.count[i];
		    value[i] = newResult.value[i];
		} else if (newResult.valid[i] && valid[i]) {
		    //both have the same agg
		    AggOp agg = ((AggExpr)query.getExpr(i)).getAgg();
		    Vector resultv = agg.merge(value[i], count[i], newResult.value[i], newResult.count[i]);
		    value[i] = ((Integer)resultv.elementAt(0)).intValue();
		    count[i] = ((Integer)resultv.elementAt(1)).intValue();
		}
	    }
	}
    }
  

    /* Return a FieldRecord representing the value of the idxth column of the query, which is assumed
       to begin at offset bytes into result.
    */
    private FieldRecord decodeField(int idx, byte result[], short offset) throws ArrayIndexOutOfBoundsException {
	TinyDBQuery q = query;

	QueryField f = q.getField(idx);
	FieldRecord fr = new FieldRecord();
      
	fr.name = f.getName();
	switch (f.getType()) {
	case QueryField.INTONE:
	    fr.size = 1;
	    fr.field = new Byte(result[offset]);
	    break;
	case QueryField.INTTWO:
	    int i = unsign(result[offset]) + (unsign(result[offset + 1]) << 8);
	    fr.size = 2;
	    fr.field = new Integer(i);
	    break;
	case QueryField.INTFOUR:
	    long l = unsign(result[offset]) + (unsign(result[offset + 1]) << 8) + 
		(unsign(result[offset + 2]) << 16) + (unsign(result[offset + 3]) << 24);
	    fr.size = 4;
	    fr.field = new Long(l);
	    break;
	case QueryField.STRING:
	    int len = 0;
	    while (result[offset + len] != 0) len++;
	    fr.field = new String(result,offset,len);
	    break;
	default:
	    System.out.println("UNSUPPORTED TYPE: " + f.getType());
	}
	return fr;

    }
  
    /** Return a vector of strings corresponding to the result tuple for this
	query result.  

	Always includes epoch number as the first field.
	
	The names of the result fields can be obtained from TinyDBQuery.getColumnHeadings

    */
    public Vector resultVector() {
	Vector v = new Vector();
	int loc = 0;

	v.addElement(new Integer(epoch).toString());

	if (isAgg) {
	    if (query.grouped()) { 
	      v.addElement(new Integer(group).toString());
	      loc++;
	    }
	    for (int i = 0; i < query.numExprs(); i++) {
		if (query.getExpr(i).isAgg()) loc++;
		if (valid[i]) {
		    String aggStr = ((AggExpr)query.getExpr(i)).getAgg().getString(value[i], count[i]);

		    if (v.size() <= loc) v.setSize(loc + 1);
		    v.setElementAt(aggStr, loc);
		    
		}
	    }
	} else {
	    for (int i = 0 ; i < fieldValues.size(); i++) {
		Vector vals = (Vector)fieldValues.elementAt(i);
		v.addElement(vals.elementAt(1));
	    }
	}
	return v;
	
    }

    /** Convert this query result to an (ugly looking) string representation */
    public String toString() {
	String s = new String();
	if (isAgg) {
	    for (int i = 0; i < query.numExprs(); i++) {
		if (valid[i])
		    s += "AGGREGATE VALUE: id = " + id + ", qid = " + qid + ", epoch = " + epoch + ", expr = " + i + ", group = " + group + ", value = " + value[i] + ", count = " + count[i];
	    }
	} else {

	    s += "TUPLE: qid = " + qid + ", epoch = " + epoch + ", ";
	    for (int i = 0; i < fieldValues.size(); i++) {
		Vector v = (Vector)fieldValues.elementAt(i);
		s += (String)v.elementAt(0);
		s += " = ";
		s += (String)v.elementAt(1);
		s += ", ";
	    }
	}
	return s;
    }

    /* Return the id of the recipient */
    public int getRecipient() {
	return parent;
    }
  
    /* Return the id of the sender */
    public int getSender() {
	return id;
    }


    /* Utility routine to combine two bytes into an integer, handling 
       little endian - big endian issues.
       @param hibyte is the least significant bits of the integer
       @param lowbyte is the most significant bits
    */
    private int makeInt(byte lowbyte, byte hibyte)
    {
	return unsign(lowbyte) + (unsign(hibyte) << 8);
    }
    
    /* Given a byte, convert it to an unsigned int in the range 0 - 255*/
    public static int unsign(byte b) {
	if (b < 0) return (int)(b & 0x7f) + 128;
	else return (int)b;
    }

    private boolean isAgg;  //is this an aggregate query
    private Vector fieldValues; //vector of field name / value string vectors (if a non-aggregata query)

    //aggregate values
    private int group; //the group this aggregate result belongs to (or 0 if not grouped)
    private int[] value; //an array of aggregate values (one per expr in the query)
    private int[] count; //an array of aggregate counts (only if an average query)
    private boolean[] valid; /* Array of booleans indicating which exprs are
				valid aggregate expressions that are included in this result */


    private int id;  //sender id
    private int parent; //parent id
    private int epoch; //epoch number
    private int qid; //query id


    private TinyDBQuery query;
}

//internal class used to represent a tuple field
class FieldRecord {
    String name;
    int size;  // in bytes
    Object field;

}
