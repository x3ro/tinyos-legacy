package net.tinyos.tinydb;

/** Abstract interface for all kinds of expressions that
    can appear in a query
*/
public interface QueryExpr {
    /** Return true if this expression is an aggregator */
    public boolean isAgg();
    
    /** Return the id of the field this expression applies to */
    public short getField();

    /** Return the arithmetic operation that is used in the
	arithmetic expression that will be performed to the 
	field.
    */
    public short getFieldOp();

    /** Return the constant that is used in the arithmetic 
	expression that will be performed on the field.
    */
    public short getFieldConst();
}
