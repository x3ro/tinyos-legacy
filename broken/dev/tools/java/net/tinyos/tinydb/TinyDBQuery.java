package net.tinyos.tinydb;

import java.util.*;
import net.tinyos.message.*;

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
	this.from_qid = NO_FROM_QUERY;
	this.epochDur = epochDur;
    }

    

    /** Return the id of the query */
    public int getId() {
	return qid;
    }

    /* Set the id of the query.  Added by Kyle */
    public void setId(byte qid) {
	this.qid = qid;
    }

    /* Set the epoch size of the query */
    public void setEpoch(short epochDur) {
	this.epochDur = epochDur;
    }

    /** Add the specified field to the query */
    public void addField(QueryField f) {
	int idx = f.getIdx();
	
	/* Ick -- insure that the field is inserted at the correct
	   index (as indicated by f.getIdx)
	   
	   ArrayList.insureCapacity doesn't work, so explicitly insert nulls
	   for fields we haven't seen yet.
	*/
	int diff = (idx + 1) - fields.size();
	while (diff-- > 0)
	    fields.add(null);

	try {
	    fields.set(idx,f);
	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

    /** Add the specified expression to the query */
    public void addExpr(QueryExpr e) {
	/*  Aggregate expressions must appear at the end of the expression list
	    or else the query won't run properly. */
	if (e.isAgg()) {
	    exprs.add(lastSelExpr+1, e);

	    AggExpr ae = (AggExpr)e;

	    if (TinyDBMain.debug) System.out.println("ae's groupField = " + ae.getGroupField());

	    if (ae.getGroupField() != AggExpr.NO_GROUPING) {
		isGrouped = true;
		groupExpr = ae;
	    }
	} else {
	    exprs.add(0,e);
	    lastSelExpr++;
	}

	//exprs.add(e);
	//	if (e instanceof AggExpr) {

	//}
	    
    }

    /** Return true if the query is grouped (e.g. contains one or more aggregates with a 
	group by expression)
    */
    public boolean grouped() {
	return isGrouped;
    }

  public void setGrouped(boolean isGrouped) {
    this.isGrouped = isGrouped;
  }

  public void setGroupExpr(AggExpr ae) {
    groupExpr = ae;
  }
    
    
    /** Return the name of the group by column */
    public String groupColName() {
	if (TinyDBMain.debug) System.out.println("isGrouped = " + isGrouped);

	if (isGrouped) {
	    String fname = getField(groupExpr.getGroupField()).getName();

	    return (fname + " " + ArithOps.getStringValue(groupExpr.getGroupFieldOp()) + " " + groupExpr.getGroupFieldConst());
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

    /* Display list of expressions contained in query */
    public String toString() {
	QueryExpr temp;
	String result = "";
	int i;

	result += "Fields in query:\n";

	for (i = 0; i < numFields(); i++)
	    result += (i + "  " + getField(i) + "\n");

	result += numExprs() + " expressions representing query:\n";
	for (i = 0; i < numExprs(); i++) {
	    try {
		temp = getExpr(i);
		result += temp;
	    } catch (ArrayIndexOutOfBoundsException e) {}
	}
	result += "Epoch Duration = " + epochDur + "\n";
	result += "Query ID = " + qid + "\n";
	
	return result;
    }


    public void setOutputCommand(String cmd, short param) {
	hasCmd = true;
	paramVal = param;
	cmdName = cmd;
	hasParam = false;
    }

    public void setOutputCommand(String cmd) {
	setOutputCommand(cmd, (short)0);
	hasParam = false;
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
    public Message abortMessage() {
      QueryMsg m = new QueryMsg();
      initCommonFields(m);
      m.set_msgType(DEL_MSG);
      return m;
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

		//System.out.println("Expression " + i + " is " + e.isAgg() + "   " + e);

		if (e.isAgg()) {
		    AggExpr ae = (AggExpr)e;
		    if (ae.getGroupField() != -1 && !addedGroupCol) {
			cols.addElement(groupColName());
			addedGroupCol = true;
		    }
		    String aggString = "";
		    aggString += ae.getAgg().toString() + "(" + getField(ae.getField()).getName();
		    
		    if (ae.getFieldOp() != ArithOps.NO_OP) {
			aggString += ArithOps.getStringValue(ae.getFieldOp()) + " ";
			aggString += ae.getFieldConst();
		    }
		    
		    aggString += ")";

		    cols.addElement(aggString);

		}
		if (TinyDBMain.debug) System.out.println(cols);
	    }
	    
	} else {
	    //its a selection; the columns that are returned
	    //are the exprs
	    for (int i =0; i < numFields(); i++) {
		QueryField qf = getField(i);
		if (qf != null) cols.addElement(qf.getName());
	    }

	}

	return cols;
    }

    //Returns the type (as defined in QueryField) of the specified
    //column in the result set.
    public byte getFieldType(int idx) throws IndexOutOfBoundsException {
	boolean addedGroupCol = false;
	if (idx == 0) return QueryField.INTTWO;
	if (isAgg()) {
	    for (int i = 0; i < numExprs(); i++) {
		QueryExpr e = getExpr(i);

		if (e.isAgg()) {
		    AggExpr ae = (AggExpr)e;
		    if (ae.getGroupField() != -1 && !addedGroupCol) {
			if (--idx == 0) return getField(groupExpr.getGroupField()).getType();
			addedGroupCol = true;
		    } 
		    if (--idx == 0) return getField(ae.getField()).getType();
		}

	    }
	    throw new IndexOutOfBoundsException();
	} else {
	    for (int i = 0; i < numFields(); i++) {
		QueryField qf = getField(i);
		if (--idx == 0) return qf.getType();
	    } 
	    throw new IndexOutOfBoundsException();
	}

    }

    
    /** Return an Iterator over messages to be sent
	to start sensors running this 
	query 
    */
    public Iterator messageIterator() {
	ArrayList messages = new ArrayList();
	QueryMsg msg;

	//first, set up all the fields
	for (int i = 0; i < fields.size(); i++) {
	    QueryField f = (QueryField)fields.get(i);

	    msg = new QueryMsg();
	    initCommonFields(msg);
	    msg.set_type(FIELD);
	    msg.set_idx((byte)i);
	    msg.set_u_field_op(f.getOp());
	    msg.setString_u_field_name(f.getName());
	    if (TinyDBMain.debug) System.out.println(msg.toString());
	    
	    messages.add(msg);
	}

	//then all the exprs
	for (int i = 0; i < exprs.size(); i++) {
	    QueryExpr e = (QueryExpr)exprs.get(i);
	    
	    msg = new QueryMsg();
	    initCommonFields(msg);

	    msg.set_type(EXPR);
	    msg.set_idx((byte)i);
	    msg.set_u_expr_opType((byte)(e.isAgg()?(((AggExpr)e).isTemporalAgg()?TEMPORAL_AGG_EXPR:AGG_EXPR):SEL_EXPR));
				 

	    msg.set_u_expr_fieldOp(e.getFieldOp());
	    msg.set_u_expr_fieldConst(e.getFieldConst());
	    if (e.isAgg()) {
		AggExpr a = (AggExpr)e;

		msg.set_u_expr_ex_agg_field(e.getField());
		msg.set_u_expr_ex_agg_op(a.getAggOpCode());
		msg.set_u_expr_ex_agg_groupingField(a.getGroupField());
		msg.set_u_expr_ex_agg_groupFieldOp(a.getGroupFieldOp());
		msg.set_u_expr_ex_agg_groupFieldConst(a.getGroupFieldConst());
		if (a.isTemporalAgg()) {
		    msg.set_u_expr_ex_tagg_u_epochsPerWindow(a.getAgg().getConst());
		    msg.set_u_expr_ex_tagg_epochsLeft((short)0);
		}
	    } else {
		SelExpr s = (SelExpr)e;

		msg.set_u_expr_ex_opval_field(e.getField());
		msg.set_u_expr_ex_opval_op((byte)s.getSelOpCode());
		msg.set_u_expr_ex_opval_value(s.getValue());
	    }
	    if (TinyDBMain.debug) {
		System.out.println("expr msg: ");
		System.out.print(msg.toString());
	    }
	    messages.add(msg);
	}

	//the command, if this is a command buffer
	if (hasCmd) {
	  msg = new QueryMsg();
	  initCommonFields(msg);
	  msg.set_type(BUFFER);
	  msg.setString_u_buf_cmd_name(cmdName);
	  msg.set_u_buf_cmd_hasParam((short)(hasParam?1:0));
	  msg.set_u_buf_cmd_param(paramVal);
	  if (TinyDBMain.debug) System.out.println("command msg: " + msg.toString());
	  messages.add(msg);
	} else if (ramBuffer) { //or, might be a ram buffer
	  msg = new QueryMsg();
	  initCommonFields(msg);
	  msg.set_type(BUFFER);
	  msg.set_u_buf_ram_numRows(bufSize);
	  msg.set_u_buf_ram_policy(EVICT_OLDEST_POLICY);
	  if (TinyDBMain.debug) System.out.println("ram buffer msg: " + msg.toString());
	  messages.add(msg);
	}
	
	
	return messages.iterator();
    }

    // set up common fields in radio messages
    private void initCommonFields(QueryMsg m) {
      m.set_hdr_senderid((short)0);
      m.set_hdr_parentid((short)0);
      m.set_hdr_level((short)0);
      m.set_hdr_timeRemaining((short)0);
      m.set_hdr_idx((short)0);
      m.set_msgType(ADD_MSG);
      m.set_qid(qid);
      m.set_queryRoot((short)0); 
      m.set_numFields((byte)fields.size());
      m.set_numExprs((byte)exprs.size());
      m.set_fromQid(from_qid);
      m.set_bufferType(hasCmd?COMMAND_BUFFER:(ramBuffer?RAM_BUFFER:RADIO_BUFFER));
      m.set_epochDuration(epochDur);
    }

    /* Return the id fo the query this query reads results from */
    public byte getFromQid() {
	return from_qid;
    }
    
    /** Set the id of the query this query reads results from */
    public void setFromQid(byte qid) {
	this.from_qid = qid;
    }

  public void useRamBuffer(short size) {
    bufSize = size;
    ramBuffer = true;
  }

    
    public byte qid,from_qid;
    public short epochDur;

  private boolean ramBuffer = false;
  private short bufSize;

    private boolean isGrouped = false;
    private AggExpr groupExpr = null;

    private ArrayList fields;
    private ArrayList exprs;
    private int lastSelExpr = -1;

    private String sql = "";

    private boolean hasCmd = false;
    private String cmdName;
    private short paramVal = 0;
    private boolean hasParam = false;

    
    static final byte FIELD = 0;
    static final byte EXPR = 1;
    static final byte BUFFER = 2;

    static final byte ADD_MSG = 0;
    static final byte DEL_MSG = 1;
    static final byte MODIFY_MSG = 2;

    public static final byte NO_FROM_QUERY = (byte)0xFF;

    static final byte SEL_EXPR = 0;
    static final byte AGG_EXPR = 1;
    static final byte TEMPORAL_AGG_EXPR = 2;

    static final byte RADIO_BUFFER = 0;
    static final byte RAM_BUFFER = 1;
    static final byte EEPROM_BUFFER = 2;
    static final byte COMMAND_BUFFER = 3;

    static final byte EVICT_OLDEST_POLICY = 0;
    public static final short kEPOCH_DUR_ONE_SHOT=(short)0xFFFF;


  
}
