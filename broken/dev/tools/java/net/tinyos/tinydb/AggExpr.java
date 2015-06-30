package net.tinyos.tinydb;

/** Class to represent an aggregation expression.
    Aggregates are of the form:
    [aggf(fielda),groupby(fieldb)]
    
    Aggf is an aggregation function from AggOp, 
    and groupby may be NO_GROUPING, indicating an ungrouped aggregate
*/
public class AggExpr implements QueryExpr {
    public static final short NO_GROUPING = (short)0xFFFF;
  
    /** Create an aggregate expression applying the specified
	operation to field, grouping by field groupBy.
	@param field The field to aggregate
	@param op The operator to aggregate with
	@param groupBy The field to group by, or NO_GROUPING 
    */
    public AggExpr(short field, AggOp op, short groupBy) {
	this.field = field;
	this.op = op;
	this.groupBy = groupBy;
    }

    /** Create an aggregate expression that applies a simple arithmetic
	expression to the field before applying the aggregate operator
    */
    public AggExpr(short field, String fieldOp, short fieldConst, AggOp op, short groupBy) {
	this.field = field;
	this.fieldOp = ArithOps.getOp(fieldOp);
	this.fieldConst = fieldConst;
	this.op = op;
	this.groupBy = groupBy;
    }

    /** Create an aggregate expression and set the groupBy field 
	later.  Added by Kyle
    */
    public AggExpr(short field, AggOp op) {
	this.field = field;
	this.op = op;
	this.groupBy = -1;
    }

    public AggExpr(short field, String fieldOp, short fieldConst, AggOp op) {
	this.field = field;
	this.fieldOp = ArithOps.getOp(fieldOp);
	this.fieldConst = fieldConst;
	this.op = op;
	this.groupBy = -1;
    }

    public boolean isAgg() {
	return true;
    }

    public boolean isTemporalAgg() {
	return op.isTemporal();
    }
    
    public short getField() {
	return field;
    }

    public short getGroupField() {
	return groupBy;
    }
    
    // added by Kyle
    public void setGroupField(short groupBy) {
	this.groupBy = groupBy;
    }

    public byte getAggOpCode() {
	return op.toByte();
    }
    
    public AggOp getAgg() {
	return op;
    }

  /** groupFieldOp is a constant representing a simple arithmetic operator
      that will be performed on the value of the group by attribute before
      the groups are defined.
  */
  public short getGroupFieldOp() {
    return groupFieldOp;
  }

  public void setGroupFieldOp(String groupFieldOpStr) {
    groupFieldOp = ArithOps.getOp(groupFieldOpStr);
  }
  
  /** groupFieldConst is a constant value that is used inthe arithmetic operation
      specified by groupFieldOp
  */
  public short getGroupFieldConst() {
    return groupFieldConst;
  }

  public void setGroupFieldConst(short groupFieldConst) {
    this.groupFieldConst = groupFieldConst;
  }

    /** fieldOp is a constant representing a simple arithmetic operator
	that will be performed on the value of the attribute before the
	aggregate is computed.
    */
    public short getFieldOp() {
	return fieldOp;
    }
  
  public void setFieldOp(String fieldOpStr) {
    this.fieldOp = ArithOps.getOp(fieldOpStr);
  }
    

    /** fieldConst is the constant in the arithmetic operation specified by fieldOp */
    public short getFieldConst() {
	return fieldConst;
    }

  public void setFieldConst(short fieldConst) {
    this.fieldConst = fieldConst;
  }

    public String toString() {
	return("Agg:  " + op + "(" + field + " " + ArithOps.getStringValue(fieldOp) + " " + fieldConst + ")  Group By(" + groupBy + " " + ArithOps.getStringValue(groupFieldOp) + " " + groupFieldConst + ")\n");
    }


  private short fieldOp = ArithOps.NO_OP; // By default, there is no operation applied to the aggregated field
  private short fieldConst = 0;
  private short field; //the id of the field the aggregate pertains to
  private AggOp op;
  private short groupBy = NO_GROUPING;
  private short groupFieldOp = ArithOps.NO_OP; // By default, there is no operation applied to the group by field
  private short groupFieldConst = 0;
}
