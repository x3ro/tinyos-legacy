package net.tinyos.tinydb;
import java.util.*;

/** QueryResult accepts a query result in the form of an array of
    bytes read off the network (and a query) and parses the results
    and provides a number of utility routines to read the
    values back.

    @author Sam Madden (madden@cs.berkeley.edu)
*/
public class QueryResult {

    //we have to keep track of offsets into aggregate data by
    //hand, since we don't have a message class to represent them
    static final int GROUP_B1 = 1;  //start of aggregate data
    static final int GROUP_B2 = 0;
    static final int EXPR_IDX_B = 2; 
    static final int VALUE_B1 = 4;
    static final int VALUE_B2 = 3;
    static final int COUNT_B1 = 6;
    static final int COUNT_B2 = 5;

    /** Constructor -- parse the specified result assuming it
	is a result for query q 
    */
    public QueryResult(TinyDBQuery q, QueryResultMsg m) {
	short curByte = 0;
	FieldRecord fr;

	this.query = q;
	id = m.get_hdr_senderid();
	parent = m.get_hdr_parentid();
	epoch = m.get_qr_epoch();
	qid = m.get_qr_qid();
	isAgg = q.isAgg();
	fieldValues = new Vector();

	value = new int[q.numExprs()];
	count = new int[q.numExprs()];
	valid = new boolean[q.numExprs()];
		   
	try {
	    if (isAgg) {  //aggregate query 
		int eidx = (int)m.getElement_qr_d_data(EXPR_IDX_B);
		group = unsign(m.getElement_qr_d_data(GROUP_B1)) << 8;
		group += unsign(m.getElement_qr_d_data(GROUP_B2));
		/* This result corresponds to just one of (possibly several) 
		   aggregate expressions in the query.
		   Note that we allocate an array with space for every expression, not just
		   the aggregates.  Valid sez which we've actually merged (see mergeQueryResult) 
		*/
		value[eidx] = unsign(m.getElement_qr_d_data(VALUE_B2));
		value[eidx] += (unsign(m.getElement_qr_d_data(VALUE_B1)) << 8);
		
		count[eidx] = m.getElement_qr_d_data(COUNT_B1) << 8;
		count[eidx] += m.getElement_qr_d_data(COUNT_B2);
		
		valid[eidx] = true;
	    } else {  //non aggregate query
		long nullFields = m.get_qr_d_t_notNull();
		for (int i = 0; i < m.get_qr_d_t_numFields(); i++) {
		    if ((nullFields & (1 << i)) > 0) {
			
			fr = decodeField(i, m, curByte);
			Vector fieldV = new Vector();
			fieldV.addElement(fr.name);
			fieldV.addElement(fr.field.toString());
			fieldValues.addElement(fieldV);
			if (TinyDBMain.debug) System.out.print(fieldV.elementAt(0) + " = " + fieldV.elementAt(1) + ", ");
			curByte += fr.size;
			
		    }
		}
	    }
	    if (TinyDBMain.debug) System.out.println(" ");	
	} catch (ArrayIndexOutOfBoundsException e) {
	    System.out.println("Bad tuple.");
	}
    }


    /** Generate a data message that a local node can use to send out
	a query result.
	Message has specified query id, network size information
	message index, and epoch number
    */
    static public QueryResultMsg generateDataMessage(byte queryNo, char msgIdx, short epochNo, byte nwSize, byte timeRem) {
	QueryResultMsg msg = new QueryResultMsg(TinyDBMain.DATA_SIZE);
	
	msg.set_qr_qid(queryNo);
	//msg.setHdr_xmitSlots((char)nwSize);
	msg.set_hdr_timeRemaining(timeRem);
	msg.set_qr_epoch((char)epochNo);
	msg.set_hdr_idx((short)msgIdx);

	return msg;
    }

    /** Given a query result message, return the query id it belongs to */
    static public byte queryId(QueryResultMsg m) {
	return (byte)m.get_qr_qid();
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

	public static int numFields(QueryResultMsg m)
	{
	    return m.get_qr_d_t_numFields();
	}

    /** Merge the newResult with this query result.
	Merging does the following:
	
	- Combine information from several aggregate results that correspond the evaluations of
	  different aggregate expressions over the tuple.

	- Merge together aggregate values from the same aggregate expression reported to the root
	  by different sensors.

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
    private FieldRecord decodeField(int idx, QueryResultMsg m, short offset) throws ArrayIndexOutOfBoundsException {
	TinyDBQuery q = query;

	QueryField f = q.getField(idx);
	FieldRecord fr = new FieldRecord();

	fr.name = f.getName();
	switch (f.getType()) {
	case QueryField.INTONE:
	    fr.size = 1;
	    fr.field = new Byte((byte)m.getElement_qr_d_t_fields(offset));
	    break;
	case QueryField.INTTWO:
	    int i = unsign(m.getElement_qr_d_t_fields(offset)) +  (unsign(m.getElement_qr_d_t_fields(offset + 1)) << 8);
	    fr.size = 2;
	    fr.field = new Integer(i);
	    break;
	case QueryField.INTFOUR:
	    long l = unsign(m.getElement_qr_d_t_fields(offset)) + (unsign(m.getElement_qr_d_t_fields(offset + 1)) << 8) + 
		(unsign(m.getElement_qr_d_t_fields(offset + 2)) << 16) + (unsign(m.getElement_qr_d_t_fields(offset + 3)) << 24);
	    fr.size = 4;
	    fr.field = new Long(l);
	    break;
	case QueryField.STRING:
	    int len = 0;
	    byte[] data = new byte[m.totalSize_qr_d_data()];
	    
	    while (m.getElement_qr_d_t_fields(offset + len) != 0) {
		data[len] = (byte)m.getElement_qr_d_t_fields(offset + len);
		len++;
	    }
	
	    fr.field = new String(data,0,len);
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


    public static int unsign(int b) {
	if (b < 0) return (int)((b & 0x7f)) + 128;
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
