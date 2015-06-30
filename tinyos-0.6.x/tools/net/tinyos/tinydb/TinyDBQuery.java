package net.tinyos.tinydb;

import java.util.*;

/** TinyDBQuery is a Java data structure representing a query running (or to be run)
    on a set of motes.
    
    Queries consist of:
    - a list of fields to select
    - a list of expressions over those fields, where an expression is
      - an filter that rejects some readings
      - an aggregate that combines local readings with readings from
        neighbors.

   In addition to allowing a query to be built, this class includes methods
   to generate radio messages so the query can be distributed over the network
   or to abort the query
   
*/
public class TinyDBQuery {
    
    /** Constructor
	@param qid The id of the query
	@param epochDur The rate at which results from the query should be generated 
    */
    public TinyDBQuery(byte qid, short epochDur) {
	fields = new ArrayList();
	exprs = new ArrayList();
	this.qid = qid;
	this.epochDur = epochDur;
    }

    /** Return the id of the query */
    public int getId() {
	return qid;
    }

    /** Add the specified field to the query */
    public void addField(QueryField f) {
	fields.add(f);
    }

    /** Add the specified expression to the query */
    public void addExpr(QueryExpr e) {
	exprs.add(e);
	if (e instanceof AggExpr) {
	    AggExpr ae = (AggExpr)e;
	    if (ae.getGroupField() != AggExpr.NO_GROUPING) {
		isGrouped = true;
		groupExpr = ae;
	    }
	}
	    
    }

    /** Return true if the query is grouped (e.g. contains one or more aggregates with a 
	group by expression)
    */
    public boolean grouped() {
	return isGrouped;
    }
    
    /** Return the name of the group by column */
    public String groupColName() {
	if (isGrouped) {
	    String fname = getField(groupExpr.getGroupField()).getName();
	    if (groupExpr.getAttenuation() == 0) {
		return fname;
	    } else {
		return "(" + fname + ">>" + (int)groupExpr.getAttenuation() + ")";
	    }

	} else return null;
    }

    /** Return the text of the SQL for this query as set by setSQL (Note that TinyDBQuery does not 
	include an interface for generating SQL from an arbitrary query.)
    */
    public String getSQL() {
	return sql;
    }
  
    /** Set the SQL string associated with this query.  Note that this string doesn't not neccessarily have
	any relationship to the fields / expressions in this object 
    */
    public void setSQL(String s) {
	sql = s;
    }
    
    /** Return true if this query contains one or more aggregate expressions */
    public boolean isAgg() {
	Iterator i = exprs.iterator();
	while (i.hasNext()) {
	    QueryExpr e = (QueryExpr)i.next();
	    if (e.isAgg()) return true;
	}
	return false;
    }

    /* Return the number of expressions in this query */
    public int numExprs() {
	return exprs.size();
    }
    
    /* Return the ith expression in this query
       @throws ArrayIndexOutOfBoundsException if i < 0 or i >= numExprs() 
    */
    public QueryExpr getExpr(int i) throws ArrayIndexOutOfBoundsException {
	return (QueryExpr)exprs.get(i);
    }

    /** Return the number of fields in this query */
    public int numFields() {
	return fields.size();
    }
    
    /** Return the ith field in this query
	@throws ArrayIndexOutOfBoundsException if i < 0 or i >= numFields()
    */
    public QueryField getField(int i) throws ArrayIndexOutOfBoundsException {
      return (QueryField)fields.get(i);
    }

    /** Return a byte array representing a radio message that will tell
	motes to abort this query */
    public byte[] abortMessage() {
	byte msg[] = new byte[30];
	initCommonFields(msg);
	msg[MSG_TYPE_B] = DEL_MSG;
	
	return msg;
    }

    /* Return a vector of strings containing the
       headings for the columns in this query
    */
    public Vector getColumnHeadings() {
	Vector cols = new Vector();
	boolean addedGroupCol = false;

	cols.addElement("Epoch");

	if (isAgg()) {
	    //it's an agg; the columns that are returned
	    //are the group and the aggregate value
	    for (int i = 0; i < numExprs(); i++) {
		QueryExpr e = getExpr(i);

		if (e.isAgg()) {
		    AggExpr ae = (AggExpr)e;
		    if (ae.getGroupField() != -1 && !addedGroupCol) {
			cols.addElement(groupColName());
			addedGroupCol = true;
		    }
		    cols.addElement(ae.getAgg().toString() + "(" + getField(ae.getField()).getName() + ")" );

		}
	    }
	    
	} else {
	    //its a selection; the columns that are returned
	    //are the exprs
	    for (int i =0; i < numFields(); i++) {
		QueryField qf = getField(i);
		cols.addElement(qf.getName());
	    }

	}

	return cols;
    }

    
    /** Return an Iterator over messages to be sent
	to start sensors running this 
	query 
    */
    public Iterator messageIterator() {
	ArrayList messages = new ArrayList();
	byte msg[];

	
	//first, send all the fields
	for (int i = 0; i < fields.size(); i++) {
	    QueryField f = (QueryField)fields.get(i);

	    msg = new byte[30];
	    initCommonFields(msg);
	    msg[IS_EXPR_B] = 0;
	    msg[IDX_B] = (byte)i;
	    f.getName().getBytes(0,f.getName().length(), msg, NAME_B1);
	    msg[f.getName().length() + NAME_B1] = 0;
	    System.out.println("msg: ");
	    for (int j = 0 ; j < 30; j++)
		System.out.print(msg[j] + ",");
	    System.out.println("");
	    messages.add(msg);
	}

	//then all the exprs
	for (int i = 0; i < exprs.size(); i++) {
	    QueryExpr e = (QueryExpr)exprs.get(i);
	    
	    msg = new byte[30];
	    initCommonFields(msg);
	    msg[IS_EXPR_B] = 1;
	    msg[IDX_B] = (byte)i;
	    msg[IS_AGG_B] = (byte)(e.isAgg()?1:0);
	    msg[FIELD_B1] = (byte)((e.getField() & 0xFF00) >> 8);
	    msg[FIELD_B2] = (byte)(e.getField() & 0x00FF);
	    if (e.isAgg()) {
		AggExpr a = (AggExpr)e;
		msg[GROUP_B1] = (byte)((a.getGroupField() & 0xFF00) >> 8);
		msg[GROUP_B2] = (byte)(a.getGroupField() & 0x00FF);
		msg[AGG_OP_B] = (byte)(a.getAggOpCode());
		msg[ATTENUATION_B] = (byte)(a.getAttenuation());
	    } else {
		SelExpr s = (SelExpr)e;
		msg[OP_B] = (byte)s.getSelOpCode();
		msg[VALUE_B1] = (byte)((s.getValue() & 0xFF00) >> 8);
		msg[VALUE_B2] = (byte)(s.getValue() & 0x00FF);
	    }
	    System.out.println("msg: ");
	    for (int j = 0 ; j < 30; j++)
		System.out.print(msg[j] + ",");
	    System.out.println("");
	    messages.add(msg);
	}
	return messages.iterator();
    }

    // set up common fields in radio messages
    private void initCommonFields(byte m[]) {
	m[SENDER_ID_B1] = 0;
	m[SENDER_ID_B2] = 0;
	m[PARENT_ID_B1] = 0;
	m[PARENT_ID_B2] = 0;
	m[LEVEL_B] = 0;
	m[TIME_B1] = 0;
	m[TIME_B2] = 0;
	m[MSG_IDX_B1] = 0;
	m[MSG_IDX_B2] =0;
	m[MSG_TYPE_B] = ADD_MSG;
	m[QUERY_B] = qid;
	m[NUM_FIELDS_B] = (byte)fields.size();
	m[NUM_EXPRS_B] = (byte)exprs.size();
	m[EPOCH_DUR_B1] = (byte)((epochDur & 0xFF00) >> 8);
	m[EPOCH_DUR_B2] = (byte)((epochDur & 0x00FF));
    }
    
    public byte qid;
    public short epochDur;


    private boolean isGrouped = false;
    private AggExpr groupExpr = null;

    private ArrayList fields;
    private ArrayList exprs;

  private String sql = "";
    
    static final byte QUERY_MSG_ID = 101;
    static final byte DATA_MSG_ID = 100;

    static final byte FIELD = 0;
    static final byte EXPR = 1;

    static final byte ADD_MSG = 0;
    static final byte DEL_MSG = 1;
    static final byte MODIFY_MSG = 2;


    /* Query messages are :
       2 bytes sender id
       2 bytes parent id
       1 byte level
       2 bytes sendtime
       2 bytes msg idx
       1 byte message type (e.g. add, del)
       1 byte query id
       1 byte num fields
       1 byte num exprs
       2 bytes epoch duration
       1 byte field / expr 
       1 byte index (17)
       
       if field:
       
       8 bytes field name (25)

       if expr:
       
       1 byte is aggregate?
       1 byte success (unused on entry)
       1 byte expression index (unneeded on entry) (20)
       if agg:
       
       2 bytes field
       2 bytes grouping
       1 byte agg operator (24)
       
       if not agg:

       2 bytes field 
       1 byte operator
       2 bytes value  (24)

       -- operator state handle (unneeded)
    */
  static final int SENDER_ID_B1 = 1;
  static final int SENDER_ID_B2 = 0;
  static final int PARENT_ID_B1 = 3;
  static final int PARENT_ID_B2 = 2;
  static final int LEVEL_B = 4;
  static final int TIME_B1 = 6;
  static final int TIME_B2 = 5;
  static final int MSG_IDX_B1 = 8;
  static final int MSG_IDX_B2 = 7;
    static final int MSG_TYPE_B = 9;
    static final int QUERY_B = 10;
    static final int NUM_FIELDS_B = 11;
    static final int NUM_EXPRS_B = 12;
    static final int EPOCH_DUR_B1 = 14;
    static final int EPOCH_DUR_B2 = 13;
    static final int IS_EXPR_B = 15;
    static final int IDX_B = 16;
    static final int NAME_B1 = 17; //if field
    static final int IS_AGG_B = 17; //if expr
    static final int SUCCESS_B = 18;
  static final int EXPR_IDX_B = 19;
    static final int FIELD_B1 = 21; //if agg or op
    static final int FIELD_B2 = 20;
    static final int GROUP_B1 = 23; //if agg
    static final int GROUP_B2 = 22;
    static final int ATTENUATION_B = 24;
    static final int AGG_OP_B = 25;
    static final int OP_B = 22; //if op
    static final int VALUE_B1 = 24;
    static final int VALUE_B2 = 23; 

    
}
