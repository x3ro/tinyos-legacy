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
	this.attenuation = (char)0;
    }

    public boolean isAgg() {
	return true;
    }
    public short getField() {
	return field;
    }

    public short getGroupField() {
	return groupBy;
    }

    public byte getAggOpCode() {
	return op.toByte();
    }
    
    public AggOp getAgg() {
	return op;
    }

    /** Attenuation is the amount to bit-shift the group by field by
	before grouping.  This simple grouping expression makes it
	easy to partition nodes into coarse buckets (e.g light / dark
	
	This method returns the attenuation factor (number of bits
	to shift off the of the grouping field
    */
    public char getAttenuation() {
	return attenuation;
    }

    /** Set the attentuation factor -- see getAttenuation() */
    public void setAttenuation(char a) {
	attenuation = a;
    }
    
    private short field;
    private AggOp op;
    private short groupBy;
    private char attenuation;
}
