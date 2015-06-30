package net.tinyos.tinydb;

/** Abstract interface for all kinds of expressions that
    can appear in a query
*/
public interface QueryExpr {
    /** Return true if this expression is an aggregator */
    public boolean isAgg();
    
    /** Return the id of the field this expression applies to */
    public short getField();
}
